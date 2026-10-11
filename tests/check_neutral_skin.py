"""Verify immutable design geometry, normalized skinning and all four leg chains."""
from pathlib import Path
import sys
import numpy as np
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools'))
from mossrat_rig_common import load,read,skin
from rig_neutral_mossrat import SOURCES
for name in SOURCES:
    folder=root/'assets/models/MossratNeutral'/name
    g,b=load(folder/f'{name}.glb');source,raw=load(folder/'Source.glb')
    p=g['meshes'][0]['primitives'][0];o=source['meshes'][0]['primitives'][0]
    for attr in ('POSITION','NORMAL','TEXCOORD_0'):
        assert np.array_equal(read(g,b,p['attributes'][attr]),read(source,raw,o['attributes'][attr])),(name,attr)
    assert np.array_equal(read(g,b,p['indices']),read(source,raw,o['indices']))
    w=read(g,b,p['attributes']['WEIGHTS_0']);j=read(g,b,p['attributes']['JOINTS_0'])
    assert w.shape[1]==4 and np.isfinite(w).all() and (w>=0).all()
    assert np.allclose(w.sum(axis=1),1,atol=1e-6)
    positions,_=skin(g,b)
    assert np.allclose(positions,read(g,b,p['attributes']['POSITION']),atol=1e-6)
    s=g['skins'][0]
    for side in ('Left','Right'):
        for limb in ('Front','Rear'):
            previous=None
            for part in ('Upper','Lower','Paw'):
                index=next(i for i,n in enumerate(g['nodes']) if n.get('name')==side+limb+part)
                joint=s['joints'].index(index)
                assert w[j==joint].sum()>.1,(name,side,limb,part)
                if previous is not None: assert index in g['nodes'][previous]['children']
                previous=index
    print('NEUTRAL_SKIN_PASS',name,len(read(g,b,p['indices']))//3,'triangles; unchanged geometry; bind pose; 12 weighted leg joints')
