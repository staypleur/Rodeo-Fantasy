"""Original regal sky whale: crescent crest, broad fins and constellation markings; review only."""
import math
import numpy as np
from PIL import Image
import faceted_airship_mesh as F
from airship_c_faceted_refinement import atlas, blade, crystal, tube
F.meshes.clear();F.STEM='SkyWhale_RegalReview'

# A broad whale head flows directly into the chest and tapering tail stock.
rings=[((0,0,-75),1.5,2),((0,1,-71),7,6),((0,3,-65),15,11),
 ((0,6,-56),24,18),((0,8,-44),31,23),
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
 blade(side+'PectoralFin',(sg*24,-3,-30),(sg*82,-7,32),38,'BlueLight',3)
 ribbon(side+'RearCurrentFin',[(sg*15,-5,23),(sg*34,-10,48),(sg*37,-4,74),(sg*24,3,92)],[5,15,10,1])
 # Broad flukes rise gently; a central notch separates their two lobes.
 m=F.mesh(side+'TailFluke')
 pts=[np.array((sg*x,y,z),float) for x,y,z in [(0,2,78),(16,5,82),(45,9,94),(36,15,112),(13,7,98),(0,3,87)]]
 center=np.array((sg*17,8,91));under=[p-(0,1.7,0) for p in pts]
 for j in range(6):
  k=(j+1)%6
  uv=[(.5,0),(.3,.2),(0,.4),(0,1),(.3,.8),(.5,1)]
  F.tri(m,[pts[j],pts[k],center],[uv[j],uv[k],(.4,.5)],'BlueLight',(0,1,0))
  F.tri(m,[under[j],under[k],center-(0,3.5,0)],[uv[j],uv[k],(.4,.5)],'BlueLight',(0,-1,0))
  F.quad(m,[pts[j],under[j],under[k],pts[k]],[uv[j],uv[j],uv[k],uv[k]],'BlueLight',pts[j]-center)


# Calm mouth and bold current markings; a new crescent crest defines the final stage.
tube('MouthLine',[(-10,0,-69),(-5,-1,-72),(0,-.4,-75.2),(5,-1,-72),(10,0,-69)],[.28]*5,'Dark',5)
for sg,side in ((-1,'Left'),(1,'Right')):
 for j in range(3):
  z=-32+j*9
  tube(side+'LuminousCheek'+str(j),[surface(sg,z,17,.35),surface(sg,z+4,13,.35),surface(sg,z+2,8,.35)],[.65,1.0,.6],'Ivory',4)
# Split crescent diadem: an open swept crest rather than a circular sun-ray halo.
for sg,side in ((-1,'Left'),(1,'Right')):
 tube(side+'CrescentDiadem',[(sg*24,21,-35),(sg*32,34,-29),(sg*31,49,-20),(sg*22,62,-11),(sg*7,71,-3)], [2.8,3.0,2.7,2.0,.3],'Gold',5)
 blade(side+'CrestSail',(sg*28,38,-24),(sg*49,62,-3),9,'Gold',1.1)
 blade(side+'CheekGuard',(sg*26,15,-44),(sg*34,0,-24),5.5,'Gold',.8)
 # A clean ivory/gold current motif follows the fin surface.
 tube(side+'FinCurrent',[(sg*33,.1,-20),(sg*49,-.3,-2),(sg*67,-1.7,16),(sg*78,-4.6,28)],[.55,1.1,.8,.15],'Ivory',4)
 blade(side+'FinInlay',(sg*41,.3,-12),(sg*62,-.9,11),2.0,'Gold',.35)
 crystal(side+'CrestGem',(sg*31,43,-24),3.0,7,'Crystal')
# A bevelled sapphire on a broad gold brow plate, integrated into the forehead.
for name,radius,kind,depth in [('ForeheadBezel',8,'Gold',-56.8),('ForeheadJewel',5.8,'Crystal',-57.5)]:
 m=F.mesh(name);center=np.array((0,24,depth-1.8))
 ring=[np.array((math.cos(j*math.tau/6)*radius,24+math.sin(j*math.tau/6)*radius*.72,depth)) for j in range(6)]
 for j in range(6):F.tri(m,[center,ring[j],ring[(j+1)%6]],[(.5,.15),(0,.8),(1,.8)],kind,(0,.1,-1))
for sg,side in ((-1,'Left'),(1,'Right')):
 tube(side+'BrowGold',[(sg*4,26,-57),(sg*12,26,-53),(sg*19,27,-46)],[1.4,1.6,.3],'Gold',5)
# Broad ivory diamond outlines sit on the faceted skin, visible at lobby distance.
def top_skin(x,z):
 for i in range(len(rings)-1):
  c,rx,ry=rings[i];nc,nrx,nry=rings[i+1]
  if c[2]<=z<=nc[2]:
   t=(z-c[2])/(nc[2]-c[2]);rx=rx*(1-t)+nrx*t;ry=ry*(1-t)+nry*t
   q=abs(x)/rx
   if q>.8660254:h=(1-q)/.1339746*.5
   elif q>.5:h=.8660254-(q-.5)
   else:h=1-q*.2679492
   return (x,c[1]*(1-t)+nc[1]*t+ry*h+.3,z)
 raise ValueError(z)
for number,(z,width,length) in enumerate([(-33,10,14),(-3,7,11),(22,4.5,8)]):
 m=F.mesh('IvoryConstellationMark'+str(number))
 outer=[(0,z-length),(width,z),(0,z+length),(-width,z)]
 inner=[(0,z-length*.66),(width*.66,z),(0,z+length*.66),(-width*.66,z)]
 for j in range(4):
  k=(j+1)%4
  F.quad(m,[top_skin(*outer[j]),top_skin(*outer[k]),top_skin(*inner[k]),top_skin(*inner[j])],[(0,0),(1,0),(1,1),(0,1)],'Ivory',(0,1,0))
# Three unmistakable diamonds form an independent constellation on the back.
for j in range(3):
 crystal('BackConstellation'+str(j),(0,29-j*5,-15+j*22),3.0-j*.45,5.5-j*.9,'Crystal')
# Repaint only this review's atlas; keep a single embedded 512 texture.
for kind,low,high in [('Fur',(18,81,119),(78,205,210)),('BlueLight',(43,133,158),(162,240,219)),('Cream',(208,225,209),(254,249,222)),('Crystal',(8,35,118),(74,177,232))]:
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
assert not any(any(k in m['name'] for k in ('Tusk','Trunk','Wing','Feather')) for m in F.meshes)
count=F.save(Image.fromarray(atlas))
assert count<2000
print(f'REGAL_WHALE_PASS: {count} triangles / {len(F.meshes)} nodes / shared 512px texture / static body review only')
