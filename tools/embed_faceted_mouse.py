from pathlib import Path
import json,struct,io
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
b=(R/'dist/ReviewModels/MeadowMouse_A_S1_FacetedReview.glb').read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n]);binary=b[28+n:]
def val(i):
 a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];d={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
 return np.frombuffer(binary,dtype={5126:'<f4',5123:'<u2'}[a['componentType']],count=a['count']*d,offset=v.get('byteOffset',0)).reshape(a['count'],d)
v=g['bufferViews'][g['images'][0]['bufferView']];im=Image.open(io.BytesIO(binary[v['byteOffset']:v['byteOffset']+v['byteLength']])).convert('RGB');px=list(im.getdata());runs=[];start=0
while start<len(px):
 end=start+1
 while end<len(px) and end-start<65535 and px[end]==px[start]:end+=1
 runs.append(f'{end-start:04x}'+''.join(f'{x:02x}' for x in px[start]));start=end
s=''.join(runs);decoded=[]
for i in range(0,len(s),10):decoded.extend([tuple(bytes.fromhex(s[i+4:i+10]))]*int(s[i:i+4],16))
assert decoded==px
fmt=lambda a:'{'+','.join(f'{float(x):.8g}' for x in a)+'}'
lines=['-- Generated from approved GLB; flat normals and lossless painted texture.','return {Revision="FacetedA1-v1",GroundY=-1.28,Triangles=747,ImageSize=1024,ImageRLE=[[',s,']],Parts={'];count=0
for node in g['nodes']:
 p=g['meshes'][node['mesh']]['primitives'][0];pos=val(p['attributes']['POSITION']);norm=val(p['attributes']['NORMAL']);uv=val(p['attributes']['TEXCOORD_0']);ids=val(p['indices']).flatten();c=(pos.min(axis=0)+pos.max(axis=0))/2
 lines.append('{Name='+json.dumps(node['name'])+',Center='+fmt(c)+',Vertices={')
 for i in ids:lines.append(fmt([*(pos[i]-c),*norm[i],*uv[i]])+',')
 lines.append('}},');count+=len(ids)//3
assert count==747
lines.append('}}');target=R/'src/client/FacetedMouseData.luau';target.write_text('\n'.join(lines)+'\n',encoding='utf-8');print('EMBED_PASS:747 triangles; lossless 1024 texture;',target.stat().st_size,'bytes')
