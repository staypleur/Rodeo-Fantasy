-- Review map only. Does not install hunting logic or modify an existing map.
local Generator = {}
local Layout = require(script.Parent.StudHuntLayout)
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
 model:SetAttribute("StudMapRevision",4)
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
  for _, value in ipairs({position.X, position.Y, position.Z}) do
   assert(onGrid(value), "Block position must align to the 4-stud grid")
  end
  for _, value in ipairs({size.X, size.Y, size.Z}) do
   -- Multiples of 8 also put both faces on the 4-stud grid.
   assert(onGrid(value) and value > 0 and value % 8 == 0, "Block dimensions must align their faces to the grid")
  end
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
  part.CanCollide = true
  part.CanTouch = false
  part.CanQuery = true
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
