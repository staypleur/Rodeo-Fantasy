"""Build source-guarded shared mobile UI patch; preserve world/user edits."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def q(s):
 e='='
 while ']'+e+']' in s:e+='='
 return '['+e+'['+s+']'+e+']'
rows=[]
for name,path in [('BagUI','src/client/BagUI.luau'),('LobbyMenus','src/client/LobbyMenus.luau'),('HudStats','src/client/HudStats.luau'),('CaptureClient','src/client/CaptureClient.client.luau')]:
 before=subprocess.check_output(['git','show','HEAD:'+path],cwd=R).decode('utf8')
 after=(R/path).read_text(encoding='utf8')
 rows.append('{name='+q(name)+',before='+q(before)+',after='+q(after)+'}')
code='''assert(not game.RunService:IsRunning(),"Stop Play first")
assert(game.GameId==10770388358,"Wrong experience")
local C=game.StarterPlayer.StarterPlayerScripts
local updates={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,u in ipairs(updates) do
 local n=C:FindFirstChild(u.name)
 if u.name~="CaptureClient" or game.PlaceId==131121026461681 then
  assert(n and n:IsA(u.name=="CaptureClient" and "LocalScript" or "ModuleScript"),"Missing "..u.name)
  assert(norm(n.Source)==norm(u.before) or norm(n.Source)==norm(u.after),"Changed source: "..u.name)
  assert(loadstring(u.after),"Compile failed "..u.name)
 end
end
local backup=Instance.new("Folder") backup.Name="MobileUIBackup_"..game.HttpService:GenerateGUID(false) backup.Parent=game.ServerStorage
game.ChangeHistoryService:SetWaypoint("Before mobile UI fix")
local count=0
for _,u in ipairs(updates) do
 if u.name~="CaptureClient" or game.PlaceId==131121026461681 then
  local n=C[u.name] n:Clone().Parent=backup n.Source=u.after count+=1
 end
end
game.ChangeHistoryService:SetWaypoint("Mobile UI fix")
print("MOBILE_UI_INSTALLED",game.PlaceId,count)
'''
(R/'.tools/MobileUI.commandbar.lua').write_text(code,encoding='utf8')
print(len(code))
