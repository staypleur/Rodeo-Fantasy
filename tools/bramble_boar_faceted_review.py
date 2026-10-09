"""Original baby boar review, using the approved faceted atlas/mesh workflow."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
helpers=base.split('# A short bevelled torso')[0]
helpers=helpers.replace("STEM='MeadowMouse_A_S1_FacetedReview'","STEM='BrambleBoar_S1_FacetedReview'")
helpers=helpers.replace('(220,162,136),(251,216,182)','(74,112,56),(167,192,98)')
helpers=helpers.replace('tea=np.array((239,194,168))','tea=np.array((133,169,86))')
helpers=helpers.replace('(254,220,186)','(192,211,128)').replace('cream)', 'cream*.18)')
helpers=helpers.replace("'Dark':(0,2)","'Hoof':(3,2),'Dark':(0,2)")
helpers=helpers.replace("if kind=='Fur':", "if kind=='Hoof':return blend((81,62,45),(137,110,73),1-v)\n if kind=='Fur':")
head=base.split('# Angular cheek silhouette')[1].split('for sg,side in')[0]
head=head.replace('profiles=[(-.20,.34,.33),(.08,.80,.61),(.43,1.06,.73),(.94,.99,.69),(1.29,.72,.53),(1.48,.28,.27)]',
 'profiles=[(-.20,.30,.32),(.08,.67,.58),(.43,.91,.75),(.94,.86,.73),(1.29,.62,.57),(1.48,.22,.28)]')
leaf=base.split('def leaf(')[1].split("leaf('HeadSproutLeft'")[0]
export=base.split('# Embed the actual atlas')[1]
body=r'''
loft('Body',[((0,-.04,-.74),.87,.66),((0,.05,-.1),1.13,.85),((0,.03,.95),1.13,.84),((0,-.10,1.62),.80,.60)],sides=10)
for sg,side in ((-1,'Left'),(1,'Right')):
 for z,label in ((-.52,'Front'),(1.14,'Back')):
  m=mesh(side+label+'Leg');rows=[]
  for y,w,d in ((-.34,.32,.33),(-.9,.26,.29),(-1.18,.36,.40)):
   rows.append([np.array((sg*.79+dx*w,y,z+dz*d)) for dx,dz in ((-1,-1),(1,-1),(1,1),(-1,1))])
  for i in range(2):
   for j in range(4):
    k=(j+1)%4;quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(0,0),(1,0),(1,1),(0,1)],'Hoof' if i==1 else 'Fur',rows[i][j]-np.array((sg*.79,-.5,z)))
  quad(m,rows[-1],[(0,0),(1,0),(1,1),(0,1)],'Hoof',(0,-1,0))
  # Two visible toe seams distinguish boar feet from mouse paws.
  seam=mesh(side+label+'ToeSplit')
  quad(seam,[(sg*.79-.025,-.98,z-.405),(sg*.79+.025,-.98,z-.405),(sg*.79+.025,-1.175,z-.405),(sg*.79-.025,-1.175,z-.405)],[(0,0),(1,0),(1,1),(0,1)],'Cream',(0,0,-1))
'''
details=r'''
for sg,side in ((-1,'Left'),(1,'Right')):
 cx=sg*.51;cy=.77
 points=[(cx+math.cos(j*math.tau/8)*.22,cy+math.sin(j*math.tau/8)*.29) for j in range(8)]
 face_patch(side+'Eye',points,'Eye',.055)
 # Small pointed ears, with a closed thick rim and pink inner face.
 center=np.array((sg*.68,1.29,-1.02))
 outline=[center+np.array((sg*x,y,z)) for x,y,z in ((-.19,-.13,-.04),(.40,.23,.03),(.28,.51,.06),(-.16,.31,-.02))]
 ear=mesh(side+'Ear');rear=[p+np.array((0,0,.15)) for p in outline]
 for j in range(4):
  k=(j+1)%4;quad(ear,[outline[j],outline[k],rear[k],rear[j]],[(0,1),(1,1),(1,0),(0,0)],'Fur',outline[j]-center)
 quad(ear,rear,[(0,1),(1,1),(1,0),(0,0)],'Fur',(0,0,1))
 quad(ear,outline,[(0,1),(1,1),(1,0),(0,0)],'Fur',(0,0,-1))
 inner=[center+(p-center)*.63+np.array((0,.07,-.022)) for p in outline]
 quad(mesh(side+'EarPink'),inner,[(0,1),(1,1),(1,0),(0,0)],'Pink',(0,0,-1))
 # Soft cream cheek and very short upward tusk; no adult spikes on a baby.
 face_patch(side+'Cheek',[(sg*.42,.31),(sg*.68,.38),(sg*.77,.25),(sg*.65,.13),(sg*.45,.16)],'Cream',.05)
 tusk=mesh(side+'Tusk')
 root=np.array((sg*.62,.21,-1.92));tip=root+np.array((sg*.045,.36,-.19))
 ring=[root+np.array((math.cos(j*math.tau/5)*.10,0,math.sin(j*math.tau/5)*.10)) for j in range(5)]
 for j in range(5):tri(tusk,[ring[j],ring[(j+1)%5],tip],[(0,1),(1,1),(.5,0)],'Ivory',ring[j]-root)
 for j in range(1,4):tri(tusk,[ring[0],ring[j],ring[j+1]],[(0,1),(1,1),(.5,0)],'Ivory',(0,-1,0))
snout=loft('Snout',[((0,.42,-1.88),.47,.28),((0,.42,-2.25),.57,.35),((0,.42,-2.34),.50,.29)],kind='Pink',sides=8)
for sg,side in ((-1,'Left'),(1,'Right')):
 nostril=mesh(side+'Nostril');cx=sg*.23;cy=.46
 points=[(cx+math.cos(j*math.tau/6)*.075,cy+math.sin(j*math.tau/6)*.10,-2.345) for j in range(6)]
 for j in range(1,5):tri(nostril,[points[0],points[j],points[j+1]],[(0,0),(.5,1),(1,0)],'Dark',(0,0,-1))
face_patch('BabySmile',[(-.18,.06),(0,-.015),(.18,.06),(.08,.07),(0,.035),(-.08,.07)],'Dark',.07)
# A tidy row of bramble leaves over a warm moss-green back.
for i in range(4):
 leaf('BrambleMane'+str(i),(0,.72,.0+i*.36),(0,.42,.9),.68,.44,.07)
for sg in (-1,1):
 leaf('BrowLeaf'+str(sg),(sg*.18,1.35,-1.25),(sg*.50,.72,.05),.52,.32,.055)
 leaf('ShoulderLeaf'+str(sg),(sg*.72,.38,-.52),(sg*.70,-.24,.62),.64,.38,.07)
# One short curled tail with a single sprout: no mouse-like clover tail.
tail=mesh('Tail');centers=[(0,.0,1.6),(.15,.18,1.95),(.38,.31,2.08),(.52,.55,2.05),(.39,.73,1.98)]
for i in range(len(centers)-1):
 a=np.array(centers[i]);b=np.array(centers[i+1]);axis=(b-a)/np.linalg.norm(b-a);side=np.cross(axis,(0,0,1));side/=np.linalg.norm(side);up=np.cross(axis,side)
 rows=[[c+.075*(math.cos(j*math.tau/5)*side+math.sin(j*math.tau/5)*up) for j in range(5)] for c in (a,b)]
 for j in range(5):
  k=(j+1)%5;quad(tail,[rows[0][j],rows[0][k],rows[1][k],rows[1][j]],[(0,0),(1,0),(1,1),(0,1)],'Fur',rows[0][j]-a)
leaf('TailSprout',centers[-1],(-.7,.55,.05),.38,.25,.05)
# Medium baby body is wider/heavier than the small mouse, retaining low stature.
for m in meshes:
 p=np.asarray(m['p'],float)*1.25;m['p']=p.tolist()
 n=np.asarray(m['n']);coords=np.asarray(m['uv'])
 assert np.isfinite(p).all() and ((coords>=0)&(coords<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(n[i],n[i+1]) and np.allclose(n[i],n[i+2])
  assert np.dot(np.cross(p[i+1]-p[i],p[i+2]-p[i]),n[i])>1e-8
assert len([m for m in meshes if m['name'].endswith('Leg')])==4
'''
source=helpers+body+'\n# Head silhouette'+head+'\ndef leaf('+leaf+details+'\n# Export'+export
source=source.replace('PaintedTeaFantasy','PaintedBrambleFantasy')
exec(compile(source,str(__file__),'exec'))
