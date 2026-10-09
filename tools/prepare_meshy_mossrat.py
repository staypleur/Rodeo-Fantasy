"""Prepare approved Meshy 3k/10k source without changing topology or UVs."""
from pathlib import Path
import sys,json,struct,hashlib,copy,io,shutil
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1]);raw=source.read_bytes()
n=struct.unpack_from('<I',raw,12)[0];original=json.loads(raw[20:20+n]);binary=bytearray(raw[28+n:])
base=R/'assets/meshes/meshy';base.mkdir(parents=True,exist_ok=True)
target=base/('Mossrat_S1_Source10k.glb' if '--detail' in sys.argv else 'Mossrat_S1_Source.glb')
if source.resolve()!=target.resolve():shutil.copyfile(source,target)
# Reorient +Z Meshy front to the game's -Z; no remesh or UV rebake.
for mesh in original['meshes']:
 for p in mesh['primitives']:
  for key in ('POSITION','NORMAL'):
   a=original['accessors'][p['attributes'][key]];v=original['bufferViews'][a['bufferView']]
   assert a['componentType']==5126 and not v.get('byteStride')
   arr=np.frombuffer(binary,dtype='<f4',count=a['count']*3,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,3)
   arr*=np.array([-1,1,-1],dtype='<f4')
   if 'min' in a:a['min']=arr.min(axis=0).tolist();a['max']=arr.max(axis=0).tolist()
triangles=sum(original['accessors'][p['indices']]['count']//3 for m in original['meshes'] for p in m['primitives'])
assert triangles in (3114,10348)
for role in (('Detail',) if '--detail' in sys.argv else ('Hunt',)):
 g=copy.deepcopy(original);parts=[];offset=0;hashes=[]
 for i,v in enumerate(g['bufferViews']):
  ov=original['bufferViews'][i];data=bytes(binary[ov.get('byteOffset',0):ov.get('byteOffset',0)+ov['byteLength']])
  image=next((im for im in g.get('images',[]) if im.get('bufferView')==i),None)
  if image:
   im=Image.open(io.BytesIO(data)).convert('RGB')
   if role=='Hunt':
    im.thumbnail((512,512),Image.Resampling.LANCZOS);buf=io.BytesIO();im.save(buf,format='JPEG',quality=92);data=buf.getvalue();image['mimeType']='image/jpeg'
   hashes.append({'sha256':hashlib.sha256(data).hexdigest(),'size':list(im.size)})
  v['byteOffset']=offset;v['byteLength']=len(data);parts.append(data+b'\0'*((-len(data))%4));offset+=len(parts[-1])
 g['buffers']=[{'byteLength':offset}]
 j=json.dumps(g,separators=(',',':')).encode();j+=b' '*((-len(j))%4);b=b''.join(parts)
 output=base/f'Mossrat_S1_{role}.glb'
 output.write_bytes(struct.pack('<III',0x46546c67,2,28+len(j)+len(b))+struct.pack('<I4s',len(j),b'JSON')+j+struct.pack('<I4s',len(b),b'BIN\0')+b)
 manifest={'source_name':source.name,'source_sha256':hashlib.sha256(raw).hexdigest(),'triangles':triangles,'role':role,'geometry':'Original approved triangles/normals/UVs unchanged; rotate 180 degrees about Y only','images':hashes,'rigged':False,'aura':False,'roblox_height_studs':2.5,'forward':'-Z'}
 output.with_suffix('.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
 print(role,triangles,'triangles',output.stat().st_size,'bytes')
