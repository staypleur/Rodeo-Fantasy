"""Verify preserved mesh/UV topology, valid shared skins and portrait transparency."""
import numpy as np
from PIL import Image
from mossrat_rig_common import ROOT,load,read,skin
from inspect_brambleboar import SOURCE,NAMES
for label,filename in NAMES:
 original,ob=load(SOURCE/filename);g,b=load(ROOT/f'assets/models/Brambleboar/{label}/Brambleboar.glb')
 p=original['meshes'][0]['primitives'][0];q=g['meshes'][0]['primitives'][0]
 for key in ['POSITION','NORMAL','TEXCOORD_0']:assert np.array_equal(read(original,ob,p['attributes'][key]),read(g,b,q['attributes'][key])),(label,key)
 assert np.array_equal(read(original,ob,p['indices']),read(g,b,q['indices']))
 w=read(g,b,q['attributes']['WEIGHTS_0']);j=read(g,b,q['attributes']['JOINTS_0'])
 assert np.isfinite(w).all() and np.all(w>=0) and np.allclose(w.sum(1),1)
 assert j.max()<len(g['skins'][0]['joints']) and len(g['skins'][0]['joints'])==18
 rest,_=skin(g,b);assert np.allclose(rest,read(g,b,q['attributes']['POSITION']),atol=2e-6)
 for clip in g['animations']:
  for t in np.linspace(0,3,9):
   v,n=skin(g,b,clip['name'],float(t));assert np.isfinite(v).all() and np.isfinite(n).all()
 print(label,'geometry/UV preserved; valid 18-joint skin; finite draft samples')
for stage in [1,3,6,9]:
 im=np.array(Image.open(ROOT/f'assets/ui/BrambleboarPortraits/BrambleboarS{stage}.png'))
 assert im.shape==(512,512,4) and im[0,:,3].max()==0 and im[:,0,3].max()==0
 assert np.sum(im[:,:,3]==0)>im.shape[0]*im.shape[1]*.2
 print(stage,'512px RGBA portrait with transparent borders')
