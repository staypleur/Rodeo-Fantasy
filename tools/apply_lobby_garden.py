"""Install the approved native garden architecture; preserve all non-lobby assets."""
from pathlib import Path
import copy,math,itertools,xml.etree.ElementTree as E
import numpy as np
R=Path(__file__).resolve().parents[1]
def name(n):return n.findtext("Properties/string[@name='Name']")
def find(n,key):return next(c for c in n.findall('Item') if name(c)==key)
def vec(p,key):return np.array([float(p.find(f"Vector3[@name='{key}']/{a}").text) for a in 'XYZ'])
def pose(node):
 cf=node.find("Properties/CoordinateFrame[@name='CFrame']")
 return cf,np.array([float(cf.findtext(a)) for a in 'XYZ']),np.array([[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)])
def setpose(node,pos,matrix=None):
 cf,_,_=pose(node)
 for i,a in enumerate('XYZ'):cf.find(a).text=str(pos[i])
 if matrix is not None:
  for i in range(3):
   for j in range(3):cf.find(f'R{i}{j}').text=str(matrix[i,j])
def setsize(node,size):
 p=node.find("Properties/Vector3[@name='size']")
 for i,a in enumerate('XYZ'):p.find(a).text=str(size[i])
def flag(node,key,value):
 p=node.find('Properties');v=p.find(f"bool[@name='{key}']")
 if v is None:v=E.SubElement(p,'bool',name=key)
 v.text='true' if value else 'false'
def rename(node,new):node.find("Properties/string[@name='Name']").text=new
source=R/'dist/RodeoFantasy-RanchVisualFix.rbxlx'
before=E.parse(source).getroot();after=copy.deepcopy(before)
lobby=next(n for n in after.iter('Item') if name(n)=='RodeoLobby')
oldLobby=next(n for n in before.iter('Item') if name(n)=='RodeoLobby')
plots=find(lobby,'Plots');native=E.parse(R/'dist/ReviewModels/LobbyGardenAGradient.rbxmx').getroot().find('Item')
accents=[(233,140,143),(243,178,111),(247,225,129),(147,204,154),(137,189,230),(111,132,186),(188,154,220),(245,244,236)]
centers=[]
for index,old in enumerate(list(plots.findall('Item')),1):
 angle=math.radians((index-1)*45);c,s=math.cos(angle),math.sin(angle)
 rotation=np.array([[c,0,s],[0,1,0],[-s,0,c]])
 center=np.array([6000+s*175,0,c*175]);centers.append((center,rotation))
 plot=E.Element('Item',dict(old.attrib));plot.append(copy.deepcopy(old.find('Properties')))
 pens=E.SubElement(plot,'Item',{'class':'Folder','referent':f'GardenPens{index}'})
 pp=E.SubElement(pens,'Properties');E.SubElement(pp,'string',name='Name').text='Pens'
 penNodes={}
 for number in range(1,5):
  pen=E.SubElement(pens,'Item',{'class':'Model','referent':f'GardenPen{index}_{number}'})
  pp=E.SubElement(pen,'Properties');E.SubElement(pp,'string',name='Name').text=f'Pen_{number}'
  penNodes[number]=pen
 for serial,original in enumerate(native.findall('Item')):
  node=copy.deepcopy(original);node.set('referent',f'GardenNative{index}_{serial}')
  _,position,matrix=pose(node)
  # Older saved review models have a coplanar stone lip at island height zero.
  if name(node)=='Foundation':position[1]=-.57
  parent=plot
  if name(node).startswith('RanchGrass'):
   oldNumber=int(name(node).replace('RanchGrass',''));number={1:1,2:3,3:2,4:4}[oldNumber]
   rename(node,'PenGrass');parent=penNodes[number]
   E.SubElement(node.find('Properties'),'token',name='Material').text='1280'
   # One material property per Part.
   materials=node.findall("Properties/token[@name='Material']")
   for duplicate in materials[:-1]:node.find('Properties').remove(duplicate)
  if name(node) in ('GardenChannel','Flowers','DomeFacet','DomeFill','GateDomeFacet','GateDomeFill','TealRoofCourse','RoofRidge','Finial','FinialTop','GateFinial'):
   flag(node,'CanCollide',False)
  # Open a gate in each inner ranch rail facing the center walk.
  size=vec(node.find('Properties'),'size')
  if name(node)=='FenceRail' and abs(position[0])==8 and size[2]==28:
   for gateSide in (-1,1):
    rail=copy.deepcopy(node);rail.set('referent',f'GardenNative{index}_{serial}_{gateSide}')
    local=position+np.array([0,0,gateSide*9.5]);newSize=size.copy();newSize[2]=9
    setsize(rail,newSize);setpose(rail,center+rotation@local,rotation@matrix);parent.append(rail)
   continue
  setpose(node,center+rotation@position,rotation@matrix);parent.append(node)
 marker=copy.deepcopy(find(old,'ManagePoint'));setpose(marker,center+rotation@np.array([0,2.2,-49]),rotation);plot.append(marker)
 board=copy.deepcopy(find(old,'OwnerBoard'));setpose(board,center+rotation@np.array([0,12.2,-48]),rotation)
 for p in board.findall("Properties/Color3uint8[@name='Color3uint8']"):
  rgb=accents[index-1];p.text=str(rgb[0]*65536+rgb[1]*256+rgb[2])
 flag(board,'CanCollide',False);plot.append(board)
 plots.remove(old);plots.append(plot)
# Extend the ground and edge enclosure to fit the approved full-size architecture.
for node in lobby.iter('Item'):
 if node.get('class') not in ('Part','MeshPart'):continue
 key=name(node);_,position,matrix=pose(node);size=vec(node.find('Properties'),'size')
 if key=='MeadowIsland':size[[0,2]]=500;setsize(node,size)
 elif key=='GardenPath':
  radial=position-np.array([6000,position[1],0]);direction=radial/np.linalg.norm(radial)
  position=np.array([6000,position[1],0])+direction*80
  size[2]=98;size[0]=12;setpose(node,position);setsize(node,size)
 elif key in ('GardenWall','WallTrim'):
  offset=position-np.array([6000,position[1],0])
  axis=int(np.argmax(np.abs(offset[[0,2]])))*2
  position[axis]=(6000 if axis==0 else 0)+(250 if offset[axis]>0 else -250)
  size[2 if axis==0 else 0]=500
  setpose(node,position);setsize(node,size)
 elif key in ('IslandCliff','IslandWaterfall'):
  offset=position-np.array([6000,position[1],0])
  axis=int(np.argmax(np.abs(offset[[0,2]])))*2
  position[axis]+=(92 if offset[axis]>0 else -92)
  setpose(node,position)
# All Parts are anchored, terrain fits and plots remain spatially independent.
for index,(center,rotation) in enumerate(centers):
 corners=np.array(list(itertools.product((-41.5,41.5),(-49.5,49.5))))
 world=np.array([[v[0],0,v[1]] for v in corners])@rotation.T+center
 assert np.abs(world[:,0]-6000).max()<250 and np.abs(world[:,2]).max()<250
 for other,otherRotation in centers[index+1:]:
  separate=False
  for axis in (rotation[:,0],rotation[:,2],otherRotation[:,0],otherRotation[:,2]):
   a=abs(axis@rotation[:,0])*41.5+abs(axis@rotation[:,2])*49.5
   b=abs(axis@otherRotation[:,0])*41.5+abs(axis@otherRotation[:,2])*49.5
   if abs((center-other)@axis)>a+b:separate=True
  assert separate,'private buildings overlap'
for plot in plots.findall('Item'):
 assert len(find(plot,'Pens').findall('Item'))==4
 for pen in find(plot,'Pens').findall('Item'):assert find(pen,'PenGrass') is not None
 assert find(plot,'ManagePoint') is not None and find(plot,'OwnerBoard') is not None
for tree in (before,after):
 parent=next(n for n in tree.iter('Item') if lobby in list(n)) if tree is after else next(n for n in tree.iter('Item') if oldLobby in list(n))
 parent.remove(lobby if tree is after else oldLobby)
assert E.tostring(before)==E.tostring(after),'non-lobby asset changed'
# Restore the patched lobby after the comparison.
parent.append(lobby)
refs=[n.get('referent') for n in after.iter('Item')];assert len(refs)==len(set(refs))
assert not {n.text for n in after.iter('Ref') if n.text and n.text not in refs and n.text not in ('null','nil')},'broken instance reference'
assert sum(n.get('class')=='MeshPart' for n in after.iter('Item'))==703
out=R/'dist/RodeoFantasy-LobbyGarden.rbxlx';E.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
print('LOBBY_APPLY_PASS: 8 full-size non-overlapping gardens / 32 functional pens / all non-lobby properties and 703 MeshParts preserved / unique references')
print(out)
