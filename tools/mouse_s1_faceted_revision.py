"""Build a review-only, flat shaded mouse with an embedded painted color atlas.

No subdivision, implicit surface, smoothing, external character asset or game install.
"""
from pathlib import Path
import math, json, struct, io
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'dist/ReviewModels'
ART=ROOT/'assets/meshes/review'
STEM='MeadowMouse_A_S1_FacetedReview'
OUT.mkdir(parents=True,exist_ok=True);ART.mkdir(parents=True,exist_ok=True)
SIZE=1024;TILE=256
# Atlas coordinates use glTF's top-left texture convention.
tiles={'Fur':(0,0),'Head':(1,0),'Ear':(2,0),'Eye':(3,0),
       'Cream':(0,1),'Leaf':(1,1),'Mouth':(2,1),'Pink':(3,1),
       'Dark':(0,2),'Ivory':(1,2)}
tea=np.array((239,194,168));ivory=np.array((255,239,207))
def blend(a,b,t):return np.array(a)*(1-t)+np.array(b)*t
def paint(kind,u,v):
 if kind=='Fur':return blend((220,162,136),(251,216,182),.25+.75*(1-v))
 if kind=='Cream':return blend((239,213,180),(255,243,217),1-v)
 if kind=='Ivory':return np.array((255,244,218))
 if kind=='Pink':return blend((215,104,124),(252,171,183),1-v)
 if kind=='Dark':return np.array((57,31,29))
 if kind=='Head':
  # Cylindrical UV unwrap of the faceted head: front at u=.5.
  theta=(u-.5)*math.tau;x=math.sin(theta)*1.02;y=1.48-v*1.7
  front=max(0,math.cos(theta))**4
  cream=front*math.exp(-((x/.85)**4+((y-.28)/.75)**4)*1.2)
  color=blend(blend(tea,(254,220,186),.3*(1-v)),ivory,cream)
  blush=front*.45*(math.exp(-((abs(x)-.68)/.22)**2-((y-.30)/.24)**2)
                    +.55*math.exp(-((abs(x)-.52)/.25)**2-((y-.78)/.33)**2))
  return blend(color,(249,151,164),min(.65,blush))
 if kind=='Ear':
  # u/v coordinates across the entire shallow bowl, not individual flat rings.
  return blend((248,214,188),(244,144,168),max(0,min(1,(1-v)*1.1)))
 if kind=='Leaf':
  base=blend((64,140,68),(179,220,65),max(0,min(1,1-v)))
  edge=min(1,(abs(u-.5)*2)**5)*.35
  color=blend(base,(240,222,83),edge)
  vein=.17*math.exp(-((u-.5)/.055)**2)
  return blend(color,(231,238,124),vein)
 if kind=='Eye':
  x=(u-.5)*2;y=(v-.5)*2
  radius=math.sqrt((x/.84)**2+(y/1.02)**2)
  gold=max(0,min(1,(v-.25)/.65))
  color=blend((94,42,27),(255,180,42),gold)
  if radius>.84:color=np.array((47,24,25))
  if (x/.31)**2+((y+.08)/.76)**2<1:color=np.array((35,23,29))
  # Large crisp main highlight, small reflected highlight and lower jewel glow.
  if ((x+.25)/.26)**2+((y+.46)/.24)**2<1:color=np.array((255,253,231))
  if ((x-.32)/.10)**2+((y-.35)/.12)**2<1:color=np.array((255,242,185))
  if .54<y<.76 and abs(x)<.40:color=blend(color,(255,216,92),.42)
  return color
 if kind=='Mouth':
  x=(u-.5)*2;y=(v-.5)*2;color=np.array((87,36,43))
  if ((x/.74)**2+((y-.5)/.52)**2)<1:color=np.array((249,139,158))
  if v<.18:color=np.array((255,238,207))
  return color
 raise ValueError(kind)
atlas=np.full((SIZE,SIZE,3),(255,239,207),dtype=np.uint8)
for kind,(tx,ty) in tiles.items():
 for py in range(TILE):
  for px in range(TILE):atlas[ty*TILE+py,tx*TILE+px]=np.clip(paint(kind,px/(TILE-1),py/(TILE-1)),0,255)
texture=Image.fromarray(atlas)
texture_path=ART/(STEM+'_BaseColor.png');texture.save(texture_path)

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
# A short bevelled torso, four tapering angular legs; no ball joints.
loft('Body',[((0,-.20,-.84),.65,.59),((0,-.10,-.35),.93,.71),((0,-.09,.68),.94,.70),((0,-.23,1.27),.62,.53)],sides=8)
for sg,side in ((-1,'Left'),(1,'Right')):
 for z,label in ((-.59,'Front'),(.87,'Back')):
  m=mesh(side+label+'Leg');rings=[]
  for y,w,depth,forward in ((-.45,.30,.29,0),(-1.01,.24,.25,-.03),(-1.28,.32,.39,-.13)):
   rings.append([np.array((sg*.62+dx*w,y,z+forward+dz*depth)) for dx,dz in ((-1,-1),(1,-1),(1,1),(-1,1))])
  for i in range(2):
   for j in range(4):
    k=(j+1)%4;quad(m,[rings[i][j],rings[i][k],rings[i+1][k],rings[i+1][j]],[(0,0),(1,0),(1,1),(0,1)],'Cream' if i==1 else 'Fur',rings[i][j]-np.array((sg*.62,-.45,z)))
  quad(m,rings[-1],[(0,0),(1,0),(1,1),(0,1)],'Cream',(0,-1,0))

# Angular cheek silhouette and defined chin. Ten sides, five ring heights.
profiles=[(-.20,.34,.33),(.08,.80,.61),(.43,1.06,.73),(.94,.99,.69),(1.29,.72,.53),(1.48,.28,.27)]
def head_point(theta,y,rx,rz):return np.array((math.sin(theta)*rx,y,-1.18-math.cos(theta)*rz))
head=mesh('Head');rows=[];N=12
for y,rx,rz in profiles:rows.append([head_point((j/N-.5)*math.tau,y,rx,rz) for j in range(N)])
for i in range(len(rows)-1):
 for j in range(N):
  k=(j+1)%N;coords=[(j/N,(1.48-profiles[i][0])/1.7),((j+1)/N,(1.48-profiles[i][0])/1.7),((j+1)/N,(1.48-profiles[i+1][0])/1.7),(j/N,(1.48-profiles[i+1][0])/1.7)]
  p=[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]]
  quad(head,p,coords,'Head',np.mean(p,axis=0)-np.array((0,.65,-1.18)))
for i,hint in ((0,(0,-1,0)),(-1,(0,1,0))):
 for j in range(N):tri(head,[(0,profiles[i][0],-1.18),rows[i][j],rows[i][(j+1)%N]],[(.5,.5),(j/N,.1),((j+1)/N,.1)],'Head',hint)
def face_z(x,y):
 # Intersect the exact polygonal head cross section, rather than an invisible sphere.
 for i in range(len(profiles)-1):
  if profiles[i][0]<=y<=profiles[i+1][0]:
   t=(y-profiles[i][0])/(profiles[i+1][0]-profiles[i][0]);rx=(1-t)*profiles[i][1]+t*profiles[i+1][1];rz=(1-t)*profiles[i][2]+t*profiles[i+1][2];break
 else:raise ValueError((x,y))
 front=[head_point(j*math.pi/6,y,rx,rz) for j in range(-3,4)]
 for a,b in zip(front,front[1:]):
  if a[0]-1e-6<=x<=b[0]+1e-6:return float(a[2]+(b[2]-a[2])*(x-a[0])/(b[0]-a[0]))
 raise ValueError((x,y,rx))
def face_patch(name,points,kind,depth=.024):
 m=mesh(name);xmin=min(p[0] for p in points);xmax=max(p[0] for p in points);ymin=min(p[1] for p in points);ymax=max(p[1] for p in points)
 # These are flat planes sitting just over a face facet. Not protruding eye balls.
 cx=(xmin+xmax)/2;cy=(ymin+ymax)/2
 center=np.array((cx,cy,face_z(cx,cy)-depth));slope=(face_z(cx+.015,cy)-face_z(cx-.015,cy))/.03
 verts=[np.array((x,y,center[2]+slope*(x-cx))) for x,y in points]
 for j in range(1,len(verts)-1):
  ids=[0,j,j+1];tri(m,[verts[k] for k in ids],[((points[k][0]-xmin)/(xmax-xmin),1-(points[k][1]-ymin)/(ymax-ymin)) for k in ids],kind,(0,0,-1))
 return m
for sg,side in ((-1,'Left'),(1,'Right')):
 # Shallow, large octagonal cup with a real recessed inner surface and back cap.
 m=mesh(side+'Ear');center=np.array((sg*1.08,1.50,-1.07));angle=math.radians(-sg*18)
 def ear(rx,ry,z):
  row=[]
  for j in range(8):
   a=math.tau*j/8;x=rx*math.cos(a);y=ry*math.sin(a)
   row.append(center+np.array((x*math.cos(angle)-y*math.sin(angle),x*math.sin(angle)+y*math.cos(angle),z)))
  return row
 back=ear(.71,.88,.085);outer=ear(.74,.91,-.095);rim=ear(.59,.75,-.13);inner=ear(.46,.59,.035)
 def coords(p):return ((p[0]-center[0])/(1.6)+.5,.5-(p[1]-center[1])/1.9)
 for j in range(8):
  k=(j+1)%8
  for a,b,kind in ((back,outer,'Fur'),(outer,rim,'Cream'),(rim,inner,'Ear')):
   quad(m,[a[j],a[k],b[k],b[j]],[coords(q) for q in (a[j],a[k],b[k],b[j])],kind,(0,0,-1) if kind!='Fur' else a[j]-center)
  tri(m,[center+np.array((0,0,.06)),inner[j],inner[k]],[(.5,.5),coords(inner[j]),coords(inner[k])],'Ear',(0,0,-1))
  tri(m,[center+np.array((0,0,.09)),back[k],back[j]],[(.5,.5),(.1,.1),(.9,.9)],'Fur',(0,0,1))
 # Three small faceted tufts anchored inside each ear; separate low-poly geometry.
 fur=mesh(side+'EarFur')
 for j in (-1,0,1):
  x=center[0]+j*.17;y=center[1]-.36;z=-1.225
  p=[(x-.13,y-.13,z),(x+.13,y-.13,z),(x+.09,y+.04,z-.05),(x+j*.045,y+.22,z+.025),(x-.09,y+.04,z-.05)]
  for k in range(1,4):tri(fur,[p[0],p[k],p[k+1]],[(0,1),(.5,0),(1,1)],'Ivory',(0,0,-1))
 # Mirror a tilted almond silhouette; outer corner is raised but expression stays friendly.
 points=[(sg*(.49-.23),.72),(sg*(.49-.17),.97),(sg*(.49+.18),1.02),(sg*(.49+.27),.92),(sg*(.49+.17),.53),(sg*(.49-.11),.52)]
 face_patch(side+'Eye',points,'Eye',.055)
 # Defined ivory cheek tufts maintain the original A baby identity.
 face_patch(side+'Cheek',[(sg*.28,.35),(sg*.60,.41),(sg*.87,.29),(sg*.73,.19),(sg*.79,.13),(sg*.52,.11)],'Cream',.029)
face_patch('Nose',[(-.12,.48),(.12,.48),(.10,.39),(0,.34),(-.10,.39)],'Pink',.04)
face_patch('OpenSmile',[(-.27,.25),(-.12,.27),(0,.21),(.12,.27),(.27,.25),(.19,.06),(0,-.025),(-.19,.06)],'Mouth',.052)

def leaf(name,root,direction,length,width,thickness=.095,clover=False):
 m=mesh(name);base=np.array(root,float);axis=np.array(direction,float);axis/=np.linalg.norm(axis)
 side=np.cross(axis,(0,0,1))
 if np.linalg.norm(side)<.1:side=np.cross(axis,(0,1,0))
 side/=np.linalg.norm(side);normal=np.cross(side,axis);normal/=np.linalg.norm(normal)
 # A tidy pointed diamond with a raised central vein and actual edge thickness.
 tip=base+axis*length;middle=base+axis*length*.45
 outline=[(0,0),(-.5,.45),(0,1),(.5,.45)]
 if clover:outline=[(0,0),(-.42,.46),(-.50,.78),(-.25,1),(0,.82),(.25,1),(.50,.78),(.42,.46)]
 verts=[base+side*x*width+axis*y*length for x,y in outline]
 coords=[(x+.5,1-y) for x,y in outline];count=len(verts)
 center=middle+normal*thickness
 for j in range(count):tri(m,[verts[j],verts[(j+1)%count],center],[coords[j],coords[(j+1)%count],(.5,.55)],'Leaf',normal)
 underside=[p-normal*thickness*.5 for p in verts]
 for j in range(count):tri(m,[underside[j],underside[(j+1)%count],middle-normal*thickness*.5],[coords[j],coords[(j+1)%count],(.5,.55)],'Leaf',-normal)
 for j in range(count):
  k=(j+1)%count;quad(m,[verts[j],underside[j],underside[k],verts[k]],[coords[j],coords[j],coords[k],coords[k]],'Leaf',verts[j]-middle)
leaf('HeadSproutLeft',(-.10,1.39,-1.18),(-.68,.74,.1),.78,.49)
leaf('HeadSproutRight',(.08,1.43,-1.17),(.57,.82,.03),.94,.52)
for sg in (-1,1):
 for i in range(3):leaf('NeckLeaf'+str(sg)+'_'+str(i),(sg*(.27+i*.16),.11+i*.12,-.74),(sg*(.6+i*.10),-.66,.2),.60,.35,.075)
# A segmented angular curve, not a chain of detached spheres.
tail=mesh('Tail');centers=[(0,-.02,1.24),(.68,.06,1.72),(1.18,.42,2.01),(1.18,1.03,2.12),(.98,1.42,2.07)];rings=[]
for i,c in enumerate(centers):
 tangent=np.array(centers[min(i+1,4)])-np.array(centers[max(i-1,0)]);tangent/=np.linalg.norm(tangent)
 right=np.cross(tangent,(0,1,0));right/=np.linalg.norm(right);up=np.cross(tangent,right)
 rings.append([np.array(c)+.065*(math.cos(j*math.tau/5)*right+math.sin(j*math.tau/5)*up) for j in range(5)])
for i in range(4):
 for j in range(5):
  k=(j+1)%5;quad(tail,[rings[i][j],rings[i][k],rings[i+1][k],rings[i+1][j]],[(0,0),(1,0),(1,1),(0,1)],'Fur',rings[i][j]-np.array(centers[i]))
for j in range(4):
 a=j*math.tau/4;leaf('TailClover'+str(j),centers[-1],(math.sin(a),math.cos(a),.03),.62,.48,.065,clover=True)

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
gltf={'asset':{'version':'2.0','generator':'Rodeo Planeture faceted review mesh'},'scene':0,'scenes':[{'nodes':list(range(len(nodes)))}],'nodes':nodes,'meshes':gmeshes,
 'materials':[{'name':'PaintedTeaFantasy','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'baseColorTexture':{'index':0},'metallicFactor':0,'roughnessFactor':.9}}],
 'images':[{'bufferView':tex_view,'mimeType':'image/png'}],'textures':[{'source':0,'sampler':0}],'samplers':[{'magFilter':9729,'minFilter':9729,'wrapS':33071,'wrapT':33071}],
 'buffers':[{'byteLength':len(blob)}],'bufferViews':views,'accessors':accessors,
 'extras':{'reviewOnly':True,'triangleBudget':2000,'flatShaded':True,'forward':'-Z','texture':'embedded 1024x1024 base color','rigged':False}}
assert tri_count<2000,(tri_count,'triangle budget exceeded')
j=json.dumps(gltf,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
while len(blob)%4:blob.append(0)
glb=struct.pack('<4sII',b'glTF',2,28+len(j)+len(blob))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(blob),b'BIN\0')+blob
(OUT/(STEM+'.glb')).write_bytes(glb)
# UV mapped OBJ/MTL for editing in a modelling tool; OBJ's V points upward.
lines=[f'mtllib {STEM}.mtl','s off'];offset=1
for m in meshes:
 lines.extend((f'o {m["name"]}','usemtl PaintedTeaFantasy'))
 lines.extend('v '+' '.join(f'{v:.6f}' for v in p) for p in m['p'])
 lines.extend(f'vt {u:.6f} {1-v:.6f}' for u,v in m['uv'])
 lines.extend('vn '+' '.join(f'{v:.6f}' for v in n) for n in m['n'])
 for i in range(0,len(m['ids']),3):lines.append('f '+' '.join(f'{idx+offset}/{idx+offset}/{idx+offset}' for idx in m['ids'][i:i+3]))
 offset+=len(m['p'])
(ART/(STEM+'.obj')).write_text('\n'.join(lines)+'\n',encoding='utf-8')
(ART/(STEM+'.mtl')).write_text(f'newmtl PaintedTeaFantasy\nKd 1 1 1\nmap_Kd {texture_path.name}\n',encoding='utf-8')
print(f'REVIEW_ONLY: {tri_count} flat triangles, {len(nodes)} nodes, embedded painted atlas; no rig or game install')
