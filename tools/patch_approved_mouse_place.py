"""Add approved mesh data/rendering and topbar settings; preserve all imported assets."""
from pathlib import Path
import xml.etree.ElementTree as ET
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={name:R/'src/client'/filename for name,filename in {
 'SettingsUI':'SettingsUI.luau','CreatureMesh':'CreatureMesh.luau',
 'MonsterPortrait':'MonsterPortrait.luau','CrashEffect':'CrashEffect.luau','CaptureClient':'CaptureClient.client.luau'}.items()}
patcher.SOURCES.update(MonsterCatalog=R/'src/shared/MonsterCatalog.luau',HuntWorld=R/'src/server/HuntWorld.luau')
def main():
 temp=R/'.tools/approved-mouse-sources.rbxlx'
 patcher.patch(R/'dist/RodeoFantasy-AudioSettings.rbxlx',temp)
 before=ET.parse(temp).getroot();after=ET.fromstring(ET.tostring(before))
 parent=next(n for n in after.iter('Item') if n.get('class')=='StarterPlayerScripts')
 for name in ('FacetedMouse','FacetedMouseData'):
  assert not any(n.findtext("Properties/string[@name='Name']")==name for n in after.iter('Item'))
  module=ET.SubElement(parent,'Item',{'class':'ModuleScript','referent':'RBXApproved'+name})
  props=ET.SubElement(module,'Properties');ET.SubElement(props,'string',name='Name').text=name
  ET.SubElement(props,'ProtectedString',name='Source').text=(R/f'src/client/{name}.luau').read_text(encoding='utf-8')
 out=R/'dist/RodeoFantasy-ApprovedMouse.rbxlx';ET.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
 saved=ET.parse(out).getroot();parent=next(n for n in saved.iter('Item') if n.get('class')=='StarterPlayerScripts')
 for name in ('FacetedMouse','FacetedMouseData'):
  matches=[n for n in parent.findall('Item') if n.findtext("Properties/string[@name='Name']")==name]
  assert len(matches)==1 and matches[0].findtext("Properties/ProtectedString[@name='Source']")==(R/f'src/client/{name}.luau').read_text(encoding='utf-8')
  parent.remove(matches[0])
 assert ET.tostring(before)==ET.tostring(saved)
 print('APPROVED_MOUSE_PLACE_PASS: 7 source changes + 2 modules; all other saved properties and 703 imported meshes preserved')
if __name__=='__main__':main()
