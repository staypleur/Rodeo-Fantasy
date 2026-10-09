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
helpers=helpers.replace("name=='Body' and j in (5,6)","name=='Body' and j in (6,7,8)")
head=base.split('# Angular cheek silhouette')[1].split('for sg,side in')[0]
head=head.replace('profiles=[(-.20,.34,.33),(.08,.80,.61),(.43,1.06,.73),(.94,.99,.69),(1.29,.72,.53),(1.48,.28,.27)]',
 'profiles=[(-.20,.30,.32),(.08,.67,.58),(.43,.91,.75),(.94,.86,.73),(1.29,.62,.57),(1.48,.22,.28)]')
leaf=base.split('def leaf(')[1].split("leaf('HeadSproutLeft'")[0]
export=base.split('# Embed the actual atlas')[1]
body=r'''
# Lift and taper the front torso into the rear of the head. The closed end
# sits inside the head rather than showing as a vertical block below it.
loft('Body',[((0,.55,-1.20),.49,.54),((0,.37,-.79),.83,.67),((0,.12,-.12),1.10,.80),((0,.03,.95),1.13,.84),((0,-.10,1.62),.80,.60)],sides=10)
for sg,side in ((-1,'Left'),(1,'Right')):
 for z,label in ((-.52,'Front'),(1.14,'Back')):
  m=mesh(side+label+'Leg');rows=[]
  for y,cx,w,d in ((.30,.53,.24,.30),(.06,.62,.32,.34),(-.22,.70,.36,.36),(-.53,.77,.29,.32),(-.83,.79,.25,.29),(-.96,.79,.31,.35),(-1.10,.79,.36,.40),(-1.18,.79,.33,.37)):
   rows.append([np.array((sg*cx+math.cos(j*math.tau/8)*w,y,z+math.sin(j*math.tau/8)*d)) for j in range(8)])
  for i in range(len(rows)-1):
   for j in range(8):
    k=(j+1)%8;quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(j/8,.25),((j+1)/8,.25),((j+1)/8,.4),(j/8,.4)],'Hoof' if i>=4 else 'Fur',rows[i][j]-np.array((sg*.79,-.5,z)))
  for j in range(1,7):tri(m,[rows[-1][0],rows[-1][j],rows[-1][j+1]],[(0,0),(.5,1),(1,0)],'Hoof',(0,-1,0))
  # Two visible toe seams distinguish boar feet from mouse paws.
  seam=mesh(side+label+'ToeSplit')
  marks=[(-.98,.365),(-1.10,.408),(-1.179,.378)]
  for (y,d),(ny,nd) in zip(marks,marks[1:]):
   quad(seam,[(sg*.79-.023,y,z-d),(sg*.79+.023,y,z-d),(sg*.79+.023,ny,z-nd),(sg*.79-.023,ny,z-nd)],[(0,0),(1,0),(1,1),(0,1)],'Cream',(0,0,-1))
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
snout=loft('Snout',[((0,.42,-1.80),.38,.23),((0,.42,-2.00),.51,.31),((0,.42,-2.20),.55,.33),((0,.42,-2.34),.50,.29)],kind='Pink',sides=8)
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
rows=[]
for i,c in enumerate(centers):
 axis=np.array(centers[min(i+1,len(centers)-1)])-np.array(centers[max(i-1,0)]);axis/=np.linalg.norm(axis)
 side=np.cross(axis,(0,0,1));side/=np.linalg.norm(side);up=np.cross(axis,side)
 rows.append([np.array(c)+.075*(math.cos(j*math.tau/5)*side+math.sin(j*math.tau/5)*up) for j in range(5)])
for i in range(len(rows)-1):
 for j in range(5):
  k=(j+1)%5;quad(tail,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(0,0),(1,0),(1,1),(0,1)],'Fur',rows[i][j]-np.array(centers[i]))
for i,hint in ((0,np.array(centers[0])-np.array(centers[1])),(-1,np.array(centers[-1])-np.array(centers[-2]))):
 for j in range(5):tri(tail,[centers[i],rows[i][j],rows[i][(j+1)%5]],[(.5,.5),(0,0),(1,1)],'Fur',hint)
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
