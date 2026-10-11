"""Inspect user GLBs without modifying or installing the Brambleboar models."""
from pathlib import Path
import hashlib, io, json
from PIL import Image, ImageDraw
from mossrat_rig_common import ROOT, load, read
from render_mossrat_rig_review import render

report=[]
sheet=Image.new('RGB',(1080,390),'white')
paths=sorted(Path('C:/Users/wucha/Downloads').glob('Meshy_AI_*10110635*_texture.glb'))
for i,path in enumerate(paths):
    g,b=load(path);p=g['meshes'][0]['primitives'][0]
    v=read(g,b,p['attributes']['POSITION']);n=read(g,b,p['attributes']['NORMAL'])
    textures=[]
    for im in g.get('images',[]):
        view=g['bufferViews'][im['bufferView']];start=view.get('byteOffset',0)
        textures.append(Image.open(io.BytesIO(b[start:start+view['byteLength']])).size)
    tris=sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives'])
    report.append(dict(file=path.name,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),triangles=tris,
                       vertices=len(v),meshes=len(g['meshes']),materials=len(g.get('materials',[])),
                       skins=len(g.get('skins',[])),textures=textures,bytes=path.stat().st_size,
                       boundsMin=v.min(0).tolist(),boundsMax=v.max(0).tolist()))
    picture=render(g,b,v,n,(.65,.35,1),size=(360,360))
    sheet.paste(picture,(i*360,30))
    ImageDraw.Draw(sheet).text((i*360+8,8),f'{path.name.split("_1Star")[0]}: {tris} triangles',fill='black')
out=ROOT/'docs/previews'
sheet.save(out/'HuntSourceModels-2026-10-11.png')
(out/'HuntSourceModels-2026-10-11.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
