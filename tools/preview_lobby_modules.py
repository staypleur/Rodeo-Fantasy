"""Orthographic GLB geometry inspection, not a Roblox lighting screenshot."""
from pathlib import Path
import json,struct
import numpy as np
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1]
def read(key):
 p=R/'assets/models/LobbyModules'/key;g=json.loads((p/(key+'.gltf')).read_text());b=(p/(key+'.bin')).read_bytes()
 def a(i):
  v=g['accessors'][i];view=g['bufferViews'][v['bufferView']];t={5126:'<f4',5123:'<u2',5125:'<u4'}[v['componentType']];cols={'SCALAR':1,'VEC2':2,'VEC3':3}[v['type']]
  return np.frombuffer(b,dtype=t,count=v['count']*cols,offset=view.get('byteOffset',0)+v.get('byteOffset',0)).reshape(v['count'],cols)
 prim=g['meshes'][0]['primitives'][0];verts=a(prim['attributes']['POSITION']);faces=a(prim['indices']).reshape(-1,3);uv=a(prim['attributes']['TEXCOORD_0']);tex=np.array(Image.open(p/g['images'][0]['uri']).convert('RGB'))
 return g,b,verts,faces,uv,tex
def render(key,reverse=False):
 g,b,v,f,uv,tex=read(key);lo=v.min(0);hi=v.max(0)
 im=Image.new('RGB',(700,600),(225,231,242));d=ImageDraw.Draw(im)
 scale=min(620/(hi[0]-lo[0]),520/(hi[1]-lo[1]));center=(lo+hi)/2
 for face in sorted(f,key=lambda tri:v[tri,2].mean(),reverse=reverse):
  points=v[face];normal=np.cross(points[1]-points[0],points[2]-points[0]);length=np.linalg.norm(normal)
  if not length:continue
  color=tex[min(tex.shape[0]-1,max(0,int(uv[face,1].mean()*tex.shape[0]))),min(tex.shape[1]-1,max(0,int(uv[face,0].mean()*tex.shape[1])))]
  shade=.62+.38*abs(normal[2]/length);color=tuple((color*shade).astype(int))
  d.polygon([(350+(p[0]-center[0])*scale,570-(p[1]-lo[1])*scale) for p in points],fill=color)
 d.text((10,10),key+' geometry inspection',fill='black');return im
if __name__=='__main__':
 for key in ['Door','Incubator','Console','Planet']:
  render(key).save(R/'assets/models/LobbyModules'/key/(key+'Preview.png'))
