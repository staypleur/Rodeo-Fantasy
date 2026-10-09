"""Embed approved lineage into body, legs, ears and tail animation batches."""
from pathlib import Path
import json, struct, io, argparse
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
fmt=lambda a:'{'+','.join(f'{float(x):.8g}' for x in a)+'}'
stages=[]
parser=argparse.ArgumentParser();parser.add_argument('--boar',action='store_true');args=parser.parse_args()
for stage in (1,3,6,9):
 path=R/'dist/ReviewModels'/(f'BrambleBoar_S{stage}_FacetedReview.glb' if args.boar else 'MeadowMouse_A_S1_FacetedReview.glb' if stage==1 else f'Mossrat_S{stage}_FacetedReview.glb')
 b=path.read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n]);binary=b[28+n:]
 def val(i):
  a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];d={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
  return np.frombuffer(binary,dtype={5126:'<f4',5123:'<u2'}[a['componentType']],count=a['count']*d,offset=v.get('byteOffset',0)).reshape(a['count'],d)
 v=g['bufferViews'][g['images'][0]['bufferView']];im=Image.open(io.BytesIO(binary[v['byteOffset']:v['byteOffset']+v['byteLength']])).convert('RGB')
 groups={};nodes={}
 for node in g['nodes']:
  p=g['meshes'][node['mesh']]['primitives'][0];pos=val(p['attributes']['POSITION']);norm=val(p['attributes']['NORMAL']);uv=val(p['attributes']['TEXCOORD_0']);ids=val(p['indices']).flatten()
  name=node['name'];nodes[name]=pos
  group=name if name in ('LeftFrontLeg','RightFrontLeg','LeftBackLeg','RightBackLeg') else 'Body'
  if name.startswith('LeftEar'):group='LeftEar'
  elif name.startswith('RightEar'):group='RightEar'
  elif name.startswith('Tail'):group='Tail'
  elif name.endswith('ToeSplit'):group=name.replace('ToeSplit','Leg')
  groups.setdefault(group,[]).append(np.concatenate((pos[ids],norm[ids],uv[ids]),axis=1))
 ground=min(nodes[name][:,1].min() for name in nodes if name.endswith('Leg'))
 stages.append((stage,groups,ground,nodes,im))
def encode(atlas):
 pixels=list(atlas.getdata());runs=[];start=0
 while start<len(pixels):
  end=start+1
  while end<len(pixels) and end-start<65535 and pixels[end]==pixels[start]:end+=1
  runs.append(f'{end-start:04x}'+''.join(f'{x:02x}' for x in pixels[start]));start=end
 return ''.join(runs)
atlas=stages[-1][-1]
for stage,groups,ground,nodes,im in stages:
 if stage==1:continue
 for arrays in groups.values():
  for uv in np.concatenate(arrays)[:,6:]:
   x=min(1023,int(uv[0]*1024));y=min(1023,int((1-uv[1])*1024))
   assert im.getpixel((x,y))==atlas.getpixel((x,y)),f'palette changed at stage {stage}'
images=((1,stages[0][-1]),) if args.boar else ((1,stages[0][-1]),(3,atlas))
lines=['-- Approved meshes with retained atlases and eight animation batches.',
 'return {ImageSize=1024,Images={',[f'[{key}]=[[{encode(im)}]],' for key,im in images],' },Stages={']
lines=[item for line in lines for item in (line if isinstance(line,list) else [line])]
for stage,groups,ground,nodes,im in stages:
 count=sum(len(a)//3 for arrays in groups.values() for a in arrays)
 revision='BrambleBoar-Connected-v1' if args.boar else 'Mossrat-Lineage-v1'
 lines.append(f'[{stage}]={{Revision="{revision}-S{stage}",ImageKey={1 if args.boar or stage==1 else 3},GroundY={ground:.9g},Triangles={count},Parts={{')
 for name,arrays in groups.items():
  a=np.concatenate(arrays);low=a[:,:3].min(axis=0);high=a[:,:3].max(axis=0);center=(low+high)/2
  pivot=center.copy()
  if name.endswith('Ear'):pivot[1]=low[1]
  if name=='Tail':pivot[2]=low[2]
  a[:,:3]-=center
  lines.append('{Name='+json.dumps(name)+',Center='+fmt(center)+',Pivot='+fmt(pivot)+',Vertices={')
  lines.extend(fmt(row)+',' for row in a);lines.append('}},')
 lines.append('}},')
 print(f'STAGE {stage}: {count} triangles / {len(groups)} batches / body top {nodes["Body"][:,1].max()-ground:.6f}')
lines.append('}}')
target=R/'src/client'/('FacetedBoarData.luau' if args.boar else 'FacetedMouseData.luau');target.write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('LINEAGE_EMBED_PASS: original baby atlas, shared growth atlas, eight animation batches per stage')
