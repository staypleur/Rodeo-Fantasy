"""Export exact S3 samples and guarded, reversible Studio installation."""
from pathlib import Path
import json
import subprocess
from mossrat_rig_common import load, read
ROOT=Path(__file__).resolve().parents[1]
def long(s):
    m='='
    while ']'+m+']' in s: m+='='
    return '['+m+'['+s+']'+m+']'
def build():
    g,b=load(ROOT/'assets/models/MossratS6UserRig/MossratS6Rigged.glb')
    lines=['-- Generated exact S6 glTF samples.','return {height=1.71,bones={']
    lines += [json.dumps(g['nodes'][j]['name'])+',' for j in g['skins'][0]['joints']]
    lines += ['},clips={']
    for a in g['animations']:
        if a['name'] not in ('Idle','Walk'): continue
        channels=[]
        for c in a['channels']:
            s=a['samplers'][c['sampler']]; ts=read(g,b,s['input']).ravel(); vals=read(g,b,s['output']).astype(float)
            if c['target']['path']=='translation': vals-=g['nodes'][c['target']['node']].get('translation',[0,0,0])
            rows=','.join('{'+','.join(format(float(v),'.9g') for v in row)+'}' for row in vals)
            channels.append('{bone='+json.dumps(g['nodes'][c['target']['node']]['name'])+',path='+json.dumps(c['target']['path'])+',values={'+rows+'}},')
        lines += [a['name']+'={duration='+str(float(ts[-1]))+',fps=24,channels={',*channels,'}},']
    lines+=['}}']
    (ROOT/'src/shared/UserMossratRigDataS6.luau').write_text('\n'.join(lines)+'\n',encoding='utf8')

if __name__=='__main__': build()
