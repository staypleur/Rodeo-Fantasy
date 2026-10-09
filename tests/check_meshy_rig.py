"""Check actual GLB bind pose, skin influences and posed leg/head separation."""
from pathlib import Path
import json,struct,numpy as np
R=Path(__file__).resolve().parents[1]
for role in ('Hunt','Detail'):
 path=R/f'assets/meshes/meshy/Mossrat_S1_{role}_Rigged.glb'
 raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+length]);b=raw[28+length:]
 def a(i):
  x=g['accessors'][i];v=g['bufferViews'][x['bufferView']];dim={'VEC3':3,'VEC4':4,'SCALAR':1,'MAT4':16}[x['type']]
  return np.frombuffer(b,dtype={5126:'<f4',5123:'<u2',5121:'u1'}[x['componentType']],count=x['count']*dim,offset=v.get('byteOffset',0)+x.get('byteOffset',0)).reshape(-1,dim).copy()
 p=g['meshes'][0]['primitives'][0];pos=a(p['attributes']['POSITION']);joints=a(p['attributes']['JOINTS_0']);weights=a(p['attributes']['WEIGHTS_0'])
 assert len(a(p['indices']))//3==(3114 if role=='Hunt' else 10348) and len(g['skins'][0]['joints'])==5
 assert np.allclose(weights.sum(axis=1),1) and (weights>=0).all() and joints.max()==4
 inv=a(g['skins'][0]['inverseBindMatrices']).reshape(5,4,4).transpose(0,2,1)
 posed=pos*weights[:,0,None];bind=pos*weights[:,0,None]
 for joint in range(1,5):
  node=g['nodes'][joint+1];hip=np.array(node['translation']);matrix=np.eye(4);matrix[:3,3]=hip
  assert np.allclose(matrix@inv[joint],np.eye(4))
  mask=joints[:,1]==joint;angle=.45*(1 if ('Left' in node['name'])==('Front' in node['name']) else -1)
  rot=np.array([[1,0,0],[0,np.cos(angle),-np.sin(angle)],[0,np.sin(angle),np.cos(angle)]])
  posed[mask]+=(hip+(pos[mask]-hip)@rot.T)*weights[mask,1,None]
  bind[mask]+=pos[mask]*weights[mask,1,None]
  assert (np.linalg.norm(posed[mask]-pos[mask],axis=1)>.01).sum()>30
 assert np.allclose(bind,pos,atol=1e-7) and np.array_equal(posed[pos[:,1]>=.235],pos[pos[:,1]>=.235])
 # Inspect the same linear skin deformation with the existing real-mesh renderer.
 if role=='Detail':
  data=bytearray(b);x=g['accessors'][p['attributes']['POSITION']];v=g['bufferViews'][x['bufferView']]
  offset=v.get('byteOffset',0)+x.get('byteOffset',0);data[offset:offset+pos.nbytes]=posed.astype('<f4').tobytes()
  (R/'.tools/mossrat-walk-pose.glb').write_bytes(raw[:28+length]+data)
 print(role,'RIG_PASS: bind pose unchanged; four legs move; head/body upper vertices remain fixed')
