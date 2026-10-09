"""Build review-only A-family growth models from the approved faceted A1 builder."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
addition=r'''
# Distinct life stages: teenager, athletic adult, tall elder. Baby is unchanged.
age={3:dict(lift=.32,width=.90,length=1.16,leg=.86,head=.92,neck=.04),
     6:dict(lift=.76,width=1.13,length=1.28,leg=1.20,head=.84,neck=.12),
     9:dict(lift=1.18,width=1.20,length=1.36,leg=1.30,head=.84,neck=.18)}[STAGE]
if STAGE>=6:
 loft('ShoulderChest',[((0,.06,-.72),.74,.66),((0,.08,-.39),1.00,.86),((0,-.02,.22),.83,.73)],sides=8)
 # Mature eyes are less round; the ivory muzzle and warm jewel eyes remain.
 for m in meshes:
  if m['name'].endswith('Eye'):
   for p in m['p']:p[1]=.77+(p[1]-.77)*(.84 if STAGE==6 else .76)
 meshes[:]=[m for m in meshes if m['name']!='OpenSmile']
 face_patch('CalmSmile',[(-.23,.23),(-.10,.20),(0,.18),(.10,.20),(.23,.23),(.12,.14),(0,.12),(-.12,.14)],'Dark',.053)
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
flower('SproutBloom',(.08,1.51,-1.35),.18 if STAGE>=6 else .15)
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
 flower('TailBloom',(1.22,2.02,2.04),.16)
 # A layered ivory throat/beard and trailing leaf mantle communicate an elder.
 for j in range(5):
  x=(j-2)*.19
  leaf('ElderBeard'+str(j),(x,-.10,-1.68),(x*.30,-1,-.04),.64 if j==2 else .50,.29,.035,kind='Cream')
 for sg in (-1,1):
  leaf('ElderCheekFur'+str(sg),(sg*.64,.20,-1.82),(sg*.75,-.65,0),.44,.30,.035,kind='Ivory')
  flower('ElderCrownBloom'+str(sg),(sg*.46,1.41,-1.50),.13)
for sg in (-1,1):
 for j in range(2 if STAGE==3 else 3):
  leaf('ChestFur'+str(sg)+'_'+str(j),(sg*(.12+j*.20),.10,-.99),(sg*.16,-.96,-.05),.56 if STAGE==3 else .72,.30,.04,kind='Cream')
# Existing gameplay growth multipliers; pose and proportions remain readable.
factor={3:1.4,6:1.9,9:2.5}[STAGE]
for m in meshes:
 p=np.asarray(m['p'],float)
 name=m['name']
 head=name in ('Head','Nose','OpenSmile','CalmSmile','LeafWreath','RegalSprout') or any(k in name for k in ('Eye','Ear','Cheek','HeadSprout','SproutBloom','Crown','Beard'))
 if head:
  if 'Ear' in name:
   center=np.array((-1.08 if name.startswith('Left') else 1.08,1.50,-1.07))
   p=center+(p-center)*(.96 if STAGE==3 else .87)
  p=(p-np.array((0,.62,-1.18)))*age['head']+np.array((0,.62+age['lift']+age['neck'],-1.18))
 elif 'Leg' in name:
  side=-1 if name.startswith('Left') else 1
  p[:,0]=side*.62*age['width']+(p[:,0]-side*.62)*age['leg']
  p[:,1]=-1.28+(p[:,1]+1.28)*(1+age['lift']/.83)
  p[:,2]=.2+(p[:,2]-.2)*age['length']
 else:
  p[:,0]*=age['width']
  p[:,1]+=age['lift']
  p[:,2]=.2+(p[:,2]-.2)*age['length']
 p*=factor
 m['p']=p.tolist()
 # Recompute exact flat normals after changing the proportions.
 for i in range(0,len(p),3):
  n=np.cross(p[i+1]-p[i],p[i+2]-p[i]);n/=np.linalg.norm(n)
  m['n'][i:i+3]=[n.tolist()]*3
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
 source=source.replace('clover=False):','clover=False,kind="Leaf"):')
 source=source.replace("'Leaf',normal)","kind,normal)").replace("'Leaf',-normal)","kind,-normal)").replace("'Leaf',verts[j]-middle)","kind,verts[j]-middle)")
 if stage>=6:
  source=source.replace('centers=[(0,-.02,1.24),(.68,.06,1.72),(1.18,.42,2.01),(1.18,1.03,2.12),(.98,1.42,2.07)]',
   'centers=[(0,-.02,1.24),(.74,.12,1.82),(1.43,.62,2.21),(1.55,1.42,2.25),(1.22,2.02,2.10)]')
  source=source.replace('.065*(math.cos(j*math.tau/5)',('.095' if stage==6 else '.125')+'*(math.cos(j*math.tau/5)')
  source=source.replace('.62,.48,.065,clover=True',('.78,.59' if stage==6 else '.94,.70')+',.065,clover=True')
 marker='# Embed the actual atlas in the GLB; do not rely on importer vertex colors.'
 source=source.replace(marker,addition+'\n'+marker)
 exec(compile(source,str(R/'tools/mouse_s1_faceted_revision.py'),'exec'),{'__file__':str(R/'tools/mouse_s1_faceted_revision.py')})
