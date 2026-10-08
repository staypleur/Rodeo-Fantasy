local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId,rideSpeed
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local spawnSerial=0
local crateRows={}

local function part(parent, name, position, size, color)
	local item = Instance.new("Part")
	item.Name, item.Anchored = name, true
	item.Size, item.Position, item.Color = size, position, color
	item.Material = Enum.Material.Sand
	item.Parent = parent
	return item
end

local function decoration(parent,name,position,size,color)
 local node=part(parent,name,position,size,color)
 node.Material=Enum.Material.SmoothPlastic
 node.CanCollide,node.CanTouch,node.CanQuery=false,false,false
 node.TopSurface,node.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 return node
end

local function createCrate(x,z,index)
 local box=part(obstacles,"BreakableCrate",Vector3.new(x,2,z),Vector3.new(4,4,4),Color3.fromRGB(133,88,54))
 box.Transparency=1 box.CanCollide=false box:SetAttribute("Chunk",index) box:SetAttribute("BreakableCrate",true)
 decoration(box,"WoodCore",box.Position,Vector3.new(3.6,3.6,3.6),Color3.fromRGB(143,97,59))
 for _,side in ipairs({-1,1}) do
  for _,height in ipairs({0.25,3.75}) do
   decoration(box,"Frame",Vector3.new(x,height,z+side*1.94),Vector3.new(4,0.5,0.25),Color3.fromRGB(218,163,94))
  end
  for _,edge in ipairs({-1,1}) do
   decoration(box,"Corner",Vector3.new(x+edge*1.75,2,z+side*1.94),Vector3.new(0.5,4,0.25),Color3.fromRGB(218,163,94))
  end
  local brace=decoration(box,"DiagonalBrace",Vector3.new(x,2,z+side*2),Vector3.new(4.4,0.45,0.2),Color3.fromRGB(195,137,77))
  brace.CFrame*=CFrame.Angles(0,0,math.pi/4)
 end
 return box
end

local function dressObstacle(rock,style,scale)
 rock.Transparency=1 rock:SetAttribute("Style",style) rock:SetAttribute("Scale",scale)
 local base=Vector3.new(rock.Position.X,0,rock.Position.Z)
 local function detail(name,pos,size,color)
  return decoration(rock,name,base+pos*scale,size*scale,color)
 end
 if style=="Tree" then
  detail("TreeTrunk",Vector3.new(0,2.2,0),Vector3.new(1.25,4.4,1.25),Color3.fromRGB(146,101,70))
  detail("TreeRoots",Vector3.new(0,0.25,0),Vector3.new(2.4,0.5,2.4),Color3.fromRGB(165,117,77))
  detail("LeafCrown",Vector3.new(0,4.3,0),Vector3.new(3.8,2.1,3.8),Color3.fromRGB(112,165,85))
  detail("LeafTop",Vector3.new(-0.2,5.65,0.1),Vector3.new(2.8,0.7,2.8),Color3.fromRGB(153,195,105))
  detail("LeafHighlight",Vector3.new(0.7,5.25,-0.7),Vector3.new(1.8,0.25,1.5),Color3.fromRGB(174,210,119))
 else
  local stone=detail("Boulder",Vector3.new(0,1.15,0),Vector3.new(3.8,2.3,3.8),Color3.fromRGB(177,157,123))
  stone.CFrame*=CFrame.Angles(0,0,0.06)
  detail("StoneCap",Vector3.new(-0.3,2.5,0.15),Vector3.new(2.7,0.7,2.6),Color3.fromRGB(199,181,143))
  detail("Moss",Vector3.new(-0.6,2.91,0.1),Vector3.new(1.6,0.12,1.5),Color3.fromRGB(124,166,87))
  detail("StoneChip",Vector3.new(1.45,0.4,1.35),Vector3.new(0.9,0.8,0.9),Color3.fromRGB(163,146,113))
 end
end

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
 rideSpeed = config.Monster.RunSpeed or tuning.ForwardStudsPerSecond
	obstacles = Instance.new("Folder")
	obstacles.Name, obstacles.Parent = "Obstacles", root
	local preview = root:FindFirstChild("PreviewMonster")
	if preview then preview:Destroy() end
	local floor = root:FindFirstChild("PreviewGround")
	if floor then floor:Destroy() end
end

function World.spawn(position)
	local model = template:Clone()
	model.Name = monsterId
	model:SetAttribute("MonsterId", monsterId)
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",rideSpeed)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1
	animals[model] = Motion.new(position.X,spawnSerial)
	return model
end

function World.ensure(z)
	local center = math.floor(z / tuning.GroundChunkStuds + 0.5)
	for index = center - 2, center + 1 do
		if chunks[index] or index*tuning.GroundChunkStuds < -Course.LengthStuds-128 or index*tuning.GroundChunkStuds>128 then continue end
		local chunk = Instance.new("Folder")
		chunk.Name, chunk.Parent = "Road_" .. index, root
		chunks[index] = chunk
		local start = index * tuning.GroundChunkStuds
		local meadow=part(chunk, "Meadow", Vector3.new(0,-1,start), Vector3.new(80,2,tuning.GroundChunkStuds), Color3.fromRGB(178,211,117))
  meadow.Material=Enum.Material.SmoothPlastic
		local random = Random.new(9101 + math.abs(index) * 137)
		for offset = -112,112,32 do
			local rowZ = start + offset
   if rowZ < -Course.LengthStuds or rowZ>128 then continue end
   local edge=Course.width(rowZ)
   local median=Course.median(rowZ)
   if median>0 then
    decoration(chunk,"ForkRidge",Vector3.new(0,1.5,rowZ),Vector3.new(median*2,3,32),Color3.fromRGB(203,143,91))
    decoration(chunk,"ForkGrass",Vector3.new(0,3.1,rowZ),Vector3.new(median*2,0.2,32),Color3.fromRGB(133,179,96))
   end
   for _, side in ipairs({-1,1}) do
    local height=8+random:NextInteger(0,3)
    decoration(chunk,"CanyonBase",Vector3.new(side*(edge+5),2,rowZ),Vector3.new(10,4,32),Color3.fromRGB(220,151,97))
    decoration(chunk,"CanyonStratum",Vector3.new(side*(edge+7),4.5,rowZ),Vector3.new(10,1,32),Color3.fromRGB(249,191,128))
    decoration(chunk,"CanyonUpper",Vector3.new(side*(edge+9),5+height/2,rowZ),Vector3.new(12,height,32),Color3.fromRGB(201,126,80))
    decoration(chunk,"GrassCap",Vector3.new(side*(edge+9),5+height+0.25,rowZ),Vector3.new(12,0.5,32),Color3.fromRGB(122,170,92))
    decoration(chunk,"GrassEdge",Vector3.new(side*(edge-3),0.08,rowZ),Vector3.new(6,0.16,32),Color3.fromRGB(143,190,96))
    for i=1,3 do
     local z=rowZ+random:NextNumber(-14,14)
     local x=side*random:NextNumber(edge-3,edge-1)
     decoration(chunk,"GrassTuft",Vector3.new(x,0.45,z),Vector3.new(0.5,0.9,0.5),Color3.fromRGB(109,161,77))
    end
    if random:NextNumber()<0.4 then
     local treeZ=rowZ+random:NextNumber(-8,8)
     decoration(chunk,"TreeTrunk",Vector3.new(side*(edge+13),5+height+2,treeZ),Vector3.new(1.4,4,1.4),Color3.fromRGB(152,99,67))
     decoration(chunk,"TreeCrown",Vector3.new(side*(edge+13),5+height+5,treeZ),Vector3.new(6,4,6),Color3.fromRGB(115,163,90))
     decoration(chunk,"TreeTop",Vector3.new(side*(edge+13),5+height+7,treeZ),Vector3.new(4,2,4),Color3.fromRGB(146,190,107))
    end
   end
   for i=1,3 do
    decoration(chunk,"MeadowPatch",Vector3.new(random:NextNumber(-29,29),0.025,rowZ+random:NextNumber(-14,14)),Vector3.new(random:NextNumber(2,5),0.05,random:NextNumber(3,8)),Color3.fromRGB(187,218,128))
   end
			-- Leave the run launch area clear; all other rows contain moving herds.
			if rowZ < -20 or rowZ > 30 then
				local lanes={}
    local ranges=Course.ranges(rowZ,4)
    for _,range in ipairs(ranges) do
     for i=1,4/#ranges do table.insert(lanes,range[1]+(range[2]-range[1])*i/(4/#ranges+1)) end
    end
    for _, x in ipairs(lanes) do
					if random:NextNumber() < tuning.HerdSpawnChance then World.spawn(Vector3.new(x,2,rowZ)) end
				end
				if random:NextNumber() < tuning.RockSpawnChance then
					local kind=(math.abs(index)*8+math.floor((offset+112)/32))%4
     local style=kind>=2 and "Tree" or "MossyRock"
     local scale=kind%2==1 and 2 or 1
     local bounds=Course.ranges(rowZ-12,2*scale+2)
     local range=bounds[random:NextInteger(1,#bounds)]
     local x=random:NextNumber(range[1],range[2])
     local height=(style=="Tree" and 6 or 3)*scale
     local rock=part(obstacles,"Rock",Vector3.new(x,height/2,rowZ-12),Vector3.new(4*scale,height,4*scale),Color3.fromRGB(167,130,99))
     rock:SetAttribute("Chunk",index)
     rock.CanCollide=false -- server swept collision is authoritative
     dressObstacle(rock,style,scale)
				end

    -- Independent seeded rolls keep existing herd/rock density unchanged.
    if rowZ < -96 then
     local crateRandom=Random.new(33017+math.abs(math.floor(rowZ))*31)
     if crateRandom:NextNumber()<tuning.CrateSpawnChance then
      local clear=true
      for existing in pairs(crateRows) do if math.abs(existing-rowZ)<192 then clear=false break end end
      if clear then
       local ranges=Course.ranges(rowZ,5)
       local range=ranges[crateRandom:NextInteger(1,#ranges)]
       local x=crateRandom:NextNumber(range[1],range[2])
       -- Crates need their own clear footprint beside trees/rocks.
       for _,other in ipairs(obstacles:GetChildren()) do
        if math.abs(other.Position.Z-rowZ)<other.Size.Z/2+4 and math.abs(other.Position.X-x)<other.Size.X/2+4 then clear=false break end
       end
       if clear then createCrate(x,rowZ,index) crateRows[rowZ]=index end
      end
     end
    end
			end
		end
	end
end

function World.step(dt)
 local rocks={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if rock:IsA("BasePart") and not rock:GetAttribute("Broken") then table.insert(rocks,{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z}) end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx=Motion.step(motion,p.X,p.Z,dt,rocks,tuning,half.X,half.Z,Rules,Course)
   model.PrimaryPart.CFrame=CFrame.new(x,p.Y,z)*CFrame.Angles(0,-math.atan2(vx,tuning.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

function World.nearest(position, excluded)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Maintain a camera-sized moving window, not the whole generated road.
function World.replenish(z,aspect)
 aspect=aspect or 1
 local count=0
 for model in pairs(animals) do
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   if Visibility.visible(p.X,p.Y,p.Z-z,aspect,tuning) then count+=1 end
  end
 end
 -- Two extra animals buffer movement between server refreshes.
 if count>=6 then return end
 for offset=20,100,16 do
  local targetZ=z-offset
  -- Keep the last running screen populated; the run still stops at 1,000m.
  if targetZ < -Course.LengthStuds-100 then continue end
  local ranges=Course.ranges(targetZ,3)
  local rowCount=0
  for _,i in ipairs({3,4,2,5,1,6}) do
   for _,range in ipairs(ranges) do
    local x=range[1]+(range[2]-range[1])*i/7
    local safe=Visibility.visible(x,2,targetZ-z,aspect,tuning)
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+2 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+4 then safe=false break end
    end
    if safe then
     for other in pairs(animals) do
      if other.Parent and math.abs(other.PrimaryPart.Position.X-x)<5 and math.abs(other.PrimaryPart.Position.Z-targetZ)<10 then safe=false break end
     end
    end
    if safe then World.spawn(Vector3.new(x,2,targetZ)) count+=1 rowCount+=1 end
    if count>=6 then return end
    if rowCount>=2 then break end
   end
   if rowCount>=2 then break end
  end
 end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount)
 local half=mount.PrimaryPart.Size/2
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  if not Course.contains(p.X,p.Z-half.Z,half.X) or not Course.contains(p.X,p.Z+half.Z,half.X) then return "Wall" end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then return "Monster" end
 end
 return nil
end

function World.hit(from, to)
	for _, rock in ipairs(obstacles:GetChildren()) do
		if rock:GetAttribute("Broken") then continue end
		local p,s = rock.Position,rock.Size
		if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then return true end
	end
	return false
end

function World.crateHit(from,to,mount,sizeClass)
 for _,box in ipairs(obstacles:GetChildren()) do
  if not box:GetAttribute("BreakableCrate") or box:GetAttribute("Broken") then continue end
  local p,s=box.Position,box.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0) then
   if sizeClass~="Medium" and sizeClass~="Large" then return true end
   box.CanQuery=false box.CanTouch=false
   box:SetAttribute("Broken",true) box:SetAttribute("BrokenAt",workspace:GetServerTimeNow())
   for _,piece in ipairs(box:GetDescendants()) do if piece:IsA("BasePart") then piece.Transparency=1 piece.CanQuery=false end end
   -- Loot is deliberately pending the user's item design.
  end
 end
 return false
end

-- Preserve each active runner's vicinity, and avoid unlimited course/animal growth.
function World.cleanup(nearZ)
	for index, chunk in pairs(chunks) do
		local keep = false
		for _, z in ipairs(nearZ) do if math.abs(index*tuning.GroundChunkStuds-z) < tuning.GroundChunkStuds*4 then keep = true break end end
		if not keep then
			chunk:Destroy()
			chunks[index] = nil
			for _, rock in ipairs(obstacles:GetChildren()) do if rock:GetAttribute("Chunk") == index then rock:Destroy() end end
			for z,owner in pairs(crateRows) do if owner==index then crateRows[z]=nil end end
		end
	end
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < tuning.GroundChunkStuds*4 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
