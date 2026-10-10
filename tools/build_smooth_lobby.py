"""Smooth lobby redesign draft. Separate from the rejected, installed Stud map."""
from pathlib import Path
import math,json,xml.etree.ElementTree as E
import numpy as np
from build_project import node,prop,composite,part
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1];OUT=R/'assets/maps/SmoothLobby';OUT.mkdir(parents=True,exist_ok=True)
root=E.Element('roblox',version='4');lobby=node(root,'Model','SmoothLobbyDesignDraft')
WHITE=(220,229,241);NAVY=(25,35,57);GREY=(89,109,139);CYAN=(61,205,247);GOLD=(255,205,91)
shapes=[]
def rot(y):return np.array([[math.cos(y),0,math.sin(y)],[0,1,0],[-math.sin(y),0,math.cos(y)]])
def create(parent,name,pos,size,color=WHITE,shape='box',yaw=0,glass=False,neon=False,kind='detail'):
 p=part(parent,name,[6000+pos[0],pos[1],pos[2]],size,color)
 for face in ('TopSurface','BottomSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'):prop(p,'token',face,0)
 prop(p,'token','Material',1568 if glass else 288 if neon else 272)
 prop(p,'bool','CanCollide',str(not glass and not neon).lower());prop(p,'bool','CastShadow',str(not glass and not neon).lower())
 prop(p,'float','Transparency',.85 if glass else 0)
 orientation=rot(yaw)
 if shape=='cylinder':
  prop(p,'token','shape',2)
  # Native Roblox cylinders run along local X. Rotate into the vertical axis.
  orientation=orientation@np.array([[0,-1,0],[1,0,0],[0,0,1]])
  composite(p,'Vector3','size',dict(zip('XYZ',[size[1],size[0],size[2]])))
 elif shape=='ball':prop(p,'token','shape',0)
 composite(p,'CoordinateFrame','CFrame',dict(zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],[6000+pos[0],pos[1],pos[2]]+orientation.flatten().tolist())))
 shapes.append(dict(name=name,position=pos,size=size,color=color,shape=shape,yaw=yaw,glass=glass,neon=neon,kind=kind))
 return p
def label(parent,name,pos,size,text,color=CYAN,yaw=0):
 p=create(parent,name,pos,size,NAVY,yaw=yaw)
 gui=node(p,'SurfaceGui','Sign');prop(gui,'token','Face',5)
 t=node(gui,'TextLabel','Text');prop(t,'string','Text',text);prop(t,'bool','TextScaled','true');prop(t,'bool','TextWrapped','true');prop(t,'float','BackgroundTransparency',1)
 composite(t,'Color3','TextColor3',dict(zip('RGB',[v/255 for v in color])))
 e=prop(t,'UDim2','Size','')
 for k,v in [('XS',1),('XO',0),('YS',1),('YO',0)]:E.SubElement(e,k).text=str(v)
 return p
deck=node(lobby,'Model','Deck')
create(deck,'CircularDeck',[0,0,0],[392,4,392],GREY,'cylinder',kind='floor')
for r,y,c in [(190,2.1,NAVY),(184,2.2,WHITE),(178,2.3,GREY)]:create(deck,'DeckBorder',[0,y,0],[r*2,.2,r*2],c,'cylinder',kind='floor')
for r in [52,100,168]:
 for n in range(64):
  a=n*math.tau/64
  create(deck,'GuideLine',[math.sin(a)*r,2.6,math.cos(a)*r],[2,.4,r*math.tau/64*.85],GOLD if r==52 else CYAN,yaw=a+math.pi/2,neon=True,kind='guide')
airport=node(lobby,'Model','Airport');node(airport,'Model','Airship')
for radius,y,h,c in [(30,4,4,NAVY),(28,6.2,.4,GOLD),(26,8,4,WHITE),(24,10.2,.4,CYAN),(22,11,2,GREY)]:create(airport,'Dock',[0,y,0],[radius*2,h,radius*2],c,'cylinder',neon=h<1,kind='dock')
dep=create(airport,'Departure',[0,4,-34],[8,4,8],NAVY);prop(dep,'float','Transparency',1);prop(dep,'bool','CanCollide','false')
rocket=node(airport,'Model','Rocket')
create(rocket,'RocketHull',[0,34,0],[20,38,20],(244,244,231),'cylinder',kind='rocket')
create(rocket,'Nose',[0,57,0],[20,28,20],(234,63,71),'ball',kind='rocket')
for y,c in [(17,GOLD),(20,(235,61,72)),(50,GOLD)]:create(rocket,'Band',[0,y,0],[21,2,21],c,'cylinder',kind='rocket')
create(rocket,'WindowRim',[0,36,-10],[12,12,4],GOLD,'ball',kind='rocket')
create(rocket,'Window',[0,36,-12],[9,9,3],(51,180,234),'ball',kind='rocket')
for angle in [0,math.tau/3,math.tau*2/3]:
 for i in range(4):
  r=13+i*2
  create(rocket,'Fin',[math.sin(angle)*r,21-i*2,math.cos(angle)*r],[4,16-i*2,8],(232,64,72),yaw=angle,kind='rocket')
label(airport,'Destination',[0,9,-29],[24,8,2],'GREEN STAR',GOLD)
plots=node(lobby,'Folder','Plots');colors=[(255,109,106),(80,161,255),(140,223,108),(190,129,255),(255,207,79),(62,223,238),(255,137,205),(255,165,75)]
for index in range(8):
 a=index*math.tau/8;center=np.array([math.sin(a)*138,0,math.cos(a)*138]);turn=rot(a)
 room=node(plots,'Model',f'Plot_{index+1}');accent=colors[index]
 def local(parent,name,pos,size,color=WHITE,shape='box',glass=False,neon=False,kind='room'):
  return create(parent,name,(center+turn@np.array(pos)).tolist(),size,color,shape,a,glass,neon,kind)
 local(room,'RoomBase',[0,3,0],[88,2,88],WHITE,'cylinder')
 local(room,'RoomRoof',[0,44,0],[88,4,88],WHITE,'cylinder',kind='roof')
 for n in range(9):
  theta=(n/8)*math.pi;pos=[math.cos(theta)*42,24,math.sin(theta)*42]
  local(room,'WallColumn',pos,[3,40,3],WHITE,'cylinder')
 for n in range(8):
  theta=(n+.5)*math.pi/8
  pos=(center+turn@np.array([math.cos(theta)*42,24,math.sin(theta)*42])).tolist()
  panel=create(room,'RearWindow',pos,[13.5,38,1],(144,199,221),yaw=a+math.pi/2-theta,glass=True,kind='window')
  prop(panel,'bool','CanCollide','true')
 for x in [-18,18]:local(room,'DoorPillar',[x,21,-30],[5,34,5])
 local(room,'DoorLintel',[0,37,-30],[40,6,6])
 for x in [-8,8]:local(room,'DoorLeft' if x<0 else 'DoorRight',[x,15,-30],[16,22,2],GREY)
 sensor=local(room,'DoorSensor',[0,8,-40],[24,12,16]);prop(sensor,'float','Transparency',1);prop(sensor,'bool','CanCollide','false')
 manage=local(room,'ManagePoint',[0,4,-18],[8,4,8]);prop(manage,'float','Transparency',1);prop(manage,'bool','CanCollide','false')
 label(room,'OwnerBoard',(center+turn@np.array([0,40,-31])).tolist(),[32,8,2],f'{index+1:02} | YOUR HATCHERY',accent,a)
 pen=node(node(room,'Folder','Pens'),'Model','Pen_1')
 local(pen,'PenGrass',[0,6,0],[24,4,24],NAVY,'cylinder')
 for y in [9,31]:
  local(pen,'IncubatorFrame',[0,y,0],[28,4,28],WHITE,'cylinder')
  local(pen,'IncubatorRim',[0,y+2.1,0],[25,.3,25],accent,'cylinder',neon=True)
 local(pen,'GlassChamber',[0,20,0],[23,20,23],accent,'cylinder',glass=True)
 for theta in [math.pi/4,3*math.pi/4,5*math.pi/4,7*math.pi/4]:
  local(pen,'FrameSupport',[math.sin(theta)*13,20,math.cos(theta)*13],[3,24,3],WHITE,'cylinder')
 capsules=node(room,'Folder','BabyCapsules')
 for slot,(x,z) in enumerate([(-22,10),(-22,24),(22,10),(22,24)],1):
  cap=node(capsules,'Model',f'Capsule_{slot}')
  for y in [7,23]:local(cap,'Frame',[x,y,z],[12,3,12],WHITE,'cylinder')
  local(cap,'Glass',[x,15,z],[10,14,10],accent,'cylinder',glass=True)
  local(cap,'Glow',[x,8.6,z],[10,.3,10],accent,'cylinder',neon=True)
  label(cap,'CapsuleNumber',(center+turn@np.array([x,25,z-6])).tolist(),[8,4,1],str(slot),accent,a)
 for t in range(7):
  r=38+t*9
  create(deck,'Walkway',[math.sin(a)*r,3,math.cos(a)*r],[14,1,8],WHITE,yaw=a,kind='guide')
shell=node(lobby,'Model','ShipShell')
for n in range(16):
 a=n*math.tau/16;r=188
 create(shell,'StructuralRib',[math.sin(a)*r,45,math.cos(a)*r],[5,88,5],WHITE,'cylinder')
 create(shell,'Window',[math.sin(a)*r,48,math.cos(a)*r],[r*math.tau/16-5,72,1],(106,173,223),yaw=a,glass=True,kind='window')
for radius,y in [(188,10),(188,86)]:
 for n in range(64):
  a=n*math.tau/64
  create(shell,'WindowRim',[math.sin(a)*radius,y,math.cos(a)*radius],[4,4,radius*math.tau/64],WHITE,yaw=a+math.pi/2)
roof=node(lobby,'Model','Roof');create(roof,'Ceiling',[0,94,0],[392,4,392],NAVY,'cylinder',kind='roof')
label(shell,'GameTitle',[0,70,186],[72,20,3],'RODEO\nPLANETURE',GOLD)
create(shell,'TitlePlanet',[0,85,183],[9,9,3],CYAN,'ball')
for name,x,z,text in [('ShopA',-90,-145,'SHOP 01'),('ShopB',90,-145,'SHOP 02'),('DistanceRank',-168,-50,'DISTANCE'),('JournalRank',-168,50,'JOURNAL'),('Roulette',168,-50,'ROULETTE'),('BattlePass',168,50,'BATTLE PASS')]:
 booth=node(lobby,'Model',name);label(booth,'Board',[x,22,z],[32,20,2],text)
 create(booth,'Console',[x,6,z],[32,8,14],WHITE)
assert_unique_ids(root)
E.ElementTree(root).write(OUT/'SmoothLobbyDraft.rbxmx',encoding='utf-8',xml_declaration=True)
import copy
place=E.Element('roblox',version='4');workspace=node(place,'Workspace','Workspace');workspace.append(copy.deepcopy(lobby))
spawn=create(workspace,'ReviewSpawn',[0,4,-64],[8,2,8],NAVY)
spawn.set('class','SpawnLocation');prop(spawn,'bool','Neutral','true')
lighting=node(place,'Lighting','Lighting');prop(lighting,'float','Brightness',2)
composite(lighting,'Color3','Ambient',{'R':.48,'G':.52,'B':.62})
composite(lighting,'Color3','OutdoorAmbient',{'R':.48,'G':.52,'B':.62})
assert_unique_ids(place)
E.ElementTree(place).write(OUT/'SmoothLobbyDraft.rbxlx',encoding='utf-8',xml_declaration=True)
(OUT/'layout.json').write_text(json.dumps({'draft':True,'title':'Rodeo Planeture','shapes':shapes},indent=2),encoding='utf-8')
print('SMOOTH_LOBBY_DRAFT_BUILT',len(shapes),'native smooth Parts; not installed')
if __name__=='__main__':pass
