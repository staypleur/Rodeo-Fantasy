local server=Instance.new("Script") server.Name="HerdPlayServer"
server.Source=[==[
local World=require(game.ServerScriptService.HuntWorld)
-- Keep the player alive to inspect the whole course; NPC obstacle avoidance stays real.
World.hit=function() return false end
World.mountedHit=function() return nil end
World.crateHit=function() return false end
local remote=Instance.new("RemoteFunction") remote.Name="HerdPlayDriver" remote.Parent=game.ReplicatedStorage
remote.OnServerInvoke=function(player,action,value)
 if action=="Start" then player.Character.HumanoidRootPart.CFrame=workspace.RodeoLobby.Airport.Departure.CFrame+Vector3.new(0,0,4) return true end
 if action=="Finish" then print("HERD_PLAY_SERVER: "..value) task.defer(function() game:GetService("StudioTestService"):EndTest(value) end) return true end
end
]==] server.Parent=game.ServerScriptService
local client=Instance.new("LocalScript") client.Name="HerdPlayClient"
client.Source=[==[
local player=game.Players.LocalPlayer
local remote=game.ReplicatedStorage.RodeoFantasy.CaptureRemote
local driver=game.ReplicatedStorage:WaitForChild("HerdPlayDriver")
local state={} local minimum=1000 local samples=0
remote.OnClientEvent:Connect(function(kind,data) if kind=="State" then state=data end end)
local ok,err=pcall(function()
 repeat task.wait(.1) until player.Character and player.Character:FindFirstChild("HumanoidRootPart") and state.area=="Lobby"
 driver:InvokeServer("Start") remote:FireServer("Start")
 local untilTime=os.clock()+100
 repeat
  task.wait(.25)
  if state.phase=="Riding" then
   local visible=0
   for _,model in ipairs(workspace.RodeoPrototype.Monsters:GetChildren()) do
    local root=model.PrimaryPart
    if root and model:FindFirstChild("Body") and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") then
     local point,onScreen=workspace.CurrentCamera:WorldToViewportPoint(model.Body.Position)
     if onScreen and point.Z>0 and model.Body.LocalTransparencyModifier<1 and (model.Body.Position-root.Position).Magnitude<5 then visible+=1 end
    end
   end
   minimum=math.min(minimum,visible) samples+=1
   assert(visible>=4,"RENDERED_HERD_LOW distance="..tostring(state.distance).." visible="..visible)
   assert(not player.PlayerGui.RodeoCaptureUI.LobbyStats.Visible,"hunt money must stay hidden")
  end
  assert(os.clock()<untilTime,"herd Play timeout")
 until state.phase=="CourseEnd"
 assert(samples>200,"must inspect the full meadow")
end)
driver:InvokeServer("Finish",ok and ("PASS: rendered herd minimum="..minimum.." samples="..samples) or ("FAIL: "..tostring(err)))
]==] client.Parent=game.StarterPlayer.StarterPlayerScripts
task.wait(2)
local result=game:GetService("StudioTestService"):ExecutePlayModeAsync("HerdCamera")
assert(type(result)=="string" and result:sub(1,5)=="PASS:",tostring(result))
print("HERD_PLAY_RESULT: "..result)
