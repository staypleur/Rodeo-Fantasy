"""Validate actual exported skin/animations and preservation of the user source."""
from pathlib import Path
import hashlib
import json
import sys
import numpy as np
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
from mossrat_rig_common import ASSETS,load,read,skin,transforms
g,b=load(ASSETS/'MossratS1Rigged.glb');s,sb=load(ASSETS/'Source.glb')
meta=json.loads((ASSETS/'metadata.json').read_text(encoding='utf-8'))
assert hashlib.sha256((ASSETS/'Source.glb').read_bytes()).hexdigest()==meta['sourceSha256']
p=g['meshes'][0]['primitives'][0];source=s['meshes'][0]['primitives'][0]
count=s['accessors'][source['attributes']['POSITION']]['count']
for key in ('POSITION','NORMAL','TEXCOORD_0'):
    assert np.array_equal(read(g,b,p['attributes'][key])[:count],read(s,sb,source['attributes'][key])),key
assert np.array_equal(read(g,b,p['indices'])[:s['accessors'][source['indices']]['count']],read(s,sb,source['indices']))
for im,original in zip(g['images'],s['images']):
    v=g['bufferViews'][im['bufferView']];sv=s['bufferViews'][original['bufferView']]
    assert b[v['byteOffset']:v['byteOffset']+v['byteLength']]==sb[sv['byteOffset']:sv['byteOffset']+sv['byteLength']]
weights=read(g,b,p['attributes']['WEIGHTS_0']);joints=read(g,b,p['attributes']['JOINTS_0'])
assert np.isfinite(weights).all() and (weights>=0).all() and np.allclose(weights.sum(axis=1),1,atol=1e-6)
assert joints.max()<len(g['skins'][0]['joints']) and weights.shape[1]==4
pos=read(g,b,p['attributes']['POSITION']);ids=read(g,b,p['indices']).reshape(-1,3)
assert ids.max()<len(pos)
rest,_=skin(g,b);assert np.allclose(rest,pos,atol=1e-6)
# Split UV vertices must share exactly the same weights at the same position.
_,inverse=np.unique(np.round(pos[:count],6),axis=0,return_inverse=True)
blended=np.zeros((count,len(g['skins'][0]['joints'])))
for slot in range(4):blended[np.arange(count),joints[:count,slot]]+=weights[:count,slot]
first={}
for i,key in enumerate(inverse):
    if int(key) in first:assert np.allclose(blended[i],blended[first[int(key)]],atol=1e-6)
    else:first[int(key)]=i
names=[n['name'] for n in g['nodes']]
for name in ('Neck','Head','EyeLeft','EyeRight','Spine','Chest','Tail5',
             'LeftFrontPaw','RightFrontPaw','LeftRearPaw','RightRearPaw'):
    joint=g['skins'][0]['joints'].index(names.index(name))
    assert ((joints==joint)&(weights>.01)).any(),name
max_stretch=0
edges=np.unique(np.sort(np.concatenate((ids[:,[0,1]],ids[:,[1,2]],ids[:,[2,0]])),axis=1),axis=0)
length=np.linalg.norm(pos[edges[:,0]]-pos[edges[:,1]],axis=1)
for animation in g['animations']:
    assert all(c['target']['path'] in ('rotation','translation') for c in animation['channels'])
    duration=max(float(read(g,b,a['input']).max()) for a in animation['samplers'])
    first_pose,_=skin(g,b,animation['name'],0);last_pose,_=skin(g,b,animation['name'],duration)
    assert np.allclose(first_pose,last_pose,atol=1e-5),animation['name']+' loop seam'
    for t in np.linspace(0,duration,17):
        moved,norm=skin(g,b,animation['name'],float(t))
        assert np.isfinite(moved).all() and np.isfinite(norm).all()
        assert np.allclose(np.linalg.norm(norm,axis=1),1,atol=1e-5)
        ratio=np.linalg.norm(moved[edges[:,0]]-moved[edges[:,1]],axis=1)/np.maximum(length,1e-8)
        # Only report source triangles: folding cap seams are separate geometry.
        valid=(edges[:,1]<count)&(length>.002)
        max_stretch=max(max_stretch,float(np.quantile(ratio[valid],.99)))
    assert np.linalg.norm(first_pose-pos,axis=1).max()>.001
external,eb=load(ASSETS/'MossratS1Rigged.gltf')
for i,accessor in enumerate(external['accessors']):assert np.array_equal(read(external,eb,i),read(g,b,i))
for view in external['bufferViews']:assert view['byteOffset']+view['byteLength']<=len(eb)
assert len(ids)==meta['riggedTriangles'] and len(g['skins'][0]['joints'])==34
assert not any('Lid' in name for name in names) and meta['blinkEnabled'] is False
assert len(ids)==meta['sourceTriangles'] and meta['addedEyelidTriangles']==0
assert meta['rigReviewApproved'] is False and meta['installedInGame'] is False
print(f"MOSSRAT_RIG_PASS: {len(ids)} triangles, 34 bones, four clips; source/texture preserved; rest pose, welds, weights, loop endpoints and finite skinning checked; 99th percentile max edge ratio {max_stretch:.3f}")
