"""Catch missing SharedStrings that make a well-formed XML model unreadable."""
from pathlib import Path
import copy,sys,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'tools'))
from model_export import export_model,validate_model

source=E.fromstring('''<roblox version="4"><Item class="Model" referent="model"><Properties><string name="Name">VisualTemplate</string><SharedString name="ModelMeshData">geometry</SharedString><Ref name="PrimaryPart">body</Ref></Properties><Item class="MeshPart" referent="body"><Properties><string name="Name">Body</string><SharedString name="Tags">empty</SharedString></Properties></Item></Item><SharedStrings><SharedString md5="geometry">Z2VvbWV0cnk=</SharedString><SharedString md5="empty"></SharedString><SharedString md5="unrelated">cHJpdmF0ZQ==</SharedString></SharedStrings></roblox>''')
result=export_model(source,source.find('Item'),'RecoveryMossratDetailTemplate')
assert {x.get('md5') for x in result.findall('SharedStrings/SharedString')}=={'geometry','empty'}
assert source.findtext("Item/Properties/string[@name='Name']")=='VisualTemplate'
broken=copy.deepcopy(result)
broken.remove(broken.find('SharedStrings'))
try: validate_model(broken)
except AssertionError: pass
else: raise AssertionError('Dangling shared-string references accepted')
artifact=E.parse(R/'dist/ModelRecovery/Mossrat_S1_Detail_Restore.rbxmx').getroot()
validate_model(artifact)
assert len(artifact.findall('SharedStrings/SharedString'))==2
items=list(artifact.iter('Item'))
assert any(x.get('class')=='MeshPart' for x in items)
assert sum(x.get('class')=='Bone' for x in items)>=4
assert any(x.findtext("Properties/string[@name='Name']")=='MountRoot' for x in items)
print('DETAIL_MODEL_EXPORT_PASS: referenced data included, unrelated data excluded, missing table rejected; native mesh/bones/root preserved')
