local World = {}
local chunks, animals = {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId

local function part(parent, name, position, size, color)
	local item = Instance.new("Part")
	item.Name, item.Anchored = name, true
	item.Size, item.Position, item.Color = size, position, color
	item.Material = Enum.Material.Sand
	item.Parent = parent
	return item
end

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
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
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow())
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	animals[model] = true
	return model
end

function World.ensure(z)
	local center = math.floor(z / tuning.GroundChunkStuds + 0.5)
	for index = center - 2, center + 1 do
		if chunks[index] then continue end
		local chunk = Instance.new("Folder")
		chunk.Name, chunk.Parent = "Road_" .. index, root
		chunks[index] = chunk
		local start = index * tuning.GroundChunkStuds
		part(chunk, "Sand", Vector3.new(0,-1,start), Vector3.new(80,2,tuning.GroundChunkStuds), Color3.fromRGB(195,166,119))
		local random = Random.new(9101 + math.abs(index) * 137)
		for offset = -112,112,32 do
			local rowZ = start + offset
			for _, side in ipairs({-1,1}) do
				local wall = part(chunk, "Canyon", Vector3.new(side*44,4,rowZ), Vector3.new(8,8+random:NextInteger(0,4),32), Color3.fromRGB(174,115,68))
				wall.CanCollide = false
				local ledge = part(chunk, "CanyonLedge", Vector3.new(side*41,1,rowZ), Vector3.new(4,2,30), Color3.fromRGB(153,97,58))
				ledge.CanCollide = false
			end
			-- Leave the run launch area clear; all other rows contain moving herds.
			if rowZ < -20 or rowZ > 30 then
				for _, x in ipairs({-18,-6,6,18}) do
					if random:NextNumber() < 0.65 then World.spawn(Vector3.new(x,2,rowZ)) end
				end
				if random:NextNumber() < 0.55 then
					local rock = part(obstacles, "Rock", Vector3.new(random:NextInteger(-3,3)*8,1.5,rowZ-12), Vector3.new(4,3,4), Color3.fromRGB(126,91,65))
					rock:SetAttribute("Chunk", index)
					rock.CanCollide = false -- server swept collision is authoritative
				end
			end
		end
	end
end

function World.step(dt)
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil continue end
		if not model:GetAttribute("Occupied") then
			model:PivotTo(model:GetPivot() + Vector3.new(0,0,-tuning.HerdStudsPerSecond*dt))
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

function World.hit(from, to)
	for _, rock in ipairs(obstacles:GetChildren()) do
		local p,s = rock.Position,rock.Size
		if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then return true end
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
		end
	end
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < tuning.GroundChunkStuds*4 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil end
	end
end

return World
