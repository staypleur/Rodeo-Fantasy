"""Three original native-Part body proposals; basket/game place unchanged."""
from pathlib import Path
import math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from native_part_review import save_review
R=Path(__file__).resolve().parents[1]
outs=[]
for variant in 'ABC':
 parts=[];balls=set();serial=0
 def add(n,p,s,c,rot=None,ball=True):
  global serial
  serial+=1;n=f'{n}_{serial}'
  parts.append((n,np.array(p,float),np.array(s,float),c,np.eye(3) if rot is None else rot))
  if ball:balls.add(n)
 def ry(deg):
  a=math.radians(deg);c,s=math.cos(a),math.sin(a)
  return np.array([[c,0,s],[0,1,0],[-s,0,c]])
 def tube(n,points,width,color):
  for j in range(len(points)-1):
   a,b=np.array(points[j]),np.array(points[j+1]);d=b-a;length=np.linalg.norm(d);d/=length
   ref=np.array((0,1,0)) if abs(d[1])<.95 else np.array((1,0,0))
   x=np.cross(ref,d);x/=np.linalg.norm(x);y=np.cross(d,x)
   w=width*(1-j/(len(points)-1)*.55)
   add(n,(a+b)/2,(w,w,length+w*.8),color,np.column_stack((x,y,d)))
 blue={'A':(55,143,185),'B':(43,153,158),'C':(69,110,180)}[variant]
 light={'A':(182,224,229),'B':(148,225,203),'C':(175,196,234)}[variant]
 ivory=(243,231,193);gold=(213,165,76)
 # One elongated main volume, overlapping chest/head; no separated balloon chain.
 add('Body',(0,0,3),(26,16,47),blue)
 add('Belly',(0,-4,4),(21,9,37),light)
 add('Head',(0,1,-21),(22,17,22),blue)
 add('Forehead',(0,5,-25),(15,10,11),light)
 for side in (-1,1):
  add('Muzzle',(side*4,-1,-30),(9,6,5),ivory)
  add('EyeOutline',(side*6.4,4.4,-29.7),(4.5,4.1,.8),(29,49,64))
  add('Iris',(side*6.4,4.5,-30.18),(3.5,3.3,.4),(222,166,69))
  add('Pupil',(side*6.4,4.8,-30.45),(2.2,2.5,.2),(24,32,45))
  add('EyeHighlight',(side*6.1,5.5,-30.6),(1,1,.14),(255,249,218))
  add('Ear',(side*11,3,-19),(3.5,8,8),blue)
  add('EarInset',(side*11.8,3,-20),(1.4,5.8,4.8),light)
  tusks=[(side*(5+j*.12),-2-j*.55,-31-j*.8) for j in range(8)]
  tube('Tusk',tusks,2.2,ivory)
 # A tapered upturned trunk keeps the agreed long-nosed fantasy silhouette.
 points=[]
 for j in range(17):
  t=j/16;points.append((0,-1-6*math.sin(math.pi*t)+7*t*t,-30-14*t))
 tube('Trunk',points,5.4,blue)
 add('TrunkTip',(0,6,-44),(2.8,2.6,3),light)
 for side in (-1,1):
  add('WingRoot',(side*15,2,1),(17,3,19),blue,ry(side*12))
  feathers=9 if variant=='A' else 6 if variant=='B' else 8
  for j in range(feathers):
   angle=side*(15+j*4)
   x=side*(22+j*2.3);z=2+j*1.8;y=2-j*.13
   length=(23 if variant=='A' else 25 if variant=='B' else 19)-j*.6
   color=ivory if variant=='A' else light if variant=='B' else (124+j*7,160+j*5,215+j*3)
   add('WingFeather',(x,y,z),(length,1.6 if variant!='B' else 2.2,4.7 if variant!='B' else 7),color,ry(angle))
   add('WingAccent',(x-side*4,y+1,z-1),(length*.55,.6,1.1),gold if variant!='B' else blue,ry(angle))
  add('TailFin',(side*7,0,25),(17,2,10),light,ry(side*30))
 if variant=='A':
  for j in range(3):
   add('CrownStem',((j-1)*4,10,-22),(.8,4+(j==1)*2,.8),gold,ball=False)
   add('CrownGem',((j-1)*4,12.5+(j==1),-22),(2.3,3,2.3),light,ball=False)
  for z in range(-12,20,6):add('BackTrim',(0,8,z),(1.2,.8,4),gold)
 elif variant=='B':
  for j in range(6):add('CoralCrest',(0,9-j*.25,-16+j*5),(1.8,3.5-j*.25,4),light)
  for side in (-1,1):add('SeaMantle',(side*9,6,-4),(5,2,25),gold,ry(side*8))
 else:
  for j in range(5):
   add('CrystalCrest',((j-2)*2.8,9+abs(j-2)*.3,-22),(1.8,5-abs(j-2),1.8),gold,ball=False)
  for z in range(-10,20,6):add('CrystalBack',(0,9,z),(2,3,3),light,ball=False)
 for n,p,s,c,m in parts:assert np.isfinite(p).all() and (s>0).all() and np.allclose(m.T@m,np.eye(3))
 label={'A':'A · 하늘 왕관 / 크림색 깃날개','B':'B · 바다의 수호자 / 청록 지느러미 날개','C':'C · 푸른 결정 / 남청색 겹날개'}[variant]
 out=save_review(parts,'AirshipBodyReview'+variant,label,'게임 미적용 · 기본 Ball/Block Part · 바구니 제외 · 곡면은 소프트웨어 근사 렌더',(.55,.42,-1.1),balls)
 outs.append(out)
 print(f'AIRSHIP_REVIEW_{variant}_PASS: {len(parts)} native Parts, {len(balls)} ellipsoids, finite positive geometry, no game changes')

comparison=Image.new('RGB',(1950,500),(234,237,226))
for i,p in enumerate(outs):comparison.paste(Image.open(p).resize((650,442)),(i*650,0))
draw=ImageDraw.Draw(comparison);font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',22)
draw.text((25,458),'실제 3D 후보 3개 · 선택 후 연결부/날갯짓을 검증해 적용 · 현재 게임 본체는 아직 변경하지 않았습니다.',font=font,fill=(37,74,68))
comparison.save(R/'assets/previews/AirshipBodyReviews.png')
