-- Studio edit-time isolated production-world simulation; no player or inventory.
assert(not game.RunService:IsRunning())
local package=game.ReplicatedStorage.RodeoFantasy
local config=require(package.Config)
local rules=require(package.HuntRules)
local module=game.ServerScriptService.HuntWorld:Clone()
module.Source=module.Source:gsub("require%(game%.ReplicatedStorage%.RodeoFantasy%.MonsterCatalog%)","require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog:Clone())")
module.Source=module.Source:gsub("script%.Parent%.GreenStarCourseLayout","game.ServerScriptService.GreenStarCourseLayout")
local world=require(module).new()
local folder=Instance.new("Folder") folder.Name="HuntSpeciesReview"
local models=Instance.new("Folder") models.Name="Monsters" models.Parent=folder
folder.Parent=game.ServerStorage
world.init(folder,game.ServerStorage.RodeoMonsterTemplate,config,rules)
local seen={} local totals={MeadowMouse=0,GrassBoar=0} local sides={[-1]={},[1]={}}
local firstBirth,firstVisible
local viewer={}
for step=0,160 do
 local meters=step*64*config.Prototype.MetersPerStud*.25
 local z=-meters/config.Prototype.MetersPerStud
 world.ensure(z)
 if step==0 then world.replenish(z,1,nil,true,40)
 else
  world.step(.1) world.step(.1) world.step(.05)
  world.replenish(z,1,nil,false,12)
 end
 for _,model in ipairs(models:GetChildren()) do
  if not seen[model] then
   seen[model]=true local id=model:GetAttribute("MonsterId")
   local birthMeters=-model.PrimaryPart.Position.Z*config.Prototype.MetersPerStud
   if id=="GrassBoar" then assert(birthMeters>=300) firstBirth=firstBirth or meters end
   if birthMeters>=300 then
    totals[id]+=1 local side=model.PrimaryPart.Position.X<0 and -1 or 1
    sides[side][id]=(sides[side][id] or 0)+1
   end
  end
 end
 for model in pairs(world.visibleSet(z,1,viewer)) do
  if model:GetAttribute("MonsterId")=="GrassBoar" then firstVisible=firstVisible or meters end
 end
 world.cleanup({z})
end
assert(firstBirth and firstBirth<300,"300m preload missing")
assert(firstVisible and firstVisible>=300 and firstVisible<=310,"Brambleboar misses the 300m entry")
assert(totals.MeadowMouse>0 and totals.GrassBoar>0 and math.abs(totals.MeadowMouse-totals.GrassBoar)<=2)
assert((sides[-1].GrassBoar or 0)>0 and (sides[1].GrassBoar or 0)>0)
print("HUNT_SPECIES_STUDIO_PASS",firstBirth,firstVisible,totals.MeadowMouse,totals.GrassBoar)
-- Review-only geometry stays server-only; it is not an active run.
