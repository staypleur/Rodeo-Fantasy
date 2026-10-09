"""Preserve imported assets, patch local audio, and add the client settings module."""
from pathlib import Path
import xml.etree.ElementTree as ET
import patch_nameplate_place as patcher
ROOT=Path(__file__).resolve().parents[1]
patcher.SOURCES={
 'AudioPresentation':ROOT/'src/client/AudioPresentation.luau',
 'CaptureClient':ROOT/'src/client/CaptureClient.client.luau',
 'Localization':ROOT/'src/shared/Localization.luau',
}
def main():
 temporary=ROOT/'.tools/settings-sourcepatched.rbxlx'
 patcher.patch(ROOT/'dist/RodeoFantasy-HuntAudio.rbxlx',temporary)
 before=ET.parse(temporary).getroot();after=ET.fromstring(ET.tostring(before))
 parents=[n for n in after.iter('Item') if n.get('class')=='StarterPlayerScripts']
 assert len(parents)==1
 assert not any(n.findtext("Properties/string[@name='Name']")=='SettingsUI' for n in after.iter('Item'))
 module=ET.SubElement(parents[0],'Item',{'class':'ModuleScript','referent':'RBXLocalAudioSettings'})
 props=ET.SubElement(module,'Properties')
 ET.SubElement(props,'string',name='Name').text='SettingsUI'
 source=(ROOT/'src/client/SettingsUI.luau').read_text(encoding='utf-8')
 ET.SubElement(props,'ProtectedString',name='Source').text=source
 output=ROOT/'dist/RodeoFantasy-AudioSettings.rbxlx'
 ET.ElementTree(after).write(output,encoding='utf-8',xml_declaration=True)
 # Verify the saved file, not just the in-memory edit. Addition is the only other change.
 saved=ET.parse(output).getroot()
 parent=next(n for n in saved.iter('Item') if n.get('class')=='StarterPlayerScripts')
 modules=[n for n in parent.findall('Item') if n.findtext("Properties/string[@name='Name']")=='SettingsUI']
 assert len(modules)==1 and modules[0].findtext("Properties/ProtectedString[@name='Source']")==source
 parent.remove(modules[0]);assert ET.tostring(before)==ET.tostring(saved)
 print('SETTINGS_PLACE_PASS: 3 source updates + 1 client module; every other saved property and asset preserved')
if __name__=='__main__':main()
