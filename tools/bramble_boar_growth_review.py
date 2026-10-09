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
meshes[:]=[m for m in meshes if not m['name'].endswith('Tusk') and not m['name'].startswith('BrambleMane') and not m['name'].startswith('BrowLeaf')]
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

def curved_tusk(name,path,radii):
 m=mesh(name);rows=[]
 for i,c in enumerate(path):
  axis=np.array(path[min(i+1,len(path)-1)])-np.array(path[max(i-1,0)]);axis/=np.linalg.norm(axis)
  side=np.cross(axis,(0,0,1));side/=np.linalg.norm(side);up=np.cross(axis,side)
  rows.append([np.array(c)+radii[i]*(math.cos(j*math.tau/6)*side+math.sin(j*math.tau/6)*up) for j in range(6)])
 for i in range(len(rows)-1):
  for j in range(6):
   k=(j+1)%6;quad(m,[rows[i][j],rows[i][k],rows[i+1][k],rows[i+1][j]],[(j/6,i/(len(rows)-1)),(k/6,i/(len(rows)-1)),(k/6,(i+1)/(len(rows)-1)),(j/6,(i+1)/(len(rows)-1))],'Ivory',rows[i][j]-np.array(path[i]))
 for i in (0,-1):
  for j in range(6):tri(m,[path[i],rows[i][j],rows[i][(j+1)%6]],[(.5,.5),(0,0),(1,1)],'Ivory')
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
 # Bramble bristles develop from a short ridge into a broad leader's fan.
 count={3:4,6:5,9:6}[STAGE]
 for j in range(count):
  z=-.20+j*{3:.36,6:.37,9:.36}[STAGE]
  y=body_surface_y(sg*.12,z)-.08
  length={3:.72,6:1.02,9:1.30}[STAGE]*(1-.045*j)
  leaf(side+'BrambleRidge'+str(j),(sg*.12,y,z),(sg*{3:.28,6:.42,9:.62}[STAGE],.65,.68),length,{3:.38,6:.46,9:.56}[STAGE],.08)
 if STAGE>=6:
  for j in range(2 if STAGE==6 else 3):
   leaf(side+'ShoulderBramble'+str(j),(sg*.78,.64,-.44+j*.29),(sg*.65,.46,.62),.72 if STAGE==6 else .92,.40,.085)
 leaf(side+'ForeheadLeaf',(sg*.18,{3:1.32,6:1.20,9:1.08}[STAGE],-1.24),(sg*.5,.72,.12),.55 if STAGE==3 else .68,.32,.055)
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
