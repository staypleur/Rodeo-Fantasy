"""Independent lion form study from user reference, not a new game species."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
base=(R/'tools/mouse_s1_faceted_revision.py').read_text(encoding='utf-8')
helpers=base.split('# A short bevelled torso')[0]
helpers=helpers.replace("STEM='MeadowMouse_A_S1_FacetedReview'","STEM='Lion_FormStudy'")
helpers=helpers.replace('(220,162,136),(251,216,182)','(65,39,140),(147,101,231)')
helpers=helpers.replace('(239,213,180),(255,243,217)','(179,133,68),(246,220,153)')
helpers=helpers.replace("'Dark':(0,2),'Ivory':(1,2)","'Dark':(0,2),'Ivory':(1,2),'Gold':(2,2)")
helpers=helpers.replace(" if kind=='Fur':", " if kind=='Gold':return blend((150,93,27),(255,206,88),1-v)\n if kind=='Fur':",1)
growth=(R/'tools/mouse_growth_faceted_review.py').read_text(encoding='utf-8').split("addition=r'''",1)[1].split("if STAGE==",1)[0]
# Only the geometric helpers, before the first stage-dependent build.
growth=growth.split("meshes[:]=")[0]
growth=growth.replace('for t in (0.,.5):','for t in (0.,):')
growth=growth.replace('side=np.cross(tangent,(0,1,0));side/=np.linalg.norm(side);up=np.cross(tangent,side)', 'side=np.cross(tangent,(0,1,0))\n  if np.linalg.norm(side)<.01:side=np.cross(tangent,(1,0,0))\n  side/=np.linalg.norm(side);up=np.cross(tangent,side)')
export=base.split('# Embed the actual atlas')[1]
body=r'''
# Broad chest, tucked waist and heavy rump; front is -Z.
loft('Body',[((0,1.95,-1.40),.72,.84),((0,1.90,-.85),1.01,1.03),((0,1.71,.15),.89,.82),((0,1.67,1.15),.78,.76),((0,1.72,1.80),.88,.81),((0,1.70,2.13),.60,.59)],sides=8)
loft('Head',[((0,2.87,-2.86),.63,.66),((0,2.93,-2.65),.82,.85),((0,2.91,-2.15),.87,.91),((0,2.82,-1.70),.67,.73)],'Cream',8)
# Full paired muzzle lobes, deep lower jaw and a wide feline nose.
loft('Jaw',[((0,2.29,-3.35),.49,.23),((0,2.28,-3.05),.63,.29),((0,2.40,-2.41),.64,.38)],'Cream',8)
for sg,side in ((-1,'Left'),(1,'Right')):
 loft(side+'Muzzle',[((sg*.29,2.49,-3.50),.28,.21),((sg*.32,2.52,-3.34),.40,.29),((sg*.32,2.55,-2.83),.41,.31)],'Cream',8)
 # Narrow eyes follow the forward side planes, with a heavy overhanging brow.
 normal=np.array((sg*.48,0,-.88));tangent=np.array((.88,0,sg*.48))
 center=np.array((sg*.60,3.05,-2.94));m=mesh(side+'Eye')
 coords=[(-1,-.35),(-.65,.45),(.55,.70),(1,.20),(.55,-.50),(-.50,-.65)]
 outline=[center+tangent*x*.25+np.array((0,y*.15,0)) for x,y in coords]
 for j in range(6):
  k=(j+1)%6
  tri(m,[center+normal*.02,outline[j],outline[k]],[(.5,.5),(.5+coords[j][0]*.5,.5-coords[j][1]*.5),(.5+coords[k][0]*.5,.5-coords[k][1]*.5)],'Eye',normal)
 fur_lock(side+'Brow',[(sg*.21,3.17,-3.01),(sg*.61,3.27,-2.97),(sg*.91,3.35,-2.65)],[.12,.15,.04],'Cream')
 loft(side+'Ear',[((sg*.73,3.54,-1.94),.24,.28),((sg*.73,3.54,-1.78),.30,.34),((sg*.73,3.54,-1.64),.24,.27)],'Cream',8)
 loft(side+'EarInner',[((sg*.73,3.56,-1.96),.15,.20),((sg*.73,3.56,-1.93),.16,.21)],'Dark',8)
 # Thick roots blend into the chest and rump, ending in broad feline paws.
 for z,label in ((-.98,'Front'),(1.64,'Back')):
  x=sg*.76
  upright(side+label+'Leg',[((x,2.05,z),.33,.42),((x,1.61,z),.41,.43),((x,.99,z+.10),.30,.29),((x,.45,z-.02),.28,.30),((x,.16,z-.20),.44,.56),((x,.02,z-.22),.40,.52)],'Fur',6)
  for k in (-1,0,1):
   loft(side+label+'Toe'+str(k),[((x+k*.22,.15,z-.79),.10,.10),((x+k*.22,.15,z-.58),.115,.12)],'Cream',5)
 # Small cheek wedges reinforce a feline cheekbone, rather than a round puppy face.
 fur_lock(side+'Cheek',[(sg*.53,2.73,-2.70),(sg*.89,2.67,-2.49),(sg*1.03,2.45,-2.26)],[.20,.28,.015],'Cream')
 # Gold wrist accent sits on the paw, leaving the limb readable.
 upright(side+'FrontGoldBand',[((sg*.76,.40,-1.01),.295,.32),((sg*.76,.54,-1.01),.295,.32)],'Gold',6)
loft('Nose',[((0,2.70,-3.61),.23,.125),((0,2.72,-3.53),.29,.16),((0,2.73,-3.41),.24,.13)],'Dark',6)
fur_lock('MouthCenter',[(0,2.60,-3.53),(0,2.39,-3.52),(0,2.32,-3.41)],[.023,.021,.012],'Dark')
for sg in (-1,1):
 fur_lock('Mouth'+str(sg),[(0,2.39,-3.51),(sg*.29,2.32,-3.48),(sg*.54,2.40,-3.24)],[.024,.024,.012],'Dark')
# Dense overlapping pointed locks. Each has a closed diamond section, not a flat fan.
for layer,count,radius,zbase in ((0,10,1.02,-1.94),(1,12,1.14,-1.54),(2,10,1.04,-1.12)):
 for j in range(count):
  a=(j+.40*layer)*math.tau/count
  dx,dy=math.sin(a),math.cos(a)
  root=np.array((dx*radius*.72,2.63+dy*radius*.77,zbase))
  mid=np.array((dx*(radius+.24),2.63+dy*(radius+.24),zbase+.12))
  tip=np.array((dx*(radius+.61),2.63+dy*(radius+.59),zbase+.70))
  fur_lock('Mane'+str(layer)+'_'+str(j),[root,mid,tip],[.30,.38,.009],'Fur')
 # A few golden edge pieces, no copied crown or insignia.
for sg in (-1,1):
 fur_lock('GoldShoulder'+str(sg),[(sg*.99,2.87,-1.09),(sg*1.27,2.90,-.90),(sg*1.38,2.72,-.52)],[.10,.13,.008],'Gold')
branch('Tail',[(0,1.79,2.06),(.34,1.67,2.57),(.70,1.79,3.01),(.90,2.13,3.31),(.82,2.48,3.48)],.12,'Fur')
fur_lock('TailTuft',[(.82,2.31,3.37),(.82,2.64,3.48),(.71,3.04,3.42)],[.17,.32,.012],'Fur')
ground=min(p[1] for m in meshes for p in m['p'])
top=max(p[1] for m in meshes for p in m['p'])
scale=15/(top-ground)
for m in meshes:
 p=np.asarray(m['p'],float);p[:,1]-=ground;p*=scale;m['p']=p.tolist()
 for i in range(0,len(p),3):
  n=np.cross(p[i+1]-p[i],p[i+2]-p[i]);n/=np.linalg.norm(n);m['n'][i:i+3]=[n.tolist()]*3
 assert np.isfinite(p).all() and np.isfinite(m['n']).all()
 assert ((np.asarray(m['uv'])>=0)&(np.asarray(m['uv'])<=1)).all()
assert len([m for m in meshes if m['name'].endswith('Leg')])==4
'''
source=helpers+'\n'+growth+'\n'+body+'\n# Export'+export
source=source.replace('assert tri_count<2000','assert tri_count<4000')
source=source.replace("'triangleBudget':2000","'triangleBudget':4000")
exec(compile(source,str(__file__),'exec'),{'__file__':str(R/'tools/mouse_s1_faceted_revision.py')})
