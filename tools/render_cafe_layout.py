"""Offline geometry preview, using the exact cafe layout; no AI concept image."""
from pathlib import Path
import json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];parts=json.loads((R/'assets/cafe/layout.json').read_text(encoding='utf-8'))
W,H=1600,1050
def render(eye,target,cutaway,path):
 eye=np.array(eye,float);f=np.array(target,float)-eye;f/=np.linalg.norm(f)
 right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
 pixels=np.full((H,W,3),(220,229,218),dtype=np.uint8);zbuffer=np.full((H,W),np.inf);faces=[]
 for p in parts:
  if p.get('alpha',0)>.8:continue
  if cutaway and p['name'] in ('Roof','RoofRib','CeilingBeam','FrontWindow','FrontWindowFrame','CafeSign','EntryPillar','PendantStem','WarmPendant'):continue
  if cutaway and p['name']=='SideWall' and p['pos'][0]>0:continue
  c=np.array(p['pos']);s=np.array(p['size'])/2
  a=math.radians(p.get('yaw',0));rot=np.array([[math.cos(a),0,math.sin(a)],[0,1,0],[-math.sin(a),0,math.cos(a)]])
  points=np.array([[x,y,z] for x in [-1,1] for y in [-1,1] for z in [-1,1]])*s
  points=points@rot.T+c
  for indexes,shade in [([0,1,3,2],.76),([4,6,7,5],.9),([0,4,5,1],.7),([2,3,7,6],1.05),([0,2,6,4],.8),([1,5,7,3],.93)]:
   v=points[indexes]-eye;depth=v@f
   if depth.min()<1:continue
   xy=np.stack([W/2+(v@right)*1050/depth,H/2-(v@up)*1050/depth],axis=1)
   color=tuple(int(min(255,x*shade)) for x in p['color'])
   if p.get('alpha',0)>.3:color=tuple(int(x*.6+y*.4) for x,y in zip(color,(224,232,213)))
   for tri in ([0,1,2],[0,2,3]):
    q=xy[tri];d=depth[tri]
    lo=np.maximum(np.floor(q.min(axis=0)).astype(int),[0,0]);hi=np.minimum(np.ceil(q.max(axis=0)).astype(int),[W-1,H-1])
    if (hi<lo).any():continue
    xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1),np.arange(lo[1],hi[1]+1))
    denom=(q[1,1]-q[2,1])*(q[0,0]-q[2,0])+(q[2,0]-q[1,0])*(q[0,1]-q[2,1])
    if abs(denom)<1e-8:continue
    aa=((q[1,1]-q[2,1])*(xx-q[2,0])+(q[2,0]-q[1,0])*(yy-q[2,1]))/denom
    bb=((q[2,1]-q[0,1])*(xx-q[2,0])+(q[0,0]-q[2,0])*(yy-q[2,1]))/denom
    cc=1-aa-bb;zz=1/np.maximum(aa/d[0]+bb/d[1]+cc/d[2],1e-12)
    targetz=zbuffer[lo[1]:hi[1]+1,lo[0]:hi[0]+1]
    mask=(aa>=0)&(bb>=0)&(cc>=0)&(zz<targetz)
    targetz[mask]=zz[mask];pixels[lo[1]:hi[1]+1,lo[0]:hi[0]+1][mask]=color
 image=Image.fromarray(pixels);draw=ImageDraw.Draw(image)
 font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',24)
 draw.rectangle((20,20,1580,98),fill=(37,62,46))
 draw.text((42,38),'카페 내부 · 지붕을 걷어낸 구조 검토' if cutaway else '카페 · 테라스 · 대형 몬스터 운동장 · 놀이터',font=font,fill=(247,233,197))
 draw.text((42,72),'실제 배치 데이터의 오프라인 렌더 — Roblox 조명/유리/재질 적용 화면과 다릅니다',font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',15),fill=(214,224,204))
 image.save(R/path)
render([490,460,540],[0,0,-10],False,'assets/previews/cafe-exterior-layout.png')
render([145,170,-28],[0,2,-166],True,'assets/previews/cafe-interior-layout.png')
