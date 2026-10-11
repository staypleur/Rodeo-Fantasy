"""Preserve supplied S6 skin; export shared world-space walk/run rotation deltas."""
from pathlib import Path
import copy, hashlib, json, shutil, sys
import numpy as np
from mossrat_rig_common import ROOT, load, read, transforms

OUT=ROOT/'assets/models/MossratS6ProvidedRig'
OUT.mkdir(parents=True,exist_ok=True)
sources={}
for mode in ('Walking','Running'):
    path=OUT/(mode+'.glb')
    if not path.exists():
        shutil.copyfile(Path('C:/Users/wucha/AppData/Local/Temp')/f'Meshy_AI_Mossrat_6Star_Rigged_biped_Animation_{mode}_withSkin.glb',path)
    sources[mode]=load(path)
g,b=sources['Walking'];joints=g['skins'][0]['joints']
rest=transforms(g,b)
def rigid(m):
    n=m.copy();n[:3,:3]/=np.linalg.norm(n[:3,:3],axis=0);return n
world={j:rigid(rest[j]) for j in joints}
ibm=read(g,b,g['skins'][0]['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
assert max(np.abs(rest[j]@ibm[k]-np.eye(4)).max() for k,j in enumerate(joints))<1e-4
names=[g['nodes'][j]['name'] for j in joints]
hip_joint=next(j for j in joints if g['nodes'][j]['name'].split(':')[-1]=='Hips')
records={}
for mode,(sg,sb) in sources.items():
    assert [sg['nodes'][j]['name'] for j in sg['skins'][0]['joints']]==names
    assert all(np.allclose(transforms(sg,sb)[j],rest[j],atol=1e-4) for j in joints)
    a=sg['animations'][0];duration=max(float(read(sg,sb,s['input'])[-1,0]) for s in a['samplers'])
    count=round(duration*30);frames=[];hips=[]
    for t in np.linspace(0,duration,count+1):
        animated=transforms(sg,sb,a['name'],float(t));frame=[]
        hips.append((animated[hip_joint][:3,3]-rest[hip_joint][:3,3]).tolist())
        for j in joints:
            delta=rigid(animated[j])[:3,:3]@world[j][:3,:3].T
            frame.append(delta.reshape(-1).tolist())
        frames.append(frame)
    records[mode]={'duration':duration,'frames':frames,'hips':hips}
# Normalize the centimeter armature to meters without changing mesh/UV/weights.
external=copy.deepcopy(g);binary=bytearray(b)
parents={c:i for i,n in enumerate(g['nodes']) for c in n.get('children',[])}
for j in joints:
    local=np.linalg.inv(world[parents[j]])@world[j] if parents.get(j) in world else world[j]
    n=external['nodes'][j]
    for key in ('translation','rotation','scale'):n.pop(key,None)
    n['matrix']=local.T.reshape(-1).tolist()
for i,n in enumerate(external['nodes']):
    if i not in joints:
        for key in ('translation','rotation','scale','matrix'):n.pop(key,None)
while len(binary)%4:binary.append(0)
data=np.array([np.linalg.inv(world[j]).T for j in joints],dtype='<f4').tobytes()
view=len(external['bufferViews']);external['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':len(data)})
binary.extend(data)
accessor=len(external['accessors']);external['accessors'].append({'bufferView':view,'componentType':5126,'count':len(joints),'type':'MAT4'})
external['skins'][0]['inverseBindMatrices']=accessor
external.pop('animations',None)
for i,im in enumerate(external['images']):
    v=g['bufferViews'][im.pop('bufferView')];path=OUT/f'Texture{i}.png'
    path.write_bytes(b[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]);im['uri']=path.name
external['buffers']=[{'uri':'MossratS6Provided.bin','byteLength':len(binary)}]
(OUT/'MossratS6Provided.bin').write_bytes(binary)
(OUT/'MossratS6Provided.gltf').write_text(json.dumps(external),encoding='utf8')
def lua(v):
    if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(x) for k,x in v.items())+'}'
    if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
    if isinstance(v,str):return json.dumps(v)
    return format(v,'.8g')
(ROOT/'src/shared/BipedMotionData.luau').write_text('-- Generated from user-provided walking/running; shared by compatible bipeds.\nreturn '+lua({'bones':names,'clips':records})+'\n',encoding='utf8')
report={'bones':len(joints),'triangles':sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),
        'sources':{m:hashlib.sha256((OUT/(m+'.glb')).read_bytes()).hexdigest() for m in sources},'clips':{k:{'duration':v['duration'],'samples':len(v['frames'])} for k,v in records.items()},'installationManifest':'installation.json'}
(OUT/'metadata.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report))
