"""Add native Meshy renderer/installer without replacing saved imported geometry."""
from pathlib import Path
import xml.etree.ElementTree as ET
import patch_nameplate_place as patcher
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={'CreatureMesh':R/'src/client/CreatureMesh.luau','MonsterCatalog':R/'src/shared/MonsterCatalog.luau','RideAnimator':R/'src/client/RideAnimator.luau'}
def prepare(source,output):
 temp=R/'.tools/meshy-patched.rbxlx';patcher.patch(source,temp)
 before=ET.parse(temp).getroot();after=ET.fromstring(ET.tostring(before))
 client=next(n for n in after.iter('Item') if n.get('class')=='StarterPlayerScripts')
 rs=next(n for n in after.iter('Item') if n.get('class')=='ReplicatedStorage')
 package=next(n for n in rs.findall('Item') if n.findtext("Properties/string[@name='Name']")=='RodeoFantasy')
 for parent,name,path in [(client,'NativeMossrat','src/client/NativeMossrat.luau'),(package,'MeshyMossratInstaller','src/authoring/MeshyMossratInstaller.luau')]:
  assert not any(n.findtext("Properties/string[@name='Name']")==name for n in after.iter('Item'))
  node=ET.SubElement(parent,'Item',{'class':'ModuleScript','referent':'RBXMeshy'+name})
  props=ET.SubElement(node,'Properties');ET.SubElement(props,'string',name='Name').text=name
  ET.SubElement(props,'ProtectedString',name='Source').text=(R/path).read_text(encoding='utf-8')
 assert_unique_ids(after)
 output.parent.mkdir(parents=True,exist_ok=True);ET.ElementTree(after).write(output,encoding='utf-8',xml_declaration=True)
 # Removing only the two added modules must recover the patched input exactly.
 for parent in (client,package):
  for node in list(parent):
   if node.get('referent') in ('RBXMeshyNativeMossrat','RBXMeshyMeshyMossratInstaller'):parent.remove(node)
 assert ET.tostring(before)==ET.tostring(after)
 print('PASS: saved assets unchanged; unique IDs valid; native renderer and installer embedded')
if __name__=='__main__':
 prepare(R/'dist/RodeoFantasy-LobbyFinal-Operator.rbxlx',R/'dist/RodeoFantasy-MeshyMossrat-Rigged.rbxlx')
 private=R/'dist/LocalOperator/RodeoFantasy-OperatorConfigured.rbxlx'
 if private.exists():prepare(private,R/'dist/LocalOperator/RodeoFantasy-MeshyMossrat-Rigged-Operator.rbxlx')
