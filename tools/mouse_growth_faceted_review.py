"""Build review-only A-family growth models from the approved faceted A1 builder."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
addition=r'''
# Distinct life stages: teenager, athletic adult, tall elder. Baby is unchanged.
age={3:dict(lift=.22,width=.82,length=1.28,leg=.82,head=.87,neck=-.04),
     6:dict(lift=.55,width=1.22,length=1.12,leg=1.30,head=.88,neck=.20),
     9:dict(lift=.90,width=1.03,length=1.12,leg=1.13,head=.87,neck=.56)}[STAGE]
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
def branch(name,centers,radius,kind='Fur'):
 m=mesh(name);rows=[]
 for i,c in enumerate(centers):
  tangent=np.array(centers[min(i+1,len(centers)-1)])-np.array(centers[max(i-1,0)])
  tangent/=np.linalg.norm(tangent)
  side=np.cross(tangent,(0,1,0))
  if np.linalg.norm(side)<.1:side=np.cross(tangent,(1,0,0))
  side/=np.linalg.norm(side);up=np.cross(tangent,side)
  rows.append([np.array(c)+radius*(1-.35*i/(len(centers)-1))*(math.cos(j*math.tau/5)*side+math.sin(j*math.tau/5)*up) for j in range(5)])
 for i in range(len(rows)-1):
  for j in range(5):
   k=(j+1)%5;quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(0,0),(1,0),(1,1),(0,1)],kind,rows[i][j]-np.array(centers[i]))
 for i in (0,-1):
  for j in range(5):tri(m,[centers[i],rows[i][j],rows[i][(j+1)%5]],[(.5,.5),(0,0),(1,1)],kind)

meshes[:]=[m for m in meshes if not m['name'].startswith(('Tail','HeadSprout'))]
if STAGE==3:
 tailpoints=[(0,-.02,1.24),(.55,.06,1.94),(1.13,.31,2.56),(1.45,.65,2.93)]
 branch('RunnerTail',tailpoints,.07)
 for j in range(3):
  a=(j-1)*1.05
  leaf('RunnerTailLeaf'+str(j),tailpoints[-1],(math.sin(a),math.cos(a),.05),.72,.40,.05,clover=True)
 for sg in (-1,1):leaf('HeadSprout'+str(sg),(sg*.13,1.36,-1.17),(sg*.28,.68,.68),.85,.32,.055)
elif STAGE==6:
 tailpoints=[(0,-.02,1.24),(.77,.22,1.82),(1.46,.98,2.12),(1.35,1.82,2.10)]
 branch('GuardianTail',tailpoints,.14)
 for j in range(4):
  a=j*math.tau/4;leaf('GuardianClover'+str(j),tailpoints[-1],(math.sin(a),math.cos(a),.03),1.05,.69,.075,clover=True)
 leaf('HeadSproutGuardian',(0,1.36,-1.17),(0,1,.16),1.0,.70,.06)
else:
 tailpoints=[(0,-.02,1.24),(.80,.22,1.88),(1.54,.87,2.37),(1.87,1.92,2.43),(1.48,2.83,2.40)]
 branch('ElderTreeTail',tailpoints,.19,kind='Gold')
 for sg in (-1,1):
  end=np.array(tailpoints[-1])+np.array((sg*.42,.28,.02))
  branch('ElderTailFork'+str(sg),[tailpoints[-2],tailpoints[-1],end.tolist()],.10,kind='Gold')
  for j in range(3):
   a=(j-1)*1.12
   leaf(f'ElderTailCanopy{sg}_{j}',end,(math.sin(a),math.cos(a),.02),.90,.57,.06,clover=True)
# Remove the baby collar: each evolution gets a different major silhouette.
meshes[:]=[m for m in meshes if not m['name'].startswith('NeckLeaf')]
for sg in (-1,1):
 if STAGE==3:
  # Streamlined backward crest, rather than a small copy of the elder's cape.
  for j in range(3):
   leaf(f'RunnerCrest{sg}_{j}',(sg*(.43+j*.10),.66,-.55+j*.28),(sg*.72,.12,.72),1.20-j*.10,.40,.05)
  leaf('RunnerCheekLeaf'+str(sg),(sg*.69,.37,-1.20),(sg*.48,.20,.86),.92,.32,.045)
 elif STAGE==6:
  # Two broad, serrated shoulder shields. These change the outline substantially.
  for j in range(3):
   leaf(f'GuardianShield{sg}_{j}',(sg*(.62+j*.15),.61-j*.14,-.57+j*.20),(sg*.88,-.42,.20),1.22-j*.10,.67,.07)
  leaf(f'GuardianChest{sg}',(sg*.19,.30,-1.02),(sg*.30,-.92,-.12),.93,.48,.055)
 else:
  # Long trailing leaf cloak: high shoulders, narrow waist, floorward hem.
  for j in range(4):
   leaf(f'ElderCloak{sg}_{j}',(sg*(.53+j*.13),.56,-.30+j*.40),(sg*(.38+j*.09),-.84,.34),1.82-j*.12,.62,.06)
flower('ChestBloom',(0,-.45,-.91),.20)
flower('SproutBloom',(.08,1.51,-1.35),.18 if STAGE>=6 else .15)
if STAGE==6:
 for sg in (-1,1):
  leaf('CrownSide'+str(sg),(sg*.37,1.31,-1.22),(sg*.48,.87,0),.73,.30,.05)
  flower('ShoulderBloom'+str(sg),(sg*1.0,.31,-.35),.16)
 # Angular warm-gold wreath across the forehead, no spikes or smooth spheres.
 m=mesh('LeafWreath')
 pts=[(-.65,1.25,-1.51),(-.35,1.38,-1.64),(0,1.42,-1.70),(.35,1.38,-1.64),(.65,1.25,-1.51)]
 for a,b in zip(pts,pts[1:]):quad(m,[a,b,np.array(b)+(0,-.07,-.005),np.array(a)+(0,-.07,-.005)],[(0,0),(1,0),(1,1),(0,1)],'Gold',(0,0,-1))
if STAGE==9:
 # Open woody crown above the ears, with a clean leaf fan instead of more sprigs.
 # No copied external character shape: a living grove crown for the clover mouse.
 for sg in (-1,1):
  branch('CrownBranch'+str(sg),[(sg*.52,1.31,-1.13),(sg*.91,2.09,-1.10),(sg*.76,2.62,-1.08)],.11,kind='Gold')
  leaf('CrownLeaf'+str(sg),(sg*.78,2.30,-1.10),(sg*.70,.72,0),.86,.48,.06)
 leaf('RegalSprout',(0,1.44,-1.15),(0,1,.05),1.68,.55,.065)
 for sg in (-1,1):
  flower('MantleBloom'+str(sg),(sg*1.17,.06,.18),.19)
  leaf('BackMantle'+str(sg),(sg*.60,.50,1.12),(sg*.40,-.84,.36),1.76,.60,.06)
 flower('TailBloom',(1.48,2.83,2.34),.16)
 # A layered ivory throat/beard and trailing leaf mantle communicate an elder.
 for j in range(5):
  x=(j-2)*.19
  leaf('ElderBeard'+str(j),(x,-.10,-1.68),(x*.30,-1,-.04),1.12 if j==2 else .84,.29,.035,kind='Cream')
 for sg in (-1,1):
  leaf('ElderCheekFur'+str(sg),(sg*.64,.20,-1.82),(sg*.75,-.65,0),.44,.30,.035,kind='Ivory')
  flower('ElderCrownBloom'+str(sg),(sg*.46,1.41,-1.50),.13)
# A real change in torso, posture and ears, before growth scaling.
# The adolescent crouches forward; the guardian has a heavy front; the elder
# carries the head and shoulders higher than the hips.
for m in meshes:
 p=np.asarray(m['p'],float);name=m['name']
 if STAGE==3 and name in ('Head','Nose','OpenSmile','LeftEye','RightEye','LeftCheek','RightCheek'):
  # Longer angular face, a narrower jaw and slanted eyes distinguish the teen.
  p[:,2]=-1.18+(p[:,2]+1.18)*1.18
  if name.endswith('Eye'):
   sg=-1 if name.startswith('Left') else 1
   p[:,1]=.77+(p[:,1]-.77)*.83+sg*(p[:,0]-sg*.49)*.18
  if name=='Head':p[:,0]*=.84+.16*np.clip((p[:,1]-.15)/.8,0,1)
 if STAGE==3 and 'Leg' in name:
  # Lean, bent lower limbs and small paws replace the baby's straight blocks.
  knee=1-np.minimum(1,np.abs(p[:,1]+1.01)/.27)
  p[:,2]+=knee*(-.22 if 'Front' in name else .26)
  center=-.62 if name.startswith('Left') else .62
  p[:,0]=center+(p[:,0]-center)*(.80+.20*np.clip((p[:,1]+1.28)/.83,0,1))
 if name=='Body' or name=='ShoulderChest':
  front=np.clip((1.27-p[:,2])/2.11,0,1)
  p[:,1]+=front*{3:-.12,6:.24,9:.58}[STAGE]
  if STAGE==9:p[:,0]*=.84+.23*front
 if 'FrontLeg' in name:
  p[:,1]+=np.clip((p[:,1]+1.28)/.83,0,1)*{3:-.12,6:.24,9:.58}[STAGE]
 if name.endswith('Ear') or name.endswith('EarFur'):
  sg=-1 if name.startswith('Left') else 1
  q=p-np.array((sg*1.08,1.50,-1.07))
  if STAGE==3:
   q[:,0]*=.70;q[:,1]*=1.16;q[:,2]+=q[:,1]*.28
  elif STAGE==6:
   q[:,0]*=1.25;q[:,1]*=.66
   q[:,1]-=sg*q[:,0]*.27
  else:
   q[:,0]*=.83;q[:,1]*=1.24
   q[:,0]+=sg*np.maximum(q[:,1],0)*.35
  p=q+np.array((sg*1.08,1.50,-1.07))
 m['p']=p.tolist()
for sg in (-1,1):
 for j in range(2 if STAGE==3 else 3):
   leaf('ChestFur'+str(sg)+'_'+str(j),(sg*(.12+j*.20),.10,-.99),(sg*.16,-.96,-.05),.46 if STAGE==3 else .72,.30,.04,kind='Cream')
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
