"""Run the real generator with an Instance shim; Studio rendering remains separate."""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'src/authoring/StudBlockMapGenerator.luau').read_text(encoding='utf-8')
layout=(ROOT/'src/authoring/StudHuntLayout.luau').read_text(encoding='utf-8')
source=source.replace('local Layout = require(script.Parent.StudHuntLayout)', 'local Layout = (function()\n'+layout+'\nend)()')
prefix='''
local created={}
local failAt=nil
local partCount=0
local Vector3={}
local vectorMeta={__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end}
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMeta) end
local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local Enum={PartType={Block="Block"},Material={Plastic="Plastic"},SurfaceType={Studs="Studs",Inlet="Inlet",Smooth="Smooth"}}
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
 assert(#created>600 and #created<2500)
 for _,p in ipairs(created) do
  if p.ClassName=="Part" then
   assert(p.Parent==model and p.Shape==Enum.PartType.Block)
   assert(p.Material==Enum.Material.Plastic and p.TopSurface==Enum.SurfaceType.Studs)
   assert(p.BottomSurface==Enum.SurfaceType.Inlet)
   for _,face in ipairs({"FrontSurface","BackSurface","LeftSurface","RightSurface"}) do assert(p[face]==Enum.SurfaceType.Studs) end
   assert(p.Anchored and p.CanCollide and not p.CanTouch)
   for _,axis in ipairs({"X","Y","Z"}) do
    local position,size=p.Position[axis],p.Size[axis]
    assert(position%4==0 and size>0 and size%4==0)
    assert((position-size/2)%4==0 and (position+size/2)%4==0)
   end
  end
 end
 assert(model:FindFirstChild("MeadowPlate").Size.X==160)
 assert(model:GetAttribute("LengthStuds")==4800 and model:GetAttribute("LengthMeters")==1000)
 assert(model:GetAttribute("PrivateHunt") and model:GetAttribute("MonsterModelsPending"))
 assert(model:GetAttribute("TargetEmptyScreenShare")==0.4 and model:GetAttribute("TargetObstacleScreenShare")==0.2 and model:GetAttribute("TargetMonsterScreenShare")==0.4)
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
local legacy=Instance.new("Model") legacy.Name="HuntStudBlockReview" legacy.Parent=workspace
for i=1,71 do
 local p=Instance.new("Part") p.Parent=legacy p.Name=i==1 and "MeadowPlate" or "LowRock"
 p.Material=Enum.Material.Plastic p.TopSurface=Enum.SurfaceType.Studs p.Size=Vector3.new(160,8,320)
end
local fourth=Generator.create(workspace,nil,backup)
assert(third.Parent==backup and legacy.Parent==backup and fourth.Parent==workspace)
-- Conservative ground-plane route check, including canopy footprints and 6-stud clearance.
local function blocked(x,z)
 for _,p in ipairs(fourth:GetChildren()) do
  if p:GetAttribute("MapKind")=="Obstacle" and math.abs(x-p.Position.X)<=p.Size.X/2+6 and math.abs(z-p.Position.Z)<=p.Size.Z/2+6 then return true end
 end
 return false
end
local reachable={[0]=true}
for z=0,-4800,-16 do
 local nextReach={}
 for x=-88,88,8 do
  if not blocked(x,z) and (reachable[x] or reachable[x-8] or reachable[x+8]) then nextReach[x]=true end
 end
 assert(next(nextReach),"No continuous route at z="..z)
 reachable=nextReach
end
local ground={}
for _,p in ipairs(fourth:GetChildren()) do
 if p.Name=="MeadowPlate" then table.insert(ground,p) end
end
-- Adjacent gradient strips must not reintroduce overlapping top faces.
local all=fourth:GetChildren()
for i,a in ipairs(all) do
 for j=i+1,#all do
  local b=all[j]
  if a.Position.Y+a.Size.Y/2==b.Position.Y+b.Size.Y/2 then
   local overlapX=math.min(a.Position.X+a.Size.X/2,b.Position.X+b.Size.X/2)-math.max(a.Position.X-a.Size.X/2,b.Position.X-b.Size.X/2)
   local overlapZ=math.min(a.Position.Z+a.Size.Z/2,b.Position.Z+b.Size.Z/2)-math.max(a.Position.Z-a.Size.Z/2,b.Position.Z-b.Size.Z/2)
   assert(not (overlapX>0 and overlapZ>0),"Overlapping top faces: "..a.Name.."/"..b.Name)
  end
 end
end
assert(#ground==30)
table.sort(ground,function(a,b) return a.Position.Z>b.Position.Z end)
assert(ground[1].Position.Z+ground[1].Size.Z/2==0)
assert(ground[30].Position.Z-ground[30].Size.Z/2==-4800)
for i,p in ipairs(ground) do
 assert(p.Size.X==160 and p.Size.Z==160)
 if i>1 then assert(ground[i-1].Position.Z-ground[i-1].Size.Z/2==p.Position.Z+p.Size.Z/2) end
end
local heights={}
for _,p in ipairs(all) do
 if p.Name=="MeadowShoulder" then heights[p.Size.Y]=true end
 if p.Name=="GrassCap" then assert(math.abs(p.Position.X)-p.Size.X/2>=96,"Wall narrows course") end
end
assert(heights[8] and heights[16],"Missing floor relief")
for _,p in ipairs(ground) do
 local shoulders=0
 local tops={}
 for _,q in ipairs(all) do
  if q.Position.Z==p.Position.Z and q.Name=="MeadowShoulder" then
   assert(math.abs(q.Position.X)==88 and q.Size.X==16 and q.Size.Z==160)
   shoulders+=1
  elseif q.Position.Z==p.Position.Z and q.Name=="GrassCap" and q.Position.X>0 then
   tops[q.Position.X]=q.Position.Y
  end
 end
 assert(shoulders==2,"Missing full width floor coverage")
 assert(tops[104]<tops[120] and tops[120]<tops[136],"Canyon terraces not ascending")
end
for _,origin in ipairs({Vector3.new(1,0,0),Vector3.new(0,2,0),Vector3.new(0,0,0/0),Vector3.new(math.huge,0,0)}) do
 created={}
 assert(not pcall(function() Generator.create(workspace,origin) end))
 assert(#created==0,"Invalid origin created map instances")
end
created={} partCount=0 failAt=5
assert(not pcall(function() Generator.create(workspace,nil,backup) end))
assert(created[1].destroyed and created[1].Parent==nil,"Failed map was published")
assert(fourth.Parent==workspace,"Creation failure archived the previous working map")
print("STUD_MAP_GENERATOR_PASS: layered forest colours, grid4/Studs, 1000m constant width, adjacent floors, continuous conservative route, backups and failure recovery")
'''
harness=ROOT/'.tools/test_stud_map_generator.luau'
harness.write_text(prefix+source+suffix,encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(harness.relative_to(ROOT))],cwd=ROOT,check=True)
bundle=ROOT/'dist/ReviewModels/CreateStudBlockMap.commandbar.lua'
assert source in bundle.read_text(encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau-compile.exe'),str(bundle.relative_to(ROOT))],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
