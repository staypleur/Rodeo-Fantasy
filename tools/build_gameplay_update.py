from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
FILES=['src/client/'+n+'.luau' for n in ['BagUI','IncomeEffects','PetPromptUI']]+['src/shared/'+n+'.luau' for n in ['BagRules','LobbyRideRules','MonsterCatalog','SocialRules']]+['src/server/'+n+'.luau' for n in ['CafeServer.server','CaptureServer.server','HuntWorld','InventoryStore','LobbyCompanions']]
def q(s):
 e='='
 while ']'+e+']' in s:e+='='
 return '['+e+'['+s+']'+e+']'
rows=[]
for f in FILES:
 name=Path(f).stem.replace('.server',''); parent='client' if '/client/' in f else 'package' if '/shared/' in f else 'server'
 old=subprocess.check_output(['git','show','d1b8de6:'+f],cwd=R).decode('utf8');new=(R/f).read_text(encoding='utf8')
 rows.append('{name='+q(name)+',parent='+parent+',optional='+('true' if name in ['CafeServer','CaptureServer','HuntWorld'] else 'false')+',before='+q(old)+',after='+q(new)+'}')
s='''assert(not game:GetService("RunService"):IsRunning(),"Stop Play")
assert(game.GameId==10770388358,"Wrong experience")
local package=game.ReplicatedStorage.RodeoFantasy
local client=game.StarterPlayer.StarterPlayerScripts
local server=game.ServerScriptService
local changes={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name,true)
 if (c.name=="CafeServer" and game.PlaceId~=133084853508719) or ((c.name=="CaptureServer" or c.name=="HuntWorld") and game.PlaceId~=131121026461681) then c.node=nil end
 assert(c.node or c.optional,"Missing "..c.name)
 if c.node then
  assert(c.node:IsA("LuaSourceContainer"),"Unexpected "..c.name)
  assert(norm(c.node.Source)==norm(c.before) or norm(c.node.Source)==norm(c.after) or (c.name=="BagUI" and norm(c.node.Source)==norm((c.after:gsub(' and child.Name~="DiscardMonster"','')))),"Other changes "..c.name)
  assert(loadstring(c.after),"Invalid "..c.name) c.original=c.node.Source
 end
end
local backup=Instance.new("Folder") backup.Name="GameplayUpdateBackup" backup.Archivable=false backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do if c.node then c.node:Clone().Parent=backup end end
game.ChangeHistoryService:SetWaypoint("Before gameplay update")
local ok,err=pcall(function() for _,c in ipairs(changes) do if c.node then c.node.Source=c.after end end end)
if not ok then for _,c in ipairs(changes) do if c.node then c.node.Source=c.original end end error(err) end
game.ChangeHistoryService:SetWaypoint("Gameplay updated")
print("GAMEPLAY_UPDATE_INSTALLED",game.PlaceId)
'''
(R/'dist/GameplayUpdate.commandbar.lua').write_text(s,encoding='utf8')

