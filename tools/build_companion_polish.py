"""Update only reviewed sources; never recreate the user's saved scene."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
paths=[
 'src/server/CaptureServer.server.luau','src/server/LobbyCompanions.luau','src/server/LobbyWorld.luau',
 'src/server/LobbyAppearance.luau','src/server/RecordService.luau','src/client/PetPromptUI.luau',
 'src/client/UserMossratRigAnimator.luau','src/client/HuntEffects.luau','src/client/JournalUI.luau',
 'src/client/RocketDeparture.client.luau','src/client/LocalizationController.luau','src/shared/Config.luau',
 'src/shared/HuntRules.luau','src/shared/Localization.luau','src/shared/RecordRules.luau','src/shared/PlanetCatalog.luau']
def long(s):return '[========['+s+']========]'
code='''do
assert(not game:GetService("RunService"):IsRunning(),"Play 중지")
local package=game.ReplicatedStorage.RodeoFantasy
local changes={
'''
for path in paths:
 p=Path(path);name=p.name.replace('.server.luau','').replace('.client.luau','').replace('.luau','')
 parent='game.ServerScriptService' if '/server/' in path else 'game.StarterPlayer.StarterPlayerScripts' if '/client/' in path else 'package'
 old=subprocess.run(['git','show','743aa51:'+path],cwd=R,capture_output=True)
 code+='{name="'+name+'",parent='+parent+',kind="'+('Script' if '.server.' in path else 'LocalScript' if '.client.' in path else 'ModuleScript')+'",before='+long(old.stdout.decode())+',after='+long((R/path).read_text(encoding='utf8'))+'},\n'
code+='''}
local function normal(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name)
 if c.node then assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"코드 불일치: "..c.name)
 else assert(c.before=="","코드 없음: "..c.name) end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before companion polish")
local backup=Instance.new("Folder") backup.Name="CompanionPolishBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do
 if c.node then c.node:Clone().Parent=backup else c.node=Instance.new(c.kind) c.node.Name=c.name c.node.Parent=c.parent end
 c.node.Source=c.after
end
-- The prior effect is retained in the reversible backup.
local aura=workspace.RodeoLobby:FindFirstChild("PlanetAura") if aura then aura.Parent=backup end
local appearance=(function()
'''+(R/'src/server/LobbyAppearance.luau').read_text(encoding='utf8')+'''
end)()
appearance.ensure(workspace.RodeoLobby)
package:SetAttribute("GreenStarImage","rbxassetid://78730064656056")
workspace.RodeoLobby.Leaderboards.Distance.Ranking.Heading.Text="Green Star · Distance Top 10"
workspace.RodeoLobby.Leaderboards.Distance.RankingBack.Heading.Text="Green Star · Distance Top 10"
for _,p in ipairs(game.Players:GetPlayers()) do local h=p.Character and p.Character:FindFirstChild("AstronautHelmet") if h then h.Parent=backup end end
game:GetService("ChangeHistoryService"):SetWaypoint("Companion polish installed")
print("COMPANION_POLISH_INSTALLED")
end
'''
(R/'dist/PolishCompanion.commandbar.lua').write_text(code,encoding='utf8')
print('COMPANION_POLISH_BUILT')
