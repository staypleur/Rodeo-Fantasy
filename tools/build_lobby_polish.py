"""Narrow update for the saved lobby; never rebuild the user's place file."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def long(s):return '[========['+s+']========]'
paths={'LobbyWorld':'src/server/LobbyWorld.luau','LobbyRankings':'src/server/LobbyRankings.luau',
 'LobbyPresentation':'src/server/LobbyPresentation.server.luau','LobbyCompanions':'src/server/LobbyCompanions.luau',
 'CaptureClient':'src/client/CaptureClient.client.luau','HudIcons':'src/client/HudIcons.luau','HudStats':'src/client/HudStats.luau'}
code='''do
assert(not game:GetService("RunService"):IsRunning(),"Play 중지")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"로비 없음")
local changes={
'''
for name,path in paths.items():
 before=subprocess.check_output(['git','show','bd524e3:'+path],cwd=R).decode('utf-8')
 after=(R/path).read_text(encoding='utf-8')
 code+='{name="'+name+'",before='+long(before)+',after='+long(after)+'},\n'
code+='''}
local function normal(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 local parent=(c.name=="CaptureClient" or c.name=="HudIcons" or c.name=="HudStats") and game.StarterPlayer.StarterPlayerScripts or game.ServerScriptService
 c.node=assert(parent:FindFirstChild(c.name),c.name.." 없음")
 assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"코드 불일치: "..c.name)
end
local backup=Instance.new("Folder") backup.Name="LobbyPolishBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby polish")
for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
local appearance=game.ServerScriptService:FindFirstChild("LobbyAppearance")
if appearance then appearance:Clone().Parent=backup else appearance=Instance.new("ModuleScript") appearance.Name="LobbyAppearance" appearance.Parent=game.ServerScriptService end
appearance.Source='''+long((R/'src/server/LobbyAppearance.luau').read_text(encoding='utf-8'))+'''
local promptSource='''+long((R/'src/client/PetPromptUI.luau').read_text(encoding='utf-8'))+'''
local promptUI=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("PetPromptUI")
if promptUI then assert(normal(promptUI.Source)==normal(promptSource),"PetPromptUI 코드 불일치") else promptUI=Instance.new("ModuleScript") promptUI.Name="PetPromptUI" promptUI.Source=promptSource promptUI.Parent=game.StarterPlayer.StarterPlayerScripts end
local apply=(function()
'''+(R/'src/server/LobbyAppearance.luau').read_text(encoding='utf-8')+'''
end)()
apply.ensure(lobby)
local oldSpace=lobby:FindFirstChild("OverheadSpace") if oldSpace then oldSpace.Parent=backup end
if not lobby:FindFirstChild("BlackSpaceSphere") then
 local outer=Instance.new("Part") outer.Shape=Enum.PartType.Ball outer.Size=Vector3.one*1600 outer.Position=Vector3.new(6000,150,0)
 local inner=outer:Clone() inner.Size=Vector3.one*1580
 local ok,result=pcall(function() return game:GetService("GeometryService"):SubtractAsync(outer,{inner}) end)
 outer:Destroy() inner:Destroy() assert(ok,tostring(result))
 for _,n in ipairs(result) do n.Name="BlackSpaceSphere" n.UsePartColor=true n.Anchored=true n.CanCollide=false n.CanTouch=false n.CanQuery=false n.CastShadow=false n.Color=Color3.new(0,0,0) n.Material=Enum.Material.Neon n.Parent=lobby end
end
if lobby.BlackSpaceSphere:IsA("UnionOperation") then lobby.BlackSpaceSphere.UsePartColor=true end
local rankings=(function()
'''+(R/'src/server/LobbyRankings.luau').read_text(encoding='utf-8')+'''
end)()
for _,n in ipairs(lobby.Leaderboards:GetChildren()) do n:Clone().Parent=backup end
rankings.ensure(lobby)
local package=game.ReplicatedStorage.RodeoFantasy
local ids={ShopButtonImage="135776139567636",RouletteButtonImage="103655794024864",IndexButtonImage="135277525783308",EggButtonImage="87551432940862",PawButtonImage="85966265063532",MossratFaceImage="87383094549038",MoneyImage="71604722538432"}
for key,id in pairs(ids) do package:SetAttribute(key,"rbxassetid://"..id) end
lobby:SetAttribute("LobbyPolishInstalled",true)
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby polish installed")
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(6000,48,-90),Vector3.new(6000,260,60))
workspace.CurrentCamera.Focus=CFrame.new(6000,260,60)
print("LOBBY_POLISH_INSTALLED — 이름·유리천장·검은구·보라오라·이미지7개·카메라·펫·양면랭킹")
end
'''
(R/'dist/PolishLobby.commandbar.lua').write_text(code,encoding='utf-8')
print('LOBBY_POLISH_BUILT')
