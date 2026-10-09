"""Refine selected C as a textured, flat-shaded mesh; never install in game."""
import math
import numpy as np
from PIL import Image
import faceted_airship_mesh as F
mesh,tri,quad,loft=F.mesh,F.tri,F.quad,F.loft

# One small shared atlas; crisp eyes and height gradients without extra materials.
atlas=np.full((F.SIZE,F.SIZE,3),(53,84,154),dtype=np.uint8)
for kind,(tx,ty) in F.tiles.items():
 for y in range(F.TILE):
  for x in range(F.TILE):
   u=x/(F.TILE-1);v=y/(F.TILE-1)
   colors={'Fur':((50,76,140),(112,166,225)), 'Cream':((198,210,225),(247,239,209)),
           'Gold':((162,103,40),(247,218,129)), 'BlueLight':((94,133,200),(182,216,244)),
           'Crystal':((89,132,211),(210,241,252)), 'Dark':((24,31,55),(41,54,84)),
           'Ivory':((211,210,184),(255,248,221)), 'Mouth':((79,37,63),(203,112,134))}
   if kind=='Eye':
    px=(u-.5)*2;py=(v-.5)*2;r=(px/.92)**2+(py/1.03)**2
    c=np.array((81,49,31))*(1-v)+np.array((255,196,55))*v
    if r>.78:c=np.array((28,29,49))
    if (px/.28)**2+((py+.08)/.78)**2<1:c=np.array((18,24,40))
    if ((px+.27)/.26)**2+((py+.39)/.24)**2<1:c=np.array((255,254,237))
    if ((px-.36)/.11)**2+((py-.40)/.11)**2<1:c=np.array((255,226,153))
   else:
    low,high=map(np.array,colors[kind]);c=low*v+high*(1-v)
   atlas[ty*F.TILE+y,tx*F.TILE+x]=np.clip(c,0,255).astype(np.uint8)

loft('Core',[((0,2,-27),8,6),((0,2,-21),10,8),((0,1,-13),11,7.5),
             ((0,0,2),13,8),((0,-.4,18),10,6),((0,-1,27),4,3),((0,-1,30),1.2,1.2)],sides=10)

def plane(name,points,kind,z):
 m=mesh(name);p=np.array([(x,y,z) for x,y in points]);lo=p.min(axis=0);hi=p.max(axis=0)
 coords=[((x-lo[0])/(hi[0]-lo[0]),1-(y-lo[1])/(hi[1]-lo[1])) for x,y,_ in p]
 for j in range(1,len(p)-1):tri(m,[p[0],p[j],p[j+1]],[coords[0],coords[j],coords[j+1]],kind,(0,0,-1))
for sg,side in ((-1,'Left'),(1,'Right')):
 # Flat almond eyes embedded into the head's front facet, never sphere eyes.
 plane(side+'Eye',[(sg*2.6,3.3),(sg*2.7,5.1),(sg*5.1,6.15),(sg*6.1,5.55),(sg*5.3,2.85),(sg*3.4,2.8)],'Eye',-27.08)
 plane(side+'Cheek',[(sg*1.6,1.5),(sg*4.3,1.6),(sg*6.6,.25),(sg*5.7,-1.35),(sg*3.1,-1.8),(sg*1.6,-.8)],'Cream',-27.10)
plane('Smile',[(-2.1,-1.5),(0,-1.9),(2.1,-1.5),(1.5,-2.9),(0,-3.5),(-1.5,-2.9)],'Mouth',-27.15)

def tube(name,points,radii,kind,sides=6):
 m=mesh(name);points=np.array(points,float);rows=[]
 for i,c in enumerate(points):
  d=points[min(i+1,len(points)-1)]-points[max(i-1,0)];d/=np.linalg.norm(d)
  ref=(0,1,0) if abs(d[1])<.95 else (1,0,0)
  right=np.cross(d,ref);right/=np.linalg.norm(right);up=np.cross(d,right)
  rows.append([c+radii[i]*(right*math.cos(j*math.tau/sides)+up*math.sin(j*math.tau/sides)) for j in range(sides)])
 for i in range(len(rows)-1):
  for j in range(sides):
   k=(j+1)%sides
   quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(j/sides,0),(k/sides,0),(k/sides,1),(j/sides,1)],kind,rows[i][j]-points[i])
 for i in (0,len(rows)-1):
  direction=points[i]-points[1 if i==0 else -2]
  for j in range(sides):tri(m,[points[i],rows[i][j],rows[i][(j+1)%sides]],[(.5,.5),(0,0),(1,1)],kind,direction)
 return m
points=[(0,.5,-27),(0,-1,-30),(0,-3.8,-34),(0,-4.4,-38),(0,-2.3,-42),(0,1.4,-45),(0,5.4,-46)]
tube('Trunk',points,[2.5,2.4,2.1,1.9,1.55,1.25,.95],'Fur',8)
for sg,side in ((-1,'Left'),(1,'Right')):
 tube(side+'Tusk',[(sg*4.2,-.8,-27),(sg*4.7,-2,-30),(sg*5.1,-4.5,-33),(sg*5.2,-5,-36),(sg*4.8,-3.4,-38)],
      [1.1,.95,.75,.5,.06],'Ivory',6)

def blade(name,base,tip,width,kind,thickness=.65):
 m=mesh(name);base=np.array(base,float);tip=np.array(tip,float);axis=tip-base
 side=np.cross(axis,(0,1,0));side/=np.linalg.norm(side)
 # Six-edge tapered blade, central raised facet and a closed shallow back.
 shape=[(0,0),(-.45,.25),(-.4,.72),(0,1),(.4,.72),(.45,.25)]
 verts=[base+axis*y+side*x*width for x,y in shape]
 center=base+axis*.45+np.array((0,thickness,0));under=[p-np.array((0,thickness*.45,0)) for p in verts]
 uv=[(x+.5,1-y) for x,y in shape]
 for j in range(6):
  k=(j+1)%6
  tri(m,[verts[j],verts[k],center],[uv[j],uv[k],(.5,.55)],kind,(0,1,0))
  tri(m,[under[j],under[k],base+axis*.45-np.array((0,thickness*.45,0))],[uv[j],uv[k],(.5,.55)],kind,(0,-1,0))
  quad(m,[verts[j],under[j],under[k],verts[k]],[uv[j],uv[j],uv[k],uv[k]],kind,verts[j]-(base+axis*.45))
 return m
for sg,side in ((-1,'Left'),(1,'Right')):
 blade(side+'Ear',(sg*8,4,-21),(sg*14,7.7,-18),7,'BlueLight',1.3)
 blade(side+'WingRoot',(sg*10,1,-5),(sg*28,2,1),18,'Fur',1.3)
 for j in range(7):
  base=(sg*(16+j*1.2),1-j*.05,-1+j*1.5)
  tip=(sg*(38+j*2),1.5-j*.3,2+j*2.8)
  blade(side+'WingFeather'+str(j),base,tip,4.6,'BlueLight' if j%2 else 'Crystal',.7)
  b=np.array(base)+np.array((0,.9,0));t=b+(np.array(tip)-np.array(base))*.62
  blade(side+'WingGoldVein'+str(j),b,t,.6,'Gold',.18)
 blade(side+'TailFin',(sg*1,-1,25),(sg*14,-1,32),8,'Crystal',.7)

def crystal(name,center,width,height,kind):
 m=mesh(name);x,y,z=center
 ring=[np.array((x+math.cos(j*math.tau/4)*width,y,z+math.sin(j*math.tau/4)*width)) for j in range(4)]
 for j in range(4):
  k=(j+1)%4
  tri(m,[(x,y+height,z),ring[j],ring[k]],[(.5,0),(0,.8),(1,.8)],kind,ring[j]-np.array(center)+(0,height*.3,0))
  tri(m,[(x,y-height*.3,z),ring[j],ring[k]],[(.5,1),(0,.8),(1,.8)],'Gold',ring[j]-np.array(center)-(0,height*.3,0))
for j in range(5):
 x=(j-2)*2.6;crystal('CrownCrystal'+str(j),(x,9.1,-21),1.25,5.5-abs(j-2),'Crystal')
for j,z in enumerate((-10,-1,9,19)):
 crystal('BackCrystal'+str(j),(0,8-j*.7,z),1.5,3.5-j*.35,'BlueLight')

# Validate every face, flat normal, atlas UV and the mobile geometry budget.
for m in F.meshes:
 p=np.array(m['p']);n=np.array(m['n']);uv=np.array(m['uv'])
 assert np.isfinite(p).all() and np.isfinite(n).all() and ((uv>=0)&(uv<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(n[i],n[i+1]) and np.allclose(n[i],n[i+2])
  actual=np.cross(p[i+1]-p[i],p[i+2]-p[i]);assert np.dot(actual,n[i])>1e-8
count=F.save(Image.fromarray(atlas))
assert count<2000
print(f'C_REFINEMENT_PASS: {count} flat triangles / {len(F.meshes)} parts / one 512px atlas and material / review only')
