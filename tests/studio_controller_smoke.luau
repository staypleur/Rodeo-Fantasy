-- Execute the real controller source with controlled input/clock in Studio edit mode.
-- Uses native Instances/CFrames/world. This does not claim real Play/network/input testing.
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local clock=100
local latest,heartbeat,event
local checks=0
local function signal(callback) return {Connect=function(_,fn) callback(fn) end} end
local character=Instance.new("Model")
character.Name="ControllerTestCharacter"
character.Parent=workspace
local root=Instance.new("Part")
root.Name="HumanoidRootPart"
root.Parent=character
local humanoid=Instance.new("Humanoid")
humanoid.Parent=character
local player={Character=character,UserId=991001,CharacterRemoving=signal(function() end)}
local players={PlayerAdded=signal(function() end),PlayerRemoving=signal(function() end),GetPlayers=function() return {player} end}
local remote={OnServerEvent=signal(function(fn) event=fn end),FireClient=function(_,_,kind,data) if kind=="State" then latest=data end end}
local package={Config=RS.RodeoFantasy.Config,HuntRules=RS.RodeoFantasy.HuntRules,BagRules=RS.RodeoFantasy.BagRules,CaptureRemote=remote}
local fakeRS={WaitForChild=function() return package end}
local fakeRun={Heartbeat=signal(function(fn) heartbeat=fn end)}
local fakeGame={GetService=function(_,name)
	if name=="Players" then return players end
	if name=="ReplicatedStorage" then return fakeRS end
	if name=="RunService" then return fakeRun end
	return game:GetService(name)
end}
local fakeWorkspace={RodeoPrototype=workspace.RodeoPrototype,GetServerTimeNow=function() return clock end,
	Raycast=function(_,origin,direction,params) return workspace:Raycast(origin,direction,params) end}
local module=Instance.new("ModuleScript")
module.Source="return function(game,script,workspace)\n"..SSS.CaptureServer.Source.."\nend"
module.Parent=SSS
require(module)(fakeGame,{Parent=SSS},fakeWorkspace)
local config=require(package.Config)
local world=require(SSS.HuntWorld)
local function check(value,message) assert(value,message) checks+=1 end
local function advance(seconds,keepObstacles)
	for _=1,math.ceil(seconds/0.1) do
		clock+=0.1
		if not keepObstacles then workspace.RodeoPrototype.Obstacles:ClearAllChildren() end
		heartbeat(0.1)
	end
end
event(player,"Start")
check(latest.phase=="Riding" and root.Anchored,"start must mount and anchor")
check(latest.count==0,"bag must start empty")
event(player,"Steer",0.5)
local startX=root.Position.X
advance(0.1)
check(root.Position.X>startX,"analog steering must move")
event(player,"Steer",0/0)
advance(0.1)
check(root.Position.X==root.Position.X,"NaN steering must not corrupt position")
event(player,"Steer",0)
event(player,"Hold","invalid")
check(latest.phase=="Riding","invalid input must not jump")
advance(0.2)
event(player,"Hold",true)
advance(0.2)
event(player,"Hold",false)
check(latest.phase=="Airborne","release must launch")
check(not latest.monster,"previous mount must be released")
advance(0.1)
local target=world.spawn(Vector3.new(root.Position.X,2,root.Position.Z-3))
event(player,"Hold",true)
advance(0.1)
check(latest.phase=="Lassoing" and target:GetAttribute("Occupied"),"hold must lasso nearest eligible target")
advance(0.6)
check(latest.phase=="Riding" and latest.monster==target,"rope must finish landing")
check(latest.count==0,"abandoned ride must not grant")
local protectedRock=Instance.new("Part")
protectedRock.Size=Vector3.new(4,3,4)
protectedRock.Position=Vector3.new(root.Position.X,1.5,root.Position.Z-6)
protectedRock.Parent=workspace.RodeoPrototype.Obstacles
advance(0.3,true)
check(latest.phase=="Riding" and latest.protectedUntil>clock,"landing grace must protect against obstacle")
protectedRock:Destroy()
advance(2.1)
check(latest.protectedUntil<clock,"landing grace must expire")
advance(config.Hunt.TameSeconds+0.3)
check(latest.count==1 and latest.tamed,"sustained ride must tame")
check(latest.phase=="Riding","taming must keep running")
advance(0.8)
check(latest.count==1,"same individual must not grant twice")
event(player,"Hold",false)
advance(config.Prototype.FlightSeconds+0.5)
check(latest.phase=="GameOver" and not root.Anchored,"missed airborne catch must end and restore")
event(player,"Start")
check(latest.phase=="Riding" and latest.count==1,"restart must retain bag")
advance(config.Hunt.AngerSeconds+0.4)
check(latest.angerAt~=nil and latest.phase=="Riding","anger must warn before buck-off")
advance(config.Prototype.BuckWarningSeconds+0.4)
check(latest.phase=="GameOver" and not root.Anchored,"anger must end and restore")
event(player,"Start")
advance(0.2)
local rock=Instance.new("Part")
rock.Name="ControllerTestRock"
rock.Anchored=true
rock.Size=Vector3.new(4,3,4)
rock.Position=Vector3.new(root.Position.X,1.5,root.Position.Z-6)
rock.Parent=workspace.RodeoPrototype.Obstacles
advance(0.2,true)
check(latest.phase=="GameOver" and not root.Anchored,"swept collision must end and restore")
check(humanoid.AutoRotate and not humanoid.PlatformStand,"normal character flags must be restored")
module:Destroy()
character:Destroy()
print("HUNT_CONTROLLER_SMOKE_PASS: "..checks.." actual controller checks with native world and controlled clock")
