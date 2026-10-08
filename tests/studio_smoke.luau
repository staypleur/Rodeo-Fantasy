local RS=game:GetService("ReplicatedStorage")
local package=RS.RodeoFantasy
local config=require(package.Config)
local rules=require(package.HuntRules)
local bagRules=require(package.BagRules)
assert(config.Monster.Id=="Lumidon" and config.Monster.Name=="루미돈")
assert(package:FindFirstChild("CaptureRules")==nil and config.Capture==nil)
local bag=bagRules.new()
bagRules.grant(bag,config.Monster.Id,0)
bagRules.accrue(bag,2,config.BagIncome.IncomeSeconds,config.BagIncome.IncomeAmount)
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
assert(clone.Body:FindFirstChild("Shape")==nil and clone.Body.TopSurface==Enum.SurfaceType.Studs)
assert(clone.LeftEyeWhite.FrontSurface==Enum.SurfaceType.Smooth)
assert(clone.LeftFrontLeg and clone.RightBackLeg and clone.TailCurl)
assert(clone.LanternGlow.LanternLight:IsA("PointLight") and clone.LanternGlow.Material==Enum.Material.Neon)
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
assert(#world.Monsters:GetChildren()>10,"moving herd required")
assert(#world.Obstacles:GetChildren()>0,"obstacles required")
local animal=engine.spawn(Vector3.new(0,2,-8))
local before=animal.PrimaryPart.Position
local bodyBefore=animal.Body.CFrame
engine.step(0.1)
assert(animal.PrimaryPart.Position.Z<before.Z,"wild herd must run")
assert(animal.Body.CFrame==bodyBefore,"server must not overwrite client body animation")
-- First render after the root has moved must use immutable template offsets.
animator.update(world.Monsters,1,nil,1/60)
local expected=animal.PrimaryPart.CFrame*package.VisualTemplate.Body.CFrame
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
local blocker=engine.spawn(animal.PrimaryPart.Position+Vector3.new(0,0,-4))
assert(engine.mountedHit(animal.PrimaryPart.Position,animal.PrimaryPart.Position,animal)=="Monster","mounted contact required")
blocker:Destroy()
assert(engine.mountedHit(Vector3.new(34,2,0),Vector3.new(35,2,0),animal)=="Wall","visible canyon contact required")
local gauge=require(game:GetService("StarterPlayer").StarterPlayerScripts.TamingGauge)
gauge.update(CFrame.new(0,2,0),0.5,false,false)
local gui=workspace.LocalTamingGaugeAnchor.MountedTamingGauge
assert(gui.Enabled and gui.Frame.Heart.Text=="♥","heart gauge required")
assert(gui.Frame.Arc32.BackgroundColor3~=gui.Frame.Arc33.BackgroundColor3,"half progress must fill half the circle")
gauge.update(nil,0,false,false)
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
presentation.update(rig,"GameOver",nil,1,2.5)
assert(shoulder.C0==original,"restore avatar joints after hunting")
assert(not avatarRoot:FindFirstChild("FlightTrailAnchor") and not avatarRoot:FindFirstChild("FlightTrailEnd"),"flight attachments must clean up")
local effect=require(game:GetService("StarterPlayer").StarterPlayerScripts.CrashEffect)
effect.start(rig,3)
assert(torso.LocalTransparencyModifier==1 and workspace:FindFirstChild("LocalCrashShard"),"collision must scatter visible clones")
local shard=workspace:FindFirstChild("LocalCrashShard")
local shardBefore=shard.CFrame
effect.update(rig,"GameOver",3.2)
assert(shard.CFrame~=shardBefore and rig.Parent~=nil,"shards must move without breaking real joints")
effect.update(rig,"Riding",3.3)
assert(torso.LocalTransparencyModifier==0 and not workspace:FindFirstChild("LocalCrashShard"),"restart must restore avatar and clear shards")
rig:Destroy()
print("RODEO_STUDIO_SMOKE_PASS: Lumidon, quadruped animation, running herds, lasso candidates, swept obstacles and cleanup")
