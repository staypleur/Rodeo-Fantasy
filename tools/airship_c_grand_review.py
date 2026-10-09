"""Majestic C redesign: static geometry review, never a game installer."""
import numpy as np
import math
from PIL import Image
import faceted_airship_mesh as F
# Reuse the atlas and closed mesh construction primitives from the earlier review.
from airship_c_faceted_refinement import atlas, tube, blade, crystal, plane
F.meshes.clear()
F.STEM='Airship_C_GrandReview'

# Deep chest, large forehead and short powerful silhouette instead of a flat tube.
F.loft('SovereignBody',[
 ((0,7,-34),11,12),((0,8,-29),17,17),((0,7,-18),20,21),
 ((0,4,-2),23,23),((0,2,16),21,20),((0,0,30),14,14),
 ((0,-1,40),7,7),((0,-1,46),2,2)],sides=12)

# Thin royal harness follows the body's facets instead of floating as beads.
for name,z,cy,rx,ry in [('ForwardHarness',-17,6.8,20.5,21.5),('RearHarness',16,2,21.3,20.3)]:
 m=F.mesh(name)
 rows=[[np.array((math.cos(j*math.tau/12)*rx,cy+math.sin(j*math.tau/12)*ry,z+offset)) for j in range(12)] for offset in (-.55,.55)]
 for j in range(12):
  k=(j+1)%12
  F.quad(m,[rows[0][j],rows[0][k],rows[1][k],rows[1][j]],[(0,0),(1,0),(1,1),(0,1)],'Gold',rows[0][j]-np.array((0,cy,z)))

for sg,side in ((-1,'Left'),(1,'Right')):
 # Adult, smaller eyes sit in the forehead rather than fill the whole face.
 plane(side+'Eye',[(sg*4.6,10.3),(sg*4.8,14),(sg*7.2,15.1),
                  (sg*9.1,13.6),(sg*8.5,9.4),(sg*6.1,9.1)],'Eye',-34.13)
 plane(side+'Brow',[(sg*4.4,14.7),(sg*7,16.3),(sg*9.8,14.7),
                   (sg*9.4,13.8),(sg*7,14.9)],'Gold',-34.2)
 # Volumetric muzzle lobes and integrated ivory tusks.
 F.loft(side+'Muzzle',[
  ((sg*4.7,3,-37),3.6,3.2),((sg*5,3,-35.2),5,4.6),
  ((sg*5,3,-31),4,4)],kind='Cream',sides=8)
 tube(side+'GreatTusk',[(sg*6.4,1,-35),(sg*8.5,-5,-38),
       (sg*10.5,-11,-41),(sg*12,-15,-47),(sg*12,-13,-53),
       (sg*10.4,-8,-56)],[2.4,2.3,2,1.65,1,.08],'Ivory',8)
 blade(side+'Ear',(sg*13,9,-24),(sg*24,13,-17),15,'BlueLight',3.5)

tube('GrandTrunk',[(0,6,-34),(0,0,-40),(0,-9,-44),(0,-18,-48),
     (0,-22,-54),(0,-20,-61),(0,-13,-66),(0,-5,-66)],
     [4.8,4.7,4.25,3.65,3.1,2.6,2.1,1.7],'Fur',10)
# Three broad relief bands follow the trunk curve, a deliberate royal motif.
for j,(a,b,r) in enumerate([
 ((0,-1,-40.5),(0,-2.8,-41.3),4.72),
 ((0,-10,-44.6),(0,-11.6,-45.3),4.16),
 ((0,-18.4,-48.7),(0,-19.4,-50),3.6)]):
 tube('TrunkGoldBand'+str(j),[a,b],[r,r*.97],'Gold',10)

for sg,side in ((-1,'Left'),(1,'Right')):
 # Raised, broad wings: thick shoulders, overlapping coverts and long primaries.
 blade(side+'WingShoulder',(sg*15,9,-10),(sg*42,24,-3),42,'Fur',5)
 for j in range(7):
  b=np.array((sg*(29+j*2),21-j*.65,-17+j*5.4))
  t=np.array((sg*(89-j*3.5),38-j*3.1,-22+j*10))
  blade(side+'GreatFeather'+str(j),b,t,12.5,'Crystal' if j%2==0 else 'BlueLight',2.5)
  blade(side+'GoldFeatherRidge'+str(j),b+(0,2.7,0),b+(t-b)*.70+(0,2.7,0),1.5,'Gold',.5)
 for j in range(4):
  blade(side+'WingCovert'+str(j),(sg*(21+j*2),22-j,-13+j*7),
        (sg*(53+j*1.5),29-j*2,-10+j*8),10,'Fur',2)
 blade(side+'TailFin',(sg*2,-1,39),(sg*23,4,51),15,'BlueLight',2)
 blade(side+'TailGold',(sg*3,1,39),(sg*18,5,49),1.7,'Gold',.6)

# A small deliberate crown and a connected dorsal crest; no random spike cluster.
for j in range(3):
 crystal('RoyalCrown'+str(j),((j-1)*5.5,22,-25),2.5,10 if j==1 else 6.5,'Crystal')
for j,z in enumerate((-7,8,22)):
 crystal('DorsalCrystal'+str(j),(0,26-j*3,z),3,6-j,'Crystal')

for m in F.meshes:
 p=np.asarray(m['p']);n=np.asarray(m['n']);uv=np.asarray(m['uv'])
 assert np.isfinite(p).all() and np.isfinite(n).all()
 assert ((uv>=0)&(uv<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(n[i],n[i+1]) and np.allclose(n[i],n[i+2])
  assert np.dot(np.cross(p[i+1]-p[i],p[i+2]-p[i]),n[i])>1e-8
count=F.save(Image.fromarray(atlas))
assert count<2000
allpos=np.concatenate([np.asarray(m['p']) for m in F.meshes])
extent=np.ptp(allpos,axis=0)
assert extent[0]>160 and extent[1]>55 and extent[2]>110
print(f'GRAND_C_PASS: {count} flat triangles; extent {extent.round(1)}; review only; no animation or device test')
