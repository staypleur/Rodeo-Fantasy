"""2 km approval draft: one geometry list drives the plan and Studio place.
This does not replace the live chunk generator or alter running hunt sessions.
"""
from pathlib import Path
import json,math,random
import xml.etree.ElementTree as E
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'dist/CourseReview/VarietyV4';OUT.mkdir(parents=True,exist_ok=True)
SCALE=4.8
FORK_HALF=9/SCALE
FORK_ROUTE=4.4
def half_width(d):
 # Same 48..70 stud envelope, varying along all five sections.
 return (29.5+5.5*math.cos(d/90))/SCALE
def median(d):
 for a,b in FORKS:
  if a<=d<=b:return 9/SCALE*math.sin(math.pi*(d-a)/(b-a))**.65
 return 0
SIZES={'Small':1,'Medium':1.5,'Large':3}
FORKS=[(430,550),(830,990),(1250,1390),(1670,1840)]
SECTIONS=[(0,400,50,'초원 · 적응'),(400,800,32,'숲길 · 첫 분기'),(800,1200,23,'바위 협곡'),(1200,1600,17,'나무·바위 조합'),(1600,2000,12,'마지막 숲 · 고난도')]
rng=random.Random(1012)
obstacles=[];crates=[];routes=[]
spawn_spaces=[]
for d in range(90,1980,90):
 for side in (-1,1):
  # Protected candidate pockets for dynamic herds, not extra fixed spawns.
  x=side*(median(d)+(half_width(d)-median(d))*.52)
  spawn_spaces.append(dict(x=x,meters=d,halfWidth=.65,halfDepth=3))
def route_x(d):
 base=math.sin(d/70)*(1.5+d/2000*2)
 for a,b in FORKS:
  if a-120<=d<=b+120:
   blend=min(1,max(0,(d-(a-120))/120),max(0,((b+120)-d)/120))
   blend=blend*blend*(3-2*blend)
   return base*(1-blend)+FORK_ROUTE*blend
 return base

def left_route(d):
 for a,b in FORKS:
  if a-120<=d<=b+120:
   blend=min(1,max(0,(d-(a-120))/120),max(0,((b+120)-d)/120))
   blend=blend*blend*(3-2*blend)
   return route_x(d)*(1-blend)-FORK_ROUTE*blend
 return None

def clear(o):
 # Keep a steering corridor and separate protected herd candidate pockets.
 radius=o['width']/2
 for pocket in spawn_spaces:
  if abs(o['x']-pocket['x'])<radius+pocket['halfWidth'] and abs(o['meters']-pocket['meters'])<radius+pocket['halfDepth']:return False
 if any(abs(o['x'])+radius>half_width(o['meters']+offset)-.5 for offset in (-radius,0,radius)):return False
 for offset in (-radius-2,0,radius+2):
  d=o['meters']+offset
  if abs(o['x']-route_x(d))<.7+radius:return False
  for a,b in FORKS:
   if a-radius<=d<=b+radius and abs(o['x'])<median(d)+radius:return False
  left=left_route(d)
  if left is not None and abs(o['x']-left)<.7+radius:return False
 for old in obstacles:
  if math.hypot(old['x']-o['x'],old['meters']-o['meters'])<(old['width']+o['width'])/2+.4:return False
 return True

for si,(start,end,spacing,label) in enumerate(SECTIONS):
 d=start+45
 while d<end-20:
  # Irregular forest pockets and diagonal rock outcrops, never complete rows.
  centre=rng.uniform(-6,6)
  pattern=rng.choice(['Trees','Trees','Rocks','Mixed','Sparse'])
  angle=rng.uniform(-1.1,1.1)
  for member in range(3+si):
   if pattern=='Sparse' and member>1:break
   kind='Tree' if pattern=='Trees' else 'Rock' if pattern=='Rocks' else rng.choice(['Tree','Rock'])
   tiers=['Small','Small','Medium'] if si<2 else ['Small','Medium','Medium','Large'] if si<4 else ['Medium','Large','Large','Small']
   tier=rng.choice(tiers)
   factor=SIZES[tier]
   width=4*factor/SCALE
   height=(6 if kind=='Tree' else 3)*factor/SCALE
   for attempt in range(12):
    if kind=='Rock':
     dx=(member-2)*2.4*math.cos(angle)+rng.uniform(-1,1)
     dd=(member-2)*4*math.sin(angle)+rng.uniform(-spacing*.3,spacing*.3)
    else:
     dx=rng.uniform(-2.5,2.5);dd=rng.uniform(-spacing*.38,spacing*.38)
    o=dict(kind=kind,tier=tier,x=round(centre+dx,2),meters=round(d+dd,2),width=width,height=height)
    if start+20<=o['meters']<end-10 and clear(o):
     obstacles.append(o);break
    if attempt==5:centre=rng.uniform(-6,6)
  if rng.random()<.6:
   main=route_x(d);other=left_route(d)
   candidates=[-half_width(d)+.8,half_width(d)-.8]
   for x in candidates:
    if abs(x-main)>1.2 and (other is None or abs(x-other)>1.2) and not (any(a<=d<=b for a,b in FORKS) and abs(x)<FORK_HALF+.5):
     crates.append(dict(x=x,meters=d));break
  d+=rng.uniform(spacing*.6,spacing*1.15)
routes=[dict(meters=d,x=route_x(d),fork=any(a<=d<=b for a,b in FORKS)) for d in range(2001)]
# At 64 forward / 32 sideways studs/s, both branches must be steerable.
for d in range(2000):
 assert abs(route_x(d+1)-route_x(d))<.5
 if left_route(d) is not None and left_route(d+1) is not None:
  assert abs(left_route(d+1)-left_route(d))<.5
# Sweep the same corridor at 1 m intervals; no obstacle may intrude.
for o in obstacles:
 radius=o['width']/2
 for pocket in spawn_spaces:
  assert not (abs(o['x']-pocket['x'])<radius+pocket['halfWidth'] and abs(o['meters']-pocket['meters'])<radius+pocket['halfDepth']),('Blocked herd pocket',o,pocket)
 for d in range(max(0,math.floor(o['meters']-radius)),min(2000,math.ceil(o['meters']+radius))+1):
  assert abs(o['x']-route_x(d))>=.7+radius,('Blocked route',o,d)
  left=left_route(d)
  if left is not None:assert abs(o['x']-left)>=.7+radius,('Blocked left fork',o,d)
section_counts=[sum(a<=o['meters']<b for o in obstacles) for a,b,_,_ in SECTIONS]
assert section_counts==sorted(section_counts),('Density must rise by section',section_counts)
assert sum(o['tier']=='Large' and o['meters']>=1600 for o in obstacles)>sum(o['tier']=='Large' and 800<=o['meters']<1200 for o in obstacles)
data=dict(status='Unapproved variety V4 layout; mountain versus canyon appearance not selected',lengthMeters=2000,widthStudsRange=[48,70],metersPerStud=1/SCALE,
 sizeMultipliers=SIZES,sections=SECTIONS,forks=FORKS,obstacles=obstacles,crates=crates,routes=routes,protectedHerdCandidatePockets=spawn_spaces)
(OUT/'GreenStar-2000m-layout.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')

# Top view is intentionally widened for readable placements, not equal-axis scale.
im=Image.new('RGB',(1800,1030),'#102b29');dr=ImageDraw.Draw(im)
font='C:/Windows/Fonts/malgun.ttf'
def f(n):return ImageFont.truetype(font,n)
dr.text((40,22),'Green Star · 다양한 군집 + 몬스터 공간 검토안',font=f(36),fill='#f0eed7')
dr.text((40,78),'승인 전 미적용 | 폭 48–70스터드 안에서 변화 · 가로 폭을 넓혀 표시 | 소형 1 / 중형 1.5 / 대형 3',font=f(19),fill='#bcddcb')
for si,(start,end,spacing,label) in enumerate(SECTIONS):
 left=42+si*350;top=178;w=268;h=700
 dr.text((left,126),label,font=f(22),fill='#ffdb92')
 dr.text((left,155),f'{start}–{end}m · 불규칙 군집',font=f(16),fill='#c3ddd0')
 # Road outline follows the proposed variable width.
 road=[]
 for d in range(start,end+1,2):road.append((left+w/2-half_width(d)/(70/SCALE)*w,top+(d-start)/400*h))
 for d in range(end,start-1,-2):road.append((left+w/2+half_width(d)/(70/SCALE)*w,top+(d-start)/400*h))
 dr.polygon(road,fill='#89b97b',outline='#dddfaf')
 def pt(x,d):return left+w/2+x/(70/SCALE)*w,top+(d-start)/400*h
 for d in range(start,end+1,100):
  _,y=pt(0,d);dr.line((left,y,left+w,y),fill='#c8d1a7',width=1)
  dr.text((left+w+6,y-9),str(d),font=f(13),fill='#d9e9db')
 for a,b in FORKS:
  lo,hi=max(start,a),min(end,b)
  if lo<hi:
   x1,y1=pt(-FORK_HALF,lo);x2,y2=pt(FORK_HALF,hi)
   hill=[pt(-median(d),d) for d in range(lo,hi+1)]+[pt(median(d),d) for d in range(hi,lo-1,-1)]
   dr.polygon(hill,fill='#776356',outline='#e1c18c')
   dr.line([pt(0,d) for d in range(lo,hi+1)],fill='#ead49d',width=2)
   dr.text((left+6,y1+5),'분기',font=f(14),fill='#fff7ce')
 # Mark usable paths before obstacles, using the same clearance plan.
 for pocket in spawn_spaces:
  if start<=pocket['meters']<end:
   x,y=pt(pocket['x'],pocket['meters'])
   dr.rectangle((x-9,y-7,x+9,y+7),fill='#9dc9d8',outline='#3f718c',width=2)
 pts=[]
 for r in routes:
  if start<=r['meters']<end:pts.append(pt(r['x'],r['meters']))
 dr.line(pts,fill='#e9e9be',width=7)
 for a,b in FORKS:
  if a-120<end and b+120>start:
   dr.line([pt(left_route(d),d) for d in range(max(start,a-120),min(end,b+120)+1)],fill='#e9e9be',width=7)
 for o in obstacles:
  if not start<=o['meters']<end:continue
  x,y=pt(o['x'],o['meters']);r=5*SIZES[o['tier']]
  if o['kind']=='Tree':dr.rectangle((x-r,y-r,x+r,y+r),fill='#265d40',outline='#cae8a2',width=2)
  else:dr.polygon([(x-r,y),(x-r*.4,y-r),(x+r*.6,y-r*.8),(x+r,y+r*.5),(x-r*.4,y+r)],fill='#776e63',outline='#f6deaa')
 for c in crates:
  if start<=c['meters']<end:
   x,y=pt(c['x'],c['meters']);dr.rectangle((x-4,y-4,x+4,y+4),fill='#f8c166',outline='#775330')
 dr.text((left,890),f'장애물 {sum(start<=o["meters"]<end for o in obstacles)}개',font=f(17),fill='#d5ead9')
dr.text((45,945),'초록 네모: 나무 · 갈색: 바위 · 노랑: 상자 · 파랑: 몬스터 후보 공간 · 밝은 선: 회피 통로',font=f(19),fill='#efdca8')
dr.text((45,980),'기존 전체 폭 48–70스터드 · 가까운 구간만 생성 · 실제 모바일 난이도/성능은 별도 검사',font=f(17),fill='#b9d4c8')
im.save(OUT/'GreenStar-2000m-plan.png')

# Standalone Roblox place. No live storage, scripts, monsters or user data.
doc=E.Element('roblox',{'version':'4'});serial=0
def item(cls,parent,name):
 global serial
 serial+=1;n=E.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{serial}'})
 ps=E.SubElement(n,'Properties');E.SubElement(ps,'string',{'name':'Name'}).text=name
 return n,ps
world,wp=item('Workspace',doc,'Workspace')
E.SubElement(wp,'bool',{'name':'StreamingEnabled'}).text='true'
mapnode,mp=item('Model',world,'GreenStar2000m_APPROVAL_DRAFT')
def vector(ps,key,v):
 n=E.SubElement(ps,'Vector3',{'name':key})
 for axis,x in zip(('X','Y','Z'),v):E.SubElement(n,axis).text=str(x)
def part(name,x,y,z,sx,sy,sz,color,cls='Part',yaw=0):
 n,ps=item(cls,mapnode,name)
 E.SubElement(ps,'bool',{'name':'Anchored'}).text='true'
 E.SubElement(ps,'bool',{'name':'CanTouch'}).text='false'
 vector(ps,'size',(sx,sy,sz))
 cf=E.SubElement(ps,'CoordinateFrame',{'name':'CFrame'})
 for key,val in [('X',x),('Y',y),('Z',z)]+[(f'R{i}{j}',((math.cos(yaw),0,math.sin(yaw)),(0,1,0),(-math.sin(yaw),0,math.cos(yaw)))[i][j]) for i in range(3) for j in range(3)]:E.SubElement(cf,key).text=str(val)
 c=E.SubElement(ps,'Color3',{'name':'Color'})
 for key,val in zip(('R','G','B'),color):E.SubElement(c,key).text=str(val/255)
 E.SubElement(ps,'token',{'name':'Material'}).text='272'
 E.SubElement(ps,'token',{'name':'TopSurface'}).text='0'
 E.SubElement(ps,'token',{'name':'BottomSurface'}).text='0'
 return n
for d in range(0,2000,100):
 part(f'Ground_{d}m',0,-1,-(d+50)*SCALE,half_width(d+50)*2*SCALE,2,100*SCALE,(130,175,106))
 for side in (-1,1):part('Boundary',side*(half_width(d+50)*SCALE+5),5,-(d+50)*SCALE,2*SCALE,10,100*SCALE,(138,122,91))
for a,b in FORKS:
 for d in range(a+3,b-2,8):
  radius=median(d)*SCALE
  height=5+18*math.sin(math.pi*(d-a)/(b-a))
  for side in (-1,1):
   part('FacetedMountain',side*radius/2,height/2,-d*SCALE,8*SCALE,height,max(.2,radius),(145+int(d)%15,122,91),'WedgePart',-side*math.pi/2)
for i,o in enumerate(obstacles):
 x=o['x']*SCALE;z=-o['meters']*SCALE;s=SIZES[o['tier']]
 if o['kind']=='Tree':
  part(f'Tree_{o["tier"]}_{i}',x,2.2*s,z,1.25*s,4.4*s,1.25*s,(146,101,70))
  part('Crown',x,4.3*s,z,3.8*s,2.1*s,3.8*s,(72,139,78))
  part('LeafTop',x,5.65*s,z,2.8*s,.7*s,2.8*s,(131,183,89))
 else:
  part(f'Rock_{o["tier"]}_{i}',x,1.15*s,z,3.8*s,2.3*s,3.8*s,(164,155,133))
  part('StoneCap',x,2.5*s,z,2.7*s,.7*s,2.6*s,(192,182,153))
for c in crates:part('CratePreview',c['x']*SCALE,2,-c['meters']*SCALE,4,4,4,(197,146,77))
part('ReviewSpawn',0,1,6,10,1,10,(224,223,176),'SpawnLocation')
E.indent(doc,space='  ');E.ElementTree(doc).write(OUT/'GreenStar-2000m-Approval.rbxlx',encoding='utf8',xml_declaration=True)
print('PREVIEW ONLY:',len(obstacles),'obstacles,',len(crates),'crates;',serial,'instances; live course unchanged')

# Server-only lookup: instantiate only loaded chunks, never replicate the whole list.
by_chunk={}
for o in obstacles:
 z=-o['meters']*SCALE;index=math.floor(z/256+.5)
 bucket=by_chunk.setdefault(index,{'obstacles':[],'crates':[]})
 bucket['obstacles'].append(o)
for c in crates:
 index=math.floor(-c['meters']*SCALE/256+.5)
 by_chunk.setdefault(index,{'obstacles':[],'crates':[]})['crates'].append(c)
lines=['-- UNAPPROVED mountain/difficulty review. Not installed in the live course. Server-only candidate.','return {']
for index,bucket in sorted(by_chunk.items()):
 lines.append(f'[{index}]={{obstacles={{')
 for o in bucket['obstacles']:
  lines.append('{x=%.4f,z=%.4f,style="%s",tier="%s",scale=%s,height=%.4f},'%(o['x']*SCALE,-o['meters']*SCALE,o['kind'],o['tier'],SIZES[o['tier']],o['height']*SCALE))
 lines.append('},crates={')
 for c in bucket['crates']:lines.append('{x=%.4f,z=%.4f},'%(c['x']*SCALE,-c['meters']*SCALE))
 lines.append('}},')
lines.append('}')
(OUT/'GreenStarCourseLayout-PREVIEW.luau').write_text('\n'.join(lines)+'\n',encoding='utf8')
