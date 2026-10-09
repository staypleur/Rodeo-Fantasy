"""Build distinct review-only adolescent/adult/leader boars from connected baby."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
namespace={'__file__':str(R/'tools/bramble_boar_faceted_review.py')}
builder=(R/'tools/bramble_boar_faceted_review.py').read_text(encoding='utf-8').split('exec(compile(source',1)[0]
exec(compile(builder,str(R/'tools/bramble_boar_faceted_review.py'),'exec'),namespace)
base=namespace['source']
for stage in (3,6,9):
 source=base.replace("STEM='BrambleBoar_S1_FacetedReview'",f"STEM='BrambleBoar_S{stage}_FacetedReview'")
 # The high stages shed baby tusks/sprouts before building an original adult silhouette.
 growth=r'''
meshes[:]=[m for m in meshes if not m['name'].endswith('Tusk') and not m['name'].startswith('BrambleMane') and not m['name'].startswith('BrowLeaf') and not m['name'].startswith('ShoulderLeaf')]
for m in meshes:
 p=np.asarray(m['p'],float)
 # Existing coordinates include medium-size scaling; operate in base coordinates.
 p/=1.25
 name=m['name']
 head_part=name in ('Head','Snout','BabySmile') or any(k in name for k in ('Eye','Ear','Cheek','Nostril'))
 if head_part:
  p[:,0]*={3:1.0,6:1.07,9:1.17}[STAGE]
  p[:,1]=.32+(p[:,1]-.32)*{3:.97,6:.92,9:.84}[STAGE]
  p[:,2]=-1.2+(p[:,2]+1.2)*{3:1.08,6:1.20,9:1.30}[STAGE]
  if 'Eye' in name:
   cx=(-1 if name.startswith('Left') else 1)*.51*{3:1.,6:1.07,9:1.17}[STAGE]
   p[:,1]=.77+(p[:,1]-.77)*{3:.95,6:.83,9:.75}[STAGE]
 elif name=='Body':
  p[:,0]*={3:1.06,6:1.22,9:1.46}[STAGE]
  # Shoulder rises gradually into the head rather than a separate cube/hump.
  hump=np.exp(-((p[:,2]+.38)/.80)**2)*{3:.10,6:.34,9:.68}[STAGE]
  p[:,1]+=hump*np.clip((p[:,1]+.25)/.8,0,1)
  p[:,2]*={3:1.08,6:1.16,9:1.23}[STAGE]
 elif name.endswith('Leg') or name.endswith('ToeSplit'):
  p[:,0]*={3:1.05,6:1.19,9:1.40}[STAGE]
  p[:,2]*={3:1.08,6:1.16,9:1.23}[STAGE]
 elif name.startswith('Tail'):
  p[:,2]*={3:1.08,6:1.16,9:1.23}[STAGE]
 else:
  p[:,0]*={3:1.05,6:1.19,9:1.40}[STAGE]
  p[:,2]*={3:1.08,6:1.16,9:1.23}[STAGE]
 m['p']=p.tolist()

def curved_tusk(name,path,radii,kind='Ivory',sides=6):
 m=mesh(name);rows=[]
 for i,c in enumerate(path):
  axis=np.array(path[min(i+1,len(path)-1)])-np.array(path[max(i-1,0)]);axis/=np.linalg.norm(axis)
  side=np.cross(axis,(0,0,1));side/=np.linalg.norm(side);up=np.cross(axis,side)
  rows.append([np.array(c)+radii[i]*(math.cos(j*math.tau/sides)*side+math.sin(j*math.tau/sides)*up) for j in range(sides)])
 for i in range(len(rows)-1):
  for j in range(sides):
   k=(j+1)%sides;quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(j/sides,i/(len(rows)-1)),(k/sides,i/(len(rows)-1)),(k/sides,(i+1)/(len(rows)-1)),(j/sides,(i+1)/(len(rows)-1))],kind,rows[i][j]-np.array(path[i]))
 for i in (0,-1):
  for j in range(sides):tri(m,[path[i],rows[i][j],rows[i][(j+1)%sides]],[(.5,.5),(0,0),(1,1)],kind)
def body_surface_y(x,z):
 positions=np.asarray(next(m for m in meshes if m['name']=='Body')['p'])
 heights=[]
 for i in range(0,len(positions),3):
  p=positions[i:i+3];a=np.stack((p[:,0],p[:,2],np.ones(3)))
  if abs(np.linalg.det(a))<1e-9:continue
  weights=np.linalg.solve(a,np.array((x,z,1)))
  if weights.min()>=-1e-7:heights.append(float(weights@p[:,1]))
 assert heights,(x,z,'unattached bramble')
 return max(heights)
for sg,side in ((-1,'Left'),(1,'Right')):
 if STAGE==3:
  path=[(sg*.66,.21,-2.0),(sg*.80,.36,-2.21),(sg*.86,.66,-2.25)]
  radii=[.11,.08,.025]
 elif STAGE==6:
  path=[(sg*.73,.22,-2.06),(sg*.98,.35,-2.32),(sg*1.07,.76,-2.45),(sg*.99,1.10,-2.35)]
  radii=[.17,.14,.09,.015]
 else:
  path=[(sg*.83,.20,-2.12),(sg*1.19,.33,-2.43),(sg*1.36,.73,-2.59),(sg*1.31,1.22,-2.54),(sg*1.14,1.55,-2.38)]
  radii=[.23,.20,.15,.09,.015]
 curved_tusk(side+'Tusk',path,radii)

 # Forehead sprouts remain small so the central evolution feature reads clearly.
 leaf(side+'ForeheadLeaf',(sg*.18,{3:1.32,6:1.20,9:1.08}[STAGE],-1.24),(sg*.5,.72,.12),.42,.28,.055)

# The dorsal organ changes construction, not merely scale: young shoots,
# a thorn-bearing woody ridge, then a broad flowering bramble colony.
def branch(name,path,radii):
 curved_tusk(name,path,radii,'Hoof',4)
def thorn(name,root,direction,length,radius):
 root=np.asarray(root,float);axis=np.asarray(direction,float);axis/=np.linalg.norm(axis)
 curved_tusk(name,[root,root+axis*length],[radius,.002],'Ivory',4)
def flower(name,center,radius):
 c=np.asarray(center,float)
 # Five thick, closed pointed petals, arranged on a shallow tilted plane.
 for k in range(5):
  angle=k*math.tau/5
  direction=np.array((math.cos(angle),.25,math.sin(angle)))
  # Use the same closed leaf primitive but switch the petal atlas tile.
  before=len(meshes)
  leaf(name+'Petal'+str(k),c,direction,radius,.55*radius,.06)
  petal=meshes[-1]
  # Leaf tile is (1,1), Cream is (0,1): preserve local UV coordinates.
  petal['uv']=[[u-.25,v] for u,v in petal['uv']]
 # Small central pink bud; no external character's iconic single flower.
 loft(name+'Center',[(tuple(c+np.array((0,0,-.07))),radius*.18,radius*.18),(tuple(c+np.array((0,0,.07))),radius*.18,radius*.18)],'Pink',5)

if STAGE==3:
 # Several broad juvenile shoots form a compact, unmistakable seedling clump.
 for j,z in enumerate((-.25,.28,.80)):
  y=body_surface_y(0,z)-.08
  branch('SproutStem'+str(j),[(0,y,z),(0,y+.30,z+.10)],[.07,.04])
  for sg in (-1,1):
   leaf('YoungShoot'+str(j)+str(sg),(0,y+.22,z+.08),(sg*.75,.80,.22),.68,.52,.09)
elif STAGE==6:
 # A tall, jagged dorsal hedge: visible brown forks and ivory thorns.
 for j,z in enumerate((-.35,.25,.85)):
  y=body_surface_y(0,z)-.10
  peak=np.array((0,y+.55,z+.18))
  branch('ThornTrunk'+str(j),[(0,y,z),tuple(peak)],[.16,.08])
  thorn('RidgeThorn'+str(j),peak,(0,1,.10),.55,.12)
  for sg in (-1,1):
   end=peak+np.array((sg*.78,.20,.18))
   branch('ThornFork'+str(j)+str(sg),[tuple(peak-np.array((0,.24,0))),tuple(end)],[.09,.045])
   thorn('ForkThorn'+str(j)+str(sg),end,(sg*.5,.7,.10),.38,.085)
   leaf('AdultLeaf'+str(j)+str(sg),end,(sg*.55,.25,.55),.68,.43,.08)
else:
 # A broad, multibranch living bramble canopy, anchored along the spine.
 # Gaps expose the branch network and keep the model readable on mobile.
 for j,z in enumerate((-.40,.28,1.0)):
  y=body_surface_y(0,z)-.12
  hub=np.array((0,y+.48,z+.22))
  branch('ElderTrunk'+str(j),[(0,y,z),tuple(hub)],[.23,.13])
  thorn('CrownSpine'+str(j),hub,(0,1,.18),.65,.15)
  for sg in (-1,1):
   bend=hub+np.array((sg*.75,.18,.12))
   end=hub+np.array((sg*1.50,.16,.28))
   branch('CanopyBranch'+str(j)+str(sg),[tuple(hub-np.array((0,.15,0))),tuple(bend),tuple(end)],[.13,.105,.045])
   thorn('CanopyThorn'+str(j)+str(sg),bend,(sg*.2,1,.05),.42,.095)
   leaf('CanopyLeafOuter'+str(j)+str(sg),end,(sg*.80,.18,.48),1.02,.80,.13)
   leaf('CanopyLeafInner'+str(j)+str(sg),bend,(sg*.25,.25,.90),1.08,.76,.13)
   leaf('CanopyDrape'+str(j)+str(sg),bend,(sg*.85,-.25,.35),1.15,.75,.13)
   if j==0:flower('BrambleBloom'+str(j)+str(sg),end+np.array((0,.08,0)),.29)
 # Extra rear fork extends the bush silhouette beyond the broad shoulders.
 y=body_surface_y(0,1.15)-.10
 branch('RearCrown',[(0,y,1.15),(0,y+.42,1.65),(0,y+.50,2.10)],[.17,.10,.035])
 for sg in (-1,1):
  leaf('RearCrownLeaf'+str(sg),(0,y+.42,1.65),(sg*.7,.20,.8),.86,.52,.10)
# Use the entire visible silhouette, including bramble tips, for medium size.
ground=min(p[1] for m in meshes if m['name'].endswith('Leg') for p in m['p'])
top=max(p[1] for m in meshes for p in m['p'])
ratio={3:5.0,6:10.0,9:15.0}[STAGE]/(top-ground)
for m in meshes:
 p=np.asarray(m['p'],float)*ratio;m['p']=p.tolist()
 for i in range(0,len(p),3):
  normal=np.cross(p[i+1]-p[i],p[i+2]-p[i]);normal/=np.linalg.norm(normal)
  m['n'][i:i+3]=[normal.tolist()]*3
 assert np.isfinite(p).all() and ((np.asarray(m['uv'])>=0)&(np.asarray(m['uv'])<=1)).all()
assert len([m for m in meshes if m['name'].endswith('Leg')])==4
'''
 source=source.replace('# Export',growth+'\n# Export')
 source=source.replace("'rigged':False","'rigged':False,'heightStuds':{3:5.0,6:10.0,9:15.0}[STAGE],'heightIncludesPlants':True,'avatarReferenceStuds':5")
 exec(compile(source,str(__file__),'exec'),{'__file__':str(__file__),'STAGE':stage})
