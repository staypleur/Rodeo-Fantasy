local Players=game:GetService("Players")
local player=Players.LocalPlayer
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local PPS=game:GetService("ProximityPromptService")
local remote=game.ReplicatedStorage:WaitForChild("RodeoFantasy"):WaitForChild("CaptureRemote")
local gui=Instance.new("ScreenGui") gui.Name="CafeUI" gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=player:WaitForChild("PlayerGui")
local bag=require(script.Parent.BagUI).new(gui,remote)
local journal=require(script.Parent.JournalUI).new(gui,remote)
local social=require(script.Parent.SocialUI).new(gui,remote,bag,journal)
local animator=require(script.Parent.RideAnimator)
local off=Instance.new("TextButton") off.Name="Dismount" off.Text="Q · Dismount" off.AnchorPoint=Vector2.new(.5,1) off.Position=UDim2.new(.5,0,1,-24) off.Size=UDim2.fromOffset(170,45) off.BackgroundColor3=Color3.fromRGB(61,98,72) off.TextColor3=Color3.new(1,1,1) off.TextSize=18 off.Visible=false off.Parent=gui
off.Activated:Connect(function() remote:FireServer("Dismount") end)
bag.onOpen=function() journal.close() end journal.onOpen=function() bag.close() end
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="Bag" then bag.snapshot(data)
 elseif kind=="State" then bag.state(data) journal.state(data) social.state(data) bag.income(data.income)
 elseif kind=="EvolutionResult" then bag.evolutionResult(data)
 elseif kind=="Journal" then journal.snapshot(data)
 else social.event(kind,data) end
end)
PPS.PromptShown:Connect(function(prompt)
 if prompt.Name=="RideOwnMonster" then prompt.Enabled=prompt:FindFirstAncestorOfClass("Model"):GetAttribute("OwnerUserId")==player.UserId
 elseif prompt.Name=="ViewCafeProfile" then prompt.Enabled=Players:GetPlayerFromCharacter(prompt.Parent.Parent)~=player end
end)
PPS.PromptTriggered:Connect(function(prompt)
 if prompt.Name=="ViewCafeProfile" then local other=Players:GetPlayerFromCharacter(prompt.Parent.Parent) if other and other~=player then remote:FireServer("Profile",other.UserId) end end
end)
UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.Q and player:GetAttribute("CafeMounted") then remote:FireServer("Dismount") end end)
local controls=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local sent=0
Run.RenderStepped:Connect(function(dt)
 off.Visible=player:GetAttribute("CafeMounted")==true
 local clock=workspace:GetServerTimeNow() local camera=workspace.CurrentCamera
 local pets=workspace:FindFirstChild("CafePets") if pets then animator.update(pets,clock,camera.CFrame.Position,dt) end
 if player:GetAttribute("CafeMounted") and clock-sent>.08 then
  sent=clock local move=controls:GetMoveVector() local cf=camera.CFrame
  local v=cf.RightVector*move.X+cf.LookVector*(-move.Z) v=Vector3.new(v.X,0,v.Z)
  remote:FireServer("CafeMove",v.Magnitude>1 and v.Unit or v)
 end
end)
remote:FireServer("Sync")
