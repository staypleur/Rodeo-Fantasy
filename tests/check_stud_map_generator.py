"""Run the real generator with an Instance shim; Studio rendering remains separate."""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'src/authoring/StudBlockMapGenerator.luau').read_text(encoding='utf-8')
prefix='''
local created={}
local failAt=nil
local partCount=0
local Vector3={}
local vectorMeta={__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end}
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMeta) end
local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local Enum={PartType={Block="Block"},Material={Plastic="Plastic"},SurfaceType={Studs="Studs",Smooth="Smooth"}}
local workspace={}
local Instance={}
function Instance.new(class)
 assert(class=="Model" or class=="Part","Forbidden instance class")
 if class=="Part" then partCount+=1 if partCount==failAt then error("Injected creation failure") end end
 local node={ClassName=class,Destroy=function(self) self.destroyed=true end}
 table.insert(created,node)
 return node
end
local Generator=(function()
'''
suffix='''
end)()
local function inspect(origin)
 created={} partCount=0
 local model=Generator.create(workspace,origin)
 assert(model.Parent==workspace)
 assert(#created==72)
 for _,p in ipairs(created) do
  if p.ClassName=="Part" then
   assert(p.Parent==model and p.Shape==Enum.PartType.Block)
   assert(p.Material==Enum.Material.Plastic and p.TopSurface==Enum.SurfaceType.Studs)
   assert(p.Anchored and p.CanCollide and not p.CanTouch)
   for _,axis in ipairs({"X","Y","Z"}) do
    local position,size=p.Position[axis],p.Size[axis]
    assert(position%4==0 and size>0 and size%4==0)
    assert((position-size/2)%4==0 and (position+size/2)%4==0)
   end
  end
 end
end
inspect(nil)
inspect(Vector3.new(400,8,-800))
for _,origin in ipairs({Vector3.new(1,0,0),Vector3.new(0,2,0),Vector3.new(0,0,0/0),Vector3.new(math.huge,0,0)}) do
 created={}
 assert(not pcall(function() Generator.create(workspace,origin) end))
 assert(#created==0,"Invalid origin created map instances")
end
created={} partCount=0 failAt=5
assert(not pcall(function() Generator.create(workspace) end))
assert(created[1].destroyed and created[1].Parent==nil,"Failed map was published")
print("STUD_MAP_GENERATOR_PASS: 71 plastic block Parts, Studs, centers/sizes/faces grid4, shifted origin, rejected origins, failure cleanup")
'''
harness=ROOT/'.tools/test_stud_map_generator.luau'
harness.write_text(prefix+source+suffix,encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(harness.relative_to(ROOT))],cwd=ROOT,check=True)
bundle=ROOT/'dist/ReviewModels/CreateStudBlockMap.commandbar.lua'
assert source in bundle.read_text(encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau-compile.exe'),str(bundle.relative_to(ROOT))],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
