local RS=game:GetService("ReplicatedStorage")
local package=RS.RodeoFantasy
local config=require(package.Config)
local rules=require(package.HuntRules)
local bagRules=require(package.BagRules)
assert(config.Monster.Id=="MeadowMouse" and config.Monster.Name=="MeadowMouse")
assert(package:FindFirstChild("CaptureRules")==nil and config.Capture==nil)
local bag=bagRules.new()
bagRules.grant(bag,config.Monster.Id,0)
bagRules.accrue(bag,3,config.BagIncome.IncomeSeconds,config.BagIncome.IncomeAmount)
assert(bag.pending==1)
local template=game:GetService("ServerStorage").RodeoMonsterTemplate
local clone=template:Clone()
local folder=Instance.new("Folder")
folder.Parent=workspace
clone.Parent=folder
clone:SetAttribute("Running",true)
clone:SetAttribute("RunStarted",0)
clone:PivotTo(CFrame.new(9,2,-20))
assert(clone.PrimaryPart.Name=="MountRoot" and clone.PrimaryPart.Transparency==1)
assert(clone.Body:FindFirstChild("Shape")==nil and clone.Body.TopSurface==Enum.SurfaceType.Smooth)
assert(clone.LeftEyeWhite.FrontSurface==Enum.SurfaceType.Smooth)
assert(clone.LeftFrontLeg and clone.RightBackLeg and clone.TailCurve)
assert(clone.CrownSprout or clone.Clover)
local animator=require(game:GetService("StarterPlayer").StarterPlayerScripts.RideAnimator)
local rootBefore,legBefore=clone.PrimaryPart.CFrame,clone.LeftFrontLeg.CFrame
animator.update(folder,0.1)
assert(clone.PrimaryPart.CFrame==rootBefore,"animation must preserve root")
assert((clone.LeftFrontLeg.Position-legBefore.Position).Magnitude>0.01,"legs must animate")
clone:SetAttribute("Running",false)
animator.update(folder,0.2)
assert((clone.LeftFrontLeg.Position-legBefore.Position).Magnitude<0.001,"rest pose must return")
folder:Destroy()
local world=workspace.RodeoPrototype
local engine=require(game:GetService("ServerScriptService").HuntWorld)
engine.init(world,template,config,rules)
engine.ensure(0)
engine.replenish(0,1,nil,true,128)
assert(#world.Monsters:GetChildren()>10,"moving herd required")
assert(#world.Obstacles:GetChildren()>0,"obstacles required")
local animal=engine.spawn(Vector3.new(0,2,-8))
local before=animal.PrimaryPart.Position
-- Simulate the client materialization before inspecting its local body pose.
require(game.StarterPlayer.StarterPlayerScripts.CreatureMesh).materialize(animal)
local bodyBefore=animal.Body.CFrame
engine.step(0.1)
assert(animal.PrimaryPart.Position.Z<before.Z,"wild herd must run")
assert(animal.Body.CFrame==bodyBefore,"server must not overwrite client body animation")
-- First render after the root has moved must use immutable template offsets.
local displayed=animator.update(world.Monsters,1,nil,1/60)
local expected=displayed[animal]*package.VisualTemplate.Body.CFrame
assert((animal.Body.Position-expected.Position).Magnitude<0.001,"late render must not capture displaced rest pose")
local previous=animal.Body.Position
animal.PrimaryPart.CFrame+=Vector3.new(0,0,-4)
local authoritative=animal.PrimaryPart.CFrame
animator.update(world.Monsters,1.05,nil,1/60)
assert(animal.PrimaryPart.CFrame==authoritative,"interpolation never changes server root")
assert(animal.Body.Position.Z<previous.Z and animal.Body.Position.Z>expected.Z-4,"replication corrections must blend")
animal:SetAttribute("Occupied",true)
local fixed=animal.PrimaryPart.CFrame
engine.step(0.1)
assert(animal.PrimaryPart.CFrame==fixed,"occupied animal belongs to controller")
animal:SetAttribute("Occupied",false)
assert(engine.nearest(animal.PrimaryPart.Position)==animal)
assert(engine.nearest(animal.PrimaryPart.Position,animal)~=animal,"must exclude previous mount")
local blocker=engine.spawn(animal.PrimaryPart.Position+Vector3.new(0,0,-3))
assert(engine.mountedHit(animal.PrimaryPart.Position,animal.PrimaryPart.Position,animal)=="Monster","mounted contact required")
blocker:Destroy()
assert(engine.mountedHit(Vector3.new(34,2,0),Vector3.new(35,2,0),animal)=="Wall","visible canyon contact required")
local gauge=require(game:GetService("StarterPlayer").StarterPlayerScripts.TamingGauge)
local view=Instance.new("Camera")
view.CFrame=CFrame.lookAt(Vector3.new(22,56,32),Vector3.new(0,2,-16))
gauge.update(CFrame.new(0,2,0),0.5,false,view)
local gui=workspace.LocalTamingGaugeAnchor.MountedTamingGauge
assert(gui.Enabled and gui.Frame.Heart.Text=="♥","heart gauge required")
assert(gui.Frame.Arc32.BackgroundColor3~=gui.Frame.Arc33.BackgroundColor3,"half progress must fill half the circle")
local offset=workspace.LocalTamingGaugeAnchor.Position-Vector3.new(0,2,0)
assert(offset:Dot(view.CFrame.RightVector)<0 and offset:Dot(view.CFrame.UpVector)<0,"gauge must offset lower-left in camera axes")
gauge.update(CFrame.new(0,2,0),1,true,view)
assert(not gui.Enabled,"completed taming must hide gauge")
view:Destroy()
gauge.update(nil,0,false,nil)
assert(not gui.Enabled,"gauge must hide on jump/end")
local rock=world.Obstacles:GetChildren()[1]
assert(engine.hit(rock.Position+Vector3.new(0,0,10),rock.Position-Vector3.new(0,0,10)),"swept hit required")
assert(not engine.hit(rock.Position+Vector3.new(0,20,10),rock.Position+Vector3.new(0,20,-10)),"high jump clears rock")
animal:SetAttribute("Occupied",true)
local distant=engine.spawn(Vector3.new(0,2,-5000))
engine.cleanup({0})
assert(distant.Parent==nil and animal.Parent~=nil,"cleanup must preserve active mount")
local presentation=require(game:GetService("StarterPlayer").StarterPlayerScripts.RiderPresentation)
local rig=Instance.new("Model") rig.Parent=workspace
local avatarRoot=Instance.new("Part") avatarRoot.Name="HumanoidRootPart" avatarRoot.Anchored=true avatarRoot.Parent=rig
local torso=Instance.new("Part") torso.Parent=rig
local shoulder=Instance.new("Motor6D") shoulder.Name="LeftShoulder" shoulder.Part0=avatarRoot shoulder.Part1=torso shoulder.Parent=avatarRoot
local original=shoulder.C0
local classic=Instance.new("Motor6D") classic.Name="Left Shoulder"
classic.C0=CFrame.new(-1,0.5,0)*CFrame.Angles(0,-math.pi/2,0) classic.Parent=avatarRoot
local classicOriginal=classic.C0
presentation.update(rig,"Airborne",CFrame.new(0,12,0),1,2)
assert(shoulder.C0~=original and avatarRoot.CFrame.LookVector.Y<-.4,"distinct flight pose")
assert((shoulder.C0.Rotation*original.Rotation:Inverse()).YVector.X>0.99,"R15 arm must point sideways")
assert((classic.C0.Rotation*classicOriginal.Rotation:Inverse()).YVector.X>0.99,"R6 arm must point sideways")
local hip=Instance.new("Motor6D") hip.Name="RightHip" hip.Parent=avatarRoot
local hipRest=hip.C0
-- Register new joints through a fresh presentation lifecycle.
presentation.clear()
local a0=Instance.new("Attachment") a0.Parent=avatarRoot
local a1=Instance.new("Attachment") a1.Parent=torso
local upgraded=Instance.new("AnimationConstraint") upgraded.Name="RightHip"
upgraded.Attachment0,upgraded.Attachment1=a0,a1 upgraded.Parent=avatarRoot
presentation.update(rig,"Riding",CFrame.new(0,4,0),1,1800000000.2,1800000000.8)
assert((-hip.C0.UpVector).Z<-.8,"classic thigh pose must point forward")
assert((-upgraded.Transform.UpVector).Z<-.8,"upgraded thigh pose must point forward")
assert(avatarRoot.FlightTrailAnchor:FindFirstChildOfClass("Trail").Enabled,"dash trail must appear while riding")
local rope=workspace:FindFirstChild("LocalCowboyLasso")
assert(rope and #rope:GetChildren()==50,"cowboy loop must have connected rope segments")
local first=rope:FindFirstChildOfClass("Attachment") local before=first.Position
presentation.update(rig,"Riding",CFrame.new(0,4,0),0.1,1800000000.3)
assert((first.Position-before).Magnitude>.2,"cowboy loop must visibly rotate")
presentation.update(rig,"GameOver",nil,1,2.5)
assert(hip.C0==hipRest and upgraded.Transform==CFrame.identity,"both joint types must restore")
assert(not workspace:FindFirstChild("LocalCowboyLasso"),"rope must clean up")
assert(shoulder.C0==original,"restore avatar joints after hunting")
assert(not avatarRoot:FindFirstChild("FlightTrailAnchor") and not avatarRoot:FindFirstChild("FlightTrailEnd"),"flight attachments must clean up")
local effect=require(game:GetService("StarterPlayer").StarterPlayerScripts.CrashEffect)
local crashLabel=Instance.new("BillboardGui") crashLabel.Name="ExplorerNameplate" crashLabel.Enabled=false crashLabel:SetAttribute("CrashEnabled",true) crashLabel.Parent=torso
  torso:SetAttribute("CrashAlpha",0) torso.Transparency=1
  effect.start(rig,3)
assert(torso.LocalTransparencyModifier==1 and workspace:FindFirstChild("LocalCrashShard"),"collision must scatter visible clones")
local shard=workspace:FindFirstChild("LocalCrashShard")
local shardBefore=shard.CFrame
assert(not crashLabel.Enabled,"name/level must disappear with avatar")
  effect.update(rig,"GameOver",3.2)
assert(shard.CFrame~=shardBefore and rig.Parent~=nil,"shards must move without breaking real joints")
effect.update(rig,"Riding",3.3)
assert(crashLabel.Enabled,"retry must restore the original name/level label")
assert(torso.LocalTransparencyModifier==0 and not workspace:FindFirstChild("LocalCrashShard"),"restart must restore avatar and clear shards")
rig:Destroy()
print("RODEO_STUDIO_SMOKE_PASS: MeadowMouse, quadruped animation, running herds, lasso candidates, swept obstacles and cleanup")

local markers=require(game:GetService("StarterPlayer").StarterPlayerScripts.DistanceMarkers)
markers.update(true,995,CFrame.new(0,4,-400),0.625)
local gate=workspace:FindFirstChild("LocalDistanceMarker")
assert(gate and gate:GetAttribute("Meters")==1000,"first map milestone must show 1000m")
assert(math.abs(gate:GetPivot().Z-(-408))<0.01,"milestone must align with remaining server distance")
markers.update(true,1001,CFrame.new(0,4,-410),0.625)
local nextFound=false
for _,m in ipairs(workspace:GetChildren()) do if m.Name=="LocalDistanceMarker" and m:GetAttribute("Meters")==1000 then nextFound=true end end
assert(nextFound,"unfinished second theme must not get a 2000m marker")
markers.update(false,0,nil,0.625)
assert(not workspace:FindFirstChild("LocalDistanceMarker"),"milestones must clean up on run end")
print("RODEO_MILESTONES_PASS")

local hasLog,hasRock=false,false
for _,obstacle in ipairs(world.Obstacles:GetChildren()) do
 if obstacle:GetAttribute("Style")=="Tree" then hasLog=true assert(obstacle:FindFirstChild("TreeTrunk") and obstacle:FindFirstChild("LeafCrown")) end
 if obstacle:GetAttribute("Style")=="MossyRock" then hasRock=true assert(obstacle:FindFirstChild("Moss")) end
end
assert(hasLog and hasRock,"course must include both dressed obstacle styles")
print("OBSTACLE_ART_PASS")

local dash=require(game.StarterPlayer.StarterPlayerScripts.DashPresentation)
dash.update("Riding",CFrame.new(0,4,0),4,4.6,0.6)
local wind=workspace:FindFirstChild("LocalDashWind")
assert(wind and #wind:GetChildren()==152,"dash requires wind rings and trailing streaks")
assert(not wind.CanCollide and not wind.CanQuery,"wind must be cosmetic")
dash.update("Riding",CFrame.new(0,4,-10),4.3,4.6,0.6)
assert(wind.Position.Z==-10,"wind must follow moving rider")
dash.update("Riding",CFrame.identity,4.61,4.6,0.6)
assert(not workspace:FindFirstChild("LocalDashWind"),"dash effect must clean up when boost expires")
print("DASH_WIND_PASS")

local catch=require(game.StarterPlayer.StarterPlayerScripts.CatchPresentation)
local catchRig=Instance.new("Model") catchRig.Parent=workspace
local catchRoot=Instance.new("Part") catchRoot.Name="HumanoidRootPart" catchRoot.Parent=catchRig
local hand=Instance.new("Part") hand.Name="RightHand" hand.Parent=catchRig
local catchState={phase="Lassoing",monster=animal,started=10,landingSeconds=0.28}
catch.update(catchState,catchRig,CFrame.new(0,5,0),10.05)
assert(workspace:FindFirstChild("LocalThrownLasso") and workspace:FindFirstChild("LocalCatchGlow"),"throw loop and brief glow required")
catchState.phase="Riding"
catch.update(catchState,catchRig,CFrame.new(0,4,-10),10.28)
assert(workspace:FindFirstChild("LocalLandingRing") and not workspace:FindFirstChild("LocalThrownLasso"),"landing must expand a ground ring and remove throw")
catch.update(catchState,catchRig,CFrame.new(0,4,-20),10.9)
assert(not workspace:FindFirstChild("LocalLandingRing") and not workspace:FindFirstChild("LocalCatchGlow"),"catch impulse must expire")
local crate=Instance.new("Part") crate.Position=Vector3.new(100,2,100) crate.Size=Vector3.new(4,4,4) crate.Parent=world.Obstacles
crate:SetAttribute("BreakableCrate",true)
local from,to=Vector3.new(100,2,110),Vector3.new(100,2,90)
assert(engine.crateHit(from,to,animal,"Small") and not crate:GetAttribute("Broken"),"small monster cannot smash crate")
assert(not engine.crateHit(from,to,animal,"Medium",false) and crate:GetAttribute("Broken"),"medium breaks wooden crate without dash")
crate:SetAttribute("Broken",false)
assert(not engine.crateHit(from,to,animal,"Large",false) and crate:GetAttribute("Broken"),"large ordinary running breaks wooden crate")
assert(not engine.hit(from,to),"broken crate cannot collide again")
assert(not crate.CanQuery and not crate.CanTouch,"broken crate must not block lasso raycasts or touch")
catch.crates(world.Obstacles,crate.Position,workspace:GetServerTimeNow(),0.01)
assert(workspace:FindFirstChild("LocalCrateShard"),"broken crate must scatter wood")
catch.crates(nil,nil,workspace:GetServerTimeNow()+1,1)
assert(not workspace:FindFirstChild("LocalCrateShard"),"crate shards must clean up")
crate:Destroy()
effect.start(catchRig,12,CFrame.new(100,2,100))
assert(workspace:FindFirstChild("LocalMonsterCrashShard"),"obstacle crash must also scatter monster pieces")
effect.update(catchRig,"GameOver",13.2)
assert(not workspace:FindFirstChild("LocalMonsterCrashShard"),"monster shards must clean up")
effect.clear() catchRig:Destroy()
print("CATCH_CRATE_MONSTER_BREAKUP_PASS")

for _,npc in ipairs(world.Monsters:GetChildren()) do npc:Destroy() end
engine.replenish(0,1,nil,true,128)
local count=#world.Monsters:GetChildren()
assert(count>=4 and count<=74,"opening must have a bounded nearby herd")
engine.replenish(0,1,nil,true,128)
for _=1,5 do engine.replenish(0,1,nil,true,128) end
assert(#world.Monsters:GetChildren()<=74,"repeated priming must retain the bounded shared buffer")
engine.step(config.Prototype.IntroSeconds)
local displayed=0 for _ in pairs(engine.visibleSet(0,1)) do displayed+=1 end
assert(displayed>=4 and displayed<=6,"opening display must have four to six wild animals")
local visible=0
for _,npc in ipairs(world.Monsters:GetChildren()) do
 if require(package.HerdVisibility).visible(npc.PrimaryPart.Position.X,npc.PrimaryPart.Position.Y,npc.PrimaryPart.Position.Z,1,config.Prototype) then visible+=1 end
end
assert(visible>=4,"opening screen must contain nearby monsters")
print("RESTART_HERD_REFILL_PASS")
