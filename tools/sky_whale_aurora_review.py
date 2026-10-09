"""Original sky whale body review: no wings, tusks or game installation."""
import math
import numpy as np
from PIL import Image
import faceted_airship_mesh as F
from airship_c_faceted_refinement import atlas, blade, crystal, tube
F.meshes.clear();F.STEM='SkyWhale_AuroraReview'

# A broad whale head flows directly into the chest and tapering tail stock.
rings=[((0,8,-62),13,12),((0,8,-57),25,19),((0,8,-44),31,23),
 ((0,7,-20),29,22),((0,5,10),21,17),((0,3,38),10,8),((0,2,65),3,3),((0,2,82),2,2)]
body=F.mesh('WhaleBody');rows=[];sides=12
for c,rx,ry in rings:
 rows.append([np.array(c)+np.array((math.cos(j*math.tau/sides)*rx,math.sin(j*math.tau/sides)*ry,0)) for j in range(sides)])
for i in range(len(rows)-1):
 for j in range(sides):
  k=(j+1)%sides
  kind='Cream' if math.sin((j+.5)*math.tau/sides)<-.35 else 'Fur'
  pts=[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]]
  F.quad(body,pts,[(.5+p[0]/70,np.clip(1-(p[1]+15)/46,0,1)) for p in pts],kind,rows[i][j]-np.array(rings[i][0]))
for idx,d in ((0,(0,0,-1)),(-1,(0,0,1))):
 for j in range(sides):
  pts=[np.array(rings[idx][0]),rows[idx][j],rows[idx][(j+1)%sides]]
  F.tri(body,pts,[(.5+p[0]/70,np.clip(1-(p[1]+15)/46,0,1)) for p in pts],'Fur',d)

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

def ribbon(name,centers,widths):
 m=F.mesh(name);rows=[]
 for i,c in enumerate(centers):
  c=np.array(c,float);d=np.array(centers[min(i+1,len(centers)-1)])-np.array(centers[max(i-1,0)])
  cross=np.array([-d[2],0,d[0]],float);cross/=np.linalg.norm(cross)
  rows.append([c+cross*widths[i]/2+(0,.8,0),c-cross*widths[i]/2+(0,.8,0),c+cross*widths[i]/2-(0,.8,0),c-cross*widths[i]/2-(0,.8,0)])
 for i in range(len(rows)-1):
  a,b=rows[i],rows[i+1];u=i/(len(rows)-1);v=(i+1)/(len(rows)-1)
  F.quad(m,[a[0],a[1],b[1],b[0]],[(0,u),(1,u),(1,v),(0,v)],'BlueLight',(0,1,0))
  F.quad(m,[a[2],b[2],b[3],a[3]],[(0,0),(0,1),(1,1),(1,0)],'Fur',(0,-1,0))
  for j,k in ((0,2),(1,3)):
   F.quad(m,[a[j],b[j],b[k],a[k]],[(0,0),(1,0),(1,1),(0,1)],'BlueLight',a[j]-np.array(centers[i]))
 for i in (0,-1):F.quad(m,rows[i],[(0,0),(1,0),(0,1),(1,1)],'BlueLight',(0,0,-1 if i==0 else 1))

for sg,side in ((-1,'Left'),(1,'Right')):
 m=F.mesh(side+'Eye')
 shape=[(-54,12),(-54,17),(-51,18),(-46.5,15.7),(-48,11.3),(-51,10.8)]
 pts=[surface(sg,z,y) for z,y in shape]
 uv=[((z+54)/7.5,1-(y-10.8)/7.2) for z,y in shape]
 for j in range(1,len(pts)-1):F.tri(m,[pts[0],pts[j],pts[j+1]],[uv[0],uv[j],uv[j+1]],'Eye',(sg,.2,0))
 # Broad aurora ribbons taper into several long tips; no feathers or copied armor.
 ribbon(side+'PectoralFin',[(sg*24,-3,-32),(sg*44,-10,-10),(sg*65,-13,20),(sg*68,-5,48),(sg*59,1,69)],[6,22,17,8,1])
 ribbon(side+'LowerCurrentFin',[(sg*24,-10,-5),(sg*39,-18,12),(sg*49,-20,42),(sg*40,-13,64)],[5,12,9,1])
 ribbon(side+'RearCurrentFin',[(sg*13,-7,27),(sg*29,-12,49),(sg*27,-6,75),(sg*18,-2,87)],[4,10,7,1])
 # Broad flukes rise gently; a central notch separates their two lobes.
 m=F.mesh(side+'TailFluke')
 pts=[np.array((sg*x,y,z),float) for x,y,z in [(0,2,78),(16,5,82),(39,9,94),(30,13,108),(13,7,98),(0,3,87)]]
 center=np.array((sg*17,8,91));under=[p-(0,1.7,0) for p in pts]
 for j in range(6):
  k=(j+1)%6
  uv=[(.5,0),(.3,.2),(0,.4),(0,1),(.3,.8),(.5,1)]
  F.tri(m,[pts[j],pts[k],center],[uv[j],uv[k],(.4,.5)],'BlueLight',(0,1,0))
  F.tri(m,[under[j],under[k],center-(0,3.5,0)],[uv[j],uv[k],(.4,.5)],'BlueLight',(0,-1,0))
  F.quad(m,[pts[j],under[j],under[k],pts[k]],[uv[j],uv[j],uv[k],uv[k]],'BlueLight',pts[j]-center)


# Original calm mouth and luminous cheek chevrons, no horn/crown harness.
tube('MouthLine',[(-9,1.5,-62.18),(-5,.6,-62.18),(0,.3,-62.18),(5,.6,-62.18),(9,1.5,-62.18)],[.28]*5,'Dark',5)
for sg,side in ((-1,'Left'),(1,'Right')):
 for j in range(3):
  z=-34+j*5
  tube(side+'LuminousCheek'+str(j),[surface(sg,z,14,.23),surface(sg,z+1.5,11,.23),surface(sg,z+1,8,.23)],[.30]*3,'Ivory',4)
# Repaint only this review's atlas; keep a single embedded 512 texture.
for kind,low,high in [('Fur',(18,81,119),(78,205,210)),('BlueLight',(43,133,158),(162,240,219)),('Cream',(208,225,209),(254,249,222))]:
 tx,ty=F.tiles[kind]
 for y in range(F.TILE):
  v=y/(F.TILE-1);atlas[ty*F.TILE+y,tx*F.TILE:(tx+1)*F.TILE]=np.array(low)*v+np.array(high)*(1-v)
for m in F.meshes:
 m['p']=(np.asarray(m['p'])*1.25).tolist()

for m in F.meshes:
 p=np.asarray(m['p']);n=np.asarray(m['n']);uv=np.asarray(m['uv'])
 assert np.isfinite(p).all() and np.isfinite(n).all() and ((uv>=0)&(uv<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(n[i],n[i+1]) and np.allclose(n[i],n[i+2])
  assert np.dot(np.cross(p[i+1]-p[i],p[i+2]-p[i]),n[i])>1e-8
assert not any(any(k in m['name'] for k in ('Tusk','Trunk','Wing','Feather','Crown')) for m in F.meshes)
count=F.save(Image.fromarray(atlas))
assert count<2000
print(f'AURORA_WHALE_PASS: {count} triangles / {len(F.meshes)} nodes / shared 512px texture / static body review only')
