"""Preserve user GLBs and extract exact texture/geometry bytes for Studio import."""
from pathlib import Path
import json,struct,hashlib,copy,shutil
R=Path(__file__).resolve().parents[1]
models={'Planet':'Meshy_AI_SciFi_Ringed_Planet_2_1010133328_texture.glb','Incubator':'Meshy_AI_Empty_Incubator_Pod_4_1010133233_texture.glb','Door':'Meshy_AI_SciFi_Wall_Door_Modul_1010133255_texture.glb','Console':'Meshy_AI_SciFi_Control_Console_1010133306_texture.glb'}
report={}
for key,filename in models.items():
 out=R/'assets/models/LobbyModules'/key;out.mkdir(parents=True,exist_ok=True)
 source=Path('C:/Users/wucha/Downloads')/filename
 if source.exists():shutil.copyfile(source,out/(key+'.glb'))
 b=(out/(key+'.glb')).read_bytes();assert b[:4]==b'glTF'
 chunks={};offset=12
 while offset<len(b):
  length,kind=struct.unpack_from('<II',b,offset);chunks[kind]=b[offset+8:offset+8+length];offset+=8+length
 g=json.loads(chunks[0x4e4f534a]);binary=chunks[0x004e4942]
 (out/(key+'.bin')).write_bytes(binary);g['buffers'][0]['uri']=key+'.bin'
 for i,img in enumerate(g.get('images',[])):
  view=g['bufferViews'][img.pop('bufferView')];start=view.get('byteOffset',0);ext='.png' if img.get('mimeType')=='image/png' else '.jpg'
  name=f'Texture{i}{ext}';(out/name).write_bytes(binary[start:start+view['byteLength']]);img['uri']=name
 (out/(key+'.gltf')).write_text(json.dumps(g,indent=2),encoding='utf-8')
 mesh=copy.deepcopy(g)
 for m in mesh['meshes']:
  for p in m['primitives']:p.pop('material',None)
 for field in ('materials','images','textures','samplers'):mesh.pop(field,None)
 (out/(key+'MeshOnly.gltf')).write_text(json.dumps(mesh,indent=2),encoding='utf-8')
 triangles=sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives'])
 bounds=[{k:g['accessors'][p['attributes']['POSITION']].get(k) for k in ('min','max')} for m in g['meshes'] for p in m['primitives']]
 report[key]={'sha256':hashlib.sha256(b).hexdigest(),'triangles':triangles,'meshCount':len(g['meshes']),'nodes':[n.get('name') for n in g['nodes']],'bounds':bounds}
 print(key,triangles,'triangles',report[key]['meshCount'],'meshes',bounds)
(R/'assets/models/LobbyModules/metadata.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
