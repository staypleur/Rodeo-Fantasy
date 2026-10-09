"""Native Roblox Part architecture prototype and preview of those exact Parts.
Review only: no scripts and no changes to the game lobby.
"""
from pathlib import Path
import math,itertools,xml.etree.ElementTree as E
import numpy as np
from PIL import Image,ImageDraw,ImageFont
import argparse
args=argparse.ArgumentParser(description=__doc__)
args.add_argument('--gradient',action='store_true')
gradient=args.parse_args().gradient
R=Path(__file__).resolve().parents[1]
parts=[]
cream=(228,216,181);stone=(193,178,144);teal=(32,111,113);gold=(197,151,64);grass=(116,151,103);wood=(128,95,66)
def block(name,pos,size,color,angle=0,axis='Y'):
 a=math.radians(angle);c,s=math.cos(a),math.sin(a)
 matrix=np.array([[c,0,s],[0,1,0],[-s,0,c]]) if axis=='Y' else np.array([[c,-s,0],[s,c,0],[0,0,1]])
 parts.append((name,np.array(pos,float),np.array(size,float),color,matrix))
def arch(x,z,angle=0):
 # Local arch profile is rotated into the facade plane.
 a=math.radians(angle)
 def put(n,dx,y,size,rot=0):
  center=(x+dx*math.cos(a),y,z-dx*math.sin(a))
  if angle==0:block(n,center,size,cream,rot,'Z')
  else:
   block(n,center,(size[2],size[1],size[0]),cream,-rot,'Z')
 for side in (-1,1):
  dx=side*4.35
  put('Column',dx,3.1,(1.05,5.4,1.45))
  put('ColumnFoot',dx,.65,(1.8,.65,1.9))
  put('Capital',dx,5.7,(1.7,.55,1.9))
 for deg in range(10,180,20):
  t=math.radians(deg)
  if angle==0:put('ArchStone',4.15*math.cos(t),5.65+4.15*math.sin(t),(1.55,1,1.5),deg+90)
  else:
   # Side arcade stones use a composed rotation, retaining a real curved opening.
   center=(x,5.65+4.15*math.sin(t),z-4.15*math.cos(t))
   az=math.radians(deg+90)
   rx=np.array([[1,0,0],[0,math.cos(az),-math.sin(az)],[0,math.sin(az),math.cos(az)]])
   block('ArchStone',center,(1.5,1,1.55),cream)
   parts[-1]=(*parts[-1][:4],rx)
def roof(x,z,w,d,y):
 block('RoofCornice',(x,y,z),(w+1.7,.65,d+1.7),stone)
 for i in range(6):
  block('TealRoofCourse',(x,y+.6+i*.52,z),(w+1.8-i*1.3,.6,d+1.8-i*1.3),teal)
 block('RoofRidge',(x,y+3.65,z),(max(1,w-6),.3,max(1,d-6)),gold)
def tower(x,z):
 block('TowerFoot',(x,.7,z),(10,1.4,10),stone)
 block('Tower',(x,7,z),(8,12,8),cream)
 for side in (-1,1):
  block('TowerPilaster',(x+side*3.7,7,z-4.1),(.75,12,.65),stone)
 block('TowerWindow',(x,9,z-4.15),(2.3,4.3,.35),(61,112,117))
 block('WindowSill',(x,6.8,z-4.4),(3.3,.4,.7),gold)
 block('DomeBase',(x,13.4,z),(9.8,.7,9.8),stone)
 for j in range(7):
  radius=4.7*math.sqrt(max(.07,1-(j/7)**2))
  block('DomeFill',(x,14+j*.65,z),(radius*1.42,.7,radius*1.42),teal)
  for k in range(8):
   a=k*math.pi/4
   block('DomeFacet',(x+math.sin(a)*radius*.7,14+j*.65,z+math.cos(a)*radius*.7),(radius*.65,.7,radius*.85),teal,k*45)
 block('Finial',(x,19.2,z),(.55,1.8,.55),gold)
 block('FinialTop',(x,20.3,z),(1,.55,1),gold)
def tree(x,z):
 block('Planter',(x,.5,z),(4,1,4),stone)
 block('TreeTrunk',(x,3.2,z),(.9,5.5,.9),wood)
 for dx,dy,dz,w in [(0,6,0,4.4),(-1,7,.4,3.4),(1,7,-.3,3.4),(0,8,0,2.7)]:
  block('TreeCanopy',(x+dx,dy,z+dz),(w,2.3,w),(83+int(dy)*3,126+int(dy)*3,75),15*dy)
# Keep the exposed stone lip above the island lawn (top 0), below courtyard .175.
block('Foundation',(0,-.57,1),(83,1.3,99),stone)
block('CourtyardGround',(0,0,1),(79,.35,95),grass)
block('CentralWalk',(0,.24,1),(12,.32,94),cream)
for z in range(-40,44,4):
 for x in (-3,3):block('PavingTile',(x,.45,z),(5.7,.18,3.7),(216,205,173) if z%8 else (200,190,165))
for x in (-35,35):
 block('SideArcadeWalk',(x,.4,2),(8,.4,77),cream)
 for z in range(-30,40,12):arch(x,z,90)
 block('ArcadeEntablature',(x,10.2,2),(3,1.4,81),cream)
 roof(x,2,8,82,11)
for z in (-43,45):
 for x in (-24,-12,0,12,24):arch(x,z)
 block('FacadeBand',(0,10.3,z),(64,1.25,2),cream)
 roof(0,z,65,8,11)
 for x in (-35,35):tower(x,z)
# A taller central gate distinguishes the entrance from the corner arcades.
for x in (-7,7):
 block('GateButtress',(x,6.2,-43),(2.1,12,4),cream)
 block('GateCapital',(x,12.3,-43),(3,.7,5),stone)
block('GateUpperHall',(0,18,-43),(14,11,8),cream)
for x in (-6.5,6.5):block('GatePilaster',(x,18,-47.3),(.8,11,.7),stone)
block('GateWindowFrame',(0,19,-47.4),(4.5,6,.45),gold)
block('GateWindow',(0,19,-47.7),(3.6,5.1,.25),(65,135,144))
block('GateCornice',(0,24,-43),(16,1,10),stone)
for j in range(8):
 radius=6.5*math.sqrt(max(.07,1-(j/8)**2))
 block('GateDomeFill',(0,24.8+j*.7,-43),(radius*1.42,.75,radius*1.42),teal)
 for k in range(8):
  a=k*math.pi/4
  block('GateDomeFacet',(math.sin(a)*radius*.7,24.8+j*.7,-43+math.cos(a)*radius*.7),(radius*.65,.75,radius*.85),teal,k*45)
block('GateFinial',(0,31.1,-43),(.8,2,.8),gold)
# Four separate ranches, two on each side of the center walk.
for idx,(x,z) in enumerate(itertools.product((-19,19),(-19,20)),1):
 block('RanchGrass'+str(idx),(x,.48,z),(22,.3,28),(136,168,112))
 for dx in (-11,11):
  for dz in range(-14,15,7):block('FencePost',(x+dx,1.5,z+dz),(.55,2.4,.55),wood)
  for y in (1.3,2.25):block('FenceRail',(x+dx,y,z),(.3,.3,28),wood)
 for dz in (-14,14):
  for y in (1.3,2.25):block('FenceRail',(x,y,z+dz),(22,.3,.3),wood)
 # Low shade pavilion at the far side leaves room for two roaming creatures.
 block('ShelterPad',(x,.7,z+8),(7,.3,6),stone)
 for dx,dz in itertools.product((-3,3),(-2.5,2.5)):block('ShelterPost',(x+dx,2.8,z+8+dz),(.4,4.2,.4),wood)
 roof(x,z+8,7,6,5)
for x in (-29,29):
 for z in (-34,0,37):tree(x,z)
# Thin garden water channels; central walk and animal pens stay dry.
for x in (-31,31):block('GardenChannel',(x,.45,0),(1.4,.12,76),(74,169,184))
for x in (-6,6):
 for z in (-36,0,38):
  block('FlowerBed',(x,.8,z),(2,1,4),stone)
  for dz in (-1,0,1):block('Flowers',(x,1.4,z+dz),(.75,.4,.6),(190,141,146))
if gradient:
 def blend(low,high,t):
  t=max(0,min(1,t));return tuple(round(a+(b-a)*t) for a,b in zip(low,high))
 colored=[]
 for name,pos,size,color,matrix in parts:
  if color==teal:
   bottom,top=(24.8,29.7) if name.startswith('GateDome') else (14,17.9) if name.startswith('Dome') else (5.6,8.2) if abs(pos[0])==19 else (11.6,14.2)
   color=blend((24,83,99),(83,171,158),(pos[1]-bottom)/(top-bottom))
  elif color==cream:color=blend((205,189,156),(249,236,205),pos[1]/25)
  elif color==stone:color=blend((174,158,128),(221,206,173),pos[1]/25)
  elif color==wood:color=blend((104,76,54),(159,121,83),pos[1]/6)
  colored.append((name,pos,size,color,matrix))
 parts=colored
# Export the same native parts used by the renderer.
root=E.Element('roblox',version='4');model=E.SubElement(root,'Item',{'class':'Model','referent':'LobbyGardenAReview'})
props=E.SubElement(model,'Properties');E.SubElement(props,'string',name='Name').text='LobbyGardenAReview'
for index,(name,pos,size,color,matrix) in enumerate(parts):
 item=E.SubElement(model,'Item',{'class':'Part','referent':f'GardenPart{index}'})
 p=E.SubElement(item,'Properties');E.SubElement(p,'string',name='Name').text=name
 for key,value in [('Anchored','true'),('CanCollide','true'),('CanTouch','false')]:E.SubElement(p,'bool',name=key).text=value
 E.SubElement(p,'token',name='Material').text='272'
 E.SubElement(p,'token',name='TopSurface').text='0';E.SubElement(p,'token',name='BottomSurface').text='0'
 E.SubElement(p,'Color3uint8',name='Color3uint8').text=str(color[0]*65536+color[1]*256+color[2])
 cf=E.SubElement(p,'CoordinateFrame',name='CFrame');dims=E.SubElement(p,'Vector3',name='size')
 for j,a in enumerate('XYZ'):E.SubElement(cf,a).text=str(pos[j]);E.SubElement(dims,a).text=str(size[j])
 for i in range(3):
  for j in range(3):E.SubElement(cf,f'R{i}{j}').text=str(matrix[i,j])
folder=R/'dist/ReviewModels';folder.mkdir(parents=True,exist_ok=True)
E.ElementTree(root).write(folder/('LobbyGardenAGradient.rbxmx' if gradient else 'LobbyGardenAReview.rbxmx'),encoding='utf-8',xml_declaration=True)
# Orthographic render of actual geometry, no generated concept art.
image=Image.new('RGB',(1500,1020),(234,237,226));draw=ImageDraw.Draw(image)
eye=np.array((.72,.85,-1.1));eye/=np.linalg.norm(eye);right=np.cross((0,1,0),eye);right/=np.linalg.norm(right);up=np.cross(eye,right)
vertices=[];faces=[]
faceids=[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]
for name,pos,size,color,matrix in parts:
 corners=np.array(list(itertools.product((-1,1),repeat=3)))*size/2
 world=corners@matrix.T+pos
 for ids in faceids:
  q=world[list(ids)];n=np.cross(q[1]-q[0],q[2]-q[0]);n/=np.linalg.norm(n)
  if n@eye<=0:continue
  shade=.66+.34*max(0,float(n@np.array((-.3,.85,-.4))))
  faces.append((float(q.mean(axis=0)@eye),q,tuple(int(c*shade) for c in color)))
 allp=world
 vertices.extend(allp)
v=np.array(vertices);px=v@right;py=v@up
scale=min(1380/(px.max()-px.min()),870/(py.max()-py.min()));cx=(px.max()+px.min())/2;cy=(py.max()+py.min())/2
pixels=np.full((1020,1500,3),(234,237,226),dtype=np.uint8)
depths=np.full((1020,1500),-np.inf)
for _,q,col in faces:
 for ids in ((0,1,2),(0,2,3)):
  t=q[list(ids)];sx=(t@right-cx)*scale+750;sy=-(t@up-cy)*scale+560;z=t@eye
  x0=max(0,int(sx.min()));x1=min(1499,int(math.ceil(sx.max())))
  y0=max(0,int(sy.min()));y1=min(1019,int(math.ceil(sy.max())))
  if x0>x1 or y0>y1:continue
  denom=(sy[1]-sy[2])*(sx[0]-sx[2])+(sx[2]-sx[1])*(sy[0]-sy[2])
  if abs(denom)<1e-8:continue
  yy,xx=np.mgrid[y0:y1+1,x0:x1+1];xx=xx+.5;yy=yy+.5
  a=((sy[1]-sy[2])*(xx-sx[2])+(sx[2]-sx[1])*(yy-sy[2]))/denom
  b=((sy[2]-sy[0])*(xx-sx[2])+(sx[0]-sx[2])*(yy-sy[2]))/denom
  c=1-a-b;d=a*z[0]+b*z[1]+c*z[2]
  region=depths[y0:y1+1,x0:x1+1];mask=(a>=-1e-6)&(b>=-1e-6)&(c>=-1e-6)&(d>region)
  region[mask]=d[mask];pixels[y0:y1+1,x0:x1+1][mask]=col
image=Image.fromarray(pixels);draw=ImageDraw.Draw(image)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',29);small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',18)
draw.text((30,18),'청록 석조 정원 A · 건물 하나 / 안뜰 목장 4개',font=font,fill=(37,74,68))
subtitle='그라데이션 적용 건축 · 신규 테스트 파일용' if gradient else '게임 미적용 검토안'
draw.text((30,60),f'실제 Roblox Part 모델 {len(parts)}개 · Studio 화면 아님 · {subtitle}',font=small,fill=(73,94,83))
out=R/'assets/previews'/('lobby-garden-a-gradient.png' if gradient else 'lobby-garden-a-native-review.png');out.parent.mkdir(parents=True,exist_ok=True);image.save(out)
assert len([p for p in parts if p[0].startswith('RanchGrass')])==4
for _,pos,size,_,rotation in parts:
 assert np.isfinite(pos).all() and (size>0).all()
 assert np.allclose(rotation.T@rotation,np.eye(3)) and np.isclose(np.linalg.det(rotation),1)
assert not list(root.iter('ProtectedString'))
print(f'LOBBY_NATIVE_REVIEW_PASS: {len(parts)} native Parts / four pens / no scripts / exact-model preview')
print(out)
