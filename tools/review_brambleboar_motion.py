"""Render actual skinning driven by the existing shared IK/provided run clip.
This is an offline mesh deformation review, not a Studio/game performance test.
"""
import copy,json,subprocess
import numpy as np
from PIL import Image,ImageDraw
from scipy.spatial.transform import Rotation
from mossrat_rig_common import ROOT,load,skin,transforms,read,quat
from render_mossrat_rig_review import render

def quad_pose(g,phase):
 h=copy.deepcopy(g);lookup={n.get('name'):i for i,n in enumerate(g['nodes'])}
 code='local M=(function()\n'+(ROOT/'src/shared/QuadrupedMotion.luau').read_text()+'\nend)()\n';legs=[]
 for side in ['Left','Right']:
  for limb in ['Front','Rear']:
   name=side+limb;u=np.array(g['nodes'][lookup[name+'Lower']]['translation']);l=np.array(g['nodes'][lookup[name+'Paw']]['translation'])
   a,b=np.linalg.norm(u[1:]),np.linalg.norm(l[1:]);y,z=(u+l)[1:];length=a+b
   code+=f'local z,lift=M.foot({phase},"{name}",true);local a,b=M.solve({y}+{length}*(.06+lift*.22),{z}+z*{length}*.65,{a},{b},{-1 if limb=="Front" else 1});print(a,b)\n'
   legs.append((name,np.arctan2(u[2],-u[1]),np.arctan2(l[2],-l[1])))
 path=ROOT/'.tools/test-temp/bramble-preview.luau';path.parent.mkdir(exist_ok=True);path.write_text(code)
 lines=subprocess.check_output([str(ROOT/'.tools/luau/luau.exe'),str(path.relative_to(ROOT))],cwd=ROOT,text=True).splitlines()
 for (name,ra,rb),line in zip(legs,lines):
  a,b=map(float,line.split());upper=-(a-ra);lower=-(b-rb)-upper
  for part,angle in [('Upper',upper),('Lower',lower),('Paw',-upper-lower)]:h['nodes'][lookup[name+part]]['rotation']=quat(0,angle).tolist()
 return h

def main():
 source,sb=load(ROOT/'assets/models/MossratS6ProvidedRig/Running.glb');rest=transforms(source,sb)
 sourceNames={n.get('name','').split(':')[-1]:i for i,n in enumerate(source['nodes'])}
 clip=source['animations'][0];duration=max(float(read(source,sb,s['input'])[-1,0]) for s in clip['samplers'])
 mapping=dict(Pelvis='Hips',Spine='Spine',Chest='Spine2',Neck='Neck',Head='Head')
 for side in ['Left','Right']:
  for a,b in [('FrontUpper','Arm'),('FrontLower','ForeArm'),('FrontPaw','Hand'),('RearUpper','UpLeg'),('RearLower','Leg'),('RearPaw','Foot')]:mapping[side+a]=side+b
 assets={label:load(ROOT/f'assets/models/Brambleboar/{label}/Brambleboar.glb') for label in ['S1_A','S3','S6','S9']}
 frames=[]
 for phase in np.arange(16)/16:
  frame=Image.new('RGB',(960,300),'#f7f4ed');draw=ImageDraw.Draw(frame)
  animated=transforms(source,sb,clip['name'],float(phase*duration))
  for column,(label,(g,b)) in enumerate(assets.items()):
   h=quad_pose(g,float(phase)) if label in ['S1_A','S3'] else copy.deepcopy(g)
   if label in ['S6','S9']:
    parents={c:i for i,n in enumerate(h['nodes']) for c in n.get('children',[])};world={}
    for i,n in enumerate(h['nodes']):
     if 'mesh' in n:continue
     src=sourceNames.get(mapping.get(n['name'],''));p=parents.get(i);parent=world.get(p,np.eye(3))
     if src is None:desired=parent
     else:
      ar=animated[src][:3,:3].copy();ar/=np.linalg.norm(ar,axis=0);rr=rest[src][:3,:3].copy();rr/=np.linalg.norm(rr,axis=0);desired=ar@rr.T
     n['rotation']=Rotation.from_matrix(parent.T@desired).as_quat().tolist();world[i]=desired
   v,n=skin(h,b);frame.paste(render(h,b,v,n,(.7,.15,1),size=(240,270)),(column*240,25));draw.text((column*240+10,5),label+' / shared movement',fill='#263d2a')
  frames.append(frame)
 out=ROOT/'assets/previews/Brambleboar';frames[4].save(out/'shared-motion.png');frames[0].save(out/'shared-motion.gif',save_all=True,append_images=frames[1:],duration=90,loop=0)
 g,b=assets['S1_A'];frames=[]
 for t in np.linspace(0,3,24):
  v,n=skin(g,b,'Bond',float(t));frames.append(render(g,b,v,n,(.3,.12,1),size=(320,320)))
 frames[0].save(out/'one-star-bond.gif',save_all=True,append_images=frames[1:],duration=125,loop=0)
 print('Rendered shared IK and supplied biped Running deformation; separate S1 bond review.')
if __name__=='__main__':main()
