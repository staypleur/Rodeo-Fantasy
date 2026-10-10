"""Small glTF loader, transforms and skin evaluator used by asset checks/previews."""
from pathlib import Path
import json
import struct
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/models/MossratS1UserRig'
DTYPES = {5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}
DIMS = {'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}


def load(path):
    raw = Path(path).read_bytes()
    if raw[:4] == b'glTF':
        assert struct.unpack_from('<I',raw,8)[0] == len(raw)
        n = struct.unpack_from('<I',raw,12)[0]
        return json.loads(raw[20:20+n]), raw[28+n:]
    g = json.loads(raw)
    return g, (Path(path).parent/g['buffers'][0]['uri']).read_bytes()


def read(g, b, index):
    a = g['accessors'][index]; v = g['bufferViews'][a['bufferView']]
    dtype = np.dtype(DTYPES[a['componentType']]); dims = DIMS[a['type']]
    offset = v.get('byteOffset',0)+a.get('byteOffset',0)
    stride = v.get('byteStride',dtype.itemsize*dims)
    return np.ndarray((a['count'],dims),dtype=dtype,buffer=b,offset=offset,
                      strides=(stride,dtype.itemsize)).copy()


def quat(axis, angle):
    out = np.zeros(4); out[axis] = np.sin(angle/2); out[3] = np.cos(angle/2)
    return out


def matrix(t=(0,0,0), q=(0,0,0,1), s=(1,1,1)):
    x,y,z,w = np.asarray(q)/np.linalg.norm(q)
    r = np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                  [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                  [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
    out = np.eye(4); out[:3,:3] = r@np.diag(s); out[:3,3] = t
    return out


def transforms(g, b, clip=None, time=0):
    trs = [{key:np.array(node.get(key,default),float) for key,default in
            [('translation',[0,0,0]),('rotation',[0,0,0,1]),('scale',[1,1,1])]}
           for node in g['nodes']]
    if clip is not None:
        animation = next(a for a in g['animations'] if a['name'] == clip)
        for channel in animation['channels']:
            sampler = animation['samplers'][channel['sampler']]
            ts = read(g,b,sampler['input']).ravel(); values = read(g,b,sampler['output'])
            t = min(max(time,float(ts[0])),float(ts[-1])); i = min(np.searchsorted(ts,t,side='right')-1,len(ts)-2)
            f = (t-ts[i])/max(1e-12,ts[i+1]-ts[i]); value = values[i]*(1-f)+values[i+1]*f
            if channel['target']['path'] == 'rotation': value /= np.linalg.norm(value)
            trs[channel['target']['node']][channel['target']['path']] = value
    parent = {}
    for i,node in enumerate(g['nodes']):
        for child in node.get('children',[]): parent[child] = i
    world = {}
    def evaluate(i):
        if i not in world:
            node = g['nodes'][i]
            local = np.array(node['matrix']).reshape(4,4).T if 'matrix' in node else matrix(trs[i]['translation'],trs[i]['rotation'],trs[i]['scale'])
            world[i] = evaluate(parent[i])@local if i in parent else local
        return world[i]
    for i in range(len(g['nodes'])): evaluate(i)
    return world


def skin(g, b, clip=None, time=0):
    node = next(n for n in g['nodes'] if 'mesh' in n)
    p = g['meshes'][node['mesh']]['primitives'][0]
    pos = read(g,b,p['attributes']['POSITION']); normal = read(g,b,p['attributes']['NORMAL'])
    if 'skin' not in node: return pos,normal
    s = g['skins'][node['skin']]; ibm = read(g,b,s['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
    world = transforms(g,b,clip,time); m = np.array([world[j]@ibm[i] for i,j in enumerate(s['joints'])])
    joints = read(g,b,p['attributes']['JOINTS_0']); weights = read(g,b,p['attributes']['WEIGHTS_0'])
    blend = np.sum(m[joints]*weights[:,:,None,None],axis=1)
    hom = np.column_stack((pos,np.ones(len(pos))))
    skinned = np.einsum('nij,nj->ni',blend,hom)[:,:3]
    normals = np.einsum('nij,nj->ni',blend[:,:3,:3],normal)
    normals /= np.maximum(1e-12,np.linalg.norm(normals,axis=1))[:,None]
    return skinned,normals
