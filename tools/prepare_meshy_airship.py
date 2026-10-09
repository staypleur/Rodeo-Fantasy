"""Preserve the user's new lobby GLB; fit four cables to its real underside."""
from pathlib import Path
import json,struct,hashlib,shutil
import numpy as np
R=Path(__file__).resolve().parents[1]
source=Path(r'C:/Users/wucha/Downloads/Meshy_AI_Crystal_Phoenix_Remes_1009165547_texture.glb')
raw=source.read_bytes();n=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+n]);b=raw[28+n:]
def a(i):
 x=g['accessors'][i];v=g['bufferViews'][x['bufferView']];dims={'VEC3':3,'SCALAR':1}[x['type']]
 return np.frombuffer(b,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[x['componentType']],count=x['count']*dims,offset=v.get('byteOffset',0)+x.get('byteOffset',0)).reshape(-1,dims)
p=g['meshes'][0]['primitives'][0];v=a(p['attributes']['POSITION']);tri=v[a(p['indices']).reshape(-1).astype(int)].reshape(-1,3,3)
def hits(x,z):
 aa=tri[:,0];u=tri[:,1]-aa;w=tri[:,2]-aa;det=u[:,0]*w[:,2]-w[:,0]*u[:,2]
 valid=abs(det)>1e-9;dd=np.where(valid,det,1)
 s=((x-aa[:,0])*w[:,2]-(z-aa[:,2])*w[:,0])/dd
 t=(u[:,0]*(z-aa[:,2])-u[:,2]*(x-aa[:,0]))/dd
 mask=valid&(s>=-1e-6)&(t>=-1e-6)&(s+t<=1+1e-6)
 return (aa[:,1]+s*u[:,1]+t*w[:,1])[mask]
# Scale 10-metre authored height to 90 studs; centre the physical torso over deck.
scale=9.;candidates=[]
for z in np.linspace(-5,5,201):
 ys=[hits(-x/scale,z-dz/scale) for x,dz in [(-7,-5),(-7,5),(7,-5),(7,5)]]
 if any(len(y)<2 for y in ys):continue
 # Prefer a thick section with four comparable underside contacts over thin fins.
 thickness=min(float(y.max()-y.min()) for y in ys)
 bottom=np.array([y.min() for y in ys]);score=thickness-bottom.std()*.6
 candidates.append((score,z,bottom))
assert candidates,'No four-cable contact region found'
_,z,bottom=max(candidates,key=lambda c:c[0])
base_y=66-float(bottom.mean())*scale
cables=[]
for (x,dz),y in zip([(-7,-5),(-7,5),(7,-5),(7,5)],bottom):
 top=base_y+float(y)*scale+1.2
 assert top>45
 cables.append([6000+x,dz,16.5,top])
out=R/'assets/meshes/meshy/LobbyAirship_Source.glb';shutil.copyfile(source,out)
manifest={'source':source.name,'sha256':hashlib.sha256(raw).hexdigest(),'triangles':len(tri),'rigged':False,'geometry':'untouched','height_meters':10,'target_height_studs':90,'source_anchor':[0,0,float(z)],'world_anchor':[6000,base_y,0],'rotation_y_degrees':180,'cables':cables}
out.with_suffix('.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
fmt=lambda xs:'{'+','.join(str(float(x)) for x in xs)+'}'
(R/'src/authoring/MeshyAirshipData.luau').write_text('return {Height=90,SourceHeight=10,SourceAnchor='+fmt([0,0,z])+',WorldAnchor='+fmt([6000,base_y,0])+',Cables={'+','.join(fmt(c) for c in cables)+'}}\n',encoding='utf-8')
print('AIRSHIP_PASS:',len(tri),'triangles; source byte-identical; four underside intersections; cable tops',bottom*scale+base_y)
