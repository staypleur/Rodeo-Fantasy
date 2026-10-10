"""Prepare separate lobby/cafe places, never overwrite the user's open place."""
from pathlib import Path
import xml.etree.ElementTree as E
import copy,json,math
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1]
def name(n):return n.findtext("Properties/string[@name='Name']")
def prop(n,tag,key,value):
 p=n.find('Properties');old=p.find(f"*[@name='{key}']")
 if old is not None:p.remove(old)
 e=E.SubElement(p,tag,name=key);e.text=str(value);return e
def node(parent,kind,n):
 x=E.SubElement(parent,'Item',{'class':kind,'referent':'RBXSocial'+n})
 E.SubElement(x,'Properties');prop(x,'string','Name',n);return x
def composite(n,tag,key,fields):
 p=prop(n,tag,key,'')
 for k,v in fields.items():E.SubElement(p,k).text=str(v)
def cafe_geometry(ws):
 model=node(ws,'Model','RodeoCafe')
 for index,item in enumerate(json.loads((R/'assets/cafe/layout.json').read_text(encoding='utf-8')),1):
  p=node(model,item.get('class','Part'),'CafePart'+str(index));prop(p,'string','Name',item['name'])
  composite(p,'Vector3','size',dict(zip('XYZ',item['size'])))
  a=math.radians(item.get('yaw',0));c,s=math.cos(a),math.sin(a)
  composite(p,'CoordinateFrame','CFrame',dict(zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],item['pos']+[c,0,s,0,1,0,-s,0,c])))
  composite(p,'Color3','Color',dict(zip('RGB',[v/255 for v in item['color']])))
  prop(p,'bool','Anchored','true');prop(p,'bool','CanCollide',str(item.get('collide',True)).lower());prop(p,'bool','CanTouch','false')
  prop(p,'float','Transparency',item.get('alpha',0));prop(p,'token','Material',{'Grass':1280,'WoodPlanks':528,'Glass':1088,'Neon':288,'Fabric':1312}.get(item.get('material'),272))
  if item.get('shape')=='Ball':prop(p,'token','shape',0)
  for surface in ('TopSurface','BottomSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'):prop(p,'token',surface,0)
  number=node(p,'IntValue','CafeIndex'+str(index));prop(number,'string','Name','LayoutIndex');prop(number,'int','Value',index)
  if item.get('text'):
   gui=node(p,'SurfaceGui','CafeSign'+str(index));prop(gui,'token','Face',5);composite(gui,'Vector2','CanvasSize',{'X':900,'Y':200})
   label=node(gui,'TextLabel','CafeText'+str(index));prop(label,'string','Text',item['text']);prop(label,'bool','TextScaled','true');prop(label,'float','BackgroundTransparency',1)
   composite(label,'UDim2','Size',{'XS':1,'XO':0,'YS':1,'YO':0});composite(label,'Color3','TextColor3',{'R':.985,'G':.91,'B':.72})
  if item.get('light'):
   light=node(p,'PointLight','CafeLight'+str(index));prop(light,'float','Brightness',.8);prop(light,'float','Range',18);composite(light,'Color3','Color',{'R':1,'G':.87,'B':.65})
 spawn=node(model,'SpawnLocation','CafeSpawn');prop(spawn,'bool','Anchored','true');prop(spawn,'bool','CanCollide','false');prop(spawn,'float','Transparency',1);prop(spawn,'bool','Neutral','true');prop(spawn,'int','Duration',0)
 composite(spawn,'Vector3','size',{'X':8,'Y':1,'Z':8});composite(spawn,'CoordinateFrame','CFrame',{'X':0,'Y':0,'Z':-84,'R00':1,'R01':0,'R02':0,'R10':0,'R11':1,'R12':0,'R20':0,'R21':0,'R22':1})
def prepare(source,prefix):
 root=E.parse(source).getroot()
 rs=next(n for n in root.iter('Item') if n.get('class')=='ReplicatedStorage')
 package=next(n for n in rs.findall('Item') if name(n)=='RodeoFantasy')
 server=next(n for n in root.iter('Item') if n.get('class')=='ServerScriptService')
 client=next(n for n in root.iter('Item') if n.get('class')=='StarterPlayerScripts')
 scripts={name(n):n for n in root.iter('Item') if n.get('class') in ('Script','LocalScript','ModuleScript')}
 files={}
 for folder in ('shared','server','client'):
  for path in (R/'src'/folder).glob('*.luau'):
   key=path.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau')
   # Preserve private operator credentials/configuration embedded by the user.
   if 'Operator' in key:continue
   files[key]=(path,folder)
 additions={'SocialConfig','SocialRules','InventoryStore','SocialService','PlaceTravel','SocialUI','NativeMossrat','UserMossratRigData','UserMossratRigAnimator','CafeLayout','CafeWorld','CafeServer','CafeClient'}
 for key,(path,folder) in files.items():
  if key not in scripts and key not in additions:continue
  kind='Script' if path.name.endswith('.server.luau') else 'LocalScript' if path.name.endswith('.client.luau') else 'ModuleScript'
  n=scripts.get(key)
  if n is None:n=node({'shared':package,'server':server,'client':client}[folder],kind,key);scripts[key]=n
  prop(n,'ProtectedString','Source',path.read_text(encoding='utf-8'))
 installer=scripts.get('MeshyMossratInstaller')
 if installer is None:installer=node(package,'ModuleScript','MeshyMossratInstaller')
 prop(installer,'ProtectedString','Source',(R/'src/authoring/MeshyMossratInstaller.luau').read_text(encoding='utf-8'))
 for key in ('MeshyAirshipInstaller','MeshyAirshipData'):
  n=node(package,'ModuleScript',key)
  prop(n,'ProtectedString','Source',(R/f'src/authoring/{key}.luau').read_text(encoding='utf-8'))
 for cafe,label in ((False,'Hatchery'),(True,'Cafe')):
  out=copy.deepcopy(root)
  for n in out.iter('Item'):
   key=name(n)
   if key in ('CaptureServer','CaptureClient','CafeServer','CafeClient'):
    prop(n,'bool','Disabled',str((key.startswith('Cafe'))!=cafe).lower())
  if cafe:
   ws=next(n for n in out.iter('Item') if n.get('class')=='Workspace')
   for n in list(ws.findall('Item')):
    if n.get('class') not in ('Camera','Terrain'):ws.remove(n)
   cafe_geometry(ws)
  assert_unique_ids(out)
  path=R/f'{prefix}-{label}.rbxlx';path.parent.mkdir(parents=True,exist_ok=True)
  E.ElementTree(out).write(path,encoding='utf-8',xml_declaration=True)
  print(path.name,'prepared',path.stat().st_size)
prepare(R/'dist/RodeoFantasy-LobbyFinal-Operator.rbxlx','dist/RodeoFantasy-Social')
private=R/'dist/LocalOperator/RodeoFantasy-MeshyMossrat-Operator.rbxlx'
if private.exists():prepare(private,'dist/LocalOperator/RodeoFantasy-Social-Operator')
