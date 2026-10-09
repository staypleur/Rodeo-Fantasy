"""Preserve the approved GLB's triangles/UVs while merging into four motion groups."""
from pathlib import Path
import json,struct,io
import xml.etree.ElementTree as E
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
b=(R/'dist/ReviewModels/SkyWhale_RegalReview.glb').read_bytes();n=struct.unpack_from('<I',b,12)[0]
g=json.loads(b[20:20+n]);binary=b[28+n:]
def val(i):
 a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];d={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
 return np.frombuffer(binary,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']],count=a['count']*d,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],d)
groups={k:[] for k in ('Body','LeftFin','RightFin','Tail')};body=None
for node in g['nodes']:
 p=g['meshes'][node['mesh']]['primitives'][0];ids=val(p['indices']).flatten()
 vertices=np.concatenate([val(p['attributes'][k])[ids] for k in ('POSITION','NORMAL','TEXCOORD_0')],axis=1)
 name=node['name'];group='Body'
 if 'TailFluke' in name:group='Tail'
 elif any(k in name for k in ('PectoralFin','RearCurrentFin','FinCurrent','FinInlay')):group='LeftFin' if name.startswith('Left') else 'RightFin'
 groups[group].append(vertices)
 if name=='WhaleBody':body=vertices[:,:3]
allpos=np.concatenate([v[:,:3] for values in groups.values() for v in values]);center=(allpos.min(0)+allpos.max(0))/2
scale=.85;target=np.array((6000.,95.,0.))
# Align the broad mid-belly (design z=-20), not the ornament/tail bounding box, over the deck.
center[2]=-20*1.25
transform=lambda p:target+(np.asarray(p)-center)*scale
tree=E.parse(R/'dist/RodeoFantasy-JournalBagReview.rbxlx').getroot()
airport=next(x for x in tree.iter('Item') if x.findtext("Properties/string[@name='Name']")=='Airport')
cables=[]
for part in airport.iter('Item'):
 if part.findtext("Properties/string[@name='Name']")!='Cable':continue
 cf=part.find("Properties/CoordinateFrame[@name='CFrame']");pos=np.array([float(cf.findtext(a)) for a in 'XYZ'])
 bottom=pos[1]-float(part.findtext("Properties/Vector3[@name='size']/Y"))/2
 x,z=((pos-target)/scale+center)[[0,2]];hits=[]
 for a,c,d in body.reshape(-1,3,3):
  matrix=np.stack((c[[0,2]]-a[[0,2]],d[[0,2]]-a[[0,2]]),axis=1)
  if abs(np.linalg.det(matrix))<1e-8:continue
  u,v=np.linalg.solve(matrix,np.array((x,z))-a[[0,2]])
  if u>=-1e-6 and v>=-1e-6 and u+v<=1+1e-6:hits.append(a[1]+u*(c[1]-a[1])+v*(d[1]-a[1]))
 assert len(hits)>=2,'cable must intersect actual approved body'
 top=target[1]+(min(hits)-center[1])*scale+1.2
 assert top>bottom+10,'keep whale belly well above boarding deck'
 cables.append([pos[0],pos[2],bottom,top])
assert len(cables)==4
v=g['bufferViews'][g['images'][0]['bufferView']]
im=Image.open(io.BytesIO(binary[v['byteOffset']:v['byteOffset']+v['byteLength']])).convert('RGB');px=list(im.getdata());runs=[];start=0
while start<len(px):
 end=start+1
 while end<len(px) and end-start<65535 and px[end]==px[start]:end+=1
 runs.append(f'{end-start:04x}'+''.join(f'{x:02x}' for x in px[start]));start=end
encoded=''.join(runs);decoded=[]
for i in range(0,len(encoded),10):decoded.extend([tuple(bytes.fromhex(encoded[i+4:i+10]))]*int(encoded[i:i+4],16))
assert decoded==px
fmt=lambda a:'{'+','.join(f'{float(x):.10g}' for x in a)+'}'
lines=['-- Approved RegalReview geometry, lossless texture; four shared motion groups.',
 'return {Revision="SkyWhale-Regal-v2",Triangles=1038,ImageSize=512,Anchor='+fmt(target)+',Cables={'+','.join(fmt(c) for c in cables)+'},ImageRLE=[[',encoded,']],Parts={']
hinges={'LeftFin':(-24,-3,-30),'RightFin':(24,-3,-30),'Tail':(0,2,78)}
count=0
for group,arrays in groups.items():
 verts=np.concatenate(arrays);world=transform(verts[:,:3]);c=(world.min(0)+world.max(0))/2
 lines.append('{Name='+json.dumps(group)+',Center='+fmt(c)+((',Hinge='+fmt(transform(np.array(hinges[group])*1.25))) if group in hinges else '')+',Vertices={')
 for p,v in zip(world,verts):lines.append(fmt([*(p-c),*v[3:]])+',')
 lines.append('}},');count+=len(verts)//3
assert count==1038 and len(groups)==4
lines.append('}}')
(R/'src/client/SkyWhaleData.luau').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('REGAL_EMBED_PASS: unchanged1038 triangles/UV/normals, lossless512 texture, four motion groups, four belly cables;',cables)
