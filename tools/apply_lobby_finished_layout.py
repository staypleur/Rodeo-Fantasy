"""Apply approved tall shops, freestanding boards and outer entrance to a saved place."""
from pathlib import Path
import argparse,copy,math,itertools,xml.etree.ElementTree as E
import numpy as np
from place_identity import repair_duplicate_unique_ids
R=Path(__file__).resolve().parents[1]
def name(n):return n.findtext("Properties/string[@name='Name']")
def find(n,key):return next(k for k in n.findall('Item') if name(k)==key)
def pose(n):
 cf=n.find("Properties/CoordinateFrame[@name='CFrame']")
 return cf,np.array([float(cf.findtext(a)) for a in 'XYZ']),np.array([[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)])
def transform(n,p,m):
 cf,_,_=pose(n)
 for i,a in enumerate('XYZ'):cf.find(a).text=str(p[i])
 for i in range(3):
  for j in range(3):cf.find(f'R{i}{j}').text=str(m[i,j])
def flag(n,key,value):
 p=n.find('Properties');v=p.find(f"bool[@name='{key}']")
 if v is None:v=E.SubElement(p,'bool',name=key)
 v.text='true' if value else 'false'
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,default=R/'dist/RodeoFantasy-LobbyHuntFix.rbxlx')
parser.add_argument('--output',type=Path,default=R/'dist/RodeoFantasy-LobbyFinishedLayout.rbxlx')
args=parser.parse_args()
before=E.parse(args.source).getroot();after=copy.deepcopy(before)
lobby=next(n for n in after.iter('Item') if name(n)=='RodeoLobby')
oldLobby=next(n for n in before.iter('Item') if name(n)=='RodeoLobby')
native=E.parse(R/'dist/ReviewModels/LobbyServicesRevisionReview.rbxmx').getroot().find('Item')
shops=find(lobby,'Shops');boards=find(lobby,'Leaderboards')
oldShops=copy.deepcopy(shops);oldBoards=copy.deepcopy(boards)
saved={key:E.tostring(find(lobby,key)) for key in ('Plots','Airport','PlazaGarden','PlanetureFloorLogo','LobbySpawn','Boundary')}

for old in list(shops.findall('Item'))+list(boards.findall('Item')):
 (shops if old in shops.findall('Item') else boards).remove(old)
installed=[]
for serial,(kind,slot,angle) in enumerate((('Shop','Shop_1',22.5),('Shop','Shop_2',202.5),('Ranking','Distance',112.5),('Ranking','Income',292.5))):
 a=math.radians(angle);co,si=math.cos(a),math.sin(a)
 rot=np.array([[co,0,si],[0,1,0],[-si,0,co]])
 center=np.array([6000+si*95,0,co*95]);cx=-19 if kind=='Shop' else 19
 if kind=='Shop':
  old=find(oldShops,slot);container=E.Element('Item',dict(old.attrib));container.append(copy.deepcopy(old.find('Properties')));shops.append(container)
 else:
  old=find(oldBoards,slot);container=E.SubElement(boards,'Item',{'class':'Model','referent':f'RevisedService{serial}'})
  p=E.SubElement(container,'Properties');E.SubElement(p,'string',name='Name').text=slot+'BoardStand'
 for index,original in enumerate(native.findall('Item')):
  _,pos,matrix=pose(original)
  if (pos[0]<0)!=(cx<0):continue
  key=name(original)
  if kind=='Ranking' and key in ('RankingHeader','Divider','ListSlot'):continue # Real ranking GUI supplies all text/rows.
  n=copy.deepcopy(original);n.set('referent',f'ApprovedService{serial}_{index}')
  local=pos-np.array([cx,0,0]);transform(n,center+rot@local,rot@matrix)
  if kind=='Ranking' and key=='RankingBoardFace':
   n.set('referent',old.get('referent'));n.find("Properties/string[@name='Name']").text=slot
   for gui in old.findall('Item'):n.append(copy.deepcopy(gui))
   # RecordService still uses Leaderboards.Distance/Income.Ranking.* paths.
   parent=boards
  else:parent=container
  if kind=='Shop' and key=='ShopSignFace':
   n.find("Properties/string[@name='Name']").text='ShopSign'
   for gui in find(old,'ShopSign').findall('Item'):n.append(copy.deepcopy(gui))
  flag(n,'CanCollide',key not in ('RoofCourse','GoldRidge','FlowerLeaves','Flower','ShopSignFace','RankingBoardFace'))
  parent.append(n);installed.append(n)

for slot in ('Distance','Income'):
 old=find(oldBoards,slot);new=find(boards,slot)
 assert [E.tostring(n) for n in old.findall('Item')]==[E.tostring(n) for n in new.findall('Item')],'ranking GUI changed'
 assert find(find(new,'Ranking'),'Entries') is not None
 assert find(find(new,'Ranking'),'Heading') is not None
for slot in ('Shop_1','Shop_2'):
 old=find(find(oldShops,slot),'ShopSign');new=find(find(shops,slot),'ShopSign')
 assert [E.tostring(n) for n in old.findall('Item')]==[E.tostring(n) for n in new.findall('Item')]
for key,value in saved.items():assert E.tostring(find(lobby,key))==value,key
for n in installed:
 _,pos,rot=pose(n);pos[0]-=6000
 size=np.array([float(n.findtext(f"Properties/Vector3[@name='size']/{a}")) for a in 'XYZ'])
 for sx,sz in itertools.product((-1,1),repeat=2):
  q=pos+rot@np.array([sx*size[0]/2,0,sz*size[2]/2])
  assert np.linalg.norm(q[[0,2]])>70 and np.linalg.norm(q[[0,2]])<116,'service overlaps central gardens or ranch entrance'
  for i in range(8):
   a=i*math.pi/4;along=q[0]*math.sin(a)+q[2]*math.cos(a);cross=q[0]*math.cos(a)-q[2]*math.sin(a)
   assert not (31<along<129 and abs(cross)<6),'service blocks main path'
for tree,child in ((before,oldLobby),(after,lobby)):
 parent=next(n for n in tree.iter('Item') if child in list(n));parent.remove(child)
assert E.tostring(before)==E.tostring(after)
parent.append(lobby)
refs=[n.get('referent') for n in after.iter('Item')];assert len(refs)==len(set(refs))
assert all(n.text in set(refs) or n.text in ('null','nil',None) for n in after.iter('Ref'))
meshCount=sum(n.get('class')=='MeshPart' for n in after.iter('Item'))
assert meshCount==sum(n.get('class')=='MeshPart' for n in before.iter('Item'))
# Approved outer gate goes between ranches, inside the perimeter.
for old in list(lobby.findall('Item')):
 if name(old)=='OuterGatewayGarden':lobby.remove(old)
gateway=E.parse(R/'dist/ReviewModels/LobbyGatewayReview.rbxmx').getroot().find('Item')
container=E.SubElement(lobby,'Item',{'class':'Model','referent':'ApprovedOuterGate'})
p=E.SubElement(container,'Properties');E.SubElement(p,'string',name='Name').text='OuterGatewayGarden'
a=math.radians(22.5);co,si=math.cos(a),math.sin(a)
rotation=np.array([[co,0,si],[0,1,0],[-si,0,co]])
center=np.array([6000+si*231,0,co*231])
for index,original in enumerate(gateway.findall('Item')):
 if name(original)=='ReviewGround':continue
 n=copy.deepcopy(original);n.set('referent',f'ApprovedOuterGate{index}')
 # Trim the outer end of the level paving to stop inside the enclosure.
 if name(n)=='OpenLevelWalk':n.find("Properties/Vector3[@name='size']/Z").text='68'
 _,pos,matrix=pose(n);transform(n,center+rotation@pos,rotation@matrix)
 key=name(n)
 flag(n,'CanCollide',key not in ('Flowers','Leaves','WaterRill','ArchGoldInset','CrestInset','Lamp'))
 container.append(n)
 # Explicit 3D separating-axis bounds against each existing ranch's footprint.
 _,pos,matrix=pose(n)
 size=np.array([float(n.findtext(f"Properties/Vector3[@name='size']/{q}")) for q in 'XYZ'])
 corners=np.array(list(itertools.product((-1,1),repeat=3)))*size/2@matrix.T+pos
 assert abs(corners[:,0]-6000).max()<250 and abs(corners[:,2]).max()<250,'gateway outside island'
 if corners[:,1].min()>8:continue
 for i in range(8):
  angle=i*math.pi/4;cs,sn=math.cos(angle),math.sin(angle)
  pr=np.array([[cs,0,sn],[0,1,0],[-sn,0,cs]])
  pc=np.array([6000+sn*175,0,cs*175])
  # Project all corners onto ranch axes; no low decor may enter its 83x99 base.
  local=(corners-pc)@pr
  assert local[:,0].min()>41.5 or local[:,0].max()<-41.5 or local[:,2].min()>49.5 or local[:,2].max()<-49.5, f'gateway overlaps ranch {i+1}: {key}'
repair_duplicate_unique_ids(after)
from place_identity import assert_unique_ids
assert_unique_ids(after)
out=args.output;E.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
print(f'SERVICES_APPLY_PASS: {len(installed)} service parts + {len(container.findall("Item"))} gateway parts, clear walks, preserved gardens/32 pens/{meshCount} meshes; {out}')
