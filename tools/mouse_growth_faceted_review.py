"""Build review-only A-family growth models from the approved faceted A1 builder."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
addition=r'''
# Keep the approved face/ears/legs; mature the torso and layer a tidy leaf mantle.
for m in meshes:
 if m['name']=='Body':
  for p in m['p']:p[2]=.2+(p[2]-.2)*({3:1.08,6:1.23,9:1.36}[STAGE])
def flower(name,center,radius=.15):
 c=np.array(center,float);m=mesh(name)
 for j in range(5):
  a=j*math.tau/5;axis=np.array((math.cos(a),math.sin(a),0.))
  across=np.array((-axis[1],axis[0],0.))
  pts=[c,c+axis*radius*.7+across*radius*.35,c+axis*radius,c+axis*radius*.7-across*radius*.35]
  quad(m,pts,[(.5,1),(0,.4),(.5,0),(1,.4)],'Ivory',(0,0,-1))
 m=mesh(name+'Center');pts=[c+np.array((math.cos(a)*radius*.25,math.sin(a)*radius*.25,-.018)) for a in [j*math.tau/5 for j in range(5)]]
 for j in range(5):tri(m,[c+(0,0,-.025),pts[j],pts[(j+1)%5]],[(.5,.5),(0,0),(1,1)],'Gold',(0,0,-1))
layers=1 if STAGE==3 else 2 if STAGE==6 else 3
for layer in range(layers):
 z=-.25+layer*.54
 for sg in (-1,1):
  for j in range(3):
   leaf(f'Mantle{layer}_{sg}_{j}',(sg*(.67+j*.09),.55-j*.12,z),(sg*(.48+j*.12),-.85,.28),.90+layer*.16,.48,.055)
flower('ChestBloom',(0,-.45,-.91),.20)
flower('SproutBloom',(.08,1.51,-1.35),.13)
if STAGE>=6:
 for sg in (-1,1):
  leaf('CrownSide'+str(sg),(sg*.37,1.31,-1.22),(sg*.48,.87,0),.73,.30,.05)
  flower('ShoulderBloom'+str(sg),(sg*1.0,.31,-.35),.16)
 # Angular warm-gold wreath across the forehead, no spikes or smooth spheres.
 m=mesh('LeafWreath')
 pts=[(-.65,1.25,-1.51),(-.35,1.38,-1.64),(0,1.42,-1.70),(.35,1.38,-1.64),(.65,1.25,-1.51)]
 for a,b in zip(pts,pts[1:]):quad(m,[a,b,np.array(b)+(0,-.07,-.005),np.array(a)+(0,-.07,-.005)],[(0,0),(1,0),(1,1),(0,1)],'Gold',(0,0,-1))
if STAGE==9:
 leaf('RegalSprout',(0,1.44,-1.15),(0,1,.05),1.04,.44,.065)
 for sg in (-1,1):
  flower('MantleBloom'+str(sg),(sg*1.17,.06,.18),.19)
  leaf('BackMantle'+str(sg),(sg*.68,.55,1.20),(sg*.65,-.74,.62),1.32,.54,.06)
 flower('TailBloom',(1.0,1.43,2.01),.12)
# Existing gameplay growth multipliers; pose and proportions remain readable.
factor={3:1.4,6:1.9,9:2.5}[STAGE]
for m in meshes:
 m['p']=(np.asarray(m['p'])*factor).tolist()
 p=np.asarray(m['p']);n=np.asarray(m['n']);coords=np.asarray(m['uv'])
 assert np.isfinite(p).all() and ((coords>=0)&(coords<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(n[i],n[i+1]) and np.allclose(n[i],n[i+2])
  assert np.dot(np.cross(p[i+1]-p[i],p[i+2]-p[i]),n[i])>1e-8
'''
for stage in (3,6,9):
 source=base.replace("STEM='MeadowMouse_A_S1_FacetedReview'",f"STAGE={stage}\nSTEM='Mossrat_S{stage}_FacetedReview'")
 source=source.replace("'Dark':(0,2),'Ivory':(1,2)","'Dark':(0,2),'Ivory':(1,2),'Gold':(2,2)")
 source=source.replace(" if kind=='Fur':", " if kind=='Gold':return blend((174,117,41),(255,216,103),1-v)\n if kind=='Fur':",1)
 marker='# Embed the actual atlas in the GLB; do not rely on importer vertex colors.'
 source=source.replace(marker,addition+'\n'+marker)
 exec(compile(source,str(R/'tools/mouse_s1_faceted_revision.py'),'exec'),{'__file__':str(R/'tools/mouse_s1_faceted_revision.py')})
