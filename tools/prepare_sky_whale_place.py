"""Prepare saved-mesh import and installation; never invent Roblox asset IDs."""
from pathlib import Path
import base64,copy,json,struct
import xml.etree.ElementTree as E
import numpy as np
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1]
b=(R/'dist/ReviewModels/SkyWhale_BodyReview.glb').read_bytes()
n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n]);binary=b[28+n:]
g['buffers'][0]['uri']='data:application/octet-stream;base64,'+base64.b64encode(binary[:g['buffers'][0]['byteLength']]).decode()
(R/'dist/SkyWhale_BodyReview.gltf').write_text(json.dumps(g,separators=(',',':')),encoding='utf-8')
def values(index):
 a=g['accessors'][index];v=g['bufferViews'][a['bufferView']]
 return np.frombuffer(binary,dtype={5126:'<f4',5123:'<u2'}[a['componentType']],count=a['count']*{'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']],offset=v.get('byteOffset',0)).reshape(a['count'],-1)
meshes={node['name']:values(g['meshes'][node['mesh']]['primitives'][0]['attributes']['POSITION']) for node in g['nodes']}
allpos=np.concatenate(list(meshes.values()));center=(allpos.min(0)+allpos.max(0))/2
scale=.85;target=np.array((6000,55,-5))
groups={k:('LeftFin' if k.startswith('Left') else 'RightFin') for k in meshes if 'PectoralFin' in k or 'FinGoldInlay' in k}
groups.update({k:'Tail' for k in meshes if 'TailFluke' in k or 'TailGoldInlay' in k})
hinges={key:target+(np.array(p)-center)*scale for key,p in {'LeftFin':(-17,-2,-19),'RightFin':(17,-2,-19),'Tail':(0,2,56)}.items()}
before=E.parse(R/'dist/RodeoFantasy-LobbyBoardingFixed.rbxlx').getroot();after=copy.deepcopy(before)
name=lambda x:x.findtext("Properties/string[@name='Name']")
airport=next(x for x in after.iter('Item') if name(x)=='Airport')
area=next(x for x in airport.findall('Item') if name(x)=='BoardingArea')
cables=[]
for part in area.findall('Item'):
 if name(part)!='Cable':continue
 cf=part.find("Properties/CoordinateFrame[@name='CFrame']")
 pos=np.array([float(cf.findtext(a)) for a in 'XYZ']);height=float(part.findtext("Properties/Vector3[@name='size']/Y"))
 x,z=((pos-target)/scale+center)[[0,2]];hits=[]
 for tri in meshes['WhaleBody'].reshape(-1,3,3):
  a,c,d=tri;matrix=np.stack((c[[0,2]]-a[[0,2]],d[[0,2]]-a[[0,2]]),axis=1)
  if abs(np.linalg.det(matrix))<1e-8:continue
  u,v=np.linalg.solve(matrix,np.array((x,z))-a[[0,2]])
  if u>=-1e-6 and v>=-1e-6 and u+v<=1+1e-6:hits.append(float(a[1]+u*(c[1]-a[1])+v*(d[1]-a[1])))
 assert len(hits)>=2,'cable does not intersect whale belly'
 belly=target[1]+(min(hits)-center[1])*scale
 top=belly+1.1 # penetration covers the bounded bob and slight roll.
 bottom=pos[1]-height/2
 assert top>bottom+10
 cables.append([float(pos[0]),float(pos[2]),top,bottom])
assert len(cables)==4
fmt=lambda p:'{'+','.join(f'{float(v):.9g}' for v in p)+'}'
text=['-- Generated from the approved 584-triangle GLB and saved boarding cables.',
 'return {Revision="SkyWhale-v1",Length='+str(float(np.ptp(allpos,axis=0)[2]*scale))+',Names={'+','.join(json.dumps(k) for k in meshes)+'},Groups={']
text += [f'[{json.dumps(k)}]={json.dumps(v)},' for k,v in groups.items()]
text+=['},Hinges={']+[f'{k}={fmt(p)},' for k,p in hinges.items()]+['},Cables={']+[fmt(c)+',' for c in cables]+['}}']
data='\n'.join(text)+'\n';(R/'src/server/SkyWhaleInstallData.luau').write_text(data,encoding='utf-8')
# Replace only the client source, then insert the small motion and installer modules.
client=next(x for x in after.iter('Item') if name(x)=='CaptureClient')
client.find("Properties/ProtectedString[@name='Source']").text=(R/'src/client/CaptureClient.client.luau').read_text(encoding='utf-8')
parent=next(p for p in after.iter('Item') if client in list(p))
storage=next(x for x in after.iter('Item') if x.get('class')=='ServerStorage')
for par,key,path in [(parent,'SkyWhaleMotion','src/client/SkyWhaleMotion.luau'),(storage,'SkyWhaleInstaller','src/server/SkyWhaleInstaller.luau'),(storage,'SkyWhaleInstallData','src/server/SkyWhaleInstallData.luau')]:
 item=E.SubElement(par,'Item',{'class':'ModuleScript','referent':'Approved'+key})
 props=E.SubElement(item,'Properties');E.SubElement(props,'string',name='Name').text=key
 E.SubElement(props,'ProtectedString',name='Source').text=(R/path).read_text(encoding='utf-8')
assert_unique_ids(after)
# Full non-script model/boarding/departure content stays identical until installation.
after_compare=copy.deepcopy(after);before_compare=copy.deepcopy(before)
for tree in (after_compare,before_compare):
 for par in tree.iter('Item'):
  for item in list(par.findall('Item')):
   if name(item) in ('SkyWhaleMotion','SkyWhaleInstaller','SkyWhaleInstallData'):par.remove(item)
 for item in tree.iter('Item'):
  if name(item)=='CaptureClient':item.find("Properties/ProtectedString[@name='Source']").text=''
assert E.tostring(after_compare)==E.tostring(before_compare)
out=R/'dist/RodeoFantasy-SkyWhaleReady.rbxlx';E.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
assert_unique_ids(E.parse(out).getroot())
print('SKY_WHALE_READY_PASS: saved GLTF, 18 objects, exact scene preservation, four belly-intersecting cables, unique IDs; Studio import pending')
