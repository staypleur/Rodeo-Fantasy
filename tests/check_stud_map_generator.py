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
local registry={}
local function children(self)
 local result={} for _,node in ipairs(registry) do if node.Parent==self then table.insert(result,node) end end return result
end
local workspace={GetChildren=children}
local Instance={}
function Instance.new(class)
 assert(class=="Model" or class=="Part","Forbidden instance class")
 if class=="Part" then partCount+=1 if partCount==failAt then error("Injected creation failure") end end
 local node={ClassName=class,GetChildren=children,attributes={}}
 function node:IsA(wanted) return self.ClassName==wanted end
 function node:SetAttribute(key,value) self.attributes[key]=value end
 function node:GetAttribute(key) return self.attributes[key] end
 function node:FindFirstChild(name) for _,child in ipairs(self:GetChildren()) do if child.Name==name then return child end end end
 function node:Destroy() self.destroyed=true self.Parent=nil for _,child in ipairs(self:GetChildren()) do child:Destroy() end end
 table.insert(registry,node)
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
   for _,face in ipairs({"FrontSurface","BackSurface","LeftSurface","RightSurface"}) do assert(p[face]==Enum.SurfaceType.Studs) end
   assert(p.Anchored and p.CanCollide and not p.CanTouch)
   for _,axis in ipairs({"X","Y","Z"}) do
    local position,size=p.Position[axis],p.Size[axis]
    assert(position%4==0 and size>0 and size%4==0)
    assert((position-size/2)%4==0 and (position+size/2)%4==0)
   end
  end
 end
 assert(model:FindFirstChild("MeadowPlate").Size.X==192)
 if not origin then assert(model:FindFirstChild("MeadowPlate").Position.Y==4) end
 return model
end
local first=inspect(nil)
inspect(Vector3.new(400,8,-800))
local backup={}
local unrelated=Instance.new("Model") unrelated.Name="HuntStudBlockReview" unrelated.Parent=workspace
local baseplate=Instance.new("Part") baseplate.Name="Baseplate" baseplate.Parent=workspace
local second=Generator.create(workspace,nil,backup)
assert(first.Parent==backup and unrelated.Parent==workspace and baseplate.Parent==workspace)
local third=Generator.create(workspace,nil,backup)
assert(second.Parent==backup and third.Parent==workspace and not second.destroyed)
-- Old unmarked 71-Part bundle must also be archived to stop the overlap.
third:SetAttribute("StudMapGenerator",nil)
third:FindFirstChild("MeadowPlate").Size=Vector3.new(160,8,320)
local fourth=Generator.create(workspace,nil,backup)
assert(third.Parent==backup and fourth.Parent==workspace)
for _,origin in ipairs({Vector3.new(1,0,0),Vector3.new(0,2,0),Vector3.new(0,0,0/0),Vector3.new(math.huge,0,0)}) do
 created={}
 assert(not pcall(function() Generator.create(workspace,origin) end))
 assert(#created==0,"Invalid origin created map instances")
end
created={} partCount=0 failAt=5
assert(not pcall(function() Generator.create(workspace,nil,backup) end))
assert(created[1].destroyed and created[1].Parent==nil,"Failed map was published")
assert(fourth.Parent==workspace,"Creation failure archived the previous working map")
print("STUD_MAP_GENERATOR_PASS: 71 plastic blocks, five Stud faces, grid4, width192, elevated floor, repeat/legacy archive, unrelated/Baseplate preservation, failure cleanup")
'''
harness=ROOT/'.tools/test_stud_map_generator.luau'
harness.write_text(prefix+source+suffix,encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(harness.relative_to(ROOT))],cwd=ROOT,check=True)
bundle=ROOT/'dist/ReviewModels/CreateStudBlockMap.commandbar.lua'
assert source in bundle.read_text(encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau-compile.exe'),str(bundle.relative_to(ROOT))],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
