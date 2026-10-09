"""Write flat triangle GLB/OBJ with an embedded atlas for static review."""
from pathlib import Path
import math,json,struct,io
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'dist/ReviewModels'
ART=ROOT/'assets/meshes/review'
OUT.mkdir(parents=True,exist_ok=True);ART.mkdir(parents=True,exist_ok=True)
STEM='Airship_C_FacetedRefinement'
SIZE=512;TILE=128
tiles={'Fur':(0,0),'Cream':(1,0),'Gold':(2,0),'Eye':(3,0),'BlueLight':(0,1),'Crystal':(1,1),'Dark':(2,1),'Ivory':(3,1),'Mouth':(0,2)}
meshes=[]
def mesh(name):
 m={'name':name,'p':[],'uv':[],'n':[],'ids':[]};meshes.append(m);return m
def uv(kind,u,v):
 tx,ty=tiles[kind];pad=4
 return ((tx*TILE+pad+u*(TILE-2*pad))/SIZE,(ty*TILE+pad+v*(TILE-2*pad))/SIZE)
def tri(m,points,coords,kind,normal_hint=None):
 p=np.array(points,float);n=np.cross(p[1]-p[0],p[2]-p[0]);length=np.linalg.norm(n)
 if length<1e-8:return
 if normal_hint is not None and np.dot(n,normal_hint)<0:
  p=p[[0,2,1]];coords=[coords[0],coords[2],coords[1]];n=-n
 n=n/length;start=len(m['p'])
 m['p'].extend(p.tolist());m['uv'].extend(uv(kind,*q) for q in coords)
 m['n'].extend([n.tolist()]*3);m['ids'].extend((start,start+1,start+2))
def quad(m,p,coords,kind,hint=None):
 tri(m,p[:3],coords[:3],kind,hint);tri(m,[p[0],p[2],p[3]],[coords[0],coords[2],coords[3]],kind,hint)
def loft(name,rings,kind='Fur',sides=8):
 # Rings: center xyz, radius x/y. Along the animal's length; bevels are polygons.
 m=mesh(name);rows=[]
 for center,rx,ry in rings:
  rows.append([np.array(center)+np.array((math.cos(math.tau*j/sides)*rx,math.sin(math.tau*j/sides)*ry,0)) for j in range(sides)])
 for i in range(len(rows)-1):
  for j in range(sides):
   k=(j+1)%sides
   shade='Cream' if name=='Body' and j in (5,6) else kind
   quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(j/sides,i/(len(rows)-1)),((j+1)/sides,i/(len(rows)-1)),((j+1)/sides,(i+1)/(len(rows)-1)),(j/sides,(i+1)/(len(rows)-1))],shade,rows[i][j]-np.array(rings[i][0]))
 for index,hint in ((0,(0,0,-1)),(-1,(0,0,1))):
  for j in range(sides):tri(m,[rings[index][0],rows[index][j],rows[index][(j+1)%sides]],[(.5,.5),(.1,.1),(.9,.9)],'Cream' if name=='Body' and index==0 else kind,hint)
 return m

def save(texture):
 global blob,views,accessors,gmeshes,nodes
 texture_path=ART/(STEM+"_basecolor.png")
 texture.save(texture_path)
 # Embed the actual atlas in the GLB; do not rely on importer vertex colors.
 blob=bytearray();views=[];accessors=[];gmeshes=[];nodes=[]
 def data_view(data,target=None):
  while len(blob)%4:blob.append(0)
  idx=len(views);view={'buffer':0,'byteOffset':len(blob),'byteLength':len(data)}
  if target:view['target']=target
  views.append(view);blob.extend(data);return idx
 def accessor(array,kind,component=5126):
  a=np.array(array,dtype='<f4' if component==5126 else '<u2');v=data_view(a.tobytes(),34963 if kind=='SCALAR' else 34962)
  record={'bufferView':v,'componentType':component,'count':len(array),'type':kind}
  if kind=='VEC3':record.update(min=a.min(axis=0).tolist(),max=a.max(axis=0).tolist())
  accessors.append(record);return len(accessors)-1
 tri_count=0
 for m in meshes:
  if not m['ids']:continue
  attrs={'POSITION':accessor(m['p'],'VEC3'),'NORMAL':accessor(m['n'],'VEC3'),'TEXCOORD_0':accessor(m['uv'],'VEC2')}
  index=accessor(m['ids'],'SCALAR',5123);tri_count+=len(m['ids'])//3
  gmeshes.append({'name':m['name'],'primitives':[{'attributes':attrs,'indices':index,'material':0}]});nodes.append({'name':m['name'],'mesh':len(gmeshes)-1})
 png=io.BytesIO();texture.save(png,format='PNG');tex_view=data_view(png.getvalue())
 gltf={'asset':{'version':'2.0','generator':'Rodeo Planeture C airship faceted review'},'scene':0,'scenes':[{'nodes':list(range(len(nodes)))}],'nodes':nodes,'meshes':gmeshes,
  'materials':[{'name':'PaintedCrystalBlue','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'baseColorTexture':{'index':0},'metallicFactor':0,'roughnessFactor':.9}}],
  'images':[{'bufferView':tex_view,'mimeType':'image/png'}],'textures':[{'source':0,'sampler':0}],'samplers':[{'magFilter':9729,'minFilter':9729,'wrapS':33071,'wrapT':33071}],
  'buffers':[{'byteLength':len(blob)}],'bufferViews':views,'accessors':accessors,
  'extras':{'reviewOnly':True,'triangleBudget':2000,'flatShaded':True,'forward':'-Z','texture':'embedded 512x512 base color','rigged':False}}
 assert tri_count<2000,(tri_count,'triangle budget exceeded')
 j=json.dumps(gltf,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
 while len(blob)%4:blob.append(0)
 glb=struct.pack('<4sII',b'glTF',2,28+len(j)+len(blob))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(blob),b'BIN\0')+blob
 (OUT/(STEM+'.glb')).write_bytes(glb)
 # UV mapped OBJ/MTL for editing in a modelling tool; OBJ's V points upward.
 lines=[f'mtllib {STEM}.mtl','s off'];offset=1
 for m in meshes:
  lines.extend((f'o {m["name"]}','usemtl PaintedCrystalBlue'))
  lines.extend('v '+' '.join(f'{v:.6f}' for v in p) for p in m['p'])
  lines.extend(f'vt {u:.6f} {1-v:.6f}' for u,v in m['uv'])
  lines.extend('vn '+' '.join(f'{v:.6f}' for v in n) for n in m['n'])
  for i in range(0,len(m['ids']),3):lines.append('f '+' '.join(f'{idx+offset}/{idx+offset}/{idx+offset}' for idx in m['ids'][i:i+3]))
  offset+=len(m['p'])
 (ART/(STEM+'.obj')).write_text('\n'.join(lines)+'\n',encoding='utf-8')
 (ART/(STEM+'.mtl')).write_text(f'newmtl PaintedCrystalBlue\nKd 1 1 1\nmap_Kd {texture_path.name}\n',encoding='utf-8')
 print(f'REVIEW_ONLY: {tri_count} flat triangles, {len(nodes)} nodes, embedded painted atlas; no rig or game install')
 return tri_count
