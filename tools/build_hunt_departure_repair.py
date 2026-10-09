"""Patch the open Studio place without reimporting or moving installed models."""
from pathlib import Path
import xml.etree.ElementTree as E
from model_export import export_model
R=Path(__file__).resolve().parents[1]
code=['assert(not game:GetService("RunService"):IsRunning(),"■ 정지 후 실행하세요.")',
 'local server=game:GetService("ServerScriptService")',
 'local storage=game:GetService("ServerStorage")',
 'local package=game:GetService("ReplicatedStorage").RodeoFantasy',
 'local updates={}']
for name,file in [('CaptureServer','CaptureServer.server.luau'),('HuntWorld','HuntWorld.luau')]:
 source=(R/'src/server'/file).read_text(encoding='utf-8')
 assert ']====]' not in source
 code.append(f'updates[#updates+1]={{node=assert(server:FindFirstChild("{name}"),"Missing {name}"),source=[====[{source}]====]}}')
repair=(R/'src/authoring/HuntTemplateRepair.luau').read_text(encoding='utf-8')
code.extend(['local once=Instance.new("ModuleScript") once.Name="HuntTemplateRepairOnce" once.Parent=package',
 'once.Source=[====['+repair+']====]',
 'local ok,err=pcall(function() require(once).apply() end)',
 'once:Destroy() assert(ok,err)', '''local template=storage.RodeoMonsterTemplate
template.Archivable=true
for _,node in ipairs(template:GetDescendants()) do node.Archivable=true end
for _,entry in ipairs(updates) do entry.node.Source=entry.source end
print("HUNT_DEPARTURE_REPAIRED: Ctrl+S로 저장 후 Play에서 중앙 발판 E 출발을 확인하세요.")'''])
(R/'dist/ModelRecovery/RepairHuntDeparture.commandbar.lua').write_text('\n'.join(code),encoding='utf-8')
print('HUNT_DEPARTURE_REPAIR_BUILT')
# Export only the approved detailed Model from the saved local working file.
# No server code, configuration or operator credentials enter this artifact.
saved=R/'dist/LocalOperator/RodeoFantasy-Social-Operator-Hatchery.rbxlx'
if saved.exists():
 import copy
 tree=E.parse(saved)
 candidates=[n for n in tree.getroot().iter('Item') if n.findtext("Properties/string[@name='Name']")=='VisualTemplate']
 assert len(candidates)==1
 detail=copy.deepcopy(candidates[0])
 assert detail.get('class')=='Model' and any(n.get('class')=='MeshPart' for n in detail.iter('Item'))
 assert not any(n.get('class') in ('Script','LocalScript','ModuleScript') for n in detail.iter('Item'))
 detail.find("Properties/string[@name='Name']").text='RecoveryMossratDetailTemplate'
 document=export_model(tree.getroot(),detail,'RecoveryMossratDetailTemplate')
 E.ElementTree(document).write(R/'dist/ModelRecovery/Mossrat_S1_Detail_Restore.rbxmx',encoding='utf-8',xml_declaration=True)
 print('DETAIL_TEMPLATE_EXPORTED: approved native mesh, bones and PBR only')
# Update only shared review files. Never rewrite the user's private working place.
for label in ('Hatchery','Cafe'):
 path=R/f'dist/RodeoFantasy-Social-{label}.rbxlx'
 tree=E.parse(path)
 for item in tree.getroot().iter('Item'):
  name=item.findtext("Properties/string[@name='Name']")
  file={'CaptureServer':'CaptureServer.server.luau','HuntWorld':'HuntWorld.luau'}.get(name)
  if file and item.get('class') in ('Script','ModuleScript'):
   item.find("Properties/ProtectedString[@name='Source']").text=(R/'src/server'/file).read_text(encoding='utf-8')
 tree.write(path,encoding='utf-8',xml_declaration=True)
