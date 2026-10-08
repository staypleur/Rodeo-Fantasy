local package=game.ReplicatedStorage.RodeoFantasy
local cfg=require(package.Config) local rules=require(package.HuntRules)
local world=workspace.RodeoPrototype local engine=require(game.ServerScriptService.HuntWorld)
engine.init(world,game.ServerStorage.RodeoMonsterTemplate,cfg,rules)
engine.ensure(0)
local progress={}
for tick=1,500 do
 engine.ensure(-tick*6.4) engine.step(0.1)
 for _,animal in ipairs(world.Monsters:GetChildren()) do
  local p=animal.PrimaryPart.Position local old=progress[animal]
  local still=old and math.abs(p.Z-old.z)<0.001 and old.still+0.1 or 0
  progress[animal]={z=p.Z,still=still}
  assert(still<3,"generated course herd stuck beside obstacle: "..tostring(p))
 end
 engine.cleanup({0,-tick*6.4})
 for animal in pairs(progress) do if not animal.Parent then progress[animal]=nil end end
end
print("COURSE_SOAK_PASS: 50 seconds across generated obstacles without persistent stationary herds")
