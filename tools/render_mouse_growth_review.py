"""Render all four real growth meshes with one camera and one physical scale."""
from pathlib import Path
import io,json,struct,subprocess,sys,argparse
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--equal-height',action='store_true')
parser.add_argument('--silhouette',action='store_true')
parser.add_argument('--avatar-reference',action='store_true')
args=parser.parse_args()
def load(path):
 data=path.read_bytes();size=struct.unpack_from('<I',data,12)[0]
 doc=json.loads(data[20:20+size]);binary=data[28+size:]
 def read(i):
  a=doc['accessors'][i];view=doc['bufferViews'][a['bufferView']]
  return np.frombuffer(binary,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']],count=a['count']*{'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']],offset=view.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],-1)
 view=doc['bufferViews'][doc['images'][0]['bufferView']]
 texture=np.array(Image.open(io.BytesIO(binary[view['byteOffset']:view['byteOffset']+view['byteLength']])).convert('RGB'))
 triangles=[];body_positions=[]
 for node in doc['nodes']:
  for p in doc['meshes'][node['mesh']]['primitives']:
   pos,uv,norm=[read(p['attributes'][a]) for a in ('POSITION','TEXCOORD_0','NORMAL')]
   if node['name'] in ('Head','Body','ShoulderChest') or 'Leg' in node['name'] or 'Ear' in node['name']:body_positions.append(pos)
   for indices in read(p['indices']).reshape(-1,3):triangles.append((pos[indices],uv[indices],norm[indices[0]]))
 return triangles,texture,np.concatenate(body_positions)
models=[];eye=np.array((.63,.16,-1.));eye/=np.linalg.norm(eye)
if args.avatar_reference:
 assert not args.equal_height
 eye=np.array((0.,0.,-1.)) # exact vertical size comparison, no perspective distortion
right=np.cross(eye,(0,1,0));right/=np.linalg.norm(right);up=np.cross(right,eye)
for stage in (1,3,6,9):
 path=R/('dist/ReviewModels/MeadowMouse_A_S1_FacetedReview.glb' if stage==1 else f'dist/ReviewModels/Mossrat_S{stage}_FacetedReview.glb')
 tris,texture,body_positions=load(path);positions=np.concatenate([t[0] for t in tris]);projection=np.stack((positions@right,positions@up),axis=-1)
 models.append(dict(stage=stage,tris=tris,texture=texture,low=projection.min(0),high=projection.max(0),bodyHeight=float(np.ptp(body_positions@up)),height=float(np.ptp(positions[:,1]))))
if args.avatar_reference:
 tris=[]
 def block(center,size):
  corners=np.array([(x,y,z) for x in (-.5,.5) for y in (-.5,.5) for z in (-.5,.5)])*size+center
  for face in ((0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)):
   for ids in ((face[0],face[1],face[2]),(face[0],face[2],face[3])):
    pos=corners[list(ids)];normal=np.cross(pos[1]-pos[0],pos[2]-pos[0]);normal/=np.linalg.norm(normal)
    tris.append((pos,np.zeros((3,2)),normal))
 for i in range(3):
  y=i*5
  for center,size in (((0,4.5+y,0),(1,1,1)),((0,3+y,0),(2,2,1)),((-1.5,3+y,0),(1,2,1)),((1.5,3+y,0),(1,2,1)),((-.5,1+y,0),(1,2,1)),((.5,1+y,0),(1,2,1))):block(np.array(center),np.array(size))
 pos=np.concatenate([t[0] for t in tris]);proj=np.stack((pos@right,pos@up),axis=-1)
 models.insert(3,dict(stage=0,tris=tris,texture=np.array([[[100,137,150]]],dtype=np.uint8),low=proj.min(0),high=proj.max(0),bodyHeight=15.,height=15.))
W,H=2048,790;margin=54;gap=1.0
scale=min((W-margin*2)/(sum(m['high'][0]-m['low'][0] for m in models)+gap*(len(models)-1)),590/max(m['high'][1]-m['low'][1] for m in models))
frame=np.full((H,W,3),(249,242,226),dtype=np.uint8);depth=np.full((H,W),-np.inf)
light=np.array((-.35,.75,-.65));light/=np.linalg.norm(light)
slot_widths=[max(220,(m['high'][0]-m['low'][0])*scale) for m in models]
layout_width=sum(slot_widths)+gap*scale*(len(models)-1)
if not args.equal_height:
 while layout_width>W-margin*2:
  scale*=.98
  slot_widths=[max(220,(m['high'][0]-m['low'][0])*scale) for m in models]
  layout_width=sum(slot_widths)+gap*scale*(len(models)-1)
xstart=(W-layout_width)/2;baseline=H-90;labels=[]
normalized_height=min(min(530*m['bodyHeight']/(m['high'][1]-m['low'][1]),450*m['bodyHeight']/(m['high'][0]-m['low'][0])) for m in models)
for index,m in enumerate(models):
 if args.equal_height:
  scale=normalized_height/m['bodyHeight']
  xstart=index*512+(512-(m['high'][0]-m['low'][0])*scale)/2
 width=(m['high'][0]-m['low'][0])*scale
 slot=width if args.equal_height else slot_widths[index]
 draw_start=xstart+(slot-width)/2
 labels.append((xstart+slot/2,m));texture=m['texture']
 for pos,uv,normal in m['tris']:
  sx=(pos@right-m['low'][0])*scale+draw_start;sy=baseline-(pos@up-m['low'][1])*scale;z=pos@eye
  x0=max(0,int(np.floor(sx.min())));x1=min(W-1,int(np.ceil(sx.max())))
  y0=max(0,int(np.floor(sy.min())));y1=min(H-1,int(np.ceil(sy.max())))
  if x0>x1 or y0>y1:continue
  denom=(sy[1]-sy[2])*(sx[0]-sx[2])+(sx[2]-sx[1])*(sy[0]-sy[2])
  if abs(denom)<1e-8:continue
  yy,xx=np.mgrid[y0:y1+1,x0:x1+1];xx=xx+.5;yy=yy+.5
  a=((sy[1]-sy[2])*(xx-sx[2])+(sx[2]-sx[1])*(yy-sy[2]))/denom
  b=((sy[2]-sy[0])*(xx-sx[2])+(sx[0]-sx[2])*(yy-sy[2]))/denom;c=1-a-b
  zz=a*z[0]+b*z[1]+c*z[2];old=depth[y0:y1+1,x0:x1+1];mask=(a>=-1e-5)&(b>=-1e-5)&(c>=-1e-5)&(zz>old)
  if not mask.any():continue
  tuv=a[...,None]*uv[0]+b[...,None]*uv[1]+c[...,None]*uv[2]
  tx=np.clip((tuv[...,0]*texture.shape[1]).astype(int),0,texture.shape[1]-1);ty=np.clip((tuv[...,1]*texture.shape[0]).astype(int),0,texture.shape[0]-1)
  rgb=np.zeros_like(texture[ty,tx]) if args.silhouette else np.clip(texture[ty,tx]*(.88+.12*max(0,np.dot(normal,light))),0,255).astype(np.uint8)
  old[mask]=zz[mask];frame[y0:y1+1,x0:x1+1][mask]=rgb[mask]
 xstart+=slot+gap*scale
image=Image.fromarray(frame);draw=ImageDraw.Draw(image)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28);small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
draw.text((28,16),'MOSSRAT / DISTINCT EVOLUTIONS / '+('SILHOUETTES' if args.silhouette else 'ACTUAL 3D'),font=font,fill=(60,43,29))
draw.text((28,56),('Body height normalized (excluding crowns and tails), NOT actual size.' if args.equal_height else 'One camera and one shared scale.')+' Original baby unchanged. Review only, not installed.',font=small,fill=(105,86,63))
if args.avatar_reference:draw.text((28,90),'REFERENCE: three illustrative 5-stud avatars = 15 studs, measured to the elder head (crown excluded).',font=small,fill=(105,86,63))
if args.avatar_reference:
 reference_y=baseline-15*scale
 a=labels[3][0];b=labels[4][0]+slot_widths[4]/2
 for x in range(int(a),int(b),16):draw.line((x,reference_y,min(x+8,b),reference_y),fill=(138,105,61),width=2)
 draw.text((a-15,reference_y-25),'15 studs',font=small,fill=(105,86,63),anchor='rt')
for center,m in labels:
 if m['stage']==0:
  draw.text((center,baseline+15),'3 PLAYERS',font=font,fill=(71,52,30),anchor='mt')
  draw.text((center,baseline+48),'5 + 5 + 5 = 15 studs',font=small,fill=(105,86,63),anchor='mt')
  continue
 role={1:'BABY',3:'TEEN',6:'ADULT',9:'ELDER'}[m['stage']]
 draw.text((center,baseline+15),f'{m["stage"]} STAR / {role}',font=font,fill=(71,52,30),anchor='mt')
 draw.text((center,baseline+48),f'{len(m["tris"])} triangles',font=small,fill=(105,86,63),anchor='mt')
suffix='giant-comparison' if args.avatar_reference else 'silhouettes' if args.silhouette else 'equal-height' if args.equal_height else 'faceted-review'
out=R/f'assets/previews/mossrat-growth-{suffix}.png';image.save(out)
report={'bodyDisplayHeight':normalized_height} if args.equal_height else {'sharedPixelsPerUnit':scale,'stages':[{k:m[k] for k in ('stage','height')} for m in models]}
stages=[m for m in models if m['stage']!=0]
assert all(stages[i+1]['height']>stages[i]['height'] for i in range(3))
if not args.equal_height and not args.avatar_reference:(R/'assets/previews/mossrat-growth-dimensions.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('GROWTH_NORMALIZED_SHAPE_PASS' if args.equal_height else 'GROWTH_SHARED_SCALE_PASS',report)
if args.equal_height or args.avatar_reference:sys.exit(0)
for stage in (3,6,9):
 subprocess.run([sys.executable,str(R/'tools/render_textured_review.py'),'--model',str(R/f'dist/ReviewModels/Mossrat_S{stage}_FacetedReview.glb'),'--output',str(R/f'assets/previews/mossrat-s{stage}-faceted-review.png'),'--title',f'MOSSRAT {stage} STAR / AGE REFINEMENT'],check=True,cwd=R)
