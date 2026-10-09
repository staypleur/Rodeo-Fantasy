"""Review-only entrance and outer garden: keep a wide, level walking corridor."""
import math
import numpy as np
from native_part_review import save_review
parts=[]
cream=(237,226,199);stone=(189,174,146);gold=(208,169,90);teal=(34,104,115)
def box(name,pos,size,col,angle=0,roll=0):
 a=math.radians(angle);r=math.radians(roll)
 ry=np.array([[math.cos(a),0,math.sin(a)],[0,1,0],[-math.sin(a),0,math.cos(a)]])
 rz=np.array([[math.cos(r),-math.sin(r),0],[math.sin(r),math.cos(r),0],[0,0,1]])
 parts.append((name,np.array(pos,float),np.array(size,float),col,ry@rz))
box('ReviewGround',(0,-.55,0),(110,1,72),(123,158,112))
box('OpenLevelWalk',(0,.02,0),(24,.16,72),cream)
for sg in (-1,1):
 x=sg*19
 for j in range(4):
  col=tuple(round(v+(237-v)*j/5) for v in stone)
  box('TowerMasonry',(x,3.1+j*5.5,0),(9,5.4,11),col)
 box('TowerFoot',(x,.55,0),(12,1.1,14),stone)
 for y in (1.2,12,23):box('GoldTowerBand',(x,y,0),(9.4,.32,11.4),gold)
 for j in range(7):
  t=j/6;col=tuple(round(lo+(hi-lo)*t) for lo,hi in zip(teal,(107,181,172)))
  box('GradientRoof',(x,24+j*.7,0),(13-j*1.35,.75,15-j*1.35),col)
 box('RoofGoldCap',(x,29,0),(3.6,.4,5.6),gold)
 # Tall recessed facade panels avoid making the tower a blank cuboid.
 box('RecessedTowerPanel',(x,11,-5.6),(4,14,.2),teal)
 for dx in (-2.35,2.35):box('PanelFrame',(x+dx,11,-5.8),(.45,15,.3),cream)
 # Outer wall segments with open railing, never across the central walk.
 for j in range(3):
  wx=sg*(29+j*9)
  box('OuterWall',(wx,2.6,2),(8.7,5.2,2),stone)
  box('WallCap',(wx,5.4,2),(9,.5,2.5),cream)
  for dx in (-3,0,3):box('WallRail',(wx+dx,6.6,2),(.4,2,.4),gold)
  box('WallRailTop',(wx,7.6,2),(9,.3,.5),gold)
 # Blue-green water, flowers and lamps stay well outside the 24-stud corridor.
 box('WaterRill',(sg*15,.05,-23),(3,.18,30),(87,179,197))
 for rx in (sg*13,sg*17):box('WaterCurb',(rx,.2,-23),(.4,.4,31),cream)
 for j in range(4):
  cx=sg*29;cz=-12-j*8
  box('GardenBed',(cx,.4,cz),(10,.8,5),stone)
  box('Soil',(cx,.85,cz),(9,.15,4),(121,103,76))
  for dx in (-3,0,3):
   box('Leaves',(cx+dx,1.2,cz),(1.8,.5,1.6),(91,146,102),25)
   box('Flowers',(cx+dx,1.55,cz),(.9,.3,.9),[(230,171,183),(246,215,142),(185,175,225)][j%3],45)
 for z in (-13,-33):
  box('LampPost',(sg*21,3,z),(.4,6,.4),(98,113,106))
  box('Lamp',(sg*21,6.4,z),(1.8,1.8,1.8),(255,231,166))

# Masonry arch, no doors or bars: the lowest inner edge remains above headroom.
radius=15.5
for j in range(11):
 a=math.pi*j/10
 box('ArchStone',(radius*math.cos(a),13+radius*math.sin(a),0),(4.4,3.5,6),cream,roll=math.degrees(a)-90)
 box('ArchGoldInset',(radius*math.cos(a),13+radius*math.sin(a),-3.08),(2.3,1.1,.15),gold,roll=math.degrees(a)-90)
box('Crest',(0,31,0),(5,5,.9),teal,roll=45)
box('CrestInset',(0,31,-.55),(3.2,3.2,.18),gold,roll=45)
for n,p,s,c,m in parts:
 assert np.isfinite(p).all() and (s>0).all() and np.allclose(m.T@m,np.eye(3))
 if n in ('ReviewGround','OpenLevelWalk'):continue
 # Swept corner bounds must leave the ground-level central path unobstructed.
 corners=np.array([[x,y,z] for x in (-1,1) for y in (-1,1) for z in (-1,1)])*s/2@m.T+p
 if corners[:,1].min()<8:
  assert corners[:,0].min()>=12 or corners[:,0].max()<=-12,'entrance corridor obstructed'
assert len(parts)<260
out=save_review(parts,'LobbyGatewayReview','다음 로비 디자인 · 큰 아치 입구와 외곽 정원','게임 미적용 · 중앙24studs 평지 통로 · 문/출발 기능 추가 없음',(.52,.45,-1.1))
print(f'GATEWAY_REVIEW_PASS: {len(parts)} native Parts, 24-stud corridor clear, no game mutations; {out}')
