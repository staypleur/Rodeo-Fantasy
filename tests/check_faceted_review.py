"""Validate the review mesh's actual triangle budget, flat normals and embedded atlas."""
from pathlib import Path
import struct,json,io
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
data=(ROOT/'dist/ReviewModels/MeadowMouse_A_S1_FacetedReview.glb').read_bytes()
magic,version,length=struct.unpack_from('<4sII',data)
assert (magic,version,length)==(b'glTF',2,len(data))
n,kind=struct.unpack_from('<I4s',data,12);assert kind==b'JSON'
g=json.loads(data[20:20+n]);binary=data[28+n:]
assert not g.get('animations') and not g.get('skins')
def values(idx):
 a=g['accessors'][idx];v=g['bufferViews'][a['bufferView']]
 dims={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
 dtype={5126:'<f4',5123:'<u2'}[a['componentType']]
 return np.frombuffer(binary,dtype=dtype,count=a['count']*dims,offset=v.get('byteOffset',0)).reshape(a['count'],dims)
total=0;names={n['name'] for n in g['nodes']}
assert len(names)==len(g['nodes'])
assert {'LeftEye','RightEye','OpenSmile','LeftEar','RightEar','LeftEarFur','RightEarFur','TailClover0','TailClover3'}<=names
for mesh in g['meshes']:
 for p in mesh['primitives']:
  pos=values(p['attributes']['POSITION']);normals=values(p['attributes']['NORMAL']);uv=values(p['attributes']['TEXCOORD_0'])
  ids=values(p['indices']).reshape(-1,3);total+=len(ids)
  assert np.isfinite(pos).all() and np.isfinite(normals).all()
  assert len(pos)==len(normals)==len(uv) and ids.max()<len(pos)
  assert ((uv>=0)&(uv<=1)).all()
  for indices in ids:
   n=normals[indices];assert np.allclose(n,n[0]),'smooth normals found'
   a,b,c=pos[indices];cross=np.cross(b-a,c-a);assert np.linalg.norm(cross)>1e-8
   assert np.dot(cross,n[0])>0,'normal/winding disagreement'
  if mesh['name'] in ('LeftEye','RightEye'):
   # All eye vertices lie in a single polygonal plane.
   assert np.max(np.abs((pos-pos[0])@normals[0]))<1e-5
assert 0<total<2000,total
view=g['bufferViews'][g['images'][0]['bufferView']]
atlas=Image.open(io.BytesIO(binary[view['byteOffset']:view['byteOffset']+view['byteLength']]))
assert atlas.size==(1024,1024)
external=Image.open(ROOT/'assets/meshes/review/MeadowMouse_A_S1_FacetedReview_BaseColor.png')
assert atlas.tobytes()==external.tobytes()
assert g['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index']==0
print(f'FACETED_REVIEW_PASS: {total} triangles, all flat normals, planar eyes, valid UVs, embedded/external atlas equality; static review only')
