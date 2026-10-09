"""Draft A mouse revision for user review; does not replace any game templates."""
from pathlib import Path
import math
from meadow_models import components
from export_creature_meshes import transform,geometry
from export_roblox_glb import make_glb
ROOT=Path(__file__).resolve().parents[1]
parts=components('MeadowMouse',1)
for p in parts:
 n=p['name'];x,y,z=p['position']
 if n=='Body':p.update(position=(0,-.16,.28),size=(2.1,1.95,2.45),color=(210,169,120))
 elif n=='BackPatch':p.update(position=(0,-.35,-.35),size=(1.65,1.6,1.9),color=(244,232,206))
 elif n=='Head':p.update(position=(0,.5,-1.10),size=(2.25,1.90,1.85))
 elif n=='FaceMask':p.update(position=(0,.38,-1.83),size=(1.94,1.42,.62))
 elif n=='Muzzle':p.update(position=(0,.1,-1.99),size=(1.3,.62,.48))
 elif n=='Nose':p.update(position=(0,.38,-2.23),size=(.24,.19,.12))
 elif 'EyeRim' in n:p.update(position=(x,.76,-2.075),size=(.58,.70,.07))
 elif 'EyeWhite' in n:p.update(position=(x,.76,-2.112),size=(.51,.64,.045))
 elif 'Iris' in n:p.update(position=(x,.76,-2.139),size=(.39,.56,.032))
 elif 'Pupil' in n:p.update(position=(x,.76,-2.159),size=(.25,.44,.025))
 elif 'Shine' in n:p.update(position=(x,.92,-2.178),size=(.11,.14,.018))
 elif 'MouthSmile' in n:p.update(position=(x,y+.02,-2.241),size=(.15,.03,.026))
 elif 'Whisker' in n:p.update(position=(x,y,-2.145),size=(.68,.025,.025))
 elif 'Cheek' in n:p.update(position=(x,y,-2.115),size=(.56,.30,.12))
 elif 'Leg' in n:p.update(position=(x,y+.34,z),size=(.86,1.12,.89))
 elif 'Paw' in n:p.update(position=(x,y+.28,z),size=(.90,.45,1.00))
 elif 'Claw' in n:p.update(position=(x,y+.28,z),size=(.13,.12,.15))
 elif n.startswith('TailCurve'):p['size']=(.16,.16,.38)
 elif n.startswith('TailClover'):p.update(position=(x,1.3+z-2.4,2.4),rotation=(90,0,math.degrees(math.atan2(x-.9,z-2.4))))
# More even rounded faceting than the six-ring draft; detailed leaves remain pointed.
def rounded(p):
 if p['shape']!='Ball' or any(w in p['name'] for w in ('Leaf','Clover','Sprout')):return geometry(p,1)
 sides,rings=16,10
 verts=[(0,.5,0),(0,-.5,0)]
 for r in range(1,rings):
  a=math.pi*r/rings
  for i in range(sides):
   t=math.tau*i/sides;verts.append((math.sin(a)*math.cos(t)*.5,math.cos(a)*.5,math.sin(a)*math.sin(t)*.5))
 faces=[]
 for i in range(sides):
  j=(i+1)%sides;faces.extend(((0,2+j,2+i),(1,2+(rings-2)*sides+i,2+(rings-2)*sides+j)))
  for r in range(rings-2):
   a,b,c,d=2+r*sides+i,2+r*sides+j,2+(r+1)*sides+j,2+(r+1)*sides+i
   faces.extend(((a,b,c),(a,c,d)))
 return verts,faces
folder=ROOT/'assets/meshes/review';folder.mkdir(parents=True,exist_ok=True)
obj=folder/'MeadowMouse_A_S1_Review.obj'
lines=['# Review draft only; +Y up, -Z forward',f'mtllib {obj.stem}.mtl'];mats=[];offset=1
for i,p in enumerate(parts):
 verts,faces=rounded(p);material=f'color_{i}'
 lines.extend((f'o {p["name"]}',f'usemtl {material}','s off'))
 mats.extend((f'newmtl {material}','Kd '+' '.join(f'{v/255:.6f}' for v in p['color']),'d 1'))
 for v in verts:lines.append('v '+' '.join(f'{k:.6f}' for k in transform(v,p)))
 for face in faces:lines.append('f '+' '.join(str(v+offset) for v in face))
 offset+=len(verts)
obj.write_text('\n'.join(lines)+'\n',encoding='utf-8');obj.with_suffix('.mtl').write_text('\n'.join(mats)+'\n',encoding='utf-8')
output=ROOT/'dist/ReviewModels/MeadowMouse_A_S1_Review.glb';output.parent.mkdir(exist_ok=True)
count=make_glb(obj,output)
assert count>=10
print(f'Review only: {count} mesh nodes -> {output}')
