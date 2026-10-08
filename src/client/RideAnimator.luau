-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}

local function remember(model)
	local root = model.PrimaryPart
	if not root then return nil end
	local pose = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			local side, leg = string.match(part.Name, "^(%a+)Front")
			if side ~= "Left" and side ~= "Right" then side = nil end
			if side then leg = "Front" else
				side = string.match(part.Name, "^(%a+)Back")
				if side ~= "Left" and side ~= "Right" then side = nil end
				if side then leg = "Back" end
			end
			table.insert(pose, { part = part, rest = root.CFrame:ToObjectSpace(part.CFrame), side = side, leg = leg })
		end
	end
	poses[model] = pose
	return pose
end

function RideAnimator.update(monsters, clock)
	for model, pose in pairs(poses) do
		if model.Parent ~= monsters then poses[model] = nil end
	end
	for _, model in ipairs(monsters:GetChildren()) do
		local root = model.PrimaryPart
		if not root then continue end
		local running = model:GetAttribute("Running") == true
		local pose = poses[model]
		if not pose and not running then continue end
		pose = pose or remember(model)
		local phase = (clock - (model:GetAttribute("RunStarted") or clock)) * math.pi * 7
		local bob = running and (0.07 * math.sin(phase * 2)) or 0
		local lean = running and (model:GetAttribute("Steering") or 0) * -0.09 or 0
		local frame = root.CFrame * CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, lean)
		for _, entry in ipairs(pose) do
			if not entry.part.Parent then continue end
			local localFrame = entry.rest
			if running and entry.side then
				local opposite = (entry.side == "Left") ~= (entry.leg == "Front")
				local swing = math.sin(phase + (opposite and math.pi or 0)) * 0.3
				local joint = CFrame.new(entry.side == "Left" and -0.87 or 0.87, -0.45, entry.leg == "Front" and -1.25 or 1.45)
				localFrame = joint * CFrame.Angles(swing, 0, 0) * joint:Inverse() * entry.rest
			end
			entry.part.CFrame = frame * localFrame
		end
		if not running then poses[model] = nil end
	end
end

return RideAnimator
