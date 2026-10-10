"""Uninstalled design review. XML and images use the same generated block list."""
from pathlib import Path
import math,json,xml.etree.ElementTree as E
from PIL import Image,ImageDraw,ImageFont
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1]
OUT=R/'assets/maps/LobbyReview';OUT.mkdir(parents=True,exist_ok=True)
blocks=[];serial=0
root=E.Element('roblox',version='4')
def node(parent,kind,name):
 global serial
 serial+=1;i=E.SubElement(parent,'Item',{'class':kind,'referent':f'RBXLobbyReview{serial}'})
 p=E.SubElement(i,'Properties');E.SubElement(p,'string',name='Name').text=name;return i
def prop(i,tag,name,text):
 e=E.SubElement(i.find('Properties'),tag,name=name);e.text=str(text);return e
def composite(i,tag,name,values):
 e=prop(i,tag,name,'')
 for k,v in values.items():E.SubElement(e,k).text=str(v)
def snap(v):return math.floor(v/4+.5)*4
model=node(root,'Model','RodeoLobbyDesignReview')
WHITE=(181,195,213);DARK=(26,36,60);MID=(69,85,112);BLUE=(65,192,255);GOLD=(255,194,65)
def brick(parent,name,pos,size,color=WHITE,kind='architecture',glass=False,neon=False,hidden=False):
 assert all(v%4==0 for v in (pos[0],pos[2]))
 p=node(parent,'Part',name)
 composite(p,'Vector3','size',dict(zip('XYZ',size)))
 composite(p,'CoordinateFrame','CFrame',dict(zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],[6000+pos[0],pos[1],pos[2],1,0,0,0,1,0,0,0,1])))
 composite(p,'Color3','Color',dict(zip('RGB',[v/255 for v in color])))
 for key,value in [('Anchored','true'),('CanCollide',str(not(glass or hidden or neon)).lower()),('CanTouch','false'),('CanQuery',str(not hidden).lower()),('CastShadow',str(not(glass or neon or hidden)).lower())]:prop(p,'bool',key,value)
 prop(p,'float','Transparency',1 if hidden else .76 if glass else 0)
 prop(p,'token','Material',1568 if glass else 288 if neon else 256)
 prop(p,'token','shape',1)
 for face in ('TopSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'):prop(p,'token',face,3)
 prop(p,'token','BottomSurface',4)
 blocks.append(dict(name=name,position=pos,size=size,color=color,kind=kind,glass=glass,neon=neon,hidden=hidden))
 return p
def sign(parent,name,pos,size,text,color=BLUE):
 p=brick(parent,name,pos,size,DARK)
 gui=node(p,'SurfaceGui','Sign');prop(gui,'token','Face',5);prop(gui,'float','PixelsPerStud',24)
 label=node(gui,'TextLabel','Text');prop(label,'string','Text',text);prop(label,'float','BackgroundTransparency',1);prop(label,'bool','TextScaled','true')
 composite(label,'Color3','TextColor3',dict(zip('RGB',[v/255 for v in color])))
 e=prop(label,'UDim2','Size','')
 for key,value in [('XS',1),('XO',0),('YS',1),('YO',0)]:E.SubElement(e,key).text=str(value)
 return p
floor=node(model,'Model','Deck')
for x in range(-224,225,32):
 for z in range(-224,225,32):
  if max(abs(x),abs(z))<=224 and abs(x)+abs(z)<=352:
   c=(88,102,128) if (x//32+z//32)%2 else (103,118,143)
   brick(floor,'DeckTile',[x,0,z],[32,4,32],c,'floor')
# Segmented luminous guide ring, wide walkways and low central dock.
airport=node(model,'Model','Airport')
for layer,radius in enumerate([40,32,24]):
 brick(airport,'DockLayer',[0,3+layer*2,0],[radius*2,2,radius*2],MID,'dock')
for n in range(64):
 a=n*math.tau/64
 for radius,color in [(48,GOLD),(112,BLUE),(216,BLUE)]:
  brick(floor,'GuideLight',[snap(math.cos(a)*radius),2.2,snap(math.sin(a)*radius)],[4,1,4],color,'guide',neon=True)
brick(airport,'Departure',[0,4,-44],[8,4,8],BLUE,hidden=True)
airship=node(airport,'Model','Airship') # compatibility anchor for the existing departure system
rocket=node(airport,'Model','Rocket')
for y in range(10,58,4):
 for x,z,w,d in [(0,0,16,24),(-12,0,8,16),(12,0,8,16)]:
  brick(rocket,'Hull',[x,y,z],[w,4,d],(238,238,222) if y%12 else (230,66,65),'rocket')
for layer in range(7):
 width=max(4,28-layer*4);brick(rocket,'Nose',[0,60+layer*4,0],[width,4,width],(235,53,62),'rocket')
for x,z in [(-20,0),(20,0),(0,20),(0,-20)]:
 for y in range(12,34,4):
  w=4 if y>24 else 8
  brick(rocket,'Fin',[x,y,z],[w,4,w],(226,57,70),'rocket')
brick(rocket,'WindowFrame',[0,44,-16],[16,16,4],GOLD,'rocket')
brick(rocket,'Window',[0,44,-20],[8,8,4],BLUE,'rocket',neon=True)
sign(airport,'DepartureSign',[0,8,-32],[24,8,4],'GREEN STAR')
plots=node(model,'Folder','Plots')
accents=[(255,97,94),(80,157,255),(130,221,106),(178,117,255),(255,209,76),(63,223,238),(255,133,201),(255,161,65)]
for index in range(8):
 a=-math.pi/2+index*math.tau/8;cx,cz=snap(math.cos(a)*168),snap(math.sin(a)*168)
 start=len(blocks)
 # Orthogonal room geometry remains aligned to the global four-stud grid.
 room=node(plots,'Model',f'Plot_{index+1}');accent=accents[index]
 brick(room,'RoomBase',[cx,3,cz],[80,2,80],MID,'room')
 for dx in [-40,40]:brick(room,'SideWall',[cx+dx,20,cz],[4,32,80],WHITE,'roomwall')
 brick(room,'RearWall',[cx,20,cz+40],[80,32,4],WHITE,'roomwall')
 for dx in [-28,28]:brick(room,'FrontWall',[cx+dx,20,cz-40],[24,32,4],WHITE,'roomwall')
 for dx in [-8,8]:brick(room,'DoorLeft' if dx<0 else 'DoorRight',[cx+dx,14,cz-40],[16,20,4],MID,'door')
 brick(room,'DoorSensor',[cx,8,cz-48],[24,12,16],hidden=True)
 brick(room,'ManagePoint',[cx,4,cz-20],[8,4,8],hidden=True)
 sign(room,'OwnerBoard',[cx,34,cz-40],[32,8,4],f'{index+1} | YOUR HATCHERY',accent)
 # Roof is included in Studio but omitted from the cutaway review images.
 brick(room,'RoomRoof',[cx,40,cz],[80,4,80],WHITE,'roof')
 pens=node(room,'Folder','Pens');pen=node(pens,'Model','Pen_1')
 brick(pen,'PenGrass',[cx,6,cz+4],[24,4,24],DARK,'hatchery')
 for dx in [-12,12]:
  brick(pen,'IncubatorSupport',[cx+dx,18,cz+4],[4,24,24],WHITE,'hatchery')
  brick(pen,'StatusLight',[cx+dx,18,cz-8],[4,16,2],accent,'hatchery',neon=True)
 for y in [8,30]:
  brick(pen,'IncubatorCap',[cx,y,cz+4],[28,4,28],MID,'hatchery')
  brick(pen,'RimLight',[cx,y+2.2,cz-8],[20,1,2],accent,'hatchery',neon=True)
 brick(pen,'IncubatorGlass',[cx,19,cz-8],[20,20,2],accent,'glass',glass=True)
 # Layered machinery and display plinth; the egg itself is supplied by inventory.
 for height,width in [(5,32),(7,28),(31,32),(33,28)]:
  for dx,dz,sx,sz in [(-width//2,0,4,width),(width//2,0,4,width),(0,-width//2,width,4),(0,width//2,width,4)]:
   brick(pen,'SteppedCasing',[cx+snap(dx),height,cz+4+snap(dz)],[sx,2,sz],WHITE,'hatchery')
 for dx in [-12,12]:
  for y in [12,24]:brick(pen,'CasingJoint',[cx+dx,y,cz-12],[8,4,4],MID,'hatchery')
 brick(pen,'ControlPanel',[cx-20,12,cz-12],[12,8,4],DARK,'hatchery')
 brick(pen,'ControlScreen',[cx-20,12,cz-16],[8,4,2],BLUE,'hatchery',neon=True)
 sign(room,'EggStatus',[cx-24,22,cz],[12,12,4],'EGG\n01',accent)
 capsules=node(room,'Folder','BabyCapsules')
 for slot,(dx,dz) in enumerate([(-28,12),(-28,24),(28,12),(28,24)],1):
  cap=node(capsules,'Model',f'Capsule_{slot}')
  for y in [8,24]:brick(cap,'Cap',[cx+dx,y,cz+dz],[12,4,12],MID,'capsule')
  brick(cap,'Back',[cx+dx,16,cz+dz+4],[12,12,4],WHITE,'capsule')
  brick(cap,'Glass',[cx+dx,16,cz+dz-4],[12,12,2],accent,'glass',glass=True)
  brick(cap,'CapLight',[cx+dx,26.2,cz+dz],[8,1,8],accent,'capsule',neon=True)
  for side in [-8,8]:brick(cap,'Rail',[cx+dx+side,16,cz+dz],[4,16,12],WHITE,'capsule')
  brick(cap,'EmptySocket',[cx+dx,10.2,cz+dz],[8,1,8],accent,'capsule',neon=True)
 for dx in [-32,32]:
  for dz in [-24]:
   brick(room,'Planter',[cx+dx,6,cz+dz],[8,4,8],WHITE,'plant')
   brick(room,'Stem',[cx+dx,12,cz+dz],[4,8,4],(107,83,59),'plant')
   for y,w in [(14,12),(18,8)]:brick(room,'LeafPlate',[cx+dx,y,cz+dz],[w,4,w],(90,140+y,99),'plant')
 # Quarter-turn rooms towards the plaza. Their furniture stays on the four-stud grid.
 angle=round(math.atan2(cx,cz)/(math.pi/2))*math.pi/2;c,s=round(math.cos(angle)),round(math.sin(angle))
 roomparts=[i for i in room.iter('Item') if i.get('class')=='Part']
 assert len(roomparts)==len(blocks)-start
 for b,p in zip(blocks[start:],roomparts):
  x,y,z=b['position'];dx,dz=x-cx,z-cz
  x,z=cx+dx*c+dz*s,cz-dx*s+dz*c;b['position']=[x,y,z]
  cf=p.find("Properties/CoordinateFrame[@name='CFrame']")
  for key,value in [('X',6000+x),('Z',z),('R00',c),('R02',s),('R20',-s),('R22',c)]:cf.find(key).text=str(value)
  if s:b['size']=[b['size'][2],b['size'][1],b['size'][0]]
 # A path from each room towards the dock, clear of capsule furniture.
 for t in range(8):
  r=56+t*8;brick(floor,'RadialPath',[snap(math.cos(a)*r),2.4,snap(math.sin(a)*r)],[8,1,8],(131,155,184),'path')
shell=node(model,'Model','ShipShell')
for x,z,sx,sz in [(0,240,320,8),(0,-240,320,8),(240,0,8,320),(-240,0,8,320)]:
 brick(shell,'WindowSpace',[x,48,z],[sx,64,sz],(16,23,54),'space')
 brick(shell,'Sill',[x,12,z],[sx,8,sz],WHITE,'shell')
 brick(shell,'TopBeam',[x,84,z],[sx,8,sz],WHITE,'shell')
for x,z in [(x,z) for x in [-160,-80,0,80,160] for z in [-240,240]]+[(x,z) for x in [-240,240] for z in [-160,-80,0,80,160]]:
 brick(shell,'Column',[x,48,z],[8,80,8],WHITE,'shell')
 brick(shell,'ColumnLight',[x,40,z-4],[4,12,2],GOLD,'shell',neon=True)
for signx in [-1,1]:
 for signz in [-1,1]:
  for x,z in [(176,224),(192,208),(208,192),(224,176)]:
   brick(shell,'CornerHull',[signx*x,48,signz*z],[32,80,32],MID,'shell')
# Low-cost outer space diorama outside windows (no external texture dependency).
space=node(model,'Model','SpaceDiorama')
for n in range(64):
 a=n*math.tau/64;r=248
 brick(space,'Star',[snap(math.cos(a)*r),24+(n*17)%52,snap(math.sin(a)*r)],[2,2,2],(177,211,255),'star',neon=True)
for cx,cz,color in [(80,248,(107,146,239)),(-112,248,(182,119,230)),(248,48,(112,197,169))]:
 for y in range(32,72,4):
  width=snap(math.sqrt(max(0,20**2-(y-52)**2))*2)
  if width:brick(space,'PlanetLayer',[cx,y,cz],[max(4,width),4,8],color,'planet')
roof=node(model,'Model','Roof')
for x in range(-224,225,32):
 for z in range(-224,225,32):
  if abs(x)+abs(z)<=352:brick(roof,'Ceiling',[x,96,z],[32,4,32],DARK,'roof')
amenities=node(model,'Model','Amenities')
for name,x,z,text in [('ShopA',-64,-216,'SHOP 01'),('ShopB',64,-216,'SHOP 02'),('DistanceRank',-216,-64,'DISTANCE'),('JournalRank',-216,64,'JOURNAL'),('Roulette',216,-64,'ROULETTE'),('BattlePass',216,64,'BATTLE PASS')]:
 booth=node(amenities,'Model',name);brick(booth,'Base',[x,4,z],[32,4,16],MID)
 sign(booth,'Board',[x,20,z],[32,20,4],text)
 for dx in [-16,16]:brick(booth,'FrameLight',[x+dx,20,z],[4,20,4],BLUE,neon=True)
sign(shell,'GameTitle',[0,72,232],[64,16,4],'RODEO FANTASY',GOLD)
assert_unique_ids(root)
E.ElementTree(root).write(OUT/'LobbyDesignReview.rbxmx',encoding='utf-8',xml_declaration=True)
(OUT/'layout.json').write_text(json.dumps({'reviewOnly':True,'rooms':8,'incubatorsPerRoom':1,'babyCapsulesPerRoom':4,'blocks':blocks},indent=2),encoding='utf-8')
# Geometry review renderer: block colors and shapes, not Studio lighting/PBR.
def render(filename,room=False):
 w,h=1800,1300;im=Image.new('RGB',(w,h),(12,18,34));d=ImageDraw.Draw(im)
 focus=(0,0) if not room else (0,168)
 scale=2.6 if not room else 9
 def project(p):
  x,y,z=p;x-=focus[0];z=-(z-focus[1])
  return (w/2+(x-z)*.72*scale,h*.56+(x+z)*.32*scale-y*.88*scale)
 visible=[b for b in blocks if not b['hidden'] and b['kind']!='roof']
 if room:visible=[b for b in visible if abs(b['position'][0])<44 and abs(b['position'][2]-168)<44 and b['kind'] not in ('roomwall','door')]
 else:visible=[b for b in visible if b['kind'] not in ('roomwall','door') and (b['kind'] not in ('space','shell','star','planet') or b['position'][2]>=200 or b['position'][0]<-200)]
 for b in sorted(visible,key=lambda b:b['position'][0]-b['position'][2]+b['position'][1]*.5):
  x,y,z=b['position'];sx,sy,sz=b['size'];c=b['color']
  points=[(x+dx*sx/2,y+dy*sy/2,z+dz*sz/2) for dx,dy,dz in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]]
  pp=[project(p) for p in points]
  for face,factor in [([2,3,7,6],.65),([1,2,6,5],.8),([4,5,6,7],1.04)]:
   col=tuple(min(255,int(v*factor)) for v in c)
   if b['glass']:col=tuple(int(v*.45+40) for v in col)
   d.polygon([pp[n] for n in face],fill=col,outline=tuple(max(0,v-20) for v in col))
  if not b['glass'] and not b['neon'] and sy>=2 and sx<=32 and sz<=32:
   for dx in range(int(-sx/2+2),int(sx/2),4):
    for dz in range(int(-sz/2+2),int(sz/2),4):
     px,py=project((x+dx,y+sy/2+.15,z+dz));rr=max(1,scale*.6)
     d.ellipse((px-rr,py-rr*.4,px+rr,py+rr*.4),fill=tuple(min(255,v+20) for v in c))
 font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',30)
 d.rectangle((0,0,w,110),fill=(12,18,34));d.text((40,22),'RODEO FANTASY | '+('PERSONAL HATCHERY' if room else 'ORBITAL LOBBY'),font=font,fill=(190,220,255))
 d.text((40,64),'8 rooms / 1 egg incubator + 4 empty baby capsules per room',font=font,fill=(255,202,94))
 d.rectangle((0,h-72,w,h),fill=(12,18,34));d.text((40,h-54),'Actual block layout cutaway. Roof/walls hidden for review. Not a Studio render.',font=font,fill=(172,185,212))
 im.save(OUT/filename)
render('LobbyGeometryReview.png');render('HatcheryGeometryReview.png',True)
print('LOBBY_REVIEW_BUILT',len(blocks),'parts; not installed')
