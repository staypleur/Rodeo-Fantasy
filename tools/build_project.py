"""The sole place build entry point: new lobby/forest plus retained systems."""
from pathlib import Path
import xml.etree.ElementTree as E
import json,copy,math
from place_identity import assert_unique_ids
from lobby_geometry import expand
R=Path(__file__).resolve().parents[1]
serial=0
def prop(n,tag,key,value):
 p=n.find('Properties');old=p.find(f"*[@name='{key}']")
 if old is not None:p.remove(old)
 e=E.SubElement(p,tag,name=key);e.text=str(value);return e
def node(parent,kind,name):
 global serial
 serial+=1;x=E.SubElement(parent,'Item',{'class':kind,'referent':f'RBXNewProject{serial}'})
 E.SubElement(x,'Properties');prop(x,'string','Name',name);return x
def composite(n,tag,key,values):
 p=prop(n,tag,key,'')
 for k,v in values.items():E.SubElement(p,k).text=str(v)
def part(parent,name,pos,size,color=(255,255,255),hidden=False):
 p=node(parent,'Part',name);composite(p,'Vector3','size',dict(zip('XYZ',size)))
 composite(p,'CoordinateFrame','CFrame',dict(zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],pos+[1,0,0,0,1,0,0,0,1])))
 composite(p,'Color3','Color',dict(zip('RGB',[v/255 for v in color])))
 prop(p,'bool','Anchored','true');prop(p,'bool','CanTouch','false');prop(p,'bool','CanCollide',str(not hidden).lower());prop(p,'float','Transparency',1 if hidden else 0);prop(p,'token','Material',256);prop(p,'token','shape',1)
 for f in ('TopSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'):prop(p,'token',f,3)
 prop(p,'token','BottomSurface',4);return p
def script(parent,kind,name,source,disabled=False):
 n=node(parent,kind,name);prop(n,'ProtectedString','Source',source)
 if kind!='ModuleScript':prop(n,'bool','Disabled',str(disabled).lower())
 return n
def generate_data():
 data=json.loads((R/'assets/courses/StudForest1000/layout.json').read_text())
 rows=[]
 for b in data['blocks']:
  fields=[]
  for k in ('name','kind','position','size','color'):
   value=b[k];fields.append(k+'='+('{' + ','.join(map(str,value))+'}' if isinstance(value,list) else json.dumps(value)))
  rows.append('{'+','.join(fields)+'},')
 (R/'src/shared/GreenStarLayout.luau').write_text('return {blocks={\n'+'\n'.join(rows)+'\n}}\n',encoding='utf-8')
 return data
def build():
 global serial
 # Keep the user's successfully uploaded models and material asset references.
 existing=R/'dist/RodeoFantasy-New.rbxlx'
 previous=E.parse(existing).getroot() if existing.exists() else None
 legacy_course='Restored pre-Raise-Animal' in (R/'src/server/HuntWorld.luau').read_text(encoding='utf-8')
 serial=0;data={'blocks':[]} if legacy_course else generate_data();root=E.Element('roblox',version='4')
 ws=node(root,'Workspace','Workspace');node(ws,'Terrain','Terrain')
 prop(ws,'float','Gravity',196.2)
 rs=node(root,'ReplicatedStorage','ReplicatedStorage');package=node(rs,'Folder','RodeoFantasy')
 ss=node(root,'ServerStorage','ServerStorage');server=node(root,'ServerScriptService','ServerScriptService')
 player=node(root,'StarterPlayer','StarterPlayer');client=node(player,'StarterPlayerScripts','StarterPlayerScripts');node(root,'StarterGui','StarterGui');node(root,'Lighting','Lighting')
 node(package,'RemoteEvent','CaptureRemote')
 lobby=copy.deepcopy(E.parse(R/'assets/maps/SpaceLobby.rbxmx').getroot().find('Item'));ws.append(lobby)
 expand(lobby,node,part)
 boards=node(lobby,'Folder','Leaderboards')
 for key,title,x in [('Distance','최고 거리',5946),('Income','도감 수집',6054)]:
  board=part(boards,key,[x,2.04,-16],[26,.08,30],(24,38,64))
  prop(board,'bool','CanCollide','false');prop(board,'bool','CanQuery','false')
  gui=node(board,'SurfaceGui','Ranking');prop(gui,'token','Face',1)
  composite(gui,'Vector2','CanvasSize',{'X':780,'Y':900})
  for key,y,height,text,size in [('Heading',0,120,title,52),('Entries',140,740,'기록을 불러오는 중입니다.',34)]:
   label=node(gui,'TextLabel',key);prop(label,'string','Text',text);prop(label,'float','TextSize',size)
   prop(label,'float','BackgroundTransparency',1);prop(label,'bool','TextWrapped','true');prop(label,'token','TextYAlignment',0)
   composite(label,'Color3','TextColor3',{'R':.9,'G':.95,'B':1})
   composite(label,'UDim2','Position',{'XS':0,'XO':24,'YS':0,'YO':y})
   composite(label,'UDim2','Size',{'XS':1,'XO':-48,'YS':0,'YO':height})
 # All eight doors face the center, including the diagonal rooms.
 for room in lobby.findall("Item/Item"):
  if not (room.findtext("Properties/string[@name='Name']") or '').startswith('Plot_'):continue
  def child(name):return next(c for c in room.findall('Item') if c.findtext("Properties/string[@name='Name']")==name)
  base=child('RoomBase').find("Properties/CoordinateFrame[@name='CFrame']")
  center=[float(base.find(k).text) for k in ('X','Y','Z')]
  door=child('DoorSensor').find("Properties/CoordinateFrame[@name='CFrame']")
  current=math.atan2(float(door.find('X').text)-center[0],float(door.find('Z').text)-center[2])
  target=math.atan2(6000-center[0],-center[2]);angle=target-current
  c,s=math.cos(angle),math.sin(angle)
  import numpy as np
  rotation=np.array([[c,0,s],[0,1,0],[-s,0,c]])
  for item in room.iter('Item'):
   cf=item.find("Properties/CoordinateFrame[@name='CFrame']")
   if cf is None:continue
   pos=np.array([float(cf.find(k).text) for k in ('X','Y','Z')]);pos=np.array(center)+rotation@(pos-np.array(center))
   orientation=rotation@np.array([[float(cf.find(f'R{i}{j}').text) for j in range(3)] for i in range(3)])
   for key,v in zip(('X','Y','Z'),pos):cf.find(key).text=str(v)
   for i in range(3):
    for j in range(3):cf.find(f'R{i}{j}').text=str(orientation[i,j])
  for gui in child('OwnerBoard').iter('Item'):
   if gui.get('class')=='TextLabel':prop(gui,'string','Text','')
 roof=next((c for c in lobby.findall('Item') if c.findtext("Properties/string[@name='Name']")=='Roof'),None)
 if roof is None:roof=node(lobby,'Model','Roof')
 for c in list(roof.findall('Item')):
  if c.findtext("Properties/string[@name='Name']") in ('Ceiling','FullOpaqueCeiling'):roof.remove(c)
 cap=part(roof,'FullGlassCeiling',[6000,102,0],[512,2,512],(173,212,232));prop(cap,'token','Material',1568);prop(cap,'float','Transparency',.65)
 floor=part(lobby,'LobbyCollisionFloor',[6000,0,0],[512,4,512],hidden=True);prop(floor,'bool','CanCollide','true')
 for parent in lobby.iter('Item'):
  for c in list(parent.findall('Item')):
   if c.findtext("Properties/string[@name='Name']") in ('PlanetLayer','PlanetRing','DepartureSign'):parent.remove(c)
  if parent.findtext("Properties/string[@name='Name']")=='WindowSpace':
   prop(parent,'token','Material',1088);prop(parent,'float','Transparency',0);prop(parent,'bool','CanCollide','true')
 # Latest request removes Studs from the installed lobby, not just a separate draft.
 for p in lobby.iter('Item'):
  if p.get('class')=='Part':
   for face in ('TopSurface','BottomSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'):prop(p,'token',face,0)
   material=p.find("Properties/token[@name='Material']")
   if material is not None and material.text=='256':material.text='272'
 prototype=node(ws,'Folder','RodeoPrototype');node(prototype,'Folder','Monsters')
 forest=node(ws,'Model','GreenStar')
 for b in data['blocks']:
  p=part(forest,b['name'],b['position'],b['size'],b['color'])
  if b['kind']=='Scenery':prop(p,'bool','CanCollide','false')
 # Empty authoritative roots are not creature designs. Real MeshParts are imported once.
 for parent,name in [(ss,'RodeoMonsterTemplate'),(package,'VisualTemplate'),(package,'MeshyMossratHuntTemplate')]:
  model=node(parent,'Model',name);p=part(model,'Root',[0,2.05,0],[2,2,3],hidden=True)
  prop(model,'Ref','PrimaryPart',p.get('referent'))
 for folder,parent in [('shared',package),('server',server),('client',client)]:
  for path in sorted((R/'src'/folder).glob('*.luau')):
   name=path.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau')
   if name in ('SpaceLobbyDoors','SpaceLobbyInit'):continue
   kind='Script' if path.name.endswith('.server.luau') else 'LocalScript' if path.name.endswith('.client.luau') else 'ModuleScript'
   script(parent,kind,name,path.read_text(encoding='utf-8'),name in ('CafeServer','CafeClient'))
 script(lobby,'Script','SpaceLobbyDoors',(R/'src/server/SpaceLobbyDoors.server.luau').read_text(encoding='utf-8'))
 script(server,'Script','SpaceLobbyInit','''local lobby=workspace:WaitForChild("RodeoLobby")
lobby:SetAttribute("SpaceLobbyInstalled",true)
lobby:SetAttribute("GreenStarRuntimeReady",workspace:FindFirstChild("GreenStar")~=nil)
lobby:SetAttribute("LobbyCapacity",8)
lobby.Airport.Airship:SetAttribute("RocketDepartureActive",true)
''')
 if previous is not None:
  def named(parent,key):return next((c for c in parent.findall('Item') if c.findtext("Properties/string[@name='Name']")==key),None)
  def service(key):return next((n for n in previous.findall('Item') if n.get('class')==key),None)
  preserved_serial=0
  def preserve(saved):
   nonlocal preserved_serial
   clone=copy.deepcopy(saved);refs={}
   for item in clone.iter('Item'):
    preserved_serial+=1;refs[item.get('referent')]=f'RBXPreserved{preserved_serial}'
   for item in clone.iter('Item'):item.set('referent',refs[item.get('referent')])
   for ref in clone.iter('Ref'):
    if ref.text not in ('null','nil',None):
     assert ref.text in refs,'Preserved model has external reference: '+str(ref.text)
     ref.text=refs[ref.text]
   return clone
  old_ss=service('ServerStorage');old_rs=service('ReplicatedStorage');old_ws=service('Workspace')
  old_package=named(old_rs,'RodeoFantasy') if old_rs is not None else None
  if old_ws is not None:
   old_lobby=named(old_ws,'RodeoLobby')
   old_airport=named(old_lobby,'Airport') if old_lobby is not None else None
   old_rocket=named(old_airport,'Rocket') if old_airport is not None else None
   if old_rocket is not None and any(n.get('class')=='MeshPart' for n in old_rocket.iter('Item')):
    new_airport=named(lobby,'Airport');default=named(new_airport,'Rocket')
    if default is not None:new_airport.remove(default)
    new_airport.append(preserve(old_rocket))
  for old_parent,new_parent,names in [(old_ss,ss,['RodeoMonsterTemplate','RodeoMonsterTemplate_S3']),(old_package,package,['VisualTemplate','MeshyMossratHuntTemplate','VisualTemplate_S3','MeshyMossratHuntTemplate_S3'])]:
   if old_parent is None:continue
   for key in names:
    saved=named(old_parent,key)
    if saved is not None and any(n.get('class')=='MeshPart' for n in saved.iter('Item')):
     default=named(new_parent,key)
     if default is not None:new_parent.remove(default)
     new_parent.append(preserve(saved))
  if old_ss is not None:
   for saved in old_ss.findall('Item'):
    key=saved.findtext("Properties/string[@name='Name']") or ''
    if key.startswith(('MossratRigBackup_','MossratS3RigBackup_')):ss.append(preserve(saved))
  if old_ws is not None:
   for key in ('MossratImport',):
    saved=named(old_ws,key)
    if saved is not None:
     backups=node(ss,'Folder','WorkspaceImportBackup')
     backups.append(preserve(saved))
 assert_unique_ids(root)
 out=R/'dist/RodeoFantasy-New.rbxlx';out.parent.mkdir(exist_ok=True)
 E.ElementTree(root).write(out,encoding='utf-8',xml_declaration=True)
 print('NEW_PROJECT_BUILT',out.stat().st_size,'bytes; new maps only, cafe systems inactive, model imports pending')
 return out
if __name__=='__main__':build()
