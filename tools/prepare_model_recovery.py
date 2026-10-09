"""Prepare head-only Mossrat correction and a fresh compact airship PBR import."""
from pathlib import Path
import json, struct, io, hashlib
import numpy as np
from PIL import Image

R = Path(__file__).resolve().parents[1]
OUT = R / 'dist/ModelRecovery'
OUT.mkdir(parents=True, exist_ok=True)

def load(path):
    raw = path.read_bytes()
    n = struct.unpack_from('<I', raw, 12)[0]
    return json.loads(raw[20:20+n]), bytearray(raw[28+n:])

def save(path, g, b):
    g['buffers'] = [{'byteLength': len(b)}]
    j = json.dumps(g, separators=(',', ':')).encode()
    j += b' ' * (-len(j) % 4)
    path.write_bytes(struct.pack('<III', 0x46546c67, 2, 28+len(j)+len(b)) +
                    struct.pack('<I4s', len(j), b'JSON') + j +
                    struct.pack('<I4s', len(b), b'BIN\0') + b)

def arr(g, b, i):
    a = g['accessors'][i]; v = g['bufferViews'][a['bufferView']]
    dim = {'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'SCALAR': 1}[a['type']]
    return np.frombuffer(b, dtype={5126: '<f4', 5123: '<u2', 5125: '<u4', 5121: 'u1'}[a['componentType']],
                         count=a['count']*dim, offset=v.get('byteOffset', 0)+a.get('byteOffset', 0)).reshape(-1, dim)

def smooth(x):
    x = np.clip(x, 0, 1)
    return x*x*(3-2*x)

yaw, roll = np.deg2rad([-7, -9])
ry = np.array([[np.cos(yaw), 0, np.sin(yaw)], [0, 1, 0], [-np.sin(yaw), 0, np.cos(yaw)]])
rz = np.array([[np.cos(roll), -np.sin(roll), 0], [np.sin(roll), np.cos(roll), 0], [0, 0, 1]])
rotation = rz @ ry
pivot = np.array([0, .40, -.24])

def deform(v):
    # A smooth neck transition, with zero influence on legs, torso and tail.
    ygate = smooth((v[:, 1]-.29)/.14)
    zgate = smooth((-.08-v[:, 2])/.19)
    upper = smooth((v[:, 1]-.43)/.15)
    face = smooth((-.30-v[:, 2])/.18)
    w = ygate*zgate*np.maximum(upper, face)
    turned = pivot+(v-pivot)@rotation.T
    return v+(turned-v)*w[:, None], w

for role in ('Hunt', 'Detail'):
    source = R/f'assets/meshes/meshy/Mossrat_S1_{role}_Rigged.glb'
    g, b = load(source); p = g['meshes'][0]['primitives'][0]
    v = arr(g, b, p['attributes']['POSITION']); old = v.copy()
    new, weight = deform(old)
    # Inverse-transpose Jacobian keeps smooth normals aligned through the neck blend.
    jac = np.empty((len(v), 3, 3))
    for k in range(3):
        offset = np.zeros(3); offset[k] = 1e-5
        jac[:, :, k] = (deform(old+offset)[0]-deform(old-offset)[0])/2e-5
    assert np.linalg.det(jac).min() > .65
    n = arr(g, b, p['attributes']['NORMAL'])
    corrected = np.linalg.solve(jac.transpose(0, 2, 1), n.astype(float)[..., None])[..., 0]
    corrected /= np.linalg.norm(corrected, axis=1)[:, None]
    v[:] = new; n[:] = corrected
    a = g['accessors'][p['attributes']['POSITION']]
    a['min'] = v.min(0).tolist(); a['max'] = v.max(0).tolist()
    g['nodes'][0]['name'] = f'Mossrat_S1_{role}_HeadStraight'
    g.setdefault('extras', {})['RodeoRecovery'] = {'headYawDegrees': -7, 'headRollDegrees': -9,
        'headOnly': True, 'preparedForward': '-Z', 'originalTrianglesUVSkinTexturesPreserved': True}
    output = OUT/f'Mossrat_S1_{role}_HeadStraight.glb'
    save(output, g, b)
    assert np.array_equal(v[weight == 0], old[weight == 0])
    print(role, 'HEAD_ONLY', 'changed vertices', int((weight > 0).sum()), 'triangles', g['accessors'][p['indices']]['count']//3)

source = R/'assets/meshes/meshy/LobbyAirship_Source.glb'
g, b = load(source)
# Decode/re-encode maps to get fresh image content, without changing geometry/UVs.
image_views = {im['bufferView']: im for im in g['images']}
base_index = g['textures'][g['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index']]['source']
base_view = g['images'][base_index]['bufferView']
parts = []; offset = 0; sizes = []
for i, view in enumerate(g['bufferViews']):
    data = bytes(b[view.get('byteOffset', 0):view.get('byteOffset', 0)+view['byteLength']])
    if i in image_views:
        im = Image.open(io.BytesIO(data)).convert('RGB')
        im.thumbnail((2048, 2048), Image.Resampling.LANCZOS)
        buf = io.BytesIO()
        if i == base_view:
            im.save(OUT/'LobbyAirship_Recovery_ColorMap.png', format='PNG', optimize=True)
            im.save(buf, format='JPEG', quality=96, subsampling=0)
            image_views[i]['mimeType'] = 'image/jpeg'
        else:
            im.save(buf, format='PNG', optimize=True)
            image_views[i]['mimeType'] = 'image/png'
        data = buf.getvalue()
        sizes.append(list(im.size))
    view['byteOffset'] = offset; view['byteLength'] = len(data)
    padded = data+b'\0'*(-len(data) % 4); parts.append(padded); offset += len(padded)
g['nodes'][0]['name'] = 'LobbyAirship_Recovery'
g['materials'][0]['name'] = 'LobbyAirship_Recovery_PBR_2k'
g.setdefault('extras', {})['RodeoRecovery'] = {'geometryUVNormalsUnchanged': True, 'textureMaxSize': 2048, 'sourceForward': '+Z'}
save(OUT/'LobbyAirship_Recovery.glb', g, b''.join(parts))
print('AIRSHIP_FRESH_PBR', sizes, 'bytes', (OUT/'LobbyAirship_Recovery.glb').stat().st_size)
