"""Render the existing GLB triangles for review; never generates new creature geometry."""
from pathlib import Path
import json, struct, math, argparse
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--model',type=Path,default=ROOT/'dist/CreatureModels/MeadowMouse_A_S1.glb')
parser.add_argument('--output',type=Path,default=ROOT/'assets/previews/meadow-mouse-s1-actual-glb.png')
args=parser.parse_args()
source=args.model
data=source.read_bytes()
assert data[:4]==b'glTF'
length=struct.unpack_from('<I',data,12)[0]
gltf=json.loads(data[20:20+length])
binary=data[28+length:]
def values(index):
 a=gltf['accessors'][index];v=gltf['bufferViews'][a['bufferView']]
 fmt={5126:'f',5125:'I',5123:'H'}[a['componentType']]
 count=a['count']*{'SCALAR':1,'VEC3':3}[a['type']]
 return struct.unpack_from('<'+fmt*count,binary,v.get('byteOffset',0)+a.get('byteOffset',0))
triangles=[]
for node in gltf['nodes']:
 assert not any(k in node for k in ('matrix','translation','rotation','scale')),'review renderer expects exported identity nodes'
 for primitive in gltf['meshes'][node['mesh']]['primitives']:
  raw=values(primitive['attributes']['POSITION']);vertices=list(zip(raw[::3],raw[1::3],raw[2::3]))
  ids=values(primitive['indices'])
  color=gltf['materials'][primitive['material']]['pbrMetallicRoughness']['baseColorFactor'][:3]
  for i in range(0,len(ids),3):triangles.append(([vertices[k] for k in ids[i:i+3]],color))
W,H=1500,600
image=Image.new('RGB',(W,H),(243,240,231));draw=ImageDraw.Draw(image)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
draw.text((25,18),source.stem+' / ACTUAL 3D FILE',font=font,fill=(39,53,47))
draw.text((25,53),'Actual GLB triangles and material colors. Offline geometry render, NOT a Roblox screenshot.',font=small,fill=(95,104,94))
def dot(a,b):return sum(x*y for x,y in zip(a,b))
views=[('FRONT',(0,0,-1)),('FRONT THREE-QUARTER',(.65,.4,-.7)),('HUNT VIEW',(.35,.86,.4))]
for col,(label,eye) in enumerate(views):
 d=tuple(v/math.sqrt(dot(eye,eye)) for v in eye)
 right=(-d[2],0,d[0]);right=tuple(v/math.sqrt(dot(right,right)) for v in right)
 up=(-d[1]*right[2],d[0]*right[2]-d[2]*right[0],d[1]*right[0])
 points=[(dot(v,right),dot(v,up)) for t,_ in triangles for v in t]
 low=[min(p[k] for p in points) for k in range(2)];high=[max(p[k] for p in points) for k in range(2)]
 unit=min(440/(high[0]-low[0]),390/(high[1]-low[1]))
 cx=(low[0]+high[0])/2;cy=(low[1]+high[1])/2
 draw.text((col*500+28,106),label,font=font,fill=(39,53,47))
 polys=[]
 for tri,color in triangles:
  a,b,c=tri;u=[b[k]-a[k] for k in range(3)];v=[c[k]-a[k] for k in range(3)]
  normal=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]);n=math.sqrt(dot(normal,normal))
  shade=.83 if n<1e-9 else .72+.25*abs(dot(normal,(-.4,.8,-.5))/n)
  rgb=tuple(int(255*x*shade) for x in color)
  screen=[(col*500+250+(dot(q,right)-cx)*unit,350-(dot(q,up)-cy)*unit) for q in tri]
  polys.append((sum(dot(q,d) for q in tri)/3,screen,rgb))
 for _,screen,rgb in sorted(polys):draw.polygon(screen,fill=rgb)
draw.text((25,568),f'{len(gltf["nodes"])} mesh nodes / {len(triangles):,} triangles / forward = -Z',font=small,fill=(39,53,47))
output=args.output
image.save(output)
print(output)
