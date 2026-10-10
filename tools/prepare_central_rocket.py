"""Extract supplied GLB without modifying geometry, UVs or embedded image bytes."""
from pathlib import Path
import struct,json,copy,hashlib
R=Path(__file__).resolve().parents[1];out=R/'assets/models/CentralRocket'
b=(out/'Rocket.glb').read_bytes();assert b[:4]==b'glTF'
chunks={};offset=12
while offset<len(b):
 length,kind=struct.unpack_from('<II',b,offset);chunks[kind]=b[offset+8:offset+8+length];offset+=8+length
g=json.loads(chunks[0x4e4f534a]);binary=chunks[0x004e4942]
(out/'Rocket.bin').write_bytes(binary)
g['buffers'][0]['uri']='Rocket.bin'
for i,img in enumerate(g.get('images',[])):
 view=g['bufferViews'][img.pop('bufferView')];start=view.get('byteOffset',0)
 name='Color.png' if i==0 else 'MetallicRoughness.png'
 (out/name).write_bytes(binary[start:start+view['byteLength']]);img['uri']=name
(out/'Rocket.gltf').write_text(json.dumps(g,indent=2),encoding='utf-8')
mesh=copy.deepcopy(g)
for m in mesh['meshes']:
 for p in m['primitives']:p.pop('material',None)
for key in ('materials','images','textures','samplers'):mesh.pop(key,None)
(out/'RocketMeshOnly.gltf').write_text(json.dumps(mesh,indent=2),encoding='utf-8')
assert g['accessors']==mesh['accessors'] and g['nodes']==mesh['nodes']
print('CENTRAL_ROCKET_PREPARED',hashlib.sha256(b).hexdigest())
