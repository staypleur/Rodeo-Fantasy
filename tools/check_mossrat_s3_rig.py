"""Preservation, bind pose, four-influence skinning and animation checks."""
import numpy as np
from mossrat_rig_common import ROOT,load,read,skin
p=ROOT/'assets/models/MossratS3UserRig'
source,sb=load(p/'Source.glb');g,b=load(p/'MossratS3Rigged.glb')
a=source['meshes'][0]['primitives'][0];r=g['meshes'][0]['primitives'][0]
for name in ('POSITION','NORMAL','TEXCOORD_0'):
    assert np.array_equal(read(source,sb,a['attributes'][name]),read(g,b,r['attributes'][name])),name
assert np.array_equal(read(source,sb,a['indices']),read(g,b,r['indices']))
def image_bytes(doc,buf,i):
    v=doc['bufferViews'][doc['images'][i]['bufferView']];o=v.get('byteOffset',0)
    return buf[o:o+v['byteLength']]
for i in range(len(source['images'])):assert image_bytes(source,sb,i)==image_bytes(g,b,i)
weights=read(g,b,r['attributes']['WEIGHTS_0']);joints=read(g,b,r['attributes']['JOINTS_0'])
assert weights.shape[1]==4 and np.all(weights>=0) and np.max(abs(weights.sum(axis=1)-1))<1e-6
assert len(g['skins'][0]['joints'])==34 and joints.max()<34
rest=read(g,b,r['attributes']['POSITION']); posed,_=skin(g,b)
assert np.max(abs(rest-posed))<1e-6
for clip in ('Idle','Walk','LookAround','RigRange'):
    for t in np.linspace(0,2,17):
        posed,_=skin(g,b,clip,float(t))
        assert np.isfinite(posed).all() and np.max(np.linalg.norm(posed-rest,axis=1))<.5,(clip,t)
print('S3_RIG_PASS: geometry, UV, indices, normals, texture bytes, bind pose, 34 joints, weights and 68 animation samples')
