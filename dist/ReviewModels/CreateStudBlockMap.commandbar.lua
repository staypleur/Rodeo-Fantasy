-- Run in a separate empty Studio place for design review.
local Generator = (function()
-- Review map only. Does not install hunting logic or modify an existing map.
local Generator = {}
local GRID = 4

local function onGrid(value)
 return value == value and math.abs(value) < math.huge and value % GRID == 0
end

function Generator.create(parent, origin)
 origin = origin or Vector3.new(0, 0, 0)
 assert(onGrid(origin.X) and onGrid(origin.Y) and onGrid(origin.Z), "Origin must align to the 4-stud grid")
 local model = Instance.new("Model")
 model.Name = "HuntStudBlockReview"
 local function block(name, position, size, color)
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
  part.BottomSurface = Enum.SurfaceType.Smooth
  part.FrontSurface = Enum.SurfaceType.Smooth
  part.BackSurface = Enum.SurfaceType.Smooth
  part.LeftSurface = Enum.SurfaceType.Smooth
  part.RightSurface = Enum.SurfaceType.Smooth
  part.Anchored = true
  part.CanCollide = true
  part.CanTouch = false
  part.CanQuery = true
  part.Size = size
  part.Position = position + origin
  part.Color = color
  part.Parent = model
 end
 local function put(name, x,y,z, sx,sy,sz, r,g,b)
  block(name,Vector3.new(x,y,z),Vector3.new(sx,sy,sz),Color3.fromRGB(r,g,b))
 end
 local ok, err = pcall(function()
  -- Proposed 160 x 320 stud meadow. These are review dimensions.
  put("MeadowPlate",0,-4,-128,160,8,320,166,196,112)
  for _, side in ipairs({-1,1}) do
   for index=0,7 do
    local z=-268+index*40
    local height=16+(index%3)*8
    put("CliffFoot",side*88,4,z,16,8,40,169,126,83)
    put("CliffWall",side*104,8+height/2,z,16,height,40,144,104,70)
    put("GrassCap",side*104,12+height,z,16,8,40,119,159,84)
   end
  end
  for _, spot in ipairs({{-56,-40},{56,-88},{-56,-136},{56,-192},{-48,-232},{40,-272}}) do
   local x,z=spot[1],spot[2]
   put("TreeTrunk",x,8,z,8,16,8,125,87,56)
   put("CanopyLower",x,20,z,24,8,24,115,154,76)
   put("CanopyUpper",x,28,z,16,8,16,150,184,98)
  end
  for _, spot in ipairs({{-32,-72},{32,-136},{-24,-216},{48,-248}}) do
   put("LowRock",spot[1],4,spot[2],16,8,16,177,165,130)
  end
  -- Publish only when the complete map passes the grid checks.
  model.Parent = parent or workspace
 end)
 if not ok then model:Destroy() error(err, 0) end
 return model
end

return Generator

end)()
local model = Generator.create(workspace, Vector3.new(0,0,0))
game:GetService("Selection"):Set({model})
print("STUD_MAP_REVIEW_CREATED", #model:GetChildren(), "Parts; no hunt logic installed")
