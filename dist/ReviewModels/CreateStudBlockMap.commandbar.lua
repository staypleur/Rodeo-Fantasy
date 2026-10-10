-- Run in a separate empty Studio place for design review.
local Generator = (function()
-- Review map only. Does not install hunting logic or modify an existing map.
local Generator = {}
local Layout = (function()
-- Deterministic private meadow layout. No monsters, rewards, or new hunt rules.
local Layout = {WidthStuds=192,LengthStuds=4800,LengthMeters=1000,MetersPerStud=1000/4800}
-- Latest user target is screen composition, not spawn counts or exact pixel masks.
-- Tune against the rear-follow camera after the user supplies new monster models.
Layout.ScreenComposition = {Empty=0.40,Obstacles=0.20,Monsters=0.40}
Layout.Seed = 317
local Scenery = (function()
-- Visual review additions only. The 192-stud driving floor and obstacles stay intact.
local Scenery={}
function Scenery.build(base)
 local blocks={}
 local function put(name,x,y,z,sx,sy,sz,r,g,b)
  table.insert(blocks,{Name=name,Position={x,y,z},Size={sx,sy,sz},Color={r,g,b},Kind="Scenery"})
 end
 -- Trees grow on the outer terraces, rather than filling the driving corridor.
 for _,cap in ipairs(base) do
  if cap.Name=="GrassCap" and math.abs(cap.Position[1])==136 then
   local x,z=cap.Position[1],cap.Position[3]
   local row=math.floor((-z-80)/160)
   if row%2==0 then
    local top=cap.Position[2]+cap.Size[2]/2
    local extra=(row%3)*8
    put("TreeRoot",x,top+4,z,16,8,16,91,65,44)
    put("TreeTrunk",x,top+24+extra/2,z,8,46+extra,8,115,83,53)
    for layer=0,3 do
     local offset=layer%2==0 and -4 or 4
     put(layer==0 and "CanopyLower" or layer==3 and "CanopyUpper" or "CanopyMiddle",
      x+offset,top+48+extra+layer*2,z+offset,80-layer*8,2,64-layer*8,
      68+layer*24,105+layer*23,53+layer*12)
    end
    for _,side in ipairs({-1,1}) do
     put("TreeTrunk",x+side*24,top+36+extra,z,40,6,8,115,83,53)
     for layer=0,3 do
      put(layer==0 and "CanopyLower" or layer==3 and "CanopyUpper" or "CanopyMiddle",
       x+side*(48+layer%2*4),top+40+extra+layer*2,z+(side==1 and 16 or -16),
       48-layer*8,2,40-layer*8,73+layer*22,110+layer*22,50+layer*13)
     end
    end
   end
  end
 end
 -- Four landmarks spaced along the forest. Water is non-colliding Plastic,
 -- never Terrain; the original shoulder beneath it remains traversable.
 for index,segment in ipairs({2,9,18,25}) do
  local side=index%2==1 and -1 or 1
  local z=-80-segment*160
  local cliffTop
  for _,p in ipairs(base) do
   if p.Name=="GrassCap" and p.Position[1]==side*104 and p.Position[3]==z then
    cliffTop=p.Position[2]+p.Size[2]/2 break
   end
  end
  assert(cliffTop,"Waterfall requires its source terrace")
  put("WaterPool",side*100,cliffTop+4,z,24,8,24,87,175,190)
  for band=2,cliffTop/8-1 do
   put("Waterfall",side*92,4+band*8,z,8,8,24,
    55+band*9,145+band*8,170+band*9)
  end
  put("WaterPool",side*88,8,z,16,16,40,62,160,175)
  put("WaterFoam",side*84,20,z,8,8,16,188,226,216)
  put("WaterStream",side*92,8,z+44,8,16,48,65,152,165)
 end
 -- Low edge plants give foreground scale without becoming new obstacles.
 for row=0,29 do
  for _,side in ipairs({-1,1}) do
   local z=-48-row*160
   local groundTop=0
   for _,p in ipairs(base) do
    if p.Name=="MeadowShoulder" and p.Position[1]==side*88 and p.Position[3]==-80-row*160 then
     groundTop=p.Position[2]+p.Size[2]/2 break
    end
   end
   put("FernBase",side*84,groundTop+4,z,8,8,8,98,135,58)
   put("FernTip",side*84,groundTop+12,z,8,8,8,154,181,87)
  end
 end
 return blocks
end
return Scenery

end)()

-- Coherent, seeded height variation, also reproducible outside Studio.
local function relief(index, channel)
 local cell=math.floor(index/4)
 local t=(index%4)/4
 t=t*t*(3-2*t)
 local function sample(n)
  local v=math.sin(n*127.1+channel*311.7+Layout.Seed)*43758.5453
  return v-math.floor(v)
 end
 return math.floor((sample(cell)*(1-t)+sample(cell+1)*t)*3)
end

function Layout.build()
 local blocks = {}
 local function put(name,x,y,z,sx,sy,sz,r,g,b,kind)
  table.insert(blocks,{Name=name,Position={x,y,z},Size={sx,sy,sz},Color={r,g,b},Kind=kind or "Scenery"})
 end
 -- Adjacent slabs share only their edge; no overlapping top faces.
 for index=0,29 do
  local z=-80-index*160
  local tint=index%3
  put("MeadowPlate",0,-4,z,160,8,160,224-tint*3,199-tint*3,151-tint*2,"Ground")
  for _,side in ipairs({-1,1}) do
   local edgeHeight=relief(index,side+3)==2 and 8 or 0
   put("MeadowShoulder",side*88,-4+edgeHeight/2,z,16,8+edgeHeight,160,218-tint*3,193-tint*3,145-tint*2,"Ground")
   -- Three terraces start OUTSIDE the full 192-stud course, never squeeze it.
   -- Vertical colour bands retain the block silhouette without buried cubes.
   for terrace=0,2 do
    local height=16+terrace*16+relief(index,side+7)*8
    local x=side*(104+terrace*16)
    for level=0,height/8-1 do
     put("CliffWall",x,4+level*8,z,16,8,160,113+level*5,73+level*5,48+level*4)
    end
    put("GrassCap",x,height+4,z,16,8,160,146+terrace*12,159+terrace*10,77+terrace*8)
   end
  end
 end
 local function tree(x,z,large)
  local crown=large and 48 or 40
  put("TreeRoot",x,4,z,16,8,16,107,72,48,"Obstacle")
  for level=0,2 do
   put("TreeTrunk",x,12+level*8,z,8,level==2 and 14 or 8,8,125+level*12,86+level*10,58+level*8,"Obstacle")
  end
  for _,side in ipairs({-1,1}) do
   put("TreeBranch",x+side*12,24,z,16,8,8,146,104,72,"Obstacle")
  end
  -- Broad, two-stud-thick plates, shifted slightly like the user's stacked
  -- Lego reference. Each upper plate touches the lower one without a gap.
  put("CanopyLower",x-4,36,z,crown,2,40,99,120,52,"Obstacle")
  put("CanopyMiddle",x+4,38,z+4,crown-8,2,32,127,148,68,"Obstacle")
  put("CanopyMiddle",x,40,z,crown-8,2,24,154,171,83,"Obstacle")
  put("CanopyUpper",x+4,42,z+4,crown-16,2,16,182,193,104,"Obstacle")
 end
 local function rock(x,z,large)
  local w=large and 48 or 32
  -- Bottom plate embeds one stud into the floor; upper plates are flush stacked.
  put("LowRock",x,0,z,w,2,32,106,91,94,"Obstacle")
  put("RockMiddle",x+4,2,z+4,w-8,2,32,124,107,110,"Obstacle")
  put("RockMiddle",x,4,z,w-8,2,24,143,124,127,"Obstacle")
  put("RockCap",x+4,6,z+4,w-16,2,16,161,141,140,"Obstacle")
  put("RockCap",x,8,z,w-16,2,16,178,157,151,"Obstacle")
 end
 -- Opening and final approach stay clear. Alternate splits with open recovery space.
 -- Rows have 160-stud spacing (~33 m); the full outer width stays constant.
 for row=0,27 do
  local z=-240-row*160
  local pattern=row%7
  if pattern==0 then tree(0,z,true)
  elseif pattern==1 then rock(-40,z,false) rock(40,z,false)
  elseif pattern==2 then tree(-56,z,true) rock(24,z,false)
  elseif pattern==3 then rock(-24,z,false) tree(56,z,true)
  elseif pattern==4 then rock(-24,z,true) rock(24,z,true)
  elseif pattern==5 then tree(-64,z,false) tree(0,z,false) tree(64,z,false)
  else rock(-64,z,false) tree(40,z,true) end
 end
 for _,block in ipairs(Scenery.build(blocks)) do table.insert(blocks,block) end
 return blocks
end

return Layout

end)()
local GRID = 4

local function onGrid(value)
 return value == value and math.abs(value) < math.huge and value % GRID == 0
end

local function isPreviousReview(node)
 if not node:IsA("Model") or node.Name ~= "HuntStudBlockReview" then return false end
 if node:GetAttribute("StudMapGenerator") == true then return true end
 -- Recognize the original 71-Part review without adopting unrelated models.
 local children = node:GetChildren()
 local floor = node:FindFirstChild("MeadowPlate")
 if #children ~= 71 or not floor or not floor:IsA("Part") then return false end
 if floor.Size.X ~= 160 or floor.Size.Y ~= 8 or floor.Size.Z ~= 320 then return false end
 local allowed = {MeadowPlate=true,CliffFoot=true,CliffWall=true,GrassCap=true,TreeTrunk=true,CanopyLower=true,CanopyUpper=true,LowRock=true}
 for _, child in ipairs(children) do
  if not child:IsA("Part") or not allowed[child.Name] or child.Material ~= Enum.Material.Plastic or child.TopSurface ~= Enum.SurfaceType.Studs then return false end
 end
 return true
end

function Generator.create(parent, origin, backupParent)
 parent = parent or workspace
 origin = origin or Vector3.new(0, 8, 0)
 assert(onGrid(origin.X) and onGrid(origin.Y) and onGrid(origin.Z), "Origin must align to the 4-stud grid")
 assert(not backupParent or backupParent ~= parent, "Backup must be outside the visible map parent")
 local previous = {}
 if backupParent then
  for _, node in ipairs(parent:GetChildren()) do
   if isPreviousReview(node) then table.insert(previous,node) end
  end
 end
 local model = Instance.new("Model")
 model.Name = "HuntStudBlockReview"
 model:SetAttribute("StudMapGenerator",true)
 model:SetAttribute("StudMapRevision",7)
 model:SetAttribute("TerrainSeed",Layout.Seed)
 model:SetAttribute("LengthMeters",Layout.LengthMeters)
 model:SetAttribute("LengthStuds",Layout.LengthStuds)
 model:SetAttribute("WidthStuds",Layout.WidthStuds)
 model:SetAttribute("MetersPerStud",Layout.MetersPerStud)
 model:SetAttribute("PrivateHunt",true)
 model:SetAttribute("MonsterModelsPending",true)
 model:SetAttribute("TargetEmptyScreenShare",Layout.ScreenComposition.Empty)
 model:SetAttribute("TargetObstacleScreenShare",Layout.ScreenComposition.Obstacles)
 model:SetAttribute("TargetMonsterScreenShare",Layout.ScreenComposition.Monsters)
 local function block(name, position, size, color, kind)
  local thinPlate = name=="CanopyLower" or name=="CanopyMiddle" or name=="CanopyUpper" or name=="LowRock" or name=="RockMiddle" or name=="RockCap"
  local function onHalfGrid(value)
   return value==value and math.abs(value)<math.huge and value%2==0
  end
  for _, value in ipairs({position.X, position.Z}) do
   assert(onGrid(value), "Block position must align to the 4-stud grid")
  end
  assert((thinPlate and onHalfGrid(position.Y)) or onGrid(position.Y), "Invalid block height")
  for _, value in ipairs({size.X, size.Z}) do
   assert(onGrid(value) and value > 0, "Block dimensions must align to the 4-stud grid")
  end
  assert(size.Y>0 and (((thinPlate or name=="TreeTrunk") and onHalfGrid(size.Y)) or onGrid(size.Y)), "Invalid block thickness")
  local part = Instance.new("Part")
  part.Name = name
  part.Shape = Enum.PartType.Block
  part.Material = Enum.Material.Plastic
  part.TopSurface = Enum.SurfaceType.Studs
  part.BottomSurface = Enum.SurfaceType.Inlet
  part.FrontSurface = Enum.SurfaceType.Studs
  part.BackSurface = Enum.SurfaceType.Studs
  part.LeftSurface = Enum.SurfaceType.Studs
  part.RightSurface = Enum.SurfaceType.Studs
  part.Anchored = true
  part.CanCollide = not (name=="Waterfall" or name=="WaterPool" or name=="WaterFoam" or name=="WaterStream" or name=="FernBase" or name=="FernTip")
  part.CanTouch = false
  part.CanQuery = part.CanCollide
  part.Size = size
  part.Position = position + origin
  part.Color = color
  part:SetAttribute("MapKind",kind)
  part.Parent = model
 end
 local ok, err = pcall(function()
  for _, data in ipairs(Layout.build()) do
   block(data.Name,Vector3.new(table.unpack(data.Position)),Vector3.new(table.unpack(data.Size)),Color3.fromRGB(table.unpack(data.Color)),data.Kind)
  end
  -- Publish only when the complete map passes the grid checks.
  model.Parent = parent
  for _, old in ipairs(previous) do old.Parent = backupParent end
 end)
 if not ok then
  for _, old in ipairs(previous) do old.Parent = parent end
  model:Destroy() error(err, 0)
 end
 return model
end

return Generator

end)()
game:GetService("ChangeHistoryService"):SetWaypoint("Before Stud map review")
local model = Generator.create(workspace, Vector3.new(0,8,0), game:GetService("ServerStorage"))
local scripts=game:GetService("StarterPlayer").StarterPlayerScripts
local old=scripts:FindFirstChild("ForestReviewPresentation") if old then old:Destroy() end
local presentation=Instance.new("LocalScript") presentation.Name="ForestReviewPresentation"
presentation.Source=[==[
-- Review-only local presentation. No server physics or Terrain edits.
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local map=workspace:WaitForChild("HuntStudBlockReview")
local water,leaves={},{}
for _,p in ipairs(map:GetChildren()) do
 if p:IsA("BasePart") then
  if p.Name=="Waterfall" or p.Name=="WaterFoam" or p.Name=="WaterStream" then
   table.insert(water,{part=p,color=p.Color,phase=p.Position.Z*.03+p.Position.Y*.08})
  elseif p.Name=="CanopyUpper" or p.Name=="CanopyMiddle" then
   -- Generated resting positions remain grid aligned; only visual canopy plates
   -- sway in Play. No trunks, ground, water collision, or gameplay is moved.
   table.insert(leaves,{part=p,rest=p.CFrame,phase=p.Position.Z*.013})
  end
 end
end
local oldLight={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient}
Lighting.ClockTime=15.2
Lighting.Brightness=2
Lighting.Ambient=Color3.fromRGB(108,116,92)
Lighting.OutdoorAmbient=Color3.fromRGB(135,143,112)
local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
local createdAtmosphere=atmosphere==nil
atmosphere=atmosphere or Instance.new("Atmosphere")
local oldAtmosphere={Density=atmosphere.Density,Haze=atmosphere.Haze,Glare=atmosphere.Glare,Color=atmosphere.Color,Decay=atmosphere.Decay}
if createdAtmosphere then atmosphere.Name="ForestReviewAtmosphere" end
atmosphere.Density=.22 atmosphere.Haze=1.1 atmosphere.Glare=.15
atmosphere.Color=Color3.fromRGB(238,226,185)
atmosphere.Decay=Color3.fromRGB(145,165,126) atmosphere.Parent=Lighting
local tint=Instance.new("ColorCorrectionEffect")
tint.Name="ForestReviewColor" tint.Contrast=.04 tint.Saturation=.08
tint.TintColor=Color3.fromRGB(255,250,231) tint.Parent=Lighting
local elapsed=0
local connection
connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.1 then return end
 elapsed=0
 if not map.Parent then
  connection:Disconnect() tint:Destroy()
  if createdAtmosphere then atmosphere:Destroy() else for key,value in pairs(oldAtmosphere) do atmosphere[key]=value end end
  for key,value in pairs(oldLight) do Lighting[key]=value end
  return
 end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local time=workspace:GetServerTimeNow()
 local eye=camera.CFrame.Position
 for _,entry in ipairs(leaves) do
  local p=entry.part
  if p.Parent then
   if (entry.rest.Position-eye).Magnitude<260 then
    p.CFrame=entry.rest*CFrame.Angles(0,0,math.sin(time*.7+entry.phase)*.012)
    entry.active=true
   elseif entry.active then p.CFrame=entry.rest entry.active=false end
  end
 end
 for _,entry in ipairs(water) do
  if entry.part.Parent and (entry.part.Position-eye).Magnitude<260 then
   local wave=(math.sin(time*2.3+entry.phase)+1)*.5
   entry.part.Color=entry.color:Lerp(Color3.fromRGB(208,239,230),wave*.16)
  end
 end
end)

]==]
presentation.Parent=scripts
game:GetService("ChangeHistoryService"):SetWaypoint("After Stud map review")
game:GetService("Selection"):Set({model:FindFirstChild("MeadowPlate")})
print("STUD_MAP_REVIEW_CREATED", #model:GetChildren(), "Parts; 1000m x 192 studs; models pending")
