"""Update only the index, portrait and HUD modules in an existing Studio place."""
from pathlib import Path
import json,subprocess
R=Path(__file__).resolve().parents[1]
long=lambda s:'[========['+s+']========]'
rows=[]
for name in ['JournalUI','MonsterPortrait','CreatureMesh','NativeMossrat','UserMossratRigAnimator','HudIcons','LobbyMenus','HudStats']:
 path='src/client/'+name+'.luau';after=(R/path).read_text(encoding='utf-8');allowed=[after]
 for rev in ['178ee8a','65aaf04','bb07b75','0c0f1db','57d4c74','78cb6bc','cbbb822','b0c9be0','58bd747']:
  old=subprocess.run(['git','show',rev+':'+path],cwd=R,capture_output=True)
  if old.returncode==0:allowed.append(old.stdout.decode('utf-8'))
 rows.append('{name='+json.dumps(name)+',after='+long(after)+',allowed={'+','.join(long(s) for s in allowed)+'}}')
code='''-- Existing uploaded models and lobby geometry are retained.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local changes={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 c.node=assert(clients:FindFirstChild(c.name),"코드 없음: "..c.name)
 assert(c.node:IsA("ModuleScript"),"종류 불일치: "..c.name)
 local valid=false for _,s in ipairs(c.allowed) do if norm(s)==norm(c.node.Source) then valid=true break end end
 assert(valid,"다른 코드가 있어 중단: "..c.name) c.before=c.node.Source
end
local backup=Instance.new("Folder") backup.Name="IndexUpdateBackup_"..game:GetService("HttpService"):GenerateGUID(false)
for _,c in ipairs(changes) do c.node:Clone().Parent=backup end
game:GetService("ChangeHistoryService"):SetWaypoint("Before index update")
local ok,err=pcall(function()
 backup.Parent=game:GetService("ServerStorage")
 for _,c in ipairs(changes) do c.node.Source=c.after end
end)
if not ok then
 for _,c in ipairs(changes) do c.node.Source=c.before end
 backup:Destroy() error("인덱스 설치 복구 완료: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Index updated")
print("INDEX_UPDATE_INSTALLED — Ctrl+S 저장 후 Play. 왼쪽 인덱스 버튼 또는 T를 누르세요.")
'''
(R/'dist/InstallIndex.commandbar.lua').write_text(code,encoding='utf-8')
print('INDEX_INSTALLER_BUILT')
