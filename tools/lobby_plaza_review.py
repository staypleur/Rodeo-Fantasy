"""Central garden proposal, review only; never patches the game place."""
import math
import numpy as np
from native_part_review import save_review

parts=[]
cream=(234,222,190);stone=(190,174,140);grass=(124,158,106)
def box(name,pos,size,color,angle=0):
 a=math.radians(angle);c,s=math.cos(a),math.sin(a)
 parts.append((name,np.array(pos,float),np.array(size,float),color,np.array([[c,0,s],[0,1,0],[-s,0,c]])))

# Flat center and eight unobstructed spokes: no fountain or raised spawn platform.
box('ReviewGround',(0,-.4,0),(158,.8,158),grass)
for x in range(-30,31,5):
 for z in range(-30,31,5):
  if x*x+z*z<30**2:box('PlazaTile',(x,.02,z),(4.9,.12,4.9),cream if (x+z)%10 else (216,202,167))
for i in range(8):
 a=i*math.pi/4
 box('OpenWalk',(math.sin(a)*55,.02,math.cos(a)*55),(12,.12,54),cream,i*45)
 # Garden alcoves occupy the gaps between walks, not their center lines.
 deg=i*45+22.5;a=math.radians(deg)
 def local(name,x,y,z,size,color,rot=0):
  box(name,(x*math.cos(a)+z*math.sin(a),y,-x*math.sin(a)+z*math.cos(a)),size,color,deg+rot)
 local('LowGardenBed',0,.35,44,(15,.7,7),stone)
 local('FlowerSoil',0,.73,44,(14,.15,6),(121,102,75))
 for x in (-5,-2.5,0,2.5,5):
  for z in (42,44,46):
   local('Leaf',x,1,z,(1.6,.4,1.2),(86,143,89),20)
   local('Flower',x,1.3,z,(.8,.3,.8),[(234,155,158),(242,206,120),(191,161,218)][i%3],45)
 # Open pergola, with all foliage kept above the walking headroom.
 for x in (-7,7):
  for z in (54,64):
   local('PergolaColumn',x,3.5,z,(.8,7,.8),cream)
   local('ColumnBase',x,.4,z,(1.4,.8,1.4),stone)
 for x in (-7,7):local('PergolaBeam',x,7.2,59,(1,.6,12),(167,130,85))
 for z in range(53,66,2):local('PergolaSlat',0,7.7,z,(16,.35,.6),(207,171,113))
 for x in (-7,7):
  for z in (55,59,63):local('VineCanopy',x,8,z,(2.8,.45,2.4),(105,163,114))
 local('BenchSeat',0,1.4,62,(9,.35,1.7),(159,120,79))
 local('BenchBack',0,2.4,62.8,(9,1.5,.35),(188,148,99))
 for x in (-3,3):local('BenchFoot',x,.7,62,(.7,1.4,1.4),stone)
 for x in (-11,11):
  local('LampPost',x,3,49,(.3,6,.3),(92,109,95))
  local('Lamp',x,6.1,49,(1.2,1.4,1.2),(249,236,174))

for name,pos,size,col,rot in parts:
 assert np.isfinite(pos).all() and (size>0).all()
 assert np.allclose(rot.T@rot,np.eye(3))
 if name in ('LowGardenBed','PergolaColumn','BenchSeat','LampPost'):
  # Closest spoke clearance, including the rotated box corners.
  for sx in (-1,1):
   for sz in (-1,1):
    p=pos+rot@np.array((sx*size[0]/2,0,sz*size[2]/2))
    for i in range(8):
     a=i*math.pi/4
     along=p[0]*math.sin(a)+p[2]*math.cos(a)
     cross=p[0]*math.cos(a)-p[2]*math.sin(a)
     assert not (28<along<82 and abs(cross)<6),'decoration blocks main walk'
out=save_review(parts,'LobbyPlazaGardenReview','다음 로비 검토안 · 중앙 광장과 8개 정원 쉼터','게임 미적용 · 비행선/상점 제외 · 중앙 평지와 8개 통로 유지')
print(f'PLAZA_REVIEW_PASS: {len(parts)} native Parts; eight clear walks; no game changes; {out}')
