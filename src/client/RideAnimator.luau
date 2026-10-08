-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}
local visibility={}
local warnings = {}
local package = game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local template = package:WaitForChild("VisualTemplate")
local templateRoot=template:WaitForChild("MountRoot")
local tuning = require(package:WaitForChild("Config")).Prototype
local Rules = require(package:WaitForChild("HuntRules"))
local restFrames = {}
local dust={}
local function clearHerdPath(from,to,root)
 local world=workspace:FindFirstChild("RodeoPrototype")
 local obstacles=world and world:FindFirstChild("Obstacles")
 if not obstacles then return true end
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:IsA("BasePart") or rock:GetAttribute("Broken") then continue end
  local p,s=rock.Position,rock.Size+root.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0.2) then return false end
 end
 return true
end
for _, part in ipairs(template:GetDescendants()) do
 if part:IsA("BasePart") and part ~= templateRoot then
  restFrames[part.Name] = templateRoot.CFrame:ToObjectSpace(part.CFrame)
 end
end

local function remember(model, existing)
	local root = model.PrimaryPart
	if not root then return nil end
	local pose = existing or {frame = root.CFrame, sample = root.CFrame, received = nil, tracked={}}
 if existing and not pose.dirty then return pose end
 if not pose.watch then pose.watch=model.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then pose.dirty=true end end) end
 pose.dirty=false
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root and not pose.tracked[part] then
   if not restFrames[part.Name] then
    local reference=template:FindFirstChild(part.Name,true)
    if not reference or not reference:IsA("BasePart") then
     part.LocalTransparencyModifier=1 pose.dirty=true continue
    end
    restFrames[part.Name]=templateRoot.CFrame:ToObjectSpace(reference.CFrame)
   end
   part.LocalTransparencyModifier=0
			local side = string.sub(part.Name,1,4)=="Left" and "Left" or string.sub(part.Name,1,5)=="Right" and "Right" or nil
			local movingLeg = side and (string.find(part.Name,"Leg",1,true) or string.find(part.Name,"Paw",1,true) or string.find(part.Name,"HoofLine",1,true))
			local leg = movingLeg and (string.find(part.Name,"Front",1,true) and "Front" or "Back") or nil
			if not leg then side=nil end
			pose.tracked[part]=true
			table.insert(pose, { part = part, rest = restFrames[part.Name], side = side, leg = leg })
		end
	end
	poses[model] = pose
	return pose
end

function RideAnimator.update(monsters, clock, cameraPosition, dt)
 dt = dt or 1/60
 for i=#dust,1,-1 do
  local puff=dust[i] local age=clock-puff.started
  if age>=0.6 then puff.part:Destroy() table.remove(dust,i)
  else puff.part.Transparency=0.45+age/0.6*0.55 puff.part.Size=Vector3.one*(0.75+age*1.5) puff.part.Position+=Vector3.new(0,dt*0.7,0) end
 end
 local displayed = {}
 for model in pairs(visibility) do if model.Parent~=monsters then visibility[model]=nil end end
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
   local record=visibility[model]
   if not record then
    record={} visibility[model]=record
    record.connection=model.DescendantAdded:Connect(function(part)
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=record.hidden and 1 or 0 end
    end)
   end
   if record.hidden~=hidden then
    record.hidden=hidden
    for _,part in ipairs(model:GetChildren()) do
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=hidden and 1 or 0 end
    end
   end
   if hidden then continue end
  end
		local running = model:GetAttribute("Running") == true
		local pose = poses[model]
		if not pose and not running then continue end
		pose = remember(model,pose) -- Include late replicated body parts on every frame.
  if pose.sample ~= root.CFrame or not pose.received then
   pose.sample, pose.received = root.CFrame, clock
  end
  local elapsed = math.clamp(clock-pose.received,0,0.08)
  local speed = model:GetAttribute("Occupied") and Rules.rideSpeed(clock,model:GetAttribute("DashUntil"),(model:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond),tuning.SwitchDashMultiplier) or tuning.HerdStudsPerSecond
  local steer = model:GetAttribute("Steering") or 0
  local velocity=Vector3.new(steer*tuning.SidewaysStudsPerSecond,0,-speed)
  if not model:GetAttribute("Occupied") then velocity=model:GetAttribute("HerdVelocity") or velocity end
  local target = pose.sample + velocity*(running and elapsed or 0)
  if not model:GetAttribute("Occupied") and not clearHerdPath(pose.sample.Position,target.Position,root) then target=pose.sample end
  if (target.Position-pose.frame.Position).Magnitude>30 or not running then
   pose.frame = target
  else
   local blended=pose.frame:Lerp(target,1-math.exp(-22*dt))
   if not model:GetAttribute("Occupied") and not clearHerdPath(pose.frame.Position,blended.Position,root) then blended=pose.sample end
   pose.frame = blended
  end

		local phase = (clock - (model:GetAttribute("RunStarted") or clock)) * math.pi * 7
		local angry = model:GetAttribute("Angry") == true
		local warningActive = model:GetAttribute("AngerWarning") == true or angry
		local warning = warnings[model]
		if warningActive and not warning then
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
		if warning then
   warning.Enabled = warningActive
   local label=warning:FindFirstChildWhichIsA("TextLabel")
   if label then label.TextTransparency=0.15+math.max(0,math.sin(clock*12))*0.45 end
  end
		local _,_,pitch=Rules.buck(clock-(model:GetAttribute("AngerStarted") or clock),tuning.BuckCycleSeconds,tuning.BuckHeightStuds)
		local lean = running and (model:GetAttribute("Steering") or 0) * -0.18 or 0
  local moving=running and velocity.Magnitude>1
  local bounce=moving and (1-math.cos(phase))*0.22 or 0
  local gallopPitch=moving and math.sin(phase)*0.085 or 0
		local frame = pose.frame * CFrame.new(0,bounce,0)*CFrame.Angles(angry and pitch or gallopPitch, 0, lean)
  if moving and not model:GetAttribute("Occupied") and clock-(pose.lastDust or clock-1)>0.18 and #dust<80 then
   pose.lastDust=clock
   local puff=Instance.new("Part") puff.Name="LocalHerdDust" puff.Anchored=true
   puff.CanCollide,puff.CanTouch,puff.CanQuery=false,false,false
   puff.Color=Color3.fromRGB(239,220,176) puff.Size=Vector3.one*0.75 puff.Transparency=0.45
   puff.Position=Vector3.new(frame.X+math.sin(phase)*0.9,0.2,frame.Z+1.6)
   puff.Parent=workspace table.insert(dust,{part=puff,started=clock})
  end
  displayed[model] = frame
		for _, entry in ipairs(pose) do
			if not entry.part.Parent then continue end
			local localFrame = entry.rest
			if moving and entry.side then
				local opposite = (entry.side == "Left") ~= (entry.leg == "Front")
				local swing = math.sin(phase + (opposite and math.pi or 0)) * 0.85
				local joint = CFrame.new(entry.side == "Left" and -0.88 or 0.88, -0.87, entry.leg == "Front" and -0.91 or 1.17)
				localFrame = CFrame.new(0,math.max(0,math.sin(phase + (opposite and math.pi or 0)))*0.22,0) * joint * CFrame.Angles(swing, 0, 0) * joint:Inverse() * entry.rest
			end
   if running and entry.part.Name:find("Ear") then
    local sign=entry.part.Name:find("Left") and -1 or 1
    local pivot=CFrame.new(sign*0.87,1.3,-1.21)
    localFrame=pivot*CFrame.Angles(math.sin(phase)*0.12,0,sign*math.sin(phase)*0.1)*pivot:Inverse()*localFrame
   elseif running and entry.part.Name:find("Tail") then
    local pivot=CFrame.new(0,-0.1,1.7)
    localFrame=pivot*CFrame.Angles(0,math.sin(phase*0.65)*0.3,0)*pivot:Inverse()*localFrame
   end
			entry.part.CFrame = frame * localFrame
		end
		if not running then poses[model] = nil end
	end
 return displayed
end

return RideAnimator
