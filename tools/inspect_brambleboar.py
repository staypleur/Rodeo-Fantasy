"""Audit user assets and render their actual source meshes before rigging."""
from pathlib import Path
import io,json,hashlib
import numpy as np
from PIL import Image,ImageDraw
from mossrat_rig_common import ROOT,load,read
from render_mossrat_rig_review import render

SOURCE=Path('C:/Users/wucha/OneDrive/바탕 화면/사진/로데오 게임개발/브램블보어')
NAMES=[('S1_A','Meshy_AI_Brambleboar_1Star_Str_1012153354_texture.glb'),('S1_B','Meshy_AI_Brambleboar_1Star_Str_1012153406_texture.glb'),('S3','Meshy_AI_Brambleboar_3Star_Rem_1012153417_texture.glb'),('S6','Meshy_AI_Brambleboar_6Star_Rem_1012153430_texture.glb'),('S9','Meshy_AI_Brambleboar_9Star_Rem_1012153441_texture.glb')]
def main():
 out=ROOT/'assets/previews/Brambleboar';out.mkdir(parents=True,exist_ok=True)
 reports=[];sheet=Image.new('RGB',(1600,700),'#f7f4ed');draw=ImageDraw.Draw(sheet)
 for i,(label,name) in enumerate(NAMES):
  path=SOURCE/name;g,b=load(path);p=g['meshes'][0]['primitives'][0]
  v=read(g,b,p['attributes']['POSITION']);n=read(g,b,p['attributes']['NORMAL']);tri=read(g,b,p['indices']).size//3
  textures=[]
  for im in g.get('images',[]):
   view=g['bufferViews'][im['bufferView']];data=b[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
   image=Image.open(io.BytesIO(data));textures.append(dict(size=image.size,encodedBytes=len(data)))
  report=dict(label=label,file=name,bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),triangles=tri,vertices=len(v),bounds=[v.min(0).tolist(),v.max(0).tolist()],meshes=len(g['meshes']),primitives=len(g['meshes'][0]['primitives']),skins=len(g.get('skins',[])),animations=len(g.get('animations',[])),textures=textures)
  reports.append(report);print(json.dumps(report,ensure_ascii=False))
  for row,eye in enumerate([(0,.08,1),(1,.15,.4)]):sheet.paste(render(g,b,v,n,eye,size=(320,320)),(i*320,35+row*330))
  draw.text((i*320+12,10),f'{label}: {tri:,} triangles',fill='#263d2a')
 (out/'source-audit.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 sheet.save(out/'source-models.png')
if __name__=='__main__':main()
