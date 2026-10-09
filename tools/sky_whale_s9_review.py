"""Larger, ornate nine-star whale review; does not overwrite the installed whale."""
import math
import numpy as np
from PIL import Image
import faceted_airship_mesh as F
from sky_whale_review import atlas,blade,crystal,rings
def surface(side,z,y,extra=.12):
 for i in range(len(rings)-1):
  c,rx,ry=rings[i];nc,nrx,nry=rings[i+1]
  if c[2]<=z<=nc[2]:
   t=(z-c[2])/(nc[2]-c[2]);rx=rx*(1-t)+nrx*t;ry=ry*(1-t)+nry*t;cy=c[1]*(1-t)+nc[1]*t
   for j in range(3):
    a=j*math.pi/6;b=(j+1)*math.pi/6
    ya,yb=cy+math.sin(a)*ry,cy+math.sin(b)*ry
    if ya<=y<=yb:
     f=(y-ya)/(yb-ya);x=rx*(math.cos(a)*(1-f)+math.cos(b)*f)
     return (side*(x+extra),y,z)
 raise ValueError((z,y))
F.STEM='SkyWhale_S9RoyalReview'
F.meshes[:]=[m for m in F.meshes if not m['name'].startswith('ForeheadCrystal')]
for j in range(5):
 crystal('S9CrownCrystal'+str(j),((j-2)*4.4,18.8,-24),2.3,10-abs(j-2)*2,'Crystal')
for sg,side in ((-1,'Left'),(1,'Right')):
 # Golden filigree follows the head surface, with a connected central jewel.
 for j in range(3):
  points=[surface(sg,-39+j*2,12+j*.9,.2),surface(sg,-34+j*2,13+j*.9,.2),surface(sg,-29+j*2,12+j*.9,.2)]
  from airship_c_faceted_refinement import tube
  tube(side+'RoyalHeadScroll'+str(j),points,[.25,.32,.18],'Gold',5)
 for j in range(3):
  blade(side+'S9FinEtching'+str(j),(sg*(23+j*3),.5-j*.6,-13+j*5),
        (sg*(43+j),-5.3-j*.5,9+j*3),.55,'Gold',.25)
 crystal(side+'FinJewel',(sg*28,1,-4),1.5,2.5,'Crystal')
 # Small gold edging on the broad tail, not feather wings.
 for j in range(2):
  blade(side+'S9TailEtching'+str(j),(sg*(5+j*5),6,61+j*2),
        (sg*(24+j*4),10,73+j*2),.65,'Gold',.25)

for j,(z,y) in enumerate(((-8,20),(4,19),(17,16))):
 crystal('S9BackGem'+str(j),(0,y,z),2,4.2-j*.4,'Crystal')
# Uniform enlargement plus a slightly deeper silhouette. Recompute flat normals
# after non-uniform scaling so the shading remains correct.
for m in F.meshes:
 p=np.asarray(m['p'],float)
 if 'Tail' in m['name']:p[:,0]*=1.15
 p*=np.array((1.4,1.54,1.4))
 m['p']=p.tolist()
 for i in range(0,len(p),3):
  normal=np.cross(p[i+1]-p[i],p[i+2]-p[i]);normal/=np.linalg.norm(normal)
  m['n'][i:i+3]=[normal.tolist()]*3
 assert np.isfinite(p).all() and ((np.asarray(m['uv'])>=0)&(np.asarray(m['uv'])<=1)).all()
count=F.save(Image.fromarray(atlas))
assert count<2000
allpos=np.concatenate([np.asarray(m['p']) for m in F.meshes]);extent=np.ptp(allpos,axis=0)
assert extent[2]>190 and len(F.meshes)<45
print(f'S9_WHALE_REVIEW_PASS: {count} triangles / {len(F.meshes)} objects / length x1.4 / shared atlas; game unchanged')
