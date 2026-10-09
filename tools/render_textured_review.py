"""Rasterize the actual GLB mesh and embedded texture with a depth buffer."""
from pathlib import Path
import struct,json,io,math,argparse
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--model',type=Path,default=ROOT/'dist/ReviewModels/MeadowMouse_A_S1_FacetedReview.glb')
parser.add_argument('--output',type=Path,default=ROOT/'assets/previews/meadow-mouse-s1-faceted-glb.png')
args=parser.parse_args();data=args.model.read_bytes();n=struct.unpack_from('<I',data,12)[0]
g=json.loads(data[20:20+n]);binary=data[28+n:]
def values(index):
 a=g['accessors'][index];v=g['bufferViews'][a['bufferView']];dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']]
 dims={'SCALAR':1,'VEC2':2,'VEC3':3}[a['type']]
 return np.frombuffer(binary,dtype=dtype,count=a['count']*dims,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],dims)
view=g['bufferViews'][g['images'][0]['bufferView']]
texture=np.array(Image.open(io.BytesIO(binary[view['byteOffset']:view['byteOffset']+view['byteLength']])).convert('RGB'))
triangles=[]
for node in g['nodes']:
 for p in g['meshes'][node['mesh']]['primitives']:
  pos=values(p['attributes']['POSITION']);uv=values(p['attributes']['TEXCOORD_0']);normal=values(p['attributes']['NORMAL']);ids=values(p['indices']).reshape(-1,3)
  for indices in ids:triangles.append((pos[indices],uv[indices],normal[indices[0]]))
W,H=1560,650;image=Image.new('RGB',(W,H),(249,242,226));draw=ImageDraw.Draw(image)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24);small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
draw.text((22,15),'MEADOW MOUSE A1 / FACETED 3D REVIEW',fill=(65,49,35),font=font)
draw.text((22,52),f'{len(triangles)} triangles / flat normals / actual embedded color texture / NOT a Roblox screenshot',fill=(106,88,64),font=small)
for col,(label,eye) in enumerate([('FRONT',(0,.07,-1)),('THREE-QUARTER',(.65,.30,-1)),('HUNT VIEW',(.36,.84,.48))]):
 d=np.array(eye,dtype=float);d/=np.linalg.norm(d);right=np.cross(d,(0,1,0));right/=np.linalg.norm(right);up=np.cross(right,d)
 allpos=np.concatenate([t[0] for t in triangles]);project=np.stack((allpos@right,allpos@up),axis=-1)
 low=project.min(axis=0);high=project.max(axis=0);center=(low+high)/2;scale=min(455/(high[0]-low[0]),440/(high[1]-low[1]))
 frame=np.full((480,510,3),(249,242,226),dtype=np.uint8);depth=np.full((480,510),-np.inf)
 light=np.array((-.35,.75,-.65));light/=np.linalg.norm(light)
 for pos,uv,normal in triangles:
  sx=(pos@right-center[0])*scale+255;sy=-(pos@up-center[1])*scale+238;z=pos@d
  x0=max(0,int(np.floor(sx.min())));x1=min(509,int(np.ceil(sx.max())))
  y0=max(0,int(np.floor(sy.min())));y1=min(479,int(np.ceil(sy.max())))
  if x0>x1 or y0>y1:continue
  denom=(sy[1]-sy[2])*(sx[0]-sx[2])+(sx[2]-sx[1])*(sy[0]-sy[2])
  if abs(denom)<1e-8:continue
  yy,xx=np.mgrid[y0:y1+1,x0:x1+1];xx=xx+.5;yy=yy+.5
  a=((sy[1]-sy[2])*(xx-sx[2])+(sx[2]-sx[1])*(yy-sy[2]))/denom
  b=((sy[2]-sy[0])*(xx-sx[2])+(sx[0]-sx[2])*(yy-sy[2]))/denom;c=1-a-b
  zz=a*z[0]+b*z[1]+c*z[2];old=depth[y0:y1+1,x0:x1+1]
  mask=(a>=-1e-5)&(b>=-1e-5)&(c>=-1e-5)&(zz>old)
  if not mask.any():continue
  tuv=a[...,None]*uv[0]+b[...,None]*uv[1]+c[...,None]*uv[2]
  tx=np.clip((tuv[...,0]*texture.shape[1]).astype(int),0,texture.shape[1]-1);ty=np.clip((tuv[...,1]*texture.shape[0]).astype(int),0,texture.shape[0]-1)
  shade=.88+.12*max(0,np.dot(normal,light))
  rgb=np.clip(texture[ty,tx]*shade,0,255).astype(np.uint8)
  old[mask]=zz[mask];frame[y0:y1+1,x0:x1+1][mask]=rgb[mask]
 image.paste(Image.fromarray(frame),(col*520+5,134))
 draw.text((col*520+24,106),label,fill=(65,49,35),font=font)
draw=ImageDraw.Draw(image);draw.text((22,621),'Static shape review only. No game installation, rigging or walking animation.',fill=(106,88,64),font=small)
args.output.parent.mkdir(parents=True,exist_ok=True);image.save(args.output);print(args.output)
