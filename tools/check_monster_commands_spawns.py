"""Exercise production command parsing and replenish logic without Roblox assets."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
def source(path):
    return (root / path).read_text(encoding="utf-8-sig")

test = "local Catalog=(function()\n" + source("src/shared/MonsterCatalog.luau") + "\nend)()\n"
test += "local Commands=(function()\n" + source("src/shared/MonsterCommandRules.luau") + "\nend)()\n"
test += "local Names=(function()\n" + source("src/shared/Localization.luau") + "\nend)().entries\n"
test += "local SpawnPlan=(function()\n" + source("src/shared/HerdSpawnPlan.luau") + "\nend)()\n"
test += r'''
for _,name in ipairs({"Brambleboar","브램블보어","GrassBoar","BRAMBLEBOAR"}) do
 local r=Commands.parse("/monster "..name.." 9 3",Catalog,Names)
 assert(r.id=="GrassBoar" and r.stars==9 and r.count==3)
end
assert(Commands.parse(" /monster   Mossrat  1 ",Catalog,Names).id=="MeadowMouse")
for _,s in ipairs({"/monster TreeWolf 3","/monster Mossrat 0","/monster Mossrat 11","/monster Mossrat 1.5","/monster Mossrat 3 0","/monster Mossrat 3 11","/monster Mossrat 3 1 extra"}) do
 assert(Commands.parse(s,Catalog,Names).invalid)
end
assert(Commands.help(Catalog,Names):find("Brambleboar"))
assert(Catalog.GrassBoar.TameSeconds==6)
for _,m in ipairs({0,150,299.999}) do for i=1,60 do assert(Catalog.pick(m,i)=="MeadowMouse") end end
for _,m in ipairs({300,400,599,1000,1999}) do
 local counts={MeadowMouse=0,GrassBoar=0}
 for i=0,59 do local id=Catalog.pick(m,i) counts[id]+=1 end
 assert(counts.MeadowMouse==30 and counts.GrassBoar==30)
end
for _,parity in ipairs({0,1}) do
 local counts={MeadowMouse=0,GrassBoar=0}
 for i=parity,59,2 do counts[Catalog.pick(300,i)]+=1 end
 assert(counts.MeadowMouse==15 and counts.GrassBoar==15)
end
-- A future active species needs no command code change. This is a test fixture.
Catalog.TestFuture={UnlockMeters=600,RootHeight=3,TameSeconds=6}
table.insert(Catalog.Order,"TestFuture") Names.TestFuture={en="FutureWolf",ko="테스트늑대"}
assert(Commands.parse("/monster FutureWolf 6",Catalog,Names).id=="TestFuture")
assert(Commands.help(Catalog,Names):find("FutureWolf"))
for _,m in ipairs({600,601,1500}) do
 local counts={MeadowMouse=0,GrassBoar=0,TestFuture=0}
 for i=0,59 do counts[Catalog.pick(m,i)]+=1 end
 assert(counts.MeadowMouse==20 and counts.GrassBoar==20 and counts.TestFuture==20)
end
assert(Catalog.pick(2000,1)==nil)
local World={} local animals={} local spawnSerial=0 local viewerMeters=0
local tuning={MetersPerStud=0.625/3}
local Course={width=function() return 40 end,ranges=function() return {{-40,40}} end}
local Visibility={visible=function() return false end}
local obstacles={GetChildren=function() return {} end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
function World.spawn(p,id)
 local model={Parent=true,PrimaryPart={Position=p},id=id,SetAttribute=function() end,GetAttribute=function() return false end}
 animals[model]=true spawnSerial+=1 return model
end
'''
world = source("src/server/HuntWorld.luau")
test += world[world.index("function World.replenish("):world.index("function World.maintain(")]
test += r'''
local function sample(meters)
 animals={} spawnSerial=0
 local total=World.replenish(-meters/tuning.MetersPerStud,1,nil,false,24)
 local counts={MeadowMouse=0,GrassBoar=0,TestFuture=0}
 for model in pairs(animals) do
  counts[model.id]+=1
  assert(-model.PrimaryPart.Position.Z*tuning.MetersPerStud>=Catalog[model.id].UnlockMeters)
 end
 assert(total>0)
 return counts
end
local two=sample(300) assert(math.abs(two.MeadowMouse-two.GrassBoar)<=1)
local three=sample(600)
assert(math.abs(three.MeadowMouse-three.GrassBoar)<=1 and math.abs(three.GrassBoar-three.TestFuture)<=1)
-- Repeated replenishment alongside the moving herd, as the live run does.
animals={} spawnSerial=0 local firstBirth
for m=240,300,3 do
 local z=-m/tuning.MetersPerStud
 for model in pairs(animals) do
  model.PrimaryPart.Position.Z-=44*(3/(64*tuning.MetersPerStud))
  if model.PrimaryPart.Position.Z>z+30 then animals[model]=nil end
 end
 World.replenish(z,1,nil,false,12)
 for model in pairs(animals) do if model.id=="GrassBoar" then firstBirth=firstBirth or m end end
end
assert(firstBirth and firstBirth<300,"The 300m region was not preloaded before arrival")
print("MONSTER_COMMAND_SPAWN_PASS: aliases, limits, auto-registration, 300m preload, 1/2 and 1/3 actual births")
'''
target = root / ".tools/monster-command-spawn-test.luau"
target.write_text(test,encoding="utf-8")
subprocess.run([str(root / ".tools/luau/luau.exe"),str(target.relative_to(root))],cwd=root,check=True)
