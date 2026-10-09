"""Render approved GLBs with a procedural particle concept; not Roblox output."""
from pathlib import Path
import sys,json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
settings=json.loads((R/'assets/effects/MossratAuraReview.json').read_text())
effects=R/'assets/effects';effects.mkdir(exist_ok=True)
# Original simple sprite masks. White RGBA pixels are tinted by emitters.
N=128;yy,xx=np.mgrid[:N,:N];x=(xx+0.5)/N*2-1;y=(yy+.5)/N*2-1
for name,alpha in (
 ('Glow',np.exp(-(x*x+y*y)*5)*(np.hypot(x,y)<.99)),
 ('Spark',np.clip(1-np.minimum(abs(x)*8+abs(y)*1.7,abs(y)*8+abs(x)*1.7),0,1)),
 ('Leaf',np.clip((1-((x+.22*y)**2/.35+abs(y)**1.6))*8,0,1))):
 rgba=np.full((N,N,4),255,dtype=np.uint8);rgba[:,:,3]=(alpha*255).astype(np.uint8)
 Image.fromarray(rgba).save(effects/f'MossratAura_{name}.png')

source=(R/'tools/render_textured_review.py').read_text(encoding='utf-8')
source=source.split(' image.paste(')[0]
source=source.replace('(249,242,226)','(20,32,27)')
source=source.replace('for col,(label,eye) in enumerate(views):',"views=[('AURA',(.65,.20,-1))]\nfor col,(label,eye) in enumerate(views):")
panels=[]
for stage in (6,9):
 sys.argv=['render','--model',str(R/f'dist/ReviewModels/Mossrat_S{stage}_FacetedReview.glb')]
 ns={'__file__':str(R/'tools/render_textured_review.py')};exec(compile(source,'actual_mesh_render','exec'),ns)
 positions=ns['allpos'];ground=positions[:,1].min()
 profile=settings[str(stage)];height=5.7 if stage==6 else 12.5
 panels.append((stage,ns,ground,profile,height))

W,H=1020,620;font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',22);small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',14)

def particle(frame,depth,ns,position,size,color,opacity,kind,angle):
 p=np.asarray(position);sx=(p@ns['right']-ns['center'][0])*ns['scale']+255
 sy=-(p@ns['up']-ns['center'][1])*ns['scale']+238;z=p@ns['d']
 radius=max(2,size*ns['scale']);x0=max(0,int(sx-radius*2));x1=min(509,int(sx+radius*2))
 y0=max(0,int(sy-radius*2));y1=min(479,int(sy+radius*2))
 if x0>x1 or y0>y1:return
 yy,xx=np.mgrid[y0:y1+1,x0:x1+1];dx=(xx-sx)/radius;dy=(yy-sy)/radius
 u=dx*math.cos(angle)+dy*math.sin(angle);v=-dx*math.sin(angle)+dy*math.cos(angle)
 if kind=='Leaf':alpha=np.clip((1-(u*u/.32+abs(v)**1.6))*4,0,1)
 elif kind=='Spark':alpha=np.clip(1-np.minimum(abs(u)*8+abs(v)*1.7,abs(v)*8+abs(u)*1.7),0,1)
 else:alpha=np.exp(-(dx*dx+dy*dy)*2.5)*.6
 # Model depth occludes particles behind it. Face stays readable.
 alpha*=opacity*(z>=depth[y0:y1+1,x0:x1+1]-.02)
 region=frame[y0:y1+1,x0:x1+1]
 if kind=='Glow':region[:]=np.clip(region+alpha[...,None]*np.array(color)*.60,0,255)
 else:region[:]=region*(1-alpha[...,None])+np.array(color)*alpha[...,None]

frames=[]
for index in range(32):
 t=index/32*math.tau
 image=Image.new('RGB',(W,H),(20,32,27));draw=ImageDraw.Draw(image)
 draw.text((22,12),'모스랫 · 초원 오라 검토안',font=font,fill=(231,238,218))
 draw.text((22,48),'실제 모델 + 효과 움직임 시안 / Roblox 실행 화면 아님 / 몸 크기를 비슷하게 맞춘 비교',font=small,fill=(174,192,171))
 for panel,(stage,ns,ground,profile,height) in enumerate(panels):
  frame=ns['frame'].astype(float).copy();depth=ns['depth']
  # Soft ascending motes around shoulders/back rather than on the face.
  count=10 if stage==6 else 28
  for j in range(count):
   phase=(t/math.tau+j/count)%1;angle=t+j*2.39996
   radius=height*(.24 if stage==6 else .38)*(1-.2*phase)
   position=(math.cos(angle)*radius,ground+height*(.13+phase*.59),.3*height+math.sin(angle)*radius)
   kind='Leaf' if j%3==0 else 'Spark'
   size=height*(.052 if kind=='Leaf' else (.012 if stage==6 else .020))
   color=settings['palette']['leaf' if kind=='Leaf' else 'spark']
   opacity=math.sin(phase*math.pi)*(.70 if stage==6 else .88)
   particle(frame,depth,ns,position,size,color,opacity,kind,angle)
  for j in range(3 if stage==6 else 9):
   angle=t+j*math.tau/(3 if stage==6 else 9)
   position=(math.cos(angle)*height*(.29 if stage==6 else .46),ground+height*(.19+.09*math.sin(angle)),math.sin(angle)*height*(.29 if stage==6 else .46)+height*.08)
   particle(frame,depth,ns,position,height*profile['glowSizeRatio'],settings['palette']['glow'],.28 if stage==6 else .65,'Glow',angle)
  # Nine-star gets loose curved streaks made of fading motes, not a solid cage.
  if stage==9:
   for arm in range(2):
    for j in range(32):
     a=t+arm*math.pi+j*.09
     position=(math.cos(a)*height*.47,ground+height*(.12+j*.019),height*.02+math.sin(a)*height*.47)
     particle(frame,depth,ns,position,height*.040,settings['palette']['glow' if arm==0 else 'spark'],math.sin(j/32*math.pi)*.55,'Glow',a)
  image.paste(Image.fromarray(frame.astype(np.uint8)),(panel*510,89))
  draw.text((panel*510+22,578),f'{stage}성 · '+('은은한 잎과 반짝임' if stage==6 else '휘도는 잎 · 금빛 반짝임 · 빛 흐름'),font=small,fill=(212,229,193))
 frames.append(image)
out=R/'assets/previews/mossrat-aura-review.gif'
frames[0].save(out,save_all=True,append_images=frames[1:],duration=90,loop=0,disposal=2)
frames[7].save(R/'assets/previews/mossrat-aura-review.png')
print('AURA_VISUAL_REVIEW_PASS: original sprites, 32 animated concept frames; not game installed',out)
