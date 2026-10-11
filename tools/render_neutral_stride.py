"""Render actual skin deformation at sampled shared-IK trot poses (not gameplay)."""
import copy, json, subprocess
import numpy as np
from PIL import Image,ImageDraw
from mossrat_rig_common import ROOT,load,read,skin,quat
from render_mossrat_rig_review import render
out=ROOT/'dist/RigReviewNeutral';out.mkdir(exist_ok=True)
for name in ('MossratNeutralS1','MossratNeutralS3'):
    g,b=load(ROOT/f'assets/models/MossratNeutral/{name}/{name}.glb')
    lookup={n.get('name'):i for i,n in enumerate(g['nodes'])}
    frames=[]
    for phase in (0,.18,.38,.62):
        h=copy.deepcopy(g)
        code='local M=(function()\n'+(ROOT/'src/shared/QuadrupedMotion.luau').read_text()+'\nend)()\n'
        legs=[]
        for side in ('Left','Right'):
            for limb in ('Front','Rear'):
                label=side+limb
                u=np.array(g['nodes'][lookup[label+'Lower']]['translation'])
                l=np.array(g['nodes'][lookup[label+'Paw']]['translation'])
                a,bn=np.linalg.norm(u[1:]),np.linalg.norm(l[1:])
                y,z=(u+l)[1:];length=a+bn
                code+=f'local z,lift=M.foot({phase},"{label}",true); local a,b=M.solve({y}+{length}*(.06+lift*.22),{z}+z*{length}*.65,{a},{bn},{-1 if limb=="Front" else 1}); print(a,b)\n'
                legs.append((label,np.arctan2(u[2],-u[1]),np.arctan2(l[2],-l[1])))
        path=ROOT/'.tools/test-temp/neutral-preview.luau';path.parent.mkdir(exist_ok=True);path.write_text(code)
        values=subprocess.check_output([str(ROOT/'.tools/luau/luau.exe'),str(path.relative_to(ROOT))],cwd=ROOT,text=True).splitlines()
        for (label,ra,rb),line in zip(legs,values):
            a,bn=map(float,line.split());upper=-(a-ra);lower=-(bn-rb)-upper
            for part,angle in [('Upper',upper),('Lower',lower),('Paw',-upper-lower)]:h['nodes'][lookup[label+part]]['rotation']=quat(0,angle).tolist()
        v,n=skin(h,b);im=render(h,b,v,n,(1,.22,1.5),size=(350,350))
        ImageDraw.Draw(im).text((12,10),f'phase {phase}',fill='black');frames.append(im)
    sheet=Image.new('RGB',(1400,350))
    for i,im in enumerate(frames):sheet.paste(im,(i*350,0))
    sheet.save(out/f'{name}StrideV2.png')
    print(name,'rendered')
