"""Generate a narrow, reversible HUD patch without touching the user's map."""
from pathlib import Path
import json, subprocess
R=Path(__file__).resolve().parents[1]
long=lambda s:'[========['+s+']========]'
rows=[]
for name in ['HudIcons','HudStats','LobbyMenus','BagUI']:
    path='src/client/'+name+'.luau'
    after=(R/path).read_text(encoding='utf-8')
    allowed=[after]
    for rev in ['178ee8a','65aaf04','bb07b75','0c0f1db','57d4c74','78cb6bc','cbbb822','b0c9be0','58bd747','e21ed7d']:
        old=subprocess.run(['git','show',rev+':'+path],cwd=R,capture_output=True)
        if old.returncode==0: allowed.append(old.stdout.decode('utf-8'))
    rows.append('{name='+json.dumps(name)+',after='+long(after)+',allowed={'+','.join(long(s) for s in allowed)+'}}')
code='''assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local package=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"RodeoFantasy 없음")
local changes={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 c.node=assert(clients:FindFirstChild(c.name),"코드 없음: "..c.name)
 assert(c.node:IsA("ModuleScript"),"종류 불일치: "..c.name)
 local valid=false for _,s in ipairs(c.allowed) do if norm(s)==norm(c.node.Source) then valid=true break end end
 assert(valid,"다른 코드가 있어 중단: "..c.name) c.before=c.node.Source
end
local oldId=package:GetAttribute("PawButtonImage")
local backup=Instance.new("Folder") backup.Name="HudArtworkBackup_"..game:GetService("HttpService"):GenerateGUID(false)
if oldId~=nil then backup:SetAttribute("OriginalPawButtonImage",oldId) end
for _,c in ipairs(changes) do c.node:Clone().Parent=backup end
game:GetService("ChangeHistoryService"):SetWaypoint("Before HUD artwork fix")
local ok,err=pcall(function()
 backup.Parent=game:GetService("ServerStorage")
 for _,c in ipairs(changes) do c.node.Source=c.after end
 if oldId==nil or oldId=="" or oldId=="rbxassetid://0" or oldId=="rbxassetid://8596625063532" then
  package:SetAttribute("PawButtonImage","rbxassetid://85966265063532")
 end
end)
if not ok then
 for _,c in ipairs(changes) do c.node.Source=c.before end
 package:SetAttribute("PawButtonImage",oldId) backup:Destroy() error("HUD 복구 완료: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("HUD artwork fixed")
print("HUD_ARTWORK_FIX_INSTALLED — Ctrl+S 저장 후 Play. 이미지 로딩 중에도 발자국 버튼을 표시합니다.")
'''
(R/'dist/FixHudArtwork.commandbar.lua').write_text(code,encoding='utf-8')
print('HUD_ARTWORK_FIX_BUILT')
