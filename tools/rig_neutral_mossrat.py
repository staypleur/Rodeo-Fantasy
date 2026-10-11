"""Skin the supplied straight-pose quadrupeds without altering geometry or UVs.
Shared joint names/animation; fit landmarks per morphology, max four weights.
"""
from pathlib import Path
import copy, hashlib, json, shutil, struct
import numpy as np
from mossrat_rig_common import ROOT, load, read, quat

SOURCES={
 'MossratNeutralS1Hunt':('Meshy_AI_Mossrat_1Star_Straigh_1011093409_texture.glb',1),
 'MossratNeutralS1':('Meshy_AI_Mossrat_1Star_Straigh_1011093422_texture.glb',1),
 'MossratNeutralS3':('Meshy_AI_Mossrat_3Star_Straigh_1011093254_texture.glb',3),
}

def build(asset_name,filename,stage):
    ASSETS=ROOT/'assets/models/MossratNeutral'/asset_name
    ASSETS.mkdir(parents=True,exist_ok=True)
    source_path=Path('C:/Users/wucha/Downloads')/filename
    if not source_path.exists(): source_path=ASSETS/'Source.glb'
    original,source_bin=load(source_path)
    assert len(original['meshes'])==1 and not original.get('skins')
    if source_path.resolve()!=(ASSETS/'Source.glb').resolve():shutil.copyfile(source_path,ASSETS/'Source.glb')
    src=original['meshes'][0]['primitives'][0]
    v=read(original,source_bin,src['attributes']['POSITION'])
    normals=read(original,source_bin,src['attributes']['NORMAL'])
    uv=read(original,source_bin,src['attributes']['TEXCOORD_0'])
    indices=read(original,source_bin,src['indices']).ravel()
    height=float(np.ptp(v[:,1])); q=v/height; source_count=len(v)
    bones=[];names={};anchors=[]
    def bone(name,parent,point):
        names[name]=len(bones);anchors.append(np.asarray(point)*height)
        bones.append(dict(name=name,parent=names[parent] if parent else None))
    front=.36 if stage==1 else .38
    rear=-.17 if stage==1 else -.25
    hip=.31 if stage==1 else .43
    bone('Root',None,(0,0,0))
    bone('Pelvis','Root',(0,hip,rear))
    bone('Spine','Pelvis',(0,hip+.07,0))
    bone('Chest','Spine',(0,hip+.08,front-.07))
    bone('Neck','Chest',(0,.56,front))
    bone('Head','Neck',(0,.69,front+.02))
    bone('Jaw','Head',(0,.51,front+.20))
    for side,sign in [('Left',1),('Right',-1)]:bone('Eye'+side,'Head',(sign*.16,.64,front+.22))
    for side,sign in [('Left',1),('Right',-1)]:
        bone('Ear'+side,'Head',(sign*.25,.78,front-.02))
        bone('EarTip'+side,'Ear'+side,(sign*.29,.87,front-.04))
    bone('Sprout','Head',(0,.84,front-.03));bone('SproutTip','Sprout',(0,.97,front-.03))
    for side,sign in [('Left',1),('Right',-1)]:bone('Whisker'+side,'Head',(sign*.22,.55,front+.20))
    for side,sign in [('Left',1),('Right',-1)]:
        for limb,z,parent in [('Front',front,'Chest'),('Rear',rear,'Pelvis')]:
            x=sign*(.21 if stage==1 else .22)
            knee_z=z+(-.045 if limb=='Front' else .07)
            bone(side+limb+'Upper',parent,(x,hip,z))
            bone(side+limb+'Lower',side+limb+'Upper',(x,hip*.50,knee_z))
            bone(side+limb+'Paw',side+limb+'Lower',(x,.045,z+.05))
    points=([(0,.30,-.33),(0,.28,-.43),(0,.24,-.54),(0,.17,-.61),(0,.13,-.68)] if stage==1 else
            [(0,.48,-.35),(.12,.48,-.46),(.23,.51,-.52),(.31,.61,-.54),(.32,.76,-.54)])
    for i,point in enumerate(points):bone('Tail'+str(i+1),'Pelvis' if i==0 else 'Tail'+str(i),point)
    anchors=np.array(anchors)
    weights=np.zeros((source_count,len(bones)),float)
    def smooth(a):
        a=np.clip(a,0,1);return a*a*(3-2*a)
    def assign(mask,candidates,scores):
        rows=np.flatnonzero(mask)
        if not len(rows):return
        scores=np.maximum(scores,1e-12);scores/=scores.sum(1)[:,None]
        weights[rows]=0
        for col,name in enumerate(candidates):weights[rows,names[name]]=scores[:,col]
    body_names=['Pelvis','Spine','Chest','Neck','Head']
    d=np.linalg.norm(q[:,None,:]-anchors[[names[n] for n in body_names]][None,:,:]/height,axis=2)
    assign(np.ones(source_count,bool),body_names,np.exp(-d*d/.028))
    # The entire face, pupils and whiskers remain rigid to Head.
    head=(q[:,1]>.48)&(q[:,2]>.15)
    mix=smooth((q[head,1]-.48)/.12)
    assign(head,['Neck','Head'],np.column_stack((1-mix,mix)))
    for limb,z,parent in [('Front',front,'Chest'),('Rear',rear,'Pelvis')]:
        for side,sign in [('Left',1),('Right',-1)]:
            mask=(q[:,1]<hip+.10)&(q[:,0]*sign>.065)&((q[:,2]>.10) if limb=='Front' else ((q[:,2]<=.10)&(q[:,2]>rear-.15)))
            y=q[mask,1]
            torso=smooth((y-(hip-.045))/.13)
            torso=1-(1-torso)*smooth((np.abs(q[mask,0])-.08)/.10)
            lower=smooth((hip*.68-y)/(hip*.42))
            paw=smooth((.11-y)/.07)
            assign(mask,[parent,side+limb+'Upper',side+limb+'Lower',side+limb+'Paw'],np.column_stack((torso,(1-torso)*(1-lower),(1-torso)*lower*(1-paw),(1-torso)*lower*paw)))
    # Keep tail influences out of the rear legs; blend only near its attachment.
    tail=(q[:,2]<(-.34 if stage==1 else -.36))&(q[:,1]>(.055 if stage==1 else .37))
    ds=np.linalg.norm(q[tail,None,:]-anchors[[names['Tail'+str(i)] for i in range(1,6)]][None,:,:]/height,axis=2)
    scores=np.exp(-ds*ds/.008);scores/=scores.sum(1)[:,None]
    attach=smooth((-q[tail,2]-.34)/.12)
    assign(tail,['Pelvis']+['Tail'+str(i) for i in range(1,6)],np.column_stack((1-attach,scores*attach[:,None])))
    # Weld UV-split duplicates before two bounded neighbor smoothing passes.
    _,inverse=np.unique(np.round(v,6),axis=0,return_inverse=True)
    welded=np.zeros((inverse.max()+1,len(bones)));counts=np.bincount(inverse)
    np.add.at(welded,inverse,weights);welded/=counts[:,None]
    tris=indices.reshape(-1,3)
    edges=np.unique(np.sort(inverse[np.concatenate([tris[:,[0,1]],tris[:,[1,2]],tris[:,[2,0]]])],axis=1),axis=0)
    degree=np.bincount(edges.ravel(),minlength=len(welded))
    for _ in range(2):
        neighbors=np.zeros_like(welded)
        np.add.at(neighbors,edges[:,0],welded[edges[:,1]]);np.add.at(neighbors,edges[:,1],welded[edges[:,0]])
        welded=.84*welded+.16*neighbors/np.maximum(1,degree)[:,None]
        welded/=welded.sum(1)[:,None]
    full_weights=welded[inverse]
    joints=np.argsort(-full_weights,axis=1)[:,:4]
    weights=np.take_along_axis(full_weights,joints,axis=1);weights/=weights.sum(1)[:,None]
    g = copy.deepcopy(original); binary = bytearray(); g['bufferViews']=[]; g['accessors']=[]
    def append(array,typ,component=5126):
        while len(binary)%4: binary.append(0)
        arr = np.asarray(array,dtype={5126:'<f4',5123:'<u2'}[component])
        g['bufferViews'].append(dict(buffer=0,byteOffset=len(binary),byteLength=arr.nbytes))
        binary.extend(arr.tobytes()); a = dict(bufferView=len(g['bufferViews'])-1,componentType=component,count=len(arr),type=typ)
        if typ in ('VEC3','SCALAR'): a.update(min=arr.min(axis=0).reshape(-1).tolist(),max=arr.max(axis=0).reshape(-1).tolist())
        g['accessors'].append(a); return len(g['accessors'])-1
    p = dict(attributes=dict(POSITION=append(v,'VEC3'),NORMAL=append(normals,'VEC3'),TEXCOORD_0=append(uv,'VEC2'),
                             JOINTS_0=append(joints,'VEC4',5123),WEIGHTS_0=append(weights,'VEC4')),indices=append(indices,'SCALAR',5123),material=0)
    g['meshes']=[dict(name='NeutralBody',primitives=[p])]
    g['nodes']=[dict(name=asset_name,mesh=0,skin=0)]
    for i,bone_spec in enumerate(bones):
        parent = bone_spec['parent']; local = anchors[i]-(anchors[parent] if parent is not None else 0)
        g['nodes'].append(dict(name=bone_spec['name'],translation=local.tolist()))
    for i,bone_spec in enumerate(bones):
        if bone_spec['parent'] is not None:
            g['nodes'][bone_spec['parent']+1].setdefault('children',[]).append(i+1)
    ibm = np.repeat(np.eye(4)[None],len(bones),axis=0); ibm[:,:3,3] = -anchors
    g['skins']=[dict(name='MossratFullBodyRig',skeleton=1,joints=list(range(1,len(bones)+1)),inverseBindMatrices=append(ibm.transpose(0,2,1).reshape(-1,16),'MAT4'))]
    g['scenes']=[dict(nodes=[0,1])];g['scene']=0
    # Review clips are deliberately modest, so fur blocks retain their silhouette.
    g['animations']=[]
    for clip,duration in [('Idle',4),('Walk',2),('LookAround',4),('RigRange',4)]:
        ts=np.linspace(0,duration,int(duration*24)+1)
        input_id=append(ts,'SCALAR')
        anim=dict(name=clip,samplers=[],channels=[])
        def channel(name,path,values):
            out=append(values,'VEC4' if path=='rotation' else 'VEC3')
            anim['samplers'].append(dict(input=input_id,output=out,interpolation='LINEAR'))
            anim['channels'].append(dict(sampler=len(anim['samplers'])-1,target=dict(node=names[name]+1,path=path)))
        def rot(name,axis,angle): channel(name,'rotation',[quat(axis,float(a)) for a in angle])
        cycle=ts/duration*2*np.pi
        bob=.0042*np.sin(cycle*2) if clip=='Walk' else .0021*np.sin(cycle)
        channel('Root','translation',np.column_stack((np.zeros(len(ts)),bob,np.zeros(len(ts)))))
        rot('Spine',0,.024*np.sin(cycle+(0 if clip=='Walk' else .3)))
        rot('Chest',2,.018*np.sin(cycle+.4))
        rot('Neck',1,(.16 if clip in ('LookAround','RigRange') else .025)*np.sin(cycle))
        rot('Head',0,(.055 if clip=='RigRange' else .025)*np.sin(cycle+.6))
        rot('Jaw',0,.045*np.maximum(0,np.sin(cycle)) if clip=='RigRange' else .008*np.sin(cycle))
        for label in ('Left','Right'):
            phase=.4 if label=='Left' else -.4
            rot('Ear'+label,2,.06*np.sin(cycle+phase))
            rot('EarTip'+label,0,.06*np.sin(cycle+phase-.35))
            rot('Whisker'+label,1,.04*np.sin(cycle+phase))
            # Tiny patch translations preserve baked pupils and facial silhouette.
            eye=anchors[names['Eye'+label]]-anchors[names['Head']]
            offset=np.zeros((len(ts),3));offset[:,0]=.0021*np.sin(cycle)
            channel('Eye'+label,'translation',offset+eye)
        rot('Sprout',2,.055*np.sin(cycle-.4));rot('SproutTip',2,.055*np.sin(cycle-.8))
        for i in range(1,6): rot('Tail'+str(i),1,(.045 if clip=='Walk' else .065)*np.sin(cycle-i*.45))
        if clip in ('Walk','RigRange'):
            for label in ('Left','Right'):
                for limb in ('Front','Rear'):
                    phase = 0 if (label=='Left')==(limb=='Front') else np.pi
                    swing=np.sin(cycle*2+phase)
                    rot(label+limb+'Upper',0,.24*swing)
                    rot(label+limb+'Lower',0,-.20*np.maximum(0,swing))
                    rot(label+limb+'Paw',0,-.12*swing+.20*np.maximum(0,swing))
        g['animations'].append(anim)
    # Rigged detailed variant retains original encoded images byte-for-byte.
    for i,image in enumerate(g['images']):
        view = original['bufferViews'][original['images'][i]['bufferView']]
        png = source_bin[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        while len(binary)%4: binary.append(0)
        image['bufferView']=len(g['bufferViews'])
        g['bufferViews'].append(dict(buffer=0,byteOffset=len(binary),byteLength=len(png)))
        binary.extend(png)
    while len(binary)%4: binary.append(0)
    g['buffers']=[dict(byteLength=len(binary))]
    js=json.dumps(g,separators=(',',':')).encode();js+=b' '*(-len(js)%4)
    (ASSETS/f'{asset_name}.glb').write_bytes(struct.pack('<4sII',b'glTF',2,28+len(js)+len(binary))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(binary),b'BIN\0')+binary)
    # Documented Studio .gltf import format with preserved full resolution images.
    external=copy.deepcopy(g)
    for i,image in enumerate(external['images']):
        view=g['bufferViews'][image.pop('bufferView')];name=f'MossratTexture{i}.png'
        (ASSETS/name).write_bytes(binary[view['byteOffset']:view['byteOffset']+view['byteLength']]); image['uri']=(ASSETS/name).resolve().as_posix()
    geometry_end=g['bufferViews'][-len(g['images'])]['byteOffset']
    external['bufferViews']=external['bufferViews'][:-len(g['images'])]
    external['buffers']=[dict(uri=f'{asset_name}.bin',byteLength=geometry_end)]
    (ASSETS/f'{asset_name}.bin').write_bytes(binary[:geometry_end])
    (ASSETS/f'{asset_name}.gltf').write_text(json.dumps(external,indent=2)+'\n',encoding='utf-8')
    report=dict(source=filename,sha256=hashlib.sha256(source_path.read_bytes()).hexdigest(),triangles=len(indices)//3,bones=len(bones),maxInfluences=4,heightMetres=height,stage=stage,geometryPreserved=True,uvPreserved=True,texturePreserved=True)
    (ASSETS/'metadata.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    (ASSETS/'bone_landmarks.json').write_text(json.dumps([dict(name=b['name'],parent=b['parent'],worldPosition=anchors[i].tolist()) for i,b in enumerate(bones)],indent=2)+'\n',encoding='utf8')
    print(asset_name,report)
if __name__=='__main__':
    for label,(filename,stage) in SOURCES.items():build(label,filename,stage)
