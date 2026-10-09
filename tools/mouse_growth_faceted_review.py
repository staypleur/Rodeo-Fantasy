"""Build review-only A-family growth models from the approved faceted A1 builder."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
addition=r'''
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
   k=(j+1)%5;quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(j/5,1-i/(len(rows)-1)),((j+1)/5,1-i/(len(rows)-1)),((j+1)/5,1-(i+1)/(len(rows)-1)),(j/5,1-(i+1)/(len(rows)-1))],kind,rows[i][j]-np.array(centers[i]))
 for i in (0,-1):
  for j in range(5):tri(m,[centers[i],rows[i][j],rows[i][(j+1)%5]],[(.5,.5),(0,0),(1,1)],kind)


def upright(name,rings,kind='Fur',sides=6):
 m=mesh(name);rows=[]
 for center,rx,rz in rings:
  rows.append([np.array(center)+np.array((math.cos(j*math.tau/sides)*rx,0,math.sin(j*math.tau/sides)*rz)) for j in range(sides)])
 for i in range(len(rows)-1):
  for j in range(sides):
   k=(j+1)%sides;quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(0,1),(1,1),(1,0),(0,0)],kind,rows[i][j]-np.array(rings[i][0]))
 for i,hint in ((0,(0,-1,0)),(-1,(0,1,0))):
  for j in range(sides):tri(m,[rings[i][0],rows[i][j],rows[i][(j+1)%sides]],[(.5,.5),(0,0),(1,1)],kind,hint)

def fur_lock(name,centers,widths,kind='Cream'):
 # Sample the curved lock twice per control span; normals remain strictly flat.
 control=np.asarray(centers,float);control_widths=list(widths);sampled=[];sample_widths=[]
 for i in range(len(control)-1):
  p0=control[max(i-1,0)];p1=control[i];p2=control[i+1];p3=control[min(i+2,len(control)-1)]
  for t in (0.,.5):
   sampled.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
   sample_widths.append(control_widths[i]*(1-t)+control_widths[i+1]*t)
 centers=sampled+[control[-1]];widths=sample_widths+[control_widths[-1]]
 m=mesh(name);rows=[]
 for i,c in enumerate(centers):
  tangent=np.array(centers[min(i+1,len(centers)-1)])-np.array(centers[max(i-1,0)]);tangent/=np.linalg.norm(tangent)
  side=np.cross(tangent,(0,1,0));side/=np.linalg.norm(side);up=np.cross(tangent,side)
  rows.append([np.array(c)+widths[i]*(math.cos(j*math.tau/5)*side+math.sin(j*math.tau/5)*up*.75) for j in range(5)])
 for i in range(len(rows)-1):
  for j in range(5):
   k=(j+1)%5
   quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(j/5,i/(len(rows)-1)),((j+1)/5,i/(len(rows)-1)),((j+1)/5,(i+1)/(len(rows)-1)),(j/5,(i+1)/(len(rows)-1))],kind,rows[i][j]-np.array(centers[i]))
 for i in (0,-1):
  for j in range(5):tri(m,[centers[i],rows[i][j],rows[i][(j+1)%5]],[(.5,.5),(0,0),(1,1)],kind)

meshes[:]=[m for m in meshes if m['name'] in ('Head','Nose','OpenSmile') or any(k in m['name'] for k in ('Eye','Ear','Cheek'))]
if STAGE>=6:
 meshes[:]=[m for m in meshes if m['name']!='OpenSmile']
 face_patch('ClosedMouth',[(-.14,.22),(-.06,.18),(0,.20),(.06,.18),(.14,.22),(.06,.20),(0,.22),(-.06,.20)],'Dark',.055)
params={3:dict(headY=1.36,headSize=.83,headWidth=.92,depth=1.06,bodyY=.10,bodyWidth=.72,length=1.85,legTop=.15,ear=.87,mane=.70),
        6:dict(headY=2.18,headSize=.76,headWidth=.82,depth=1.18,bodyY=.53,bodyWidth=.90,length=2.10,legTop=.64,ear=.80,mane=1.65),
        9:dict(headY=2.50,headSize=.78,headWidth=.72,depth=1.32,bodyY=.85,bodyWidth=1.00,length=2.44,legTop=1.04,ear=.73,mane=3.36)}[STAGE]
head_z=-1.18 if STAGE==3 else -1.44 if STAGE==6 else -1.62
for m in meshes:
 p=np.asarray(m['p'],float);name=m['name']
 if 'Ear' in name:
  sg=-1 if name.startswith('Left') else 1;center=np.array((sg*1.08,1.50,-1.07))
  p=center+(p-center)*params['ear'];p[:,2]+=np.maximum(p[:,1]-1.5,0)*(.10 if STAGE==3 else .24)
 if name.endswith('Eye'):
  sg=-1 if name.startswith('Left') else 1
  p[:,1]=.77+(p[:,1]-.77)*{3:.97,6:.86,9:.80}[STAGE]+sg*(p[:,0]-sg*.49)*.05
 if STAGE==9 and 'Ear' not in name:
  # Taper cheeks/chin and project the lower front into a short angular muzzle.
  p[:,0]*=np.clip(.84+.10*(p[:,1]-.10),.80,.98)
  front=np.clip((-p[:,2]-1.10)/.65,0,1)
  lower=np.clip((.65-p[:,1])/.55,0,1)
  p[:,2]-=.22*front*lower
 p-=np.array((0,.62,-1.18));p[:,0]*=params['headWidth'];p[:,2]*=params['depth']
 p*=params['headSize'];p+=np.array((0,params['headY'],head_z));m['p']=p.tolist()
by=params['bodyY'];bw=params['bodyWidth'];length=params['length']
loft('Body',[((0,by,-.80),bw*.76,.58),((0,by+.10,-.32),bw,.73),((0,by-.06,length*.42),bw*.92,.66),((0,by-.16,length*.72),bw*.66,.47)],sides=8)
upright('Neck',[((0,by+.20,-.70),bw*.68,.43),((0,params['headY']-.62,head_z+.34),.43,.36),((0,params['headY']-.18,head_z+.10),.35,.30)],kind='Cream',sides=8)
for sg in (-1,1):
 for z,label,top in ((-.57,'Front',params['legTop']), (length*.52,'Back',params['legTop']-.18)):
  cx=sg*bw*.70
  upright(('Left' if sg<0 else 'Right')+label+'Leg',[((cx,-1.28,z-.12),.25 if STAGE==3 else .29,.33),((cx,-1.04,z),.17 if STAGE==3 else .20,.21),((cx,-.38,z+.12),.19 if STAGE==3 else .22,.23),((cx*.94,top,z),.28 if STAGE==3 else .34,.32)],sides=5)
 leaf('ChestFur'+str(sg),(sg*.20,params['headY']-.55,head_z-.08),(sg*.16,-.96,.18),.50 if STAGE==3 else .83,.33,.05,kind='Cream')
for sg in (-1,1):
 root=np.array((sg*.26,params['headY']+.63,head_z+.02))
 if STAGE==3:
  branch('CrownBranch'+str(sg),[root,root+(sg*.12,.35,.10),root+(sg*.18,.58,.18)],.065,kind='Gold')
  leaf('CrownLeaf'+str(sg),root+(sg*.15,.30,.10),(sg*.33,.82,.30),.40,.26,.05)
 else:
  span=1.0 if STAGE==6 else 1.72
  spine=[root,root+(sg*.21,span*.40,.22),root+(sg*.51,span*.68,.49),root+(sg*.66,span,.66)]
  branch('CrownBranch'+str(sg),spine,.095 if STAGE==6 else .13,kind='Gold')
  for j in range(1 if STAGE==6 else 2):
   fork=spine[j+1];points=[fork,fork+(sg*span*.34,span*.10,-.14),fork+(sg*span*.46,span*.43,-.08)]
   branch(f'CrownFork{sg}_{j}',points,.062 if STAGE==6 else .085,kind='Gold')
   leaf(f'CrownLeaf{sg}_{j}',points[-1],(sg*.28,.93,.05),.29,.22,.045)
  leaf('CrownTip'+str(sg),spine[-1],(sg*.15,.95,.10),.32,.24,.045)
leaf('ForeheadSprout',(0,params['headY']+.55,head_z-.30),(0,.97,-.20),.42,.25,.045)
for sg in (-1,1):
 for j in range(1 if STAGE==3 else 2 if STAGE==6 else 3):
  root=(sg*(.43+j*.10),params['headY']-.15-j*.18,head_z+.20);reach=params['mane']*(1-j*.12)
  path=[root,(sg*(.58+j*.13),params['headY']-.66-j*.10,-.42),(sg*(.64+j*.14),by+1.03+j*.17,reach*.54),(sg*(.62+j*.12),by+1.22+j*.19,reach),(sg*(.50+j*.11),by+1.53+j*.22,reach+.25)]
  fur_lock(f'FlowingMane{sg}_{j}',path,[.18,.36 if STAGE==9 else .26,.46 if STAGE==9 else .29,.26 if STAGE==9 else .20,.025],kind='Cream' if j%2==0 else 'Fur')
 if STAGE>=6:leaf('ManeLeaf'+str(sg),(sg*.65,by+1.04,params['mane']*.52),(sg*.18,.14,.97),.72 if STAGE==9 else .48,.31,.05)
tail_end=(.77,by+1.38,length*.72+1.00)
branch('Tail',[(0,by-.02,length*.72),(.58,by+.14,length*.72+.46),(.88,by+.72,length*.72+.84),tail_end],.085 if STAGE==3 else .11)
for j in range(4):
 a=j*math.tau/4;leaf('TailClover'+str(j),tail_end,(math.sin(a),math.cos(a),.02),{3:.42,6:.55,9:.68}[STAGE],.34 if STAGE==3 else .43,.055,clover=True)
ground=min(p[1] for m in meshes if m['name'].endswith('Leg') for p in m['p'])
top=max(p[1] for m in meshes if m['name']=='Head' or m['name'].endswith('Ear') for p in m['p'])
target={3:4.0,6:5.7,9:12.5}[STAGE];scale=target/(top-ground)
for m in meshes:
 p=np.asarray(m['p'],float)*scale;m['p']=p.tolist()
 for i in range(0,len(p),3):
  normal=np.cross(p[i+1]-p[i],p[i+2]-p[i]);normal/=np.linalg.norm(normal);m['n'][i:i+3]=[normal.tolist()]*3
 coords=np.asarray(m['uv']);norm=np.asarray(m['n'])
 assert np.isfinite(p).all() and ((coords>=0)&(coords<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(norm[i],norm[i+1]) and np.allclose(norm[i],norm[i+2])
  assert np.dot(np.cross(p[i+1]-p[i],p[i+2]-p[i]),norm[i])>1e-8
actual=max(p[1] for m in meshes if m['name']=='Head' or m['name'].endswith('Ear') for p in m['p'])-min(p[1] for m in meshes if m['name'].endswith('Leg') for p in m['p'])
assert abs(actual-target)<1e-6
assert len([m for m in meshes if m['name'].endswith('Leg')])==4
assert not any('Cape' in m['name'] for m in meshes)
print('LINEAGE_REVIEW_PASS:',STAGE,actual,'four paws, flowing mane, no cape; no game install')
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
 source=source.replace("assert tri_count<2000", "gltf['extras'].update(referenceAvatarHeightStuds=5,groundToBodyHeightStuds={3:4.0,6:5.7,9:12.5}[STAGE],heightIncludesEars=True,reviewUnitsPerStud=1,posture='quadruped branching sprout flowing mane review',gameInstalled=False)\nassert tri_count<2000")
 exec(compile(source,str(R/'tools/mouse_s1_faceted_revision.py'),'exec'),{'__file__':str(R/'tools/mouse_s1_faceted_revision.py')})
