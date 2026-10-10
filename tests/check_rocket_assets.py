"""Validate import resources and compare to the user GLB when it is available."""
from pathlib import Path
import json,struct,hashlib
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'assets/models/UserRocket'
doc=json.loads((folder/'Rocket.gltf').read_text(encoding='utf-8'))
report=json.loads((folder/'metadata.json').read_text(encoding='utf-8'))
binary=(folder/doc['buffers'][0]['uri']).read_bytes()
assert len(binary)==doc['buffers'][0]['byteLength']
for view in doc['bufferViews']:
 assert view.get('buffer',0)==0 and view.get('byteOffset',0)+view['byteLength']<=len(binary)
for image in doc['images']:
 assert (folder/image['uri']).read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
for accessor in doc['accessors']:
 assert 0<=accessor['bufferView']<len(doc['bufferViews'])
assert sum(doc['accessors'][p['indices']]['count']//3 for mesh in doc['meshes'] for p in mesh['primitives'])==report['triangles']
original=Path('C:/Users/wucha/Downloads')/report['sourceFilename']
if original.exists():
 raw=original.read_bytes();assert hashlib.sha256(raw).hexdigest()==report['sha256']
 offset=12;source=None;source_binary=None
 while offset<len(raw):
  length,kind=struct.unpack_from('<II',raw,offset);chunk=raw[offset+8:offset+8+length];offset+=8+length
  if kind==0x4e4f534a: source=json.loads(chunk)
  elif kind==0x004e4942: source_binary=chunk
 assert source['meshes']==doc['meshes'] and source['nodes']==doc['nodes'] and source['materials']==doc['materials']
 assert source['textures']==doc['textures'] and source['accessors']==doc['accessors']
 assert source_binary[:len(binary)]==binary
 for a,b in zip(source['images'],doc['images']):
  view=source['bufferViews'][a['bufferView']];start=view.get('byteOffset',0)
  assert (folder/b['uri']).read_bytes()==source_binary[start:start+view['byteLength']]
print(f"ROCKET_ASSETS_PASS: valid glTF resources; {report['triangles']} triangles; original mesh/material/UV/normal/PNG bytes preserved")
