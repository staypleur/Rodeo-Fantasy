"""Render all four real growth meshes with one camera and one physical scale."""
from pathlib import Path
import io,json,struct,subprocess,sys
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
def load(path):
 data=path.read_bytes();size=struct.unpack_from('<I',data,12)[0]
 doc=json.loads(data[20:20+size]);binary=data[28+size:]
 def read(i):
  a=doc['accessors'][i];view=doc['bufferViews'][a['bufferView']]
  return np.frombuffer(binary,dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']],count=a['count']*{'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']],offset=view.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],-1)
 view=doc['bufferViews'][doc['images'][0]['bufferView']]
 texture=np.array(Image.open(io.BytesIO(binary[view['byteOffset']:view['byteOffset']+view['byteLength']])).convert('RGB'))
 triangles=[]
 for node in doc['nodes']:
  for p in doc['meshes'][node['mesh']]['primitives']:
   pos,uv,norm=[read(p['attributes'][a]) for a in ('POSITION','TEXCOORD_0','NORMAL')]
   for indices in read(p['indices']).reshape(-1,3):triangles.append((pos[indices],uv[indices],norm[indices[0]]))
 return triangles,texture
models=[];eye=np.array((.63,.16,-1.));eye/=np.linalg.norm(eye)
right=np.cross(eye,(0,1,0));right/=np.linalg.norm(right);up=np.cross(right,eye)
for stage in (1,3,6,9):
 path=R/('dist/ReviewModels/MeadowMouse_A_S1_FacetedReview.glb' if stage==1 else f'dist/ReviewModels/Mossrat_S{stage}_FacetedReview.glb')
 tris,texture=load(path);positions=np.concatenate([t[0] for t in tris]);projection=np.stack((positions@right,positions@up),axis=-1)
 models.append(dict(stage=stage,tris=tris,texture=texture,low=projection.min(0),high=projection.max(0),height=float(np.ptp(positions[:,1]))))
W,H=2048,790;margin=54;gap=1.0
scale=min((W-margin*2)/(sum(m['high'][0]-m['low'][0] for m in models)+gap*3),590/max(m['high'][1]-m['low'][1] for m in models))
frame=np.full((H,W,3),(249,242,226),dtype=np.uint8);depth=np.full((H,W),-np.inf)
light=np.array((-.35,.75,-.65));light/=np.linalg.norm(light)
xstart=margin;baseline=H-90;labels=[]
for m in models:
 width=(m['high'][0]-m['low'][0])*scale
 labels.append((xstart+width/2,m));texture=m['texture']
 for pos,uv,normal in m['tris']:
  sx=(pos@right-m['low'][0])*scale+xstart;sy=baseline-(pos@up-m['low'][1])*scale;z=pos@eye
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
  rgb=np.clip(texture[ty,tx]*(.88+.12*max(0,np.dot(normal,light))),0,255).astype(np.uint8)
  old[mask]=zz[mask];frame[y0:y1+1,x0:x1+1][mask]=rgb[mask]
 xstart+=width+gap*scale
image=Image.fromarray(frame);draw=ImageDraw.Draw(image)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28);small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
draw.text((28,16),'MOSSRAT / BABY - TEEN - ADULT - ELDER / ACTUAL 3D',font=font,fill=(60,43,29))
draw.text((28,56),'One camera and one shared scale. Original baby unchanged. Review only, not installed.',font=small,fill=(105,86,63))
for center,m in labels:
 role={1:'BABY',3:'TEEN',6:'ADULT',9:'ELDER'}[m['stage']]
 draw.text((center,baseline+15),f'{m["stage"]} STAR / {role}',font=font,fill=(71,52,30),anchor='mt')
 draw.text((center,baseline+48),f'{len(m["tris"])} triangles',font=small,fill=(105,86,63),anchor='mt')
out=R/'assets/previews/mossrat-growth-faceted-review.png';image.save(out)
report={'sharedPixelsPerUnit':scale,'stages':[{k:m[k] for k in ('stage','height')} for m in models]}
assert all(report['stages'][i+1]['height']>report['stages'][i]['height'] for i in range(3))
(R/'assets/previews/mossrat-growth-dimensions.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('GROWTH_SHARED_SCALE_PASS:',report)
for stage in (3,6,9):
 subprocess.run([sys.executable,str(R/'tools/render_textured_review.py'),'--model',str(R/f'dist/ReviewModels/Mossrat_S{stage}_FacetedReview.glb'),'--output',str(R/f'assets/previews/mossrat-s{stage}-faceted-review.png'),'--title',f'MOSSRAT {stage} STAR / AGE REFINEMENT'],check=True,cwd=R)
