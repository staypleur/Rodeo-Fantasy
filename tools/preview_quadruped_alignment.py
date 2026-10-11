"""Review a continuous rest-mesh correction; never modifies installed assets."""
import copy
import numpy as np
from PIL import Image,ImageDraw
from mossrat_rig_common import ROOT,load,read
from render_mossrat_rig_review import render

canvas=Image.new('RGB',(1440,960),(247,244,237));draw=ImageDraw.Draw(canvas)
for row,stage in enumerate((1,3)):
 g,b=load(ROOT/f'assets/models/MossratS{stage}UserRig/MossratS{stage}Rigged.glb')
 p=g['meshes'][0]['primitives'][0]
 v=read(g,b,p['attributes']['POSITION']);n=read(g,b,p['attributes']['NORMAL'])
 def shift(points):
  z=points[:,2]
  if stage==3:
   cx=np.interp(z,[-.30,.12,.32],[-.05,-.22,-.30])
   # Keep the whole face rigid; blend the neck continuously into the torso.
   blend=np.clip((points[:,1]-.58)/.15,0,1)*np.clip((.12-points[:,0])/.12,0,1)*np.clip((z+.1)/.2,0,1)
   cx=cx*(1-blend)-.30*blend
  else: cx=np.interp(z,[-.28,0,.25],[.04,-.015,-.055])
  out=points.copy();out[:,0]-=cx
  return out
 corrected=shift(v)
 eps=1e-4
 jac=np.stack([(shift(v+np.eye(3)[axis]*eps)-shift(v-np.eye(3)[axis]*eps))/(2*eps) for axis in range(3)],axis=2)
 normal=np.einsum('nij,nj->ni',np.linalg.inv(jac).transpose(0,2,1),n)
 normal/=np.maximum(np.linalg.norm(normal,axis=1,keepdims=True),1e-9)
 for col,(pos,norm,eye,label) in enumerate(((v,n,(0,.13,1),'ORIGINAL'),(corrected,normal,(0,.13,1),'CENTERED REVIEW'),(corrected,normal,(.1,1,.05),'TOP REVIEW'))):
  canvas.paste(render(g,b,pos,norm,eye,size=(480,450)),(480*col,480*row+30))
  draw.text((480*col+12,480*row+8),f'S{stage} {label}',fill=(20,30,20))
canvas.save(ROOT/'docs/previews/QuadrupedAlignmentReview.png')
print('Saved mesh correction review; not installed')
