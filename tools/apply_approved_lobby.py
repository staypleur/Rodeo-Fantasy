"""Apply approved journal/bag and startup whale modules to a separate playable place."""
from pathlib import Path
import copy,argparse
import xml.etree.ElementTree as E
import patch_nameplate_place as P
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1]
P.SOURCES={'CaptureClient':R/'src/client/CaptureClient.client.luau','SkyWhaleMotion':R/'src/client/SkyWhaleMotion.luau'}
P.SOURCES['CaptureServer']=R/'src/server/CaptureServer.server.luau'
P.SOURCES['HuntWorld']=R/'src/server/HuntWorld.luau'
P.SOURCES['CourseGeometry']=R/'src/shared/CourseGeometry.luau'
P.SOURCES['MonsterCatalog']=R/'src/shared/MonsterCatalog.luau'
P.SOURCES['HuntRules']=R/'src/shared/HuntRules.luau'
parser=argparse.ArgumentParser()
parser.add_argument('--output',type=Path,default=R/'dist/RodeoFantasy-ApprovedLobby.rbxlx')
args=parser.parse_args()
out=args.output
for name in ('RideAnimator','CreatureMesh','FacetedMouse','FacetedMouseData','MonsterPortrait','CrashEffect','JournalUI','BagUI'):
 P.SOURCES[name]=R/f'src/client/{name}.luau'
P.patch(R/'dist/RodeoFantasy-JournalBagReview.rbxlx',out)
root=E.parse(out).getroot();before=copy.deepcopy(root)
client=next(n for n in root.iter('Item') if n.findtext("Properties/string[@name='Name']")=='CaptureClient')
parent=next(n for n in root.iter('Item') if client in list(n))
added=[]
for name in ('SkyWhaleData','SkyWhaleRuntime','OperatorPrompt'):
 assert not any(n.findtext("Properties/string[@name='Name']")==name for n in parent.findall('Item'))
 node=E.SubElement(parent,'Item',{'class':'ModuleScript','referent':'ApprovedRegal'+name})
 props=E.SubElement(node,'Properties');E.SubElement(props,'string',name='Name').text=name
 E.SubElement(props,'ProtectedString',name='Source').text=(R/f'src/client/{name}.luau').read_text(encoding='utf-8')
 added.append((parent,node))
server=next(n for n in root.iter('Item') if n.findtext("Properties/string[@name='Name']")=='CaptureServer')
server_parent=next(n for n in root.iter('Item') if server in list(n))
for name in ('OperatorCommands','OperatorAuth','OperatorSettings','OperatorSha256'):
 node=E.SubElement(server_parent,'Item',{'class':'ModuleScript','referent':'OwnerOnly'+name})
 props=E.SubElement(node,'Properties');E.SubElement(props,'string',name='Name').text=name
 E.SubElement(props,'ProtectedString',name='Source').text=(R/f'src/server/{name}.luau').read_text(encoding='utf-8')
 added.append((server_parent,node))
assert_unique_ids(root)
for container,node in added:container.remove(node)
assert E.tostring(root)==E.tostring(before),'saved lobby, boarding, ranches or assets changed'
for container,node in added:container.append(node)
E.ElementTree(root).write(out,encoding='utf-8',xml_declaration=True)
assert_unique_ids(E.parse(out).getroot())
print('APPROVED_LOBBY_PASS: journal/bag/names/hunt fixes plus automatic four-mesh whale; all saved assets/boarding/ranches preserved; UniqueIds valid')
