-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}
local warnings = {}
local package = game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local template = package:WaitForChild("VisualTemplate")
local tuning = require(package:WaitForChild("Config")).Prototype
local restFrames = {}
for _, part in ipairs(template:GetDescendants()) do
 if part:IsA("BasePart") and part ~= template.PrimaryPart then
  restFrames[part.Name] = template.PrimaryPart.CFrame:ToObjectSpace(part.CFrame)
 end
end

local function remember(model)
	local root = model.PrimaryPart
	if not root then return nil end
	local pose = {frame = root.CFrame, sample = root.CFrame, received = nil}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			local side = string.sub(part.Name,1,4)=="Left" and "Left" or string.sub(part.Name,1,5)=="Right" and "Right" or nil
			local movingLeg = side and (string.find(part.Name,"Leg",1,true) or string.find(part.Name,"Paw",1,true) or string.find(part.Name,"HoofLine",1,true))
			local leg = movingLeg and (string.find(part.Name,"Front",1,true) and "Front" or "Back") or nil
			if not leg then side=nil end
			table.insert(pose, { part = part, rest = restFrames[part.Name] or root.CFrame:ToObjectSpace(part.CFrame), side = side, leg = leg })
		end
	end
	poses[model] = pose
	return pose
end

function RideAnimator.update(monsters, clock, cameraPosition, dt)
 dt = dt or 1/60
 local displayed = {}
	for model, pose in pairs(poses) do
		if model.Parent ~= monsters then poses[model] = nil end
	end
	for model, warning in pairs(warnings) do
		if model.Parent ~= monsters then warning:Destroy() warnings[model] = nil end
	end
	for _, model in ipairs(monsters:GetChildren()) do
		local root = model.PrimaryPart
		if not root then continue end
  local nameplate = root:FindFirstChild("Nameplate")
  if nameplate then nameplate.Enabled = model:GetAttribute("Running") ~= true end
		if cameraPosition then
   local hidden=(root.Position-cameraPosition).Magnitude>220
   for _,part in ipairs(model:GetChildren()) do
    if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=hidden and 1 or 0 end
   end
   if hidden then continue end
  end
		local running = model:GetAttribute("Running") == true
		local pose = poses[model]
		if not pose and not running then continue end
		pose = pose or remember(model)
  if pose.sample ~= root.CFrame or not pose.received then
   pose.sample, pose.received = root.CFrame, clock
  end
  local elapsed = math.clamp(clock-pose.received,0,0.08)
  local speed = model:GetAttribute("Occupied") and tuning.ForwardStudsPerSecond or tuning.HerdStudsPerSecond
  local steer = model:GetAttribute("Steering") or 0
  local target = pose.sample + Vector3.new(steer*tuning.SidewaysStudsPerSecond,0,-speed)*(running and elapsed or 0)
  if (target.Position-pose.frame.Position).Magnitude>30 or not running then
   pose.frame = target
  else
   pose.frame = pose.frame:Lerp(target,1-math.exp(-22*dt))
  end
  displayed[model] = pose.frame
		local phase = (clock - (model:GetAttribute("RunStarted") or clock)) * math.pi * 7
		local angry = model:GetAttribute("Angry") == true
		local warning = warnings[model]
		if angry and not warning then
			warning = Instance.new("BillboardGui")
			warning.Name, warning.Size, warning.StudsOffset = "AngerWarning", UDim2.fromOffset(60, 70), Vector3.new(0, 4.5, 0)
			warning.AlwaysOnTop, warning.Adornee, warning.Parent = true, root, root
			local label = Instance.new("TextLabel")
			label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1, 1), 1, "!"
			label.Font, label.TextSize = Enum.Font.GothamBlack, 58
			label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(255, 104, 55), 0
			label.Parent = warning
			warnings[model] = warning
		end
		if warning then warning.Enabled = angry end
		local bob = angry and 0.2 * math.sin(phase * 2) or 0
		local lean = running and (model:GetAttribute("Steering") or 0) * -0.09 or 0
		local frame = pose.frame * CFrame.new(0, bob, 0) * CFrame.Angles(angry and math.sin(phase)*0.08 or 0, 0, lean)
		for _, entry in ipairs(pose) do
			if not entry.part.Parent then continue end
			local localFrame = entry.rest
			if running and entry.side then
				local opposite = (entry.side == "Left") ~= (entry.leg == "Front")
				local swing = math.sin(phase + (opposite and math.pi or 0)) * 0.55
				local joint = CFrame.new(entry.side == "Left" and -0.88 or 0.88, -0.87, entry.leg == "Front" and -0.91 or 1.17)
				localFrame = CFrame.new(0,math.max(0,math.sin(phase + (opposite and math.pi or 0)))*0.22,0) * joint * CFrame.Angles(swing, 0, 0) * joint:Inverse() * entry.rest
			end
			entry.part.CFrame = frame * localFrame
		end
		if not running then poses[model] = nil end
	end
 return displayed
end

return RideAnimator
