"""Run IK tests under Unicode workspaces and verify supplied biped samples."""
from pathlib import Path
import sys,subprocess,tempfile,json
import numpy as np

root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools'))
from mossrat_rig_common import load,read,transforms

source=(root/'src/shared/QuadrupedMotion.luau').read_text(encoding='utf8')
test=(root/'tests/quadruped_motion.luau').read_text(encoding='utf8')
test=test.replace('local motion=require("../src/shared/QuadrupedMotion")','local motion=(function()\n'+source+'\nend)()')
scratch=root/'.tools/test-temp'
scratch.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='rodeo-motion-',dir=scratch) as folder:
    path=Path(folder)/'test.luau';path.write_text(test,encoding='utf8')
    subprocess.run([str(root/'.tools/luau/luau.exe'),str(path.relative_to(root))],cwd=root,check=True)

for mode in ('Walking','Running'):
    g,b=load(root/f'assets/models/MossratS6ProvidedRig/{mode}.glb')
    joints=g['skins'][0]['joints'];assert len(joints)==23
    rest=transforms(g,b)
    ibm=read(g,b,g['skins'][0]['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
    assert max(np.abs(rest[j]@ibm[k]-np.eye(4)).max() for k,j in enumerate(joints))<1e-4
    primitive=g['meshes'][0]['primitives'][0]
    weights=read(g,b,primitive['attributes']['WEIGHTS_0'])
    assert np.allclose(weights.sum(axis=1),1,atol=1e-5)
    assert sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives'])==10218
    clip=g['animations'][0]
    duration=max(float(read(g,b,s['input'])[-1,0]) for s in clip['samplers'])
    for t in np.linspace(0,duration,61):
        assert all(np.isfinite(m).all() for m in transforms(g,b,clip['name'],float(t)).values())
    print(mode,'PASS: bind matrices, normalized weights, 61 finite skeleton samples')

print('SHARED_MOTION_PASS (mathematical checks, not visual/mobile approval)')
