"""Offline native-part geometry preview; not a Roblox screenshot or concept-image edit."""
from PIL import Image,ImageDraw,ImageFont
from meadow_models import components,SPECIES,STAGES,BODY_SCALES
from pathlib import Path
import math
W,H=1920,1900
im=Image.new('RGB',(W,H),(235,239,232));d=ImageDraw.Draw(im)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
right=(.8,0,.6);up=(-.24,.9165,.32);depth=(.55,.4,-.733)
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def rotation(v,angles):
 x,y,z=v;a,b,c=map(math.radians,angles)
 x,y=x*math.cos(c)-y*math.sin(c),x*math.sin(c)+y*math.cos(c)
 x,z=x*math.cos(b)+z*math.sin(b),-x*math.sin(b)+z*math.cos(b)
 y,z=y*math.cos(a)-z*math.sin(a),y*math.sin(a)+z*math.cos(a)
 return x,y,z
for row,id in enumerate(SPECIES):
 for col,star in enumerate(STAGES):
  x0,y0=col*480,row*380
  d.rounded_rectangle((x0+8,y0+8,x0+472,y0+372),20,fill=(250,250,243))
  d.text((x0+24,y0+19),id,fill=(42,65,52),font=font)
  d.text((x0+24,y0+52),f'A / {star} STAR',fill=(102,118,93),font=small)
  parts=components(id,star);polys=[]
  unit=17 if id=='RockElephant' else 20 if id=='Weedcrow' else 26
  unit/=BODY_SCALES[id] # overview fits the growth stages; gameplay sizes remain distinct
  center=222 if id in ('RockElephant','GrassBoar','TreeWolf') else 235
  for p in parts:
   sx,sy,sz=(a/2 for a in p['size'])
   vertices=[];faces=[]
   if p['shape']=='Ball':
    for a in range(9):
     lat=-math.pi/2+math.pi*a/8
     for b in range(13):
      lon=math.tau*b/12
      vertices.append((sx*math.cos(lat)*math.cos(lon),sy*math.sin(lat),sz*math.cos(lat)*math.sin(lon)))
    for a in range(8):
     for b in range(12): faces.append((a*13+b,a*13+b+1,(a+1)*13+b+1,(a+1)*13+b))
   else:
    vertices=[(x*sx,y*sy,z*sz) for x,y,z in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
    faces=[(0,1,2,3),(5,4,7,6),(4,0,3,7),(1,5,6,2),(3,2,6,7),(4,5,1,0)]
   world=[tuple(v+k for v,k in zip(rotation(q,p['rotation']),p['position'])) for q in vertices]
   for face in faces:
    points=[world[k] for k in face];a,b,c=points[:3]
    u=tuple(b[k]-a[k] for k in range(3));v=tuple(c[k]-a[k] for k in range(3))
    normal=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]);length=math.sqrt(dot(normal,normal))
    shade=.85 if length<1e-9 else .77+.22*abs(dot(normal,(-.35,.85,-.4))/length)
    color=tuple(min(255,int(k*shade)) for k in p['color'])
    screen=[(x0+235+unit*dot(q,right),y0+center-unit*dot(q,up)) for q in points]
    polys.append((sum(dot(q,depth) for q in points)/len(points),screen,color))
  d.ellipse((x0+125,y0+302,x0+347,y0+327),fill=(220,225,209))
  for _,points,color in sorted(polys,key=lambda q:q[0]):d.polygon(points,fill=color)
Path('assets/previews').mkdir(exist_ok=True)
im.save('assets/previews/meadow-approved-a-models.png')
print('Saved native-part geometry preview')
