"""Update current Studio place without overwriting uploaded models or textures."""
from pathlib import Path
import subprocess,json
R=Path(__file__).resolve().parents[1]
def long(s):return '[========['+s+']========]'
rows=[]
for path,parent in [('src/server/HuntWorld.luau','server'),('src/shared/CourseGeometry.luau','shared'),('src/shared/Config.luau','shared'),('src/client/NativeMossrat.luau','clients'),('src/client/UserMossratRigAnimator.luau','clients')]:
 p=R/path;after=p.read_text(encoding='utf-8');allowed=[after]
 for rev in ['78cb6bc','b0c9be0','cbbb822']:
  old=subprocess.run(['git','show',rev+':'+path],cwd=R,capture_output=True)
  if old.returncode==0:allowed.append(old.stdout.decode('utf-8'))
 rows.append('{parent='+parent+',name='+json.dumps(p.stem)+',after='+long(after)+',allowed={'+','.join(long(s) for s in allowed)+'}}')
code='''assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local shared=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"게임 시스템 없음")
local server=game:GetService("ServerScriptService")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"로비 없음")
local changes={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 c.node=assert(c.parent:FindFirstChild(c.name),"모듈 없음: "..c.name)
 assert(c.node:IsA("ModuleScript"),"모듈 종류 불일치")
 local valid=false for _,s in ipairs(c.allowed) do if norm(s)==norm(c.node.Source) then valid=true break end end
 assert(valid,"수정된 코드가 있어 중단했습니다: "..c.name)
 c.before=c.node.Source
end
local old=workspace:FindFirstChild("GreenStar")
local marker=Instance.new("Model") marker.Name="GreenStar"
marker:SetAttribute("LegacyMeadowRestored",true)
local backup=Instance.new("Folder") backup.Name="LegacyHuntBackup_"..game:GetService("HttpService"):GenerateGUID(false)
local ready=lobby:GetAttribute("GreenStarRuntimeReady")
game:GetService("ChangeHistoryService"):SetWaypoint("Before legacy hunt restoration")
local ok,err=pcall(function()
 backup.Parent=game:GetService("ServerStorage")
 for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
 if old then old.Parent=backup end marker.Parent=workspace
 lobby:SetAttribute("GreenStarRuntimeReady",true)
end)
if not ok then
 for _,c in ipairs(changes) do c.node.Source=c.before end
 marker:Destroy() if old then old.Parent=workspace end
 lobby:SetAttribute("GreenStarRuntimeReady",ready) backup:Destroy() error(err)
end
game:GetService("ChangeHistoryService"):SetWaypoint("Legacy hunt and Mossrat facing restored")
print("LEGACY_HUNT_RESTORED — Ctrl+S 저장 후 Play. 중앙 E로 출발하여 맵·정면을 확인하세요.")
'''
(R/'dist/RestoreLegacyHunt.commandbar.lua').write_text(code,encoding='utf-8')
print('LEGACY_HUNT_INSTALLER_BUILT')
