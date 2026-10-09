"""Exercise the actual replenishment function with deterministic API stubs."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def mod(file):return '(function()\n'+(R/file).read_text(encoding='utf-8')+'\nend)()'
source=(R/'src/server/HuntWorld.luau').read_text(encoding='utf-8')
body=source.split('function World.replenish',1)[1].split('function World.maintain',1)[0]
code='local Course='+mod('src/shared/CourseGeometry.luau')+'\n'
code+='local Visibility='+mod('src/shared/HerdVisibility.luau')+'\n'
code+='local tuning='+mod('src/shared/Config.luau')+'.Prototype\n'
code+=r'''
local World,animals={},{}
local spawnSerial=0
local Catalog={MeadowEndMeters=1000,pick=function() return 'Mouse' end,Mouse={RootHeight=2,Flying=false}}
local obstacles={GetChildren=function() return {} end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local function spawn(p,id)
 local m={Parent=true,PrimaryPart={Position=p},SetAttribute=function() end}
 animals[m]=true spawnSerial+=1 return m
end
World.spawn=spawn
'''
code+='function World.replenish'+body
code+=r'''
local wide=World.replenish(0,1,nil,true)
assert(wide==24)
animals={} spawnSerial=0
local narrow=World.replenish(-1300,1,nil,true)
assert(narrow==16,'narrow opening must reduce generated population budget')
local byRow={}
for model in pairs(animals) do
 local p=model.PrimaryPart.Position
 assert(math.abs(p.X)<Course.width(p.Z),'animal must stay inside road')
 assert((-1300-p.Z+12)%16==0,'narrow rows must use sixteen-stud cadence')
 byRow[p.Z]=(byRow[p.Z] or 0)+1 assert(byRow[p.Z]<=2,'narrow roads use only two lanes')
end
animals={} spawnSerial=0
local later=World.replenish(-1300,1,nil,false,12)
assert(later<=12,'maintenance call must still obey its own smaller budget')
animals={} spawnSerial=0
World.replenish(-990/tuning.MetersPerStud,1,nil,true)
for model in pairs(animals) do assert(-model.PrimaryPart.Position.Z*tuning.MetersPerStud<1000,'no meadow birth past the boundary') end
print('HUNT_DENSITY_PASS: wide24/narrow16 preparation, two narrow lanes, sixteen-stud row spacing, road bounds and maintenance budget')
'''
p=R/'.tools/hunt_density_test.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
