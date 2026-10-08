local RS=game:GetService("ReplicatedStorage")
local driver=Instance.new("RemoteFunction")
driver.Name="HuntTestDriver"
driver.Parent=RS
local server=Instance.new("Script")
server.Name="HuntTestServer"
server.Source=[==[
local RS=game:GetService("ReplicatedStorage")
local service=game:GetService("StudioTestService")
local driver=RS:WaitForChild("HuntTestDriver")
local world=require(script.Parent.HuntWorld)
game:GetService("RunService").Heartbeat:Connect(function()
 local obstacles=workspace.RodeoPrototype:FindFirstChild("Obstacles")
 if obstacles then obstacles:ClearAllChildren() end
end)
driver.OnServerInvoke=function(player,action,value)
 if action=="Target" then
  local root=player.Character.HumanoidRootPart
  return world.spawn(Vector3.new(root.Position.X,2,root.Position.Z-3))
 elseif action=="Finish" then
  print("HUNT_TEST_SERVER_RESULT: "..value)
  task.defer(function() service:EndTest(value) end)
  return true
 end
end
task.delay(45,function() service:EndTest("FAIL: timeout") end)
]==]
server.Parent=game:GetService("ServerScriptService")
local client=Instance.new("LocalScript")
client.Name="HuntTestClient"
client.Source=[==[
local RS=game:GetService("ReplicatedStorage")
local player=game:GetService("Players").LocalPlayer
local remote=RS.RodeoFantasy.CaptureRemote
local driver=RS:WaitForChild("HuntTestDriver")
local config=require(RS.RodeoFantasy.Config)
local state={phase="Idle",count=0}
local checks=0
remote.OnClientEvent:Connect(function(kind,data) if kind=="State" then state=data end end)
local function check(value,message) assert(value,message) checks+=1 end
local function waitFor(predicate,message)
 local untilTime=os.clock()+12
 repeat if predicate() then return end task.wait(0.03) until os.clock()>untilTime
 error(message)
end
local success,problem=pcall(function()
 local character=player.Character or player.CharacterAdded:Wait()
 character:WaitForChild("HumanoidRootPart")
 check(player.PlayerGui:WaitForChild("RodeoCaptureUI",15)~=nil,"UI missing")
 remote:FireServer("Start")
 waitFor(function() return state.phase=="Riding" end,"start failed")
 check(state.count==0,"bag must start empty")
 remote:FireServer("Hold",true)
 task.wait(0.25)
 remote:FireServer("Hold",false)
 waitFor(function() return state.phase=="Airborne" end,"release must jump")
 local oldCount=state.count
 local target=driver:InvokeServer("Target")
 task.wait(0.06)
 remote:FireServer("Hold",true)
 waitFor(function() return state.phase=="Lassoing" or (state.phase=="Riding" and state.monster==target) end,"lasso failed")
 waitFor(function() return state.phase=="Riding" and state.monster==target end,"landing failed")
 check(state.count==oldCount,"old incomplete ride must not grant")
 check(target:GetAttribute("Occupied"),"target must be occupied")
 waitFor(function() return state.count==oldCount+1 end,"taming did not grant")
 check(state.tamed and state.phase=="Riding","taming must continue run")
 task.wait(0.8)
 check(state.count==oldCount+1,"taming must not duplicate")
 remote:FireServer("Hold",false)
 waitFor(function() return state.phase=="GameOver" end,"missed jump must end run")
 check(not character.HumanoidRootPart.Anchored,"end must restore movement")
 remote:FireServer("Start")
 waitFor(function() return state.phase=="Riding" end,"restart failed")
 check(state.count==oldCount+1,"restart must keep bag")
 waitFor(function() return state.angerAt~=nil end,"anger warning missing")
 waitFor(function() return state.phase=="GameOver" end,"anger must buck off")
 check(not character.HumanoidRootPart.Anchored,"buck off must restore movement")
end)
driver:InvokeServer("Finish",success and ("PASS: "..checks.." hunting Play checks") or ("FAIL: "..tostring(problem)))
]==]
client.Parent=game:GetService("StarterPlayer").StarterPlayerScripts
local result=game:GetService("StudioTestService"):ExecutePlayModeAsync("CharmanderHunt")
print("HUNT_PLAY_RESULT: "..tostring(result))
