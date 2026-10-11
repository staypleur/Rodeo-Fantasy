"""Build a guarded partial Studio update; never rebuild the user's place."""
from pathlib import Path
import subprocess
import json
from build_mossrat_s3_connection import long
r=Path(__file__).resolve().parents[1]
paths=['src/client/RideAnimator.luau','src/server/LobbyCompanions.luau','src/server/CaptureServer.server.luau','src/server/RocketDepartureService.luau','src/shared/DepartureSelectionRules.luau','src/client/PetPromptUI.luau','src/client/UserMossratRigAnimator.luau','src/client/HuntEffects.luau','src/client/RocketDeparture.client.luau','src/client/HudIcons.luau','src/client/BagUI.luau']
code='''assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local P=game.ReplicatedStorage.RodeoFantasy
local SS=game.ServerStorage
local client=game.StarterPlayer.StarterPlayerScripts
local changes={}
local function plan(parent,name,before,after)
 local node=assert(parent:FindFirstChild(name),name)
 assert(node.Source:gsub("\\r\\n","\\n")==before or node.Source:gsub("\\r\\n","\\n")==after,"Changed source: "..name)
 table.insert(changes,{node=node,after=after})
end
'''
for path in paths:
    key=Path(path).name.replace('.client.luau','').replace('.server.luau','').replace('.luau','')
    parent='client' if '/client/' in path else 'P' if '/shared/' in path else 'game.ServerScriptService'
    before=subprocess.check_output(['git','show','f90f43c:'+path],cwd=r).decode().replace('\r\n','\n')
    code+=f'plan({parent},{json.dumps(key)},{long(before)},{long((r/path).read_text(encoding="utf8"))})\n'
code+='''local backup=Instance.new("Folder") backup.Name="LobbyRideBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=SS
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby riding")
for _,c in ipairs(changes) do c.node:Clone().Parent=backup end
local rules=P:FindFirstChild("LobbyRideRules") or Instance.new("ModuleScript") rules.Name="LobbyRideRules"
'''
code+='rules.Source='+long((r/'src/shared/LobbyRideRules.luau').read_text(encoding='utf8'))+' rules.Parent=P\n'
code+='''for _,c in ipairs(changes) do c.node.Source=c.after end
for stage,height in pairs({[3]=4.25,[6]=7}) do
 for _,target in ipairs({{P,"VisualTemplate_S"..stage},{P,"MeshyMossratHuntTemplate_S"..stage},{SS,"RodeoMonsterTemplate_S"..stage}}) do
  local model=assert(target[1]:FindFirstChild(target[2]),target[2])
  if model:GetAttribute("LobbySizeRevision")~="PlayerRelativeV1" then
   model:Clone().Parent=backup
   local body=assert(model:FindFirstChild("Body")) local factor=height/body.Size.Y
   local rest=model.PrimaryPart.CFrame:ToObjectSpace(body.CFrame)
   local rootHeight=2.05*({[3]=1.4,[6]=1.9})[stage]
   body.Size*=factor
   for _,bone in ipairs(body:GetDescendants()) do if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*factor)*bone.CFrame.Rotation end end
   rest=CFrame.new(rest.X*factor,height/2-rootHeight,rest.Z*factor)*rest.Rotation
   body.CFrame=model.PrimaryPart.CFrame*rest body:SetAttribute("ApprovedRest",rest) body:SetAttribute("ApprovedPivot",rest.Position)
   model:SetAttribute("MossratRigTranslationScale",model:GetAttribute("MossratRigTranslationScale")*factor)
   model:SetAttribute("MeshyBackHeight",(model:GetAttribute("MeshyBackHeight") or height*.6)*factor)
   model:SetAttribute("LobbySizeRevision","PlayerRelativeV1")
   model:SetAttribute("MeshyFacingRevision",(model:GetAttribute("MeshyFacingRevision") or "").."-SizeV1")
  end
 end
end
P:SetAttribute("RideButtonImage","rbxassetid://120607489729893")
P:SetAttribute("MossratFaceImage","rbxassetid://97843855045095")
P:SetAttribute("ClockImage","rbxassetid://77808310736115")
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby riding installed")
print("LOBBY_RIDE_UPDATE_INSTALLED",#changes,"modules; S3 4.25; S6 7")
'''
(r/'dist/ReviewModels/LobbyRide.commandbar.lua').write_text(code,encoding='utf8')
