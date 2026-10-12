"""Independent 3D fork design comparison. No live source changes or scripts."""
from pathlib import Path
import math, random, json
import xml.etree.ElementTree as E

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'dist/CourseReview/SceneryV3'
OUT.mkdir(parents=True,exist_ok=True)
doc=E.Element('roblox',{'version':'4'})
serial=0
def item(cls,parent,name):
 global serial
 serial+=1
 n=E.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{serial}'})
 p=E.SubElement(n,'Properties');E.SubElement(p,'string',{'name':'Name'}).text=name
 return n,p
world,_=item('Workspace',doc,'Workspace')
root,_=item('Model',world,'ForkScenery_APPROVAL_ONLY')
records=[]
def vec(p,key,v):
 n=E.SubElement(p,'Vector3',{'name':key})
 for a,b in zip(('X','Y','Z'),v):E.SubElement(n,a).text=str(b)
def part(parent,name,pos,size,col,cls='Part',yaw=0,shape=None,material=272):
 _,p=item(cls,parent,name)
 E.SubElement(p,'bool',{'name':'Anchored'}).text='true'
 E.SubElement(p,'bool',{'name':'CanTouch'}).text='false'
 vec(p,'size',size)
 c=E.SubElement(p,'CoordinateFrame',{'name':'CFrame'})
 rot=((math.cos(yaw),0,math.sin(yaw)),(0,1,0),(-math.sin(yaw),0,math.cos(yaw)))
 for a,b in list(zip(('X','Y','Z'),pos))+[(f'R{i}{j}',rot[i][j]) for i in range(3) for j in range(3)]:E.SubElement(c,a).text=str(b)
 color=E.SubElement(p,'Color3',{'name':'Color'})
 for a,b in zip(('R','G','B'),col):E.SubElement(color,a).text=str(b/255)
 for key,val in [('Material',material),('TopSurface',0),('BottomSurface',0)]:E.SubElement(p,'token',{'name':key}).text=str(val)
 if shape is not None:E.SubElement(p,'token',{'name':'shape'}).text=str(shape)
 records.append(dict(name=name,pos=pos,size=size))

def tree(parent,x,y,z,s=1,pine=False):
 part(parent,'Trunk',(x,y+3*s,z),(1*s,6*s,1*s),(108,79,50))
 if pine:
  for k in range(3):
   part(parent,'Pine',(x,y+(5+k*1.8)*s,z),((6-k)*s,3*s,(6-k)*s),(48+k*8,105+k*10,64+k*4))
 else:
  for dx,dy,dz,sc,col in [(-1.3,6,.2,4.6,(72,135,66)),(1.4,6.2,-.5,4.8,(85,151,73)),(0,8,0,4.8,(107,166,81))]:
   part(parent,'Canopy',(x+dx*s,y+dy*s,z+dz*s),(sc*s,sc*.8*s,sc*s),col)

def rock(parent,x,y,z,s=1):
 part(parent,'Rock',(x,y+1.2*s,z),(3.2*s,2.4*s,3*s),(133,137,124),yaw=.35,material=816)
 part(parent,'RockSlope',(x+.6*s,y+2.4*s,z),(2.4*s,1.5*s,2.4*s),(167,168,148),'WedgePart',.8,material=816)

counts={}
for style,cx in [('ForestMountain',-62),('OpenCanyon',62)]:
 before=serial;model,_=item('Model',root,style)
 # Representative short fork, full envelope never wider than old 70 stud road.
 # Vary widths and taper the median. Full 2 km gameplay still needs later integration.
 for i in range(20):
  z=10-i*10
  t=i/19
  width=59+11*math.cos(t*2*math.pi)
  gap=18*math.sin(math.pi*t)**.65
  if style=='ForestMountain' or gap<.1:
   part(model,'RockGround',(cx,-16,z),(width,32,10),(125,117,94),material=816)
   part(model,'Ground',(cx,-.5,z),(width,1,10),(124,164,90),material=1280)
  else:
   lane=(width-gap)/2
   for side in (-1,1):
    x=cx+side*(gap/2+lane/2)
    part(model,'RoadBank',(x,-16,z),(lane,32,10),(125,117,94),material=816)
    part(model,'RoadGrass',(x,-.5,z),(lane,1,10),(125,166,92),material=1280)
    part(model,'CutStone',(cx+side*(gap/2+2),-15,z),(4,28,10),(129+i%3*7,116,92),material=816)
    part(model,'CliffLayer',(cx+side*(gap/2+1.8),-22,z),(4.2,3,10),(102,89,75),material=816)
   part(model,'CanyonDepth',(cx,-32,z),(max(.1,gap),2,10),(43,63,64),material=816)
  if style=='ForestMountain' and gap>.1:
   h=3+10*math.sin(math.pi*t)+3*math.sin(t*5*math.pi)
   for side in (-1,1):
    part(model,'SlopedRock',(cx+side*gap/4,h/2,z),(10,h,gap/2),(100+i%4*5,139+i%3*4,78),'WedgePart',-side*math.pi/2,material=1280)
   if i in (4,8,12,16):
    tree(model,cx,h,z,.7,pine=True)
   if i in (5,9,13):rock(model,cx-2,h-1,z+3,.75)
  # Ground cover on outer shoulder, clear travel corridor; reused shape palette.
  if i in (2,5,9,13,17):
   for side in (-1,1):
    x=cx+side*(width/2-4)
    tree(model,x,0,z,.7 if i%2 else 1,pine=i%2==0)
    # Tree-only grove; rocks occupy separate pockets instead of every tree's front.
  if i in (3,10,16):
   side=-1 if i%2 else 1
   x=cx+side*(width/2-5)
   for dx,dz,s in [(0,0,.8),(2,4,.55),(-1,-3,.65)]:rock(model,x+dx,0,z+dz,s)
  if i in (4,7,11,15):
   for side in (-1,1):
    x=cx+side*(gap/2+2.5)
    if (i+side)%3==0:rock(model,x,0,z+2,.65)
    elif (i+side)%3==1:part(model,'Shrub',(x,1,z-2),(2.8,2,2.8),(100,148,70))
  for side in (-1,1):
   part(model,'OuterBank',(cx+side*(width/2+1),.5,z),(2,3,10),(117,148,82),material=1280)
 counts[style]=serial-before

E.indent(doc,space='  ')
E.ElementTree(doc).write(OUT/'Fork-Scenery-Comparison.rbxlx',encoding='utf8',xml_declaration=True)
(OUT/'review.json').write_text(json.dumps(dict(status='UNAPPROVED',oldMaximumWidthStuds=70,widthRangeStuds=[48,70],segmentLengthStuds=200,variants=counts,limitations=['Representative scenery only; not a playable 2 km course','No mobile performance or player collision validation']),indent=2),encoding='utf8')
assert max(r['size'][0] for r in records if r['name']=='Ground')<=70
assert not list(doc.iter('ProtectedString'))
print('SCENERY_REVIEW_ONLY',counts,'instances',serial,'live sources unchanged')
