"""Record only model metadata; preserve the user GLB and embedded textures."""
from pathlib import Path
import argparse,hashlib,struct,json,io
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('--model',type=Path,required=True);p.add_argument('--export',action='store_true');args=p.parse_args()
raw=args.model.read_bytes();assert raw[:4]==b'glTF'
offset=12;doc=None;binary=None
while offset<len(raw):
 size,kind=struct.unpack_from('<II',raw,offset);chunk=raw[offset+8:offset+8+size];offset+=8+size
 if kind==0x4e4f534a: doc=json.loads(chunk)
 elif kind==0x004e4942: binary=chunk
triangles=sum(doc['accessors'][primitive['indices']]['count']//3 for mesh in doc['meshes'] for primitive in mesh['primitives'])
textures=[]
for image in doc.get('images',[]):
 view=doc['bufferViews'][image['bufferView']];start=view.get('byteOffset',0)
 pixels=Image.open(io.BytesIO(binary[start:start+view['byteLength']]))
 textures.append(dict(name=image.get('name',''),width=pixels.width,height=pixels.height,encodedBytes=view['byteLength'],uncompressedRGBABytes=pixels.width*pixels.height*4))
position=doc['accessors'][doc['meshes'][0]['primitives'][0]['attributes']['POSITION']]
report=dict(sourceFilename=args.model.name,sha256=hashlib.sha256(raw).hexdigest(),fileBytes=len(raw),triangles=triangles,
 vertices=position['count'],boundsMin=position['min'],boundsMax=position['max'],heightModelUnits=position['max'][1]-position['min'][1],targetHeightStuds=18/.28,
 textures=textures,hasSkin=bool(doc.get('skins')),hasAnimation=bool(doc.get('animations')),
 importedIntoStudio=False,mobilePerformanceMeasured=False,sourceModified=False)
out=Path(__file__).resolve().parents[1]/'assets/models/UserRocket/metadata.json';out.parent.mkdir(parents=True,exist_ok=True)
if args.export:
 # Unpack binary glTF to the officially documented .gltf import format.
 # Copy encoded PNG bytes, geometry, normals, UVs and materials unchanged.
 assert len(doc['buffers'])==1
 image_views={image['bufferView'] for image in doc['images']}
 kept=[i for i in range(len(doc['bufferViews'])) if i not in image_views]
 mapping={old:new for new,old in enumerate(kept)}
 views=[doc['bufferViews'][i] for i in kept]
 geometry_end=max(v.get('byteOffset',0)+v['byteLength'] for v in views)
 geometry=binary[:geometry_end]
 for accessor in doc['accessors']:
  assert 'sparse' not in accessor
  accessor['bufferView']=mapping[accessor['bufferView']]
 for index,image in enumerate(doc['images']):
  view=doc['bufferViews'][image.pop('bufferView')];start=view.get('byteOffset',0)
  filename=f'RocketTexture{index}.png'
  (out.parent/filename).write_bytes(binary[start:start+view['byteLength']])
  image['uri']=filename
 doc['bufferViews']=views
 doc['buffers']=[dict(uri='Rocket.bin',byteLength=len(geometry))]
 (out.parent/'Rocket.bin').write_bytes(geometry)
 (out.parent/'Rocket.gltf').write_text(json.dumps(doc,indent=2)+'\n',encoding='utf-8')
 report['preparedImportFiles']=['Rocket.gltf','Rocket.bin','RocketTexture0.png','RocketTexture1.png']
 report['geometryAndTextureBytesPreserved']=True
out.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
