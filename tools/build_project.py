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
  for old_parent,new_parent,names in [(old_ss,ss,['RodeoMonsterTemplate']),(old_package,package,['VisualTemplate','MeshyMossratHuntTemplate'])]:
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
    if key.startswith(('MossratRigBackup_',)):ss.append(preserve(saved))
  if old_ws is not None:
   for key in ('MossratImport',):
    saved=named(old_ws,key)
    if saved is not None:ws.append(preserve(saved))
 assert_unique_ids(root)
 out=R/'dist/RodeoFantasy-New.rbxlx';out.parent.mkdir(exist_ok=True)
 E.ElementTree(root).write(out,encoding='utf-8',xml_declaration=True)
 print('NEW_PROJECT_BUILT',out.stat().st_size,'bytes; new maps only, cafe systems inactive, model imports pending')
 return out
if __name__=='__main__':build()
