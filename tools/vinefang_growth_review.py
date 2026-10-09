"""Original meadow wolf lineage: closed faceted meshes, review only."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
helpers=base.split('# A short bevelled torso')[0]
helpers=helpers.replace('(220,162,136),(251,216,182)','(137,175,66),(207,233,120)')
helpers=helpers.replace("name=='Body' and j in (5,6)","name=='Body' and j in (6,7,8)")
helpers=helpers.replace('(64,140,68),(179,220,65)','(124,174,56),(211,235,119)')
helpers=helpers.replace("'Dark':(0,2),'Ivory':(1,2)","'Dark':(0,2),'Ivory':(1,2),'Gold':(2,2)")
helpers=helpers.replace(" if kind=='Fur':", " if kind=='Gold':return blend((157,111,44),(238,202,103),1-v)\n if kind=='Fur':",1)
leaf=base.split('def leaf(')[1].split("leaf('HeadSproutLeft'")[0]
leaf=leaf.replace('clover=False):','clover=False,kind="Leaf"):').replace("'Leaf',normal)","kind,normal)").replace("'Leaf',-normal)","kind,-normal)").replace("'Leaf',verts[j]-middle)","kind,verts[j]-middle)")
growth=(R/'tools/mouse_growth_faceted_review.py').read_text(encoding='utf-8').split("addition=r'''",1)[1].split("meshes[:]=",1)[0]
# Fewer guide samples in mane strands leave room for rounded joints/head.
growth=growth.replace('for t in (0.,.5):','for t in (0.,):')
growth=growth.replace('],kind,rows[i][j]-np.array(rings[i][0]))',"],'Fur' if name.endswith('Leg') and i>=4 else kind,rows[i][j]-np.array(rings[i][0]))")
export=base.split('# Embed the actual atlas')[1]
body=r'''
P={1:dict(width=.66,head=.64,muzzle=.85,mane=.20,tail=.35),3:dict(width=.72,head=.69,muzzle=.77,mane=.65,tail=.90),6:dict(width=.94,head=.63,muzzle=1.28,mane=1.35,tail=1.27),9:dict(width=1.22,head=.64,muzzle=1.68,mane=2.10,tail=1.75)}[STAGE]
w=P['width'];h=P['head'];hy=1.15 if STAGE==1 else 1.37
# Body and rising neck are a single continuous ring surface. The front cap
# is inside the skull, and the shoulder/hips have small intermediate bevels.
loft('Body',[((0,hy-.07,-1.66),h*.47,.43),((0,hy-.16,-1.37),h*.61,.48),((0,.76,-1.00),w*.68,.61),((0,.54,-.60),w*.92,.74),((0,.48,-.18),w,.73),((0,.37,.42),w*.91,.65),((0,.35,1.03),w*.79,.61),((0,.35,1.52),w*.57,.46)],sides=10)
# A rounded, closed skull built vertically; the face is its curved front
# surface, rather than an enormous cap across the front of a lengthwise tube.
profiles=[(hy-.53,h*.35,.28,-1.76),(hy-.34,h*.72,.44,-1.81),(hy-.08,h*.84,.54,-1.83),(hy+.19,h*.82,.56,-1.89),(hy+.39,h*.66,.43,-1.70),(hy+.54,h*.39,.25,-1.57),(hy+.59,h*.09,.08,-1.61)]
if STAGE==1:
 # A consistent centerline prevents the forehead/eye plane jutting out as a kink.
 profiles=[(y,rx,rz,-1.76) for y,rx,rz,cz in profiles]
head=mesh('Head');rows=[];sides=12 if STAGE==1 else 10
for y,rx,rz,cz in profiles:
 rows.append([np.array((math.sin(j*math.tau/sides)*rx,y,cz-math.cos(j*math.tau/sides)*rz)) for j in range(sides)])
for i in range(len(rows)-1):
 for j in range(sides):
  k=(j+1)%sides;points=[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]]
  coords=[(.5+v[0]/(h*2.1),.5-(v[1]-hy)/1.3) for v in points]
  quad(head,points,coords,'Fur',rows[i][j]-np.array((0,profiles[i][0],profiles[i][3])))
for row,hint in ((0,(0,-1,0)),(-1,(0,1,0))):
 center=(0,profiles[row][0],profiles[row][3])
 for j in range(sides):tri(head,[center,rows[row][j],rows[row][(j+1)%sides]],[(.5,.5),(.5,.5),(.5,.5)],'Fur',hint)

def face_z(x,y):
 heights=[];positions=np.asarray(head['p'])
 for i in range(0,len(positions),3):
  triangle=positions[i:i+3];a=np.stack((triangle[:,0],triangle[:,1],np.ones(3)))
  if abs(np.linalg.det(a))<1e-9:continue
  weights=np.linalg.solve(a,np.array((x,y,1)))
  if weights.min()>=-1e-6:heights.append(float(weights@triangle[:,2]))
 assert heights,(STAGE,x,y,'face attachment outside skull')
 return min(heights)-.026
mz=-2.20-P['muzzle']*.58
loft('Muzzle',[((0,hy-.23,-1.96),h*.52,.26),((0,hy-.24,-2.18),h*.47,.22),((0,hy-.25,mz+.19),h*.32,.17),((0,hy-.23,mz),h*.22,.13)],'Cream',10)
nose_width=h*(.20 if STAGE==1 else .25)
loft('Nose',[((0,hy-.16,mz-.07),nose_width*.80,.085),((0,hy-.16,mz-.025),nose_width,.12),((0,hy-.16,mz+.035),nose_width*.82,.10)],'Dark',6)
for sg,side in ((-1,'Left'),(1,'Right')):
 cx=sg*h*.51;cy=hy+.12
 rx={1:.145,3:.155,6:.16,9:.165}[STAGE];ry={1:.19,3:.16,6:.13,9:.105}[STAGE]
 eye=mesh(side+'Eye')
 # A gently domed oval with its own tangent axes avoids wrapping a flat iris
 # across several skull facets. Its hidden backing enters the skull.
 normal=np.array((sg*.52,0,-.85));normal/=np.linalg.norm(normal)
 tangent=np.array((.85,0,sg*.52));tangent/=np.linalg.norm(tangent)
 center=np.array((cx,cy,face_z(cx,cy)))+normal*.052
 outline=[]
 for k in range(10):
  a=k*math.tau/10
  outline.append(center+tangent*math.cos(a)*rx+np.array((0,math.sin(a)*ry,0)))
 forward=center+normal*.035
 for k in range(10):
  a=k*math.tau/10;b=(k+1)*math.tau/10
  tri(eye,[forward,outline[k],outline[(k+1)%10]],[(.5,.5),(.5+.5*math.cos(a),.5-.5*math.sin(a)),(.5+.5*math.cos(b),.5-.5*math.sin(b))],'Eye',normal)
 # Closed thin rim shares the eye's shape, without a floating rectangular card.
 for k in range(10):
  j=(k+1)%10;back1=outline[k]-normal*.055;back2=outline[j]-normal*.055
  quad(eye,[outline[k],outline[j],back2,back1],[(.5,.5)]*4,'Fur',outline[k]-center)
 root=np.array((sg*h*.69,hy+h*.58,-1.65));height={1:.40,3:.85,6:.74,9:.83}[STAGE]
 front=[root+np.array((sg*x,y,z)) for x,y,z in ((-.18,0,-.12),(.18,-.02,-.08),(.15,height*.70,-.015),(.06,height,.02),(-.08,height*.63,-.025))]
 center=np.mean(front,axis=0);outer=[center+(v-center)*1.10 for v in front]
 back=[v+np.array((0,0,.20)) for v in outer];rim=[center+(v-center)*.72+np.array((0,0,-.055)) for v in outer]
 inner=[center+(v-center)*.53+np.array((0,0,.025)) for v in outer];m=mesh(side+'Ear')
 for j in range(5):
  k=(j+1)%5
  for row1,row2,kind in ((back,outer,'Fur'),(outer,rim,'Cream'),(rim,inner,'Pink')):
   quad(m,[row1[j],row1[k],row2[k],row2[j]],[(0,1),(1,1),(1,0),(0,0)],kind,(0,0,-1) if row1 is not back else outer[j]-center)
 for j in range(1,4):
  tri(m,[inner[0],inner[j],inner[j+1]],[(0,1),(1,1),(.5,0)],'Pink',(0,0,-1))
  tri(m,[back[0],back[j],back[j+1]],[(0,1),(1,1),(.5,0)],'Fur',(0,0,1))
 leaf(side+'EarBaseFur',root+np.array((0,-.06,0)),(sg*.52,-.26,.45),.32,.19,.06,kind='Fur')
 for z,label in ((-.57,'Front'),(1.28,'Back')):
  cx=sg*w*.64
  upright(side+label+'Leg',[((cx,-1.03,z-.20),.24,.36),((cx,-.91,z-.17),.26,.35),((cx,-.76,z-.04),.19,.23),((cx,-.48,z+.10),.17,.20),((cx,-.14,z+.15),.22,.25),((cx*.92,.21,z+.06),.28,.31),((cx*.74,.61,z),.18,.24)],'Cream',6)
  for k in (-1,0,1):
   loft(side+label+'Claw'+str(k),[((cx+k*.13,-.96,z-.60),.037,.046),((cx+k*.13,-.96,z-.41),.05,.055)],'Dark',4)
 # A slim mouth line and small visible canine make the muzzle read as a wolf.
 mouth=mesh(side+'MouthLine')
 quad(mouth,[(sg*h*.41,hy-.36,-2.04),(sg*h*.31,hy-.39,mz+.09),(sg*h*.31,hy-.415,mz+.09),(sg*h*.41,hy-.385,-2.04)],[(0,0),(1,0),(1,1),(0,1)],'Dark',(sg,0,-.2))
 tooth=mesh(side+'Fang');root=np.array((sg*h*.40,hy-.35,-2.19))
 vertices=[root+np.array((-.025,0,-.06)),root+np.array((.025,0,-.06)),root+np.array((0,0,.06)),root+np.array((0,-{1:.03,3:.08,6:.12,9:.27}[STAGE],0))]
 for ids in ((0,1,2),(0,3,1),(1,3,2),(2,3,0)):tri(tooth,[vertices[k] for k in ids],[(0,0),(1,0),(.5,1)],'Ivory')
 leaf(side+'CheekFur',(sg*h*.56,hy-.10,-1.63),(sg*.45,-.35,.75),.52,.28,.07,kind='Cream')
 # Each evolution has a different fur organ: puppy cheeks, a split chest
 # ruff, a radial adult collar, then a long swept multi-layer leader mane.
 count={1:0,3:2,6:4,9:6}[STAGE]
 for j in range(count):
  if STAGE==3:
   root=(sg*.32,hy+.12-j*.35,-1.30)
   path=[root,(sg*.59,hy-.05-j*.34,-1.02),(sg*.75,hy-.20-j*.35,-.68)]
   widths=[.14,.24,.012]
  elif STAGE==6:
   frac=j/(count-1);root=(sg*.30,hy+.42-frac*.83,-1.36)
   outer=sg*(w*.82+.32*P['mane']*math.sin(frac*math.pi));arch=hy+.62-frac*1.12
   path=[root,(sg*w*.75,arch,-.97),(outer,arch+.23*(1-frac),-.58),(sg*abs(outer)*.88,arch+.36*(1-frac)-.20*frac,-.21-.26*frac)]
   widths=[.23,.49,.43,.015]
  else:
   frac=j/(count-1);root=(sg*.33,hy+.48-frac*.95,-1.38)
   # Highest layers curve backward into a pointed crest, lower layers sweep
   # outward beside the shoulders, giving a strong diagonal profile.
   reach=[1.72,.94,1.36,.67,1.02,.42][j]
   path=[root,(sg*(.84+.30*frac),hy+.78-frac*1.06,-.75),(sg*(1.0+.35*frac),hy+.82-frac*.93,.12),(sg*(.80+.30*frac),hy+.95-frac*.95,reach)]
   widths=[.20,.46,.39,.012]
  fur_lock(side+'NeckMane'+str(j),path,widths,'Cream' if j%3!=2 else 'Fur')
 if STAGE==3:
  leaf(side+'ChestSprout',(sg*.24,.75,-1.03),(sg*.30,-.55,-.12),.45,.28,.06)
 if STAGE==6:
  leaf(side+'ShoulderVine',(sg*w*.69,.96,-.54),(sg*.3,.10,.90),.92,.29,.07)
 if STAGE==9:
  for j in range(3):
   leaf(side+'DorsalFern'+str(j),(sg*.24,1.01,.10+j*.40),(sg*.55,.45,.55),.94,.44,.09)
  leaf(side+'WristLeaf',(sg*w*.64,-.20,-.53),(sg*.35,.12,.75),.48,.30,.06)

t=P['tail']
if STAGE==1:
 fur_lock('Tail',[(0,.45,1.28),(.12,.60,1.64),(.12,.78,1.84)],[.17,.34,.07],'Cream')
elif STAGE==3:
 fur_lock('Tail',[(0,.48,1.19),(.12,.66,1.82),(.22,1.03,2.51)],[.12,.26,.012],'Cream')
 leaf('TailLeaf',(.18,.90,2.30),(.25,.45,.62),.64,.40,.07)
else:
 fur_lock('Tail',[(0,.48,1.19),(.12,.56,1.65),(.27,.93,1.72+t*.55),(.23,1.25,1.72+t),(.13,1.55,1.83+t)],[.13,.25,.43,.30,.018],'Cream')
 if STAGE==9:
  for sg in (-1,1):
   fur_lock('TailPlume'+str(sg),[(.12,.56,1.65),(sg*.37,.86,2.30),(sg*.65,1.00,3.21)],[.12,.31,.012],'Fur')

# Stage-specific proportions affect the entire connected body and leg roots.
head_names=('Head','Muzzle','Nose')
for m in meshes:
 p=np.asarray(m['p'],float);name=m['name']
 if STAGE==1:
  if name=='Head':
   # Continuous vertical color across cap triangles prevents a star-shaped mask.
   m['uv']=[uv('Fur',float(np.clip(.5+x/1.5,0,1)),float(np.clip(.5-(y-hy)/1.4,0,1))) for x,y,z in p]
  facial=name in head_names or any(k in name for k in ('Eye','Ear','Brow','Mouth','Fang','Cheek'))
  if not facial:
   p[:,2]=-1.3+(p[:,2]+1.3)*.70
  if name.endswith('Leg') or 'Claw' in name:
   p[:,1]=.53+(p[:,1]-.53)*.65
 elif STAGE==3 and name=='Body':
  p[:,0]*=.90
 elif STAGE==9:
  if name=='Body':
   p[:,1]+=.24*np.exp(-((p[:,2]+.35)/.72)**2)
  if name.endswith('Leg') or 'Claw' in name:
   center=np.sign(p[:,0].mean())*w*.64
   p[:,0]=center+(p[:,0]-center)*1.22
 m['p']=p.tolist()

ground=min(p[1] for m in meshes if m['name'].endswith('Leg') for p in m['p'])
top=max(p[1] for m in meshes for p in m['p'])
target={1:3.65,3:5.,6:10.,9:15.}[STAGE];scale=target/(top-ground)
for m in meshes:
 p=np.asarray(m['p'],float)*scale;m['p']=p.tolist()
 for i in range(0,len(p),3):
  n=np.cross(p[i+1]-p[i],p[i+2]-p[i]);n/=np.linalg.norm(n);m['n'][i:i+3]=[n.tolist()]*3
 assert np.isfinite(p).all() and np.isfinite(m['n']).all()
 assert ((np.asarray(m['uv'])>=0)&(np.asarray(m['uv'])<=1)).all()
assert len([m for m in meshes if m['name'].endswith('Leg')])==4
'''
for stage in (1,3,6,9):
 source=helpers+'\ndef leaf('+leaf+'\n'+growth+'\n'+body+'\n# Export'+export
 source=source.replace("STEM='MeadowMouse_A_S1_FacetedReview'",f"STEM='Vinefang_S{stage}_FacetedReview'")
 source=source.replace('PaintedTeaFantasy','PaintedVinefangFantasy')
 source=source.replace("'rigged':False","'rigged':False,'heightStuds':{1:3.65,3:5.,6:10.,9:15.}[STAGE],'heightIncludesPlants':True,'avatarReferenceStuds':5")
 exec(compile(source,str(__file__),'exec'),{'__file__':str(R/'tools/mouse_s1_faceted_revision.py'),'STAGE':stage})
