assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local shared=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"게임 시스템 없음")
local server=game:GetService("ServerScriptService")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"로비 없음")
local changes={{parent=server,name="HuntWorld",after=[========[-- Restored pre-Raise-Animal meadow/canyon map, with current rig and private sessions.
local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId,rideSpeed
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
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

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height,position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
	return model
end

function World.groundHeight(x,z) return 0 end

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
   if rowZ < -Course.LengthStuds-160 or rowZ>128 then continue end
   local edge=Course.width(rowZ)
   local median=Course.median(rowZ)
   if median>0 then
    decoration(chunk,"ForkRidge",Vector3.new(0,1.5,rowZ),Vector3.new(median*2,3,32),Color3.fromRGB(203,143,91))
    decoration(chunk,"ForkGrass",Vector3.new(0,3.1,rowZ),Vector3.new(median*2,0.2,32),Color3.fromRGB(133,179,96))
   end
   for _, side in ipairs({-1,1}) do
    local height=18+random:NextInteger(0,3) -- wall top remains above flying creatures
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
					-- Herd spawning is coordinated across all runners below, not tied to chunk creation.
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
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if rock:IsA("BasePart") and not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,p.Y,z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

local displayed=setmetatable({},{__mode="k"})
local released=setmetatable({},{__mode="k"})
function World.resetVisibility(viewer) displayed[viewer]=nil released[viewer]=nil end
function World.releaseMount(model,viewer)
 if not model or not model.Parent or not animals[model] or not viewer then return end
 released[viewer]=released[viewer] or {}
 released[viewer][model]=true
end
function World.atDen() return false end
function World.visibleSet(z,aspect,viewer)
 local candidates={}
 local riding=false
 for model in pairs(animals) do
  if model.Parent and model:GetAttribute("Occupied") then riding=true end
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0})
  end
 end
 local preferred=viewer and released[viewer]
 if preferred then
  for model in pairs(preferred) do
   local p=model.Parent and model.PrimaryPart and model.PrimaryPart.Position
   if not p or model:GetAttribute("Occupied") or not Visibility.visible(p.X,p.Y,p.Z-z,aspect or 1,tuning,1) then preferred[model]=nil end
  end
 end
 -- Reserve the occupied runner's slot before launch, so releasing it cannot
 -- evict a different wild runner that is still in the middle of the screen.
 local target=Visibility.capacity(Course.width(z))-(riding and 1 or 0)
 local previous=viewer and displayed[viewer]
 local limit=Visibility.transitionLimit(candidates,z,aspect or 1,tuning,target,previous,preferred)
 local result=Visibility.select(candidates,z,aspect or 1,tuning,limit,previous,preferred)
 if viewer then displayed[viewer]=result end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Private run: preload the opening scene; later births are strictly beyond the camera.
function World.replenish(z,aspect,watchers,prime,budget)
 aspect=aspect or 1
 local created=0
 local lanes={-0.72,-0.24,0.24,0.72}
 for offset=prime and -12 or 0,220,8 do
  if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
  local targetZ=z-offset
  if -targetZ*tuning.MetersPerStud>=Catalog.MeadowEndMeters then continue end
  local id=Catalog.pick(math.max(0,-z*tuning.MetersPerStud),spawnSerial)
  if not id then break end
  for _,range in ipairs(Course.ranges(targetZ,5)) do
   local narrow=Course.width(targetZ)<30
   if narrow and (offset-(prime and -12 or 0))%16~=0 then continue end
   for laneIndex,lane in ipairs(narrow and {-0.5,0.5} or lanes) do
    local x=(range[1]+range[2])/2+lane*(range[2]-range[1])/2
    local onScreen=Visibility.visible(x,Catalog[id].RootHeight,targetZ-z,aspect,tuning,1.2)
    if onScreen and not prime then continue end
    local safe=true
    for other in pairs(animals) do
     if other.Parent then local p=other.PrimaryPart.Position if math.abs(p.X-x)<8 and math.abs(p.Z-targetZ)<18 then safe=false break end end
    end
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not Catalog[id].Flying and not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+5 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+10 then safe=false break end
    end
    if safe then
     local model=World.spawn(Vector3.new(x,2,targetZ),id)
     model:SetAttribute("BornOutsideView",not onScreen)
     model:SetAttribute("OpeningScene",prime==true)
     created+=1
    end
    if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
   end
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect,nil,false,12) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  if not Course.contains(p.X,p.Z-half.Z,half.X,flying) or not Course.contains(p.X,p.Z+half.Z,half.X,flying) then return "Wall" end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

local function breakObstacle(rock,respawn)
 local appearance={}
 for _,piece in ipairs(rock:GetDescendants()) do
  if piece:IsA("BasePart") then appearance[piece]=piece.Transparency piece.Transparency=1 piece.CanQuery=false end
 end
 rock:SetAttribute("Broken",true) rock:SetAttribute("BrokenAt",workspace:GetServerTimeNow()) rock.CanQuery=false
 if respawn then task.delay(5,function()
  if not rock.Parent then return end
  for piece,transparency in pairs(appearance) do if piece.Parent then piece.Transparency=transparency end end
  rock:SetAttribute("Broken",false) rock.CanQuery=true
 end) end
end
function World.hit(from, to, flying,mount,dashing)
	for _, rock in ipairs(obstacles:GetChildren()) do
  if mount and rock:GetAttribute("BreakableCrate") then continue end -- dedicated crateHit rule
		if rock:GetAttribute("Broken") or (flying and rock:GetAttribute("WallClass")~="High" and rock:GetAttribute("ObstacleSize")~="Large") then continue end
		local p,s = rock.Position,rock.Size
		if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then
   local obstacleSize=rock:GetAttribute("ObstacleSize") or (rock:GetAttribute("Scale")==1 and "Small" or nil)
   if mount and Rules.canBreakObstacle(mount:GetAttribute("SizeClass"),obstacleSize,dashing) then breakObstacle(rock,true)
   else return true end
  end
	end
	return false
end

function World.crateHit(from,to,mount,sizeClass,dashing)
 if mount:GetAttribute("Flying") then return false end
 for _,box in ipairs(obstacles:GetChildren()) do
  if not box:GetAttribute("BreakableCrate") or box:GetAttribute("Broken") then continue end
  local p,s=box.Position,box.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0) then
   if not Rules.canBreakCrate(sizeClass) then return true end
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
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]========],allowed={[========[-- Restored pre-Raise-Animal meadow/canyon map, with current rig and private sessions.
local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId,rideSpeed
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
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

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height,position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
	return model
end

function World.groundHeight(x,z) return 0 end

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
   if rowZ < -Course.LengthStuds-160 or rowZ>128 then continue end
   local edge=Course.width(rowZ)
   local median=Course.median(rowZ)
   if median>0 then
    decoration(chunk,"ForkRidge",Vector3.new(0,1.5,rowZ),Vector3.new(median*2,3,32),Color3.fromRGB(203,143,91))
    decoration(chunk,"ForkGrass",Vector3.new(0,3.1,rowZ),Vector3.new(median*2,0.2,32),Color3.fromRGB(133,179,96))
   end
   for _, side in ipairs({-1,1}) do
    local height=18+random:NextInteger(0,3) -- wall top remains above flying creatures
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
					-- Herd spawning is coordinated across all runners below, not tied to chunk creation.
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
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if rock:IsA("BasePart") and not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,p.Y,z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

local displayed=setmetatable({},{__mode="k"})
local released=setmetatable({},{__mode="k"})
function World.resetVisibility(viewer) displayed[viewer]=nil released[viewer]=nil end
function World.releaseMount(model,viewer)
 if not model or not model.Parent or not animals[model] or not viewer then return end
 released[viewer]=released[viewer] or {}
 released[viewer][model]=true
end
function World.atDen() return false end
function World.visibleSet(z,aspect,viewer)
 local candidates={}
 local riding=false
 for model in pairs(animals) do
  if model.Parent and model:GetAttribute("Occupied") then riding=true end
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0})
  end
 end
 local preferred=viewer and released[viewer]
 if preferred then
  for model in pairs(preferred) do
   local p=model.Parent and model.PrimaryPart and model.PrimaryPart.Position
   if not p or model:GetAttribute("Occupied") or not Visibility.visible(p.X,p.Y,p.Z-z,aspect or 1,tuning,1) then preferred[model]=nil end
  end
 end
 -- Reserve the occupied runner's slot before launch, so releasing it cannot
 -- evict a different wild runner that is still in the middle of the screen.
 local target=Visibility.capacity(Course.width(z))-(riding and 1 or 0)
 local previous=viewer and displayed[viewer]
 local limit=Visibility.transitionLimit(candidates,z,aspect or 1,tuning,target,previous,preferred)
 local result=Visibility.select(candidates,z,aspect or 1,tuning,limit,previous,preferred)
 if viewer then displayed[viewer]=result end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Private run: preload the opening scene; later births are strictly beyond the camera.
function World.replenish(z,aspect,watchers,prime,budget)
 aspect=aspect or 1
 local created=0
 local lanes={-0.72,-0.24,0.24,0.72}
 for offset=prime and -12 or 0,220,8 do
  if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
  local targetZ=z-offset
  if -targetZ*tuning.MetersPerStud>=Catalog.MeadowEndMeters then continue end
  local id=Catalog.pick(math.max(0,-z*tuning.MetersPerStud),spawnSerial)
  if not id then break end
  for _,range in ipairs(Course.ranges(targetZ,5)) do
   local narrow=Course.width(targetZ)<30
   if narrow and (offset-(prime and -12 or 0))%16~=0 then continue end
   for laneIndex,lane in ipairs(narrow and {-0.5,0.5} or lanes) do
    local x=(range[1]+range[2])/2+lane*(range[2]-range[1])/2
    local onScreen=Visibility.visible(x,Catalog[id].RootHeight,targetZ-z,aspect,tuning,1.2)
    if onScreen and not prime then continue end
    local safe=true
    for other in pairs(animals) do
     if other.Parent then local p=other.PrimaryPart.Position if math.abs(p.X-x)<8 and math.abs(p.Z-targetZ)<18 then safe=false break end end
    end
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not Catalog[id].Flying and not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+5 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+10 then safe=false break end
    end
    if safe then
     local model=World.spawn(Vector3.new(x,2,targetZ),id)
     model:SetAttribute("BornOutsideView",not onScreen)
     model:SetAttribute("OpeningScene",prime==true)
     created+=1
    end
    if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
   end
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect,nil,false,12) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  if not Course.contains(p.X,p.Z-half.Z,half.X,flying) or not Course.contains(p.X,p.Z+half.Z,half.X,flying) then return "Wall" end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

local function breakObstacle(rock,respawn)
 local appearance={}
 for _,piece in ipairs(rock:GetDescendants()) do
  if piece:IsA("BasePart") then appearance[piece]=piece.Transparency piece.Transparency=1 piece.CanQuery=false end
 end
 rock:SetAttribute("Broken",true) rock:SetAttribute("BrokenAt",workspace:GetServerTimeNow()) rock.CanQuery=false
 if respawn then task.delay(5,function()
  if not rock.Parent then return end
  for piece,transparency in pairs(appearance) do if piece.Parent then piece.Transparency=transparency end end
  rock:SetAttribute("Broken",false) rock.CanQuery=true
 end) end
end
function World.hit(from, to, flying,mount,dashing)
	for _, rock in ipairs(obstacles:GetChildren()) do
  if mount and rock:GetAttribute("BreakableCrate") then continue end -- dedicated crateHit rule
		if rock:GetAttribute("Broken") or (flying and rock:GetAttribute("WallClass")~="High" and rock:GetAttribute("ObstacleSize")~="Large") then continue end
		local p,s = rock.Position,rock.Size
		if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then
   local obstacleSize=rock:GetAttribute("ObstacleSize") or (rock:GetAttribute("Scale")==1 and "Small" or nil)
   if mount and Rules.canBreakObstacle(mount:GetAttribute("SizeClass"),obstacleSize,dashing) then breakObstacle(rock,true)
   else return true end
  end
	end
	return false
end

function World.crateHit(from,to,mount,sizeClass,dashing)
 if mount:GetAttribute("Flying") then return false end
 for _,box in ipairs(obstacles:GetChildren()) do
  if not box:GetAttribute("BreakableCrate") or box:GetAttribute("Broken") then continue end
  local p,s=box.Position,box.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0) then
   if not Rules.canBreakCrate(sizeClass) then return true end
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
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]========],[========[local terrainData=require(game.ReplicatedStorage.RodeoFantasy.GreenStarLayout)
local groundPlates={}
for _,b in ipairs(terrainData.blocks) do if b.kind=="Ground" then table.insert(groundPlates,b) end end
local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId,rideSpeed
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local spawnSerial=0
local crateRows={}

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
 rideSpeed = config.Monster.RunSpeed or tuning.ForwardStudsPerSecond
 local data=terrainData
 local boxes={}
 for _,b in ipairs(data.blocks) do if b.kind=="Obstacle" then
  table.insert(boxes,{Position=Vector3.new(table.unpack(b.position)),Size=Vector3.new(table.unpack(b.size)),GetAttribute=function() return nil end})
 end end
 obstacles={GetChildren=function() return boxes end}
	local preview = root:FindFirstChild("PreviewMonster")
	if preview then preview:Destroy() end
	local floor = root:FindFirstChild("PreviewGround")
	if floor then floor:Destroy() end
end

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height+World.groundHeight(position.X,position.Z),position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
	return model
end

function World.ensure(z) end -- The new 1km Stud map is already baked once.
function World.groundHeight(x,z)
 local height=0
 for _,b in ipairs(groundPlates) do
  if math.abs(x-b.position[1])<=b.size[1]/2 and math.abs(z-b.position[3])<=b.size[3]/2 then height=math.max(height,b.position[2]+b.size[2]/2) end
 end
 return height
end

function World.step(dt)
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,(model:GetAttribute("RootHeight") or 2)+World.groundHeight(x,z),z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

local displayed=setmetatable({},{__mode="k"})
local released=setmetatable({},{__mode="k"})
function World.resetVisibility(viewer) displayed[viewer]=nil released[viewer]=nil end
function World.releaseMount(model,viewer)
 if not model or not model.Parent or not animals[model] or not viewer then return end
 released[viewer]=released[viewer] or {}
 released[viewer][model]=true
end
function World.atDen() return false end
function World.visibleSet(z,aspect,viewer)
 local candidates={}
 local riding=false
 for model in pairs(animals) do
  if model.Parent and model:GetAttribute("Occupied") then riding=true end
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0})
  end
 end
 local preferred=viewer and released[viewer]
 if preferred then
  for model in pairs(preferred) do
   local p=model.Parent and model.PrimaryPart and model.PrimaryPart.Position
   if not p or model:GetAttribute("Occupied") or not Visibility.visible(p.X,p.Y,p.Z-z,aspect or 1,tuning,1) then preferred[model]=nil end
  end
 end
 -- Reserve the occupied runner's slot before launch, so releasing it cannot
 -- evict a different wild runner that is still in the middle of the screen.
 local target=Visibility.capacity(Course.width(z))-(riding and 1 or 0)
 local previous=viewer and displayed[viewer]
 local limit=Visibility.transitionLimit(candidates,z,aspect or 1,tuning,target,previous,preferred)
 local result=Visibility.select(candidates,z,aspect or 1,tuning,limit,previous,preferred)
 if viewer then displayed[viewer]=result end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Private run: preload the opening scene; later births are strictly beyond the camera.
function World.replenish(z,aspect,watchers,prime,budget)
 aspect=aspect or 1
 local created=0
 local lanes={-0.72,-0.24,0.24,0.72}
 for offset=prime and -12 or 0,220,8 do
  if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
  local targetZ=z-offset
  if -targetZ*tuning.MetersPerStud>=Catalog.MeadowEndMeters then continue end
  local id=Catalog.pick(math.max(0,-z*tuning.MetersPerStud),spawnSerial)
  if not id then break end
  for _,range in ipairs(Course.ranges(targetZ,5)) do
   local narrow=Course.width(targetZ)<30
   if narrow and (offset-(prime and -12 or 0))%16~=0 then continue end
   for laneIndex,lane in ipairs(narrow and {-0.5,0.5} or lanes) do
    local x=(range[1]+range[2])/2+lane*(range[2]-range[1])/2
    local onScreen=Visibility.visible(x,Catalog[id].RootHeight,targetZ-z,aspect,tuning,1.2)
    if onScreen and not prime then continue end
    local safe=true
    for other in pairs(animals) do
     if other.Parent then local p=other.PrimaryPart.Position if math.abs(p.X-x)<8 and math.abs(p.Z-targetZ)<18 then safe=false break end end
    end
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not Catalog[id].Flying and not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+5 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+10 then safe=false break end
    end
    if safe then
     local model=World.spawn(Vector3.new(x,2,targetZ),id)
     model:SetAttribute("BornOutsideView",not onScreen)
     model:SetAttribute("OpeningScene",prime==true)
     created+=1
    end
    if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
   end
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect,nil,false,12) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  if not Course.contains(p.X,p.Z-half.Z,half.X,flying) or not Course.contains(p.X,p.Z+half.Z,half.X,flying) then return "Wall" end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

function World.hit(from,to,flying)
 if flying then return false end
 for _,rock in ipairs(obstacles:GetChildren()) do
  local p,s=rock.Position,rock.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then return true end
 end
 return false
end
function World.crateHit() return false end

-- Preserve each active runner's vicinity, and avoid unlimited course/animal growth.
function World.cleanup(nearZ)
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]========],[========[local terrainData=require(game.ReplicatedStorage.RodeoFantasy.GreenStarLayout)
local groundPlates={}
for _,b in ipairs(terrainData.blocks) do if b.kind=="Ground" then table.insert(groundPlates,b) end end
local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId,rideSpeed
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local spawnSerial=0
local crateRows={}

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
 rideSpeed = config.Monster.RunSpeed or tuning.ForwardStudsPerSecond
 local data=terrainData
 local boxes={}
 for _,b in ipairs(data.blocks) do if b.kind=="Obstacle" then
  table.insert(boxes,{Position=Vector3.new(table.unpack(b.position)),Size=Vector3.new(table.unpack(b.size)),GetAttribute=function() return nil end})
 end end
 obstacles={GetChildren=function() return boxes end}
	local preview = root:FindFirstChild("PreviewMonster")
	if preview then preview:Destroy() end
	local floor = root:FindFirstChild("PreviewGround")
	if floor then floor:Destroy() end
end

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height+World.groundHeight(position.X,position.Z),position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
	return model
end

function World.ensure(z) end -- The new 1km Stud map is already baked once.
function World.groundHeight(x,z)
 local height=0
 for _,b in ipairs(groundPlates) do
  if math.abs(x-b.position[1])<=b.size[1]/2 and math.abs(z-b.position[3])<=b.size[3]/2 then height=math.max(height,b.position[2]+b.size[2]/2) end
 end
 return height
end

function World.step(dt)
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,(model:GetAttribute("RootHeight") or 2)+World.groundHeight(x,z),z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

local displayed=setmetatable({},{__mode="k"})
local released=setmetatable({},{__mode="k"})
function World.resetVisibility(viewer) displayed[viewer]=nil released[viewer]=nil end
function World.releaseMount(model,viewer)
 if not model or not model.Parent or not animals[model] or not viewer then return end
 released[viewer]=released[viewer] or {}
 released[viewer][model]=true
end
function World.atDen() return false end
function World.visibleSet(z,aspect,viewer)
 local candidates={}
 local riding=false
 for model in pairs(animals) do
  if model.Parent and model:GetAttribute("Occupied") then riding=true end
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0})
  end
 end
 local preferred=viewer and released[viewer]
 if preferred then
  for model in pairs(preferred) do
   local p=model.Parent and model.PrimaryPart and model.PrimaryPart.Position
   if not p or model:GetAttribute("Occupied") or not Visibility.visible(p.X,p.Y,p.Z-z,aspect or 1,tuning,1) then preferred[model]=nil end
  end
 end
 -- Reserve the occupied runner's slot before launch, so releasing it cannot
 -- evict a different wild runner that is still in the middle of the screen.
 local target=Visibility.capacity(Course.width(z))-(riding and 1 or 0)
 local previous=viewer and displayed[viewer]
 local limit=Visibility.transitionLimit(candidates,z,aspect or 1,tuning,target,previous,preferred)
 local result=Visibility.select(candidates,z,aspect or 1,tuning,limit,previous,preferred)
 if viewer then displayed[viewer]=result end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Private run: preload the opening scene; later births are strictly beyond the camera.
function World.replenish(z,aspect,watchers,prime,budget)
 aspect=aspect or 1
 local created=0
 local lanes={-0.72,-0.24,0.24,0.72}
 for offset=prime and -12 or 0,220,8 do
  if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
  local targetZ=z-offset
  if -targetZ*tuning.MetersPerStud>=Catalog.MeadowEndMeters then continue end
  local id=Catalog.pick(math.max(0,-z*tuning.MetersPerStud),spawnSerial)
  if not id then break end
  for _,range in ipairs(Course.ranges(targetZ,5)) do
   local narrow=Course.width(targetZ)<30
   if narrow and (offset-(prime and -12 or 0))%16~=0 then continue end
   for laneIndex,lane in ipairs(narrow and {-0.5,0.5} or lanes) do
    local x=(range[1]+range[2])/2+lane*(range[2]-range[1])/2
    local onScreen=Visibility.visible(x,Catalog[id].RootHeight,targetZ-z,aspect,tuning,1.2)
    if onScreen and not prime then continue end
    local safe=true
    for other in pairs(animals) do
     if other.Parent then local p=other.PrimaryPart.Position if math.abs(p.X-x)<8 and math.abs(p.Z-targetZ)<18 then safe=false break end end
    end
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not Catalog[id].Flying and not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+5 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+10 then safe=false break end
    end
    if safe then
     local model=World.spawn(Vector3.new(x,2,targetZ),id)
     model:SetAttribute("BornOutsideView",not onScreen)
     model:SetAttribute("OpeningScene",prime==true)
     created+=1
    end
    if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
   end
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect,nil,false,12) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  if not Course.contains(p.X,p.Z-half.Z,half.X,flying) or not Course.contains(p.X,p.Z+half.Z,half.X,flying) then return "Wall" end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

function World.hit(from,to,flying)
 if flying then return false end
 for _,rock in ipairs(obstacles:GetChildren()) do
  local p,s=rock.Position,rock.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then return true end
 end
 return false
end
function World.crateHit() return false end

-- Preserve each active runner's vicinity, and avoid unlimited course/animal growth.
function World.cleanup(nearZ)
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]========],[========[local terrainData=require(game.ReplicatedStorage.RodeoFantasy.GreenStarLayout)
local groundPlates={}
for _,b in ipairs(terrainData.blocks) do if b.kind=="Ground" then table.insert(groundPlates,b) end end
local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId,rideSpeed
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local spawnSerial=0
local crateRows={}

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
 rideSpeed = config.Monster.RunSpeed or tuning.ForwardStudsPerSecond
 local data=terrainData
 local boxes={}
 for _,b in ipairs(data.blocks) do if b.kind=="Obstacle" then
  table.insert(boxes,{Position=Vector3.new(table.unpack(b.position)),Size=Vector3.new(table.unpack(b.size)),GetAttribute=function() return nil end})
 end end
 obstacles={GetChildren=function() return boxes end}
	local preview = root:FindFirstChild("PreviewMonster")
	if preview then preview:Destroy() end
	local floor = root:FindFirstChild("PreviewGround")
	if floor then floor:Destroy() end
end

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height+World.groundHeight(position.X,position.Z),position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
	return model
end

function World.ensure(z) end -- The new 1km Stud map is already baked once.
function World.groundHeight(x,z)
 local height=0
 for _,b in ipairs(groundPlates) do
  if math.abs(x-b.position[1])<=b.size[1]/2 and math.abs(z-b.position[3])<=b.size[3]/2 then height=math.max(height,b.position[2]+b.size[2]/2) end
 end
 return height
end

function World.step(dt)
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,(model:GetAttribute("RootHeight") or 2)+World.groundHeight(x,z),z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

local displayed=setmetatable({},{__mode="k"})
local released=setmetatable({},{__mode="k"})
function World.resetVisibility(viewer) displayed[viewer]=nil released[viewer]=nil end
function World.releaseMount(model,viewer)
 if not model or not model.Parent or not animals[model] or not viewer then return end
 released[viewer]=released[viewer] or {}
 released[viewer][model]=true
end
function World.atDen() return false end
function World.visibleSet(z,aspect,viewer)
 local candidates={}
 local riding=false
 for model in pairs(animals) do
  if model.Parent and model:GetAttribute("Occupied") then riding=true end
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0})
  end
 end
 local preferred=viewer and released[viewer]
 if preferred then
  for model in pairs(preferred) do
   local p=model.Parent and model.PrimaryPart and model.PrimaryPart.Position
   if not p or model:GetAttribute("Occupied") or not Visibility.visible(p.X,p.Y,p.Z-z,aspect or 1,tuning,1) then preferred[model]=nil end
  end
 end
 -- Reserve the occupied runner's slot before launch, so releasing it cannot
 -- evict a different wild runner that is still in the middle of the screen.
 local target=Visibility.capacity(Course.width(z))-(riding and 1 or 0)
 local previous=viewer and displayed[viewer]
 local limit=Visibility.transitionLimit(candidates,z,aspect or 1,tuning,target,previous,preferred)
 local result=Visibility.select(candidates,z,aspect or 1,tuning,limit,previous,preferred)
 if viewer then displayed[viewer]=result end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Private run: preload the opening scene; later births are strictly beyond the camera.
function World.replenish(z,aspect,watchers,prime,budget)
 aspect=aspect or 1
 local created=0
 local lanes={-0.72,-0.24,0.24,0.72}
 for offset=prime and -12 or 0,220,8 do
  if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
  local targetZ=z-offset
  if -targetZ*tuning.MetersPerStud>=Catalog.MeadowEndMeters then continue end
  local id=Catalog.pick(math.max(0,-z*tuning.MetersPerStud),spawnSerial)
  if not id then break end
  for _,range in ipairs(Course.ranges(targetZ,5)) do
   local narrow=Course.width(targetZ)<30
   if narrow and (offset-(prime and -12 or 0))%16~=0 then continue end
   for laneIndex,lane in ipairs(narrow and {-0.5,0.5} or lanes) do
    local x=(range[1]+range[2])/2+lane*(range[2]-range[1])/2
    local onScreen=Visibility.visible(x,Catalog[id].RootHeight,targetZ-z,aspect,tuning,1.2)
    if onScreen and not prime then continue end
    local safe=true
    for other in pairs(animals) do
     if other.Parent then local p=other.PrimaryPart.Position if math.abs(p.X-x)<8 and math.abs(p.Z-targetZ)<18 then safe=false break end end
    end
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not Catalog[id].Flying and not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+5 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+10 then safe=false break end
    end
    if safe then
     local model=World.spawn(Vector3.new(x,2,targetZ),id)
     model:SetAttribute("BornOutsideView",not onScreen)
     model:SetAttribute("OpeningScene",prime==true)
     created+=1
    end
    if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
   end
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect,nil,false,12) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  if not Course.contains(p.X,p.Z-half.Z,half.X,flying) or not Course.contains(p.X,p.Z+half.Z,half.X,flying) then return "Wall" end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

function World.hit(from,to,flying)
 if flying then return false end
 for _,rock in ipairs(obstacles:GetChildren()) do
  local p,s=rock.Position,rock.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then return true end
 end
 return false
end
function World.crateHit() return false end

-- Preserve each active runner's vicinity, and avoid unlimited course/animal growth.
function World.cleanup(nearZ)
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]========]}},{parent=shared,name="CourseGeometry",after=[========[-- First meadow only. Distances below are layout trial values in studs.
local Course={LengthStuds=4800,LayoutScale=3,LengthMeters=1000}
local function ramp(d,a,b) return math.clamp((d-a)/(b-a),0,1) end
function Course.width(z)
 local d=math.max(0,-z/3)
 return 35-11*ramp(d,256,400)+11*ramp(d,600,800)
end
function Course.median(z)
 local d=math.max(0,-z/3)
 return 9*ramp(d,800,950)*(1-ramp(d,1200,1400))
end
function Course.ranges(z,padding,flying)
 local edge=Course.width(z)-padding
 local middle=Course.median(z)
 if middle>0 and not flying then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.planningRanges(z,horizon,padding)
 local edge=math.min(Course.width(z),Course.width(z-horizon),Course.width(z-horizon/2))-padding
 local middle=math.max(Course.median(z),Course.median(z-horizon),Course.median(z-horizon/2))
 if middle>0 then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.contains(x,z,padding,flying)
 for _,range in ipairs(Course.ranges(z,padding,flying)) do
  if x>range[1] and x<range[2] then return true end
 end
 return false
end
return Course
]========],allowed={[========[-- First meadow only. Distances below are layout trial values in studs.
local Course={LengthStuds=4800,LayoutScale=3,LengthMeters=1000}
local function ramp(d,a,b) return math.clamp((d-a)/(b-a),0,1) end
function Course.width(z)
 local d=math.max(0,-z/3)
 return 35-11*ramp(d,256,400)+11*ramp(d,600,800)
end
function Course.median(z)
 local d=math.max(0,-z/3)
 return 9*ramp(d,800,950)*(1-ramp(d,1200,1400))
end
function Course.ranges(z,padding,flying)
 local edge=Course.width(z)-padding
 local middle=Course.median(z)
 if middle>0 and not flying then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.planningRanges(z,horizon,padding)
 local edge=math.min(Course.width(z),Course.width(z-horizon),Course.width(z-horizon/2))-padding
 local middle=math.max(Course.median(z),Course.median(z-horizon),Course.median(z-horizon/2))
 if middle>0 then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.contains(x,z,padding,flying)
 for _,range in ipairs(Course.ranges(z,padding,flying)) do
  if x>range[1] and x<range[2] then return true end
 end
 return false
end
return Course
]========],[========[-- Green Star keeps the full 192-stud width for its entire 1,000m.
local C={LengthStuds=4800,LayoutScale=3,LengthMeters=1000}
function C.width() return 96 end
function C.median() return 0 end
function C.ranges(z,padding) return {{-96+padding,96-padding}} end
function C.planningRanges(z,horizon,padding) return C.ranges(z,padding) end
function C.contains(x,z,padding) local r=C.ranges(z,padding)[1] return x>r[1] and x<r[2] end
return C
]========],[========[-- Green Star keeps the full 192-stud width for its entire 1,000m.
local C={LengthStuds=4800,LayoutScale=3,LengthMeters=1000}
function C.width() return 96 end
function C.median() return 0 end
function C.ranges(z,padding) return {{-96+padding,96-padding}} end
function C.planningRanges(z,horizon,padding) return C.ranges(z,padding) end
function C.contains(x,z,padding) local r=C.ranges(z,padding)[1] return x>r[1] and x<r[2] end
return C
]========],[========[-- Green Star keeps the full 192-stud width for its entire 1,000m.
local C={LengthStuds=4800,LayoutScale=3,LengthMeters=1000}
function C.width() return 96 end
function C.median() return 0 end
function C.ranges(z,padding) return {{-96+padding,96-padding}} end
function C.planningRanges(z,horizon,padding) return C.ranges(z,padding) end
function C.contains(x,z,padding) local r=C.ranges(z,padding)[1] return x>r[1] and x<r[2] end
return C
]========]}},{parent=shared,name="Config",after=[========[-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=40 -- Adjustable presentation tuning for the larger lobby.

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 Wind="rbxassetid://2306939610", -- Creator Store wind; availability requires Studio verification.
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 35, -- Restored original meadow/canyon width.
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
]========],allowed={[========[-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=40 -- Adjustable presentation tuning for the larger lobby.

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 Wind="rbxassetid://2306939610", -- Creator Store wind; availability requires Studio verification.
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 35, -- Restored original meadow/canyon width.
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
]========],[========[-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=40 -- Adjustable presentation tuning for the larger lobby.

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 Wind="rbxassetid://2306939610", -- Creator Store wind; availability requires Studio verification.
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 94, -- 192-stud course with a 2-stud collision margin.
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
]========],[========[-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=40 -- Adjustable presentation tuning for the larger lobby.

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 Wind="rbxassetid://2306939610", -- Creator Store wind; availability requires Studio verification.
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 94, -- 192-stud course with a 2-stud collision margin.
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
]========],[========[-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=40 -- Adjustable presentation tuning for the larger lobby.

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 Wind="rbxassetid://2306939610", -- Creator Store wind; availability requires Studio verification.
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 94, -- 192-stud course with a 2-stud collision margin.
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
]========]}},{parent=clients,name="NativeMossrat",after=[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],allowed={[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========]}},{parent=clients,name="UserMossratRigAnimator",after=[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],allowed={[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========]}}}
local function norm(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 c.node=assert(c.parent:FindFirstChild(c.name),"모듈 없음: "..c.name)
 assert(c.node:IsA("ModuleScript"),"모듈 종류 불일치")
 local valid=false for _,s in ipairs(c.allowed) do if norm(s)==norm(c.node.Source) then valid=true break end end
 assert(valid,"수정된 코드가 있어 중단했습니다: "..c.name)
 c.before=c.node.Source
end
local old=workspace:FindFirstChild("GreenStar")
local marker=Instance.new("Model") marker.Name="GreenStar"
marker:SetAttribute("LegacyMeadowRestored",true)
local backup=Instance.new("Folder") backup.Name="LegacyHuntBackup_"..game:GetService("HttpService"):GenerateGUID(false)
local ready=lobby:GetAttribute("GreenStarRuntimeReady")
game:GetService("ChangeHistoryService"):SetWaypoint("Before legacy hunt restoration")
local ok,err=pcall(function()
 backup.Parent=game:GetService("ServerStorage")
 for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
 if old then old.Parent=backup end marker.Parent=workspace
 lobby:SetAttribute("GreenStarRuntimeReady",true)
end)
if not ok then
 for _,c in ipairs(changes) do c.node.Source=c.before end
 marker:Destroy() if old then old.Parent=workspace end
 lobby:SetAttribute("GreenStarRuntimeReady",ready) backup:Destroy() error(err)
end
game:GetService("ChangeHistoryService"):SetWaypoint("Legacy hunt and Mossrat facing restored")
print("LEGACY_HUNT_RESTORED — Ctrl+S 저장 후 Play. 중앙 E로 출발하여 맵·정면을 확인하세요.")
