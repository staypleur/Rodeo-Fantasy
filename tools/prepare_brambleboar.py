"""Prepare original-pixel portraits and shared quadruped/biped review rigs.

Original geometry/UVs remain intact. Textures are resized for mobile review;
source files are read in place and never overwritten. No game installation.
"""
from pathlib import Path
import copy,io,json,struct
import numpy as np
from PIL import Image,ImageDraw,ImageFilter
from mossrat_rig_common import ROOT,load,read,quat,skin
from inspect_brambleboar import SOURCE,NAMES
from render_mossrat_rig_review import render

def build(label,filename):
 g0,b0=load(SOURCE/filename);p0=g0['meshes'][0]['primitives'][0]
 v=read(g0,b0,p0['attributes']['POSITION']);h=float(np.ptp(v[:,1]));q=v/h
 stage=int(label[1]);quad=stage<6
 names=[];parents=[];points=[]
 def bone(name,parent,point):
  names.append(name);parents.append(names.index(parent) if parent else None);points.append(np.array(point)*h)
 if quad:
  hip=.33 if stage==1 else .31;front=.27 if stage==1 else .36;rear=-.33 if stage==1 else -.43
  bone('Root',None,(0,0,0));bone('Pelvis','Root',(0,hip,rear));bone('Spine','Pelvis',(0,hip+.12,-.10));bone('Chest','Spine',(0,hip+.12,front))
  bone('Neck','Chest',(0,.52,front));bone('Head','Neck',(0,.69,front+.07))
  for side,s in [('Left',1),('Right',-1)]:
   for limb,z,parent in [('Front',front,'Chest'),('Rear',rear,'Pelvis')]:
    bone(side+limb+'Upper',parent,(s*.19,hip,z));bone(side+limb+'Lower',side+limb+'Upper',(s*.19,.16,z+(-.03 if limb=='Front' else .03)));bone(side+limb+'Paw',side+limb+'Lower',(s*.19,.04,z+.05))
 else:
  bone('Root',None,(0,0,0));bone('Pelvis','Root',(0,.34,0));bone('Spine','Pelvis',(0,.48,0));bone('Chest','Spine',(0,.65,0));bone('Neck','Chest',(0,.76,.03));bone('Head','Neck',(0,.84,.04))
  for side,s in [('Left',1),('Right',-1)]:
   bone(side+'FrontUpper','Chest',(s*.27,.66,0));bone(side+'FrontLower',side+'FrontUpper',(s*.35,.49,.01));bone(side+'FrontPaw',side+'FrontLower',(s*.39,.36,.04))
   bone(side+'RearUpper','Pelvis',(s*.14,.34,0));bone(side+'RearLower',side+'RearUpper',(s*.16,.19,.01));bone(side+'RearPaw',side+'RearLower',(s*.17,.045,.07))
 points=np.array(points);weights=np.zeros((len(v),len(names)))
 def assign(mask,ns):
  rows=np.flatnonzero(mask)
  if not len(rows):return
  ii=[names.index(n) for n in ns];dist=np.linalg.norm(v[rows,None,:]-points[ii][None,:,:],axis=2)/h
  w=np.exp(-dist*dist/.018)+1e-12;w/=w.sum(1)[:,None];weights[rows]=0
  weights[np.ix_(rows,ii)]=w
 assign(np.ones(len(v),bool),['Pelvis','Spine','Chest'])
 if quad:
  # Whole face, eyes, tusks and ears follow their shared Neck/Head hierarchy.
  head=(q[:,1]>.42)&(q[:,2]>.12)
  weights[head]=0;weights[head,names.index('Head')]=1
  neck=(q[:,1]>.35)&(q[:,1]<.49)&(q[:,2]>.12)
  assign(neck,['Chest','Neck','Head'])
  for side,s in [('Left',1),('Right',-1)]:
   for limb,parent in [('Front','Chest'),('Rear','Pelvis')]:
    mask=(q[:,1]<hip+.07)&(q[:,0]*s>.07)&((q[:,2]>.02) if limb=='Front' else (q[:,2]<-.13))
    assign(mask,[parent,side+limb+'Upper',side+limb+'Lower',side+limb+'Paw'])
 else:
  head=(q[:,1]>.76)&(abs(q[:,0])<.23);weights[head]=0;weights[head,names.index('Head')]=1
  assign((q[:,1]>.70)&(q[:,1]<=.79)&(abs(q[:,0])<.20),['Chest','Neck','Head'])
  for side,s in [('Left',1),('Right',-1)]:
   assign((q[:,0]*s>.22)&(q[:,1]<.72),['Chest',side+'FrontUpper',side+'FrontLower',side+'FrontPaw'])
   assign((q[:,1]<.37)&(q[:,0]*s>=0)&(q[:,0]*s<.29),['Pelvis',side+'RearUpper',side+'RearLower',side+'RearPaw'])
 # Reconcile UV seams so coincident vertices deform together.
 _,inv=np.unique(np.round(v,6),axis=0,return_inverse=True);weld=np.zeros((inv.max()+1,len(names)))
 np.add.at(weld,inv,weights);weld/=np.bincount(inv)[:,None]
 if not quad:
  tris=read(g0,b0,p0['indices']).reshape(-1,3)
  edges=np.unique(np.sort(inv[np.concatenate([tris[:,[0,1]],tris[:,[1,2]],tris[:,[2,0]]])],axis=1),axis=0)
  degree=np.bincount(edges.ravel(),minlength=len(weld))
  for _ in range(6):
   neighbors=np.zeros_like(weld);np.add.at(neighbors,edges[:,0],weld[edges[:,1]]);np.add.at(neighbors,edges[:,1],weld[edges[:,0]])
   weld=.65*weld+.35*neighbors/np.maximum(degree[:,None],1)
 weights=weld[inv]
 joints=np.argsort(-weights,axis=1)[:,:4];weights=np.take_along_axis(weights,joints,1);weights/=weights.sum(1)[:,None]
 assert np.isfinite(weights).all() and np.allclose(weights.sum(1),1)
 g=copy.deepcopy(g0);g['bufferViews']=[];g['accessors']=[];buf=bytearray()
 def append(a,typ,component=5126):
  while len(buf)%4:buf.append(0)
  a=np.asarray(a,dtype={5126:'<f4',5123:'<u2'}[component]);g['bufferViews'].append(dict(buffer=0,byteOffset=len(buf),byteLength=a.nbytes));buf.extend(a.tobytes())
  acc=dict(bufferView=len(g['bufferViews'])-1,componentType=component,count=len(a),type=typ)
  if typ in ('VEC3','SCALAR'):acc.update(min=a.min(0).reshape(-1).tolist(),max=a.max(0).reshape(-1).tolist())
  g['accessors'].append(acc);return len(g['accessors'])-1
 attrs={k:append(read(g0,b0,i),{'POSITION':'VEC3','NORMAL':'VEC3','TEXCOORD_0':'VEC2'}[k]) for k,i in p0['attributes'].items() if k in ('POSITION','NORMAL','TEXCOORD_0')}
 attrs.update(JOINTS_0=append(joints,'VEC4',5123),WEIGHTS_0=append(weights,'VEC4'))
 g['meshes']=[dict(name='BrambleboarBody',primitives=[dict(attributes=attrs,indices=append(read(g0,b0,p0['indices']).ravel(),'SCALAR',5123),material=0)])]
 g['nodes']=[dict(name='Brambleboar'+label,mesh=0,skin=0)]
 for i,name in enumerate(names):g['nodes'].append(dict(name=name,translation=(points[i]-(points[parents[i]] if parents[i]!=None else 0)).tolist()))
 for i,parent in enumerate(parents):
  if parent!=None:g['nodes'][parent+1].setdefault('children',[]).append(i+1)
 ibm=np.repeat(np.eye(4)[None],len(names),0);ibm[:,:3,3]=-points
 g['skins']=[dict(name='SharedQuadruped' if quad else 'SharedBiped',skeleton=1,joints=list(range(1,len(names)+1)),inverseBindMatrices=append(ibm.transpose(0,2,1).reshape(-1,16),'MAT4'))]
 g['scenes']=[dict(nodes=[0,1])];g['scene']=0;g['animations']=[]
 for clip,duration in [('Idle',4),('Move',1.4)]+([('Bond',3)] if stage==1 else []):
  ts=np.linspace(0,duration,int(duration*24)+1);inp=append(ts,'SCALAR');anim=dict(name=clip,samplers=[],channels=[])
  def rot(name,axis,angles):
   output=append([quat(axis,float(a)) for a in angles],'VEC4');anim['samplers'].append(dict(input=inp,output=output,interpolation='LINEAR'));anim['channels'].append(dict(sampler=len(anim['samplers'])-1,target=dict(node=names.index(name)+1,path='rotation')))
  if clip=='Idle':rot('Spine',0,.012*np.sin(ts*1.8))
  if clip=='Bond':rot('Neck',2,.1*np.sin(ts*4)*np.minimum(np.clip(ts/.35,0,1),np.clip((duration-ts)/.4,0,1)))
  if clip=='Move':
   for side in ['Left','Right']:
    for limb in ['Front','Rear']:
     phase=0 if (side=='Left')==(limb=='Front') else np.pi;swing=np.sin(ts/duration*2*np.pi+phase)
     rot(side+limb+'Upper',0,(.20 if quad else .28)*swing);rot(side+limb+'Lower',0,-.22*np.maximum(0,swing));rot(side+limb+'Paw',0,-.1*swing)
  g['animations'].append(anim)
 for i,im in enumerate(g['images']):
  view=g0['bufferViews'][g0['images'][i]['bufferView']];data=b0[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
  image=Image.open(io.BytesIO(data));image.thumbnail((1024,1024) if label=='S1_B' else (2048,2048),Image.Resampling.LANCZOS);encoded=io.BytesIO();image.save(encoded,format='PNG',optimize=True)
  while len(buf)%4:buf.append(0)
  im['bufferView']=len(g['bufferViews']);im['mimeType']='image/png';g['bufferViews'].append(dict(buffer=0,byteOffset=len(buf),byteLength=len(encoded.getvalue())));buf.extend(encoded.getvalue())
 while len(buf)%4:buf.append(0)
 g['buffers']=[dict(byteLength=len(buf))];js=json.dumps(g,separators=(',',':')).encode();js+=b' '*(-len(js)%4)
 out=ROOT/'assets/models/Brambleboar'/label;out.mkdir(parents=True,exist_ok=True);path=out/'Brambleboar.glb'
 path.write_bytes(struct.pack('<4sII',b'glTF',2,28+len(js)+len(buf))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(buf),b'BIN\0')+buf)
 report=dict(source=filename,triangles=read(g0,b0,p0['indices']).size//3,bones=len(names),geometryPreserved=True,uvPreserved=True,textureResolution=1024 if label=='S1_B' else 2048,heightMetres=h,bytes=path.stat().st_size,installed=False,studioVerified=False,previewMotion='fitted joint-loop draft; not Studio playback')
 (out/'metadata.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8');print(label,report)
 return g,bytes(buf)

def portraits():
 keys=['c44536a8-98a7-41c1-868c-fe9714cfbcf6','c9971262-fc52-41e1-a9b2-7834b119b1ef','16cc7efa-e428-43ba-b774-dea5b14e4f14','a41402a5-17d4-40da-9cf2-ebafb7cc7102']
 out=ROOT/'assets/ui/BrambleboarPortraits';out.mkdir(parents=True,exist_ok=True)
 checker=Image.new('RGB',(1024,256),'#c8c8c8');d=ImageDraw.Draw(checker)
 for y in range(0,256,16):
  for x in range(0,1024,16):
   if (x//16+y//16)%2:d.rectangle((x,y,x+15,y+15),fill='#e6e6e6')
 for i,(stage,key) in enumerate(zip([1,3,6,9],keys)):
  a=np.array(Image.open(Path('C:/Users/wucha/AppData/Local/Temp')/f'codex-clipboard-{key}.png').convert('RGBA'));rgb=a[:,:,:3].astype(int)
  # Background is bright neutral; brown fur, cream tusks and green ornaments
  # fall outside this mask. Explicitly retain the eye highlights.
  bg=(rgb.min(2)>150)&(rgb.max(2)-rgb.min(2)<12)
  from scipy.ndimage import label as components
  labels,count=components(bg);border=set(labels[0])|set(labels[-1])|set(labels[:,0])|set(labels[:,-1]);sizes=np.bincount(labels.ravel())
  for n in range(1,count+1):
   if n in border or sizes[n]>300:a[labels==n,3]=0
  image=Image.fromarray(a);image.putalpha(image.getchannel('A').filter(ImageFilter.MinFilter(3)));image=image.crop(image.getbbox());image.thumbnail((480,480),Image.Resampling.LANCZOS)
  canvas=Image.new('RGBA',(512,512));canvas.alpha_composite(image,((512-image.width)//2,(512-image.height)//2));canvas.save(out/f'BrambleboarS{stage}.png',optimize=True)
  thumb=canvas.resize((256,256));checker.paste(thumb,(i*256,0),thumb)
 checker.save(ROOT/'assets/previews/Brambleboar/portrait-review.png')

if __name__=='__main__':
 portraits();sheet=Image.new('RGB',(1600,700),'#f7f4ed');draw=ImageDraw.Draw(sheet)
 for i,(label,name) in enumerate(NAMES):
  g,b=build(label,name)
  for row,(clip,t) in enumerate([('Idle',1),('Bond',.8) if label.startswith('S1') else ('Move',.3)]):
   v,n=skin(g,b,clip,t);sheet.paste(render(g,b,v,n,(.65,.15,1),size=(320,320)),(i*320,35+row*330))
  draw.text((i*320+10,10),label+' / idle + '+('bond' if label.startswith('S1') else 'move'),fill='#263d2a')
 sheet.save(ROOT/'assets/previews/Brambleboar/rig-review.png')
