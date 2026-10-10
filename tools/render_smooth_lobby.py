"""Render existing smooth Part geometry; not a Studio lighting screenshot."""
from pathlib import Path
import json,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter
R=Path(__file__).resolve().parents[1];OUT=R/'assets/maps/SmoothLobby'
shapes=json.loads((OUT/'layout.json').read_text())['shapes']
eye=np.array([1,.95,-1.35]);eye/=np.linalg.norm(eye)
right=np.cross(eye,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,eye)
light=np.array([-.4,1,-.7]);light/=np.linalg.norm(light)
def rot(y):return np.array([[math.cos(y),0,math.sin(y)],[0,1,0],[-math.sin(y),0,math.cos(y)]])
def polygons(b):
 size=np.array(b['size']);origin=np.array(b['position']);rotation=rot(b['yaw'])
 def world(v):return origin+rotation@np.array(v)
 if b['shape']=='box':
  vertices=[world(size*np.array(v)/2) for v in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]]
  for ids,normal in [([0,1,5,4],[0,0,-1]),([1,2,6,5],[1,0,0]),([2,3,7,6],[0,0,1]),([3,0,4,7],[-1,0,0]),([4,5,6,7],[0,1,0])]:yield [vertices[i] for i in ids],rotation@normal
 elif b['shape']=='cylinder':
  n=36
  ring=lambda y:[world([math.sin(i*math.tau/n)*size[0]/2,y,math.cos(i*math.tau/n)*size[2]/2]) for i in range(n)]
  low,high=ring(-size[1]/2),ring(size[1]/2)
  yield high,np.array([0,1,0])
  for i in range(n):
   a=(i+.5)*math.tau/n
   yield [low[i],low[(i+1)%n],high[(i+1)%n],high[i]],rotation@np.array([math.sin(a),0,math.cos(a)])
 else:
  n,m=28,16
  def point(i,j):
   lat=-math.pi/2+i*math.pi/m;lon=j*math.tau/n
   return world(size/2*np.array([math.cos(lat)*math.sin(lon),math.sin(lat),math.cos(lat)*math.cos(lon)]))
  for i in range(m):
   for j in range(n):
    points=[point(i,j),point(i,j+1),point(i+1,j+1),point(i+1,j)]
    normal=np.mean(points,axis=0)-origin;normal/=np.linalg.norm(normal)
    yield points,normal
def render(filename,detail=False):
 w,h=1700,1150;im=Image.new('RGBA',(w,h),(10,17,32,255));glow=Image.new('RGBA',(w,h));g=ImageDraw.Draw(glow)
 focus=np.array([0,10,0]) if not detail else np.array([0,12,138])
 scale=3.25 if not detail else 12
 def project(p):
  d=p-focus;return (w/2+float(right@d)*scale,h*.60-float(up@d)*scale)
 visible=[]
 for b in shapes:
  if b['kind']=='roof' or b['name'] in ('Departure','DoorSensor','ManagePoint','ReviewSpawn'):continue
  pos=b['position']
  if detail and (abs(pos[0])>48 or abs(pos[2]-138)>48):continue
  if not detail and b['kind']=='window' and pos[2]<0:continue
  # Outer chamber walls removed for a clear cutaway, as in the earlier review.
  if b['name'] in ('DoorLeft','DoorRight','DoorLintel','DoorPillar','RearWindow','WallColumn'):continue
  visible.append(b)
 faces=[]
 for b in visible:
  for points,normal in polygons(b):
   if normal@eye<=0:continue
   depth=float(eye@np.mean(points,axis=0));depth=depth-10000 if b['kind']=='floor' else depth
   factor=.42+.58*max(0,float(normal@light))
   if b['neon']:factor=1
   color=tuple(min(255,int(c*factor)) for c in b['color'])
   faces.append((depth,[project(p) for p in points],color,b))
 for _,points,color,b in sorted(faces,key=lambda f:f[0]):
  if b['glass']:
   layer=Image.new('RGBA',(w,h));d=ImageDraw.Draw(layer);d.polygon(points,fill=(*color,28),outline=(*color,65));im=Image.alpha_composite(im,layer)
  else:
   d=ImageDraw.Draw(im);d.polygon(points,fill=(*color,255))
  if b['neon']:g.polygon(points,fill=(*color,105))
 im=Image.alpha_composite(im,glow.filter(ImageFilter.GaussianBlur(5)))
 d=ImageDraw.Draw(im);font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',32);small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',24)
 d.rectangle((0,0,w,95),fill=(10,17,32));d.text((35,20),'RODEO PLANETURE | '+('PERSONAL HATCHERY' if detail else 'SMOOTH ORBITAL LOBBY'),font=font,fill=(225,236,251))
 d.text((35,62),'8 personal rooms | 1 egg incubator + 4 empty baby capsules each',font=small,fill=(99,208,235))
 if not detail:
  # Banner text belongs to the XML model; overlay here for readable review labeling.
  px,py=project(np.array([0,70,186]));d.text((px,py),'RODEO\nPLANETURE',font=small,fill=(255,211,97),anchor='mm',align='center')
 d.rectangle((0,h-64,w,h),fill=(10,17,32));d.text((35,h-46),'Geometry preview from the saved Parts. Roof/entrance walls hidden. Not a Studio screenshot.',font=small,fill=(153,172,196))
 im.convert('RGB').save(OUT/filename)
render('SmoothLobbyGeometry.png');render('SmoothHatcheryGeometry.png',True)
print('SMOOTH_GEOMETRY_PREVIEW_RENDERED')
