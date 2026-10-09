"""Original sky whale body review: no wings, tusks or game installation."""
import math
import numpy as np
from PIL import Image
import faceted_airship_mesh as F
from airship_c_faceted_refinement import atlas, blade, crystal, tube
F.meshes.clear();F.STEM='SkyWhale_BodyReview'

# A broad whale head flows directly into the chest and tapering tail stock.
rings=[((0,2,-58),3,2.5),((0,3,-54),10,6),((0,4,-49),15,10),((0,5,-44),18,12),((0,4,-28),23,16),
       ((0,3,-5),23,18),((0,2,16),18,14),((0,1,34),10,8),
       ((0,1,49),4.5,3.5),((0,2,60),3,2.5)]
body=F.mesh('WhaleBody');rows=[];sides=12
for c,rx,ry in rings:
 rows.append([np.array(c)+np.array((math.cos(j*math.tau/sides)*rx,math.sin(j*math.tau/sides)*ry,0)) for j in range(sides)])
for i in range(len(rows)-1):
 for j in range(sides):
  k=(j+1)%sides
  kind='Cream' if math.sin((j+.5)*math.tau/sides)<-.35 else 'Fur'
  pts=[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]]
  F.quad(body,pts,[(.5+p[0]/50,np.clip(1-(p[1]+17)/39,0,1)) for p in pts],kind,rows[i][j]-np.array(rings[i][0]))
for idx,d in ((0,(0,0,-1)),(-1,(0,0,1))):
 for j in range(sides):
  pts=[np.array(rings[idx][0]),rows[idx][j],rows[idx][(j+1)%sides]]
  F.tri(body,pts,[(.5+p[0]/50,np.clip(1-(p[1]+17)/39,0,1)) for p in pts],'Fur',d)

def surface(side,z,y,extra=.12):
 for i in range(len(rings)-1):
  c,rx,ry=rings[i];nc,nrx,nry=rings[i+1]
  if c[2]<=z<=nc[2]:
   t=(z-c[2])/(nc[2]-c[2]);rx=rx*(1-t)+nrx*t;ry=ry*(1-t)+nry*t
   cy=c[1]*(1-t)+nc[1]*t
   # Eye sits on the first upper lateral facet, never on a floating ball.
   x=rx*(1-(1-math.cos(math.pi/6))*(y-cy)/(ry*.5))
   return (side*(x+extra),y,z)
 raise ValueError(z)

for sg,side in ((-1,'Left'),(1,'Right')):
 m=F.mesh(side+'Eye')
 shape=[(-37,6),(-37,9),(-34.5,10.1),(-31.8,9),(-31.8,6),(-34.5,5.2)]
 pts=[surface(sg,z,y) for z,y in shape]
 uv=[((z+37)/5.2,1-(y-5.2)/4.9) for z,y in shape]
 for j in range(1,len(pts)-1):F.tri(m,[pts[0],pts[j],pts[j+1]],[uv[0],uv[j],uv[j+1]],'Eye',(sg,.2,0))
 # Long pectoral fins sweep backwards, unlike feather wings.
 blade(side+'PectoralFin',(sg*17,-2,-19),(sg*49,-10,18),19,'BlueLight',3.2)
 blade(side+'FinGoldInlay',(sg*21,.6,-16),(sg*44,-6.6,14),1.1,'Gold',.35)
 # Broad flukes rise gently; a central notch separates their two lobes.
 m=F.mesh(side+'TailFluke')
 pts=[np.array((sg*x,y,z),float) for x,y,z in [(0,2,57),(15,5,59),(34,9,71),(28,10,79),(12,6,72),(0,3,64)]]
 center=np.array((sg*14,8,67));under=[p-(0,1.7,0) for p in pts]
 for j in range(6):
  k=(j+1)%6
  uv=[(.5,0),(.3,.2),(0,.4),(0,1),(.3,.8),(.5,1)]
  F.tri(m,[pts[j],pts[k],center],[uv[j],uv[k],(.4,.5)],'BlueLight',(0,1,0))
  F.tri(m,[under[j],under[k],center-(0,3.5,0)],[uv[j],uv[k],(.4,.5)],'BlueLight',(0,-1,0))
  F.quad(m,[pts[j],under[j],under[k],pts[k]],[uv[j],uv[j],uv[k],uv[k]],'BlueLight',pts[j]-center)
 blade(side+'TailGoldInlay',(sg*3,5,59),(sg*27,11,73),1.1,'Gold',.35)

# Dorsal fin is vertical, a clear whale silhouette from the side.
m=F.mesh('DorsalFin')
outline=[(0,14,12),(0,27,24),(0,21,28),(0,9,35)]
front=[np.array(p)+(-1.1,0,0) for p in outline];back=[np.array(p)+(1.1,0,0) for p in outline]
for pts,hint in ((front,(-1,0,0)),(back,(1,0,0))):
 F.quad(m,pts,[(0,1),(.5,0),(1,.3),(1,1)],'Fur',hint)
for j in range(4):
 k=(j+1)%4
 F.quad(m,[front[j],back[j],back[k],front[k]],[(0,0),(1,0),(1,1),(0,1)],'BlueLight',np.array(outline[j])-np.array((0,17,24)))

# A quiet curved mouth, soft ivory underside and three gold-trimmed crystals.
tube('MouthLine',[(-14,-.8,-48),(-9,-1.1,-53),(-3,-.5,-57),
     (3,-.5,-57),(9,-1.1,-53),(14,-.8,-48)],[.32]*6,'Dark',5)
for j in range(3):
 crystal('ForeheadCrystal'+str(j),((j-1)*4.8,18,-23),1.9,5.5 if j==1 else 3.4,'Crystal')

# Chest and rear gold harness follow the actual facets of the whale body.
for i in (4,6):
 m=F.mesh('RoyalHarness'+str(i));c,rx,ry=rings[i]
 for j in range(sides):
  k=(j+1)%sides
  p=[np.array(c)+np.array((math.cos(a*math.tau/sides)*(rx+.14),math.sin(a*math.tau/sides)*(ry+.14),dz)) for a,dz in ((j,-.4),(k,-.4),(k,.4),(j,.4))]
  F.quad(m,p,[(0,0),(1,0),(1,1),(0,1)],'Gold',p[0]-np.array(c))

for m in F.meshes:
 p=np.asarray(m['p']);n=np.asarray(m['n']);uv=np.asarray(m['uv'])
 assert np.isfinite(p).all() and np.isfinite(n).all() and ((uv>=0)&(uv<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(n[i],n[i+1]) and np.allclose(n[i],n[i+2])
  assert np.dot(np.cross(p[i+1]-p[i],p[i+2]-p[i]),n[i])>1e-8
assert not any(any(k in m['name'] for k in ('Tusk','Trunk','Wing','Feather')) for m in F.meshes)
count=F.save(Image.fromarray(atlas))
print(f'SKY_WHALE_PASS: {count} triangles / {len(F.meshes)} nodes / shared 512px texture / static body review only')
