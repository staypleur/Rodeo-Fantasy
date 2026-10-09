"""Bring the majestic C head forward; static review only, no place changes."""
import numpy as np
from PIL import Image
import faceted_airship_mesh as F
from airship_c_grand_review import atlas

F.STEM='Airship_C_ForwardFaceReview'
# Retain every wing, torso decoration and tail vertex exactly as reviewed.
unchanged={m['name']:np.asarray(m['p']).copy() for m in F.meshes
           if m['name']!='SovereignBody' and not any(k in m['name'] for k in
           ('Eye','Brow','Muzzle','GreatTusk','Ear','GrandTrunk','TrunkGoldBand','RoyalCrown'))}
F.meshes[:]=[m for m in F.meshes if m['name']!='SovereignBody']
# A substantial head extends beyond a short neck; the chest/torso rings stay put.
F.loft('SovereignBody',[
 ((0,9,-49),12,14),((0,10,-43),17,17),((0,9,-34),17,17),
 ((0,7,-27),13.5,13.5),((0,7,-18),20,21),
 ((0,4,-2),23,23),((0,2,16),21,20),((0,0,30),14,14),
 ((0,-1,40),7,7),((0,-1,46),2,2)],sides=12)
for m in F.meshes:
 if any(k in m['name'] for k in ('Eye','Brow','Muzzle','GreatTusk','GrandTrunk','TrunkGoldBand','RoyalCrown')):
  m['p']=(np.asarray(m['p'])+np.array((0,2,-15))).tolist()
 elif m['name'].endswith('Ear'):
  m['p']=(np.asarray(m['p'])+np.array((0,2,-9))).tolist()
 if m['name'] in unchanged:assert np.array_equal(m['p'],unchanged[m['name']])
 p=np.asarray(m['p']);n=np.asarray(m['n']);uv=np.asarray(m['uv'])
 assert np.isfinite(p).all() and np.isfinite(n).all() and ((uv>=0)&(uv<=1)).all()
 for i in range(0,len(p),3):
  assert np.allclose(n[i],n[i+1]) and np.allclose(n[i],n[i+2])
  assert np.dot(np.cross(p[i+1]-p[i],p[i+2]-p[i]),n[i])>1e-8
count=F.save(Image.fromarray(atlas))
assert count==1974 and count<2000
print(f'FORWARD_FACE_PASS: {count} triangles; face advanced 15 units; wings/torso trim/tail preserved; review only')
