"""Apply requested eight roof gradients and remove only the entrance trees."""
from pathlib import Path
import copy,math,xml.etree.ElementTree as E
import numpy as np
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={name:R/f'src/{folder}/{name}{suffix}.luau' for folder,name,suffix in (('shared','Config',''),('server','LobbyWorld',''),('server','CaptureServer','.server'))}
def name(n):return n.findtext("Properties/string[@name='Name']")
def pos(n):
 cf=n.find("Properties/CoordinateFrame[@name='CFrame']");return np.array([float(cf.findtext(a)) for a in 'XYZ'])
patcher.patch(R/'dist/RodeoFantasy-LobbyGarden.rbxlx',R/'.tools/lobby-colors-source.rbxlx')
before=E.parse(R/'.tools/lobby-colors-source.rbxlx').getroot();after=copy.deepcopy(before)
lobby=next(n for n in after.iter('Item') if name(n)=='RodeoLobby');oldLobby=next(n for n in before.iter('Item') if name(n)=='RodeoLobby')
plots=next(n for n in lobby.findall('Item') if name(n)=='Plots')
palette=[((127,45,53),(245,153,144)),((151,79,31),(255,203,132)),((156,128,35),(255,241,158)),((39,101,65),(147,219,164)),((34,86,143),(141,204,251)),((34,44,102),(147,163,225)),((87,46,127),(220,168,243)),((158,170,183),(255,252,237))]
roofNames={'TealRoofCourse','DomeFill','DomeFacet','GateDomeFill','GateDomeFacet'}
for plot in plots.findall('Item'):
 index=int(name(plot).split('_')[-1])-1
 lows,highs=palette[index]
 for n in plot.iter('Item'):
  if name(n) not in roofNames:continue
  y=pos(n)[1];bottom,top=(24.8,29.7) if name(n).startswith('GateDome') else (14,17.9) if name(n).startswith('Dome') else (5.6,8.2) if y<10 else (11.6,14.2)
  t=min(1,max(0,(y-bottom)/(top-bottom)));rgb=[round(a+(b-a)*t) for a,b in zip(lows,highs)]
  n.find("Properties/Color3uint8[@name='Color3uint8']").text=str(rgb[0]*65536+rgb[1]*256+rgb[2])
 centers=[]
 for n in plot.iter('Item'):
  if name(n) in roofNames:centers.append(n.findtext("Properties/Color3uint8[@name='Color3uint8']"))
 assert len(set(centers))>=5,'gradient must contain multiple real roof colors'
# Original lobby decoration trees are at radius145: one centered inside each entry walk.
blocked=[]
for n in lobby.findall('Item'):
 if name(n)!='TreeTrunk':continue
 p=pos(n)
 for i in range(8):
  a=i*math.pi/4;delta=p-np.array([6000+math.sin(a)*175,p[1],math.cos(a)*175])
  x=delta[0]*math.cos(a)-delta[2]*math.sin(a);z=delta[0]*math.sin(a)+delta[2]*math.cos(a)
  if abs(x)<6 and -45<z<-15:blocked.append(p);break
removed=[]
for n in list(lobby.findall('Item')):
 if name(n) not in ('TreeTrunk','TreeCanopy'):continue
 p=pos(n)
 if any(np.linalg.norm((p-b)[[0,2]])<.1 for b in blocked):removed.append(n);lobby.remove(n)
assert len(blocked)==8 and len(removed)==32,'remove exactly eight complete entrance trees'
assert sum(name(n)=='TreeTrunk' for n in lobby.findall('Item'))==8,'keep other original garden trees'
assert sum(name(n)=='TreeTrunk' for n in plots.iter('Item'))==48,'keep personal courtyard trees'
assert sum(name(n)=='PenGrass' for n in plots.iter('Item'))==32,'keep all usable pens'
# No scripts or assets outside the already patched lobby may change.
for tree,removedLobby in ((before,oldLobby),(after,lobby)):
 parent=next(n for n in tree.iter('Item') if removedLobby in list(n));parent.remove(removedLobby)
assert E.tostring(before)==E.tostring(after)
parent.append(lobby)
assert sum(n.get('class')=='MeshPart' for n in after.iter('Item'))==703
out=R/'dist/RodeoFantasy-LobbyColors.rbxlx';E.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
print('LOBBY_COLORS_PASS: eight distinct roof gradients, exactly eight entrance trees removed, remaining trees/32 pens and non-lobby assets preserved')
print(out)
