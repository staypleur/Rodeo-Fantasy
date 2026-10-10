"""Package short ASCII paths; model geometry and approved rig remain unchanged."""
from pathlib import Path
import json,shutil,zipfile
R=Path(__file__).resolve().parents[1]
def build():
 out=R/'dist/ImportRecovery';out.mkdir(parents=True,exist_ok=True)
 for label,folder,file in [('Mossrat','MossratS1UserRig','MossratS1Rigged.gltf'),('Rocket','UserRocket','Rocket.gltf')]:
  source=R/'assets/models'/folder;dest=out/label;dest.mkdir(exist_ok=True)
  g=json.loads((source/file).read_text());g.pop('animations',None)
  for i,buf in enumerate(g['buffers']):
   old=source/buf['uri'];buf['uri']=f'Data{i}.bin';shutil.copyfile(old,dest/buf['uri'])
  for i,img in enumerate(g['images']):
   old=source/img['uri'];img['uri']=f'Texture{i}.png';shutil.copyfile(old,dest/img['uri'])
  (dest/(label+'.gltf')).write_text(json.dumps(g,indent=2)+'\n',encoding='utf-8')
  # For manual importer material-path overrides (packed originals stay linked in glTF).
  for suffix in ('Metalness','Roughness'):
   shutil.copyfile(source/(label+suffix+'.png'),dest/(suffix+'.png'))
  original=json.loads((source/file).read_text())
  for key in ('meshes','skins','nodes','accessors','bufferViews'):
   assert g.get(key)==original.get(key),label+' '+key
  for i,buf in enumerate(g['buffers']):assert (dest/buf['uri']).read_bytes()==(source/original['buffers'][i]['uri']).read_bytes()
  for i,img in enumerate(g['images']):assert (dest/img['uri']).read_bytes()==(source/original['images'][i]['uri']).read_bytes()
 archive=out/'RodeoImport.zip'
 with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=1) as z:
  for folder in ('Mossrat','Rocket'):
   for path in sorted((out/folder).iterdir()):z.write(path,path.relative_to(out).as_posix())
 print('IMPORT_RECOVERY_PREPARED',archive.stat().st_size,'bytes; exact geometry/skin/textures, model-only import, ASCII extraction recommended')
 return archive
if __name__=='__main__':build()
