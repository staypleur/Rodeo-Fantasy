"""Apply approved basket/ladder; preserve airship body and departure references."""
from pathlib import Path
import copy,math,xml.etree.ElementTree as E
import numpy as np
R=Path(__file__).resolve().parents[1]
def name(n):return n.findtext("Properties/string[@name='Name']")
def find(n,key):return next(c for c in n.findall('Item') if name(c)==key)
def pose(n):
 cf=n.find("Properties/CoordinateFrame[@name='CFrame']")
 return cf,np.array([float(cf.findtext(a)) for a in 'XYZ']),np.array([[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)])
def setpose(n,pos,rot):
 cf,_,_=pose(n)
 for i,a in enumerate('XYZ'):cf.find(a).text=str(pos[i])
 for i in range(3):
  for j in range(3):cf.find(f'R{i}{j}').text=str(rot[i,j])
def flag(n,key,value):
 p=n.find('Properties');v=p.find(f"bool[@name='{key}']")
 if v is None:v=E.SubElement(p,'bool',name=key)
 v.text='true' if value else 'false'
before=E.parse(R/'dist/RodeoFantasy-LobbyServices.rbxlx').getroot();after=copy.deepcopy(before)
lobby=next(n for n in after.iter('Item') if name(n)=='RodeoLobby')
airport=find(lobby,'Airport');oldAirport=copy.deepcopy(airport);ship=find(airport,'Airship')
departure=E.tostring(find(airport,'Departure'))
body=[E.tostring(n) for n in ship.findall('Item') if not name(n).startswith('Basket')]
for n in list(ship.findall('Item')):
 if name(n).startswith('Basket'):ship.remove(n)
ladder=copy.deepcopy(find(airport,'BoardingLadder'))
for n in list(airport.findall('Item')):
 if name(n).startswith('Ladder') or name(n) in ('BoardingLadder','BoardingDeck'):airport.remove(n)
model=E.SubElement(airport,'Item',{'class':'Model','referent':'ApprovedBoardingArea'})
p=E.SubElement(model,'Properties');E.SubElement(p,'string',name='Name').text='BoardingArea'
native=E.parse(R/'dist/ReviewModels/LobbyBoardingReview.rbxmx').getroot().find('Item')
for index,original in enumerate(native.findall('Item')):
 if name(original)=='ReviewBase':continue
 n=copy.deepcopy(original);n.set('referent',f'ApprovedBoardingPart{index}')
 _,pos,rot=pose(n);pos[0]+=6000
 # Extend only the four suspension ropes to the current body's underside.
 if name(n)=='Cable':
  pos[1]=26.5
  n.find("Properties/Vector3[@name='size']/Y").text='20'
 setpose(n,pos,rot)
 flag(n,'CanCollide',name(n) not in ('Cable','GoldBinding','PostCap','LadderRail','LadderRung','LadderPeg'))
 (airport if name(n)=='BoardingDeck' else model).append(n)
# Invisible climbable structure aligned behind the visible wooden rungs.
a=math.radians(-31);c,s=math.cos(a),math.sin(a)
rotation=np.array([[1,0,0],[0,c,-s],[0,s,c]])
position=np.array([6000,6.7,10.45])-rotation[:,2]*.85
setpose(ladder,position,rotation)
for axis,value in zip('XYZ',(4,16,2)):ladder.find(f"Properties/Vector3[@name='size']/{axis}").text=str(value)
ladder.find("Properties/float[@name='Transparency']").text='1'
flag(ladder,'CanCollide',True);airport.append(ladder)
assert E.tostring(find(airport,'Departure'))==departure
assert [E.tostring(n) for n in ship.findall('Item')]==body
assert sum(n.get('class')=='TrussPart' for n in airport.iter('Item'))==1
assert len(model.findall('Item'))==113
assert len([n for n in model.findall('Item') if name(n)=='Cable'])==4
# Check the ramp-aligned hidden ladder spans the first/last rungs.
_,climbPos,climbRot=pose(ladder)
for n in model.findall('Item'):
 if name(n)!='LadderRung':continue
 _,pos,_=pose(n);local=climbRot.T@(pos-climbPos)
 assert abs(local[1])<8 and abs(local[2]-1)<.4
deck=find(airport,'BoardingDeck');_,dp,_=pose(deck)
assert dp[1]==13 and dp[2]==6.3
# Retain all other lobby assets and every gameplay script unchanged.
oldLobby=next(n for n in before.iter('Item') if name(n)=='RodeoLobby')
for tree,lob in ((before,oldLobby),(after,lobby)):lob.remove(find(lob,'Airport'))
assert E.tostring(before)==E.tostring(after)
lobby.append(airport)
refs=[n.get('referent') for n in after.iter('Item')];assert len(refs)==len(set(refs))
refset=set(refs);assert all(n.text in refset or n.text in ('null','nil',None) for n in after.iter('Ref'))
assert sum(n.get('class')=='MeshPart' for n in after.iter('Item'))==703
out=R/'dist/RodeoFantasy-LobbyBoarding.rbxlx';E.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
print(f'BOARDING_APPLY_PASS: 114 visible parts, one hidden aligned truss, departure/body/scripts/703 meshes preserved; {out}')
