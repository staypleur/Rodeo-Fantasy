"""Update the user's open place without replacing uploaded models or textures."""
from pathlib import Path
import subprocess,json
R=Path(__file__).resolve().parents[1]
BASE_REVISION='d1b7826' # The pre-update version used in the user's saved place.
def long(s):return '[======['+s+']======]'
def build():
 paths=['src/shared/Config.luau','src/server/CaptureServer.server.luau','src/server/LobbyWorld.luau','src/server/SpaceLobbyDoors.server.luau','src/server/LobbyCompanions.luau','src/client/RideAnimator.luau','src/client/BagUI.luau','src/client/UserMossratRigAnimator.luau','src/client/CaptureClient.client.luau','src/client/HuntEffects.luau']
 rows=[]
 for path in paths:
  file=R/path;folder=file.parent.name
  name=file.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau')
  kind='Script' if file.name.endswith('.server.luau') else 'LocalScript' if file.name.endswith('.client.luau') else 'ModuleScript'
  target='lobby' if name=='SpaceLobbyDoors' else 'shared' if folder=='shared' else 'server' if folder=='server' else 'clients'
  old=subprocess.run(['git','show',BASE_REVISION+':'+path],cwd=R,capture_output=True)
  before=old.stdout.decode('utf-8') if old.returncode==0 else ''
  rows.append('{parent='+target+',name='+json.dumps(name)+',kind='+json.dumps(kind)+',before='+long(before)+',after='+long(file.read_text(encoding='utf-8'))+'}')
 code='''-- Edit only. Preserves uploaded monster and rocket models and all image IDs.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"RodeoLobby 없음")
local shared=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"RodeoFantasy 없음")
local server=game:GetService("ServerScriptService")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
assert(lobby:FindFirstChild("Plots") and lobby:FindFirstChild("Airport") and workspace:FindFirstChild("GreenStar"),"새 프로젝트 맵이 아닙니다.")
local function normalize(s) return s:gsub("\\r\\n","\\n") end
local changes={
'''+',\n'.join(rows)+'''
}
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name)
 if c.node then
  assert(c.node.ClassName==c.kind,"객체 종류 불일치: "..c.name)
  local source=normalize(c.node.Source)
  assert(source==normalize(c.before) or source==normalize(c.after),"기존 코드가 달라 중단: "..c.name)
 else assert(c.before=="","기존 모듈 없음: "..c.name) end
end
local backup=Instance.new("Folder") backup.Name="LobbyUpdateBackup_"..game:GetService("HttpService"):GenerateGUID(false)
backup.Parent=game:GetService("ServerStorage")
local savedMap=assert(lobby:Clone(),"로비 백업 실패") savedMap.Parent=backup
local installed={}
for _,c in ipairs(changes) do if c.node then c.original=c.node.Source c.node:Clone().Parent=backup end end
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby and hunt update")
local expansion=(function()
'''+(R/'src/authoring/LobbyExpansion.luau').read_text(encoding='utf-8')+'''
end)()
local ok,err=pcall(function()
 for _,c in ipairs(changes) do
  if not c.node then c.node=Instance.new(c.kind) c.node.Name=c.name table.insert(installed,c.node) end
  c.node.Source=c.after c.node.Parent=c.parent
 end
 expansion.run(lobby)
end)
if not ok then
 for _,c in ipairs(changes) do if c.original then c.node.Source=c.original end end
 for _,node in ipairs(installed) do node:Destroy() end
 lobby:Destroy() savedMap.Parent=workspace
 error("업데이트 복구 완료: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby and hunt updated")
print("LOBBY_HUNT_UPDATE_INSTALLED — Ctrl+S로 저장 후 Play. 로켓은 별도 가져오기 필요.")
'''
 (R/'dist/UpdateCurrentProject.commandbar.lua').write_text(code,encoding='utf-8')
 print('CURRENT_PROJECT_UPDATE_BUILT: source preflight, map/source backup, rollback, models preserved')
if __name__=='__main__':build()
