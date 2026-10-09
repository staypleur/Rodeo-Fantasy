"""Verify head-only deformation, normals, skin/UV/topology, and fresh airship maps."""
from pathlib import Path
import json,struct,io,hashlib
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
def load(path):
 raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0]
 return json.loads(raw[20:20+n]),raw[28+n:]
def data(g,b,index):
 a=g['accessors'][index];v=g['bufferViews'][a['bufferView']]
 dims={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
 return np.frombuffer(b,dtype={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']],
   offset=v.get('byteOffset',0)+a.get('byteOffset',0),count=a['count']*dims).reshape(-1,dims)
def image_bytes(g,b):
 return [b[g['bufferViews'][im['bufferView']]['byteOffset']:g['bufferViews'][im['bufferView']]['byteOffset']+g['bufferViews'][im['bufferView']]['byteLength']] for im in g['images']]
for role in ('Hunt','Detail'):
 g,b=load(R/f'assets/meshes/meshy/Mossrat_S1_{role}_Rigged.glb')
 h,c=load(R/f'dist/ModelRecovery/Mossrat_S1_{role}_HeadStraight.glb')
 p=g['meshes'][0]['primitives'][0];q=h['meshes'][0]['primitives'][0]
 old=data(g,b,p['attributes']['POSITION']);new=data(h,c,q['attributes']['POSITION'])
 fixed=(old[:,1]<=.29)|(old[:,2]>=-.08)
 assert np.array_equal(old[fixed],new[fixed]),'legs/torso/tail must remain unchanged'
 full=(old[:,1]>=.58)&(old[:,2]<=-.27)
 # Rigid head region: pairwise distances retain their original lengths.
 assert np.allclose(np.linalg.norm(old[full]-old[full][0],axis=1),np.linalg.norm(new[full]-new[full][0],axis=1),atol=1e-7)
 assert np.linalg.norm(new-old,axis=1).max()>.03
 for key in ('TEXCOORD_0','JOINTS_0','WEIGHTS_0'):
  assert np.array_equal(data(g,b,p['attributes'][key]),data(h,c,q['attributes'][key]))
 assert np.array_equal(data(g,b,p['indices']),data(h,c,q['indices']))
 assert image_bytes(g,b)==image_bytes(h,c)
 assert g['skins']==h['skins'] and g['animations']==h['animations']
 assert g['nodes'][1:]==h['nodes'][1:]
 normals=data(h,c,q['attributes']['NORMAL'])
 assert np.isfinite(new).all() and np.allclose(np.linalg.norm(normals,axis=1),1,atol=1e-5)
 # Local winding stays consistent and no triangle is collapsed through neck blending.
 ids=data(g,b,p['indices']).reshape(-1,3)
 before=np.cross(old[ids[:,1]]-old[ids[:,0]],old[ids[:,2]]-old[ids[:,0]])
 after=np.cross(new[ids[:,1]]-new[ids[:,0]],new[ids[:,2]]-new[ids[:,0]])
 valid=np.linalg.norm(before,axis=1)>1e-9
 assert (np.linalg.norm(after[valid],axis=1)>1e-9).all()
 assert ((before[valid]*after[valid]).sum(axis=1)>0).all()
 print(role,'HEAD_CORRECTION_PASS: rigid upper head; smooth neck; unchanged body, UV, topology, textures and leg skin')
g,b=load(R/'assets/meshes/meshy/LobbyAirship_Source.glb')
h,c=load(R/'dist/ModelRecovery/LobbyAirship_Recovery.glb')
p=g['meshes'][0]['primitives'][0];q=h['meshes'][0]['primitives'][0]
for key in ('POSITION','NORMAL','TEXCOORD_0'):
 assert np.array_equal(data(g,b,p['attributes'][key]),data(h,c,q['attributes'][key]))
assert np.array_equal(data(g,b,p['indices']),data(h,c,q['indices']))
old_maps=image_bytes(g,b);new_maps=image_bytes(h,c)
assert all(hashlib.sha256(x).digest()!=hashlib.sha256(y).digest() for x,y in zip(old_maps,new_maps))
assert all(max(Image.open(io.BytesIO(x)).size)==2048 for x in new_maps)
assert g['materials'][0]['pbrMetallicRoughness']==h['materials'][0]['pbrMetallicRoughness']
print('AIRSHIP_RECOVERY_PASS: unchanged mesh/UVs; fresh 2k color and metal/rough maps; PBR wiring preserved')
