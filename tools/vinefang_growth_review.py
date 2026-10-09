"""Original meadow wolf lineage: closed faceted meshes, review only."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
helpers=base.split('# A short bevelled torso')[0]
helpers=helpers.replace('(220,162,136),(251,216,182)','(51,92,55),(115,158,76)')
helpers=helpers.replace("'Dark':(0,2),'Ivory':(1,2)","'Dark':(0,2),'Ivory':(1,2),'Gold':(2,2)")
helpers=helpers.replace(" if kind=='Fur':", " if kind=='Gold':return blend((157,111,44),(238,202,103),1-v)\n if kind=='Fur':",1)
leaf=base.split('def leaf(')[1].split("leaf('HeadSproutLeft'")[0]
leaf=leaf.replace('clover=False):','clover=False,kind="Leaf"):').replace("'Leaf',normal)","kind,normal)").replace("'Leaf',-normal)","kind,-normal)").replace("'Leaf',verts[j]-middle)","kind,verts[j]-middle)")
growth=(R/'tools/mouse_growth_faceted_review.py').read_text(encoding='utf-8').split("addition=r'''",1)[1].split("meshes[:]=",1)[0]
export=base.split('# Embed the actual atlas')[1]
body=r'''
P={1:dict(width=.65,head=.70,muzzle=.64,mane=.55,tail=.65),3:dict(width=.77,head=.66,muzzle=.88,mane=.85,tail=.90),6:dict(width=.94,head=.63,muzzle=1.06,mane=1.35,tail=1.27),9:dict(width=1.08,head=.68,muzzle=1.15,mane=1.75,tail=1.55)}[STAGE]
w=P['width'];h=P['head'];hy=1.23 if STAGE==1 else 1.37
loft('Body',[((0,.48,-.85),w*.72,.68),((0,.49,-.28),w,.75),((0,.35,.77),w*.78,.57),((0,.35,1.60),w*.67,.64)],sides=8)
loft('Neck',[((0,hy,-1.67),h*.65,.60),((0,1.07,-1.12),w*.75,.68),((0,.74,-.57),w*.86,.67)],'Fur',8)
loft('Head',[((0,hy,-2.10),h*.78,h*.72),((0,hy+.09,-1.87),h,h),((0,hy+.04,-1.45),h*.77,h*.77)],'Fur',8)
mz=-2.12-P['muzzle']*.55
loft('Muzzle',[((0,hy-.20,-2.00),h*.66,.31),((0,hy-.24,mz+.13),h*.48,.23),((0,hy-.23,mz),h*.29,.16)],'Cream',8)
loft('Nose',[((0,hy-.16,mz-.055),h*.27,.13),((0,hy-.16,mz+.025),h*.27,.13)],'Dark',6)
for sg,side in ((-1,'Left'),(1,'Right')):
 cx=sg*h*.50;cy=hy+.16;z=-2.125
 pts=[(cx-sg*.18,cy+.08,z),(cx+sg*.20,cy+.16,z),(cx+sg*.17,cy-.13,z),(cx-sg*.15,cy-.12,z)]
 pts=[(x,y,z+.30*abs(x)-.10) for x,y,z in pts]
 quad(mesh(side+'Eye'),pts,[(0,0),(1,0),(1,1),(0,1)],'Eye',(0,0,-1))
 leaf(side+'Brow',(cx-sg*.18,cy+.08,z-.018),(sg*.90,.30,.08),.40,.15,.035,kind='Fur')
 root=np.array((sg*h*.69,hy+h*.58,-1.65));height=.53 if STAGE==1 else .74
 front=[root+np.array((sg*x,y,z)) for x,y,z in ((-.19,0,-.10),(.23,-.04,-.03),(.14,height,.02))]
 back=[v+np.array((0,0,.19)) for v in front];m=mesh(side+'Ear')
 tri(m,front,[(0,1),(1,1),(.5,0)],'Fur',(0,0,-1));tri(m,back,[(0,1),(1,1),(.5,0)],'Fur',(0,0,1))
 for j in range(3):quad(m,[front[j],front[(j+1)%3],back[(j+1)%3],back[j]],[(0,0),(1,0),(1,1),(0,1)],'Fur',front[j]-root)
 inner=[root+(v-root)*.64+np.array((0,.07,-.025)) for v in front]
 tri(mesh(side+'EarPink'),inner,[(0,1),(1,1),(.5,0)],'Pink',(0,0,-1))
 for z,label in ((-.57,'Front'),(1.28,'Back')):
  cx=sg*w*.64
  upright(side+label+'Leg',[((cx,-1.03,z-.20),.28,.38),((cx,-.84,z-.09),.22,.27),((cx,-.40,z+.12),.18,.19),((cx,-.06,z+(.22 if label=='Back' else 0)),.20,.25),((cx*.90,.53,z),.34,.37)],'Cream',6)
  for k in (-1,0,1):
   loft(side+label+'Claw'+str(k),[((cx+k*.13,-.96,z-.60),.037,.046),((cx+k*.13,-.96,z-.41),.05,.055)],'Dark',4)
 # A slim mouth line and small visible canine make the muzzle read as a wolf.
 mouth=mesh(side+'MouthLine')
 quad(mouth,[(sg*h*.41,hy-.36,-2.04),(sg*h*.31,hy-.39,mz+.09),(sg*h*.31,hy-.415,mz+.09),(sg*h*.41,hy-.385,-2.04)],[(0,0),(1,0),(1,1),(0,1)],'Dark',(sg,0,-.2))
 tooth=mesh(side+'Fang');root=np.array((sg*h*.40,hy-.35,-2.19))
 vertices=[root+np.array((-.025,0,-.06)),root+np.array((.025,0,-.06)),root+np.array((0,0,.06)),root+np.array((0,-.12,0))]
 for ids in ((0,1,2),(0,3,1),(1,3,2),(2,3,0)):tri(tooth,[vertices[k] for k in ids],[(0,0),(1,0),(.5,1)],'Ivory')
 leaf(side+'CheekFur',(sg*h*.56,hy-.10,-1.63),(sg*.45,-.35,.75),.52,.28,.07,kind='Cream')
 count={1:2,3:3,6:4,9:5}[STAGE]
 for j in range(count):
  # Radial collar tufts, not parallel horizontal strips on the back.
  frac=j/max(1,count-1);root=(sg*.30,hy+.42-frac*.83,-1.36)
  span=P['mane']
  outer=sg*(w*.82+.32*span*math.sin(frac*math.pi))
  arch=hy+.62-frac*1.12
  path=[root,(sg*w*.75,arch,-.97),(outer,arch+.23*(1-frac),-.58),(sg*(abs(outer)*.88),arch+.36*(1-frac)-.20*frac,-.21-.26*frac)]
  fur_lock(side+'NeckMane'+str(j),path,[.23,.39 if STAGE<6 else .49,.32 if STAGE<6 else .43,.015],'Cream')
 if STAGE>=6:
  leaf(side+'ShoulderVine',(sg*w*.69,.96,-.54),(sg*.3,.10,.90),.92,.29,.07)
 if STAGE==9:
  branch(side+'VineCrest',[(sg*.32,hy+.45,-1.20),(sg*.58,hy+1.10,-.72),(sg*.94,hy+1.40,-.28)],.075,'Gold')
  for j in range(2):leaf(side+'CrestLeaf'+str(j),(sg*(.45+j*.10),hy+.97+j*.24,-.79+j*.32),(sg*.6,.45,.50),.64,.36,.07)
  fur_lock(side+'FlankPlume',[(sg*w*.65,.67,.51),(sg*w*.92,.79,1.09),(sg*w*.80,.98,1.85)],[.18,.32,.01],'Cream')
t=P['tail']
fur_lock('Tail',[(0,.48,1.19),(.12,.56,1.65),(.27,.93,1.72+t*.55),(.23,1.25,1.72+t),(.13,1.55,1.83+t)],[.13,.25,.43,.30,.018],'Cream')
if STAGE>=3:
 leaf('TailLeaf',(.23,1.16,1.72+t*.8),(.35,.38,.75),.56,.32,.07)
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
