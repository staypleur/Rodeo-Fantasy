"""Add a small four-leg skin rig to the approved 3k GLB, preserving its mesh."""
from pathlib import Path
import json,struct,copy
import numpy as np
R=Path(__file__).resolve().parents[1]
for role in ('Hunt','Detail'):
 source=R/f'assets/meshes/meshy/Mossrat_S1_{role}.glb'
 raw=source.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
 g=json.loads(raw[20:20+length]);b=bytearray(raw[28+length:])
 p=g['meshes'][0]['primitives'][0]
 def read(i):
  a=g['accessors'][i];v=g['bufferViews'][a['bufferView']]
  return np.frombuffer(b,dtype='<f4',count=a['count']*3,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,3).copy()
 vertices=read(p['attributes']['POSITION'])
 names=[];hips=[]
 for side,label in ((-1,'Left'),(1,'Right')):
  for front,limb in ((-1,'Front'),(1,'Back')):
   feet=vertices[(vertices[:,1]<.09)&(vertices[:,0]*side>0)&(vertices[:,2]*front>0)]
   center=np.median(feet,axis=0);center[1]=.19
   hips.append(center);names.append('Moss'+label+limb+'Leg')
 hips=np.array(hips)
 distance=np.linalg.norm(vertices[:,None,[0,2]]-hips[None,:,[0,2]],axis=2)
 nearest=distance.argmin(axis=1);radial=np.clip((.18-distance.min(axis=1))/.07,0,1)
 height=np.clip((.235-vertices[:,1])/.12,0,1);height=height*height*(3-2*height)
 influence=radial*height
 joints=np.zeros((len(vertices),4),dtype=np.uint8);joints[:,1]=nearest+1
 weights=np.zeros((len(vertices),4),dtype='<f4');weights[:,0]=1-influence;weights[:,1]=influence
 def append(array,kind,component):
  data=array.tobytes();offset=len(b);b.extend(data);b.extend(b'\0'*((-len(b))%4))
  view=len(g['bufferViews']);g['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(data)})
  index=len(g['accessors']);g['accessors'].append({'bufferView':view,'componentType':component,'count':len(array),'type':kind})
  return index
 p['attributes']['JOINTS_0']=append(joints,'VEC4',5121)
 p['attributes']['WEIGHTS_0']=append(weights,'VEC4',5126)
 bind=np.repeat(np.eye(4,dtype='<f4')[None],5,axis=0)
 for i,hip in enumerate(hips,1):bind[i,:3,3]=-hip
 inverse=append(bind.transpose(0,2,1).copy().reshape(5,16),'MAT4',5126)
 g['nodes']=[{'mesh':0,'skin':0,'name':'MossratBody'}, {'name':'MossRoot','children':[2,3,4,5]}]
 for name,hip in zip(names,hips):g['nodes'].append({'name':name,'translation':hip.tolist()})
 g['skins']=[{'name':'MossratFourLegRig','joints':[1,2,3,4,5],'skeleton':1,'inverseBindMatrices':inverse}]
 g['scenes']=[{'nodes':[0,1]}];g['scene']=0
 # Optional embedded walk clip; runtime also drives these same bones locally.
 times=np.linspace(0,1,17,dtype='<f4');time_accessor=append(times,'SCALAR',5126)
 g['accessors'][time_accessor].update(min=[0],max=[1])
 clip={'name':'MossratWalk','samplers':[],'channels':[]}
 for i,name in enumerate(names):
  opposite=('Left' in name)!=('Front' in name)
  angle=np.sin(times*2*np.pi+(np.pi if opposite else 0))*.45
  q=np.zeros((len(times),4),dtype='<f4');q[:,0]=np.sin(angle/2);q[:,3]=np.cos(angle/2)
  output=append(q,'VEC4',5126)
  clip['samplers'].append({'input':time_accessor,'output':output,'interpolation':'LINEAR'})
  clip['channels'].append({'sampler':i,'target':{'node':i+2,'path':'rotation'}})
 g['animations']=[clip];g['buffers']=[{'byteLength':len(b)}]
 j=json.dumps(g,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
 output=source.with_name(f'Mossrat_S1_{role}_Rigged.glb')
 output.write_bytes(struct.pack('<III',0x46546c67,2,28+len(j)+len(b))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(b),b'BIN\0')+b)
 assert np.allclose(weights.sum(axis=1),1) and np.isfinite(weights).all()
 for i in range(4):assert (weights[joints[:,1]==i+1,1]>.8).sum()>30
 triangles=g['accessors'][p['indices']]['count']//3
 print(role,triangles,'triangles / five bones / normalized weights / walk clip',output.stat().st_size)
