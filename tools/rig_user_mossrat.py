"""Reference-specific full-body Mossrat rig, review only; does not install in game."""
from pathlib import Path
import copy
import hashlib
import io
import json
import shutil
import struct
import numpy as np
from PIL import Image
from mossrat_rig_common import ASSETS, load, read, matrix, quat

SOURCE = Path('C:/Users/wucha/Downloads/Meshy_AI_Mossrat_1Star_Remesh__1010052217_texture.glb')


def build():
    ASSETS.mkdir(parents=True,exist_ok=True)
    source_path = SOURCE if SOURCE.exists() else ASSETS/'Source.glb'
    original, source_bin = load(source_path)
    assert len(original['meshes']) == 1 and len(original['nodes']) == 1
    assert not original.get('skins') and not original.get('animations')
    if source_path.resolve() != (ASSETS/'Source.glb').resolve():
        shutil.copyfile(source_path,ASSETS/'Source.glb')
    src = original['meshes'][0]['primitives'][0]
    v = read(original,source_bin,src['attributes']['POSITION'])
    normals = read(original,source_bin,src['attributes']['NORMAL'])
    uv = read(original,source_bin,src['attributes']['TEXCOORD_0'])
    indices = read(original,source_bin,src['indices']).ravel()
    source_count = len(v)
    bones = []; names = {}; anchors = []
    def bone(name, parent, point):
        names[name] = len(bones); anchors.append(np.array(point,float))
        parent_id = names[parent] if parent else None
        bones.append(dict(name=name,parent=parent_id))
    bone('Root',None,(0,0,0))
    bone('Pelvis','Root',(.04,.27,-.28))
    bone('Spine','Pelvis',(.02,.32,-.16))
    bone('Chest','Spine',(-.015,.34,0))
    bone('Neck','Chest',(-.04,.37,.12))
    bone('Head','Neck',(-.055,.49,.25))
    bone('Jaw','Head',(-.06,.30,.40))
    # Anatomical left is +X for a creature looking along +Z.
    for label,point in [('Left',(.073,.398,.412)),('Right',(-.19,.416,.45))]:
        bone('Eye'+label,'Head',point)
    for label,point in [('Left',(.21,.54,.13)),('Right',(-.31,.53,.12))]:
        bone('Ear'+label,'Head',point)
        bone('EarTip'+label,'Ear'+label,(point[0],.655,point[2]))
    bone('Sprout','Head',(-.05,.71,.21))
    bone('SproutTip','Sprout',(-.06,.805,.24))
    bone('WhiskerLeft','Head',(.18,.29,.40))
    bone('WhiskerRight','Head',(-.28,.30,.40))
    for label,x in [('Left',.235),('Right',-.245)]:
        for limb,z,parent in [('Front',.02,'Chest'),('Rear',-.31,'Pelvis')]:
            hip_y = .225 if limb == 'Front' else .255
            bone(label+limb+'Upper',parent,(x,hip_y,z))
            bone(label+limb+'Lower',label+limb+'Upper',(x,.115,z+.006))
            bone(label+limb+'Paw',label+limb+'Lower',(x,.035,z+.022))
    tail = [(.15,.195,-.37),(.25,.25,-.435),(.33,.325,-.465),(.40,.40,-.465),(.435,.45,-.465)]
    for i,p in enumerate(tail): bone('Tail'+str(i+1),'Pelvis' if i == 0 else 'Tail'+str(i),p)
    anchors = np.array(anchors)
    # Region-aware capsule envelopes, smoothly normalized; at most four joints.
    weights = np.zeros((source_count,len(bones)),float)
    def smooth(x):
        x = np.clip(x,0,1); return x*x*(3-2*x)
    def assign(mask, candidates, scores):
        selected = np.flatnonzero(mask)
        if not len(selected): return
        scores = np.maximum(np.asarray(scores),1e-9)
        scores /= scores.sum(axis=1)[:,None]
        weights[selected] = 0
        for col,name in enumerate(candidates): weights[selected,names[name]] = scores[:,col]
    # Torso chain follows longitudinal positions, neck blends into bulky head.
    body_names = ['Pelvis','Spine','Chest','Neck','Head']
    d = np.linalg.norm(v[:,None,:]-anchors[[names[n] for n in body_names]][None,:,:],axis=2)
    assign(np.ones(source_count,bool),body_names,np.exp(-d*d/.035))
    head = (v[:,2]>.10)&(v[:,1]>.275)
    head_mix = smooth((v[head,1]-.28)/.13)
    assign(head,['Neck','Head'],np.column_stack((1-head_mix,head_mix)))
    jaw = (v[:,2]>.365)&(v[:,1]<.315)&(v[:,1]>.205)
    mix = smooth((.315-v[jaw,1])/.08)*.75
    assign(jaw,['Head','Jaw'],np.column_stack((1-mix,mix)))
    # Lower limbs stay separated by fore/rear and left/right gates.
    leg = (v[:,1]<.23)&(np.abs(v[:,0])>.145)
    for label,side in [('Left',1),('Right',-1)]:
        for limb,is_front,parent in [('Front',True,'Chest'),('Rear',False,'Pelvis')]:
            mask = leg&(v[:,0]*side>0)&((v[:,2]>-.16) if is_front else (v[:,2]<=-.16))
            y = v[mask,1]
            paw = smooth((.105-y)/.06); upper = smooth((y-.095)/.095)
            torso = smooth((y-.18)/.06)*.3
            assign(mask,[parent,label+limb+'Upper',label+limb+'Lower',label+limb+'Paw'],
                   np.column_stack((torso,(1-torso)*upper,(1-torso)*(1-upper)*(1-paw),(1-torso)*(1-upper)*paw)))
    # Ears separated from cheek/crown by height, front/back and lateral position.
    for label,side in [('Left',1),('Right',-1)]:
        mask = (v[:,1]>.50)&(v[:,2]<.29)&((v[:,0]>.13) if side == 1 else (v[:,0]<-.235))
        attachment = smooth((v[mask,1]-.50)/.075)
        tip = smooth((v[mask,1]-.64)/.09)*.45
        assign(mask,['Head','Ear'+label,'EarTip'+label],np.column_stack((1-attachment,attachment*(1-tip),attachment*tip)))
    sprout = (v[:,1]>.705)&(v[:,0]>-.28)&(v[:,0]<.16)
    mix = smooth((v[sprout,1]-.705)/.045); tip = smooth((v[sprout,1]-.80)/.075)*.7
    assign(sprout,['Head','Sprout','SproutTip'],np.column_stack((1-mix,mix*(1-tip),mix*tip)))
    tail_mask = ((v[:,2]<-.34)&(v[:,1]>.195)&(v[:,0]>.225))|((v[:,2]<-.20)&(v[:,1]>.28)&(v[:,0]>.355))
    dist = np.linalg.norm(v[tail_mask,None,:]-anchors[[names['Tail'+str(i)] for i in range(1,6)]][None,:,:],axis=2)
    scores = np.exp(-dist*dist/.004)
    attach = smooth((np.linalg.norm(v[tail_mask]-anchors[names['Tail1']],axis=1))/.065)
    assign(tail_mask,['Pelvis']+['Tail'+str(i) for i in range(1,6)],np.column_stack((1-attach,scores*attach[:,None])))
    # Baked eye textures: restrained eye-patch motion, not new eyeball topology.
    for label in ('Left','Right'):
        p = anchors[names['Eye'+label]]
        ellipse = ((v[:,0]-p[0])/.090)**2+((v[:,1]-p[1])/.108)**2
        mask = (ellipse<1.8)&(v[:,2]>p[2]-.09)
        eye = smooth((1.8-ellipse[mask])/.4)
        assign(mask,['Head','Eye'+label],np.column_stack((1-eye,eye)))
    for label,side in [('Left',1),('Right',-1)]:
        mask = (v[:,1]>.235)&(v[:,1]<.345)&(v[:,2]>.31)&((v[:,0]>.235) if side>0 else (v[:,0]<-.325))
        assign(mask,['Head','Whisker'+label],np.tile([.15,.85],(mask.sum(),1)))
    # Weld duplicates before smoothing to avoid split-UV cracks during skinning.
    _,inverse = np.unique(np.round(v,6),axis=0,return_inverse=True)
    welded = np.zeros((inverse.max()+1,len(bones)))
    counts = np.bincount(inverse)
    np.add.at(welded,inverse,weights); welded /= counts[:,None]
    edges = np.concatenate([indices.reshape(-1,3)[:,[0,1]],indices.reshape(-1,3)[:,[1,2]],indices.reshape(-1,3)[:,[2,0]]])
    edges = np.unique(np.sort(inverse[edges],axis=1),axis=0)
    degree = np.bincount(edges.ravel(),minlength=len(welded))
    for _ in range(3):
        neighbor = np.zeros_like(welded)
        np.add.at(neighbor,edges[:,0],welded[edges[:,1]])
        np.add.at(neighbor,edges[:,1],welded[edges[:,0]])
        welded = welded*.72+neighbor/np.maximum(1,degree)[:,None]*.28
        welded /= welded.sum(axis=1)[:,None]
    weights = welded[inverse]
    joints = np.argsort(-weights,axis=1)[:,:4]
    weights = np.take_along_axis(weights,joints,axis=1); weights /= weights.sum(axis=1)[:,None]
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
    g['meshes']=[dict(name='MossratS1Body',primitives=[p])]
    g['nodes']=[dict(name='MossratS1',mesh=0,skin=0)]
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
        bob=.003*np.sin(cycle*2) if clip=='Walk' else .0015*np.sin(cycle)
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
            offset=np.zeros((len(ts),3));offset[:,0]=.0015*np.sin(cycle)
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
    (ASSETS/'MossratS1Rigged.glb').write_bytes(struct.pack('<4sII',b'glTF',2,28+len(js)+len(binary))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(binary),b'BIN\0')+binary)
    # Documented Studio .gltf import format with preserved full resolution images.
    external=copy.deepcopy(g)
    for i,image in enumerate(external['images']):
        view=g['bufferViews'][image.pop('bufferView')];name=f'MossratTexture{i}.png'
        (ASSETS/name).write_bytes(binary[view['byteOffset']:view['byteOffset']+view['byteLength']]); image['uri']=name
    geometry_end=g['bufferViews'][-len(g['images'])]['byteOffset']
    external['bufferViews']=external['bufferViews'][:-len(g['images'])]
    external['buffers']=[dict(uri='MossratS1Rigged.bin',byteLength=geometry_end)]
    (ASSETS/'MossratS1Rigged.bin').write_bytes(binary[:geometry_end])
    (ASSETS/'MossratS1Rigged.gltf').write_text(json.dumps(external,indent=2)+'\n',encoding='utf-8')
    report=dict(source=SOURCE.name,sourceSha256=hashlib.sha256(source_path.read_bytes()).hexdigest(),sourceTriangles=len(read(original,source_bin,src['indices']))//3,
                riggedTriangles=len(indices)//3,vertices=len(v),bones=len(bones),maxInfluences=4,clips=[a['name'] for a in g['animations']],
                originalGeometryNormalsUVPreserved=True,originalTextureBytesPreserved=True,addedEyelidTriangles=0,blinkEnabled=False,
                eyeMotion='Restrained textured eye-patch translation; eyes remain open, no eyelid geometry or blink animation',
                heightMetres=.9,targetHeightStuds=2.5,frontAxis='+Z',rigReviewApproved=False,installedInGame=False,
                studioVerified=False,mobilePerformanceMeasured=False)
    (ASSETS/'metadata.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (ASSETS/'bone_landmarks.json').write_text(json.dumps([dict(name=b['name'],parent=b['parent'],worldPosition=anchors[i].tolist()) for i,b in enumerate(bones)],indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False))


if __name__=='__main__': build()
