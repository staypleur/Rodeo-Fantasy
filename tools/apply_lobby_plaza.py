"""Apply the approved plaza model, preserve gameplay paths and ranch assets."""
from pathlib import Path
import copy, math, itertools, xml.etree.ElementTree as E
import numpy as np
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
def name(n):return n.findtext("Properties/string[@name='Name']")
def find(n,key):return next(c for c in n.findall('Item') if name(c)==key)
def pose(n):
 cf=n.find("Properties/CoordinateFrame[@name='CFrame']")
 return cf,np.array([float(cf.findtext(a)) for a in 'XYZ']),np.array([[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)])
def flag(n,key,value):
 p=n.find('Properties');v=p.find(f"bool[@name='{key}']")
 if v is None:v=E.SubElement(p,'bool',name=key)
 v.text='true' if value else 'false'

patcher.SOURCES={'Config':R/'src/shared/Config.luau'}
patcher.patch(R/'dist/RodeoFantasy-LobbyColors.rbxlx',R/'.tools/plaza-source.rbxlx')
before=E.parse(R/'.tools/plaza-source.rbxlx').getroot();after=copy.deepcopy(before)
lobby=next(n for n in after.iter('Item') if name(n)=='RodeoLobby')
oldLobby=next(n for n in before.iter('Item') if name(n)=='RodeoLobby')
saved={key:E.tostring(find(lobby,key)) for key in ('Plots','Airport','PlanetureFloorLogo','LobbySpawn','Boundary')}
light=next(n for n in find(lobby,'Lantern').findall('Item') if n.get('class')=='PointLight')
removed=[]
for n in list(lobby.findall('Item')):
 if name(n) in ('PlazaBrick','PavingStone','LampPost','Lantern','LampCap') or name(n).startswith('GardenCorner_'):
  removed.append(n);lobby.remove(n)
assert sum(name(n).startswith('GardenCorner_') for n in removed)==4

model=E.SubElement(lobby,'Item',{'class':'Model','referent':'ApprovedPlazaGarden'})
p=E.SubElement(model,'Properties');E.SubElement(p,'string',name='Name').text='PlazaGarden'
native=E.parse(R/'dist/ReviewModels/LobbyPlazaGardenReview.rbxmx').getroot().find('Item')
count=0
for serial,original in enumerate(native.findall('Item')):
 # Existing island and 98-stud paths already connect every entrance. Keep them.
 if name(original) in ('ReviewGround','OpenWalk'):continue
 n=copy.deepcopy(original);n.set('referent',f'ApprovedPlazaPart{serial}')
 cf,pos,rot=pose(n);pos[0]+=6000
 # Align paving with the existing floor beneath the preserved logo/spawn.
 if name(n)=='PlazaTile':pos[1]+=.15
 for i,a in enumerate('XYZ'):cf.find(a).text=str(pos[i])
 flag(n,'CanCollide',name(n) not in ('Leaf','Flower','VineCanopy','Lamp'))
 if name(n)=='Lamp':
  glow=copy.deepcopy(light);glow.set('referent',f'ApprovedPlazaLight{serial}');n.append(glow)
 model.append(n);count+=1
assert count==613

# Move existing service stations into the outer gaps, clear of approved gardens.
# Only their placement changes; signs, prompts, datastore boards remain intact.
for key in ('Shops','Leaderboards'):
 service=find(lobby,key)
 for n in service.iter('Item'):
  if n.find("Properties/CoordinateFrame[@name='CFrame']") is None:continue
  cf,pos,rot=pose(n);offset=pos-np.array([6000,pos[1],0])
  angle=round(math.atan2(offset[0],offset[2])/ (math.pi/4)-.5)*math.pi/4+math.pi/8
  delta=np.array([math.sin(angle),0,math.cos(angle)])*(95-49)
  new=pos+delta
  for i,a in enumerate('XYZ'):cf.find(a).text=str(new[i])
 # GUI and all props except CFrame must stay the same.
 old=copy.deepcopy(find(oldLobby,key));new=copy.deepcopy(service)
 for obj in (old,new):
  for cf in obj.findall(".//CoordinateFrame[@name='CFrame']"):
   for axis in 'XYZ':cf.find(axis).text='0'
 assert E.tostring(old)==E.tostring(new)

for key,value in saved.items():assert E.tostring(find(lobby,key))==value,key
assert sum(name(n)=='PenGrass' for n in find(lobby,'Plots').iter('Item'))==32
assert sum(name(n)=='GardenPath' for n in lobby.findall('Item'))==8
# Check actual installed decorations and relocated services against main walks.
checked=list(model.findall('Item'))
for key in ('Shops','Leaderboards'):
 checked.extend(n for n in find(lobby,key).iter('Item') if n.find("Properties/CoordinateFrame[@name='CFrame']") is not None)
for n in checked:
 if name(n)=='PlazaTile':continue
 cf,pos,rot=pose(n);pos[0]-=6000
 size=np.array([float(n.findtext(f"Properties/Vector3[@name='size']/{a}")) for a in 'XYZ'])
 for sx,sz in itertools.product((-1,1),repeat=2):
  q=pos+rot@np.array([sx*size[0]/2,0,sz*size[2]/2])
  for i in range(8):
   a=i*math.pi/4;along=q[0]*math.sin(a)+q[2]*math.cos(a);across=q[0]*math.cos(a)-q[2]*math.sin(a)
   assert not (31<along<129 and abs(across)<6),'garden blocks a main path'
assert sum(n.get('class')=='PointLight' for n in model.iter('Item'))==16
# Non-lobby geometry/scripts remain untouched after the selected Config patch.
for tree,child in ((before,oldLobby),(after,lobby)):
 parent=next(n for n in tree.iter('Item') if child in list(n));parent.remove(child)
assert E.tostring(before)==E.tostring(after)
parent.append(lobby)
refs=[n.get('referent') for n in after.iter('Item')];assert len(refs)==len(set(refs))
refset=set(refs)
assert all(n.text in refset or n.text in ('null','nil',None) for n in after.iter('Ref'))
assert sum(n.get('class')=='MeshPart' for n in after.iter('Item'))==703
out=R/'dist/RodeoFantasy-LobbyPlaza.rbxlx'
E.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
print(f'PLAZA_APPLY_PASS: {count} installed parts, 8 clear paths, 32 pens, logo/spawn/airport/703 meshes preserved; {out}')
