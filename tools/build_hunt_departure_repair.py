"""Patch the open Studio place without reimporting or moving installed models."""
from pathlib import Path
import xml.etree.ElementTree as E
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
code.extend(['''local template=storage:FindFirstChild("RodeoMonsterTemplate")
if not template then
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터용 모스랫 설치본을 찾지 못했습니다.")
 approved.Archivable=true
 for _,node in ipairs(approved:GetDescendants()) do node.Archivable=true end
 template=assert(approved:Clone()) template.Name="RodeoMonsterTemplate" template.Parent=storage
end
assert(template:IsA("Model") and template.PrimaryPart,"사냥터 템플릿에 루트가 없습니다.")
template.Archivable=true
for _,node in ipairs(template:GetDescendants()) do node.Archivable=true end
for _,entry in ipairs(updates) do entry.node.Source=entry.source end
print("HUNT_DEPARTURE_REPAIRED: Ctrl+S로 저장 후 Play에서 중앙 발판 E 출발을 확인하세요.")'''])
(R/'dist/ModelRecovery/RepairHuntDeparture.commandbar.lua').write_text('\n'.join(code),encoding='utf-8')
print('HUNT_DEPARTURE_REPAIR_BUILT')
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
