local package=game:GetService("ReplicatedStorage").RodeoFantasy
local config=require(package.Config)
local rules=require(package.HuntRules)
local world=workspace.RodeoPrototype
local engine=require(game:GetService("ServerScriptService").HuntWorld)
engine.init(world,game:GetService("ServerStorage").RodeoMonsterTemplate,config,rules)
local function rock(x,z)
 local p=Instance.new("Part") p.Anchored=true p.CanCollide=false
 p.Size=Vector3.new(4,3,4) p.Position=Vector3.new(x,1.5,z) p.Parent=world.Obstacles
 return p
end
local rocks={rock(0,0),rock(5,-35),rock(29,-20)}
local animals={engine.spawn(Vector3.new(0,2,65)),engine.spawn(Vector3.new(29,2,65)),engine.spawn(Vector3.new(-12,2,65))}
local mounted=engine.spawn(Vector3.new(12,2,65)) mounted:SetAttribute("Occupied",true)
local mountedStart=mounted.PrimaryPart.CFrame
local animator=require(game:GetService("StarterPlayer").StarterPlayerScripts.RideAnimator)
local low,high={},{}
for _,a in ipairs(animals) do low[a],high[a]=a.PrimaryPart.Position.X,a.PrimaryPart.Position.X end
local checks=0
for i=1,200 do
 local before={}
 for _,a in ipairs(animals) do before[a]=a.PrimaryPart.Position end
 engine.step(0.05)
 local displayed=animator.update(world.Monsters,1800000000+i*0.05,nil,0.05)
 for _,a in ipairs(animals) do
  local from,to=before[a],a.PrimaryPart.Position
  assert(to.Z<=from.Z and math.abs(to.X)<33,"wild animal must move forward inside road")
  low[a],high[a]=math.min(low[a],to.X),math.max(high[a],to.X)
  for _,p in ipairs(rocks) do
   local size=p.Size+a.PrimaryPart.Size
   assert(not rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.Position.X,p.Position.Y,p.Position.Z,size.X,size.Y,size.Z,0.2),"authoritative animal footprint passed through rock")
   local frame=displayed[a]
   assert(not rules.sweptBox(frame.X,frame.Y,frame.Z,frame.X,frame.Y,frame.Z,p.Position.X,p.Position.Y,p.Position.Z,size.X,size.Y,size.Z,0),"displayed animal passed through rock")
   checks+=2
  end
 end
 assert(mounted.PrimaryPart.CFrame==mountedStart,"herd AI must not steer mounted animal")
end
for _,a in ipairs(animals) do
 assert(a.PrimaryPart.Position.Z<-200,"animal must go around obstacles and continue forward")
 assert(high[a]-low[a]>2,"individual must sway and turn rather than follow a straight lane")
end
assert(config.Prototype.HerdSpawnChance==0.325 and config.Prototype.RockSpawnChance==0.825,"confirmed density tuning")
print("HERD_STUDIO_PASS: "..checks.." native authoritative and displayed obstacle checks, lateral motion and mounted ownership")
