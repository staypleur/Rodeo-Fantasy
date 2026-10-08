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
 if obstacles then for _,obstacle in ipairs(obstacles:GetChildren()) do if not obstacle:GetAttribute("TestKeep") then obstacle:Destroy() end end end
 for _,animal in ipairs(workspace.RodeoPrototype.Monsters:GetChildren()) do
  if not animal:GetAttribute("Occupied") and not animal:GetAttribute("TestKeep") then animal:Destroy() end
 end
end)
driver.OnServerInvoke=function(player,action,value)
 if action=="HerdFixture" then
  local z=player.Character.HumanoidRootPart.Position.Z
  local rock=Instance.new("Part") rock.Name="TestRock" rock.Anchored=true rock.CanCollide=false
  rock.Size=Vector3.new(4,3,4) rock.Position=Vector3.new(0,1.5,z-40)
  rock:SetAttribute("TestKeep",true) rock.Parent=workspace.RodeoPrototype.Obstacles
  local animal=world.spawn(Vector3.new(0,2,z+25)) animal:SetAttribute("TestKeep",true)
  return {animal=animal,rock=rock}
 elseif action=="ClearHerdFixture" then
  for _,folder in ipairs({workspace.RodeoPrototype.Monsters,workspace.RodeoPrototype.Obstacles}) do
   for _,node in ipairs(folder:GetChildren()) do if node:GetAttribute("TestKeep") then node:Destroy() end end
  end
  return true
 elseif action=="Target" then
  local root=player.Character.HumanoidRootPart
  local target=world.spawn(Vector3.new(root.Position.X,2,root.Position.Z-3))
  target:SetAttribute("TestKeep",true)
  return target
 elseif action=="Collision" then
  local root=player.Character.HumanoidRootPart
  local blocker=world.spawn(Vector3.new(root.Position.X,2,root.Position.Z-4))
  blocker:SetAttribute("TestKeep",true)
  return blocker
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
 local fixture=driver:InvokeServer("HerdFixture")
 local animal,rock=fixture.animal,fixture.rock
 animal:WaitForChild("Body")
 local bad,renderSamples,low,high=0,0,0,0
 local run=game:GetService("RunService")
 local rules=require(RS.RodeoFantasy.HuntRules)
 local rest=RS.RodeoFantasy.VisualTemplate.Body.CFrame
 run:BindToRenderStep("CheckLiveHerd",Enum.RenderPriority.Last.Value,function()
  if not animal.Parent or not rock.Parent then return end
  local root=animal.PrimaryPart
  if not root then return end
  local frame=animal.Body.CFrame*rest:Inverse()
  local size=rock.Size+root.Size local p=rock.Position
  if rules.sweptBox(frame.X,frame.Y,frame.Z,frame.X,frame.Y,frame.Z,p.X,p.Y,p.Z,size.X,size.Y,size.Z,0) then bad+=1 end
  low,high=math.min(low,root.Position.X),math.max(high,root.Position.X)
  renderSamples+=1
 end)
 waitFor(function() return animal.PrimaryPart and animal.PrimaryPart.Position.Z<rock.Position.Z-15 end,"live herd must go around its rock")
 run:UnbindFromRenderStep("CheckLiveHerd")
 check(renderSamples>0 and bad==0,"networked displayed animal must not pass through its rock")
 check(high-low>3,"networked wild animal must visibly steer around rock")
 driver:InvokeServer("ClearHerdFixture")
 local originalFov=workspace.CurrentCamera.FieldOfView
 remote:FireServer("Start")
 waitFor(function() return state.phase=="Lassoing" end,"opening flight missing")
 waitFor(function() return state.phase=="Riding" end,"opening landing failed")
 waitFor(function() return workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable and workspace.CurrentCamera.CFrame.LookVector.Y < -0.7 end,"angled camera did not activate")
 check(workspace.CurrentCamera.FieldOfView==config.Prototype.CameraFieldOfView,"hunt field of view must apply")
 local camera=workspace.CurrentCamera
 check(math.abs(camera.CFrame.Position.X-config.Prototype.CameraSideStuds)<0.5,"diagonal camera must follow road center")
 if camera.ViewportSize.Y>0 then
  local point,onScreen=camera:WorldToViewportPoint(character.HumanoidRootPart.Position)
  check(onScreen and point.Y/camera.ViewportSize.Y>0.5 and point.Y/camera.ViewportSize.Y<0.8,"rider must be in lower screen with forward road visible")
 end
 check(state.count==0,"bag must start empty")
 local bound=game:GetService("ContextActionService"):GetBoundActionInfo("RodeoJump")
 local spaceBound=false
 for _,key in ipairs(bound.inputTypes or {}) do if key==Enum.KeyCode.Space then spaceBound=true end end
 check(spaceBound,"space key must bind jump/lasso action")
 check(not player.PlayerGui.RodeoCaptureUI.HuntHelp.Visible,"riding must hide bottom explanations")
 waitFor(function() return workspace:FindFirstChild("LocalTamingGaugeAnchor")~=nil end,"mounted gauge missing")
 local mountedGauge=workspace.LocalTamingGaugeAnchor.MountedTamingGauge
 check(mountedGauge.Enabled and mountedGauge.Frame.Heart.Text=="♥","mounted heart gauge must be visible")
 local mountPoint=camera:WorldToViewportPoint(state.monster.PrimaryPart.Position)
 local gaugePoint=camera:WorldToViewportPoint(workspace.LocalTamingGaugeAnchor.Position)
 check(gaugePoint.X<mountPoint.X and gaugePoint.Y>mountPoint.Y,"gauge must stay lower-left of the monster on screen")
 task.wait(0.3)
 local leg=character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
 check(leg and (-leg.CFrame.UpVector):Dot(character.HumanoidRootPart.CFrame.LookVector)>0.6,"mounted thigh must point forward in a seated pose")
 local rope=workspace:FindFirstChild("LocalCowboyLasso")
 check(rope and #rope:GetChildren()==50,"mounted cowboy rope loop missing")
 local point=rope:FindFirstChildOfClass("Attachment")
 local before=point.Position
 waitFor(function() return (point.Position-before).Magnitude>0.2 end,"cowboy rope must spin while riding")
 check((point.Position-before).Magnitude>0.2,"cowboy rope must spin while riding")
 remote:FireServer("Jump")
 waitFor(function() return state.phase=="Airborne" end,"release must jump")
 waitFor(function() return not workspace:FindFirstChild("LocalCowboyLasso") end,"spinning rope must hide on jump")
 check(not workspace:FindFirstChild("LocalCowboyLasso"),"spinning rope must hide during airborne lasso aiming")
 local airX=character.HumanoidRootPart.Position.X
 remote:FireServer("Steer",1)
 local flightSeen=false
 local runService=game:GetService("RunService")
 runService:BindToRenderStep("CheckFlightPose",Enum.RenderPriority.Last.Value,function()
  if state.phase=="Airborne" and character.HumanoidRootPart.CFrame.LookVector.Y<-.3 then flightSeen=true end
 end)
 task.wait(0.08)
 runService:UnbindFromRenderStep("CheckFlightPose")
 check(flightSeen,"airborne character must lean forward when rendered")
 check(math.abs(character.HumanoidRootPart.Position.X-airX)<0.05,"airborne steering must stay locked on client and server")
 check(character.HumanoidRootPart:FindFirstChild("FlightTrailAnchor")~=nil,"flight trail must exist")
 local oldCount=state.count
 local target=driver:InvokeServer("Target")
 task.wait(0.06)
 remote:FireServer("Jump")
 waitFor(function() return state.phase=="Lassoing" end,"lasso failed")
 remote:FireServer("Jump")
 waitFor(function() return state.phase=="Riding" and state.monster==target end,"landing failed")
 check(state.count==oldCount,"old incomplete ride must not grant")
 check(target:GetAttribute("Occupied"),"target must be occupied")
 check(state.dashUntil and state.dashUntil>workspace:GetServerTimeNow(),"switch must start short dash")
 waitFor(function() local a=character.HumanoidRootPart:FindFirstChild("FlightTrailAnchor") return a and a:FindFirstChildOfClass("Trail") and a:FindFirstChildOfClass("Trail").Enabled end,"switch dash must display brief speed trail")
 check(character.HumanoidRootPart.FlightTrailAnchor:FindFirstChildOfClass("Trail").Enabled,"dash trail must appear")
 check(state.protectedUntil>workspace:GetServerTimeNow(),"landing protection missing")
 local worstOffset=0
 local samples=0
 runService:BindToRenderStep("CheckMountAlignment",Enum.RenderPriority.Last.Value,function()
  if state.phase=="Riding" and target:FindFirstChild("Body") then
   local expected=character.HumanoidRootPart.CFrame:VectorToWorldSpace(Vector3.new(0,-config.Prototype.RideHeightStuds-0.05,0.15-config.Prototype.RideForwardStuds))
   local offset=target.Body.Position-character.HumanoidRootPart.Position
   worstOffset=math.max(worstOffset,(offset-expected).Magnitude)
   samples+=1
  end
 end)
 task.wait(0.5)
 runService:UnbindFromRenderStep("CheckMountAlignment")
 check(samples>0 and worstOffset<0.1,"mounted body and avatar must stay aligned across rendered frames")
 check(state.phase=="Riding" and state.monster==target,"early release must not force repeated flights")
 waitFor(function() return state.count==oldCount+1 end,"taming did not grant")
 check(state.tamed and state.phase=="Riding","taming must continue run")
 waitFor(function() return not mountedGauge.Enabled end,"taming must hide the heart gauge")
 check(not mountedGauge.Enabled,"completed taming must remove the heart gauge")
 task.wait(0.8)
 check(state.count==oldCount+1,"taming must not duplicate")
 remote:FireServer("Jump")
 waitFor(function() return state.phase=="GameOver" end,"missed jump must end run")
 check(not character.HumanoidRootPart.Anchored,"end must restore movement")
 waitFor(function() return workspace.CurrentCamera.CameraType~=Enum.CameraType.Scriptable end,"camera must restore")
 check(workspace.CurrentCamera.FieldOfView==originalFov,"field of view must restore")
 remote:FireServer("Start")
 waitFor(function() return state.phase=="Riding" end,"restart failed")
 check(state.count==oldCount+1,"restart must keep bag")
 waitFor(function() return state.angerAt~=nil end,"anger warning missing")
 local angryMonster=state.monster
 waitFor(function() return angryMonster.PrimaryPart:FindFirstChild("AngerWarning")~=nil end,"exclamation missing")
 check(angryMonster.PrimaryPart.AngerWarning.Enabled,"anger exclamation must be visible")
 waitFor(function() return angryMonster:GetAttribute("Angry")==true end,"warning must transition into bucking")
 local lowY,highY=math.huge,-math.huge
 local buckUntil=os.clock()+0.65
 repeat
  local y=angryMonster.PrimaryPart.Position.Y
  lowY,highY=math.min(lowY,y),math.max(highY,y)
  task.wait(0.03)
 until os.clock()>buckUntil
 check(highY-lowY>1,"anger must physically hop repeatedly")
 task.wait(2.3)
 check(state.phase=="Riding" and state.tamed,"tamed monster must keep bucking without automatic ejection")
 check(not mountedGauge.Enabled,"heart must remain hidden during anger after taming")
 remote:FireServer("Jump")
 waitFor(function() return state.phase=="Airborne" end,"space must jump during angry bucking")
 check(state.phase=="Airborne","angry mount must allow voluntary jumping")
 waitFor(function() return state.phase=="GameOver" end,"uncaught jump must end normally")
 check(not character.HumanoidRootPart.Anchored,"missed jump must restore movement")
 remote:FireServer("Start")
 waitFor(function() return state.phase=="Riding" end,"collision test restart failed")
 driver:InvokeServer("Collision")
 waitFor(function() return state.phase=="GameOver" and state.crash end,"monster collision must end the run")
 waitFor(function() return workspace:FindFirstChild("LocalCrashShard")~=nil end,"cartoon body breakup missing")
 check(character.Parent~=nil and character:FindFirstChild("HumanoidRootPart")~=nil,"breakup must preserve real avatar")
 task.wait(1.3)
 check(workspace:FindFirstChild("LocalCrashShard")==nil,"breakup shards must clean up")
 remote:FireServer("Start")
 waitFor(function() return state.phase=="Riding" end,"restart after breakup failed")
 check(character.Head.LocalTransparencyModifier<1,"restart must restore avatar visibility")
end)
driver:InvokeServer("Finish",success and ("PASS: "..checks.." hunting Play checks") or ("FAIL: "..tostring(problem)))
]==]
client.Parent=game:GetService("StarterPlayer").StarterPlayerScripts
-- Let the CLI document finish opening before entering Play.
task.wait(2)
local result=game:GetService("StudioTestService"):ExecutePlayModeAsync("LumidonHunt")
assert(type(result)=="string" and string.sub(result,1,5)=="PASS:","Play did not pass: "..tostring(result))
print("HUNT_PLAY_RESULT: "..result)
