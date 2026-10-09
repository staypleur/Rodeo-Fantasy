"""Apply approved journal/bag and startup whale modules to a separate playable place."""
from pathlib import Path
import copy
import xml.etree.ElementTree as E
import patch_nameplate_place as P
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1]
P.SOURCES={'CaptureClient':R/'src/client/CaptureClient.client.luau','SkyWhaleMotion':R/'src/client/SkyWhaleMotion.luau'}
out=R/'dist/RodeoFantasy-ApprovedLobby.rbxlx'
P.patch(R/'dist/RodeoFantasy-JournalBagReview.rbxlx',out)
root=E.parse(out).getroot();before=copy.deepcopy(root)
client=next(n for n in root.iter('Item') if n.findtext("Properties/string[@name='Name']")=='CaptureClient')
parent=next(n for n in root.iter('Item') if client in list(n))
added=[]
for name in ('SkyWhaleData','SkyWhaleRuntime'):
 assert not any(n.findtext("Properties/string[@name='Name']")==name for n in parent.findall('Item'))
 node=E.SubElement(parent,'Item',{'class':'ModuleScript','referent':'ApprovedRegal'+name})
 props=E.SubElement(node,'Properties');E.SubElement(props,'string',name='Name').text=name
 E.SubElement(props,'ProtectedString',name='Source').text=(R/f'src/client/{name}.luau').read_text(encoding='utf-8')
 added.append(node)
assert_unique_ids(root)
for node in added:parent.remove(node)
assert E.tostring(root)==E.tostring(before),'saved lobby, boarding, ranches or assets changed'
for node in added:parent.append(node)
E.ElementTree(root).write(out,encoding='utf-8',xml_declaration=True)
assert_unique_ids(E.parse(out).getroot())
print('APPROVED_LOBBY_PASS: journal/bag/names/hunt fixes plus automatic four-mesh whale; all saved assets/boarding/ranches preserved; UniqueIds valid')
