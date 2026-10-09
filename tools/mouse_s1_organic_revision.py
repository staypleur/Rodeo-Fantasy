"""Review-only connected mouse skin and soft expression; never modifies game templates."""
from pathlib import Path
import math
import numpy as np
from meadow_models import components
from export_creature_meshes import geometry,transform
from export_roblox_glb import make_glb
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'assets/meshes/review';folder.mkdir(parents=True,exist_ok=True)
obj=folder/'MeadowMouse_A_S1_OrganicReview.obj'
# Smooth union of anatomical volumes, instead of detached body/leg primitives.
volumes=[((0,-.14,.45),(.98,.88,1.22),0),((0,.02,-.6),(.77,.75,.8),0),
 ((0,.58,-1.1),(1.06,.92,.86),0),((0,.25,-1.77),(.73,.42,.43),0)]
for side in (-1,1):
 volumes.extend([((side*.63,-1.02,-.65),(.34,.62,.37),0),((side*.63,-1.43,-.8),(.43,.28,.47),0),
  ((side*.66,-.98,1.12),(.38,.61,.4),0),((side*.66,-1.42,1.0),(.44,.28,.49),0),
  ((side*1.02,1.4,-1.01),(.64,.80,.18),side*-15)])
def field(points):
 result=None
 for center,radii,angle in volumes:
  q=points-np.array(center);a=math.radians(angle)
  x=q[...,0]*math.cos(a)+q[...,1]*math.sin(a)
  y=-q[...,0]*math.sin(a)+q[...,1]*math.cos(a)
  d=(np.sqrt((x/radii[0])**2+(y/radii[1])**2+(q[...,2]/radii[2])**2)-1)*min(radii)
  if result is None:result=d
  else:
   k=.10;h=np.maximum(k-np.abs(result-d),0)/k
   result=np.minimum(result,d)-h*h*k*.25
 return result
axes=[np.arange(-1.9,1.91,.12),np.arange(-1.86,2.31,.12),np.arange(-2.4,1.951,.12)]
x,y,z=np.meshgrid(*axes,indexing='ij');grid=np.stack((x,y,z),axis=-1);values=field(grid)
offsets=np.array([(0,0,0),(1,0,0),(1,1,0),(0,1,0),(0,0,1),(1,0,1),(1,1,1),(0,1,1)])
corners=np.stack([values[i:values.shape[0]-1+i,j:values.shape[1]-1+j,k:values.shape[2]-1+k] for i,j,k in offsets],axis=-1)
cells=np.argwhere((corners.min(axis=-1)<=0)&(corners.max(axis=-1)>0))
tetra=((0,5,1,6),(0,1,2,6),(0,2,3,6),(0,3,7,6),(0,7,4,6),(0,4,5,6))
triangles=[]
for cell in cells:
 indices=cell+offsets;v=grid[indices[:,0],indices[:,1],indices[:,2]];d=values[indices[:,0],indices[:,1],indices[:,2]]
 for tet in tetra:
  inside=[i for i in tet if d[i]<0];outside=[i for i in tet if d[i]>=0]
  if not inside or not outside:continue
  def edge(i,j):return v[i]+(v[j]-v[i])*(d[i]/(d[i]-d[j]))
  if len(inside)==1:polys=[tuple(edge(inside[0],j) for j in outside)]
  elif len(inside)==3:polys=[tuple(edge(outside[0],j) for j in inside)]
  else:
   a,b=inside;c,e=outside;p0,p1,p2,p3=edge(a,c),edge(a,e),edge(b,c),edge(b,e)
   polys=[(p0,p1,p3),(p0,p3,p2)]
  for tri in polys:
   a,b,c=tri;normal=np.cross(b-a,c-a)
   if np.linalg.norm(normal)<1e-9:continue
   center=(a+b+c)/3;n=normal/np.linalg.norm(normal)
   if field(center+n*.003)<field(center-n*.003):tri=(a,c,b)
   triangles.append(tri)
lines=['# Review-only continuous skin; +Y up -Z forward',f'mtllib {obj.stem}.mtl'];mats=[];offset=1
colors=[(210,169,120),(244,232,206)]
def paint_field(point):
 x,y,z=point
 face=max((x/.89)**2+((y-.44)/.73)**2-1,z+1.40)
 chest=max((x/.67)**2+((y+.34)/.75)**2-1,z+.58)
 return min(face,chest,y+1.35)
def clipped(tri,material):
 out=[]
 for i,a in enumerate(tri):
  b=tri[(i+1)%3];da,db=paint_field(a),paint_field(b)
  inside_a=(da<=0) if material==1 else (da>=0)
  inside_b=(db<=0) if material==1 else (db>=0)
  if inside_a!=inside_b:out.append(a+(b-a)*da/(da-db))
  if inside_b:out.append(b)
 return out
skin_vertices={}
for material,color in enumerate(colors):
 name=f'skin_{material}';lines.extend(('o Body',f'usemtl {name}','s 1'))
 mats.extend((f'newmtl {name}','Kd '+' '.join(str(v/255) for v in color),'d 1'))
 for tri in triangles:
  polygon=clipped(tri,material)
  for i in range(1,len(polygon)-1):
   ids=[]
   for v in (polygon[0],polygon[i],polygon[i+1]):
    key=tuple(round(float(k),6) for k in v)
    if key not in skin_vertices:
     skin_vertices[key]=offset;offset+=1
     lines.append('v '+' '.join(f'{k:.6f}' for k in key))
    ids.append(skin_vertices[key])
   if len(set(ids))==3:lines.append('f '+' '.join(str(k) for k in ids))
# Place eye layers directly on the local face surface instead of protruding tubes.
def face_z(x,y):
 zs=np.linspace(-2.35,-.8,300);pts=np.array([[x,y,z] for z in zs]);hits=np.flatnonzero(field(pts)<0)
 assert len(hits),'face ray missed skin'
 return float(zs[hits[0]])
parts=[]
for p in components('MeadowMouse',1):
 n=p['name'];x,y,z=p['position']
 if n in ('Body','BackPatch','Head','FaceMask','Muzzle') or any(w in n for w in ('Leg','Paw','Claw','EarRim','Cheek','MouthSmile','TailCurve')) or n in ('LeftEar','RightEar'):continue
 if 'EarInner' in n:p.update(position=(x,1.42,-1.18),size=(.96,1.29,.05))
 elif any(w in n for w in ('EyeRim','EyeWhite','Iris','Pupil','Shine')):
  sg=-1 if 'Left' in n else 1;cx=sg*.56;cy=.78;base=face_z(cx,cy)
  if 'EyeRim' in n:p.update(position=(cx,cy,base-.045),size=(.52,.64,.018),color=(103,75,53))
  elif 'EyeWhite' in n:p.update(position=(cx,cy,base-.070),size=(.48,.59,.016))
  elif 'Iris' in n:p.update(position=(cx,cy,base-.095),size=(.40,.55,.012),color=(140,88,38))
  elif 'Pupil' in n:p.update(position=(cx,cy,base-.120),size=(.27,.44,.010))
  else:p.update(position=(cx-sg*.065,cy+.14,base-.145),size=(.10,.13,.009))
 elif n=='Nose':p.update(position=(0,.39,face_z(0,.39)-.026),size=(.24,.16,.06))
 elif 'Whisker' in n:p.update(position=(x,.22-(0 if n.endswith('Whisker') else .12),face_z(min(.68,max(-.68,x)),.22)-.03),size=(.64,.018,.018))
 elif n.startswith('TailClover'):p.update(position=(x,1.30+z-2.4,2.4),rotation=(90,0,math.degrees(math.atan2(x-.9,z-2.4))))
 parts.append(p)
for i,p in enumerate(parts):
 verts,faces=geometry(p,1);name=f'detail_{i}'
 if any(w in p['name'] for w in ('EyeRim','EyeWhite','Iris','Pupil','Shine','EarInner')):
  verts=[(0,0,0)];faces=[];sides=32;rings=4
  for r in range(1,rings+1):
   for j in range(sides):
    angle=math.tau*j/sides;verts.append((.5*r/rings*math.cos(angle),.5*r/rings*math.sin(angle),0))
  for j in range(sides):faces.append((0,1+(j+1)%sides,1+j))
  for r in range(rings-1):
   for j in range(sides):
    a=1+r*sides+j;b=1+r*sides+(j+1)%sides;c=a+sides;d=b+sides
    faces.extend(((a,b,d),(a,d,c)))
 lines.extend((f'o {p["name"]}',f'usemtl {name}','s 1' if p['shape']=='Ball' else 's off'))
 mats.extend((f'newmtl {name}','Kd '+' '.join(str(v/255) for v in p['color']),'d 1'))
 for v in verts:
  world=list(transform(v,p))
  if 'EarInner' in p['name']:
   side=-1 if 'Left' in p['name'] else 1;angle=math.radians(side*-15)
   qx=world[0]-side*1.02;qy=world[1]-1.4
   ex=qx*math.cos(angle)+qy*math.sin(angle);ey=-qx*math.sin(angle)+qy*math.cos(angle)
   world[2]=-1.01-.18*math.sqrt(max(0,1-(ex/.64)**2-(ey/.8)**2))-.025
  elif any(w in p['name'] for w in ('EyeRim','EyeWhite','Iris','Pupil','Shine')):
   world[2]=face_z(world[0],world[1])+(world[2]-p['position'][2])+(p['position'][2]-face_z(p['position'][0],p['position'][1]))
  lines.append('v '+' '.join(f'{k:.6f}' for k in world))
 for face in faces:lines.append('f '+' '.join(str(v+offset) for v in face))
 offset+=len(verts)
# One continuous curling tail tube, no necklace of disconnected spheres.
lines.extend(('o Tail','usemtl skin_0','s 1'));tail=[];rings=21;sides=8
for i in range(rings):
 t=i/(rings-1);a=np.array((0,-.05,1.45));b=np.array((1.5,.02,2.05));c=np.array((1.4,1.08,2.6));d=np.array((.9,1.3,2.4))
 center=(1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d
 tangent=3*(1-t)**2*(b-a)+6*(1-t)*t*(c-b)+3*t*t*(d-c);tangent/=np.linalg.norm(tangent)
 right=np.cross(tangent,(0,1,0));right/=np.linalg.norm(right);up=np.cross(right,tangent)
 for j in range(sides):
  angle=math.tau*j/sides;v=center+.075*(math.cos(angle)*right+math.sin(angle)*up);tail.append(v)
  lines.append('v '+' '.join(f'{k:.6f}' for k in v))
for i in range(rings-1):
 for j in range(sides):
  a=offset+i*sides+j;b=offset+i*sides+(j+1)%sides;c=a+sides;d=b+sides
  lines.extend((f'f {a} {b} {d}',f'f {a} {d} {c}'))
offset+=len(tail)
# A thin smile follows the muzzle's own surface.
lines.extend(('o Smile','usemtl smile','s off'));mats.extend(('newmtl smile','Kd .30 .20 .15','d 1'))
for i in range(13):
 x=-.28+i*.56/12;y=.06+.7*x*x
 for dy in (-.012,.012):
  lines.append(f'v {x:.6f} {y+dy:.6f} {face_z(x,y+dy)-.014:.6f}')
for i in range(12):
 a=offset+i*2;lines.extend((f'f {a} {a+1} {a+3}',f'f {a} {a+3} {a+2}'))
obj.write_text('\n'.join(lines)+'\n',encoding='utf-8');obj.with_suffix('.mtl').write_text('\n'.join(mats)+'\n',encoding='utf-8')
output=ROOT/'dist/ReviewModels'/f'{obj.stem}.glb'
count=make_glb(obj,output)
print(f'Review only: connected skin {len(triangles)} triangles, {count} material/animation nodes: {output}')
