"""Prepare deterministic Studio glTF imports; source textures stay untouched."""
from pathlib import Path
import json, shutil, tempfile
from PIL import Image
from rig_neutral_mossrat import ROOT, SOURCES

out=Path(tempfile.gettempdir())/'MossratNeutralImport'
out.mkdir(exist_ok=True)
for name in SOURCES:
    folder=ROOT/'assets/models/MossratNeutral'/name
    data=json.loads((folder/f'{name}.gltf').read_text(encoding='utf8'))
    label=name+'V2'
    data['nodes'][0]['name']=label
    data['buffers'][0]['uri']=label+'.bin'
    shutil.copyfile(folder/f'{name}.bin',out/f'{label}.bin')
    for i,image in enumerate(data['images']):
        target=out/f'{name}Texture{i}.png'
        im=Image.open(folder/f'MossratTexture{i}.png')
        limit=1024 if 'Hunt' in name else 2048
        im.thumbnail((limit,limit),Image.Resampling.LANCZOS)
        im.save(target)
        image['uri']=target.as_posix()
    (out/f'{label}.gltf').write_text(json.dumps(data,indent=2),encoding='utf8')
    print(out/f'{label}.gltf')
