assert(not game:GetService("RunService"):IsRunning(),"Stop Play")
local parent=game.StarterPlayer.StarterPlayerScripts
local changes={}
do local n=assert(parent:FindFirstChild("RideAnimator")) local before=[====[-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}
local visibility={}
local warnings = {}
local package = game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local template = package:WaitForChild("VisualTemplate")
local templateRoot=assert(template.PrimaryPart,"VisualTemplate PrimaryPart 없음")
local tuning = require(package:WaitForChild("Config")).Prototype
local Rules = require(package:WaitForChild("HuntRules"))
local Catalog=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
local Crash=require(script.Parent:WaitForChild("CrashEffect"))
local dust={}
local contexts=setmetatable({},{__mode="k"})
local function lobbyModels(root,context)
 if context.models then return context.models end
 local models,indices={},{}
 context.models=models
 local function add(node)
  if node:IsA("Model") and not indices[node] then models[#models+1]=node indices[node]=#models end
 end
 local function remove(node)
  local index=indices[node] if not index then return end
  local last=models[#models] models[index]=last indices[last]=index models[#models]=nil indices[node]=nil
 end
 for _,node in ipairs(root:GetDescendants()) do add(node) end
 -- Track late imports/summons without scanning every lobby part each frame.
 root.DescendantAdded:Connect(add) root.DescendantRemoving:Connect(remove)
 return models
end
local function clearHerdPath(from,to,root)
 local world=root:FindFirstAncestor("RodeoPrototype") or root:FindFirstAncestorWhichIsA("Folder")
 if world and world.Name=="Monsters" then world=world.Parent end
 local obstacles=world and world:FindFirstChild("Obstacles")
 if not obstacles then return true end
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:IsA("BasePart") or rock:GetAttribute("Broken") then continue end
  local p,s=rock.Position,rock.Size+root.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0.2) then return false end
 end
 return true
end
local function remember(model, existing)
	local root = model.PrimaryPart
 local speciesId=model:GetAttribute("MonsterId") or "MeadowMouse"
 local referenceTemplate=package:WaitForChild(Catalog.visual(speciesId,model:GetAttribute("Stars") or 1))
 local referenceRoot=assert(referenceTemplate.PrimaryPart,"몬스터 템플릿 PrimaryPart 없음")
	if not root then return nil end
	local pose = existing or {frame = root.CFrame, sample = root.CFrame, received = nil, tracked={}, restByPart={}}
 if existing and not pose.dirty then return pose end
 if not pose.watch then pose.watch=model.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then pose.dirty=true end end) end
 pose.dirty=false
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root and not pose.tracked[part] then
   local restFrame
   if part:GetAttribute("ApprovedRest") then
    -- Canonical mesh coordinates survive root movement during async installation.
    restFrame=part:GetAttribute("ApprovedRest")
   elseif model:GetAttribute("ImportedA") then
    -- Imported meshes already carry their correct per-model offsets; many are
    -- color-batched nodes whose names do not exist in the old part template.
    restFrame=root.CFrame:ToObjectSpace(part.CFrame)
   else
    local reference=referenceTemplate:FindFirstChild(part.Name,true)
    if not reference or not reference:IsA("BasePart") then
     part.LocalTransparencyModifier=1 pose.dirty=true continue
    end
    restFrame=referenceRoot.CFrame:ToObjectSpace(reference.CFrame)
   end
   part.LocalTransparencyModifier=0
			local side = string.sub(part.Name,1,4)=="Left" and "Left" or string.sub(part.Name,1,5)=="Right" and "Right" or nil
			local movingLeg = side and (string.find(part.Name,"Leg",1,true) or string.find(part.Name,"Paw",1,true) or string.find(part.Name,"Claw",1,true) or string.find(part.Name,"HoofLine",1,true))
			local leg = movingLeg and (string.find(part.Name,"Front",1,true) and "Front" or "Back") or nil
			if not leg then side=nil end
			pose.tracked[part]=true
   local entry={part=part,rest=restFrame,side=side,leg=leg}
   pose.restByPart[part]=restFrame
   table.insert(pose,entry)
		end
	end
	poses[model] = pose
	return pose
end

function RideAnimator.update(monsters, clock, cameraPosition, dt, selected)
 local context=contexts[monsters]
 if not context then context={poses={},visibility={},warnings={},dust={}} contexts[monsters]=context end
 poses,visibility,warnings,dust=context.poses,context.visibility,context.warnings,context.dust
 dt = dt or 1/60
 for i=#dust,1,-1 do
  local puff=dust[i] local age=clock-puff.started
  if age>=0.6 then puff.part:Destroy() table.remove(dust,i)
  else puff.part.Transparency=0.45+age/0.6*0.55 puff.part.Size=Vector3.one*(0.75+age*1.5) puff.part.Position+=Vector3.new(0,dt*0.7,0) end
 end
 local displayed = {}
 for model,record in pairs(visibility) do
  if not model:IsDescendantOf(monsters) then
   if record.connection then record.connection:Disconnect() end
   visibility[model]=nil
  end
 end
	for model, pose in pairs(poses) do
		if not model:IsDescendantOf(monsters) then
   if pose.watch then pose.watch:Disconnect() end
   poses[model] = nil
  end
	end
	for model, warning in pairs(warnings) do
		if not model:IsDescendantOf(monsters) then warning:Destroy() warnings[model] = nil end
	end
	if monsters.Name=="RodeoLobby" then
  local airport=monsters:FindFirstChild("Airport")
  local ship=airport and airport:FindFirstChild("Airship")
  if ship then
   context.airshipFrames=context.airshipFrames or {}
   for _,part in ipairs(ship:GetDescendants()) do
    if part:IsA("BasePart") and (part.Name=="SeaWingRoot" or part.Name=="SeaWingFeather") then
     local base=context.airshipFrames[part] or part.CFrame context.airshipFrames[part]=base
     local side=base.Position.X<6000 and -1 or 1
     local pivot=CFrame.new(6000+side*22,47,-9)
     local beat=math.sin(clock*1.15+1.2)*.21
     part.CFrame=pivot*CFrame.Angles(0,0,-side*beat)*pivot:Inverse()*base
    end
   end
  end
 end
 local outlineCount=0
	for _, model in ipairs(monsters.Name=="RodeoLobby" and lobbyModels(monsters,context) or monsters:GetChildren()) do
  if not model:IsA("Model") then continue end
  if not model:GetAttribute("MonsterId") or model:GetAttribute("NativeMeshyAirship") then continue end
		local root = model.PrimaryPart
		if not root then continue end
  if model:GetAttribute("KnockedAway") then
   Crash.knock(model,clock)
   for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=1 end end
   continue
  end
  local ownCompanion=model:GetAttribute("BagItemId") and model:GetAttribute("OwnerUserId")==game.Players.LocalPlayer.UserId
  local nameplate = root:FindFirstChild("Nameplate")
  if nameplate then nameplate.Enabled = false end
		if cameraPosition then
   local hidden=not ownCompanion and ((root.Position-cameraPosition).Magnitude>220 or (selected and not model:GetAttribute("Occupied") and not selected[model]))
   local record=visibility[model]
   if not record then
    record={} visibility[model]=record
    record.connection=model.DescendantAdded:Connect(function(part)
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=record.hidden and 1 or 0 end
    end)
   end
   if record.hidden~=hidden then
    record.hidden=hidden
    if not hidden then record.revealed=clock end
    for _,part in ipairs(model:GetChildren()) do
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=hidden and 1 or 0 end
    end
   end
   if hidden then
    local outline=model:FindFirstChild("LocalCreatureOutline") if outline then outline:Destroy() end
    continue
   end
  end
		Mesh.materialize(model)
  local outline=model:FindFirstChild("LocalCreatureOutline")
  if outlineCount<20 then
   if not outline then
    outline=Instance.new("Highlight") outline.Name="LocalCreatureOutline" outline.Adornee=model
    outline.FillTransparency=1 outline.OutlineTransparency=.05
    outline.OutlineColor=Color3.fromRGB(35,49,68) outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Parent=model
   end
   outline.Enabled=true outlineCount+=1
  elseif outline then outline:Destroy() end
  if not Mesh.failed and not model:GetAttribute("MeshDecorated") then task.spawn(Mesh.decorate,model) end
  local running = model:GetAttribute("Running") == true
		local pose = poses[model]
		if not pose and not running and not model:GetAttribute("BagItemId") then continue end
		pose = remember(model,pose) -- Include late replicated body parts on every frame.
  if pose.sample ~= root.CFrame or not pose.received then
   pose.sample, pose.received = root.CFrame, clock
  end
  local elapsed = math.clamp(clock-pose.received,0,0.08)
  local speed = model:GetAttribute("Occupied") and Rules.rideSpeed(clock,model:GetAttribute("DashUntil"),(model:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond),tuning.SwitchDashMultiplier) or (model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond)
  if model:GetAttribute("InitialLanding") then speed=0 end
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

		local scale=Catalog.scale(model:GetAttribute("Stars") or 1)
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
		local _,_,pitch=Rules.buck(clock-(model:GetAttribute("AngerStarted") or clock),tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[model:GetAttribute("MonsterId") or "MeadowMouse"].TripleHop)
		local facingFrame,straightFacing=Mesh.huntFrame(model,pose.frame)
		local lean = not straightFacing and running and (model:GetAttribute("Steering") or 0) * -0.18 or 0
  local moving=running and (model:GetAttribute("BagItemId")~=nil or velocity.Magnitude>1)
  Mesh.animate(model,phase,moving,angry)
  local flying=model:GetAttribute("Flying")==true
  local bounce=moving and (flying and (.55+math.sin(phase*.5)*.22) or (1-math.cos(phase))*.22) or 0
  local gallopPitch=moving and math.sin(phase)*0.085 or 0
		local frame = facingFrame * CFrame.new(0,bounce,0)*CFrame.Angles(angry and not flying and pitch or gallopPitch, 0, lean)
    if monsters.Name~="RodeoLobby" and monsters.Name~="CafePets" and moving and not flying and not model:GetAttribute("Occupied") and clock-(pose.lastDust or clock-1)>0.18 and #dust<80 then
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
			if moving and flying and entry.part.Name:find("Wing",1,true) then
    local side=entry.part.Name:find("Left",1,true) and -1 or 1
    local pivot=CFrame.new(side*.8*scale,.3*scale,.15*scale)
    localFrame=pivot*CFrame.Angles(0,0,side*math.sin(phase*.7)*(angry and .85 or .55))*pivot:Inverse()*localFrame
   elseif moving and entry.side then
				local opposite = (entry.side == "Left") ~= (entry.leg == "Front")
				local swing = math.sin(phase + (opposite and math.pi or 0)) * 0.85
				local legPart=model:FindFirstChild(entry.side..entry.leg.."Leg")
			local legRest=legPart and pose.restByPart[legPart]
    local joint=CFrame.new(legRest and (legRest.Position+Vector3.new(0,legPart.Size.Y*.5,0)) or entry.rest.Position)
				localFrame = CFrame.new(0,math.max(0,math.sin(phase + (opposite and math.pi or 0)))*0.22,0) * joint * CFrame.Angles(swing, 0, 0) * joint:Inverse() * entry.rest
			end
   if running and entry.part.Name:find("Ear") then
    local sign=entry.part.Name:find("Left") and -1 or 1
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(sign*0.87*scale,1.3*scale,-1.21*scale)
    localFrame=pivot*CFrame.Angles(math.sin(phase)*0.12,0,sign*math.sin(phase)*0.1)*pivot:Inverse()*localFrame
   elseif running and entry.part.Name:find("Tail") then
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(0,-0.1*scale,1.7*scale)
    localFrame=pivot*CFrame.Angles(0,math.sin(phase*0.65)*0.3,0)*pivot:Inverse()*localFrame
   end
			entry.part.CFrame = frame * localFrame
   local shown=visibility[model]
   if shown and not shown.hidden then entry.part.LocalTransparencyModifier=ownCompanion and 0 or math.clamp(1-(clock-(shown.revealed or clock-.3))/.25,0,1) end
		end
		-- Keep cached canonical poses while resting; late parts still align.
	end
 return displayed
end

return RideAnimator
]====] local after=[====[-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}
local visibility={}
local warnings = {}
local package = game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local template = package:WaitForChild("VisualTemplate")
local templateRoot=assert(template.PrimaryPart,"VisualTemplate PrimaryPart 없음")
local tuning = require(package:WaitForChild("Config")).Prototype
local Rules = require(package:WaitForChild("HuntRules"))
local Catalog=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
local Crash=require(script.Parent:WaitForChild("CrashEffect"))
local dust={}
local contexts=setmetatable({},{__mode="k"})
local renderedFrames=setmetatable({},{__mode="k"})
function RideAnimator.frame(model) return renderedFrames[model] end
local function lobbyModels(root,context)
 if context.models then return context.models end
 local models,indices={},{}
 context.models=models
 local function add(node)
  if node:IsA("Model") and not indices[node] then models[#models+1]=node indices[node]=#models end
 end
 local function remove(node)
  local index=indices[node] if not index then return end
  local last=models[#models] models[index]=last indices[last]=index models[#models]=nil indices[node]=nil
 end
 for _,node in ipairs(root:GetDescendants()) do add(node) end
 -- Track late imports/summons without scanning every lobby part each frame.
 root.DescendantAdded:Connect(add) root.DescendantRemoving:Connect(remove)
 return models
end
local function clearHerdPath(from,to,root)
 local world=root:FindFirstAncestor("RodeoPrototype") or root:FindFirstAncestorWhichIsA("Folder")
 if world and world.Name=="Monsters" then world=world.Parent end
 local obstacles=world and world:FindFirstChild("Obstacles")
 if not obstacles then return true end
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:IsA("BasePart") or rock:GetAttribute("Broken") then continue end
  local p,s=rock.Position,rock.Size+root.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0.2) then return false end
 end
 return true
end
local function remember(model, existing)
	local root = model.PrimaryPart
 local speciesId=model:GetAttribute("MonsterId") or "MeadowMouse"
 local referenceTemplate=package:WaitForChild(Catalog.visual(speciesId,model:GetAttribute("Stars") or 1))
 local referenceRoot=assert(referenceTemplate.PrimaryPart,"몬스터 템플릿 PrimaryPart 없음")
	if not root then return nil end
	local pose = existing or {frame = root.CFrame, sample = root.CFrame, received = nil, tracked={}, restByPart={}}
 if existing and not pose.dirty then return pose end
 if not pose.watch then pose.watch=model.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then pose.dirty=true end end) end
 pose.dirty=false
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root and not pose.tracked[part] then
   local restFrame
   if part:GetAttribute("ApprovedRest") then
    -- Canonical mesh coordinates survive root movement during async installation.
    restFrame=part:GetAttribute("ApprovedRest")
   elseif model:GetAttribute("ImportedA") then
    -- Imported meshes already carry their correct per-model offsets; many are
    -- color-batched nodes whose names do not exist in the old part template.
    restFrame=root.CFrame:ToObjectSpace(part.CFrame)
   else
    local reference=referenceTemplate:FindFirstChild(part.Name,true)
    if not reference or not reference:IsA("BasePart") then
     part.LocalTransparencyModifier=1 pose.dirty=true continue
    end
    restFrame=referenceRoot.CFrame:ToObjectSpace(reference.CFrame)
   end
   part.LocalTransparencyModifier=0
			local side = string.sub(part.Name,1,4)=="Left" and "Left" or string.sub(part.Name,1,5)=="Right" and "Right" or nil
			local movingLeg = side and (string.find(part.Name,"Leg",1,true) or string.find(part.Name,"Paw",1,true) or string.find(part.Name,"Claw",1,true) or string.find(part.Name,"HoofLine",1,true))
			local leg = movingLeg and (string.find(part.Name,"Front",1,true) and "Front" or "Back") or nil
			if not leg then side=nil end
			pose.tracked[part]=true
   local entry={part=part,rest=restFrame,side=side,leg=leg}
   pose.restByPart[part]=restFrame
   table.insert(pose,entry)
		end
	end
	poses[model] = pose
	return pose
end

function RideAnimator.update(monsters, clock, cameraPosition, dt, selected)
 local context=contexts[monsters]
 if not context then context={poses={},visibility={},warnings={},dust={}} contexts[monsters]=context end
 poses,visibility,warnings,dust=context.poses,context.visibility,context.warnings,context.dust
 dt = dt or 1/60
 for i=#dust,1,-1 do
  local puff=dust[i] local age=clock-puff.started
  if age>=0.6 then puff.part:Destroy() table.remove(dust,i)
  else puff.part.Transparency=0.45+age/0.6*0.55 puff.part.Size=Vector3.one*(0.75+age*1.5) puff.part.Position+=Vector3.new(0,dt*0.7,0) end
 end
 local displayed = {}
 for model,record in pairs(visibility) do
  if not model:IsDescendantOf(monsters) then
   if record.connection then record.connection:Disconnect() end
   visibility[model]=nil
  end
 end
	for model, pose in pairs(poses) do
		if not model:IsDescendantOf(monsters) then
   if pose.watch then pose.watch:Disconnect() end
   poses[model] = nil
  end
	end
	for model, warning in pairs(warnings) do
		if not model:IsDescendantOf(monsters) then warning:Destroy() warnings[model] = nil end
	end
	if monsters.Name=="RodeoLobby" then
  local airport=monsters:FindFirstChild("Airport")
  local ship=airport and airport:FindFirstChild("Airship")
  if ship then
   context.airshipFrames=context.airshipFrames or {}
   for _,part in ipairs(ship:GetDescendants()) do
    if part:IsA("BasePart") and (part.Name=="SeaWingRoot" or part.Name=="SeaWingFeather") then
     local base=context.airshipFrames[part] or part.CFrame context.airshipFrames[part]=base
     local side=base.Position.X<6000 and -1 or 1
     local pivot=CFrame.new(6000+side*22,47,-9)
     local beat=math.sin(clock*1.15+1.2)*.21
     part.CFrame=pivot*CFrame.Angles(0,0,-side*beat)*pivot:Inverse()*base
    end
   end
  end
 end
 local outlineCount=0
	for _, model in ipairs(monsters.Name=="RodeoLobby" and lobbyModels(monsters,context) or monsters:GetChildren()) do
  if not model:IsA("Model") then continue end
  if not model:GetAttribute("MonsterId") or model:GetAttribute("NativeMeshyAirship") then continue end
		local root = model.PrimaryPart
		if not root then continue end
  if model:GetAttribute("KnockedAway") then
   Crash.knock(model,clock)
   for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=1 end end
   continue
  end
  local ownCompanion=model:GetAttribute("BagItemId") and model:GetAttribute("OwnerUserId")==game.Players.LocalPlayer.UserId
  local nameplate = root:FindFirstChild("Nameplate")
  if nameplate then nameplate.Enabled = false end
		if cameraPosition then
   local hidden=not ownCompanion and ((root.Position-cameraPosition).Magnitude>220 or (selected and not model:GetAttribute("Occupied") and not selected[model]))
   local record=visibility[model]
   if not record then
    record={} visibility[model]=record
    record.connection=model.DescendantAdded:Connect(function(part)
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=record.hidden and 1 or 0 end
    end)
   end
   if record.hidden~=hidden then
    record.hidden=hidden
    if not hidden then record.revealed=clock end
    for _,part in ipairs(model:GetChildren()) do
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=hidden and 1 or 0 end
    end
   end
   if hidden then
    local outline=model:FindFirstChild("LocalCreatureOutline") if outline then outline:Destroy() end
    continue
   end
  end
		Mesh.materialize(model)
  local outline=model:FindFirstChild("LocalCreatureOutline")
  if outlineCount<20 then
   if not outline then
    outline=Instance.new("Highlight") outline.Name="LocalCreatureOutline" outline.Adornee=model
    outline.FillTransparency=1 outline.OutlineTransparency=.05
    outline.OutlineColor=Color3.fromRGB(35,49,68) outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Parent=model
   end
   outline.Enabled=true outlineCount+=1
  elseif outline then outline:Destroy() end
  if not Mesh.failed and not model:GetAttribute("MeshDecorated") then task.spawn(Mesh.decorate,model) end
  local running = model:GetAttribute("Running") == true
		local pose = poses[model]
		if not pose and not running and not model:GetAttribute("BagItemId") then continue end
		pose = remember(model,pose) -- Include late replicated body parts on every frame.
  if pose.sample ~= root.CFrame or not pose.received then
   pose.sample, pose.received = root.CFrame, clock
  end
  local elapsed = math.clamp(clock-pose.received,0,0.08)
  local speed = model:GetAttribute("Occupied") and Rules.rideSpeed(clock,model:GetAttribute("DashUntil"),(model:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond),tuning.SwitchDashMultiplier) or (model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond)
  if model:GetAttribute("InitialLanding") then speed=0 end
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

		local scale=Catalog.scale(model:GetAttribute("Stars") or 1)
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
		local _,_,pitch=Rules.buck(clock-(model:GetAttribute("AngerStarted") or clock),tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[model:GetAttribute("MonsterId") or "MeadowMouse"].TripleHop)
		local facingFrame,straightFacing=Mesh.huntFrame(model,pose.frame)
		local lean = not straightFacing and running and (model:GetAttribute("Steering") or 0) * -0.18 or 0
  local moving=running and (model:GetAttribute("BagItemId")~=nil or velocity.Magnitude>1)
  Mesh.animate(model,phase,moving,angry)
  local flying=model:GetAttribute("Flying")==true
  local bounce=moving and (flying and (.55+math.sin(phase*.5)*.22) or (1-math.cos(phase))*.22) or 0
  local gallopPitch=moving and math.sin(phase)*0.085 or 0
		local frame = facingFrame * CFrame.new(0,bounce,0)*CFrame.Angles(angry and not flying and pitch or gallopPitch, 0, lean)
    if monsters.Name~="RodeoLobby" and monsters.Name~="CafePets" and moving and not flying and not model:GetAttribute("Occupied") and clock-(pose.lastDust or clock-1)>0.18 and #dust<80 then
   pose.lastDust=clock
   local puff=Instance.new("Part") puff.Name="LocalHerdDust" puff.Anchored=true
   puff.CanCollide,puff.CanTouch,puff.CanQuery=false,false,false
   puff.Color=Color3.fromRGB(239,220,176) puff.Size=Vector3.one*0.75 puff.Transparency=0.45
   puff.Position=Vector3.new(frame.X+math.sin(phase)*0.9,0.2,frame.Z+1.6)
   puff.Parent=workspace table.insert(dust,{part=puff,started=clock})
  end
  displayed[model] = frame
  renderedFrames[model] = frame
		for _, entry in ipairs(pose) do
			if not entry.part.Parent then continue end
			local localFrame = entry.rest
			if moving and flying and entry.part.Name:find("Wing",1,true) then
    local side=entry.part.Name:find("Left",1,true) and -1 or 1
    local pivot=CFrame.new(side*.8*scale,.3*scale,.15*scale)
    localFrame=pivot*CFrame.Angles(0,0,side*math.sin(phase*.7)*(angry and .85 or .55))*pivot:Inverse()*localFrame
   elseif moving and entry.side then
				local opposite = (entry.side == "Left") ~= (entry.leg == "Front")
				local swing = math.sin(phase + (opposite and math.pi or 0)) * 0.85
				local legPart=model:FindFirstChild(entry.side..entry.leg.."Leg")
			local legRest=legPart and pose.restByPart[legPart]
    local joint=CFrame.new(legRest and (legRest.Position+Vector3.new(0,legPart.Size.Y*.5,0)) or entry.rest.Position)
				localFrame = CFrame.new(0,math.max(0,math.sin(phase + (opposite and math.pi or 0)))*0.22,0) * joint * CFrame.Angles(swing, 0, 0) * joint:Inverse() * entry.rest
			end
   if running and entry.part.Name:find("Ear") then
    local sign=entry.part.Name:find("Left") and -1 or 1
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(sign*0.87*scale,1.3*scale,-1.21*scale)
    localFrame=pivot*CFrame.Angles(math.sin(phase)*0.12,0,sign*math.sin(phase)*0.1)*pivot:Inverse()*localFrame
   elseif running and entry.part.Name:find("Tail") then
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(0,-0.1*scale,1.7*scale)
    localFrame=pivot*CFrame.Angles(0,math.sin(phase*0.65)*0.3,0)*pivot:Inverse()*localFrame
   end
			entry.part.CFrame = frame * localFrame
   local shown=visibility[model]
   if shown and not shown.hidden then entry.part.LocalTransparencyModifier=ownCompanion and 0 or math.clamp(1-(clock-(shown.revealed or clock-.3))/.25,0,1) end
		end
		-- Keep cached canonical poses while resting; late parts still align.
	end
 return displayed
end

return RideAnimator
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed RideAnimator") table.insert(changes,{n=n,after=after}) end
do local n=assert(parent:FindFirstChild("PetPromptUI")) local before=[====[-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent.HudIcons).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoLobby")
  local folder=map and map:FindFirstChild("LobbyCompanions")
  local pet=folder and folder:FindFirstChild("Companion_"..player.UserId)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if pet and root and pet.PrimaryPart and pet:GetAttribute("OwnerUserId")==player.UserId
   and (root.Position-pet.PrimaryPart.Position).Magnitude<=10 then return pet end
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  current=nearby() local mounted=player:GetAttribute("LobbyRiding")==true
  button.Visible=current~=nil and not mounted ride.Visible=current~=nil or mounted ring.Enabled=mounted
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 ride.Activated:Connect(function()
  local pet=nearby()
  if pet or player:GetAttribute("LobbyRiding") then package.CaptureRemote:FireServer("RidePet",pet and pet:GetAttribute("BagItemId")) end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0 local lastInput
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView} end
   camera.CameraType=Enum.CameraType.Scriptable
   local pet=current and current.Parent and current local part=pet and pet.PrimaryPart
   local frame=part and part.CFrame or root.CFrame
   local height=pet and pet:FindFirstChild("Body") and pet.Body.Size.Y or 4
   local target=root.Position+Vector3.new(0,1,0)
   camera.CFrame=CFrame.lookAt(target-frame.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),target)
   inputTime+=dt
   local direction=hum.MoveDirection
   if inputTime>=.08 and (not lastInput or (direction-lastInput).Magnitude>.02 or inputTime>=.25) then
    inputTime=0 lastInput=direction package.CaptureRemote:FireServer("RideInput",direction)
   end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
   inputTime=0 lastInput=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]====] local after=[====[-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local presentation=require(script.Parent.RideAnimator)
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent.HudIcons).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoLobby")
  local folder=map and map:FindFirstChild("LobbyCompanions")
  local pet=folder and folder:FindFirstChild("Companion_"..player.UserId)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if pet and root and pet.PrimaryPart and pet:GetAttribute("OwnerUserId")==player.UserId
   and (root.Position-pet.PrimaryPart.Position).Magnitude<=10 then return pet end
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  current=nearby() local mounted=player:GetAttribute("LobbyRiding")==true
  button.Visible=current~=nil and not mounted ride.Visible=current~=nil or mounted ring.Enabled=mounted
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 ride.Activated:Connect(function()
  local pet=nearby()
  if pet or player:GetAttribute("LobbyRiding") then package.CaptureRemote:FireServer("RidePet",pet and pet:GetAttribute("BagItemId")) end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0 local lastInput
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView} end
   camera.CameraType=Enum.CameraType.Scriptable
   local pet=current and current.Parent and current local part=pet and pet.PrimaryPart
   -- Match rider and camera to the pet's interpolated visual frame, not its
   -- server root, which intentionally arrives at a lower network frequency.
   local frame=pet and presentation.frame(pet) or (part and part.CFrame or root.CFrame)
   local height=pet and pet:FindFirstChild("Body") and pet.Body.Size.Y or 4
   if pet and part and root.Anchored then
    local rootHeight=pet:GetAttribute("RootHeight") or 2
    local upright=(pet:GetAttribute("Stars") or 1)>=6
    local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
    root.CFrame=frame*CFrame.new(offset)
   end
   local target=root.Position+Vector3.new(0,1,0)
   camera.CFrame=CFrame.lookAt(target-frame.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),target)
   inputTime+=dt
   local direction=hum.MoveDirection
   if inputTime>=.08 and (not lastInput or (direction-lastInput).Magnitude>.02 or inputTime>=.25) then
    inputTime=0 lastInput=direction package.CaptureRemote:FireServer("RideInput",direction)
   end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
   inputTime=0 lastInput=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed PetPromptUI") table.insert(changes,{n=n,after=after}) end
do local n=assert(parent:FindFirstChild("UserMossratRigAnimator")) local before=[====[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local dataS3=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS3"))
local dataS6=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS6"))
local dataS9=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS9"))
local function rigData(model)
 local revision=model:GetAttribute("MossratUserRigRevision")
 return revision=="UserS9-v1" and dataS9 or revision=="UserS6-v1" and dataS6 or revision=="UserS3-v1" and dataS3 or data
end
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local s3=rigData(model)~=data
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=not s3 and torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" and not s3 then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local data=rigData(model)
 local s9=data==dataS9
 local s6=data==dataS6 or s9
 local s3=data==dataS3 or s6
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},poses={},sample={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 local interval=moving and 1/30 or 1/15
 local camera=workspace.CurrentCamera
 if model:GetAttribute("OwnerUserId") and camera then
  local distance=(body.Position-camera.CFrame.Position).Magnitude
  if distance>150 then return end
  if distance>70 then interval=1/10 end
 end
 if c.mode and now-c.last<interval then return end c.last=now
 local serverNow=workspace:GetServerTimeNow()
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=bondUntil>serverNow
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={} table.clear(c.poses)
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses=c.poses
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v=c.sample
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
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=not s3 and torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" and not s3 then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding and not s3 then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-serverNow)/.35,0,1))
    local pose=CFrame.identity
    if name=="Pelvis" then pose=CFrame.new(0,-.08*scale,0)*CFrame.Angles(math.rad(-32),0,0)
    elseif name=="Spine" then pose=CFrame.Angles(math.rad(-18),0,0)
    elseif name=="Chest" then pose=CFrame.Angles(math.rad(8),0,0)
    elseif name=="Neck" then pose=CFrame.Angles(math.rad(22),0,0)
    elseif name=="Head" then pose=CFrame.Angles(math.rad(20),math.sin(t*4)*.12,math.sin(t*4)*.20)
    elseif legLimb=="Rear" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(50),0,0)
    elseif legLimb=="Rear" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(-55),0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(-50),0,0)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(40),0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*(s6 and (legLimb=="Front" and .22 or .45) or .65),0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*(s6 and .28 or .65),0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   local tailIndex=tonumber(name:match("^Tail(%d+)$"))
   if tailIndex then
    frame=frame*CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035)
   end
   if bonding and data==dataS3 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local progress=math.clamp((t-.35)/1.7,0,1)
    if name=="Root" then
     local height=data.height*scale local lift=math.sin(progress*math.pi)*height*.65
     frame=CFrame.new(0,height*.5+lift,0)*CFrame.Angles(-math.pi*2*progress,0,0)*CFrame.new(0,-height*.5,0)
    elseif legLimb and progress>0 and progress<1 then
     frame=CFrame.Angles(math.sin(progress*math.pi)*(legLimb=="Front" and -.6 or .6),0,0)
    end
   elseif bonding and s9 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.5,0,1),math.clamp((bondUntil-serverNow)/.5,0,1))
    local pose=CFrame.identity
    if name=="Chest" then pose=CFrame.Angles(-.28,0,0)
    elseif name=="Head" then pose=CFrame.Angles(-.40,0,math.sin(t*8)*.025)
    elseif name=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(.15,0,(legSide=="Left" and 1 or -1)*.6)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-.5,0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif bonding and s6 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.4,0,1),math.clamp((bondUntil-serverNow)/.4,0,1))
    local sign=legSide=="Left" and 1 or -1
    local pose=CFrame.identity
    if legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(-.25,0,sign*1.35)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-1.5,0,0)
    elseif name=="Chest" then pose=CFrame.Angles(-.12,math.sin(t*2)*.12,0)
    elseif name=="Head" then pose=CFrame.Angles(-.1,math.sin(t*2)*.12,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]====] local after=[====[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local dataS3=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS3"))
local dataS6=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS6"))
local dataS9=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS9"))
local function rigData(model)
 local revision=model:GetAttribute("MossratUserRigRevision")
 return revision=="UserS9-v1" and dataS9 or revision=="UserS6-v1" and dataS6 or revision=="UserS3-v1" and dataS3 or data
end
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
local torsoCenterS3={Pelvis=.05,Spine=.07,Chest=.10,Neck=.06,Head=.02}
local function centering(data)
 return data==dataS3 and torsoCenterS3 or data~=dataS6 and data~=dataS9 and torsoCenterX or nil
end
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local selected=rigData(model)
 local centers=centering(selected)
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=centers and centers[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" and selected==data then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),math.rad(3.9)) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local data=rigData(model)
 local s9=data==dataS9
 local s6=data==dataS6 or s9
 local s3=data==dataS3 or s6
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},poses={},sample={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 local interval=moving and 1/30 or 1/15
 local camera=workspace.CurrentCamera
 if model:GetAttribute("OwnerUserId") and camera then
  local distance=(body.Position-camera.CFrame.Position).Magnitude
  if distance>150 then return end
  if distance>70 then interval=1/10 end
 end
 if c.mode and now-c.last<interval then return end c.last=now
 local serverNow=workspace:GetServerTimeNow()
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=bondUntil>serverNow
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={} table.clear(c.poses)
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses=c.poses
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v=c.sample
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
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centers=centering(data)
   local centerX=centers and centers[name]
   if centerX then frame=CFrame.new(0,(p.translation or Vector3.zero).Y,0) end
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" and not s3 then frame=frame*CFrame.Angles(0,math.rad(-8.2),math.rad(3.9)) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding and not s3 then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-serverNow)/.35,0,1))
    local pose=CFrame.identity
    if name=="Pelvis" then pose=CFrame.new(0,-.08*scale,0)*CFrame.Angles(math.rad(-32),0,0)
    elseif name=="Spine" then pose=CFrame.Angles(math.rad(-18),0,0)
    elseif name=="Chest" then pose=CFrame.Angles(math.rad(8),0,0)
    elseif name=="Neck" then pose=CFrame.Angles(math.rad(22),0,0)
    elseif name=="Head" then pose=CFrame.Angles(math.rad(20),math.sin(t*4)*.12,math.sin(t*4)*.20)
    elseif legLimb=="Rear" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(50),0,0)
    elseif legLimb=="Rear" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(-55),0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(-50),0,0)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(40),0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*(s6 and (legLimb=="Front" and .22 or .45) or .65),0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*(s6 and .28 or .65),0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   local tailIndex=tonumber(name:match("^Tail(%d+)$"))
   if tailIndex then
    frame=frame*CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035)
   end
   if bonding and data==dataS3 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local progress=math.clamp((t-.35)/1.7,0,1)
    if name=="Root" then
     local height=data.height*scale local lift=math.sin(progress*math.pi)*height*.65
     frame=CFrame.new(0,height*.5+lift,0)*CFrame.Angles(-math.pi*2*progress,0,0)*CFrame.new(0,-height*.5,0)
    elseif legLimb and progress>0 and progress<1 then
     frame=CFrame.Angles(math.sin(progress*math.pi)*(legLimb=="Front" and -.6 or .6),0,0)
    end
   elseif bonding and s9 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.5,0,1),math.clamp((bondUntil-serverNow)/.5,0,1))
    local pose=CFrame.identity
    if name=="Chest" then pose=CFrame.Angles(-.28,0,0)
    elseif name=="Head" then pose=CFrame.Angles(-.40,0,math.sin(t*8)*.025)
    elseif name=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(.15,0,(legSide=="Left" and 1 or -1)*.6)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-.5,0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif bonding and s6 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.4,0,1),math.clamp((bondUntil-serverNow)/.4,0,1))
    local sign=legSide=="Left" and 1 or -1
    local pose=CFrame.identity
    if legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(-.25,0,sign*1.35)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-1.5,0,0)
    elseif name=="Chest" then pose=CFrame.Angles(-.12,math.sin(t*2)*.12,0)
    elseif name=="Head" then pose=CFrame.Angles(-.1,math.sin(t*2)*.12,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed UserMossratRigAnimator") table.insert(changes,{n=n,after=after}) end
do local n=assert(parent:FindFirstChild("MonsterPortrait")) local before=[====[local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
function P.fill(viewport,id,stars,silhouette,distanceScale)
 local world=Instance.new("WorldModel") world.Parent=viewport
 local source=package:FindFirstChild(C.visual(id,stars))
 if not source or not source:GetAttribute("NativeMeshyMossrat") then
  local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
  label.Text="Model pending" label.TextScaled=true label.TextColor3=Color3.fromRGB(160,180,170) label.Parent=viewport
  return nil
 end
 local model=source:Clone()
 local stage=C.stage(stars)
 model:ScaleTo(C.scale(stars)/C.Scales[stage])
 model.Parent=world model:PivotTo(CFrame.new())
 for _,node in ipairs(model:GetDescendants()) do
  if node:IsA("BillboardGui") or node:IsA("Light") then node:Destroy()
  elseif silhouette and node:IsA("SurfaceAppearance") then node:Destroy()
  elseif silhouette and node:IsA("BasePart") then node.Color=Color3.new(0,0,0) node.Material=Enum.Material.SmoothPlastic if node:IsA("MeshPart") then node.TextureID="" end end
 end
 model:SetAttribute("Stars",stars)
 model:SetAttribute("MonsterId",id) model:SetAttribute("PortraitSilhouette",silhouette==true)
 Mesh.decorate(model)
 Mesh.posePortrait(model)
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 -- Approved visual faces -Z. A straight camera avoids the old overhead
 -- three-quarter view, which made the face look turned in every menu.
 local direction=Vector3.new(0,0,-1)
 local function fit()
  local distance=math.max(size.X,size.Y,size.Z)*2.3
  if distanceScale then
   local aspect=viewport.AbsoluteSize.Y>0 and viewport.AbsoluteSize.X/viewport.AbsoluteSize.Y or 1
   local basis=CFrame.lookAt(Vector3.zero,-direction)
   local tangent=math.tan(math.rad(camera.FieldOfView/2))
   distance=0
   for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
    local p=basis:VectorToObjectSpace(frame:VectorToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
    distance=math.max(distance,p.Z+math.abs(p.Y)/tangent,p.Z+math.abs(p.X)/(tangent*math.max(.1,aspect)))
   end end end
   distance*=1.08
  end
  camera.CFrame=CFrame.lookAt(frame.Position+direction*distance,frame.Position)
 end
 fit()
 viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
 camera.Parent=viewport viewport.CurrentCamera=camera
 return model
end
return P
]====] local after=[====[-- Shared 2D portraits: inventory/catalog never clone 3D rigs or cameras.
local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local defaults={[1]="rbxassetid://136157716828140",[3]="rbxassetid://132856650627155",[6]="rbxassetid://117627702063447",[9]="rbxassetid://127579346809789"}
function P.fill(container,id,stars,silhouette,_distanceScale)
 local stage=C.stage(stars)
 local imageId=id=="MeadowMouse" and (package:GetAttribute("MossratPortraitS"..stage) or defaults[stage]) or nil
 local image=Instance.new("ImageLabel") image.Name="MonsterPortraitImage"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ScaleType=Enum.ScaleType.Fit image.ZIndex=container.ZIndex+1
 image.Image=type(imageId)=="string" and imageId or ""
 image.ImageColor3=silhouette and Color3.new(0,0,0) or Color3.new(1,1,1)
 image.Parent=container
 if image.Image=="" then
  local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
  label.Text="?" label.TextScaled=true label.TextColor3=Color3.fromRGB(160,180,170) label.Parent=container
 end
 return image
end
return P
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed MonsterPortrait") table.insert(changes,{n=n,after=after}) end
do local n=assert(parent:FindFirstChild("BagUI")) local before=[====[local UI={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Query=require(game.ReplicatedStorage.RodeoFantasy.CollectionQuery)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Income=require(script.Parent:WaitForChild("IncomeEffects"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamBold end
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
function UI.iconButton(gui,kind,key,right)
 local bag=kind=="Bag"
 local button=make("TextButton",{Name=bag and "OpenBag" or "OpenJournal",Text="",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-right,1,-18),Size=UDim2.fromOffset(64,64),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.08,BorderSizePixel=0},gui)
 make("UICorner",{CornerRadius=UDim.new(0,16)},button)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},button)
 local function shape(name,x,y,w,h,color,radius)
  local node=make("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,BorderSizePixel=0},button)
  make("UICorner",{CornerRadius=UDim.new(0,radius or 3)},node) return node
 end
 if bag then
  local leather=Color3.fromRGB(178,126,84)
  shape("Handle",25,10,14,12,leather,5)
  shape("Backpack",18,17,28,32,leather,8)
  shape("Pocket",23,31,18,12,Color3.fromRGB(133,88,58),4)
  shape("Clasp",30,28,4,5,Color3.fromRGB(250,213,131),1)
 else
  shape("Cover",12,15,40,32,Color3.fromRGB(178,126,84),4)
  shape("LeftPage",15,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("RightPage",33,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("Spine",31,16,2,29,Color3.fromRGB(120,91,61),1)
  for _,x in ipairs({18,36}) do for y=23,35,6 do shape("Ink",x,y,10,2,Color3.fromRGB(136,156,119),1) end end
 end
 make("TextLabel",{Name="Shortcut",Text=key,BackgroundTransparency=1,Position=UDim2.fromOffset(42,45),Size=UDim2.fromOffset(18,16),TextSize=11,TextColor3=Color3.fromRGB(246,229,193)},button)
 return button
end
function UI.new(gui,remote)
 local self={area="Lobby",items={},count=-1,pen=nil,region="All",page=1,query="",evolutionMode=false,selected={}}
 local button=UI.iconButton(gui,"Bag","R",18)
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(.31,-24,0,34),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=20},money)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve","en-us"),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters","en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("ViewportFrame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolvePreview)
 local evolveCancel=make("TextButton",{Name="CancelEvolution",Text=L.text("Cancel","en-us"),Position=UDim2.new(1,-194,0,12),Size=UDim2.fromOffset(80,34),TextSize=13,BackgroundColor3=Color3.fromRGB(164,139,107),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 local evolveConfirm=make("TextButton",{Name="ConfirmEvolution",Text=L.text("Evolve","en-us"),Position=UDim2.new(1,-108,0,12),Size=UDim2.fromOffset(100,34),TextSize=13,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolveCancel) make("UICorner",{CornerRadius=UDim.new(0,8)},evolveConfirm)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,245),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 local search=make("TextBox",{Name="BagSearch",PlaceholderText="Search",Text="",ClearTextOnFocus=false,Position=UDim2.new(.32,0,0,55),Size=UDim2.new(.27,0,0,34),BackgroundColor3=Color3.fromRGB(255,250,237),TextColor3=Color3.fromRGB(71,58,40),TextSize=17,ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,8)},search)
 local tabs=make("ScrollingFrame",{Name="BagRegions",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(20,136),Size=UDim2.new(1,-40,0,32),AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=0,ZIndex=23},window)
 make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)},tabs)
 local previous=make("TextButton",{Name="BagPrevious",Text="‹",BackgroundTransparency=1,Position=UDim2.new(.35,-45,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 local pageLabel=make("TextLabel",{Name="BagPage",Text="1 / 1",BackgroundTransparency=1,Position=UDim2.new(.35,0,1,-45),Size=UDim2.new(.3,0,0,30),TextSize=15,ZIndex=23},window)
 local nextPage=make("TextButton",{Name="BagNext",Text="›",BackgroundTransparency=1,Position=UDim2.new(.65,5,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 function self.filter(region,query)
  self.region,self.query,self.page=region or self.region,query or self.query,1
  self.snapshot(self.items)
 end
 for _,region in ipairs(Query.regions(Catalog)) do
  local tab=make("TextButton",{Name="Region_"..region,Text=L.text(region,"en-us"),Size=UDim2.fromOffset(112,30),BackgroundColor3=Color3.fromRGB(213,193,159),TextColor3=Color3.fromRGB(65,53,37),TextSize=15,ZIndex=24},tabs)
  make("UICorner",{CornerRadius=UDim.new(0,8)},tab)
  tab.Activated:Connect(function() self.filter(region,nil) end)
 end
 local breed=make("TextButton",{Name="Breed",Text="Breed",Position=UDim2.new(.62,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},breed)
 breed.Activated:Connect(function() if self.onBreed then self.onBreed() end end)
 local chooser
 local revision=0
 local function selectedCount() local n=0 for _ in pairs(self.selected) do n+=1 end return n end
 local function selectionAnchor()
  for id in pairs(self.selected) do
   for _,item in ipairs(self.items) do if item.id==id then return item end end
  end
 end
 local function updateEvolutionControls()
  local count=selectedCount()
  local anchor=selectionAnchor()
  if anchor then
   evolveStatus.Text=L.text(anchor.monsterId,"en-us").." · "..anchor.stars.."★  →  "..(anchor.stars+1).."★    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
   if anchor.stars<10 then Portrait.fill(evolvePreview,anchor.monsterId,anchor.stars+1,false) end
  else
   evolveStatus.Text=L.text("Select three matching monsters","en-us").."    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
  end
  evolveConfirm.Active=count==3 and anchor~=nil and anchor.stars<10
  evolveConfirm.AutoButtonColor=evolveConfirm.Active
  evolveConfirm.BackgroundColor3=evolveConfirm.Active and Color3.fromRGB(80,134,104) or Color3.fromRGB(151,159,143)
 end
 function self.setEvolutionMode(enabled)
  self.evolutionMode=enabled==true
  if not self.evolutionMode then self.selected={} end
  self.mode=nil self.pen=nil chooser.Visible=false scroll.Visible=true
  evolveControls.Visible=self.evolutionMode
  scroll.Position=UDim2.fromOffset(16,self.evolutionMode and 240 or 175)
  scroll.Size=UDim2.new(1,-32,1,self.evolutionMode and -295 or -230)
  evolveToggle.Text=self.evolutionMode and L.text("Cancel","en-us") or L.text("Evolve","en-us")
  self.snapshot(self.items)
 end
 evolveToggle.Activated:Connect(function()
  if self.area~="Hunt" and not self.pen then self.setEvolutionMode(not self.evolutionMode) end
 end)
 evolveCancel.Activated:Connect(function() self.setEvolutionMode(false) end)
 evolveConfirm.Activated:Connect(function()
  if not evolveConfirm.Active or self.area=="Hunt" then return end
  local ids={} for id in pairs(self.selected) do table.insert(ids,id) end
  table.sort(ids)
  if #ids==3 then remote:FireServer("Evolve",ids) end
 end)
 search:GetPropertyChangedSignal("Text"):Connect(function()
  revision+=1 local current=revision
  task.delay(.12,function() if revision==current then self.filter(nil,search.Text) end end)
 end)
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("Frame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,4 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="Hatchery".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Manage",index) end end)
 end
 function self.openCompanionMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="Companion" self.pen=nil chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items) window.Visible=true self.opened() title.Text="Companion · Choose one" remote:FireServer("Bag")
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="Eggs · My hatcheries"
 end
 function self.toggle()
  if self.area=="Hunt" then return end
  self.mode=nil self.pen=nil self.setEvolutionMode(false) chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items)
  window.Visible=not window.Visible
  if window.Visible then self.opened() remote:FireServer("Bag") end
 end
 button.Activated:Connect(self.toggle)
 close.Activated:Connect(self.close)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.R then self.toggle() end
 end)
 function self.state(state)
  self.area=state.area
  local nextSummoned=state.summonedId
  if self.summonedId~=nextSummoned then self.summonedId=nextSummoned self.snapshot(self.items) end
  button.Visible=state.area~="Hunt"
  if state.area=="Hunt" then window.Visible=false self.pen=nil self.setEvolutionMode(false) end
  money.Text="Coins: "..tostring((state.pending or 0)+(state.balance or 0))
  button.Text=""
  if state.area~="Hunt" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.openPen(index)
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode=nil chooser.Visible=false scroll.Visible=true
  self.pen=index self.snapshot(self.items) window.Visible=true self.opened()
 end
 function self.snapshot(items)
  self.items=items self.cards={}
  local present={} for _,item in ipairs(items) do present[item.id]=true end
  for id in pairs(self.selected) do if not present[id] then self.selected[id]=nil end end
  local placed=0
  for _,item in ipairs(items) do if item.assignedPen==self.pen and self.pen then placed+=1 end end
  title.Text=L.text(self.mode=="Companion" and "Companion · Choose one" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag","en-us")..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,"en-us") end)
  local pages=math.max(1,math.ceil(#filtered/12)) self.page=math.clamp(self.page,1,pages)
  pageLabel.Text=self.page.." / "..pages
  local show=self.mode~="RanchMenu"
  search.Visible=show tabs.Visible=show previous.Visible=show nextPage.Visible=show pageLabel.Visible=show
  evolveToggle.Visible=show and not self.pen breed.Visible=show and not self.pen
  evolveControls.Visible=show and self.evolutionMode and not self.pen
  if self.evolutionMode then
   scroll.Position=UDim2.fromOffset(16,240) scroll.Size=UDim2.new(1,-32,1,-295)
  else
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
  end
  empty.Visible=show and #filtered==0
  empty.Text=L.text(#items==0 and "No monsters caught yet" or "No matching monsters","en-us")
  for _,tab in ipairs(tabs:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundColor3=tab.Name=="Region_"..self.region and Color3.fromRGB(167,127,79) or Color3.fromRGB(213,193,159) end end
  scroll.CanvasPosition=Vector2.zero
  for index=(self.page-1)*12+1,math.min(self.page*12,#filtered) do
   local item=filtered[index]
   local card=make("Frame",{Name="MonsterCard",Size=UDim2.fromOffset(170,245),BackgroundColor3=Color3.fromRGB(237,225,204),ZIndex=22,LayoutOrder=index},scroll)
   make("UICorner",{CornerRadius=UDim.new(0,12)},card)
   local male=item.sex=="Male" local female=item.sex=="Female"
   local color=male and Color3.fromRGB(72,130,180) or female and Color3.fromRGB(183,88,115) or Color3.fromRGB(119,109,91)
   local badge=make("Frame",{Name="SexBadge",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-7,0,6),Size=UDim2.fromOffset(30,26),Visible=male or female,BackgroundColor3=Color3.fromRGB(255,241,213),BorderSizePixel=0,ZIndex=26},card)
   make("UICorner",{CornerRadius=UDim.new(0,6)},badge)
   local offset=male and 0 or 3
   local ring=make("Frame",{Name="SexRing",Position=UDim2.fromOffset(6+offset,5),Size=UDim2.fromOffset(11,11),BackgroundTransparency=1,ZIndex=27},badge)
   make("UICorner",{CornerRadius=UDim.new(1,0)},ring) make("UIStroke",{Color=color,Thickness=2},ring)
   local function line(name,x,y,w,h,rotation)
    make("Frame",{Name=name,Position=UDim2.fromOffset(x+offset,y),Size=UDim2.fromOffset(w,h),Rotation=rotation or 0,BackgroundColor3=color,BorderSizePixel=0,ZIndex=27},badge)
   end
   if male then line("MaleStem",14,4,9,2,-45) line("ArrowTop",18,2,6,2) line("ArrowRight",22,2,2,6)
   elseif female then line("FemaleStem",10,15,2,7) line("FemaleCross",7,18,8,2) end
   self.cards[item.id]=card
   local preview=make("ViewportFrame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23,Ambient=Color3.fromRGB(195,195,195),LightColor=Color3.new(1,1,1)},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   local income=make("Frame",{Name="Income",BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),ZIndex=23},card)
   make("ImageLabel",{Name="Money",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.new(.5,-66,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Amount",Text=tostring(item.incomeAmount),BackgroundTransparency=1,Position=UDim2.new(.5,-34,0,0),Size=UDim2.fromOffset(38,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   make("ImageLabel",{Name="Clock",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"ClockImage"),BackgroundTransparency=1,Position=UDim2.new(.5,5,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Seconds",Text=tostring(item.incomeSeconds),BackgroundTransparency=1,Position=UDim2.new(.5,33,0,0),Size=UDim2.fromOffset(32,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Summon",item.id) end end)
   elseif self.pen then
    local mine=item.assignedPen==self.pen
    local allowed=mine or (not item.assignedPen and placed<2)
    local label=mine and "Return to bag" or item.assignedPen and "Placed" or placed>=2 and "Full" or "Place"
    local choose=make("TextButton",{Name="ChooseMonster",Text=L.text(label,"en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=allowed and Color3.fromRGB(80,134,104) or Color3.fromRGB(154,167,151),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if allowed and self.pen and self.area=="Lobby" then remote:FireServer(mine and "Remove" or "Place",{id=item.id,pen=self.pen}) end
    end)
   elseif self.evolutionMode then
    local anchor=selectionAnchor()
    local compatible=not anchor or (anchor.monsterId==item.monsterId and anchor.stars==item.stars)
    local selected=self.selected[item.id]==true
    local choose=make("TextButton",{Name="SelectForEvolution",Text=selected and L.text("Selected","en-us") or L.text("Select","en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=selected and Color3.fromRGB(80,134,104) or compatible and Color3.fromRGB(147,182,154) or Color3.fromRGB(184,181,168),TextColor3=Color3.new(1,1,1),Active=compatible and (selected or selectedCount()<3),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if self.selected[item.id] then self.selected[item.id]=nil
     elseif compatible and selectedCount()<3 and self.area~="Hunt" then self.selected[item.id]=true end
     self.snapshot(self.items)
    end)
   elseif self.area=="Cafe" or self.area=="Lobby" then
    if item.id==self.summonedId and self.area=="Cafe" then
     make("TextLabel",{Text="Summoned",BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
    elseif not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     summon.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed","en-us").." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve","en-us")
  else
   local key=result.reason=="MaxStars" and "Already at max stars" or "Evolution failed"
   evolveStatus.Text=L.text(key,"en-us")
  end
 end
 function self.income(gains)
  if self.area=="Hunt" or not window.Visible then return end
  for _,gain in ipairs(gains or {}) do
   local card=self.cards and self.cards[gain.id]
   if card and card.Parent then Income.card(card,gain.amount) end
  end
 end
 return self
end
return UI
]====] local after=[====[local UI={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Query=require(game.ReplicatedStorage.RodeoFantasy.CollectionQuery)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Income=require(script.Parent:WaitForChild("IncomeEffects"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamBold end
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
function UI.iconButton(gui,kind,key,right)
 local bag=kind=="Bag"
 local button=make("TextButton",{Name=bag and "OpenBag" or "OpenJournal",Text="",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-right,1,-18),Size=UDim2.fromOffset(64,64),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.08,BorderSizePixel=0},gui)
 make("UICorner",{CornerRadius=UDim.new(0,16)},button)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},button)
 local function shape(name,x,y,w,h,color,radius)
  local node=make("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,BorderSizePixel=0},button)
  make("UICorner",{CornerRadius=UDim.new(0,radius or 3)},node) return node
 end
 if bag then
  local leather=Color3.fromRGB(178,126,84)
  shape("Handle",25,10,14,12,leather,5)
  shape("Backpack",18,17,28,32,leather,8)
  shape("Pocket",23,31,18,12,Color3.fromRGB(133,88,58),4)
  shape("Clasp",30,28,4,5,Color3.fromRGB(250,213,131),1)
 else
  shape("Cover",12,15,40,32,Color3.fromRGB(178,126,84),4)
  shape("LeftPage",15,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("RightPage",33,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("Spine",31,16,2,29,Color3.fromRGB(120,91,61),1)
  for _,x in ipairs({18,36}) do for y=23,35,6 do shape("Ink",x,y,10,2,Color3.fromRGB(136,156,119),1) end end
 end
 make("TextLabel",{Name="Shortcut",Text=key,BackgroundTransparency=1,Position=UDim2.fromOffset(42,45),Size=UDim2.fromOffset(18,16),TextSize=11,TextColor3=Color3.fromRGB(246,229,193)},button)
 return button
end
function UI.new(gui,remote)
 local self={area="Lobby",items={},count=-1,pen=nil,region="All",page=1,query="",evolutionMode=false,selected={}}
 local button=UI.iconButton(gui,"Bag","R",18)
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(.31,-24,0,34),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=20},money)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve","en-us"),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters","en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("Frame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolvePreview)
 local evolveCancel=make("TextButton",{Name="CancelEvolution",Text=L.text("Cancel","en-us"),Position=UDim2.new(1,-194,0,12),Size=UDim2.fromOffset(80,34),TextSize=13,BackgroundColor3=Color3.fromRGB(164,139,107),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 local evolveConfirm=make("TextButton",{Name="ConfirmEvolution",Text=L.text("Evolve","en-us"),Position=UDim2.new(1,-108,0,12),Size=UDim2.fromOffset(100,34),TextSize=13,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolveCancel) make("UICorner",{CornerRadius=UDim.new(0,8)},evolveConfirm)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,245),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 local search=make("TextBox",{Name="BagSearch",PlaceholderText="Search",Text="",ClearTextOnFocus=false,Position=UDim2.new(.32,0,0,55),Size=UDim2.new(.27,0,0,34),BackgroundColor3=Color3.fromRGB(255,250,237),TextColor3=Color3.fromRGB(71,58,40),TextSize=17,ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,8)},search)
 local tabs=make("ScrollingFrame",{Name="BagRegions",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(20,136),Size=UDim2.new(1,-40,0,32),AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=0,ZIndex=23},window)
 make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)},tabs)
 local previous=make("TextButton",{Name="BagPrevious",Text="‹",BackgroundTransparency=1,Position=UDim2.new(.35,-45,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 local pageLabel=make("TextLabel",{Name="BagPage",Text="1 / 1",BackgroundTransparency=1,Position=UDim2.new(.35,0,1,-45),Size=UDim2.new(.3,0,0,30),TextSize=15,ZIndex=23},window)
 local nextPage=make("TextButton",{Name="BagNext",Text="›",BackgroundTransparency=1,Position=UDim2.new(.65,5,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 function self.filter(region,query)
  self.region,self.query,self.page=region or self.region,query or self.query,1
  self.snapshot(self.items)
 end
 for _,region in ipairs(Query.regions(Catalog)) do
  local tab=make("TextButton",{Name="Region_"..region,Text=L.text(region,"en-us"),Size=UDim2.fromOffset(112,30),BackgroundColor3=Color3.fromRGB(213,193,159),TextColor3=Color3.fromRGB(65,53,37),TextSize=15,ZIndex=24},tabs)
  make("UICorner",{CornerRadius=UDim.new(0,8)},tab)
  tab.Activated:Connect(function() self.filter(region,nil) end)
 end
 local breed=make("TextButton",{Name="Breed",Text="Breed",Position=UDim2.new(.62,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},breed)
 breed.Activated:Connect(function() if self.onBreed then self.onBreed() end end)
 local chooser
 local revision=0
 local function selectedCount() local n=0 for _ in pairs(self.selected) do n+=1 end return n end
 local function selectionAnchor()
  for id in pairs(self.selected) do
   for _,item in ipairs(self.items) do if item.id==id then return item end end
  end
 end
 local function updateEvolutionControls()
  local count=selectedCount()
  local anchor=selectionAnchor()
  if anchor then
   evolveStatus.Text=L.text(anchor.monsterId,"en-us").." · "..anchor.stars.."★  →  "..(anchor.stars+1).."★    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
   if anchor.stars<10 then Portrait.fill(evolvePreview,anchor.monsterId,anchor.stars+1,false) end
  else
   evolveStatus.Text=L.text("Select three matching monsters","en-us").."    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
  end
  evolveConfirm.Active=count==3 and anchor~=nil and anchor.stars<10
  evolveConfirm.AutoButtonColor=evolveConfirm.Active
  evolveConfirm.BackgroundColor3=evolveConfirm.Active and Color3.fromRGB(80,134,104) or Color3.fromRGB(151,159,143)
 end
 function self.setEvolutionMode(enabled)
  self.evolutionMode=enabled==true
  if not self.evolutionMode then self.selected={} end
  self.mode=nil self.pen=nil chooser.Visible=false scroll.Visible=true
  evolveControls.Visible=self.evolutionMode
  scroll.Position=UDim2.fromOffset(16,self.evolutionMode and 240 or 175)
  scroll.Size=UDim2.new(1,-32,1,self.evolutionMode and -295 or -230)
  evolveToggle.Text=self.evolutionMode and L.text("Cancel","en-us") or L.text("Evolve","en-us")
  self.snapshot(self.items)
 end
 evolveToggle.Activated:Connect(function()
  if self.area~="Hunt" and not self.pen then self.setEvolutionMode(not self.evolutionMode) end
 end)
 evolveCancel.Activated:Connect(function() self.setEvolutionMode(false) end)
 evolveConfirm.Activated:Connect(function()
  if not evolveConfirm.Active or self.area=="Hunt" then return end
  local ids={} for id in pairs(self.selected) do table.insert(ids,id) end
  table.sort(ids)
  if #ids==3 then remote:FireServer("Evolve",ids) end
 end)
 search:GetPropertyChangedSignal("Text"):Connect(function()
  revision+=1 local current=revision
  task.delay(.12,function() if revision==current then self.filter(nil,search.Text) end end)
 end)
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("Frame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,4 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="Hatchery".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Manage",index) end end)
 end
 function self.openCompanionMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="Companion" self.pen=nil chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items) window.Visible=true self.opened() title.Text="Companion · Choose one" remote:FireServer("Bag")
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="Eggs · My hatcheries"
 end
 function self.toggle()
  if self.area=="Hunt" then return end
  self.mode=nil self.pen=nil self.setEvolutionMode(false) chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items)
  window.Visible=not window.Visible
  if window.Visible then self.opened() remote:FireServer("Bag") end
 end
 button.Activated:Connect(self.toggle)
 close.Activated:Connect(self.close)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.R then self.toggle() end
 end)
 function self.state(state)
  self.area=state.area
  local nextSummoned=state.summonedId
  if self.summonedId~=nextSummoned then self.summonedId=nextSummoned self.snapshot(self.items) end
  button.Visible=state.area~="Hunt"
  if state.area=="Hunt" then window.Visible=false self.pen=nil self.setEvolutionMode(false) end
  money.Text="Coins: "..tostring((state.pending or 0)+(state.balance or 0))
  button.Text=""
  if state.area~="Hunt" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.openPen(index)
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode=nil chooser.Visible=false scroll.Visible=true
  self.pen=index self.snapshot(self.items) window.Visible=true self.opened()
 end
 function self.snapshot(items)
  self.items=items self.cards={}
  local present={} for _,item in ipairs(items) do present[item.id]=true end
  for id in pairs(self.selected) do if not present[id] then self.selected[id]=nil end end
  local placed=0
  for _,item in ipairs(items) do if item.assignedPen==self.pen and self.pen then placed+=1 end end
  title.Text=L.text(self.mode=="Companion" and "Companion · Choose one" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag","en-us")..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,"en-us") end)
  local pages=math.max(1,math.ceil(#filtered/12)) self.page=math.clamp(self.page,1,pages)
  pageLabel.Text=self.page.." / "..pages
  local show=self.mode~="RanchMenu"
  search.Visible=show tabs.Visible=show previous.Visible=show nextPage.Visible=show pageLabel.Visible=show
  evolveToggle.Visible=show and not self.pen breed.Visible=show and not self.pen
  evolveControls.Visible=show and self.evolutionMode and not self.pen
  if self.evolutionMode then
   scroll.Position=UDim2.fromOffset(16,240) scroll.Size=UDim2.new(1,-32,1,-295)
  else
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
  end
  empty.Visible=show and #filtered==0
  empty.Text=L.text(#items==0 and "No monsters caught yet" or "No matching monsters","en-us")
  for _,tab in ipairs(tabs:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundColor3=tab.Name=="Region_"..self.region and Color3.fromRGB(167,127,79) or Color3.fromRGB(213,193,159) end end
  scroll.CanvasPosition=Vector2.zero
  for index=(self.page-1)*12+1,math.min(self.page*12,#filtered) do
   local item=filtered[index]
   local card=make("Frame",{Name="MonsterCard",Size=UDim2.fromOffset(170,245),BackgroundColor3=Color3.fromRGB(237,225,204),ZIndex=22,LayoutOrder=index},scroll)
   make("UICorner",{CornerRadius=UDim.new(0,12)},card)
   local male=item.sex=="Male" local female=item.sex=="Female"
   local color=male and Color3.fromRGB(72,130,180) or female and Color3.fromRGB(183,88,115) or Color3.fromRGB(119,109,91)
   local badge=make("Frame",{Name="SexBadge",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-7,0,6),Size=UDim2.fromOffset(30,26),Visible=male or female,BackgroundColor3=Color3.fromRGB(255,241,213),BorderSizePixel=0,ZIndex=26},card)
   make("UICorner",{CornerRadius=UDim.new(0,6)},badge)
   local offset=male and 0 or 3
   local ring=make("Frame",{Name="SexRing",Position=UDim2.fromOffset(6+offset,5),Size=UDim2.fromOffset(11,11),BackgroundTransparency=1,ZIndex=27},badge)
   make("UICorner",{CornerRadius=UDim.new(1,0)},ring) make("UIStroke",{Color=color,Thickness=2},ring)
   local function line(name,x,y,w,h,rotation)
    make("Frame",{Name=name,Position=UDim2.fromOffset(x+offset,y),Size=UDim2.fromOffset(w,h),Rotation=rotation or 0,BackgroundColor3=color,BorderSizePixel=0,ZIndex=27},badge)
   end
   if male then line("MaleStem",14,4,9,2,-45) line("ArrowTop",18,2,6,2) line("ArrowRight",22,2,2,6)
   elseif female then line("FemaleStem",10,15,2,7) line("FemaleCross",7,18,8,2) end
   self.cards[item.id]=card
   local preview=make("Frame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   local income=make("Frame",{Name="Income",BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),ZIndex=23},card)
   make("ImageLabel",{Name="Money",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.new(.5,-66,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Amount",Text=tostring(item.incomeAmount),BackgroundTransparency=1,Position=UDim2.new(.5,-34,0,0),Size=UDim2.fromOffset(38,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   make("ImageLabel",{Name="Clock",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"ClockImage"),BackgroundTransparency=1,Position=UDim2.new(.5,5,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Seconds",Text=tostring(item.incomeSeconds),BackgroundTransparency=1,Position=UDim2.new(.5,33,0,0),Size=UDim2.fromOffset(32,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Summon",item.id) end end)
   elseif self.pen then
    local mine=item.assignedPen==self.pen
    local allowed=mine or (not item.assignedPen and placed<2)
    local label=mine and "Return to bag" or item.assignedPen and "Placed" or placed>=2 and "Full" or "Place"
    local choose=make("TextButton",{Name="ChooseMonster",Text=L.text(label,"en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=allowed and Color3.fromRGB(80,134,104) or Color3.fromRGB(154,167,151),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if allowed and self.pen and self.area=="Lobby" then remote:FireServer(mine and "Remove" or "Place",{id=item.id,pen=self.pen}) end
    end)
   elseif self.evolutionMode then
    local anchor=selectionAnchor()
    local compatible=not anchor or (anchor.monsterId==item.monsterId and anchor.stars==item.stars)
    local selected=self.selected[item.id]==true
    local choose=make("TextButton",{Name="SelectForEvolution",Text=selected and L.text("Selected","en-us") or L.text("Select","en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=selected and Color3.fromRGB(80,134,104) or compatible and Color3.fromRGB(147,182,154) or Color3.fromRGB(184,181,168),TextColor3=Color3.new(1,1,1),Active=compatible and (selected or selectedCount()<3),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if self.selected[item.id] then self.selected[item.id]=nil
     elseif compatible and selectedCount()<3 and self.area~="Hunt" then self.selected[item.id]=true end
     self.snapshot(self.items)
    end)
   elseif self.area=="Cafe" or self.area=="Lobby" then
    if item.id==self.summonedId and self.area=="Cafe" then
     make("TextLabel",{Text="Summoned",BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
    elseif not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     summon.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed","en-us").." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve","en-us")
  else
   local key=result.reason=="MaxStars" and "Already at max stars" or "Evolution failed"
   evolveStatus.Text=L.text(key,"en-us")
  end
 end
 function self.income(gains)
  if self.area=="Hunt" or not window.Visible then return end
  for _,gain in ipairs(gains or {}) do
   local card=self.cards and self.cards[gain.id]
   if card and card.Parent then Income.card(card,gain.amount) end
  end
 end
 return self
end
return UI
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed BagUI") table.insert(changes,{n=n,after=after}) end
do local n=assert(parent:FindFirstChild("JournalUI")) local before=[====[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
local Planets=require(package.PlanetCatalog)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Buttons=require(script.Parent:WaitForChild("BagUI"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(kind,props,parent)
 local n=Instance.new(kind)
 if n:IsA("TextLabel") or n:IsA("TextButton") then
  n.Font=Enum.Font.GothamBlack n.TextColor3=Color3.new(1,1,1)
  n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0
 end
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
local function label(parent,name,value,x,y,w,h,max)
 local n=make("TextLabel",{Name=name,Text=value,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundTransparency=1,TextScaled=true,TextWrapped=true,ZIndex=45},parent)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=max},n) return n
end
local function panel(parent,name,x,y,w,h,color)
 local n=make("Frame",{Name=name,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color,BorderSizePixel=0,ZIndex=42},parent)
 make("UIStroke",{Color=Color3.fromRGB(10,14,20),Thickness=2},n) return n
end
local function gradient(parent,a,b)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new(a,b)},parent)
end
local function T(v) return L.text(v,"en-us") end
function J.new(gui,remote)
 local allEntries=Q.entries(C)
 local self={area="Lobby",planet="GreenStar",page=1,seen={},data={},entries=allEntries,perSpread=8,selected=1}
 local button=Buttons.iconButton(gui,"Journal","T",92)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.91,.82),BackgroundColor3=Color3.fromRGB(54,58,72),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1000,620)},book)
 make("UIStroke",{Color=Color3.fromRGB(8,12,19),Thickness=3},book)
 gradient(book,Color3.fromRGB(71,77,96),Color3.fromRGB(37,39,52))
 -- Smooth plate seams, rather than studs, carry the reference's dark framing.
 for i=1,15 do
  make("Frame",{Name="FrameSeam",Position=UDim2.fromScale(i/16,0),Size=UDim2.fromScale(.002,1),BackgroundColor3=Color3.fromRGB(100,108,129),BackgroundTransparency=.8,BorderSizePixel=0,ZIndex=40},book)
 end
 local header=panel(book,"IndexHeader",.008,.012,.984,.12,Color3.fromRGB(22,204,247))
 gradient(header,Color3.fromRGB(117,241,255),Color3.fromRGB(0,167,228))
 label(header,"Title","Pet Index",.02,.05,.7,.85,30).TextXAlignment=Enum.TextXAlignment.Left
 local close=make("TextButton",{Name="CloseJournal",Text="X",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(255,56,60),TextSize=30,BorderSizePixel=0,ZIndex=47},header)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},close)
 gradient(close,Color3.fromRGB(255,131,129),Color3.fromRGB(241,24,34))
 local region=panel(book,"PlanetLandscape",.02,.16,.14,.68,Color3.fromRGB(37,93,29))
 gradient(region,Color3.fromRGB(127,186,62),Color3.fromRGB(24,73,39))
 label(region,"PlanetName","Green Star",.04,.04,.92,.2,23)
 label(region,"Biome","Meadow",.08,.66,.84,.18,22)
 local planet=make("Frame",{Name="GreenStarPlanet",Position=UDim2.fromScale(.13,.30),Size=UDim2.fromScale(.74,.28),BackgroundColor3=Color3.fromRGB(98,209,45),BorderSizePixel=0,ZIndex=43},region)
 make("UICorner",{CornerRadius=UDim.new(1,0)},planet)
 make("UIAspectRatioConstraint",{AspectRatio=1},planet)
 gradient(planet,Color3.fromRGB(166,237,66),Color3.fromRGB(19,100,55))
 make("UIStroke",{Color=Color3.fromRGB(158,255,157),Thickness=2},planet)
 local art=make("ImageLabel",{Name="GreenStarArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.01,.23),Size=UDim2.fromScale(.98,.42),ScaleType=Enum.ScaleType.Fit,ZIndex=44},region)
 task.spawn(function() while art.Parent and not art.IsLoaded do task.wait(.25) end if art.Parent then planet.Visible=false end end)
 local pages=panel(book,"JournalEntries",.18,.16,.50,.53,Color3.fromRGB(23,27,35))
 local progress=panel(book,"CollectionProgress",.18,.72,.50,.12,Color3.fromRGB(14,18,25))
 local progressFill=make("Frame",{Name="ProgressFill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(26,220,84),BorderSizePixel=0,ZIndex=43},progress)
 gradient(progressFill,Color3.fromRGB(103,255,68),Color3.fromRGB(8,138,55))
 local progressText=label(progress,"ProgressCount","",0,0,1,1,32)
 local detail=panel(book,"SelectedMonster",.70,.16,.28,.42,Color3.fromRGB(14,99,181))
 gradient(detail,Color3.fromRGB(30,148,235),Color3.fromRGB(8,31,60))
 local info=panel(book,"MonsterInformation",.70,.61,.28,.23,Color3.fromRGB(21,68,40))
 gradient(info,Color3.fromRGB(35,110,57),Color3.fromRGB(13,37,24))
 local bottom=panel(book,"UnlockSummary",.02,.88,.96,.095,Color3.fromRGB(17,20,29))
 local summary=label(bottom,"JournalCount","",.1,0,.68,1,24)
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(2,0),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-2,0,0),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local pageNumber=label(bottom,"JournalPage","",.79,0,.12,1,15)
 local planetTab=make("Frame",{Name="PlanetTabs",Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.68),BackgroundTransparency=1,ZIndex=46},book)
 local planetButtons={}
 for index,id in ipairs(Planets.Order) do
  local p=Planets[id]
  local tab=make("TextButton",{Name="Planet_"..id,Text="",Position=UDim2.fromScale(0,(index-1)/4),Size=UDim2.fromScale(1,.23),BackgroundColor3=Color3.fromRGB(42,99,112),BorderSizePixel=0,ZIndex=46},planetTab)
  make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},tab)
  local text=label(tab,"PlanetTabLabel",p.Name,.36,.04,.62,.92,21) text.ZIndex=47
  make("ImageLabel",{Name=id.."TabArtwork",Image=p.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.015,.08),Size=UDim2.fromScale(.34,.84),ScaleType=Enum.ScaleType.Fit,ZIndex=47},tab)
  table.insert(planetButtons,tab)
  tab.Activated:Connect(function()
   self.planet=id self.page=1 self.selected=1 self.entries={}
   for _,entry in ipairs(allEntries) do if (C[entry.monsterId].Planet or "GreenStar")==id then table.insert(self.entries,entry) end end
   art.Image=p.Image region.PlanetName.Text=p.Name region.Biome.Visible=id=="GreenStar"
   self.render()
  end)
 end
 local compact=false
 local lockedHumanoid,savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h and h~=lockedHumanoid then
   lockedHumanoid=h savedWalk=h.WalkSpeed savedJump=h.JumpPower savedRotate=h.AutoRotate savedHeight=h.JumpHeight
   h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0 h.AutoRotate=false
  end
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid:Move(Vector3.zero) end
 end
 local function unlock()
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.WalkSpeed=savedWalk lockedHumanoid.JumpPower=savedJump lockedHumanoid.JumpHeight=savedHeight lockedHumanoid.AutoRotate=savedRotate end
  lockedHumanoid=nil CAS:UnbindAction("JournalPages")
 end
 function self.close() book.Visible=false unlock() end
 local function selectedDetail()
  for _,n in ipairs(detail:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  for _,n in ipairs(info:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local entry=self.entries[self.selected] if not entry then return end
  local species=C[entry.monsterId] local revealed=self.seen[entry.key]==true
  local viewport=make("ViewportFrame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,Ambient=Color3.fromRGB(210,215,211),LightColor=Color3.new(1,1,1),ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income((species.IncomeAmount or 1)*2^(entry.stars-1),species.IncomeSeconds or 3,"en-us") or "???",.04,.87,.92,.12,20)
  income.TextColor3=Color3.fromRGB(97,255,61)
  label(info,"Acquisition",revealed and (entry.stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,"en-us") or L.evolutionHint(entry.stars,"en-us")) or "Collect to reveal details",.05,.05,.9,.58,16)
  label(info,"Caught",T("Caught").." "..(self.data.caught and self.data.caught[entry.key] or 0),.05,.67,.9,.26,17)
 end
 function self.render()
  for _,n in ipairs(pages:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) self.page=math.clamp(self.page,1,max)
  self.selected=math.clamp(self.selected,1,math.max(1,#self.entries))
  pageNumber.Text=self.page.." / "..max
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text=T("Unlocked")..": "..discovered.."/"..#self.entries
  progressText.Text=discovered.."/"..#self.entries progressFill.Size=UDim2.fromScale(#self.entries>0 and discovered/#self.entries or 0,1)
  previous.Visible=max>1 nextPage.Visible=max>1
  local colors={Color3.fromRGB(83,181,78),Color3.fromRGB(26,139,232),Color3.fromRGB(203,73,229),Color3.fromRGB(242,190,32)}
  local columns=(compact or #self.entries<=4) and 2 or 4
  for slot=1,self.perSpread do
   local index=(self.page-1)*self.perSpread+slot local entry=self.entries[index] if not entry then break end
   local revealed=self.seen[entry.key]==true
   local rows=math.max(2,math.ceil(math.min(self.perSpread,#self.entries)/columns))
   local card=make("TextButton",{Name="JournalEntry",Text="",Position=UDim2.fromScale(((slot-1)%columns)/columns+.01,math.floor((slot-1)/columns)/rows+.015),Size=UDim2.fromScale(1/columns-.02,1/rows-.03),BackgroundColor3=colors[((slot-1)%4)+1],BorderSizePixel=0,ZIndex=44},pages)
   make("UIStroke",{Color=index==self.selected and Color3.fromRGB(232,250,255) or Color3.new(0,0,0),Thickness=index==self.selected and 3 or 2},card)
   gradient(card,Color3.fromRGB(218,230,235),Color3.fromRGB(50,86,108))
   local viewport=make("ViewportFrame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,Ambient=Color3.fromRGB(205,213,200),LightColor=Color3.new(1,1,1),ZIndex=45},card)
   Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
   label(card,"EntryName",revealed and T(entry.monsterId) or "???",.02,.01,.96,.19,17)
   label(card,"Stars",entry.stars.."★",0,.82,1,.18,16)
   card.Activated:Connect(function() self.selected=index self.render() end)
  end
  selectedDetail()
  if #self.entries==0 then label(pages,"NoEntries","No entries here yet",.05,.35,.90,.25,22) end
  for index,tab in ipairs(planetButtons) do tab.BackgroundColor3=Planets.Order[index]==self.planet and Color3.fromRGB(59,160,90) or Color3.fromRGB(42,99,112) end
 end
 function self.turn(direction)
  if not book.Visible then return end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) local page=math.clamp(self.page+direction,1,max)
  if self.page==page then return end self.page=page self.render() Audio.ui("PageTurn")
 end
 function self.open()
  if self.area=="Hunt" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze() self.render() Audio.ui("BookOpen")
  if not self.other then remote:FireServer("Journal") end
  CAS:BindActionAtPriority("JournalPages",function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then self.turn(-1)
    elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then self.turn(1) end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
 end
 function self.viewOther(data) self.other=true self.close() self.snapshot(data) self.open() end
 function self.snapshot(data) self.data=data self.seen=data.seen or self.seen if book.Visible then self.render() end end
 function self.state(data)
  self.area=data.area button.Visible=self.area~="Hunt"
  if self.area=="Hunt" then self.close() end
  if book.Visible and not self.other and data.count~=self.lastCount then remote:FireServer("Journal") end self.lastCount=data.count
 end
 local function resize()
  local camera=workspace.CurrentCamera
  compact=camera and camera.ViewportSize.X<860 or false
  if compact then
   book.Position=UDim2.fromScale(.5,.5) book.Size=UDim2.fromScale(.92,.86)
   region.Visible=false planetTab.Position=UDim2.fromScale(.02,.15) planetTab.Size=UDim2.fromScale(.96,.13)
   pages.Position=UDim2.fromScale(.02,.30) pages.Size=UDim2.fromScale(.65,.44)
   progress.Position=UDim2.fromScale(.02,.76) progress.Size=UDim2.fromScale(.65,.08)
   detail.Position=UDim2.fromScale(.70,.30) detail.Size=UDim2.fromScale(.28,.51)
   info.Visible=false
  else
   book.Position=UDim2.fromScale(.44,.5) book.Size=UDim2.fromScale(.76,.82)
   region.Visible=true planetTab.Position=UDim2.fromScale(1.025,.17) planetTab.Size=UDim2.fromScale(.18,.68)
   pages.Position=UDim2.fromScale(.18,.16) pages.Size=UDim2.fromScale(.50,.53)
   progress.Position=UDim2.fromScale(.18,.72) progress.Size=UDim2.fromScale(.50,.12)
   detail.Position=UDim2.fromScale(.70,.16) detail.Size=UDim2.fromScale(.28,.42) info.Visible=true
  end
  for index,tab in ipairs(planetButtons) do
   tab.Position=compact and UDim2.fromScale((index-1)/4,0) or UDim2.fromScale(0,(index-1)/4)
   tab.Size=compact and UDim2.fromScale(.24,1) or UDim2.fromScale(1,.23)
  end
  if book.Visible then self.render() end
 end
 -- Decide from screen width, not a size this callback itself changes.
 local function screenLayout()
  resize()
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(screenLayout) end
 task.defer(screenLayout)
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]====] local after=[====[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
local Planets=require(package.PlanetCatalog)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Buttons=require(script.Parent:WaitForChild("BagUI"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(kind,props,parent)
 local n=Instance.new(kind)
 if n:IsA("TextLabel") or n:IsA("TextButton") then
  n.Font=Enum.Font.GothamBlack n.TextColor3=Color3.new(1,1,1)
  n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0
 end
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
local function label(parent,name,value,x,y,w,h,max)
 local n=make("TextLabel",{Name=name,Text=value,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundTransparency=1,TextScaled=true,TextWrapped=true,ZIndex=45},parent)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=max},n) return n
end
local function panel(parent,name,x,y,w,h,color)
 local n=make("Frame",{Name=name,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color,BorderSizePixel=0,ZIndex=42},parent)
 make("UIStroke",{Color=Color3.fromRGB(10,14,20),Thickness=2},n) return n
end
local function gradient(parent,a,b)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new(a,b)},parent)
end
local function T(v) return L.text(v,"en-us") end
function J.new(gui,remote)
 local allEntries=Q.entries(C)
 local self={area="Lobby",planet="GreenStar",page=1,seen={},data={},entries=allEntries,perSpread=8,selected=1}
 local button=Buttons.iconButton(gui,"Journal","T",92)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.91,.82),BackgroundColor3=Color3.fromRGB(54,58,72),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1000,620)},book)
 make("UIStroke",{Color=Color3.fromRGB(8,12,19),Thickness=3},book)
 gradient(book,Color3.fromRGB(71,77,96),Color3.fromRGB(37,39,52))
 -- Smooth plate seams, rather than studs, carry the reference's dark framing.
 for i=1,15 do
  make("Frame",{Name="FrameSeam",Position=UDim2.fromScale(i/16,0),Size=UDim2.fromScale(.002,1),BackgroundColor3=Color3.fromRGB(100,108,129),BackgroundTransparency=.8,BorderSizePixel=0,ZIndex=40},book)
 end
 local header=panel(book,"IndexHeader",.008,.012,.984,.12,Color3.fromRGB(22,204,247))
 gradient(header,Color3.fromRGB(117,241,255),Color3.fromRGB(0,167,228))
 label(header,"Title","Pet Index",.02,.05,.7,.85,30).TextXAlignment=Enum.TextXAlignment.Left
 local close=make("TextButton",{Name="CloseJournal",Text="X",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(255,56,60),TextSize=30,BorderSizePixel=0,ZIndex=47},header)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},close)
 gradient(close,Color3.fromRGB(255,131,129),Color3.fromRGB(241,24,34))
 local region=panel(book,"PlanetLandscape",.02,.16,.14,.68,Color3.fromRGB(37,93,29))
 gradient(region,Color3.fromRGB(127,186,62),Color3.fromRGB(24,73,39))
 label(region,"PlanetName","Green Star",.04,.04,.92,.2,23)
 label(region,"Biome","Meadow",.08,.66,.84,.18,22)
 local planet=make("Frame",{Name="GreenStarPlanet",Position=UDim2.fromScale(.13,.30),Size=UDim2.fromScale(.74,.28),BackgroundColor3=Color3.fromRGB(98,209,45),BorderSizePixel=0,ZIndex=43},region)
 make("UICorner",{CornerRadius=UDim.new(1,0)},planet)
 make("UIAspectRatioConstraint",{AspectRatio=1},planet)
 gradient(planet,Color3.fromRGB(166,237,66),Color3.fromRGB(19,100,55))
 make("UIStroke",{Color=Color3.fromRGB(158,255,157),Thickness=2},planet)
 local art=make("ImageLabel",{Name="GreenStarArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.01,.23),Size=UDim2.fromScale(.98,.42),ScaleType=Enum.ScaleType.Fit,ZIndex=44},region)
 task.spawn(function() while art.Parent and not art.IsLoaded do task.wait(.25) end if art.Parent then planet.Visible=false end end)
 local pages=panel(book,"JournalEntries",.18,.16,.50,.53,Color3.fromRGB(23,27,35))
 local progress=panel(book,"CollectionProgress",.18,.72,.50,.12,Color3.fromRGB(14,18,25))
 local progressFill=make("Frame",{Name="ProgressFill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(26,220,84),BorderSizePixel=0,ZIndex=43},progress)
 gradient(progressFill,Color3.fromRGB(103,255,68),Color3.fromRGB(8,138,55))
 local progressText=label(progress,"ProgressCount","",0,0,1,1,32)
 local detail=panel(book,"SelectedMonster",.70,.16,.28,.42,Color3.fromRGB(14,99,181))
 gradient(detail,Color3.fromRGB(30,148,235),Color3.fromRGB(8,31,60))
 local info=panel(book,"MonsterInformation",.70,.61,.28,.23,Color3.fromRGB(21,68,40))
 gradient(info,Color3.fromRGB(35,110,57),Color3.fromRGB(13,37,24))
 local bottom=panel(book,"UnlockSummary",.02,.88,.96,.095,Color3.fromRGB(17,20,29))
 local summary=label(bottom,"JournalCount","",.1,0,.68,1,24)
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(2,0),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-2,0,0),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local pageNumber=label(bottom,"JournalPage","",.79,0,.12,1,15)
 local planetTab=make("Frame",{Name="PlanetTabs",Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.68),BackgroundTransparency=1,ZIndex=46},book)
 local planetButtons={}
 for index,id in ipairs(Planets.Order) do
  local p=Planets[id]
  local tab=make("TextButton",{Name="Planet_"..id,Text="",Position=UDim2.fromScale(0,(index-1)/4),Size=UDim2.fromScale(1,.23),BackgroundColor3=Color3.fromRGB(42,99,112),BorderSizePixel=0,ZIndex=46},planetTab)
  make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},tab)
  local text=label(tab,"PlanetTabLabel",p.Name,.36,.04,.62,.92,21) text.ZIndex=47
  make("ImageLabel",{Name=id.."TabArtwork",Image=p.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.015,.08),Size=UDim2.fromScale(.34,.84),ScaleType=Enum.ScaleType.Fit,ZIndex=47},tab)
  table.insert(planetButtons,tab)
  tab.Activated:Connect(function()
   self.planet=id self.page=1 self.selected=1 self.entries={}
   for _,entry in ipairs(allEntries) do if (C[entry.monsterId].Planet or "GreenStar")==id then table.insert(self.entries,entry) end end
   art.Image=p.Image region.PlanetName.Text=p.Name region.Biome.Visible=id=="GreenStar"
   self.render()
  end)
 end
 local compact=false
 local lockedHumanoid,savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h and h~=lockedHumanoid then
   lockedHumanoid=h savedWalk=h.WalkSpeed savedJump=h.JumpPower savedRotate=h.AutoRotate savedHeight=h.JumpHeight
   h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0 h.AutoRotate=false
  end
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid:Move(Vector3.zero) end
 end
 local function unlock()
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.WalkSpeed=savedWalk lockedHumanoid.JumpPower=savedJump lockedHumanoid.JumpHeight=savedHeight lockedHumanoid.AutoRotate=savedRotate end
  lockedHumanoid=nil CAS:UnbindAction("JournalPages")
 end
 function self.close() book.Visible=false unlock() end
 local function selectedDetail()
  for _,n in ipairs(detail:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  for _,n in ipairs(info:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local entry=self.entries[self.selected] if not entry then return end
  local species=C[entry.monsterId] local revealed=self.seen[entry.key]==true
  local viewport=make("Frame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income((species.IncomeAmount or 1)*2^(entry.stars-1),species.IncomeSeconds or 3,"en-us") or "???",.04,.87,.92,.12,20)
  income.TextColor3=Color3.fromRGB(97,255,61)
  label(info,"Acquisition",revealed and (entry.stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,"en-us") or L.evolutionHint(entry.stars,"en-us")) or "Collect to reveal details",.05,.05,.9,.58,16)
  label(info,"Caught",T("Caught").." "..(self.data.caught and self.data.caught[entry.key] or 0),.05,.67,.9,.26,17)
 end
 function self.render()
  for _,n in ipairs(pages:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) self.page=math.clamp(self.page,1,max)
  self.selected=math.clamp(self.selected,1,math.max(1,#self.entries))
  pageNumber.Text=self.page.." / "..max
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text=T("Unlocked")..": "..discovered.."/"..#self.entries
  progressText.Text=discovered.."/"..#self.entries progressFill.Size=UDim2.fromScale(#self.entries>0 and discovered/#self.entries or 0,1)
  previous.Visible=max>1 nextPage.Visible=max>1
  local colors={Color3.fromRGB(83,181,78),Color3.fromRGB(26,139,232),Color3.fromRGB(203,73,229),Color3.fromRGB(242,190,32)}
  local columns=(compact or #self.entries<=4) and 2 or 4
  for slot=1,self.perSpread do
   local index=(self.page-1)*self.perSpread+slot local entry=self.entries[index] if not entry then break end
   local revealed=self.seen[entry.key]==true
   local rows=math.max(2,math.ceil(math.min(self.perSpread,#self.entries)/columns))
   local card=make("TextButton",{Name="JournalEntry",Text="",Position=UDim2.fromScale(((slot-1)%columns)/columns+.01,math.floor((slot-1)/columns)/rows+.015),Size=UDim2.fromScale(1/columns-.02,1/rows-.03),BackgroundColor3=colors[((slot-1)%4)+1],BorderSizePixel=0,ZIndex=44},pages)
   make("UIStroke",{Color=index==self.selected and Color3.fromRGB(232,250,255) or Color3.new(0,0,0),Thickness=index==self.selected and 3 or 2},card)
   gradient(card,Color3.fromRGB(218,230,235),Color3.fromRGB(50,86,108))
   local viewport=make("Frame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,ZIndex=45},card)
   Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
   label(card,"EntryName",revealed and T(entry.monsterId) or "???",.02,.01,.96,.19,17)
   label(card,"Stars",entry.stars.."★",0,.82,1,.18,16)
   card.Activated:Connect(function() self.selected=index self.render() end)
  end
  selectedDetail()
  if #self.entries==0 then label(pages,"NoEntries","No entries here yet",.05,.35,.90,.25,22) end
  for index,tab in ipairs(planetButtons) do tab.BackgroundColor3=Planets.Order[index]==self.planet and Color3.fromRGB(59,160,90) or Color3.fromRGB(42,99,112) end
 end
 function self.turn(direction)
  if not book.Visible then return end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) local page=math.clamp(self.page+direction,1,max)
  if self.page==page then return end self.page=page self.render() Audio.ui("PageTurn")
 end
 function self.open()
  if self.area=="Hunt" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze() self.render() Audio.ui("BookOpen")
  if not self.other then remote:FireServer("Journal") end
  CAS:BindActionAtPriority("JournalPages",function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then self.turn(-1)
    elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then self.turn(1) end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
 end
 function self.viewOther(data) self.other=true self.close() self.snapshot(data) self.open() end
 function self.snapshot(data) self.data=data self.seen=data.seen or self.seen if book.Visible then self.render() end end
 function self.state(data)
  self.area=data.area button.Visible=self.area~="Hunt"
  if self.area=="Hunt" then self.close() end
  if book.Visible and not self.other and data.count~=self.lastCount then remote:FireServer("Journal") end self.lastCount=data.count
 end
 local function resize()
  local camera=workspace.CurrentCamera
  compact=camera and camera.ViewportSize.X<860 or false
  if compact then
   book.Position=UDim2.fromScale(.5,.5) book.Size=UDim2.fromScale(.92,.86)
   region.Visible=false planetTab.Position=UDim2.fromScale(.02,.15) planetTab.Size=UDim2.fromScale(.96,.13)
   pages.Position=UDim2.fromScale(.02,.30) pages.Size=UDim2.fromScale(.65,.44)
   progress.Position=UDim2.fromScale(.02,.76) progress.Size=UDim2.fromScale(.65,.08)
   detail.Position=UDim2.fromScale(.70,.30) detail.Size=UDim2.fromScale(.28,.51)
   info.Visible=false
  else
   book.Position=UDim2.fromScale(.44,.5) book.Size=UDim2.fromScale(.76,.82)
   region.Visible=true planetTab.Position=UDim2.fromScale(1.025,.17) planetTab.Size=UDim2.fromScale(.18,.68)
   pages.Position=UDim2.fromScale(.18,.16) pages.Size=UDim2.fromScale(.50,.53)
   progress.Position=UDim2.fromScale(.18,.72) progress.Size=UDim2.fromScale(.50,.12)
   detail.Position=UDim2.fromScale(.70,.16) detail.Size=UDim2.fromScale(.28,.42) info.Visible=true
  end
  for index,tab in ipairs(planetButtons) do
   tab.Position=compact and UDim2.fromScale((index-1)/4,0) or UDim2.fromScale(0,(index-1)/4)
   tab.Size=compact and UDim2.fromScale(.24,1) or UDim2.fromScale(1,.23)
  end
  if book.Visible then self.render() end
 end
 -- Decide from screen width, not a size this callback itself changes.
 local function screenLayout()
  resize()
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(screenLayout) end
 task.defer(screenLayout)
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed JournalUI") table.insert(changes,{n=n,after=after}) end
do local n=assert(parent:FindFirstChild("SocialUI")) local before=[====[local S={}
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local Portrait=require(script.Parent.MonsterPortrait)
function S.new(gui,remote,bag,journal)
 local self={}
 local function make(class,props,parent)
  local n=Instance.new(class) for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
 end
 local window=make("Frame",{Name="SocialWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.9,.82),BackgroundColor3=Color3.fromRGB(239,227,203),ZIndex=60},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1050,720)},window) make("UICorner",{CornerRadius=UDim.new(0,20)},window)
 local title=make("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-80,0,40),TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(48,77,55),ZIndex=61},window)
 local function button(text,x,y,w,parent,fn)
  local b=make("TextButton",{Text=text,Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,-10,0,38),BackgroundColor3=Color3.fromRGB(78,116,86),TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,ZIndex=64},parent)
  make("UICorner",{CornerRadius=UDim.new(0,8)},b) b.Activated:Connect(fn) return b
 end
 local content=make("ScrollingFrame",{Position=UDim2.fromOffset(18,110),Size=UDim2.new(1,-36,1,-178),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=6,ZIndex=61},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,205),CellPadding=UDim2.fromOffset(12,12)},content)
 local message=make("TextLabel",{Text="",Visible=false,AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,.08),Size=UDim2.new(.84,0,0,70),BackgroundColor3=Color3.fromRGB(44,70,52),TextColor3=Color3.fromRGB(255,242,204),TextSize=18,TextWrapped=true,ZIndex=100},gui)
 local noticeVersion=0
 function self.message(text) noticeVersion+=1 local v=noticeVersion message.Text=text message.Visible=true task.delay(5,function() if v==noticeVersion then message.Visible=false end end) end
 local controls=make("Frame",{Position=UDim2.fromOffset(18,63),Size=UDim2.new(1,-36,0,40),BackgroundTransparency=1,ZIndex=62},window)
 local footer=make("Frame",{Position=UDim2.new(0,18,1,-56),Size=UDim2.new(1,-36,0,42),BackgroundTransparency=1,ZIndex=62},window)
 local mode,selected,other,trade=nil,{},nil,nil
 local function clear(parent) for _,n in ipairs(parent:GetChildren()) do if not n:IsA("UIGridLayout") then n:Destroy() end end end
 local function open(name)
  if self.onOpen then self.onOpen() end
  bag.close() journal.close() window.Visible=true title.Text=name clear(content) clear(controls) clear(footer)
 end
 function self.close() window.Visible=false end
 local function ids() local out={} for id in pairs(selected) do table.insert(out,id) end table.sort(out) return out end
 local function card(m,fn)
  local frame=make("Frame",{BackgroundColor3=selected[m.id] and Color3.fromRGB(183,208,155) or Color3.fromRGB(251,243,224),Size=UDim2.fromOffset(170,205),ZIndex=62},content)
  make("UICorner",{CornerRadius=UDim.new(0,12)},frame)
  local v=make("ViewportFrame",{Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ZIndex=63},frame)
  Portrait.fill(v,m.monsterId,m.stars,false)
  make("TextLabel",{Text=(mode=="Trade" and not fn and "Partner · " or "")..L.text(m.monsterId,"en-us").." · "..m.stars.."★",Size=UDim2.new(1,0,0,24),Position=UDim2.fromOffset(0,139),BackgroundTransparency=1,TextSize=15,ZIndex=63},frame)
  if fn then button((selected[m.id] and "✓ " or "")..(m.sex=="Male" and "♂ " or m.sex=="Female" and "♀ " or "").."Select",0,166,1,frame,fn) end
 end
 local renderSelection
 renderSelection=function()
  open(mode=="Breed" and "Breed · Up to 4 pairs / 8 monsters" or "Profile · Up to 5 monsters")
  button(mode=="Breed" and "Female + Male · Coming soon" or (#ids().." / 5 selected"),0,0,1,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil elseif #ids()<(mode=="Breed" and 2 or 5) and not m.breedingTeam then selected[m.id]=true end renderSelection()
  end) end
  button(mode=="Breed" and "Check pairing" or "Save profile",.5,0,.5,footer,function() remote:FireServer(mode=="Breed" and "Breed" or "ProfileSave",ids()) end)
 end
 function self.breed() mode="Breed" selected={} renderSelection() end
 function self.edit() mode="Profile" selected={} for _,id in ipairs(self.profile or {}) do selected[id]=true end renderSelection() end
 local close=button("×",.93,10,.07,window,function() window.Visible=false if trade then remote:FireServer("TradeDecline") end end)
 close.Size=UDim2.fromOffset(38,38)
 local function showTrade(data)
  trade=data mode="Trade" open("Trade · "..data.name)
  selected={} for _,id in ipairs(data.mine.ids) do selected[id]=true end
  local coins=make("TextBox",{Text=tostring(data.mine.coins),PlaceholderText="Coins to offer",ClearTextOnFocus=false,Size=UDim2.new(.28,0,0,36),TextSize=18,ZIndex=64},controls)
  button("Update offer",.3,0,.23,controls,function() remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text)}) end)
  button("Partner: "..data.theirs.coins.." coins / "..#data.theirs.ids.." monsters",.54,0,.46,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil else selected[m.id]=true end
   remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text) or 0})
  end) end
  for _,m in ipairs(data.theirs.monsters or {}) do card(m,nil) end
  button(data.accepted and "Cancel" or "Decline trade",0,0,.3,footer,function() remote:FireServer("TradeDecline") window.Visible=false end)
  if not data.accepted then button("Accept trade",.5,0,.5,footer,function() remote:FireServer("TradeAccept") end)
  elseif data.ready and data.otherReady then button(data.final and "Waiting for final confirmation" or "Confirm exchange",.5,0,.5,footer,function() remote:FireServer("TradeConfirm",data.revision) end)
  else button(data.ready and "Waiting for partner" or "Confirm offer",.5,0,.5,footer,function() remote:FireServer("TradeReady",data.revision) end) end
 end
 function self.event(kind,data)
  if kind=="SocialMessage" then self.message(data)
  elseif kind=="Profile" then
   mode="View" other=data.userId open(data.name.."  @"..data.username)
   local avatar=make("ImageLabel",{BackgroundTransparency=1,Size=UDim2.fromOffset(170,205),ZIndex=63},content)
   task.spawn(function() local ok,url=pcall(function() return Players:GetUserThumbnailAsync(data.userId,Enum.ThumbnailType.AvatarThumbnail,Enum.ThumbnailSize.Size420x420) end) if ok and avatar.Parent then avatar.Image=url end end)
   for _,m in ipairs(data.monsters) do card(m,nil) end
   button("View index",0,0,.5,footer,function() remote:FireServer("OtherJournal",other) end)
   button("Request trade",.5,0,.5,footer,function() remote:FireServer("TradeRequest",other) end)
  elseif kind=="OtherJournal" then window.Visible=false journal.viewOther(data)
  elseif kind=="Trade" then showTrade(data)
  elseif kind=="TradeInvitation" then self.message(data.name.." requested a trade.")
  elseif kind=="TradeClosed" then trade=nil if mode=="Trade" then window.Visible=false end
  elseif kind=="Eggs" then
   mode="Eggs" open("Eggs · Hatchery "..data.pen.." · One egg per slot")
   if #data.eggs==0 then self.message("No eggs yet. Breeding is coming soon.") end
   for _,egg in ipairs(data.eggs) do
    button("Egg "..tostring(egg.id)..(egg.assignedPen and " · Placed" or " · Bag"),0,0,1,content,function() remote:FireServer(egg.assignedPen==data.pen and "RemoveEgg" or "PlaceEgg",{id=egg.id,pen=data.pen}) end)
   end
  end
 end
 local tStart
 UIS.InputBegan:Connect(function(input,processed) if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Cafe" then tStart=os.clock() end end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.T then tStart=nil end end)
 Run.RenderStepped:Connect(function() if tStart and os.clock()-tStart>=1 then tStart=nil self.edit() end end)
 local edit=button("Hold T · Edit profile",.02,14,.24,gui,self.edit)
 function self.state(data) self.area=data.area self.profile=data.profile or self.profile edit.Visible=data.area=="Cafe" end
 edit.Visible=false bag.onBreed=self.breed
 return self
end
return S
]====] local after=[====[local S={}
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local Portrait=require(script.Parent.MonsterPortrait)
function S.new(gui,remote,bag,journal)
 local self={}
 local function make(class,props,parent)
  local n=Instance.new(class) for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
 end
 local window=make("Frame",{Name="SocialWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.9,.82),BackgroundColor3=Color3.fromRGB(239,227,203),ZIndex=60},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1050,720)},window) make("UICorner",{CornerRadius=UDim.new(0,20)},window)
 local title=make("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-80,0,40),TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(48,77,55),ZIndex=61},window)
 local function button(text,x,y,w,parent,fn)
  local b=make("TextButton",{Text=text,Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,-10,0,38),BackgroundColor3=Color3.fromRGB(78,116,86),TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,ZIndex=64},parent)
  make("UICorner",{CornerRadius=UDim.new(0,8)},b) b.Activated:Connect(fn) return b
 end
 local content=make("ScrollingFrame",{Position=UDim2.fromOffset(18,110),Size=UDim2.new(1,-36,1,-178),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=6,ZIndex=61},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,205),CellPadding=UDim2.fromOffset(12,12)},content)
 local message=make("TextLabel",{Text="",Visible=false,AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,.08),Size=UDim2.new(.84,0,0,70),BackgroundColor3=Color3.fromRGB(44,70,52),TextColor3=Color3.fromRGB(255,242,204),TextSize=18,TextWrapped=true,ZIndex=100},gui)
 local noticeVersion=0
 function self.message(text) noticeVersion+=1 local v=noticeVersion message.Text=text message.Visible=true task.delay(5,function() if v==noticeVersion then message.Visible=false end end) end
 local controls=make("Frame",{Position=UDim2.fromOffset(18,63),Size=UDim2.new(1,-36,0,40),BackgroundTransparency=1,ZIndex=62},window)
 local footer=make("Frame",{Position=UDim2.new(0,18,1,-56),Size=UDim2.new(1,-36,0,42),BackgroundTransparency=1,ZIndex=62},window)
 local mode,selected,other,trade=nil,{},nil,nil
 local function clear(parent) for _,n in ipairs(parent:GetChildren()) do if not n:IsA("UIGridLayout") then n:Destroy() end end end
 local function open(name)
  if self.onOpen then self.onOpen() end
  bag.close() journal.close() window.Visible=true title.Text=name clear(content) clear(controls) clear(footer)
 end
 function self.close() window.Visible=false end
 local function ids() local out={} for id in pairs(selected) do table.insert(out,id) end table.sort(out) return out end
 local function card(m,fn)
  local frame=make("Frame",{BackgroundColor3=selected[m.id] and Color3.fromRGB(183,208,155) or Color3.fromRGB(251,243,224),Size=UDim2.fromOffset(170,205),ZIndex=62},content)
  make("UICorner",{CornerRadius=UDim.new(0,12)},frame)
  local v=make("Frame",{Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ZIndex=63},frame)
  Portrait.fill(v,m.monsterId,m.stars,false)
  make("TextLabel",{Text=(mode=="Trade" and not fn and "Partner · " or "")..L.text(m.monsterId,"en-us").." · "..m.stars.."★",Size=UDim2.new(1,0,0,24),Position=UDim2.fromOffset(0,139),BackgroundTransparency=1,TextSize=15,ZIndex=63},frame)
  if fn then button((selected[m.id] and "✓ " or "")..(m.sex=="Male" and "♂ " or m.sex=="Female" and "♀ " or "").."Select",0,166,1,frame,fn) end
 end
 local renderSelection
 renderSelection=function()
  open(mode=="Breed" and "Breed · Up to 4 pairs / 8 monsters" or "Profile · Up to 5 monsters")
  button(mode=="Breed" and "Female + Male · Coming soon" or (#ids().." / 5 selected"),0,0,1,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil elseif #ids()<(mode=="Breed" and 2 or 5) and not m.breedingTeam then selected[m.id]=true end renderSelection()
  end) end
  button(mode=="Breed" and "Check pairing" or "Save profile",.5,0,.5,footer,function() remote:FireServer(mode=="Breed" and "Breed" or "ProfileSave",ids()) end)
 end
 function self.breed() mode="Breed" selected={} renderSelection() end
 function self.edit() mode="Profile" selected={} for _,id in ipairs(self.profile or {}) do selected[id]=true end renderSelection() end
 local close=button("×",.93,10,.07,window,function() window.Visible=false if trade then remote:FireServer("TradeDecline") end end)
 close.Size=UDim2.fromOffset(38,38)
 local function showTrade(data)
  trade=data mode="Trade" open("Trade · "..data.name)
  selected={} for _,id in ipairs(data.mine.ids) do selected[id]=true end
  local coins=make("TextBox",{Text=tostring(data.mine.coins),PlaceholderText="Coins to offer",ClearTextOnFocus=false,Size=UDim2.new(.28,0,0,36),TextSize=18,ZIndex=64},controls)
  button("Update offer",.3,0,.23,controls,function() remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text)}) end)
  button("Partner: "..data.theirs.coins.." coins / "..#data.theirs.ids.." monsters",.54,0,.46,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil else selected[m.id]=true end
   remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text) or 0})
  end) end
  for _,m in ipairs(data.theirs.monsters or {}) do card(m,nil) end
  button(data.accepted and "Cancel" or "Decline trade",0,0,.3,footer,function() remote:FireServer("TradeDecline") window.Visible=false end)
  if not data.accepted then button("Accept trade",.5,0,.5,footer,function() remote:FireServer("TradeAccept") end)
  elseif data.ready and data.otherReady then button(data.final and "Waiting for final confirmation" or "Confirm exchange",.5,0,.5,footer,function() remote:FireServer("TradeConfirm",data.revision) end)
  else button(data.ready and "Waiting for partner" or "Confirm offer",.5,0,.5,footer,function() remote:FireServer("TradeReady",data.revision) end) end
 end
 function self.event(kind,data)
  if kind=="SocialMessage" then self.message(data)
  elseif kind=="Profile" then
   mode="View" other=data.userId open(data.name.."  @"..data.username)
   local avatar=make("ImageLabel",{BackgroundTransparency=1,Size=UDim2.fromOffset(170,205),ZIndex=63},content)
   task.spawn(function() local ok,url=pcall(function() return Players:GetUserThumbnailAsync(data.userId,Enum.ThumbnailType.AvatarThumbnail,Enum.ThumbnailSize.Size420x420) end) if ok and avatar.Parent then avatar.Image=url end end)
   for _,m in ipairs(data.monsters) do card(m,nil) end
   button("View index",0,0,.5,footer,function() remote:FireServer("OtherJournal",other) end)
   button("Request trade",.5,0,.5,footer,function() remote:FireServer("TradeRequest",other) end)
  elseif kind=="OtherJournal" then window.Visible=false journal.viewOther(data)
  elseif kind=="Trade" then showTrade(data)
  elseif kind=="TradeInvitation" then self.message(data.name.." requested a trade.")
  elseif kind=="TradeClosed" then trade=nil if mode=="Trade" then window.Visible=false end
  elseif kind=="Eggs" then
   mode="Eggs" open("Eggs · Hatchery "..data.pen.." · One egg per slot")
   if #data.eggs==0 then self.message("No eggs yet. Breeding is coming soon.") end
   for _,egg in ipairs(data.eggs) do
    button("Egg "..tostring(egg.id)..(egg.assignedPen and " · Placed" or " · Bag"),0,0,1,content,function() remote:FireServer(egg.assignedPen==data.pen and "RemoveEgg" or "PlaceEgg",{id=egg.id,pen=data.pen}) end)
   end
  end
 end
 local tStart
 UIS.InputBegan:Connect(function(input,processed) if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Cafe" then tStart=os.clock() end end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.T then tStart=nil end end)
 Run.RenderStepped:Connect(function() if tStart and os.clock()-tStart>=1 then tStart=nil self.edit() end end)
 local edit=button("Hold T · Edit profile",.02,14,.24,gui,self.edit)
 function self.state(data) self.area=data.area self.profile=data.profile or self.profile edit.Visible=data.area=="Cafe" end
 edit.Visible=false bag.onBreed=self.breed
 return self
end
return S
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed SocialUI") table.insert(changes,{n=n,after=after}) end
do local n=assert(parent:FindFirstChild("HudIcons")) local before=[====[-- Small native shapes: no external images are required for the menu symbols.
local I={}
-- IDs supplied by the user from their uploaded image list.
I.ImageIds={RideButtonImage="rbxassetid://120607489729893",ClockImage="rbxassetid://77808310736115",ShopButtonImage="rbxassetid://114640852127407",RouletteButtonImage="rbxassetid://71863210551741",IndexButtonImage="rbxassetid://110488541037597",BondButtonImage="rbxassetid://104399312241349",
 EggButtonImage="rbxassetid://87551432940862",PawButtonImage="rbxassetid://85966265063532",MossratFaceImage="rbxassetid://97843855045095",MoneyImage="rbxassetid://71604722538432"}
function I.imageId(package,key)
 local id=package:GetAttribute(key)
 if key=="PawButtonImage" and id=="rbxassetid://8596625063532" then return I.ImageIds[key] end
 if type(id)=="string" and id~="rbxassetid://0" and id:match("^rbxassetid://%d+$") then return id end
 return I.ImageIds[key] or ""
end
-- User-supplied PNGs become Roblox image assets only after upload. Keep the
-- native controls usable until their content IDs are configured.
function I.bindArtwork(button,key)
 local package=game.ReplicatedStorage.RodeoFantasy
 local image=Instance.new("ImageLabel") image.Name="UploadedArtwork"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ZIndex=button.ZIndex+2 image.ScaleType=Enum.ScaleType.Fit image.Parent=button
 local background=button.BackgroundTransparency
 local originals,strokes={},{}
 for _,n in ipairs(button:GetChildren()) do
  if n:IsA("GuiObject") and n~=image then originals[n]=n.Visible
  elseif n:IsA("UIStroke") then strokes[n]=n.Enabled end
 end
 local function display()
  local ready=image.Image~="" and image.IsLoaded
  -- Keep the label renderable while Roblox requests the image. Hiding it until
  -- IsLoaded can leave it waiting indefinitely; a faint image permits loading.
  image.Visible=true image.ImageTransparency=ready and 0 or .99
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
 local function refresh()
  local id=I.imageId(package,key)
  if image.Image~=id then image.Image=id end
  display()
  -- IsLoaded may update without a property signal. Poll only this request and
  -- stop when it loads, changes, or the control is removed.
  task.spawn(function()
   while image.Parent and image.Image==id and not image.IsLoaded do task.wait(.25) end
   if image.Parent and image.Image==id then display() end
  end)
 end
 image:GetPropertyChangedSignal("IsLoaded"):Connect(display)
 package:GetAttributeChangedSignal(key):Connect(refresh) refresh()
end
function I.draw(parent,kind,size)
 local root=Instance.new("Frame") root.Name=kind.."Icon" root.Size=UDim2.fromOffset(size,size) root.BackgroundTransparency=1 root.Parent=parent
 local function shape(x,y,w,h,color,radius,rotation)
  local n=Instance.new("Frame") n.Position=UDim2.fromScale(x,y) n.Size=UDim2.fromScale(w,h) n.BackgroundColor3=color n.BorderSizePixel=0 n.Rotation=rotation or 0 n.Parent=root
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(radius or 0,0) c.Parent=n
  local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(15,18,20) s.Thickness=2 s.Parent=n return n
 end
 local white=Color3.fromRGB(255,249,229)
 if kind=="Egg" then shape(.23,.08,.54,.82,Color3.fromRGB(255,211,145),.5)
 elseif kind=="Paw" then
  shape(.27,.48,.48,.4,Color3.fromRGB(255,198,124),.45)
  for _,p in ipairs({{.08,.3},{.28,.1},{.53,.1},{.75,.3}}) do shape(p[1],p[2],.18,.28,Color3.fromRGB(255,209,151),.5) end
 elseif kind=="Shop" then
  shape(.2,.34,.65,.42,white,.12,-6) shape(.07,.17,.23,.09,white,.15)
  for _,x in ipairs({.3,.68}) do shape(x,.84,.15,.15,white,.5) end
 elseif kind=="Journal" then
  shape(.18,.17,.64,.66,white,.07,-8)
  for _,y in ipairs({.33,.48,.63}) do shape(.32,y,.36,.025,Color3.fromRGB(60,74,82),0) end
 elseif kind=="Money" then
  shape(.06,.25,.78,.52,Color3.fromRGB(92,226,39),.05,-12)
  shape(.2,.12,.75,.5,Color3.fromRGB(130,255,59),.05,-12)
  shape(.44,.16,.13,.51,Color3.fromRGB(240,215,35),0,-12)
 elseif kind=="Roulette" then
  shape(.08,.08,.84,.84,Color3.fromRGB(255,219,48),.5)
  for i=0,5 do local a=i*math.pi/3 shape(.43+math.cos(a)*.25,.43+math.sin(a)*.25,.16,.16,i%2==0 and Color3.fromRGB(255,93,104) or white,.5) end
  shape(.4,.4,.2,.2,Color3.fromRGB(250,250,250),.5)
 end
 return root
end
return I
]====] local after=[====[-- Small native shapes: no external images are required for the menu symbols.
local I={}
-- IDs supplied by the user from their uploaded image list.
I.ImageIds={RideButtonImage="rbxassetid://120607489729893",ClockImage="rbxassetid://87364518179349",ShopButtonImage="rbxassetid://114640852127407",RouletteButtonImage="rbxassetid://71863210551741",IndexButtonImage="rbxassetid://110488541037597",BondButtonImage="rbxassetid://104399312241349",
 EggButtonImage="rbxassetid://87551432940862",PawButtonImage="rbxassetid://85966265063532",MossratFaceImage="rbxassetid://97843855045095",MoneyImage="rbxassetid://71604722538432"}
function I.imageId(package,key)
 local id=package:GetAttribute(key)
 if key=="PawButtonImage" and id=="rbxassetid://8596625063532" then return I.ImageIds[key] end
 if type(id)=="string" and id~="rbxassetid://0" and id:match("^rbxassetid://%d+$") then return id end
 return I.ImageIds[key] or ""
end
-- User-supplied PNGs become Roblox image assets only after upload. Keep the
-- native controls usable until their content IDs are configured.
function I.bindArtwork(button,key)
 local package=game.ReplicatedStorage.RodeoFantasy
 local image=Instance.new("ImageLabel") image.Name="UploadedArtwork"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ZIndex=button.ZIndex+2 image.ScaleType=Enum.ScaleType.Fit image.Parent=button
 local background=button.BackgroundTransparency
 local originals,strokes={},{}
 for _,n in ipairs(button:GetChildren()) do
  if n:IsA("GuiObject") and n~=image then originals[n]=n.Visible
  elseif n:IsA("UIStroke") then strokes[n]=n.Enabled end
 end
 local function display()
  local ready=image.Image~="" and image.IsLoaded
  -- Keep the label renderable while Roblox requests the image. Hiding it until
  -- IsLoaded can leave it waiting indefinitely; a faint image permits loading.
  image.Visible=true image.ImageTransparency=ready and 0 or .99
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
 local function refresh()
  local id=I.imageId(package,key)
  if image.Image~=id then image.Image=id end
  display()
  -- IsLoaded may update without a property signal. Poll only this request and
  -- stop when it loads, changes, or the control is removed.
  task.spawn(function()
   while image.Parent and image.Image==id and not image.IsLoaded do task.wait(.25) end
   if image.Parent and image.Image==id then display() end
  end)
 end
 image:GetPropertyChangedSignal("IsLoaded"):Connect(display)
 package:GetAttributeChangedSignal(key):Connect(refresh) refresh()
end
function I.draw(parent,kind,size)
 local root=Instance.new("Frame") root.Name=kind.."Icon" root.Size=UDim2.fromOffset(size,size) root.BackgroundTransparency=1 root.Parent=parent
 local function shape(x,y,w,h,color,radius,rotation)
  local n=Instance.new("Frame") n.Position=UDim2.fromScale(x,y) n.Size=UDim2.fromScale(w,h) n.BackgroundColor3=color n.BorderSizePixel=0 n.Rotation=rotation or 0 n.Parent=root
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(radius or 0,0) c.Parent=n
  local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(15,18,20) s.Thickness=2 s.Parent=n return n
 end
 local white=Color3.fromRGB(255,249,229)
 if kind=="Egg" then shape(.23,.08,.54,.82,Color3.fromRGB(255,211,145),.5)
 elseif kind=="Paw" then
  shape(.27,.48,.48,.4,Color3.fromRGB(255,198,124),.45)
  for _,p in ipairs({{.08,.3},{.28,.1},{.53,.1},{.75,.3}}) do shape(p[1],p[2],.18,.28,Color3.fromRGB(255,209,151),.5) end
 elseif kind=="Shop" then
  shape(.2,.34,.65,.42,white,.12,-6) shape(.07,.17,.23,.09,white,.15)
  for _,x in ipairs({.3,.68}) do shape(x,.84,.15,.15,white,.5) end
 elseif kind=="Journal" then
  shape(.18,.17,.64,.66,white,.07,-8)
  for _,y in ipairs({.33,.48,.63}) do shape(.32,y,.36,.025,Color3.fromRGB(60,74,82),0) end
 elseif kind=="Money" then
  shape(.06,.25,.78,.52,Color3.fromRGB(92,226,39),.05,-12)
  shape(.2,.12,.75,.5,Color3.fromRGB(130,255,59),.05,-12)
  shape(.44,.16,.13,.51,Color3.fromRGB(240,215,35),0,-12)
 elseif kind=="Roulette" then
  shape(.08,.08,.84,.84,Color3.fromRGB(255,219,48),.5)
  for i=0,5 do local a=i*math.pi/3 shape(.43+math.cos(a)*.25,.43+math.sin(a)*.25,.16,.16,i%2==0 and Color3.fromRGB(255,93,104) or white,.5) end
  shape(.4,.4,.2,.2,Color3.fromRGB(250,250,250),.5)
 end
 return root
end
return I
]====] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Changed HudIcons") table.insert(changes,{n=n,after=after}) end
local backup=Instance.new("Folder") backup.Name="PortraitRideSmoothBackup" backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do c.n:Clone().Parent=backup c.n.Source=c.after end
local P=game.ReplicatedStorage.RodeoFantasy
P:SetAttribute("ClockImage","rbxassetid://87364518179349")
P:SetAttribute("MossratPortraitS1","rbxassetid://136157716828140")
P:SetAttribute("MossratPortraitS3","rbxassetid://132856650627155")
P:SetAttribute("MossratPortraitS6","rbxassetid://117627702063447")
P:SetAttribute("MossratPortraitS9","rbxassetid://127579346809789")
print("PORTRAIT_RIDE_SMOOTH_INSTALLED",#changes)
