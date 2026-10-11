local updates={}
table.insert(updates,{parent=game.StarterPlayer.StarterPlayerScripts,name="RideAnimator",before=[====[-- Procedural visual motion for the native part model. Never changes its mount root.
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
]====],after=[====[-- Procedural visual motion for the native part model. Never changes its mount root.
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
local travelFrames=setmetatable({},{__mode="k"})
function RideAnimator.frame(model) return renderedFrames[model] end
-- Camera tracks locomotion only; stride bounce/pitch belong to the creature.
function RideAnimator.travelFrame(model) return travelFrames[model] end
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
  travelFrames[model]=facingFrame
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
]====]})
table.insert(updates,{parent=game.StarterPlayer.StarterPlayerScripts,name="PetPromptUI",before=[====[-- Only this bounded image button can request bonding; no world-touch prompt.
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
]====],after=[====[-- Only this bounded image button can request bonding; no world-touch prompt.
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
 local cameraTarget local cameraHeading local cameraPet
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
   local travel=pet and presentation.travelFrame(pet) or (part and part.CFrame or root.CFrame)
   local forward=Vector3.new(travel.LookVector.X,0,travel.LookVector.Z)
   if forward.Magnitude<.001 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
   local rootHeight=pet and pet:GetAttribute("RootHeight") or 2
   local upright=pet and (pet:GetAttribute("Stars") or 1)>=6
   local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
   local target=(travel*CFrame.new(offset)).Position+Vector3.new(0,1,0)
   local heading=CFrame.lookAt(Vector3.zero,forward)
   if cameraPet~=pet or not cameraTarget or (target-cameraTarget).Magnitude>30 then
    cameraTarget=target cameraHeading=heading cameraPet=pet
   else
    cameraTarget=cameraTarget:Lerp(target,1-math.exp(-14*dt))
    cameraHeading=cameraHeading:Lerp(heading,1-math.exp(-8*dt))
   end
   camera.CFrame=CFrame.lookAt(cameraTarget-cameraHeading.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),cameraTarget)
   inputTime+=dt
   local direction=hum.MoveDirection
   if inputTime>=.08 and (not lastInput or (direction-lastInput).Magnitude>.02 or inputTime>=.25) then
    inputTime=0 lastInput=direction package.CaptureRemote:FireServer("RideInput",direction)
   end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
   inputTime=0 lastInput=nil cameraTarget=nil cameraHeading=nil cameraPet=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]====]})
table.insert(updates,{parent=game.StarterPlayer.StarterPlayerScripts,name="NativeMossrat",before=[====[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local stage=C.stage(model:GetAttribute("Stars") or 1)
 local visual=package:FindFirstChild(C.visual("MeadowMouse",stage))
 return model:GetAttribute("MonsterId")=="MeadowMouse" and (stage==1 or stage==3 or stage==6 or stage==9) and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local stage=C.stage(stars)
 local suffix=stage==1 and "" or "_S"..stage
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate"..suffix) or package:FindFirstChild(C.visual("MeadowMouse",stars))
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 elseif source:GetAttribute("MossratUserRigRevision")=="UserS3-v1" or source:GetAttribute("MossratUserRigRevision")=="UserS6-v1" or source:GetAttribute("MossratUserRigRevision")=="UserS9-v1" then
  yaw+=180
  facingRevision..="-ForwardV3"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(stars)/C.Scales[stage]
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
function M.posePortrait(model)
 if not M.isTarget(model) then return end
 rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
 rigAnimator.poseFront(model)
end
function M.huntFrame(model,frame)
 local stage=C.stage(model:GetAttribute("Stars") or 1)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate"..(stage==1 and "" or "_S"..stage))
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
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
]====],after=[====[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local bipedAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local stage=C.stage(model:GetAttribute("Stars") or 1)
 local visual=package:FindFirstChild(C.visual("MeadowMouse",stage))
 return model:GetAttribute("MonsterId")=="MeadowMouse" and (stage==1 or stage==3 or stage==6 or stage==9) and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local stage=C.stage(stars)
 local suffix=stage==1 and "" or "_S"..stage
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate"..suffix) or package:FindFirstChild(C.visual("MeadowMouse",stars))
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 elseif source:GetAttribute("MossratUserRigRevision")=="UserS3-v1" or source:GetAttribute("MossratUserRigRevision")=="UserS6-v1" or source:GetAttribute("MossratUserRigRevision")=="UserS9-v1" then
  yaw+=180
  facingRevision..="-ForwardV3"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(stars)/C.Scales[stage]
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
function M.posePortrait(model)
 if not M.isTarget(model) then return end
 rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
 rigAnimator.poseFront(model)
end
function M.huntFrame(model,frame)
 local stage=C.stage(model:GetAttribute("Stars") or 1)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate"..(stage==1 and "" or "_S"..stage))
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and model:GetAttribute("MossratUserRigRevision")=="ProvidedBiped-v1" then
  bipedAnimator=bipedAnimator or require(script.Parent.BipedAnimator)
  bipedAnimator.animate(model,moving)
  return
 end
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
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
]====]})
table.insert(updates,{parent=game.StarterPlayer.StarterPlayerScripts,name="BipedAnimator",before=nil,after=[====[-- One decoded clip cache; each creature owns only its skeleton and playback state.
local raw=require(game.ReplicatedStorage.RodeoFantasy.BipedMotionData)
local A={}
local clips={}
local index={}
for i,name in ipairs(raw.bones) do index[name]=i end
for name,clip in pairs(raw.clips) do
 local frames={}
 for i,row in ipairs(clip.frames) do
  local decoded={}
  for j,r in ipairs(row) do decoded[j]=CFrame.new(0,0,0,table.unpack(r)) end
  frames[i]=decoded
 end
 clips[name]={frames=frames,duration=clip.duration,hips=clip.hips}
end
local mapping={Pelvis="Hips",Spine="Spine",Chest="Spine2",Neck="Neck",Head="Head"}
for _,side in ipairs({"Left","Right"}) do
 mapping[side.."FrontUpper"]=side.."Arm"
 mapping[side.."FrontLower"]=side.."ForeArm"
 mapping[side.."FrontPaw"]=side.."Hand"
 mapping[side.."RearUpper"]=side.."UpLeg"
 mapping[side.."RearLower"]=side.."Leg"
 mapping[side.."RearPaw"]=side.."Foot"
end
local cache=setmetatable({},{__mode="k"})
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,phase=0}
  local function visit(parent,parentEntry,world)
   for _,b in ipairs(parent:GetChildren()) do
    if b:IsA("Bone") then
     local rest=world*b.CFrame
     local name=b.Name local source=index[name] or index["mixamorig:"..(mapping[name] or name)]
     local entry={bone=b,rest=rest,localRest=b.CFrame,parent=parentEntry,source=source}
     c.bones[#c.bones+1]=entry visit(b,entry,rest)
    end
   end
  end
  visit(body,nil,CFrame.identity) cache[model]=c
 end
 local now=os.clock() local camera=workspace.CurrentCamera
 local distance=camera and (body.Position-camera.CFrame.Position).Magnitude or 0
 if distance>150 and model:GetAttribute("RiderUserId")~=game.Players.LocalPlayer.UserId then return end
 local interval=distance>70 and .1 or moving and 1/30 or 1/15
 if now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 0 c.last=now
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=moving and speed>18
 local clip=clips[running and "Running" or "Walking"]
 if moving then c.phase=(c.phase+dt/clip.duration)%1 end
 local sample=(moving and c.phase or 0)*(#clip.frames-1)
 local i=math.floor(sample)+1 local t=sample-math.floor(sample)
 local first,second=clip.frames[i],clip.frames[math.min(i+1,#clip.frames)]
 local hipA,hipB=clip.hips[i],clip.hips[math.min(i+1,#clip.hips)]
 local translationScale=body.Size.Y/1.71
 local hip=Vector3.new(hipA[1]+(hipB[1]-hipA[1])*t,hipA[2]+(hipB[2]-hipA[2])*t,hipA[3]+(hipB[3]-hipA[3])*t)*translationScale
 if not moving then hip=Vector3.zero end
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bondTime=workspace:GetServerTimeNow()
 local bonding=bondUntil>bondTime
 local ease=bonding and math.min(math.clamp((bondTime-(model:GetAttribute("PetBondStarted") or bondTime))/.4,0,1),math.clamp((bondUntil-bondTime)/.4,0,1)) or 0
 for _,e in ipairs(c.bones) do
  local parentRotation=e.parent and e.parent.currentRotation or CFrame.identity
  local desired=e.source and (moving and first[e.source]:Lerp(second[e.source],t) or CFrame.identity)*e.rest.Rotation or parentRotation*e.localRest.Rotation
  local name=e.bone.Name:gsub("mixamorig:","")
  if bonding then
   local side=name:find("Left",1,true) and 1 or -1
   local pose=CFrame.identity
   if name:find("Arm",1,true) and not name:find("Fore",1,true) then pose=CFrame.Angles(-.25,0,side*1.15)
   elseif name:find("ForeArm",1,true) then pose=CFrame.Angles(-1.3,0,0)
   elseif name=="Spine2" then pose=CFrame.Angles(-.12,0,0) end
   desired=desired:Lerp(pose*e.rest.Rotation,ease)
  end
  local transform=e.localRest.Rotation:Inverse()*parentRotation:Inverse()*desired
  if name=="Hips" or name=="Pelvis" then
   transform=CFrame.new(e.localRest.Rotation:VectorToObjectSpace(parentRotation:VectorToObjectSpace(hip)))*transform
  end
  e.bone.Transform=e.bone.Transform:Lerp(transform,1-math.exp(-18*dt))
  e.currentRotation=parentRotation*e.localRest.Rotation*e.bone.Transform.Rotation
 end
end
return A
]====]})
table.insert(updates,{parent=game.ReplicatedStorage.RodeoFantasy,name="BipedMotionData",before=nil,after=[====[-- Generated from user-provided walking/running; shared by compatible bipeds.
return {["bones"]={"mixamorig:Hips","mixamorig:LeftUpLeg","mixamorig:LeftLeg","mixamorig:LeftFoot","mixamorig:LeftToeBase","mixamorig:RightUpLeg","mixamorig:RightLeg","mixamorig:RightFoot","mixamorig:RightToeBase","mixamorig:Spine","mixamorig:Spine1","mixamorig:Spine2","mixamorig:LeftShoulder","mixamorig:LeftArm","mixamorig:LeftForeArm","mixamorig:LeftHand","mixamorig:RightShoulder","mixamorig:RightArm","mixamorig:RightForeArm","mixamorig:RightHand","mixamorig:Neck","mixamorig:Head","headfront"},["clips"]={["Walking"]={["duration"]=1.0833334,["frames"]={{{0.99711646,0.056643148,0.050500735,-0.049988584,0.99096114,-0.12448757,-0.057095631,0.12160414,0.99093518},{0.97801756,0.02496077,0.20702318,-0.075674996,0.9676105,0.24083856,-0.1943063,-0.25121083,0.94822899},{0.98669322,0.12802098,0.10023543,-0.07493502,0.90515498,-0.41842468,-0.14429573,0.40534565,0.90270351},{0.97308438,0.20687289,0.10154011,-0.10117955,0.77940602,-0.61829517,-0.20704949,0.59137959,0.77935917},{0.98313631,0.14817593,0.10717675,-0.060080382,0.81524622,-0.57598959,-0.17272327,0.55983703,0.81040061},{0.98929255,-0.11780636,-0.086150119,0.12827329,0.9834132,0.12823599,0.06961422,-0.13791368,0.9879948},{0.99813984,-0.053506279,-0.029221054,0.049250619,0.99018508,-0.13079729,0.035932789,0.1291148,0.99097842},{0.99394501,-0.10390437,-0.035736485,0.097971065,0.98530617,-0.13990535,0.04974828,0.13555703,0.98951979},{0.99819873,-0.047018355,-0.037261947,0.0409176,0.98779342,-0.15029929,0.043874023,0.14850398,0.98793814},{0.9995379,-0.025646486,0.016316804,0.028020152,0.98547116,-0.16751557,-0.011783553,0.16789538,0.98573439},{0.99906914,-0.03779352,-0.020796814,0.033118255,0.98091337,-0.19160412,0.027641271,0.19073702,0.98125193},{0.99810679,-0.0044071247,-0.061346586,-0.0033535817,0.992046,-0.1258312,0.061413198,0.12579871,0.99015307},{0.87986101,0.38542771,-0.27801091,-0.44264765,0.87755325,-0.18429158,0.17293834,0.28521182,0.94273355},{0.81075915,0.15361256,-0.56486528,-0.27411964,0.95224532,-0.13448909,0.51723108,0.26387886,0.81414981},{0.81322626,-0.12225193,-0.56896176,-0.16507442,0.88906787,-0.42697629,0.55804429,0.4411493,0.70283276},{0.80621477,-0.068718569,-0.58761851,-0.29388559,0.81550504,-0.4985808,0.5134676,0.57465574,0.63727684},{0.93229789,-0.35607776,0.063476398,0.36133653,0.90915581,-0.20705461,0.016017605,0.215973,0.97626796},{0.89689353,-0.14716491,0.41704254,0.16631877,0.98602393,-0.0097402765,-0.40978056,0.07809806,0.90883475},{0.85121007,-0.0049549513,0.52480174,0.070501736,0.99197154,-0.10498561,-0.52006822,0.12636425,0.84472546},{0.82798416,-0.11356922,0.54913046,0.21464331,0.96888348,-0.1232602,-0.51804489,0.21992469,0.826597},{0.99929524,-0.022854608,-0.029777347,0.019356212,0.99341867,-0.11289233,0.032161489,0.11223638,0.99316093},{0.99928372,-0.0038763739,0.037643434,0.0065610135,0.99742203,-0.071457988,-0.037269387,0.071653776,0.99673303},{0.99928371,-0.003875121,0.03764371,0.0065598673,0.99742189,-0.071460047,-0.037269738,0.071655807,0.99673287}},{{0.99711646,0.056643148,0.050500735,-0.049988584,0.99096114,-0.12448757,-0.057095631,0.12160414,0.99093518},{0.97801756,0.02496077,0.20702318,-0.075674996,0.9676105,0.24083856,-0.1943063,-0.25121083,0.94822899},{0.98669322,0.12802098,0.10023543,-0.07493502,0.90515498,-0.41842468,-0.14429573,0.40534565,0.90270351},{0.97308438,0.20687289,0.10154011,-0.10117955,0.77940602,-0.61829517,-0.20704949,0.59137959,0.77935917},{0.98313631,0.14817593,0.10717675,-0.060080382,0.81524622,-0.57598959,-0.17272327,0.55983703,0.81040061},{0.98929255,-0.11780636,-0.086150119,0.12827329,0.9834132,0.12823599,0.06961422,-0.13791368,0.9879948},{0.99813984,-0.053506279,-0.029221054,0.049250619,0.99018508,-0.13079729,0.035932789,0.1291148,0.99097842},{0.99394501,-0.10390437,-0.035736485,0.097971065,0.98530617,-0.13990535,0.04974828,0.13555703,0.98951979},{0.99819873,-0.047018355,-0.037261947,0.0409176,0.98779342,-0.15029929,0.043874023,0.14850398,0.98793814},{0.9995379,-0.025646486,0.016316804,0.028020152,0.98547116,-0.16751557,-0.011783553,0.16789538,0.98573439},{0.99906914,-0.03779352,-0.020796814,0.033118255,0.98091337,-0.19160412,0.027641271,0.19073702,0.98125193},{0.99810679,-0.0044071247,-0.061346586,-0.0033535817,0.992046,-0.1258312,0.061413198,0.12579871,0.99015307},{0.87986101,0.38542771,-0.27801091,-0.44264765,0.87755325,-0.18429158,0.17293834,0.28521182,0.94273355},{0.81075915,0.15361256,-0.56486528,-0.27411964,0.95224532,-0.13448909,0.51723108,0.26387886,0.81414981},{0.81322626,-0.12225193,-0.56896176,-0.16507442,0.88906787,-0.42697629,0.55804429,0.4411493,0.70283276},{0.80621477,-0.068718569,-0.58761851,-0.29388559,0.81550504,-0.4985808,0.5134676,0.57465574,0.63727684},{0.93229789,-0.35607776,0.063476398,0.36133653,0.90915581,-0.20705461,0.016017605,0.215973,0.97626796},{0.89689353,-0.14716491,0.41704254,0.16631877,0.98602393,-0.0097402765,-0.40978056,0.07809806,0.90883475},{0.85121007,-0.0049549513,0.52480174,0.070501736,0.99197154,-0.10498561,-0.52006822,0.12636425,0.84472546},{0.82798416,-0.11356922,0.54913046,0.21464331,0.96888348,-0.1232602,-0.51804489,0.21992469,0.826597},{0.99929524,-0.022854608,-0.029777347,0.019356212,0.99341867,-0.11289233,0.032161489,0.11223638,0.99316093},{0.99928372,-0.0038763739,0.037643434,0.0065610135,0.99742203,-0.071457988,-0.037269387,0.071653776,0.99673303},{0.99928371,-0.003875121,0.03764371,0.0065598673,0.99742189,-0.071460047,-0.037269738,0.071655807,0.99673287}},{{0.99908886,0.026725801,0.033274327,-0.022491369,0.9923122,-0.12169901,-0.036271022,0.12083975,0.99200915},{0.98120388,0.030713493,0.19051405,-0.089514443,0.94705267,0.30834788,-0.17095643,-0.31960589,0.93200107},{0.98308589,0.12709996,0.13186263,-0.096938423,0.97197708,-0.21415769,-0.15538682,0.19775285,0.9678578},{0.96221423,0.23777266,0.13269488,-0.16647615,0.89933666,-0.40432569,-0.21547498,0.36695741,0.90493801},{0.97430145,0.18081881,0.13431761,-0.11737015,0.91650083,-0.38242705,-0.19225223,0.35683438,0.91417085},{0.98944353,-0.10696528,-0.097774927,0.11072517,0.99327417,0.033858055,0.093495674,-0.044326771,0.99463244},{0.99893451,-0.039302639,-0.024189582,0.03559282,0.98975315,-0.13828175,0.029376555,0.13727347,0.99009749},{0.99407493,-0.10323452,-0.034024444,0.0980172,0.98666429,-0.12994682,0.046985709,0.1258419,0.99093703},{0.99832611,-0.046516245,-0.034368517,0.041094458,0.98866381,-0.14441301,0.040696482,0.14275892,0.98892048},{0.99971529,-0.0051650925,0.023295171,0.0088722922,0.98675616,-0.16196778,-0.022150067,0.16212836,0.98652104},{0.99995254,-0.0081270259,-0.0053734339,0.0070016619,0.98295462,-0.18371499,0.006774907,0.18366866,0.98296487},{0.99874768,0.031972613,-0.038481459,-0.036176116,0.99281917,-0.11402361,0.034559506,0.11527295,0.99273248},{0.87252488,0.428856,-0.23405706,-0.47175996,0.8641161,-0.1753453,0.12705471,0.26341204,0.95627993},{0.85365656,0.16329887,-0.49457441,-0.28984573,0.93790056,-0.19060968,0.43273547,0.30606555,0.84797639},{0.85978538,-0.081665356,-0.50408308,-0.19535295,0.8594412,-0.47243852,0.47181179,0.50466992,0.72298128},{0.83586874,0.02335458,-0.54843222,-0.35998909,0.77757109,-0.51554929,0.4144048,0.62836126,0.65835469},{0.93896626,-0.33280416,0.087084105,0.34380133,0.91663396,-0.20391889,-0.011959287,0.22141267,0.97510688},{0.87059917,-0.13009523,0.47448107,0.13857034,0.99020247,0.017242902,-0.47207571,0.050737461,0.88009675},{0.80241884,0.0067185255,0.59672347,0.032202061,0.9979923,-0.054538739,-0.59589191,0.062978692,0.80059129},{0.78518133,-0.088810588,0.61286455,0.20033481,0.97287392,-0.11568225,-0.58596623,0.2136097,0.7816741},{0.99998489,-0.0040220585,-0.0037478011,0.0035959137,0.99419903,-0.1074958,0.0041584282,0.10748071,0.99419847},{0.99875474,0.01542967,0.047443697,-0.011995495,0.99734437,-0.071835359,-0.048426088,0.071176785,0.99628749},{0.99875471,0.015430881,0.047443938,-0.011996587,0.99734421,-0.071837431,-0.048426445,0.0711788,0.99628734}},{{0.9997541,-0.008184619,0.020609655,0.010612672,0.99264368,-0.12060635,-0.019470925,0.12079541,0.99248645},{0.98541274,0.036598811,0.16619944,-0.092473749,0.93499607,0.34239005,-0.14286476,-0.3527646,0.92474149},{0.97928196,0.11426969,0.16718049,-0.12342156,0.99131605,0.045382842,-0.16054279,-0.065076251,0.98488125},{0.95430517,0.24908567,0.1650999,-0.22289691,0.96129933,-0.16192779,-0.19904431,0.11772828,0.97289329},{0.96700007,0.19521722,0.16371047,-0.16900487,0.9723432,-0.1612019,-0.19065213,0.12821446,0.97324859},{0.9885997,-0.087317452,-0.12266319,0.083317465,0.9958218,-0.03737855,0.12541452,0.026732474,0.99174422},{0.99920109,-0.032152256,-0.023735492,0.027844945,0.98613064,-0.16361836,0.028667035,0.1628268,0.98623817},{0.99528977,-0.089595941,-0.03702425,0.084123481,0.98800651,-0.12948484,0.048181559,0.12576033,0.99088999},{0.99876606,-0.033746704,-0.036434082,0.028087231,0.98888715,-0.14599073,0.040955955,0.1447873,0.98861485},{0.99949817,0.012901015,0.028930579,-0.008168591,0.98738958,-0.15809833,-0.030605376,0.15778268,0.98699946},{0.99971899,0.021896787,0.0090809641,-0.019950636,0.98408719,-0.17656268,-0.012802611,0.1763319,0.98424751},{0.99755243,0.067978848,-0.016371025,-0.069306052,0.99229499,-0.1027002,0.0092634507,0.10358346,0.99457763},{0.86368819,0.46646958,-0.19091528,-0.49684649,0.85165203,-0.16683083,0.08477195,0.2389455,0.9673256},{0.88887263,0.17928957,-0.42161677,-0.30037529,0.9229253,-0.24079773,0.34594845,0.34068183,0.87421714},{0.89849372,-0.033715555,-0.43768976,-0.21966718,0.82870823,-0.5147708,0.38007301,0.55866449,0.7371828},{0.85628571,0.10816747,-0.50504906,-0.40503584,0.74738712,-0.52664828,0.32050112,0.65552448,0.68378854},{0.94591889,-0.30420075,0.11269098,0.32145662,0.92566893,-0.19950611,-0.043624761,0.22494205,0.97339511},{0.84216768,-0.10751053,0.52838909,0.10205704,0.99399069,0.039583314,-0.52946966,0.020590187,0.84807901},{0.73914587,0.00702682,0.67350873,-0.015868057,0.99984972,0.0069829778,-0.67335861,-0.015848648,0.73914611},{0.72734503,-0.057403518,0.68386694,0.17607649,0.97874816,-0.10511504,-0.66329968,0.19686785,0.72199485},{0.99972872,0.010268077,0.020905915,-0.0081375336,0.99499809,-0.09956196,-0.021823653,0.099364842,0.99481172},{0.99787264,0.029810522,0.05797858,-0.026046395,0.99756936,-0.064629394,-0.059764291,0.062981795,0.99622364},{0.9978726,0.029811689,0.057978783,-0.026047415,0.9975692,-0.06463149,-0.059764615,0.062983814,0.99622348}},{{0.9993953,-0.033484908,0.0093690968,0.034391835,0.99161932,-0.12453245,-0.0051206363,0.12477938,0.9921713},{0.99004403,0.040948977,0.13466977,-0.093696383,0.90570471,0.4134247,-0.10504178,-0.42192671,0.90052435},{0.97966729,0.092821851,0.17786539,-0.13716252,0.95686273,0.25612525,-0.14641877,-0.275314,0.95013882},{0.95185799,0.25191952,0.1746506,-0.26727979,0.96103865,0.070471556,-0.15009285,-0.11375941,0.98210539},{0.96402848,0.20043912,0.17456558,-0.21450649,0.97451405,0.065645932,-0.15695864,-0.10072994,0.98245484},{0.98528157,-0.055712778,-0.16160494,0.044835664,0.99652547,-0.070191496,0.16495407,0.061912696,0.98435616},{0.99739561,-0.030647089,-0.065288942,0.015835962,0.97619623,-0.21631057,0.070364119,0.21471324,0.97413917},{0.9956212,-0.08314864,-0.042715523,0.076109266,0.98634906,-0.1460239,0.054274213,0.14213339,0.98835847},{0.99876323,-0.027430514,-0.041466149,0.020469877,0.98693282,-0.15982673,0.04530854,0.15878028,0.98627385},{0.99911823,0.026280932,0.032742514,-0.020927191,0.98780459,-0.15428596,-0.036397972,0.15346469,0.98748356},{0.99841205,0.052046351,0.021553599,-0.047632878,0.98424982,-0.17024516,-0.030074752,0.16894814,0.98516599},{0.99437216,0.10588201,0.0036052555,-0.10510002,0.9901703,-0.092286288,-0.013341263,0.091387984,0.99572599},{0.85371481,0.49711711,-0.15506619,-0.51813199,0.84067272,-0.15750763,0.05206037,0.21481144,0.97526704},{0.91390607,0.19831535,-0.35418458,-0.30665711,0.90899061,-0.28230744,0.26596477,0.36661576,0.89154676},{0.92734157,0.015679694,-0.37388746,-0.23735875,0.79706784,-0.55528699,0.28930717,0.60368617,0.74287573},{0.87433662,0.18217651,-0.44983017,-0.42863299,0.72457434,-0.53969045,0.2276167,0.66468324,0.71160864},{0.95312325,-0.26906149,0.13842685,0.29253625,0.9362997,-0.19433314,-0.077321506,0.22571837,0.97111927},{0.81153946,-0.081951283,0.57852197,0.054639853,0.99642059,0.06450161,-0.58173729,-0.020735201,0.81311243},{0.67382632,0.01868135,0.73865357,-0.079538607,0.99570535,0.047375564,-0.73459636,-0.090674353,0.67241829},{0.66005694,-0.028053795,0.75069154,0.13139261,0.9882096,-0.078598901,-0.73963566,0.15051509,0.65596061},{0.9989281,0.018043724,0.042627241,-0.014114856,0.99577502,-0.090735204,-0.044084331,0.090036236,0.99496233},{0.99675123,0.042228873,0.068583612,-0.038750479,0.99793224,-0.051280357,-0.070607296,0.048456083,0.99632655},{0.99675117,0.042229985,0.068583796,-0.038751443,0.99793209,-0.051282337,-0.070607608,0.048457959,0.99632644}},{{0.99820607,-0.059723123,0.0042171938,0.059756831,0.98945087,-0.13197,0.0037089499,0.13198525,0.99124475},{0.99398781,0.053066057,0.095771736,-0.094945054,0.85338977,0.51255371,-0.05453142,-0.5185652,0.85329742},{0.98625594,0.053876427,0.15619391,-0.11371017,0.90718084,0.40508383,-0.11987167,-0.41727717,0.90083881},{0.9632046,0.21672814,0.1589522,-0.25662498,0.91737302,0.30425377,-0.079878101,-0.33384972,0.93923578},{0.9723646,0.1666009,0.16355799,-0.21088531,0.92734219,0.309134,-0.10017222,-0.33508297,0.93684842},{0.97923619,-0.023496172,-0.20135621,0.0034811298,0.99506309,-0.099183638,0.20269259,0.096423218,0.97448361},{0.989658,-0.025883208,-0.14109227,-0.012931463,0.9634839,-0.267454,0.14286272,0.26651248,0.95318484},{0.99573706,-0.077298846,-0.050324393,0.067986951,0.98379547,-0.16590451,0.06233318,0.16177582,0.98485692},{0.99856878,-0.021598776,-0.048926646,0.012893887,0.98506503,-0.17169927,0.05190446,0.17082268,0.98393374},{0.99855111,0.047261492,0.025730101,-0.042961586,0.98810158,-0.14768064,-0.032403549,0.14636124,0.98870036},{0.99606968,0.085104243,0.024544867,-0.080067173,0.98364611,-0.16133688,-0.037873903,0.15873752,0.98659412},{0.98955868,0.14323851,0.016010529,-0.14155629,0.98677055,-0.079029786,-0.02711881,0.075938199,0.99674368},{0.84516452,0.51998248,-0.12375454,-0.53380081,0.83300567,-0.14545857,0.027452335,0.18899679,0.98159392},{0.93183625,0.21535873,-0.29206474,-0.30639599,0.898178,-0.31527406,0.19442917,0.38327135,0.90293987},{0.9476288,0.06153075,-0.31339058,-0.24639989,0.76515392,-0.59483322,0.20319155,0.64090053,0.74024299},{0.88650426,0.24687203,-0.39136224,-0.44296452,0.69727682,-0.56354898,0.13376339,0.67294821,0.72749438},{0.95546087,-0.24336962,0.16693036,0.27264434,0.94442458,-0.18364979,-0.11295847,0.22098291,0.96871409},{0.77391475,-0.058101915,0.6306188,-0.0023695938,0.99550976,0.094629164,-0.63328546,-0.074729161,0.77030199},{0.60904001,0.040758416,0.79209153,-0.15260133,0.98604139,0.066596903,-0.7783208,-0.16143435,0.60675842},{0.59949616,0.0035504575,0.80036971,0.055648052,0.99738532,-0.046106102,-0.79844087,0.072179479,0.59773107},{0.99811764,0.023425076,0.056678448,-0.018864489,0.99664018,-0.079702513,-0.058355049,0.078483263,0.99520604},{0.99567832,0.049810485,0.078381094,-0.047472826,0.9983785,-0.031411569,-0.079818617,0.027554863,0.99642848},{0.99567826,0.04981155,0.078381259,-0.047473734,0.9983784,-0.031413572,-0.0798189,0.027556719,0.9964284}},{{0.99672032,-0.080310377,0.0099423433,0.080899782,0.98590727,-0.14643121,0.0019577176,0.1467553,0.98917088},{0.99482891,0.07132007,0.072311092,-0.10071748,0.78453442,0.61185111,-0.013093272,-0.61597013,0.78766065},{0.9913687,0.029233612,0.12780266,-0.086086776,0.88037476,0.46640041,-0.098879651,-0.47337688,0.87529259},{0.97556949,0.1715068,0.13729383,-0.21706235,0.84887474,0.48197056,-0.033883999,-0.49999711,0.86536393},{0.98200365,0.12231728,0.14390042,-0.17755567,0.85759455,0.48270656,-0.064364834,-0.49956988,0.86387906},{0.97304729,-0.0018836378,-0.23059766,-0.030462927,0.99015352,-0.13663124,0.22858448,0.13997332,0.96340888},{0.98011383,-0.015956871,-0.19779319,-0.048183873,0.94779301,-0.31522499,0.192497,0.3184868,0.92817623},{0.99568244,-0.074061267,-0.055958608,0.062967135,0.98182207,-0.1790547,0.068202445,0.17475804,0.98224645},{0.99833693,-0.01903249,-0.05441576,0.009434914,0.98514479,-0.17146643,0.056870878,0.17066785,0.98368605},{0.99719281,0.074134068,0.010518451,-0.071907687,0.98732242,-0.14150523,-0.020875483,0.14035162,0.98988163},{0.9933904,0.11245654,0.023000907,-0.107656,0.98231581,-0.15318565,-0.039820902,0.14969695,0.98792971},{0.98514704,0.16968067,0.026339588,-0.16759814,0.9835395,-0.067534597,-0.03736536,0.062117031,0.99736919},{0.84087667,0.53383011,-0.089173516,-0.54122654,0.82953406,-0.13764801,0.00049176645,0.16400807,0.98645888},{0.94359908,0.2327509,-0.23547347,-0.30378533,0.8914516,-0.33619717,0.13166303,0.38876875,0.91187923},{0.96079252,0.10087805,-0.25826596,-0.24709922,0.73406578,-0.63252626,0.12577621,0.67154379,0.7302118},{0.88891323,0.29809902,-0.34780776,-0.45493983,0.66320149,-0.59430089,0.053506157,0.68651351,0.72514569},{0.95350452,-0.22902652,0.19589786,0.26366743,0.94876237,-0.17415362,-0.14597475,0.21770813,0.96503603},{0.73343747,-0.041490232,0.67848952,-0.054936652,0.9912525,0.12000168,-0.6775334,-0.12528777,0.72474239},{0.5515415,0.064032498,0.83168613,-0.21706388,0.97371703,0.068980595,-0.80541002,-0.21857466,0.55094456},{0.55085097,0.041846459,0.83355388,-0.024832226,0.99912176,-0.033748105,-0.83423417,-0.0021087924,0.55140643},{0.99730769,0.027665365,0.06791162,-0.02289312,0.99727929,-0.070070795,-0.069665399,0.068327425,0.99522766},{0.99462098,0.05317794,0.08888872,-0.052247334,0.99855259,-0.012765224,-0.089438902,0.0080523568,0.99595976},{0.99462091,0.053178942,0.088888888,-0.052248186,0.99855252,-0.012766997,-0.089439173,0.0080540387,0.99595972}},{{0.99674809,-0.080411932,-0.0052123445,0.078825413,0.98642155,-0.14408014,0.01672736,0.14320075,0.98955228},{0.99342202,0.084125818,0.077688922,-0.11432177,0.76757986,0.6306756,-0.0065763334,-0.63540854,0.7721481},{0.99233189,0.046744196,0.11442204,-0.095794,0.87585472,0.4729715,-0.078108394,-0.48030564,0.87361636},{0.97633766,0.18118724,0.11805072,-0.21582177,0.85080695,0.47911222,-0.013629326,-0.49325326,0.86977896},{0.98339429,0.13085226,0.12575127,-0.17579383,0.85894436,0.48094815,-0.045080171,-0.49506794,0.86768397},{0.96835881,0.0069090564,-0.24946606,-0.054902842,0.98102459,-0.18594761,0.24344766,0.19376033,0.95036321},{0.97295352,-0.00090777717,-0.2309989,-0.083981926,0.93017492,-0.35738193,0.21519383,0.36711564,0.9049407},{0.99544605,-0.075802478,-0.05780185,0.061961781,0.9753129,-0.21195664,0.072441817,0.20740985,0.97556819},{0.99819677,-0.022303857,-0.055728427,0.011817469,0.98325528,-0.18185,0.058851298,0.18086346,0.98174589},{0.99535665,0.09615668,0.004364167,-0.094645,0.9859544,-0.13760901,-0.017534858,0.13655694,0.99047702},{0.99098682,0.13046182,0.030411428,-0.12452692,0.9808358,-0.14984717,-0.049377912,0.14470948,0.98824135},{0.98213969,0.18229955,0.046567407,-0.17900797,0.98155465,-0.067131237,-0.057946407,0.057596317,0.99665685},{0.83753948,0.54364611,-0.054557916,-0.54547066,0.8262228,-0.14077512,-0.031454736,0.14766447,0.98853719},{0.95009326,0.24831008,-0.18885158,-0.30099295,0.8887718,-0.3456704,0.082012668,0.38526209,0.91915555},{0.96864429,0.13099922,-0.21111017,-0.2404117,0.7086138,-0.66337677,0.062693917,0.69332943,0.71788835},{0.88818663,0.3235046,-0.32629639,-0.45948205,0.62668271,-0.62940057,0.00087051382,0.70895245,0.70525568},{0.95350502,-0.2034848,0.22231093,0.24462688,0.9534087,-0.17654909,-0.17602799,0.22272356,0.9588578},{0.70685729,-0.027624915,0.70681656,-0.089450842,0.98772433,0.12805969,-0.7016774,-0.15374525,0.69570909},{0.52181385,0.090244617,0.84827248,-0.25622628,0.9650538,0.054948668,-0.81366962,-0.2460227,0.52670153},{0.51893888,0.074293096,0.85157677,-0.091130986,0.99534688,-0.031302005,-0.84993967,-0.061361207,0.52329461},{0.9957684,0.033607384,0.085532835,-0.027796785,0.99728156,-0.068240897,-0.087593669,0.065574551,0.99399563},{0.99317787,0.05781419,0.10126822,-0.058023526,0.99831485,-0.00087946469,-0.10114837,-0.005002568,0.99485874},{0.9931778,0.057815152,0.10126837,-0.058024313,0.99831478,-0.0008812029,-0.10114862,-0.0050008538,0.99485875}},{{0.99664196,-0.073353858,-0.036387061,0.06863573,0.99072237,-0.11729583,0.044653567,0.11440448,0.99243019},{0.99014092,0.11205538,0.084050874,-0.1400739,0.78992553,0.5969899,0.0005019884,-0.60287749,0.79783364},{0.99375998,0.081705098,0.075929963,-0.10702344,0.89022214,0.44277592,-0.031417504,-0.44813932,0.89341151},{0.98188598,0.1764255,0.069093878,-0.18918687,0.93291628,0.30639115,-0.010403609,-0.31391288,0.94939479},{0.98899354,0.1254593,0.07843309,-0.14457007,0.93219679,0.33182618,-0.031484408,-0.33951304,0.94007427},{0.96528385,0.00044938466,-0.26120263,-0.068272319,0.96566965,-0.25064131,0.25212283,0.25977289,0.93217603},{0.97168415,0.019362501,-0.23548871,-0.1144091,0.91056822,-0.39721036,0.20673754,0.41290509,0.88700003},{0.99502263,-0.078119788,-0.061864584,0.056436676,0.9534435,-0.2962437,0.082126904,0.29127775,0.95310679},{0.99790542,-0.027489458,-0.058557998,0.013886914,0.97514748,-0.22112113,0.06318124,0.21984478,0.97348676},{0.99325906,0.11541048,0.010810723,-0.1131039,0.98535868,-0.12757649,-0.025376102,0.12549375,0.99176982},{0.98815126,0.14628562,0.046450258,-0.13836122,0.98001185,-0.14294382,-0.066432426,0.13482317,0.9886402},{0.97892855,0.19003035,0.074748843,-0.18517891,0.98039937,-0.06727425,-0.086067865,0.052014757,0.99493055},{0.83212359,0.55377328,-0.030090987,-0.55200147,0.82178285,-0.14130576,-0.053523021,0.13419424,0.98950857},{0.95201835,0.25713994,-0.16595213,-0.30023175,0.88986669,-0.34350864,0.059345676,0.37685072,0.92437092},{0.97146579,0.14662187,-0.18643017,-0.23506538,0.69991319,-0.6744375,0.031597849,0.69901618,0.71440734},{0.89657048,0.3006199,-0.32525237,-0.44285515,0.59791576,-0.66811382,-0.006374558,0.74305085,0.66920456},{0.95412517,-0.16874623,0.24732538,0.21600199,0.95997288,-0.17831208,-0.20733619,0.22355487,0.95238383},{0.70007841,-0.012388034,0.71395842,-0.10273006,0.9877009,0.11787056,-0.70663768,-0.15586372,0.69019548},{0.52175902,0.11855072,0.84481546,-0.26821595,0.96287488,0.030532742,-0.80983194,-0.24252369,0.53418584},{0.50834366,0.099051362,0.85543875,-0.13783924,0.98991431,-0.032711493,-0.85005125,-0.10128431,0.51686982},{0.99312092,0.045808926,0.10776079,-0.038852356,0.99707663,-0.065792657,-0.11045967,0.061153283,0.99199745},{0.99174418,0.063748245,0.11126386,-0.065218727,0.99782458,0.0096238031,-0.11040831,-0.016800851,0.9937443},{0.99174411,0.063749163,0.11126398,-0.065219446,0.99782455,0.0096220109,-0.11040853,-0.016799161,0.99374431}},{{0.9961369,-0.063771435,-0.060369369,0.057468954,0.99323256,-0.10092769,0.066397124,0.097068406,0.9930605},{0.98602146,0.14372384,0.084291795,-0.16635082,0.82051386,0.54688608,0.0094379801,-0.55326343,0.83295291},{0.99347617,0.10762367,0.037713007,-0.11372175,0.9102734,0.39808253,0.0085139993,-0.39977431,0.91657405},{0.99198557,0.1229639,0.029060691,-0.1250526,0.98836029,0.086635769,-0.018069339,-0.089575507,0.99581612},{0.99668684,0.072397943,0.037065653,-0.076768987,0.98791169,0.13467372,-0.026867495,-0.13707307,0.99019652},{0.9612437,-0.013724494,-0.27535805,-0.080732487,0.94096769,-0.32872794,0.26361476,0.33821805,0.90339136},{0.97409156,0.043648796,-0.22190164,-0.13568608,0.89777607,-0.41903148,0.18092781,0.43828403,0.88043872},{0.99313445,-0.083983166,-0.081429291,0.040098176,0.89834021,-0.43746652,0.10989109,0.43119792,0.89554029},{0.99614637,-0.044230567,-0.075736229,0.023847406,0.96758513,-0.25141658,0.08440163,0.24864167,0.9649113},{0.99158924,0.12808747,0.01855787,-0.12529242,0.98595332,-0.11044384,-0.032443681,0.10718978,0.99370909},{0.98634635,0.15355682,0.05950792,-0.1451766,0.98134911,-0.1260066,-0.077747239,0.11564701,0.99024297},{0.97701061,0.19021378,0.096275624,-0.18579128,0.98115513,-0.05306774,-0.10455556,0.033960566,0.99393904},{0.83240242,0.55399057,-0.01416473,-0.55107734,0.82478685,-0.12665081,-0.058480532,0.1132303,0.99184623},{0.95258944,0.25451051,-0.16672647,-0.29674716,0.89817296,-0.32438631,0.067189418,0.35848253,0.93111539},{0.97231229,0.14261971,-0.18511715,-0.23036748,0.71799431,-0.65682192,0.039237263,0.68128096,0.73096971},{0.90727368,0.24889744,-0.33897569,-0.41969795,0.58689797,-0.69239037,0.026609904,0.77045493,0.63693886},{0.95412701,-0.14841741,0.26002672,0.19504592,0.96703125,-0.16373041,-0.22715357,0.20693677,0.95161886},{0.70592251,-0.0085919346,0.70823688,-0.095300642,0.98968167,0.10699534,-0.70184842,-0.14302595,0.69781978},{0.54476955,0.14561499,0.82584643,-0.25943722,0.96575962,0.0008528776,-0.79744497,-0.21471989,0.56389444},{0.51420778,0.10879155,0.85073773,-0.15976752,0.98671044,-0.029612082,-0.84265338,-0.12069345,0.52475558},{0.99035794,0.062312957,0.12372646,-0.056031869,0.99698837,-0.053615294,-0.1266948,0.046165726,0.99086688},{0.99134839,0.066973685,0.11288441,-0.069204733,0.99747481,0.015958753,-0.11153057,-0.023632787,0.99347997},{0.99134833,0.066974541,0.1128845,-0.069205392,0.9974748,0.015956951,-0.11153076,-0.0236311,0.99347998}},{{0.99487975,-0.059862774,-0.08142937,0.05148142,0.99351319,-0.1013962,0.086971018,0.096684915,0.99150798},{0.98427264,0.15140303,0.091019175,-0.17659984,0.83030099,0.52859511,0.00445759,-0.53635566,0.84398028},{0.99168657,0.12511683,0.030058646,-0.12833539,0.94468283,0.30183501,0.0093687542,-0.30318338,0.95288618},{0.99431255,0.10409531,0.022510114,-0.10108402,0.98896656,-0.1082928,-0.03353457,0.10540141,0.99386409},{0.99835479,0.049154155,0.029522299,-0.046982977,0.99642513,-0.070210971,-0.032867935,0.068708319,0.99709521},{0.95953999,-0.01180916,-0.28132437,-0.09017821,0.93360543,-0.34676917,0.26674106,0.35810821,0.8947669},{0.98237829,0.045879171,-0.18118474,-0.13156546,0.85829251,-0.49600861,0.13275299,0.51110576,0.84920409},{0.98481283,-0.12518211,-0.12030398,0.022820406,0.78023808,-0.62506623,0.17211288,0.61282784,0.77124526},{0.98969901,-0.067975842,-0.12599616,0.019212967,0.9351903,-0.35362409,0.14186836,0.34756063,0.92686303},{0.99068546,0.13429356,0.02252914,-0.13119719,0.98565462,-0.10617098,-0.036464,0.10222625,0.99409263},{0.98687767,0.14876699,0.062776216,-0.14077877,0.98313725,-0.11671548,-0.079081013,0.10634631,0.99117942},{0.97928171,0.1754989,0.10103206,-0.17218724,0.98422373,-0.040684068,-0.10657813,0.022444701,0.99405097},{0.84354914,0.53684325,-0.014967752,-0.5349895,0.83754287,-0.11094286,-0.047022546,0.1015936,0.99371405},{0.9537034,0.23903483,-0.18251656,-0.28544117,0.91056868,-0.29897839,0.094727958,0.33723449,0.93664259},{0.97298614,0.11791922,-0.198477,-0.21811088,0.75130469,-0.62287156,0.075668481,0.64933536,0.75672829},{0.90856926,0.2165345,-0.35723207,-0.41186738,0.60716779,-0.67949435,0.069766217,0.76449995,0.6408373},{0.95375675,-0.14628747,0.26257964,0.18910278,0.97106151,-0.14587558,-0.23364117,0.18878431,0.95381982},{0.72510021,-0.020640075,0.68833398,-0.060370037,0.99379726,0.093394084,-0.6859921,-0.10927494,0.71935656},{0.5881142,0.16287048,0.79220887,-0.22296984,0.97420539,-0.034760501,-0.77743562,-0.15619554,0.60925925},{0.53200632,0.097723257,0.84108231,-0.14425446,0.9892569,-0.023694635,-0.83436198,-0.10872418,0.54038795},{0.98888142,0.078117834,0.12653519,-0.073538165,0.99647069,-0.04047589,-0.12925046,0.030720653,0.99113599},{0.99236233,0.064579571,0.10510233,-0.066140842,0.99774479,0.011433946,-0.10412688,-0.018298197,0.99439567},{0.99236227,0.06458035,0.1051024,-0.066141441,0.99774477,0.011432164,-0.10412705,-0.018296476,0.99439569}},{{0.99108632,-0.087237059,-0.10068555,0.074428324,0.98940812,-0.12462743,0.11049125,0.11602266,0.98708178},{0.98412649,0.14362984,0.10423776,-0.17731236,0.82040535,0.54359487,-0.0074407791,-0.55344876,0.83284999},{0.98951954,0.14112605,0.030569972,-0.14419225,0.97703164,0.15690055,-0.0077250631,-0.15966419,0.98714115},{0.99432484,0.10354165,0.024438367,-0.099100616,0.98500667,-0.14121261,-0.038693364,0.13798932,0.98967758},{0.99849328,0.045021033,0.03137277,-0.040785738,0.99137138,-0.12457675,-0.036710661,0.12310931,0.99171387},{0.96088172,0.00091266236,-0.27695728,-0.090801637,0.94576199,-0.3119125,0.26165105,0.32485913,0.90884836},{0.99069372,0.019303177,-0.13473406,-0.098343767,0.78586608,-0.61052685,0.094097821,0.61809538,0.78045099},{0.96619419,-0.21376386,-0.14413097,-0.0045146622,0.54493342,-0.83846719,0.25777576,0.81077275,0.5255466},{0.97397126,-0.14483848,-0.17436068,-0.0024488898,0.76245453,-0.64703721,0.22665804,0.63062263,0.74225421},{0.99054569,0.13473828,0.025784643,-0.13067898,0.98395278,-0.12149043,-0.041740259,0.11697225,0.99225765},{0.98766446,0.14462783,0.060014319,-0.13619112,0.98256573,-0.12655658,-0.077271596,0.11682196,0.99014227},{0.98205335,0.16345642,0.094091567,-0.16005117,0.98618399,-0.042716937,-0.099773932,0.026890786,0.9946467},{0.85647651,0.51456658,-0.040855495,-0.51590663,0.85072378,-0.1005459,-0.01698079,0.10719274,0.99409323},{0.95106995,0.21807643,-0.21888036,-0.27351235,0.92375056,-0.2680969,0.14372518,0.3148453,0.93819799},{0.96907832,0.081125683,-0.23303601,-0.20484491,0.7910251,-0.57647017,0.13757078,0.60638094,0.78318355},{0.90580836,0.19634499,-0.3754462,-0.40453914,0.6641868,-0.62865254,0.12593359,0.72132135,0.68105522},{0.9519802,-0.1525016,0.26547498,0.19355181,0.97162979,-0.13591633,-0.23721595,0.18077281,0.95448928},{0.75367813,-0.035652261,0.65627596,-0.0099777304,0.99779192,0.065663696,-0.65716801,-0.056037499,0.75165821},{0.63841848,0.17160654,0.75031527,-0.16862973,0.98233003,-0.081189785,-0.75098994,-0.074692385,0.65607557},{0.55931318,0.091601062,0.82387983,-0.10496465,0.99370213,-0.039224218,-0.82228416,-0.064539633,0.56540551},{0.98859114,0.090175588,0.12064792,-0.086648248,0.99565242,-0.034180759,-0.12320566,0.02333681,0.99210673},{0.99384086,0.058499235,0.094117918,-0.059116724,0.99824391,0.0037838898,-0.093731274,-0.00932454,0.99555386},{0.99384082,0.058499916,0.094117993,-0.059117262,0.99824388,0.0037822153,-0.093731443,-0.0093229556,0.99555387}},{{0.98661907,-0.10531759,-0.12446303,0.085959158,0.98466606,-0.1518017,0.13854192,0.13907171,0.98054332},{0.9846613,0.13317732,0.11272063,-0.17305476,0.82777858,0.53369907,-0.022231084,-0.5450196,0.8381285},{0.98814413,0.15095489,0.027997184,-0.15212243,0.98730255,0.045743612,-0.020736386,-0.049460333,0.99856077},{0.99424249,0.10419125,0.025021448,-0.09959656,0.98471375,-0.1428967,-0.039527538,0.1395819,0.98942122},{0.99846376,0.04553921,0.031564394,-0.041035467,0.99052997,-0.13102093,-0.037232051,0.12952436,0.99087698},{0.96167512,0.021112958,-0.27337722,-0.096806352,0.95896664,-0.26647999,0.25653346,0.28273183,0.92425826},{0.98476465,-0.0024626902,-0.17387479,-0.12212067,0.70203778,-0.70159074,0.12379439,0.71213548,0.69104125},{0.94181533,-0.28791114,-0.1734675,-0.082590834,0.30203426,-0.94971269,0.32582595,0.90878074,0.26068174},{0.95475072,-0.21794967,-0.20235831,-0.093233435,0.42677226,-0.89954045,0.28241544,0.87770347,0.38714107},{0.99152421,0.1281725,0.021249846,-0.12400004,0.98240301,-0.13967224,-0.03877803,0.13585338,0.98996975},{0.98942498,0.13624851,0.049744839,-0.1280512,0.98160375,-0.14162267,-0.06812557,0.13375507,0.98867005},{0.98592538,0.14715585,0.079349285,-0.14349514,0.98838481,-0.05004602,-0.085792163,0.037955385,0.99558982},{0.86942786,0.48787571,-0.077926138,-0.49360634,0.86451392,-0.094701996,0.021165441,0.12080135,0.99245103},{0.94564038,0.19004355,-0.26390849,-0.25254045,0.94041143,-0.22770542,0.20490868,0.28197495,0.93728464},{0.95995916,0.039366705,-0.27736013,-0.18294554,0.83789494,-0.51425968,0.21215406,0.54441003,0.8115469},{0.90735583,0.16860602,-0.38506804,-0.37685807,0.73210503,-0.56745067,0.18623478,0.65999561,0.72782029},{0.94828849,-0.17597211,0.26416415,0.21548031,0.96798982,-0.12870102,-0.23306047,0.17896793,0.95585215},{0.78005143,-0.059356514,0.62289362,0.044420678,0.99823193,0.039494921,-0.62413672,-0.0031386477,0.78130889},{0.68537477,0.16782701,0.70858693,-0.10834312,0.98575033,-0.12867851,-0.72008564,0.011422542,0.69379117},{0.58832001,0.084089027,0.80424403,-0.051137957,0.9964566,-0.066777698,-0.80700967,-0.0018407033,0.59053538},{0.98945739,0.096148126,0.10830339,-0.092979749,0.99508916,-0.033946013,-0.11103535,0.023518086,0.99353814},{0.99464239,0.056641608,0.086476831,-0.057132014,0.9983615,0.0032045348,-0.086153602,-0.0081279972,0.9962487},{0.99464235,0.056642216,0.086476903,-0.057132475,0.99836147,0.0032028962,-0.086153757,-0.0081263637,0.99624871}},{{0.98794645,-0.09261619,-0.12403241,0.073072893,0.98540154,-0.1537666,0.136463,0.14284976,0.98029168},{0.98538778,0.12466797,0.11605518,-0.16624592,0.85220821,0.49608818,-0.037056872,-0.50813292,0.8604811},{0.98847151,0.14994193,0.021011622,-0.1491444,0.98818018,-0.035438028,-0.026076895,0.031895776,0.99915098},{0.99443877,0.10274016,0.023151565,-0.09839054,0.98471876,-0.14369479,-0.037561003,0.14061779,0.98935124},{0.99855794,0.045461464,0.028553151,-0.041483723,0.99102097,-0.12710838,-0.034075328,0.12574056,0.99147778},{0.96539704,0.049386428,-0.25606506,-0.09781208,0.97879407,-0.17998636,0.24174614,0.19880455,0.94975558},{0.9682111,-0.0021477574,-0.25012484,-0.18938066,0.64696231,-0.73863044,0.1634077,0.762519,0.62598938},{0.92402639,-0.29217216,-0.24659765,-0.17282697,0.2561308,-0.9510668,0.3410365,0.92142959,0.18617644},{0.93767206,-0.21461879,-0.27333059,-0.18514299,0.35709893,-0.91553412,0.29409691,0.90907598,0.29510653},{0.99367267,0.11221971,0.0046224039,-0.11044822,0.98380242,-0.14118777,-0.020391589,0.13978386,0.98997205},{0.99264373,0.11837096,0.025431115,-0.11351032,0.9829544,-0.14462382,-0.042116893,0.1406732,0.98915985},{0.99141877,0.12168531,0.047765149,-0.11916538,0.99148667,-0.052476587,-0.053744143,0.046334319,0.99747917},{0.87817564,0.4628157,-0.12086809,-0.47438783,0.87506861,-0.095974846,0.061349251,0.14162115,0.98801808},{0.93831509,0.16284739,-0.30503355,-0.22456354,0.95779454,-0.17944615,0.26293718,0.23687637,0.93528262},{0.94627451,0.0071695894,-0.32328478,-0.15537999,0.88685464,-0.43513907,0.28358686,0.46199296,0.84032196},{0.90543257,0.13766923,-0.40154579,-0.34358866,0.79317819,-0.50280733,0.24927633,0.5932247,0.76547095},{0.94496211,-0.22173617,0.24058193,0.25642232,0.95862316,-0.1236498,-0.20320977,0.17853489,0.96272066},{0.80268829,-0.090370327,0.58951226,0.093751562,0.99528368,0.024920354,-0.58898403,0.035264406,0.80737491},{0.73285087,0.1627302,0.66064248,-0.053942235,0.98181713,-0.1820041,-0.67824761,0.097745356,0.72830343},{0.6186232,0.077498886,0.78185628,0.005863022,0.99464037,-0.10322929,-0.78566592,0.068444065,0.61485311},{0.99254175,0.092068446,0.07990166,-0.0894619,0.99535316,-0.035618009,-0.082809663,0.028204182,0.99616619},{0.99505729,0.060850244,0.078474511,-0.061812468,0.99803879,0.0098892471,-0.077718847,-0.014691104,0.99686706},{0.99505725,0.060850764,0.078474562,-0.061812872,0.99803878,0.0098877452,-0.077718989,-0.014689641,0.99686708}},{{0.99094293,-0.083608322,-0.10507969,0.068025406,0.98723626,-0.14400393,0.11577841,0.13555159,0.98398228},{0.98571477,0.12172213,0.11640504,-0.16069996,0.88661822,0.43368616,-0.050417615,-0.4461971,0.89351338},{0.99009561,0.13961839,0.014744452,-0.13772993,0.98629624,-0.090830838,-0.027224008,0.087900414,0.99575716},{0.9946922,0.10075575,0.020873975,-0.096698354,0.98468757,-0.14505139,-0.035169097,0.14226297,0.98920387},{0.99869312,0.044443678,0.025235501,-0.040955211,0.9913056,-0.12504347,-0.03057347,0.12384654,0.99183027},{0.97119941,0.056991013,-0.23135165,-0.074699943,0.99484958,-0.06851479,0.22625545,0.083823471,0.97045463},{0.9622962,-0.01236752,-0.27172218,-0.19773621,0.65416049,-0.73005106,0.18677879,0.75625468,0.62705068},{0.92457275,-0.26521303,-0.27354546,-0.17880367,0.3319562,-0.92619352,0.33644373,0.90524426,0.25949662},{0.93720523,-0.18427866,-0.29612089,-0.19394628,0.43029704,-0.88160614,0.28988117,0.88367745,0.36753657},{0.9960811,0.087462177,-0.013145927,-0.088438241,0.98672926,-0.13617653,0.0010612061,0.13680546,0.99059736},{0.99572092,0.092200169,-0.0062430947,-0.09214219,0.98540107,-0.14315918,-0.0070473178,0.14312184,0.98967998},{0.99580365,0.091480547,0.0025303233,-0.091200893,0.99429133,-0.055381979,-0.0075822201,0.054918844,0.99846203},{0.88426364,0.43343645,-0.17381165,-0.4541165,0.88489429,-0.10363602,0.1088854,0.17057239,0.97931051},{0.92448133,0.14728839,-0.35162542,-0.20282479,0.97100634,-0.12652577,0.32279486,0.18828905,0.92755091},{0.92374509,-0.0093714806,-0.38289323,-0.13219996,0.9304605,-0.34171107,0.3594694,0.36627244,0.8582693},{0.88980408,0.10323129,-0.44451325,-0.31197698,0.84850395,-0.4274475,0.33304542,0.51902245,0.78720802},{0.94291271,-0.26992543,0.19507904,0.29678153,0.94680504,-0.12442256,-0.15111699,0.17521549,0.9728634},{0.83732471,-0.11647178,0.53415498,0.13153582,0.99126151,0.009951542,-0.53064645,0.061927802,0.84532794},{0.79416876,0.15173656,0.58844868,-0.009632961,0.9713472,-0.23746983,-0.60762091,0.18292263,0.77287527},{0.668078,0.07851137,0.73993759,0.055807367,0.98633026,-0.15504267,-0.74199552,0.14487462,0.654564},{0.99616153,0.079311459,0.037039315,-0.077846645,0.9961847,-0.039445556,-0.040026455,0.036410775,0.99853499},{0.99562843,0.067164044,0.064907818,-0.067983972,0.99763111,0.010504587,-0.064048502,-0.014871357,0.99783597},{0.9956284,0.067164491,0.064907853,-0.067984319,0.9976311,0.010503074,-0.064048622,-0.014869893,0.99783599}},{{0.99304577,-0.088167353,-0.078016902,0.077402643,0.98827298,-0.13162577,0.088707098,0.12467172,0.98822467},{0.98563274,0.12286151,0.11590131,-0.15664825,0.9215507,0.35525434,-0.063161884,-0.36830602,0.92755662},{0.99238011,0.12275255,0.010655913,-0.12041518,0.9845316,-0.12727032,-0.026113806,0.12501738,0.99181081},{0.99492274,0.09882545,0.019033217,-0.095003725,0.98464844,-0.14643021,-0.033212079,0.14387852,0.98903785},{0.99883131,0.042778832,0.022493705,-0.039625442,0.99128036,-0.12567062,-0.02767363,0.12463235,0.99181699},{0.97649697,0.040140523,-0.21175988,-0.030626891,0.99837683,0.04801841,0.21334371,-0.040404326,0.9761414},{0.97290546,-0.042912952,-0.22718565,-0.13019589,0.71032623,-0.69172665,0.19105992,0.70256328,0.68549323},{0.93984471,-0.25474562,-0.22758823,-0.094073647,0.44746238,-0.88934116,0.32839298,0.85725268,0.39658033},{0.95266791,-0.18247305,-0.24316091,-0.11728499,0.51732343,-0.84771508,0.28047804,0.83611007,0.47143617},{0.99797293,0.05928938,-0.023125583,-0.061805625,0.98956805,-0.13013506,0.015168748,0.13130055,0.99122655},{0.9974416,0.062891409,-0.033984295,-0.067062489,0.98785481,-0.1401624,0.024756574,0.14208287,0.98954513},{0.99729836,0.060667869,-0.04141725,-0.062999258,0.99635462,-0.057520215,0.037776674,0.059974064,0.99748486},{0.89013896,0.3949653,-0.22727741,-0.42670065,0.89749147,-0.1115152,0.15993496,0.19624343,0.96742407},{0.90006339,0.14411545,-0.41123794,-0.18991043,0.97911904,-0.072525359,0.39219899,0.14337572,0.90863818},{0.88579831,-0.010015114,-0.46396238,-0.11312923,0.96494555,-0.236816,0.45007026,0.26225894,0.8536141},{0.85404533,0.068971047,-0.515606,-0.277047,0.89921418,-0.338613,0.44028589,0.43203789,0.78707793},{0.9394185,-0.3116822,0.14264325,0.32959134,0.9356554,-0.12616853,-0.094140428,0.16553907,0.98169975},{0.88223549,-0.13104011,0.45220464,0.15730939,0.98733037,-0.020795941,-0.4437503,0.089482979,0.89167173},{0.86033716,0.12491974,0.49418117,0.027514156,0.95671016,-0.28973879,-0.50898231,0.26287,0.81965629},{0.73957739,0.06726161,0.66970228,0.10520146,0.97121343,-0.21372184,-0.66479924,0.22851751,0.71121152},{0.9979381,0.063789735,-0.0071005453,-0.064042593,0.99696404,-0.044286057,0.0042540344,0.04464948,0.99899365},{0.99644675,0.069031361,0.048254991,-0.069072198,0.99761133,-0.00082305621,-0.048196503,-0.0025129496,0.99883471},{0.99644672,0.069031736,0.048255005,-0.069072503,0.9976113,-0.00082457174,-0.048196619,-0.0025114775,0.99883471}},{{0.99510817,-0.087874558,-0.045141828,0.082425121,0.99040052,-0.11096354,0.054459352,0.1066999,0.99279873},{0.98512187,0.12050613,0.1225281,-0.14980222,0.95154204,0.26856477,-0.084226977,-0.28292401,0.955437},{0.9945122,0.10426939,0.0085673853,-0.10167208,0.98254133,-0.15580548,-0.024663475,0.15407939,0.98775058},{0.99518134,0.096411856,0.017856503,-0.092736999,0.98464305,-0.14791161,-0.031842715,0.14554296,0.9888394},{0.99896076,0.040675679,0.020563251,-0.037738953,0.99115504,-0.12723004,-0.025556581,0.12632173,0.99166007},{0.98210567,0.012416841,-0.18792034,0.020250415,0.98507657,0.17092144,0.1872384,-0.1716684,0.96719797},{0.98308831,-0.069897556,-0.16926774,-0.050954254,0.78339537,-0.61943149,0.17590027,0.6175808,0.76658539},{0.95511869,-0.24269825,-0.16984003,0.010429756,0.60054917,-0.79951986,0.2960395,0.76186503,0.57612708},{0.96758637,-0.17671478,-0.18041144,-0.021838324,0.65316266,-0.75690265,0.251594,0.73630865,0.62813235},{0.99903191,0.033864441,-0.028079279,-0.036972998,0.99222889,-0.11880581,0.023837804,0.11972903,0.99252039},{0.99787688,0.033744858,-0.055704868,-0.040808126,0.99054599,-0.13097068,0.050758674,0.13296588,0.98982},{0.99660295,0.027715281,-0.077552683,-0.031926119,0.99805226,-0.053594791,0.075916267,0.055888713,0.99554667},{0.8953142,0.3528833,-0.27181944,-0.3941681,0.91188088,-0.1144758,0.20747049,0.20963454,0.95551529},{0.86719224,0.14722403,-0.47571278,-0.17766788,0.98389969,-0.019378392,0.46520083,0.1013238,0.87938713},{0.83219364,0.0047555674,-0.5544647,-0.089870923,0.98789803,-0.12641399,0.54715367,0.15503116,0.82254995},{0.79637926,0.046378235,-0.60301659,-0.23925369,0.93988017,-0.24368613,0.55546184,0.33834057,0.75959722},{0.93052377,-0.35381577,0.094550214,0.36355954,0.92354875,-0.12199296,-0.04415874,0.14789222,0.98801719},{0.91879164,-0.13999757,0.36908354,0.174687,0.98266191,-0.062128324,-0.35398664,0.12155724,0.92731728},{0.91064374,0.08852463,0.40359812,0.059173751,0.93877076,-0.33942301,-0.40893341,0.33297595,0.84964719},{0.81036636,0.016961728,0.585678,0.1682863,0.95072689,-0.26038083,-0.5612364,0.30956552,0.76758242},{0.99783953,0.047981575,-0.044878191,-0.050060807,0.997667,-0.046416164,0.042546393,0.048562563,0.99791356},{0.99754782,0.062255151,0.031979121,-0.061766496,0.99796161,-0.016046891,-0.032912925,0.014032328,0.99935972},{0.99754779,0.062255464,0.03197912,-0.061766743,0.99796158,-0.016048426,-0.032913019,0.014033845,0.99935969}},{{0.99701873,-0.075822819,-0.014303418,0.074211309,0.99305354,-0.09130896,0.021127379,0.08997529,0.99571987},{0.98367274,0.11603733,0.13756198,-0.13977053,0.97409147,0.17779204,-0.11336744,-0.19411626,0.97440581},{0.99645435,0.083900285,0.0062840776,-0.081464685,0.98079918,-0.17719052,-0.021029669,0.17605034,0.98415649},{0.99544358,0.093837432,0.016930298,-0.090296599,0.98473229,-0.14882502,-0.030637166,0.14661816,0.98871857},{0.9990904,0.038357174,0.018630633,-0.035642046,0.99100825,-0.12896621,-0.023409891,0.12818491,0.99147396},{0.98616501,-0.009130614,-0.16551452,0.058450012,0.95350478,0.2956557,0.15511948,-0.30123965,0.9408468},{0.98650583,-0.08175886,-0.1418508,-0.0021376754,0.85988669,-0.51048054,0.16371195,0.50389524,0.84810849},{0.95906512,-0.24298992,-0.14542976,0.097467235,0.76541302,-0.63611566,0.26588367,0.59590174,0.75776454},{0.97160505,-0.18137548,-0.15194199,0.056496316,0.8014321,-0.59541148,0.22976436,0.56992063,0.78892265},{0.99943012,0.0097627566,-0.032312921,-0.013156345,0.99422169,-0.10653702,0.031086143,0.10690149,0.99378354},{0.99714506,0.0038669301,-0.075410693,-0.013029986,0.99251822,-0.12139931,0.074377077,0.12203538,0.98973503},{0.9938286,-0.0077396723,-0.1106562,0.0024294487,0.99884231,-0.048043201,0.11089997,0.047477922,0.99269685},{0.89832436,0.31113356,-0.31017604,-0.36071137,0.9253796,-0.11644711,0.25080004,0.21649135,0.94352047},{0.82527681,0.15319746,-0.54355193,-0.16195355,0.98627671,0.03208264,0.54100764,0.061553161,0.83876216},{0.7596068,0.035358999,-0.64942069,-0.057466867,0.99826449,-0.012864735,0.64783881,0.047092317,0.76032051},{0.71539022,0.054395611,-0.69660454,-0.20788689,0.96838709,-0.13787485,0.66708318,0.24344929,0.70408279},{0.91586577,-0.39842622,0.049460502,0.40148284,0.90851778,-0.1157888,0.0011974768,0.12590465,0.99204163},{0.94293993,-0.15274896,0.29585829,0.1907772,0.97610002,-0.10408035,-0.27288915,0.15458457,0.94954469},{0.94371222,0.047324812,0.32736475,0.08856338,0.91742329,-0.38793171,-0.31869079,0.39508848,0.86159226},{0.85815893,-0.064191824,0.50935521,0.24467041,0.92336807,-0.29585097,-0.45133111,0.37851134,0.8081023},{0.99641023,0.030073834,-0.079134241,-0.033921979,0.99828354,-0.04774172,0.077562663,0.050254791,0.99572009},{0.99868533,0.048331076,0.017079773,-0.047811766,0.99841748,-0.029606481,-0.018483644,0.028750989,0.99941571},{0.99868532,0.048331323,0.017079769,-0.047811969,0.99841744,-0.029608011,-0.018483713,0.028752516,0.99941565}},{{0.99857021,-0.052530926,0.0099006614,0.053136001,0.9956519,-0.076510526,-0.0058384578,0.076927201,0.99701963},{0.98224044,0.11078182,0.15143011,-0.125228,0.98808965,0.089424747,-0.13971993,-0.1067999,0.98441463},{0.99802159,0.062826127,0.0024035595,-0.061141472,0.97874902,-0.19573454,-0.014649689,0.19520041,0.98065399},{0.9957758,0.090803923,0.013608776,-0.087767987,0.98487356,-0.14940132,-0.026969151,0.14757585,0.98868303},{0.9992566,0.035857405,0.014158439,-0.033705608,0.99086127,-0.13060571,-0.018712262,0.13003149,0.9913333},{0.9888713,-0.021559267,-0.14720302,0.081557729,0.90607602,0.41518022,0.12442617,-0.42256534,0.89775089},{0.98658441,-0.081668818,-0.1413555,0.024561961,0.93027438,-0.36604145,0.16139361,0.35765878,0.91980012},{0.95844287,-0.24305927,-0.14936351,0.16229278,0.89512411,-0.4152275,0.23462377,0.37373121,0.89737209},{0.97077954,-0.18510461,-0.15271981,0.11481751,0.91711111,-0.3817384,0.21072258,0.35304886,0.91156594},{0.99927109,-0.013763222,-0.035607101,0.010128152,0.9949031,-0.10032567,0.036806431,0.09989186,0.9943173},{0.99520041,-0.026439595,-0.094218351,0.015249653,0.99294821,-0.11756407,0.096662305,0.11556296,0.98858565},{0.98869328,-0.045629367,-0.14284098,0.039337316,0.99814021,-0.04656909,0.14470027,0.040423522,0.98864948},{0.90052641,0.26518455,-0.34457112,-0.32335844,0.93824792,-0.12300481,0.29067424,0.22218908,0.93066672},{0.77515751,0.15474626,-0.61252297,-0.13900843,0.98755417,0.073575871,0.61628529,0.028113026,0.78702106},{0.66364389,0.089500749,-0.74267516,-0.012785525,0.99402877,0.10836676,0.74793943,-0.062421433,0.66082537},{0.62102532,0.08686332,-0.77896228,-0.15947244,0.98705482,-0.017070791,0.7673957,0.13482447,0.62683825},{0.89670346,-0.44259651,0.0055815108,0.44033971,0.8907075,-0.11287686,0.044987285,0.10367491,0.9935933},{0.95772371,-0.17030984,0.23186182,0.20773768,0.96695093,-0.14782072,-0.19902378,0.18973782,0.96145153},{0.96326424,0.0014522466,0.2685515,0.11903501,0.89408007,-0.43180034,-0.24073367,0.44790487,0.86106242},{0.87966555,-0.14733682,0.45219511,0.32070605,0.88586861,-0.33523789,-0.35119261,0.43991897,0.82651981},{0.99362934,0.011688753,-0.11208973,-0.017379107,0.99860179,-0.049924201,0.11134947,0.051554124,0.99244318},{0.99946206,0.032572366,0.0038261422,-0.032403783,0.99875248,-0.037993615,-0.0050589051,0.037849149,0.99927064},{0.99946205,0.032572536,0.003826148,-0.032403944,0.99875241,-0.037995012,-0.0050589604,0.037850523,0.9992706}},{{0.9992117,-0.026404596,0.029643817,0.028419208,0.9971608,-0.069733021,-0.027718374,0.070520496,0.99712514},{0.98073722,0.097333437,0.16935377,-0.10027322,0.99492038,0.0088731116,-0.16762988,-0.025683812,0.98551538},{0.99858625,0.044406518,0.02921547,-0.037139646,0.97608737,-0.21418227,-0.038027929,0.21279449,0.97635673},{0.99603129,0.088444424,0.0099626338,-0.085974269,0.98503808,-0.14935957,-0.02302358,0.14791031,0.98873281},{0.99939754,0.033297895,0.0097873043,-0.031720468,0.99077667,-0.13173987,-0.014083712,0.13135004,0.99123601},{0.99141857,-0.040211495,-0.12438709,0.099204492,0.85108831,0.51556493,0.085132857,-0.52348042,0.84777397},{0.98814531,-0.066126295,-0.13855,0.039729108,0.98188296,-0.18527669,0.14829159,0.17757583,0.97287024},{0.96409657,-0.22133167,-0.14673076,0.19046335,0.96137257,-0.1987122,0.18504438,0.16363094,0.96901167},{0.97496633,-0.16545077,-0.148548,0.13841405,0.97445163,-0.17687724,0.17401744,0.15188836,0.97295841},{0.99874803,-0.034790385,-0.035944555,0.031105524,0.99465784,-0.098428813,0.039176913,0.097187501,0.99449473},{0.99239207,-0.056534129,-0.10937032,0.043462756,0.99201314,-0.11840995,0.11519099,0.11275556,0.98692311},{0.98165755,-0.086168545,-0.17006894,0.078985642,0.99569176,-0.048571406,0.17352156,0.034247469,0.98423441},{0.90448572,0.21251545,-0.36978738,-0.27856629,0.95089797,-0.13488473,0.32296505,0.22501162,0.91927329},{0.72360167,0.14833219,-0.6740906,-0.10832167,0.98893753,0.10133586,0.68166496,-0.00030820882,0.73166443},{0.55456479,0.15880237,-0.8168474,0.04678011,0.97412015,0.22113706,0.83082463,-0.16084705,0.53278385},{0.52645943,0.11905028,-0.84182388,-0.070981836,0.99284555,0.096017186,0.84723204,0.0092050429,0.53114328},{0.87554837,-0.48177468,-0.036169875,0.47533093,0.87239425,-0.11396818,0.086461327,0.082591933,0.99282576},{0.96580417,-0.19132527,0.17497707,0.22393471,0.95569653,-0.19104294,-0.13067368,0.22369348,0.96586002},{0.97383025,-0.048652151,0.22200827,0.15038145,0.87035062,-0.46890848,-0.17041169,0.49002318,0.85489013},{0.8871306,-0.21648311,0.40759586,0.38227908,0.83949146,-0.38615642,-0.25857695,0.49838654,0.82749551},{0.99005712,-0.0034390963,-0.14062389,-0.0040143256,0.99860312,-0.052684775,0.14060864,0.052725424,0.98866033},{0.99979583,0.018522327,-0.0080766856,-0.018816879,0.99909806,-0.038065991,0.0073643342,0.038210154,0.99924257},{0.99979582,0.018522431,-0.0080766892,-0.018816991,0.99909799,-0.038067381,0.0073643023,0.038211537,0.99924253}},{{0.99881317,-0.0042949016,0.048516068,0.0075713804,0.99768691,-0.067553517,-0.048113696,0.067840653,0.99653537},{0.97638813,0.074727899,0.20268685,-0.062392779,0.99582787,-0.066588242,-0.20681721,0.052369765,0.976977},{0.99533845,0.029638766,0.091776523,-0.0080627002,0.97384805,-0.22705721,-0.096106016,0.22525881,0.96954735},{0.99648257,0.083272274,0.0093925905,-0.080792979,0.98442482,-0.15614175,-0.022248571,0.15483371,0.98769},{0.99957446,0.027745744,0.0090037413,-0.026249245,0.99019124,-0.13723069,-0.01272301,0.13693604,0.9904982},{0.99330367,-0.069923767,-0.091969611,0.11044838,0.80827255,0.57835683,0.033895687,-0.58464189,0.81058315},{0.99131953,-0.034705037,-0.12681128,0.038356897,0.99891345,0.026469507,0.12575495,-0.031103766,0.99157367},{0.97313635,-0.18848244,-0.13221149,0.19139645,0.98146612,0.0095728434,0.12795689,-0.034620439,0.99117537},{0.98171347,-0.13487745,-0.13433747,0.13881538,0.99010922,0.020348005,0.13026439,-0.038623867,0.99072677},{0.99818203,-0.05014268,-0.033441566,0.046713067,0.99424013,-0.096459635,0.03808571,0.094722123,0.99477495},{0.98915596,-0.084548901,-0.12009151,0.070074094,0.99029455,-0.12002636,0.12907408,0.11030949,0.98548044},{0.97345296,-0.12732662,-0.19020323,0.1195388,0.99147105,-0.051919645,0.19519175,0.027804685,0.98037089},{0.90839292,0.15887279,-0.38675791,-0.23114463,0.96161432,-0.14788522,0.3484171,0.22373499,0.91024627},{0.67464721,0.13432079,-0.72581603,-0.06672236,0.99037551,0.12126204,0.73511862,-0.033380926,0.67711629},{0.44741207,0.22838295,-0.86467538,0.1168801,0.94361949,0.30971175,0.88665758,-0.23963208,0.39549323},{0.4405132,0.15141065,-0.88488575,0.045866681,0.9805918,0.19062,0.89657375,-0.12455737,0.42501894},{0.85458366,-0.5142997,-0.071990176,0.5049203,0.85528659,-0.11636306,0.12141773,0.063092613,0.99059429},{0.9693101,-0.21202663,0.12442935,0.23588657,0.94470384,-0.22779857,-0.069249532,0.25015865,0.96572518},{0.97857648,-0.098040636,0.18104185,0.17747775,0.84740048,-0.50041387,-0.1043541,0.52182411,0.84664622},{0.8888163,-0.27836034,0.36403451,0.42780974,0.78876298,-0.44139752,-0.16426943,0.54805879,0.82015067},{0.98658752,-0.013315923,-0.16268911,0.0044104812,0.99847781,-0.054978293,0.16317356,0.053523378,0.98514448},{0.99980754,0.007549851,-0.018107626,-0.008077101,0.9995402,-0.029225616,0.017878687,0.029366253,0.99940881},{0.99980754,0.0075498884,-0.018107629,-0.0080771577,0.99954017,-0.029226827,0.017878673,0.029367472,0.99940878}},{{0.99793361,0.016165918,0.062186616,-0.011663524,0.99732963,-0.072094301,-0.063186005,0.071219997,0.9954573},{0.96909419,0.051323313,0.24129311,-0.02089942,0.9916832,-0.12699469,-0.2458041,0.11802691,0.96210705},{0.98515337,0.014628023,0.17105219,0.028853508,0.96808228,-0.24896616,-0.16923443,0.25020535,0.95328748},{0.99706881,0.075762143,0.010673169,-0.072867801,0.98284582,-0.1694234,-0.023325893,0.16814909,0.98548559},{0.99974107,0.020283606,0.010314248,-0.018582504,0.98934057,-0.14442962,-0.013133822,0.14420062,0.98946131},{0.99339527,-0.092821716,-0.06745267,0.11473195,0.79575467,0.59465212,-0.0015207354,-0.59846361,0.80114858},{0.99352745,-0.014522172,-0.11265964,0.039361684,0.97435948,0.22152715,0.10655404,-0.22452784,0.96862458},{0.97860311,-0.1701652,-0.11567025,0.1919311,0.95753841,0.21513417,0.074150495,-0.23273173,0.96971013},{0.9855933,-0.11942365,-0.11976507,0.14367955,0.96477671,0.22036812,0.089229493,-0.23440115,0.96803634},{0.99762708,-0.064146296,-0.025009136,0.061579197,0.99379886,-0.092584155,0.030793008,0.090824403,0.99539074},{0.98621023,-0.10867083,-0.12481998,0.093823591,0.98842301,-0.11923547,0.1363324,0.10588016,0.98498877},{0.96558101,-0.1623156,-0.20324107,0.15476966,0.98654952,-0.052596354,0.20904463,0.019330453,0.97771504},{0.91011558,0.11312261,-0.39861371,-0.18898493,0.96944979,-0.15637063,0.36874696,0.21764737,0.90368984},{0.62919258,0.11159332,-0.76919671,-0.012570146,0.99097103,0.13348557,0.7771478,-0.074319273,0.62491438},{0.34929368,0.29532184,-0.88925751,0.19341412,0.90587215,0.37681114,0.91683418,-0.3036127,0.25929599},{0.38667991,0.18679381,-0.9030984,0.17877252,0.94551335,0.27211185,0.90472043,-0.26666936,0.33221744},{0.83734142,-0.53693554,-0.10275958,0.52598103,0.8425107,-0.11627454,0.14900782,0.043312081,0.98788698},{0.97055395,-0.2277538,0.078443185,0.24040295,0.93638753,-0.25570476,-0.015215781,0.26703323,0.96356708},{0.9799507,-0.1403952,0.14137149,0.19460606,0.82660834,-0.52805986,-0.042722067,0.54498427,0.83735704},{0.88629569,-0.33530252,0.31945629,0.45765155,0.73979696,-0.4932094,-0.070958693,0.58332901,0.80913038},{0.98382877,-0.01790177,-0.17821467,0.0083342866,0.99849044,-0.05428983,0.17891758,0.051926578,0.98249282},{0.99967883,0.0019613857,-0.025266312,-0.0023484153,0.99988023,-0.015297737,0.025233351,0.015352135,0.99956369},{0.99967883,0.00196135,-0.025266336,-0.0023484194,0.9998802,-0.01529914,0.025233372,0.015353509,0.99956368}},{{0.99689344,0.029851949,0.072885675,-0.024073399,0.99659087,-0.078912159,-0.074992902,0.076912416,0.99421353},{0.96215642,0.040991773,0.26939688,0.01307432,0.9805377,-0.19589505,-0.2721839,0.19200388,0.94289472},{0.97270884,-0.0058799348,0.23195457,0.06806367,0.96293164,-0.26101719,-0.22182164,0.26968143,0.93705236},{0.99743153,0.07085929,0.010454574,-0.067722023,0.98049383,-0.18451441,-0.023325221,0.18333248,0.98277421},{0.99981691,0.01630907,0.010007111,-0.014642296,0.98879445,-0.14856352,-0.012317923,0.14838983,0.98885224},{0.99268966,-0.10520219,-0.059158214,0.12034118,0.82525108,0.55179586,-0.0092296907,-0.55488124,0.83187839},{0.99529324,-0.02403384,-0.093881211,0.059221915,0.91766135,0.39292549,0.07670771,-0.39663593,0.91476549},{0.97791811,-0.1876989,-0.091897866,0.20809518,0.91515455,0.34523693,0.019300241,-0.35673693,0.93400554},{0.98571516,-0.13708787,-0.097838771,0.16240915,0.92751645,0.33665492,0.04459586,-0.34773575,0.93653144},{0.99647544,-0.083173752,-0.01090046,0.081881578,0.99265938,-0.08900992,0.018223702,0.087803625,0.99597109},{0.98393831,-0.12895116,-0.12343827,0.11466018,0.98653489,-0.11662747,0.13681537,0.10060076,0.98547503},{0.95980101,-0.18668326,-0.20959816,0.17978666,0.98234804,-0.051663304,0.21554297,0.011903535,0.97642179},{0.91389668,0.07575756,-0.39881524,-0.1521386,0.9747468,-0.16347026,0.37635981,0.21007014,0.90234354},{0.59157462,0.080546569,-0.80221671,0.045932871,0.99001421,0.13327444,0.80494078,-0.11568982,0.58196756},{0.26968258,0.35144666,-0.89652466,0.26541387,0.86782786,0.42003607,0.92564942,-0.35122651,0.14075919},{0.36970492,0.23105881,-0.8999611,0.30232284,0.88596617,0.35166022,0.87858935,-0.40208931,0.25769167},{0.82551476,-0.54904685,-0.13066306,0.53700992,0.83536266,-0.11742969,0.17362532,0.026772714,0.98444777},{0.97054364,-0.23797957,0.037561025,0.23890145,0.93045568,-0.27780993,0.03116413,0.27860004,0.95990141},{0.97937634,-0.17348596,0.10355969,0.20166459,0.80794614,-0.55367363,0.012383863,0.56313914,0.82626926},{0.88216317,-0.38064121,0.27730937,0.47068539,0.69310866,-0.54594473,0.015603468,0.61213781,0.7905971},{0.98208752,-0.019937533,-0.18736757,0.010299145,0.99857964,-0.052274629,0.18814363,0.04940852,0.98089794},{0.99954425,0.0007174249,-0.03017899,-0.00086903585,0.99998707,-0.0050115184,0.030174969,0.0050354379,0.99953194},{0.99954425,0.00071733785,-0.030179013,-0.00086898159,0.99998706,-0.005012739,0.030174997,0.0050366494,0.99953194}},{{0.99599744,0.033879506,0.082712052,-0.027282558,0.9964515,-0.079624675,-0.085116191,0.077049387,0.99338744},{0.95613157,0.042847194,0.28978699,0.036644953,0.9639798,-0.26343901,-0.29063643,0.26250158,0.9201214},{0.96442334,-0.030220312,0.26262968,0.10729552,0.95268739,-0.28438434,-0.24160976,0.30244587,0.92203643},{0.99782937,0.06541988,0.0075377748,-0.062101164,0.97288179,-0.22281041,-0.021909558,0.22185868,0.97483263},{0.99989259,0.013063647,0.0066466161,-0.01175885,0.98566138,-0.16832517,-0.0087502212,0.16822897,0.9857091},{0.99118624,-0.11900774,-0.058196863,0.13162536,0.83502401,0.53423752,-0.014982469,-0.53718909,0.8433288},{0.99613289,-0.042515805,-0.076886663,0.071680227,0.899314,0.43138878,0.050804552,-0.43523189,0.89888387},{0.98211559,-0.1741914,-0.071457383,0.18809606,0.92445923,0.33165501,0.0082881555,-0.33916448,0.94069064},{0.9890957,-0.12394102,-0.079549542,0.14368397,0.93063507,0.33656094,0.032318028,-0.34432106,0.93829567},{0.99492065,-0.10065833,0.00090194683,0.10034444,0.9910273,-0.088294249,0.0079937246,0.087936266,0.99609403},{0.98227483,-0.14360102,-0.12047779,0.12968117,0.98470183,-0.11638336,0.13534751,0.098696734,0.98587018},{0.95612207,-0.20238156,-0.2118308,0.19524545,0.97924977,-0.054305546,0.21842575,0.010563722,0.9757964},{0.92107912,0.041701415,-0.38713596,-0.11717339,0.97784756,-0.17344906,0.37132688,0.20512224,0.90556125},{0.56844184,0.051901429,-0.82108472,0.090176707,0.98806458,0.12488607,0.81776648,-0.14503334,0.55697697},{0.22116631,0.37945844,-0.89838562,0.31470951,0.84414517,0.43402412,0.92306192,-0.37872208,0.067277225},{0.36414596,0.27693343,-0.88921629,0.38413294,0.82511568,0.41427776,0.84843357,-0.49243486,0.19408323},{0.81647286,-0.55725446,-0.15112747,0.5436902,0.83012937,-0.12363749,0.19435286,0.018780273,0.98075188},{0.96905976,-0.24664997,0.0093299006,0.23834884,0.92528631,-0.29501703,0.064133,0.28811298,0.9554464},{0.97718721,-0.19815465,0.076419566,0.20549085,0.79125861,-0.5759196,0.05365343,0.5784848,0.81392662},{0.87471696,-0.41507482,0.25016638,0.47659484,0.64310967,-0.59938911,0.087906859,0.64352388,0.76036131},{0.98115906,-0.024310515,-0.1916661,0.014454404,0.99850816,-0.052654816,0.19266027,0.048892332,0.98004672},{0.99943673,-0.0014102675,-0.033529533,0.0014288297,0.99999883,0.0005307535,0.033528759,-0.00057834143,0.99943759},{0.99943673,-0.001410413,-0.033529574,0.0014289423,0.99999884,0.00052953478,0.033528808,-0.00057712814,0.99943759}},{{0.99509145,0.0413173,0.089921638,-0.034874139,0.99678888,-0.072081358,-0.09261108,0.068591607,0.99333698},{0.95072293,0.050875608,0.30583915,0.051882267,0.94642928,-0.31871598,-0.30566997,0.31887818,0.89715246},{0.96387026,-0.052770103,0.26109282,0.14075134,0.93306599,-0.33102415,-0.22614858,0.35581347,0.90678195},{0.99822785,0.058435041,0.0112495,-0.051654852,0.94472959,-0.3237558,-0.029546377,0.32260097,0.94607374},{0.99988645,0.012672827,0.0081560925,-0.01059252,0.97593061,-0.21782386,-0.010720191,0.21771277,0.975954},{0.98932728,-0.1347699,-0.055394814,0.14300349,0.82510726,0.54657845,-0.027955651,-0.54866664,0.83557371},{0.99610939,-0.05624894,-0.067839016,0.077486853,0.92570679,0.37021987,0.041974586,-0.37403604,0.92646379},{0.98995499,-0.12550267,-0.065101212,0.13668864,0.96725321,0.21386301,0.03612899,-0.22061329,0.97469203},{0.99426058,-0.077959941,-0.073267335,0.094699547,0.95995463,0.26366479,0.049778058,-0.26908988,0.96182785},{0.99356353,-0.11319793,0.0042113964,0.11312613,0.98964738,-0.088320714,0.0058299323,0.088228686,0.99608319},{0.98067461,-0.15393273,-0.12075603,0.13977488,0.98311631,-0.11809019,0.13689516,0.09892942,0.98563314},{0.95296338,-0.21282194,-0.21579533,0.20475592,0.9770128,-0.059338006,0.22346321,0.012361593,0.97463397},{0.92475873,0.014900849,-0.38026203,-0.090635557,0.97910328,-0.18204929,0.36960316,0.202817,0.90678489},{0.56893403,0.03222132,-0.82175175,0.10602387,0.98801935,0.11214581,0.81552008,-0.15092876,0.55870156},{0.21517123,0.3747647,-0.90180535,0.32880646,0.84171847,0.42824784,0.9195584,-0.38866597,0.057888628},{0.36573147,0.29205698,-0.88370998,0.41387279,0.79941445,0.43548332,0.8336365,-0.52501343,0.17149668},{0.80773721,-0.5668011,-0.16216408,0.55176099,0.82369744,-0.13069917,0.20765457,0.01609485,0.9780698},{0.96737621,-0.25331952,0.0035427266,0.24259047,0.9221924,-0.30118267,0.073028234,0.29221649,0.95355984},{0.97522818,-0.21013847,0.069079174,0.20981987,0.77990117,-0.58968619,0.070040709,0.58957274,0.8046727},{0.86575689,-0.43575385,0.24613755,0.48250272,0.59617737,-0.64168814,0.13287634,0.67430798,0.72639695},{0.98018593,-0.035173282,-0.19493176,0.025085221,0.99822677,-0.053981826,0.19648479,0.048022356,0.97933016},{0.99937007,-0.004941255,-0.035143179,0.005271462,0.99994277,0.0093085199,0.035095157,-0.0094878711,0.99933895},{0.99937007,-0.0049414651,-0.035143241,0.0052716247,0.99994279,0.0093074538,0.035095211,-0.0094867956,0.99933894}},{{0.99406267,0.042852336,0.1000155,-0.036011864,0.99695083,-0.069225461,-0.10267699,0.065212683,0.9925748},{0.9442481,0.056452606,0.32435876,0.063724108,0.93522271,-0.34827827,-0.32300888,0.34953055,0.87948488},{0.97349502,-0.05540668,0.22189534,0.14322764,0.90409442,-0.40261538,-0.17830669,0.42372563,0.88806718},{0.99855355,0.038886589,0.037130337,-0.014822821,0.86292722,-0.50511073,-0.051682766,0.50382974,0.86225547},{0.99965297,0.0098927712,0.024414724,-0.0028819665,0.96231349,-0.27192726,-0.026184726,0.27176254,0.96200804},{0.98761435,-0.14513001,-0.059624875,0.15337636,0.81290952,0.56183079,-0.03306883,-0.5640172,0.82510064},{0.99555724,-0.076777929,-0.054505914,0.088415231,0.96135244,0.26073784,0.032380543,-0.26439863,0.96386975},{0.99321161,-0.10443828,-0.051217947,0.10729176,0.99261844,0.056543361,0.044934666,-0.06165481,0.99708555},{0.99671752,-0.056288558,-0.058186693,0.063432436,0.98957736,0.12927873,0.050303385,-0.13254528,0.98989969},{0.99267055,-0.12076462,-0.0045917399,0.11987664,0.98876607,-0.089281857,0.015322259,0.088077004,0.99599582},{0.97932652,-0.15642599,-0.12825941,0.14149201,0.98284329,-0.11831775,0.14456689,0.097724004,0.98465752},{0.95089275,-0.21128409,-0.2261902,0.20275097,0.97735401,-0.060590323,0.23386969,0.01175461,0.9721969},{0.92244004,0.0022715936,-0.38613358,-0.078752058,0.98007178,-0.18236612,0.37802447,0.19863068,0.90423638},{0.59608794,0.020252689,-0.80266358,0.09169798,0.99142389,0.09311379,0.79766581,-0.1291066,0.58911873},{0.256917,0.34645109,-0.90220017,0.30673703,0.8560353,0.41607208,0.91646397,-0.38363418,0.11366061},{0.40183436,0.2651557,-0.87648242,0.40485731,0.80708462,0.42977321,0.82135244,-0.52754797,0.21696408},{0.80338025,-0.57090726,-0.16924871,0.55551919,0.82092387,-0.13222101,0.21442622,0.012202713,0.97666395},{0.96801424,-0.2500818,0.020186053,0.24504438,0.92510132,-0.29007053,0.053867277,0.28573872,0.95679236},{0.9764256,-0.20016791,0.080782432,0.20899269,0.78307614,-0.58575917,0.05399138,0.5888331,0.80644936},{0.86385223,-0.42998929,0.26242807,0.48481691,0.56819962,-0.66490736,0.13679148,0.70161115,0.69930671},{0.97803966,-0.052822079,-0.2016141,0.042732717,0.99762211,-0.05407446,0.20399102,0.04427143,0.97797122},{0.99946431,-0.0062704621,-0.032121339,0.0068373384,0.99982228,0.017569021,0.032005477,-0.017779258,0.99932954},{0.9994643,-0.00627072,-0.032121402,0.0068375652,0.99982229,0.017567957,0.032005545,-0.017778179,0.99932957}},{{0.99167645,0.054788328,0.11651642,-0.044960606,0.99533485,-0.085364386,-0.1206498,0.079415191,0.98951343},{0.93886833,0.036094762,0.34237911,0.076588075,0.94767103,-0.30992563,-0.33564943,0.31720152,0.88697386},{0.98308407,-0.019564506,0.18210697,0.1141714,0.84292195,-0.52578273,-0.14321519,0.53768006,0.83089684},{0.99512204,0.056225176,0.081061008,0.020358646,0.68695814,-0.72641176,-0.096528066,0.72451863,0.68246249},{0.99740025,0.018218897,0.069719927,0.015496317,0.89064871,-0.45442794,-0.070375085,0.45432691,0.88805086},{0.98712002,-0.14384219,-0.070024536,0.15826198,0.81400065,0.55888822,-0.023391658,-0.56277202,0.82628117},{0.99380649,-0.10168104,-0.044828413,0.10737453,0.9825796,0.15168396,0.028624173,-0.15555795,0.98741198},{0.99378347,-0.10403724,-0.039630932,0.1013667,0.99276878,-0.06430269,0.046034277,0.059885741,0.99714327},{0.99766968,-0.049740787,-0.046701049,0.048716301,0.99855181,-0.022825548,0.047768851,0.020497294,0.99864813},{0.99232403,-0.12197814,-0.020355512,0.11936607,0.98778645,-0.10014829,0.032322837,0.096949815,0.99476428},{0.97817443,-0.15497362,-0.13841225,0.13772742,0.98235141,-0.12655775,0.15558262,0.10473241,0.98225515},{0.94967577,-0.20489746,-0.2369239,0.19466581,0.97864237,-0.066063206,0.24539998,0.016617638,0.96927949},{0.91714006,-0.0066245294,-0.39851002,-0.071757693,0.98077884,-0.1814488,0.39205221,0.19501023,0.89903621},{0.63721096,0.012859667,-0.77058208,0.055851593,0.99646124,0.062814031,0.76866302,-0.083064081,0.63423781},{0.33265045,0.29049633,-0.89719313,0.25463881,0.8883673,0.38205052,0.90802139,-0.35554938,0.22154423},{0.4716681,0.19799401,-0.85925989,0.37494469,0.83694673,0.39866853,0.79808882,-0.5102141,0.32052438},{0.80473542,-0.56900845,-0.16920483,0.55343436,0.82222425,-0.13288235,0.21473546,0.01329166,0.97658179},{0.96853286,-0.24274487,0.054946792,0.24853963,0.93167916,-0.26495659,0.013123825,0.27027573,0.96269344},{0.97774854,-0.17685808,0.11282362,0.20960746,0.80177456,-0.55966268,0.0085215381,0.57085803,0.82100443},{0.86345977,-0.40334499,0.30290299,0.49480826,0.5606347,-0.663968,0.097990036,0.72318861,0.68366368},{0.97568101,-0.06998688,-0.20772189,0.059536419,0.99664566,-0.056150129,0.21095493,0.042417611,0.97657502},{0.99969886,-0.0081513028,-0.023146474,0.0084699243,0.99987028,0.013699173,0.023031859,-0.013891057,0.99963823},{0.99969885,-0.008151617,-0.023146557,0.0084702111,0.9998703,0.013698077,0.023031936,-0.013889976,0.99963823}},{{0.98663226,0.084862346,0.13912288,-0.068094151,0.99029567,-0.1211514,-0.14805396,0.11005843,0.98283628},{0.93825907,0.01411991,0.34564514,0.080222248,0.96304773,-0.25710592,-0.33650307,0.26896038,0.90245553},{0.98902616,0.027503818,0.14515788,0.073689811,0.75974294,-0.64603437,-0.12805105,0.64964157,0.74937895},{0.98462336,0.13878282,0.10609519,0.037739797,0.42399754,-0.90487666,-0.17056543,0.89496673,0.41224022},{0.98957852,0.080354234,0.11948878,0.043169003,0.62609263,-0.77855279,-0.13737106,0.77559733,0.61609899},{0.98714433,-0.13558442,-0.084633942,0.1598114,0.82894323,0.53601631,-0.0025186661,-0.54265093,0.83995453},{0.99151842,-0.12192845,-0.044996033,0.12445669,0.9905007,0.058471429,0.037439301,-0.063575556,0.99727452},{0.99352605,-0.10599249,-0.040884552,0.10054308,0.98792281,-0.11789682,0.052887002,0.11302286,0.99218385},{0.99774616,-0.046942186,-0.047947723,0.041442019,0.99308013,-0.10988363,0.052774141,0.10764889,0.99278731},{0.99278954,-0.11692336,-0.026416961,0.11283931,0.98594628,-0.1231959,0.040450149,0.1193267,0.9920307},{0.97918829,-0.14836621,-0.13848385,0.12802774,0.98100217,-0.14575202,0.15747761,0.12498887,0.97958082},{0.95289678,-0.19065474,-0.23587815,0.17685138,0.98109757,-0.078556602,0.24639666,0.033140934,0.96860227},{0.91232721,-0.0012603493,-0.40945992,-0.079769728,0.9802881,-0.18075407,0.40161656,0.19756937,0.89424299},{0.67205579,0.020039436,-0.74022924,0.010136862,0.99929115,0.036255945,0.74043114,-0.031869608,0.67137628},{0.42215698,0.20680423,-0.8826185,0.18687826,0.93286467,0.30796123,0.88705132,-0.2949502,0.35516802},{0.55641024,0.10473417,-0.82428047,0.32761679,0.88400427,0.33347236,0.76359343,-0.45559555,0.45755627},{0.81764467,-0.55448512,-0.15493031,0.53848063,0.83175768,-0.1349736,0.20370524,0.026933484,0.9786617},{0.96894783,-0.2278885,0.09595277,0.24430355,0.94220186,-0.22928479,-0.038155634,0.24560658,0.96861833},{0.9776098,-0.14382719,0.1535994,0.20322295,0.83467617,-0.5118752,-0.054584307,0.53162907,0.84521655},{0.86937443,-0.35937427,0.33917294,0.49333212,0.59163432,-0.63764588,0.028487061,0.72167791,0.69164255},{0.97564252,-0.078256668,-0.20493309,0.067087381,0.99588647,-0.060905047,0.20885631,0.045673115,0.97687922},{0.99979734,-0.015137385,-0.013271454,0.015145411,0.99988517,0.00050454235,0.013262296,-0.00070543392,0.99991181},{0.99979734,-0.015137742,-0.013271555,0.015145757,0.99988517,0.00050345129,0.013262405,-0.0007043434,0.9999118}},{{0.98305184,0.1034482,0.15135234,-0.080133663,0.98500792,-0.15276777,-0.16488682,0.13805021,0.97660356},{0.94511549,0.0027354162,0.32672494,0.067794917,0.97656086,-0.20428595,-0.31962562,0.21522411,0.92277737},{0.98979605,0.05473107,0.13156096,0.058012364,0.68852396,-0.72288958,-0.13014732,0.72314542,0.67832319},{0.97042656,0.20917994,0.12048264,0.066938257,0.24635206,-0.96686605,-0.23193008,0.94633735,0.22506446},{0.97974418,0.14565078,0.13743064,0.080706919,0.34088488,-0.93663434,-0.18326952,0.92875365,0.32222498},{0.98714339,-0.12830938,-0.095312965,0.15892683,0.85146432,0.49975072,0.017032966,-0.50847344,0.86090923},{0.99024662,-0.13238442,-0.04342759,0.13175289,0.991135,-0.017106192,0.045307235,0.0112176,0.99891013},{0.99332109,-0.10722763,-0.04260698,0.10095186,0.9864804,-0.12909378,0.055873472,0.12393027,0.99071664},{0.99763721,-0.048000144,-0.049151638,0.041386832,0.99094911,-0.12769885,0.054836427,0.12536289,0.99059438},{0.99436165,-0.10485731,-0.015806931,0.10142332,0.98393991,-0.14688622,0.030955186,0.14445481,0.98902709},{0.98360046,-0.1338691,-0.12086852,0.11283277,0.97953315,-0.16668404,0.14070859,0.15031255,0.97857408},{0.96274648,-0.16482148,-0.21436672,0.14775317,0.98459875,-0.093457504,0.22646904,0.058302504,0.97227188},{0.91165769,0.042281855,-0.40876943,-0.1260235,0.97553127,-0.18015768,0.39115004,0.21575675,0.89467913},{0.690974,0.047651641,-0.72130729,-0.042506018,0.99877675,0.025263592,0.72162885,0.013203462,0.69215425},{0.50977139,0.098757648,-0.85462275,0.11415686,0.97684016,0.18097382,0.8527024,-0.18981632,0.48669128},{0.62919796,0.011435392,-0.77716094,0.24907064,0.94419534,0.21554349,0.73625659,-0.32918749,0.59123755},{0.84004195,-0.52854946,-0.12233106,0.51207653,0.84695477,-0.14298723,0.17918469,0.057472464,0.98213531},{0.96997123,-0.20258663,0.13459011,0.22598327,0.95527546,-0.19073645,-0.089930059,0.21542397,0.97237083},{0.97577136,-0.10449867,0.19222457,0.1822332,0.87438506,-0.4497131,-0.12108394,0.47384684,0.87224298},{0.88879283,-0.30596317,0.34122412,0.45588068,0.6667511,-0.58958949,-0.047118971,0.67958038,0.73208624},{0.97956687,-0.07741041,-0.18562427,0.065560819,0.9954493,-0.069155457,0.19013294,0.055572689,0.98018424},{0.99970025,-0.023687303,-0.0061910233,0.023615984,0.99965668,-0.011350047,0.0064577845,0.011200421,0.99991641},{0.99970024,-0.023687705,-0.0061911261,0.02361638,0.99965665,-0.011350948,0.0064579123,0.01120133,0.99991641}},{{0.98487909,0.1022158,0.1398753,-0.079041299,0.98358264,-0.16222716,-0.1541611,0.1487182,0.97678926},{0.95590196,-0.0040597884,0.29365785,0.040522424,0.99216381,-0.11819022,-0.29087687,0.12487796,0.94857586},{0.98838048,0.070835434,0.13448554,0.054022072,0.66330359,-0.746398,-0.14207608,0.74499042,0.65176962},{0.96640963,0.21995852,0.13293112,0.07265759,0.26230191,-0.96224667,-0.24652238,0.93958283,0.23750948},{0.97690945,0.15597277,0.14601506,0.089661437,0.3210408,-0.94281156,-0.19392967,0.93413345,0.29964311},{0.98750598,-0.12546085,-0.09534875,0.15500585,0.88231454,0.4444033,0.02837252,-0.45363055,0.89073812},{0.99082989,-0.12951183,-0.038506271,0.12654742,0.989386,-0.07142207,0.047347709,0.065894187,0.99670267},{0.99340354,-0.10720702,-0.040692823,0.1011057,0.98631114,-0.13026129,0.054100879,0.12528772,0.99064433},{0.99772855,-0.048908026,-0.046320193,0.042570513,0.99071669,-0.12910538,0.052204632,0.12684023,0.99054853},{0.99608948,-0.088349069,0.00044697836,0.087264886,0.9830506,-0.16123387,0.013805437,0.16064234,0.98691613},{0.98904463,-0.11554334,-0.091872045,0.097446562,0.97853253,-0.18159914,0.11088234,0.17065701,0.97907164},{0.97538624,-0.13302247,-0.17585995,0.1151258,0.98742236,-0.10836575,0.18806311,0.085452439,0.97843249},{0.91207179,0.12162749,-0.39157602,-0.20634135,0.96140586,-0.18199465,0.35432794,0.24679045,0.90196794},{0.70398646,0.084713044,-0.70514308,-0.10145982,0.9946731,0.018202576,0.70292885,0.058729267,0.70883136},{0.59087835,-0.013455603,-0.80664844,0.041090113,0.99906521,0.013433669,0.80571354,-0.041082952,0.59087879},{0.67642412,-0.058966174,-0.73414808,0.12592436,0.991372,0.036397129,0.72566756,-0.117067,0.67801311},{0.86589129,-0.49463892,-0.074596552,0.47918255,0.86298392,-0.16013369,0.14358396,0.10291302,0.9842726},{0.9684156,-0.17393146,0.17865908,0.20210833,0.96719175,-0.15392333,-0.14602549,0.18517019,0.97179655},{0.96942651,-0.06499076,0.23661881,0.1537688,0.91236737,-0.37939555,-0.19122607,0.40418073,0.89446659},{0.91252275,-0.25402426,0.3205837,0.39273663,0.76313472,-0.51320888,-0.11428105,0.59421976,0.79614239},{0.98608871,-0.071258403,-0.15017089,0.059355107,0.99483741,-0.082313427,0.15526112,0.072254927,0.98522749},{0.99958776,-0.028703482,0.00064508947,0.028710675,0.99934656,-0.021958306,-1.4418749e-05,0.02196776,0.99975868},{0.99958775,-0.028703931,0.00064496658,0.028711123,0.99934652,-0.021959197,-1.4259195e-05,0.021968684,0.99975866}},{{0.98857836,0.09661253,0.11566706,-0.077545322,0.98418154,-0.15929034,-0.12922681,0.14850154,0.98043241},{0.96372667,-0.00072256602,0.26689022,0.0043443643,0.99990631,-0.012980183,-0.26685583,0.013668816,0.96363952},{0.98810446,0.094323361,0.12146065,0.021286138,0.69832265,-0.71546653,-0.15230381,0.70954112,0.68800796},{0.96952685,0.21377879,0.11965079,0.031146584,0.37687603,-0.9257399,-0.24299702,0.9012564,0.35873294},{0.97980098,0.15101485,0.13108991,0.052533523,0.43813163,-0.89737443,-0.19295143,0.88613497,0.42134854},{0.98787437,-0.12704187,-0.089244773,0.15127679,0.91693825,0.36924187,0.034922732,-0.37826524,0.92503827},{0.99311659,-0.11183271,-0.034826571,0.10747898,0.98826223,-0.10856362,0.046558727,0.10407317,0.99347925},{0.99353288,-0.10683276,-0.038460158,0.10091159,0.98606932,-0.13222756,0.052050608,0.12749135,0.99047297},{0.99787213,-0.049019579,-0.042991589,0.042846877,0.99001235,-0.13431206,0.049146132,0.1321841,0.99000606},{0.99740214,-0.071176105,0.01108714,0.072027865,0.98334584,-0.16686205,0.00097408593,0.16722714,0.98591791},{0.99341306,-0.095787311,-0.062890978,0.082343156,0.97841762,-0.18952197,0.079687427,0.18309494,0.97986027},{0.98635792,-0.098104281,-0.13218777,0.082345086,0.98937358,-0.11982993,0.1425389,0.10731017,0.98395487},{0.90864473,0.20965543,-0.36112239,-0.28994395,0.93912589,-0.18432319,0.30049502,0.27218957,0.91412011},{0.72449404,0.11802713,-0.67910083,-0.16193846,0.98680006,-0.0012579796,0.66998831,0.11088394,0.73404389},{0.66347782,-0.089557071,-0.74281672,-0.028597965,0.98904941,-0.14478743,0.74764924,0.11730631,0.65365121},{0.7122765,-0.095463447,-0.69537678,-0.020924811,0.98737945,-0.15698388,0.70158703,0.12636655,0.70128967},{0.89113846,-0.45315184,-0.02292557,0.44229981,0.87884716,-0.17888166,0.10120846,0.1492685,0.98360345},{0.95872988,-0.15216016,0.24017573,0.18362491,0.97630942,-0.11446299,-0.21706933,0.15384142,0.9639573},{0.95262906,-0.030245541,0.30262715,0.12627902,0.94455251,-0.30310753,-0.27667967,0.32696455,0.90362737},{0.92321644,-0.20685139,0.32385803,0.33307517,0.85105518,-0.40591379,-0.19165732,0.48261542,0.854605},{0.99228251,-0.060564422,-0.10820062,0.050138625,0.99405897,-0.096606897,0.11340872,0.090436289,0.98942394},{0.99953726,-0.028778241,0.0098529494,0.029115303,0.99892861,-0.035971366,-0.0088072159,0.03624158,0.99930425},{0.99953725,-0.028778739,0.0098528022,0.029115801,0.99892856,-0.035972259,-0.0088070247,0.03624251,0.99930422}},{{0.99214371,0.087937643,0.088982182,-0.07392809,0.98591118,-0.1500459,-0.10092319,0.14228879,0.98466665},{0.96897734,0.0099441728,0.24694946,-0.034009015,0.99504995,0.093375457,-0.24479849,-0.098877246,0.96451905},{0.98765652,0.11922077,0.10159239,-0.028282502,0.77366807,-0.63295961,-0.15406066,0.62227339,0.76749013},{0.97180625,0.21429384,0.098340063,-0.030511903,0.5278742,-0.84877433,-0.23379824,0.82184362,0.51953001},{0.98222474,0.15362804,0.10785627,-0.0020010295,0.58313116,-0.81237556,-0.18769799,0.79771954,0.57307328},{0.98825343,-0.12776532,-0.083851952,0.14639516,0.94892001,0.27949823,0.043858648,-0.28849065,0.95647771},{0.99576245,-0.085887804,-0.03286922,0.080990036,0.98833579,-0.12896912,0.043562745,0.12576047,0.99110372},{0.99369142,-0.10580091,-0.037195027,0.099941118,0.9858831,-0.13433662,0.050882955,0.1297718,0.99023746},{0.99800688,-0.04836321,-0.040536357,0.042260043,0.98927204,-0.13983901,0.046864615,0.1378471,0.98934419},{0.99845078,-0.053455517,0.015445042,0.055290838,0.98430052,-0.16761686,-0.0062425302,0.16821115,0.98573122},{0.99645806,-0.073891156,-0.040142564,0.06488637,0.97926962,-0.19188742,0.05348916,0.18860307,0.98059563},{0.99364526,-0.061078649,-0.094543587,0.049000828,0.99092339,-0.12517887,0.10133119,0.11975065,0.98761925},{0.90088589,0.28801758,-0.32473134,-0.35917544,0.91472245,-0.18513733,0.24371626,0.28342321,0.92750942},{0.7565203,0.13966564,-0.63888226,-0.21535443,0.97564422,-0.041722781,0.61749461,0.16915026,0.76817227},{0.73015073,-0.12299635,-0.67212487,-0.090916236,0.95743089,-0.27397142,0.67721061,0.26114752,0.68788643},{0.75009386,-0.10348492,-0.65318457,-0.15242323,0.9340377,-0.32301815,0.64352655,0.34185447,0.68484239},{0.91115927,-0.41146198,0.022087014,0.4077214,0.89252882,-0.19275776,0.059599123,0.1846384,0.98099776},{0.93818965,-0.14472286,0.31441304,0.17512978,0.98201363,-0.070559953,-0.29854623,0.1212617,0.94666031},{0.92062154,-0.0093541095,0.39034419,0.1042393,0.96931682,-0.22261821,-0.37628483,0.24563632,0.89334911},{0.90661239,-0.16464518,0.38851768,0.28863528,0.91361011,-0.28636705,-0.3078048,0.3717638,0.87581276},{0.99648848,-0.046241868,-0.069802516,0.038611062,0.99351275,-0.10696543,0.07429596,0.10389466,0.99180946},{0.99951103,-0.023261949,0.02089435,0.024322414,0.99834983,-0.052019193,-0.019649811,0.052502021,0.9984275},{0.99951102,-0.02326251,0.020894176,0.024322963,0.99834979,-0.052019968,-0.019649595,0.052502786,0.99842744}},{{0.99564327,0.068949041,0.062773305,-0.060070208,0.98919385,-0.13374267,-0.071316412,0.12938919,0.98902599},{0.97489858,0.020236235,0.22172781,-0.064473314,0.97885246,0.19414185,-0.21311013,-0.20356413,0.95558659},{0.98693013,0.12823107,0.09759968,-0.062989345,0.86443416,-0.4987845,-0.14832814,0.48611769,0.86121328},{0.97292193,0.20983393,0.096915495,-0.080480246,0.70061486,-0.70898643,-0.21666987,0.68198867,0.69853106},{0.98311801,0.15061902,0.10388863,-0.04343331,0.74365843,-0.66714744,-0.17774279,0.65137244,0.7376459},{0.98894307,-0.1220349,-0.084255765,0.13553548,0.97436171,0.17958121,0.060180468,-0.18901522,0.98012835},{0.99754708,-0.062768907,-0.030981574,0.058140313,0.9894574,-0.13264147,0.038980747,0.13051483,0.99067977},{0.99387024,-0.10433147,-0.036562557,0.098396105,0.98557774,-0.13767614,0.050399265,0.1332346,0.98980227},{0.99813234,-0.047280446,-0.038682239,0.041142503,0.98836367,-0.1464396,0.045155924,0.14457459,0.98846305},{0.99925687,-0.03486942,0.016426724,0.037129824,0.98519918,-0.16734379,-0.010348388,0.16782939,0.98576174},{0.99842087,-0.049928807,-0.025746406,0.044087311,0.98046252,-0.1917017,0.034814854,0.19026392,0.98111548},{0.99728563,-0.023143697,-0.069898025,0.014188391,0.99192901,-0.12599814,0.072249981,0.12466442,0.98956492},{0.88803133,0.35510482,-0.29206316,-0.41664534,0.89013824,-0.18455499,0.19444026,0.28557744,0.93842344},{0.79352554,0.15002126,-0.58975477,-0.25687583,0.96113786,-0.10113777,0.551663,0.23174926,0.80122427},{0.78859367,-0.12717505,-0.60161983,-0.14270277,0.91381969,-0.38022291,0.59812717,0.38569422,0.70248417},{0.78905398,-0.085288209,-0.60837452,-0.25309486,0.85723254,-0.44843661,0.55976501,0.50781723,0.65481673},{0.92599905,-0.37382764,0.052712003,0.37647793,0.90398712,-0.20266145,0.028109376,0.20750945,0.97782911},{0.91129645,-0.14582136,0.38506485,0.1696918,0.98508353,-0.02854901,-0.37515815,0.091359193,0.92244778},{0.87624945,-0.0036507034,0.48184406,0.082642471,0.98629308,-0.14281521,-0.47471815,0.16496261,0.86454028},{0.85982188,-0.12794694,0.49430352,0.24229133,0.95439697,-0.17441727,-0.44944569,0.26973331,0.85161165},{0.99868649,-0.030573106,-0.041116784,0.025811072,0.99340265,-0.11173616,0.044261668,0.11052816,0.99288692},{0.99941752,-0.011310247,0.032197837,0.013407317,0.99775075,-0.065678471,-0.03138256,0.066071948,0.99732124},{0.99941752,-0.011310855,0.032197641,0.013407939,0.9977507,-0.065679299,-0.031382306,0.066072755,0.99732118}},{{0.99711589,0.056629388,0.050527446,-0.049970975,0.99096055,-0.12449932,-0.057121002,0.12161534,0.99093233},{0.97801511,0.02495992,0.20703492,-0.07567768,0.96760973,0.24084079,-0.19431762,-0.25121386,0.94822585},{0.98669475,0.12796677,0.10028944,-0.074876722,0.90519957,-0.4183386,-0.14431535,0.40526319,0.90273742},{0.9731214,0.20659704,0.10174679,-0.10094487,0.7797707,-0.61787359,-0.20698999,0.59099517,0.7796665},{0.98314332,0.14808808,0.10723399,-0.060002827,0.81534529,-0.57585739,-0.17271033,0.55971598,0.81048699},{0.98929099,-0.11782533,-0.086141805,0.12829139,0.98341018,0.12824106,0.069602811,-0.13791899,0.98799489},{0.9981394,-0.053516551,-0.029217018,0.04926177,0.9901861,-0.1307853,0.03592956,0.12910264,0.99098013},{0.99394499,-0.10390441,-0.035736304,0.097971115,0.98530605,-0.13990613,0.04974823,0.13555783,0.98951971},{0.99819871,-0.04701832,-0.03726167,0.040917635,0.98779328,-0.15030029,0.043873849,0.14850491,0.98793803},{0.99953813,-0.025632778,0.016324234,0.028008041,0.98546898,-0.16753042,-0.011792722,0.16791024,0.98573175},{0.9990698,-0.037776519,-0.02079568,0.033101422,0.98091161,-0.19161604,0.027637344,0.19074942,0.98124963},{0.99810681,-0.0044002333,-0.061346815,-0.003360703,0.99204551,-0.12583483,0.061412569,0.12580273,0.9901526},{0.87985897,0.38543052,-0.27801361,-0.44265092,0.87755188,-0.18429009,0.17294033,0.28521223,0.94273305},{0.81075869,0.15360893,-0.56486692,-0.27411538,0.95224669,-0.13448808,0.51723409,0.26387601,0.81414882},{0.81322618,-0.1222539,-0.56896145,-0.16507212,0.8890682,-0.42697638,0.55804516,0.44114793,0.702833},{0.80621465,-0.06871997,-0.58761847,-0.29388414,0.81550556,-0.4985808,0.51346867,0.57465477,0.63727689},{0.93229581,-0.3560826,0.063479994,0.36134199,0.90915394,-0.20705334,0.016015043,0.21597291,0.976268},{0.89689183,-0.14717244,0.41704358,0.16632451,0.98602301,-0.0097343642,-0.40978185,0.07809525,0.9088344},{0.85120892,-0.004959487,0.52480357,0.070505526,0.9919716,-0.10498256,-0.52006949,0.12636363,0.84472476},{0.82798296,-0.11357208,0.54913169,0.2146459,0.96888315,-0.12325829,-0.51804565,0.21992462,0.82659653},{0.99929533,-0.022850463,-0.029777499,0.019351987,0.9934185,-0.11289458,0.032161237,0.11223875,0.99316067},{0.99928371,-0.0038733914,0.037643847,0.0065581283,0.9974219,-0.071459861,-0.037269985,0.071655587,0.99673289},{0.99928372,-0.0038740229,0.037643636,0.0065587764,0.99742185,-0.071460697,-0.037269722,0.07165639,0.99673283}}},["hips"]={{0.001858209,-0.059579657,0.0020305252},{0.0036224984,-0.05778694,0.0022405433},{0.010671657,-0.051358832,0.0022141456},{0.019438679,-0.045034331,0.00030715942},{0.027330891,-0.041437453,-0.0043626594},{0.032671994,-0.040420188,-0.011848221},{0.036138198,-0.044594382,-0.019437255},{0.039428355,-0.053004721,-0.021266975},{0.042315308,-0.063024252,-0.017367096},{0.044435927,-0.072551726,-0.0094916342},{0.045498778,-0.08326782,-0.0039624213},{0.045298335,-0.094458044,-0.007605953},{0.043067395,-0.098992231,-0.012575397},{0.038877086,-0.095993421,-0.014945507},{0.033232173,-0.087161406,-0.011973133},{0.027153735,-0.078109053,-0.0075479124},{0.019925949,-0.068199385,-0.001622982},{0.011644042,-0.057826995,0.0036183738},{0.0028104234,-0.047855071,0.0069111441},{-0.0054979502,-0.039903487,0.0074871062},{-0.012004026,-0.034359626,0.0054289435},{-0.016681089,-0.031862144,0.0012449264},{-0.020152585,-0.033408508,-0.0029519843},{-0.02314465,-0.039627532,-0.005200157},{-0.026685275,-0.051051215,-0.0033684921},{-0.029235551,-0.06355213,0.0016288185},{-0.030119912,-0.077610014,0.0016376304},{-0.029676232,-0.089452894,-0.0030613136},{-0.028364384,-0.094699018,-0.0096987341},{-0.02496633,-0.091053808,-0.0094090078},{-0.019337098,-0.08456909,-0.0060919379},{-0.011726954,-0.075756987,-0.0022624206},{-0.0037500673,-0.066435698,0.00074842451},{0.0018496871,-0.059574164,0.0020222091}}},["Running"]={["duration"]=0.70833331,["frames"]={{{0.99384732,0.083720673,0.072514545,-0.060325282,0.95823884,-0.27953388,-0.092889013,0.27343953,0.95739357},{0.99275215,0.015812189,0.11913498,-0.044140651,0.96999564,0.23908169,-0.11178,-0.24260757,0.96366322},{0.97547306,0.036798634,0.21702114,0.20172705,0.24507685,-0.94828453,-0.08808248,0.96880504,0.23164252},{0.96178138,0.045730943,0.26997265,0.27282235,-0.0760202,-0.95905626,-0.023335206,0.99605704,-0.085591241},{0.95692564,-0.020212429,0.28962863,0.28222146,-0.16940087,-0.94427455,0.068149393,0.98533994,-0.15639967},{0.97600716,-0.15208515,-0.15582073,0.13342034,0.98327158,-0.1240001,0.17207271,0.10023533,0.97997138},{0.99339455,-0.11463028,0.0052128892,0.099286355,0.83587215,-0.53987025,0.057528167,0.53682177,0.84173213},{0.99435434,0.0049815633,0.10599357,0.053842534,0.83706194,-0.54445224,-0.091435418,0.5470854,0.83206802},{0.99201515,-0.03564101,0.12097783,0.059457251,0.97811527,-0.19938745,-0.11122384,0.20498839,0.97242431},{0.98992288,0.0077055069,0.14139776,0.045008544,0.92961879,-0.36576377,-0.13426439,0.36844204,0.91990409},{0.9850218,-0.023111842,0.17087396,0.073776638,0.95217732,-0.29650525,-0.15584951,0.30467064,0.93962052},{0.99082133,0.029031596,0.1320237,-0.0087459036,0.98838692,-0.15170634,-0.13489475,0.1491592,0.97956875},{0.95958139,0.26802913,-0.085813185,-0.28112366,0.92713941,-0.24775398,0.013155592,0.26186429,0.96501505},{0.99196392,-0.088946736,0.089977606,0.11888589,0.41198244,-0.90340282,0.043285613,0.90684014,0.4192462},{0.95578912,-0.0048361566,-0.29401315,-0.15354153,0.8445265,-0.51303026,0.25078306,0.53549196,0.80644665},{0.98857861,0.051454333,-0.14165014,-0.12180096,0.82630386,-0.54989681,0.088751555,0.56086934,0.82313347},{0.98948081,0.07528278,0.12353233,-0.038072459,0.95933778,-0.27968113,-0.13956439,0.27203588,0.95211251},{0.93107181,0.2831952,0.23001241,-0.22776303,0.94369456,-0.23992636,-0.2850074,0.17100028,0.94314881},{0.65447021,-0.52994354,0.53928525,-0.36077393,0.40794082,0.83870521,-0.66446291,-0.74346767,0.075795256},{0.85692777,-0.43641116,0.27426281,-0.1678325,0.26685388,0.94901067,-0.48734699,-0.8592638,0.15543049},{0.98612328,-0.0052588078,0.16593138,0.038652211,0.9793036,-0.19867175,-0.16145241,0.20232846,0.96591734},{0.99768927,-0.03395956,0.058846157,0.029806924,0.99709716,0.070062843,-0.061054591,-0.06814692,0.99580537},{0.99768929,-0.03395853,0.058846424,0.029806012,0.99709732,0.070060886,-0.061054711,-0.068145026,0.99580549}},{{0.99401226,0.082538367,0.071603238,-0.059466397,0.95838381,-0.27922072,-0.091669824,0.27329085,0.95755353},{0.99289003,0.016199219,0.1179278,-0.044618778,0.96911389,0.24254369,-0.11035647,-0.24608099,0.96294631},{0.97547855,0.036499653,0.21704681,0.20124529,0.25138284,-0.94673495,-0.089117347,0.96719929,0.23787314},{0.96188138,0.044440804,0.26983169,0.27244303,-0.070424275,-0.95959122,-0.023642303,0.99652669,-0.079847393},{0.9569169,-0.02148407,0.28956583,0.28234452,-0.16387985,-0.94521165,0.067760996,0.98624633,-0.15075355},{0.97608543,-0.15185645,-0.15555323,0.13257433,0.9829172,-0.12766302,0.17228241,0.10398762,0.97954345},{0.99346475,-0.11401481,0.0053276416,0.098839071,0.83601133,-0.53973699,0.057084026,0.5367362,0.84181683},{0.99444683,0.0040898426,0.10516055,0.054667042,0.83377957,-0.54938443,-0.0899276,0.55208242,0.82892579},{0.99213548,-0.036091567,0.11985231,0.060217314,0.97706474,-0.20425085,-0.10973172,0.20986161,0.97155392},{0.98984902,0.0083887083,0.14187512,0.044443467,0.92992186,-0.36506181,-0.13499519,0.36766148,0.92010941},{0.98494026,-0.022435296,0.17143321,0.073225715,0.95235456,-0.29607225,-0.15662274,0.3041668,0.93965519},{0.99071507,0.029521019,0.13271081,-0.0091556542,0.98841184,-0.15151965,-0.13564597,0.14889778,0.97950479},{0.95961591,0.26819896,-0.08489174,-0.28104401,0.9272099,-0.24758043,0.012311598,0.26144048,0.96514109},{0.99187699,-0.088591543,0.091276754,0.11986036,0.41072058,-0.90384856,0.042584151,0.9074471,0.41800283},{0.95597785,-0.0045702682,-0.29340312,-0.15334648,0.84470327,-0.51279755,0.25018213,0.5352155,0.80681673},{0.9887361,0.052159839,-0.14028624,-0.12163978,0.82616594,-0.55013964,0.087204462,0.56100741,0.82320477},{0.98934931,0.076286016,0.12396924,-0.038955854,0.95936516,-0.27946532,-0.14025118,0.27165958,0.95211908},{0.93074293,0.28401333,0.23033456,-0.22843278,0.94344829,-0.24025786,-0.28554541,0.17100238,0.94298567},{0.65233779,-0.53288001,0.53897513,-0.36257509,0.40506658,0.83932142,-0.66557858,-0.74293993,0.071031169},{0.85577872,-0.4369382,0.27699771,-0.17036437,0.26754505,0.94836476,-0.48848632,-0.85878081,0.15452059},{0.98601524,-0.005044951,0.16657878,0.038585426,0.97929301,-0.19873692,-0.16212682,0.20238517,0.9657925},{0.99768786,-0.033805008,0.05895895,0.029669291,0.99712928,0.069662936,-0.061144677,-0.06775258,0.99582676},{0.99768788,-0.033803978,0.058959215,0.029668368,0.99712945,0.06966099,-0.06114481,-0.067750674,0.99582687}},{{0.99980486,-0.017825453,-0.008514802,0.015037062,0.96625032,-0.25716569,0.012811532,0.25698748,0.96632981},{0.99662489,0.080230498,0.017375491,-0.077710848,0.85386628,0.51465852,0.026454971,-0.51427175,0.85721917},{0.98418256,0.027671107,0.17498288,0.10260711,0.71615429,-0.69035847,-0.14441774,0.69739325,0.70198731},{0.97454041,-0.064828427,0.21463522,0.22257162,0.39529998,-0.89117888,-0.027071587,0.91626151,0.39966481},{0.96129062,-0.13267763,0.24148914,0.27144303,0.30549679,-0.91268306,0.047318447,0.94290421,0.32968565},{0.98277561,-0.13963852,-0.1210499,0.075335106,0.90084598,-0.42755253,0.16875017,0.41106891,0.89584921},{0.99659126,-0.072507787,0.039350147,0.082314447,0.84223783,-0.53278493,0.0054888811,0.5342079,0.84533533},{0.99376744,-0.087553333,0.068997235,0.10153946,0.45556184,-0.88439426,0.045999197,0.88588817,0.46161264},{0.99449374,-0.09408432,0.046154645,0.10278689,0.78991634,-0.60453868,0.020419378,0.60595406,0.7952376},{0.98143391,0.067689269,0.17945934,-0.0093989116,0.9515044,-0.30749151,-0.19157019,0.30009589,0.93447488},{0.97597303,0.037767327,0.21459331,0.020303551,0.96481533,-0.26214335,-0.21694333,0.26020187,0.94086692},{0.97962287,0.075588211,0.18607922,-0.050032243,0.98911247,-0.13839541,-0.1945143,0.12626537,0.97273903},{0.9582771,0.28558477,-0.012096319,-0.2803814,0.93090088,-0.23411501,-0.055599187,0.22773866,0.97213365},{0.98109534,-0.050755243,0.18675008,0.19332472,0.30087165,-0.93386396,-0.0087891149,0.95231316,0.30499599},{0.96878448,0.020731758,-0.24703593,-0.14402625,0.85813924,-0.49280179,0.20177465,0.5129984,0.83433781},{0.99259511,0.11707392,-0.032382739,-0.1145535,0.81352764,-0.57013184,-0.040403259,0.56961965,0.82091473},{0.97388177,0.16415266,0.15687011,-0.1191492,0.95759066,-0.26234244,-0.19328159,0.23679958,0.95213875},{0.900311,0.35621033,0.25010865,-0.28859504,0.91871078,-0.26959864,-0.32581147,0.17054243,0.92992587},{0.46484637,-0.76260988,0.44982652,-0.52012116,0.175944,0.83577375,-0.71651362,-0.62247069,-0.31486271},{0.74403775,-0.44931038,0.49449765,-0.3908133,0.30762362,0.86754405,-0.54191578,-0.83874182,0.053287023},{0.97631804,0.018927195,0.2155107,0.026539238,0.97816329,-0.20613647,-0.2147062,0.20697427,0.95449614},{0.99784528,-0.012649255,0.064380239,0.010388186,0.99932152,0.03533508,-0.064783462,-0.034590119,0.99729967},{0.99784527,-0.01264822,0.064380484,0.010387268,0.99932161,0.035333108,-0.06478365,-0.034588231,0.99729972}},{{0.98235347,-0.13244229,-0.13206325,0.085871643,0.94665048,-0.31061056,0.16615571,0.29378886,0.94131843},{0.99302121,0.10205306,-0.059110366,-0.04424739,0.7869843,0.61538434,0.10932077,-0.60847422,0.7860077},{0.98749702,0.045889115,0.15081048,0.010238164,0.93600104,-0.35184832,-0.15730482,0.34899318,0.92382843},{0.98413818,-0.030432905,0.17477372,0.12334245,0.82547707,-0.55079419,-0.12750947,0.56361461,0.81613721},{0.97658381,-0.092875815,0.19405698,0.1946113,0.76588277,-0.61282141,-0.091708663,0.63623711,0.7660234},{0.98074769,-0.13417493,-0.14188393,0.031312697,0.82522132,-0.56394091,0.19275236,0.54864092,0.81353526},{0.99898072,-0.043467945,-0.012167015,0.021480066,0.69485994,-0.71882427,0.039700191,0.71783023,0.69508533},{0.97115817,-0.2384359,0.0003500981,0.0040163061,0.014890436,-0.99988112,0.23840229,0.97104404,0.015418638},{0.98815905,-0.15342083,0.0019260146,-0.014374283,-0.10506536,-0.99436146,0.15275806,0.98255958,-0.10602652},{0.97363673,0.11044318,0.19958418,-0.045878809,0.95190458,-0.30294024,-0.22344275,0.28579709,0.93187626},{0.96676758,0.089895239,0.23933094,-0.021604944,0.96151982,-0.27388474,-0.25474235,0.25961219,0.93150837},{0.96853221,0.11256337,0.2219794,-0.07928745,0.98495969,-0.15351842,-0.2359213,0.13108738,0.96289004},{0.96114691,0.27467218,0.027419391,-0.26098852,0.93660295,-0.23379453,-0.089897858,0.21755485,0.97189932},{0.97174464,-0.010482957,0.23580169,0.22934405,0.27810623,-0.93276908,-0.05579955,0.9604932,0.2726524},{0.98611959,0.023690826,-0.16433812,-0.10084846,0.87174019,-0.47947745,0.13190105,0.48939537,0.8620291},{0.9877635,0.12318439,0.095650534,-0.053166441,0.84252947,-0.53601997,-0.14661756,0.52437558,0.83876899},{0.95224756,0.21789582,0.21388313,-0.15957315,0.95238574,-0.25980309,-0.26030948,0.21326699,0.9416774},{0.8869593,0.3569089,0.29311997,-0.26128953,0.9111134,-0.31874753,-0.38082962,0.20612704,0.90137701},{0.36102553,-0.85976472,0.36119947,-0.53780447,0.12447338,0.83383015,-0.76185754,-0.49528875,-0.41744736},{0.63780795,-0.48228068,0.60050504,-0.4952423,0.34031733,0.79932418,-0.58986098,-0.80721086,-0.021788831},{0.96854799,0.039953098,0.24559839,0.01005125,0.97993754,-0.19905122,-0.24862376,0.19525926,0.94871494},{0.99777844,0.011086332,0.065690864,-0.012565732,0.99967567,0.022150405,-0.065423972,-0.022926617,0.99759415},{0.99777841,0.011087358,0.065691086,-0.012566636,0.99967571,0.022148436,-0.065424198,-0.022924718,0.99759417}},{{0.96788288,-0.17814044,-0.17739424,0.1134669,0.93920477,-0.32406738,0.22433903,0.29353089,0.92925326},{0.98740147,0.13491081,-0.082688738,-0.054275889,0.77962871,0.62388555,0.14863546,-0.61153749,0.77712895},{0.99243836,0.097071911,0.075120887,-0.097342928,0.99525089,-5.3650359e-05,-0.074769324,-0.0072591901,0.99717444},{0.99276291,0.1001991,0.066196009,-0.092641286,0.98974039,-0.10877289,-0.076415844,0.10185324,0.99186016},{0.99663429,0.029380715,0.076529888,-0.013827928,0.98044137,-0.19632496,-0.080801297,0.19460598,0.97754781},{0.97742549,-0.1370135,-0.16083107,0.015516513,0.80571672,-0.59209782,0.21070968,0.57623599,0.78965408},{0.99596215,-0.063399866,0.063559408,0.086624319,0.49280666,-0.8658163,0.023570069,0.86782608,0.49630872},{0.97689269,-0.19620878,0.084750906,0.035039277,-0.24414241,-0.96910615,0.21083839,0.9496824,-0.23162595},{0.99130063,-0.10892975,0.073873457,0.033809396,-0.33169215,-0.94278166,0.1272002,0.9370777,-0.3251239},{0.97134923,0.11577644,0.2075488,-0.048939559,0.95204065,-0.30203234,-0.2325631,0.2832215,0.93042999},{0.96318641,0.10397381,0.2479141,-0.032020239,0.95998664,-0.2782092,-0.26692067,0.26002903,0.92797534},{0.96344541,0.11192926,0.24340254,-0.074567705,0.98467586,-0.1576487,-0.25731808,0.13373595,0.95702774},{0.96314085,0.26611353,0.039284966,-0.24980292,0.93900275,-0.23637329,-0.099790823,0.21784724,0.97086784},{0.96836089,0.0129836,0.24921595,0.2282874,0.35731326,-0.90565562,-0.10080676,0.93389439,0.34304414},{0.99584416,0.013119124,-0.090123902,-0.050630802,0.90230724,-0.42811006,0.075703063,0.43089397,0.89922153},{0.98182793,0.044747895,0.18442235,0.031316931,0.92027431,-0.39001856,-0.18717159,0.38870664,0.90214958},{0.94150382,0.19149009,0.27731229,-0.1189075,0.95871608,-0.25831086,-0.31532771,0.21022613,0.92540445},{0.88305882,0.29710122,0.36323265,-0.15428899,0.91483752,-0.37318533,-0.44317265,0.27350174,0.85369477},{0.3484243,-0.86576305,0.35924202,-0.40897004,0.20444105,0.88935227,-0.84341207,-0.45679113,-0.28283894},{0.62620332,-0.51397557,0.58625809,-0.41476409,0.41710236,0.80870045,-0.66018184,-0.74956966,0.048012306},{0.96556608,0.050348028,0.25523956,-0.0055328238,0.98484682,-0.17333819,-0.26009908,0.16595727,0.95121324},{0.99758425,0.018443571,0.066973937,-0.021749164,0.99856353,0.048967929,-0.065974571,-0.050306288,0.99655237},{0.99758421,0.018444595,0.066974161,-0.021750063,0.9985636,0.048965967,-0.065974783,-0.050304383,0.99655246}},{{0.96327363,-0.18869874,-0.19104105,0.11662462,0.93485064,-0.33534012,0.24187311,0.30074419,0.92252389},{0.99166,0.12673468,-0.023425442,-0.086956541,0.79208522,0.60418505,0.095126124,-0.59710917,0.79649963},{0.98632961,0.15533185,0.055008266,-0.16416084,0.9552446,0.24608734,-0.014321169,-0.25175341,0.96768545},{0.97555345,0.2166538,0.036831769,-0.21963735,0.95555872,0.1966392,0.0074076647,-0.19992171,0.97978388},{0.98882795,0.14419914,0.037760723,-0.14736655,0.98378899,0.10218767,-0.022413254,-0.10661068,0.99404821},{0.98303533,-0.13189165,-0.12746001,0.029106746,0.79829433,-0.60156383,0.18109186,0.58764852,0.78859048},{0.99904611,-0.035112241,0.025960383,0.032578758,0.20347662,-0.97853764,0.029076181,0.97845002,0.20442648},{0.97813703,-0.20717429,0.018074389,-0.099950589,-0.54454994,-0.83275161,0.18236705,0.81273875,-0.55335168},{0.99202747,-0.12592137,0.0050204741,-0.078543951,-0.64895247,-0.75676388,0.098550713,0.75033626,-0.65366914},{0.97296069,0.13064962,0.19046831,-0.060718175,0.94031784,-0.3348368,-0.22284705,0.31421814,0.92282509},{0.96724595,0.11192093,0.2278354,-0.038763842,0.95214986,-0.30316337,-0.25086378,0.28440174,0.92530158},{0.9670751,0.091760626,0.23737257,-0.051999933,0.98430367,-0.16864846,-0.24912198,0.15075231,0.95666712},{0.9644366,0.26373788,0.017445723,-0.2512182,0.93517084,-0.24968962,-0.082167313,0.23642721,0.96816875},{0.97488216,0.0076210911,0.22259059,0.19415973,0.46056219,-0.86613194,-0.10911754,0.88759479,0.44751414},{0.99642739,0.020905829,-0.081824941,-0.043098026,0.95909486,-0.27978504,0.072628718,0.28231197,0.95656941},{0.96718607,-0.011422937,0.25381193,0.047169153,0.98969453,-0.13520304,-0.24965193,0.14273861,0.95775763},{0.93755958,0.1269046,0.32384756,-0.041005884,0.96490011,-0.25939607,-0.34539912,0.22991957,0.90985517},{0.8872137,0.24099395,0.39341314,-0.039461184,0.88924142,-0.45573276,-0.4596681,0.3888078,0.79845711},{0.39579285,-0.80838332,0.43573439,-0.20068952,0.38687369,0.9000291,-0.8961427,-0.44367248,-0.0091122844},{0.65161501,-0.49696491,0.5730827,-0.28369604,0.5410089,0.79172335,-0.70350156,-0.67848019,0.2115425},{0.96990936,0.064584548,0.23474381,-0.026433536,0.98640855,-0.16217103,-0.24202706,0.15108605,0.95843409},{0.99775649,0.026498238,0.061480346,-0.031291041,0.99643465,0.078350972,-0.059184949,-0.080098995,0.99502828},{0.99775645,0.026499244,0.061480556,-0.031291947,0.99643477,0.078348984,-0.059185134,-0.080097112,0.99502843}},{{0.97568914,-0.15705164,-0.15285781,0.097461144,0.93564419,-0.33922153,0.19629583,0.31607706,0.92820431},{0.98970916,0.10005105,0.10230141,-0.13946066,0.83451163,0.53304882,-0.032039598,-0.5418303,0.83987701},{0.96750351,0.18193492,0.17560372,-0.22205712,0.94351396,0.24591065,-0.1209448,-0.27691346,0.95325299},{0.94828118,0.27472022,0.15903325,-0.29548284,0.94700068,0.12601443,-0.11598585,-0.16648865,0.97919804},{0.96377448,0.21731401,0.15463941,-0.2288761,0.97153264,0.061156403,-0.13694707,-0.09433421,0.98607633},{0.99196043,-0.08359908,-0.095003077,0.015162211,0.82383457,-0.56662754,0.12563635,0.56063167,0.81847888},{0.99716729,-0.020510872,-0.072364048,-0.073953211,-0.091886852,-0.99301957,0.013718251,0.9955582,-0.093143398},{0.98164956,-0.16994578,-0.086500677,-0.18367413,-0.72070293,-0.66846928,0.051262138,0.67209063,-0.73869242},{0.98923609,-0.098350945,-0.108346,-0.14266839,-0.81282008,-0.56477365,-0.032519853,0.57415208,-0.8181027},{0.97632483,0.14234886,0.16287,-0.07333235,0.92617686,-0.36989022,-0.20349986,0.34918938,0.91468825},{0.97615567,0.1041385,0.19046075,-0.037432261,0.94502064,-0.32486122,-0.21381988,0.30998576,0.92638539},{0.97653019,0.056277564,0.20789813,-0.019570177,0.98445124,-0.17456451,-0.21448961,0.16639896,0.9624477},{0.96672275,0.25378984,-0.032214993,-0.25303974,0.93004534,-0.26643301,-0.037656543,0.26571861,0.96331492},{0.98877552,-0.021808212,0.14780867,0.13318424,0.57699945,-0.80581245,-0.067712124,0.81645338,0.57342725},{0.97856184,0.087090293,-0.18663342,-0.088285288,0.99609341,0.0019157687,0.18607108,0.014602345,0.98242773},{0.97595644,0.033227737,0.21541797,-0.050764664,0.9957847,0.076392614,-0.21197164,-0.085491381,0.97352927},{0.93724222,0.047347733,0.3454493,0.045965342,0.96531335,-0.25701614,-0.34563595,0.2567651,0.90255608},{0.91506411,0.20404716,0.34788271,0.037068188,0.81637073,-0.57633747,-0.40160137,0.54028108,0.73946781},{0.50232922,-0.66176381,0.5565375,0.013024618,0.64935463,0.76037422,-0.86457834,-0.37470953,0.33480898},{0.66894946,-0.36674121,0.64653498,-0.22668912,0.7277134,0.64733705,-0.70789738,-0.57959822,0.40366721},{0.97886013,0.07467548,0.19041123,-0.042446278,0.98486621,-0.16803827,-0.2000779,0.15640375,0.96721595},{0.99827973,0.029667467,0.050570891,-0.034767616,0.99405743,0.10315536,-0.047210013,-0.10473611,0.99337886},{0.99827969,0.029668465,0.050571096,-0.034768534,0.99405761,0.10315341,-0.047210189,-0.10473419,0.99337905}},{{0.98436443,-0.13916728,-0.1079775,0.094234149,0.93397653,-0.34468503,0.14881734,0.32912052,0.93248757},{0.98309231,0.10844342,0.14754517,-0.16673475,0.86321919,0.47649991,-0.075690517,-0.49304429,0.86670538},{0.96984531,0.19365188,0.14798325,-0.19482199,0.98081582,-0.006687309,-0.14643929,-0.022344734,0.98896725},{0.98170964,0.11958206,0.14814304,-0.097071763,0.98378037,-0.15084176,-0.16377813,0.1337023,0.97739471},{0.98643631,0.058798867,0.15325191,-0.024460447,0.97587126,-0.21697229,-0.16231182,0.21028072,0.96407305},{0.99345346,-0.042382481,-0.10608446,-0.009919434,0.89312022,-0.44970877,0.11380591,0.44781694,0.88685294},{0.98950811,-0.038132016,-0.13935409,-0.14438806,-0.2948693,-0.94456569,-0.0050730946,0.95477641,-0.29728134},{0.9852163,-0.085054799,-0.14870918,-0.16073318,-0.75927861,-0.63060361,-0.059275855,0.64518346,-0.76172483},{0.98286552,-0.015057837,-0.18370772,-0.11140791,-0.84253776,-0.52699004,-0.14684538,0.53842676,-0.82977892},{0.98375183,0.13824691,0.11454305,-0.081380397,0.91206874,-0.40188045,-0.16002987,0.38602902,0.90849987},{0.98832357,0.077930698,0.13093248,-0.029071957,0.93996806,-0.34002191,-0.1495705,0.33224517,0.93125818},{0.98859627,-0.003401542,0.1505518,0.030105373,0.98402724,-0.17545385,-0.14755027,0.17798543,0.97290807},{0.97973988,0.1738434,-0.099439352,-0.19541797,0.93849699,-0.28466691,0.043836153,0.29833182,0.95345506},{0.99532883,-0.090633466,0.033259919,0.088476081,0.71845612,-0.68992238,0.038634376,0.68964225,0.72311875},{0.8938066,0.25002575,-0.37228604,-0.069226099,0.89713064,0.43630771,0.44307739,-0.36420272,0.81916954},{0.98614682,0.15246539,-0.065335863,-0.12070711,0.92977025,0.34778899,0.11377311,-0.33508438,0.93529354},{0.93861885,-0.059374089,0.3398077,0.14923149,0.95801653,-0.24481475,-0.31100583,0.28049784,0.90807293},{0.96139054,0.13790588,0.23813891,0.059746205,0.74012741,-0.66980742,-0.26862375,0.65817438,0.70331192},{0.67188177,-0.4268421,0.60529383,0.15597568,0.88045229,0.44774474,-0.7240488,-0.20642037,0.65813679},{0.70383878,-0.07990964,0.70585086,-0.19053365,0.93600572,0.29595629,-0.68433041,-0.3427938,0.64357157},{0.99085511,0.058101907,0.12177979,-0.036166727,0.98387796,-0.17514605,-0.12999278,0.16913994,0.97698186},{0.99966224,0.015289893,0.021014834,-0.017844419,0.99170297,0.127306,-0.018894008,-0.12763804,0.99164083},{0.99966222,0.015290843,0.021015064,-0.017845339,0.99170319,0.12730405,-0.018894157,-0.12763608,0.99164109}},{{0.98667541,-0.14697181,-0.069791956,0.11324111,0.92834976,-0.3540384,0.116825,0.34141766,0.93262313},{0.9901727,0.07753618,0.11638804,-0.113883,0.93008251,0.34925237,-0.081170784,-0.35907475,0.92977233},{0.97573503,0.1939532,0.10160362,-0.16371391,0.95439388,-0.24966002,-0.14539223,0.22696807,0.96298835},{0.98667608,0.11228075,0.11774276,-0.093136216,0.9831816,-0.15709752,-0.13340154,0.14403824,0.98053912},{0.9914164,0.049617927,0.12096113,-0.020384862,0.97253684,-0.2318547,-0.1291433,0.22739869,0.96520039},{0.99453129,-0.0031432614,-0.10439129,-0.013846729,0.98675462,-0.16162811,0.10351667,0.16218966,0.98131486},{0.98427782,-0.049434302,-0.16956787,-0.17661842,-0.28483108,-0.9421663,-0.0017230618,0.95730222,-0.28908392},{0.98263292,0.029859615,-0.18314123,-0.10574064,-0.72093595,-0.68488705,-0.15248373,0.69235819,-0.70525817},{0.96716566,0.10167429,-0.23292201,-0.058194479,-0.80353932,-0.59240025,-0.24739405,0.58650397,-0.7712389},{0.99306756,0.1048067,0.05321996,-0.073215022,0.90572692,-0.41749051,-0.091958557,0.41069977,0.90712144},{0.99781706,0.033088085,0.057151399,-0.01095212,0.93635217,-0.35089125,-0.065124161,0.34949933,0.93467056},{0.99278399,-0.082238696,0.087274023,0.097695448,0.97672363,-0.19096217,-0.069538127,0.19811042,0.97770993},{0.99634556,0.0082015366,-0.085019177,-0.035578352,0.94476707,-0.32580568,0.077651272,0.32763992,0.94160628},{0.98534046,-0.15326901,-0.074918349,0.095391851,0.85907142,-0.50288842,0.14143761,0.48836975,0.86109834},{0.74658615,0.46789363,-0.47295303,0.12482059,0.59976174,0.7903833,0.65347462,-0.64912347,0.38937086},{0.85841223,0.30320362,-0.41375836,0.081663424,0.7155439,0.69377813,0.50641847,-0.62933653,0.58947079},{0.94284376,-0.17990441,0.28049951,0.25250446,0.9349903,-0.24906746,-0.21745609,0.30565918,0.92697649},{0.99308881,0.068757371,0.095115424,0.021601478,0.689498,-0.72396538,-0.11536005,0.72101669,0.68324746},{0.83731885,-0.22097111,0.50006893,0.19296714,0.97526064,0.10784404,-0.51152802,0.0061970515,0.85924425},{0.8043544,0.22426369,0.55019971,-0.12008003,0.96827923,-0.21912594,-0.58188909,0.11018696,0.80576917},{0.99906506,0.019626301,0.038520163,-0.011830378,0.98111708,-0.19305266,-0.041581699,0.19241643,0.98043198},{0.99987196,-0.0045827025,-0.015331886,0.0064890274,0.99191976,0.12670077,0.014627369,-0.12678406,0.99182248},{0.99987197,-0.0045818264,-0.015331606,0.0064880932,0.99192001,0.1266988,0.014627217,-0.12678211,0.99182274}},{{0.98883111,-0.14664217,-0.026628884,0.12886799,0.93099525,-0.3415273,0.07487367,0.33428122,0.93949454},{0.97908059,0.026289143,0.20176733,-0.054249398,0.98945105,0.13432659,-0.19610759,-0.14246231,0.9701785},{0.96927568,0.23370568,0.076722341,-0.18115291,0.88922322,-0.42007811,-0.16639789,0.39327306,0.90423896},{0.99314987,0.09780516,0.063933512,-0.084582249,0.97925275,-0.18414629,-0.080617524,0.17747723,0.98081736},{0.9969814,0.037270522,0.06811004,-0.023895541,0.9819622,-0.18756121,-0.073872,0.18536761,0.97988868},{0.99884137,-0.040971964,-0.025241051,0.045762589,0.9709558,0.23484176,0.014886129,-0.23572482,0.97170587},{0.98504857,0.020888072,-0.1710051,-0.17114571,0.0051175464,-0.98523253,-0.019704659,0.99976876,0.0086158813},{0.97707197,0.076468527,-0.19870226,-0.16157646,-0.34143723,-0.92591241,-0.13864766,0.93678881,-0.32125343},{0.95876423,0.15320169,-0.23937419,-0.15283956,-0.43215749,-0.88875208,-0.23960585,0.88868957,-0.39092199},{0.99728746,0.071489169,-0.017522144,-0.072718737,0.9201176,-0.38483189,-0.011388891,0.3850622,0.92282035},{0.99958958,0.00080522393,-0.028636096,-0.010465441,0.94077842,-0.33886049,0.026667347,0.3390211,0.94040074},{0.99127511,-0.13002047,0.0216411,0.13161515,0.96747772,-0.21601925,0.007149629,0.21698278,0.97614925},{0.99125819,-0.13174898,0.007031978,0.12566393,0.92655205,-0.35455572,0.040197014,0.35234004,0.93500843},{0.96982942,-0.18998056,-0.15276905,0.14426364,0.95240091,-0.26855254,0.19651735,0.23841118,0.95107359},{0.65185651,0.59535272,-0.46972136,0.36920632,0.29188621,0.88232036,0.66239716,-0.74857022,-0.029540053},{0.71506744,0.47855745,-0.50956964,0.37583803,0.35144179,0.85745816,0.58942725,-0.80465598,0.071444518},{0.96107438,-0.22788182,0.15622367,0.26484658,0.92090065,-0.28600401,-0.078691555,0.31624652,0.94540777},{0.99653391,0.0602621,-0.057347109,-0.082116534,0.60232966,-0.79401245,-0.013307168,0.79596956,0.60519038},{0.92545434,-0.100808,0.36520147,0.15366281,0.98097848,-0.11861219,-0.3462978,0.16588809,0.9233412},{0.9110448,0.3061107,0.27621306,-0.10498279,0.82006406,-0.56255977,-0.39871811,0.48351956,0.77925139},{0.99862138,-0.0082673108,-0.05183622,-0.0032342491,0.97595186,-0.21796216,0.052391606,0.2178293,0.97457966},{0.99927273,-0.0035639557,-0.037964534,0.00711679,0.99555976,0.093862288,0.037461428,-0.094064231,0.99486107},{0.99927275,-0.0035631191,-0.037964263,0.0071158519,0.99555994,0.093860341,0.037461238,-0.094062234,0.99486127}},{{0.99708047,-0.07473492,0.015659575,0.07585996,0.94614026,-0.31474417,0.0087062292,0.31501319,0.94904736},{0.96305282,0.011606056,0.2690624,0.025025418,0.99089168,-0.13231556,-0.26814735,0.13416027,0.95399057},{0.96786793,0.21274717,0.13405357,-0.10810714,0.83336683,-0.54204478,-0.22703424,0.51013563,0.8295885},{0.99548647,0.080572473,0.050147844,-0.045271657,0.86757439,-0.49524252,-0.08340987,0.49073696,0.86730616},{0.99806284,0.034180196,0.051983776,-0.012087863,0.92617649,-0.37689645,-0.061028532,0.37553803,0.9247955},{0.9958315,-0.07810857,0.04710286,0.050710832,0.90335556,0.42588399,-0.075815832,-0.42172005,0.90355085},{0.9773141,0.076609261,-0.19745427,-0.21166862,0.32108389,-0.92309345,-0.007318124,0.94394711,0.33001561},{0.97041413,0.091519058,-0.22342938,-0.23403455,0.12901251,-0.96363044,-0.0593654,0.98741075,0.14661421},{0.95395719,0.16199705,-0.25243345,-0.26162294,0.037795374,-0.96442985,-0.14669399,0.98606717,0.078437302},{0.99531773,0.039545111,-0.088197514,-0.064812432,0.94999465,-0.30546606,0.07170749,0.30975207,0.94810953},{0.99332556,-0.017933889,-0.11394168,-0.015839833,0.95727067,-0.28875936,0.11425162,0.28863686,0.95059735},{0.98877032,-0.14147656,-0.048141743,0.12786878,0.96765989,-0.21744868,0.07734874,0.20885097,0.97488381},{0.97594516,-0.20935758,0.060831221,0.21750034,0.91578567,-0.33768369,0.014988266,0.34279149,0.93929191},{0.94671802,-0.24838687,-0.20500955,0.2456577,0.9685687,-0.039077121,0.20827213,-0.013367264,0.97797956},{0.6176626,0.63670549,-0.46162652,0.54847898,0.071917642,0.83306587,0.56361668,-0.76774599,-0.3047987},{0.67839012,0.60938488,-0.4104107,0.48283348,0.051258232,0.87421076,0.55376771,-0.79121594,-0.25945831},{0.97554686,-0.21510772,0.045132494,0.21862859,0.9286108,-0.29980578,0.022580038,0.30234193,0.95293208},{0.98409971,0.066467668,-0.16471142,-0.17715812,0.43393004,-0.88335708,0.012758516,0.89849141,0.43880561},{0.95007272,-0.062312503,0.30574347,0.13580108,0.96476348,-0.22536525,-0.28092698,0.25563374,0.92505748},{0.96194073,0.25151523,0.10681843,-0.13960264,0.78837757,-0.59914264,-0.2349067,0.56142766,0.79348458},{0.99021096,-0.013012603,-0.13897098,-0.017209624,0.9766657,-0.2140746,0.13851388,0.21437065,0.96688114},{0.99870033,0.01592873,-0.048414238,-0.012887473,0.99796224,0.062492205,0.049311031,-0.061787058,0.99687049},{0.99870032,0.015929563,-0.048414013,-0.012888414,0.99796235,0.062490261,0.049310825,-0.061785035,0.99687063}},{{0.99565511,0.0062323513,0.092908988,0.02432921,0.94568933,-0.32416009,-0.089883311,0.32501204,0.94142879},{0.931813,0.0075960111,0.36285926,0.15376735,0.89735428,-0.41365558,-0.32875543,0.44124549,0.83499834},{0.95442545,0.14327925,0.26180747,0.045814541,0.79649039,-0.60291302,-0.29491202,0.58743011,0.75362637},{0.95000071,0.17319343,0.25981281,0.11910804,0.56815714,-0.81425471,-0.28863805,0.80448836,0.51912093},{0.9578975,0.10552278,0.26701559,0.1396064,0.64147529,-0.75433383,-0.25088331,0.75985156,0.59973589},{0.99439375,-0.082310691,0.066377771,0.032205603,0.83367388,0.55131724,-0.10071669,-0.54608867,0.83165095},{0.98016172,0.078620876,-0.18193858,-0.19139654,0.61389621,-0.76583214,0.051481074,0.78546176,0.6167654},{0.97095295,0.0098416726,-0.23906774,-0.21716355,0.45571152,-0.86323063,0.10045035,0.89007307,0.44461182},{0.96466377,0.071372905,-0.25363271,-0.26158321,0.37483502,-0.88942286,0.031589789,0.9243401,0.38025985},{0.99102756,-0.014715313,-0.13284517,-0.019069027,0.96818667,-0.24950142,0.13229036,0.24979596,0.95921906},{0.98432074,-0.053244563,-0.16815979,0.010092587,0.96879136,-0.24767207,0.17609888,0.24209154,0.95413879},{0.9827916,-0.15584675,-0.099158921,0.13306437,0.96964506,-0.20513975,0.12811927,0.18841508,0.97369667},{0.96364069,-0.25934379,0.064323448,0.26649762,0.91537678,-0.30176873,0.019381669,0.30793856,0.95120877},{0.9087599,-0.32189577,-0.26559107,0.36296722,0.92372916,0.12238943,0.20593764,-0.2076235,0.95628561},{0.5588278,0.7036974,-0.43877273,0.67783383,-0.082778918,0.73054022,0.47775803,-0.70566111,-0.52324903},{0.67387224,0.67572543,-0.29881668,0.46240879,-0.070275799,0.88387751,0.57625885,-0.73379593,-0.35981826},{0.97956826,-0.20058021,-0.014616552,0.18804752,0.93927934,-0.28704084,0.071303496,0.27842756,0.95780681},{0.97086968,0.039030503,-0.2364076,-0.23849206,0.25251645,-0.93774033,0.023096081,0.9668052,0.25446896},{0.96493807,-0.065127587,0.25426972,0.13677066,0.95157872,-0.27530296,-0.22402797,0.30042699,0.92712185},{0.98693741,0.16084518,-0.0091286482,-0.14459913,0.85941978,-0.49039666,-0.071032818,0.48531074,0.8714515},{0.98032693,-0.012027005,-0.19701387,-0.026552033,0.98103383,-0.19200946,0.19558651,0.19346313,0.96141454},{0.99819473,0.02650862,-0.053894076,-0.024431139,0.99894642,0.038848457,0.05486707,-0.03746167,0.99779066},{0.99819472,0.026509459,-0.053893903,-0.024432092,0.99894646,0.038846497,0.054866873,-0.037459653,0.99779076}},{{0.97882029,0.06496099,0.19414151,0.0027498995,0.9440629,-0.32975396,-0.20470294,0.32330375,0.92388927},{0.9375004,0.037453565,0.34596281,0.1767357,0.80517417,-0.56609103,-0.29976243,0.59185453,0.7482317},{0.94669643,0.10127428,0.30579308,0.16434459,0.66460463,-0.7288975,-0.27705004,0.7403001,0.61253488},{0.93776437,0.19401515,0.28802106,0.27306973,0.10043249,-0.95673729,-0.21454815,0.97584396,0.041202335},{0.94615563,0.13733199,0.29313724,0.29637394,-0.003279228,-0.95506636,-0.13019986,0.99051965,-0.043804355},{0.98959358,-0.10974358,0.093063756,0.026444069,0.77445849,0.63207178,-0.14143979,-0.62303323,0.76930126},{0.99425171,0.036604138,-0.10061618,-0.082201212,0.8631093,-0.49828231,0.068603613,0.50368884,0.86115689},{0.98358848,-0.047378687,-0.17409443,-0.081741421,0.74318735,-0.66407148,0.16084771,0.66740379,0.72711777},{0.98296454,0.013889166,-0.18326946,-0.14335082,0.6819889,-0.71717619,0.11502683,0.73123063,0.67236204},{0.98675798,-0.063380911,-0.14930361,0.026951103,0.97176584,-0.23440301,0.15994479,0.22727518,0.96060588},{0.97750042,-0.095784532,-0.18793153,0.049157403,0.96986482,-0.23863314,0.2051255,0.2240258,0.95275179},{0.97539165,-0.17820669,-0.1298211,0.14938545,0.96722414,-0.20533254,0.1621577,0.18088631,0.97004382},{0.95978455,-0.27948724,0.026468073,0.27465887,0.91530651,-0.29457839,0.058104553,0.29000151,0.9552607},{0.86512849,-0.36240799,-0.34671788,0.42862326,0.89320862,0.13586908,0.26045146,-0.26615544,0.92807664},{0.46020447,0.80518768,-0.37401166,0.73907972,-0.11404,0.66389453,0.49190736,-0.58195169,-0.64757965},{0.66016359,0.70078197,-0.27034918,0.3897139,-0.011874543,0.92085946,0.64211135,-0.71327667,-0.28094363},{0.97918144,-0.19397009,-0.059827356,0.16953464,0.94357232,-0.28448073,0.11163212,0.26841549,0.95681314},{0.95152502,-0.041528537,-0.30475492,-0.29268696,0.18224612,-0.93868023,0.094522301,0.9823756,0.16125689},{0.98887696,-0.054010532,0.13858328,0.093707583,0.94980068,-0.29849197,-0.11550483,0.30815813,0.94429721},{0.97757074,0.11245826,-0.17806908,-0.17991901,0.88542729,-0.42854125,0.10947418,0.45096736,0.88580126},{0.97508122,-0.022629915,-0.22069102,-0.019019201,0.98259412,-0.18478919,0.22103142,0.18438188,0.95767867},{0.99784367,0.02016486,-0.062461059,-0.018994867,0.99963388,0.019268711,0.062826729,-0.0180407,0.99786139},{0.99784367,0.020165697,-0.062460899,-0.018995833,0.99963391,0.019266763,0.062826538,-0.018038664,0.99786143}},{{0.95925797,0.12910136,0.25131055,-0.040748628,0.94341372,-0.329105,-0.27957773,0.30545602,0.91023784},{0.96754607,0.095607012,0.23391008,0.076070122,0.77252346,-0.6304132,-0.24097294,0.62774741,0.7401792},{0.98910489,0.13243233,0.064290263,-0.0013073927,0.44460175,-0.89572736,-0.14720668,0.88588428,0.43993098},{0.99001447,0.1311792,0.051608172,0.084155494,-0.25629224,-0.96292892,-0.11308934,0.95765668,-0.26477252},{0.99622092,0.050859841,0.070407165,0.083841945,-0.35143692,-0.93244981,-0.022680395,0.93482906,-0.35437295},{0.97500285,-0.16534723,0.14842418,0.033683341,0.77026984,0.63682789,-0.21962443,-0.6159096,0.75658476},{0.99957679,-0.029090371,4.188008e-05,0.028743847,0.98744577,-0.15532104,0.0044769816,0.15525653,0.98786405},{0.98309963,-0.16498218,-0.079347285,0.12763985,0.92840848,-0.34894951,0.13123716,0.33292427,0.93377634},{0.99187881,-0.09770472,-0.08142603,0.055241389,0.90761563,-0.41615169,0.11456354,0.408274,0.90564208},{0.98539999,-0.083238192,-0.14852022,0.045012025,0.96866828,-0.24424515,0.16419735,0.23399396,0.95827243},{0.97501041,-0.12273294,-0.1851792,0.07383568,0.96518227,-0.2509412,0.20953043,0.23099744,0.95012482},{0.96988555,-0.19324661,-0.14824905,0.15869135,0.96312764,-0.21726069,0.18476765,0.18719212,0.96479014},{0.95730261,-0.28398897,-0.054056095,0.25341436,0.91435295,-0.31581599,0.1391147,0.28863289,0.94727936},{0.83931309,-0.35977528,-0.40757258,0.38914154,0.92110329,-0.011724551,0.37963471,-0.14876283,0.91309753},{0.37868484,0.85792248,-0.34722742,0.67285112,0.0024142709,0.73977389,0.63550696,-0.5137736,-0.57633986},{0.63179205,0.69757173,-0.33798301,0.30313867,0.17894851,0.93599377,0.71340433,-0.69380917,-0.098402737},{0.97674892,-0.19716524,-0.084186854,0.16474633,0.9415763,-0.29375624,0.13718677,0.27305666,0.95216586},{0.92834688,-0.11330747,-0.35402479,-0.31873157,0.24741299,-0.91498462,0.19126468,0.96226212,0.19357042},{0.99908175,-0.032997989,0.027329949,0.038792536,0.96746923,-0.24999667,-0.018191588,0.25082729,0.96786088},{0.94445298,0.11681487,-0.3071853,-0.24067053,0.88233945,-0.40441917,0.2237994,0.4558852,0.8614421},{0.97449456,-0.04087683,-0.22065682,-0.00076506764,0.98265959,-0.18541724,0.22440981,0.18085688,0.95756515},{0.99730263,0.014236363,-0.072005497,-0.012411231,0.99959186,0.025731205,0.072342455,-0.024768153,0.99707226},{0.99730263,0.014237204,-0.07200534,-0.012412218,0.99959189,0.025729243,0.072342292,-0.024766126,0.99707233}},{{0.93550417,0.17818106,0.30509589,-0.065976386,0.93643172,-0.34459069,-0.34710097,0.30223689,0.88779149},{0.96691961,0.11463045,0.22787365,0.061470964,0.76229557,-0.64430332,-0.24756374,0.63699715,0.73003203},{0.98728474,0.15712375,-0.024103506,-0.050520498,0.1663763,-0.98476726,-0.15071985,0.97346349,0.17219869},{0.99144183,0.11558401,-0.060691286,0.021396582,-0.60247318,-0.79785228,-0.12878361,0.78972551,-0.5997903},{0.99895339,0.027257572,-0.036730276,-0.0073753015,-0.6965367,-0.71748329,-0.045140592,0.71700324,-0.69560669},{0.9635308,-0.20842204,0.16783508,0.063682968,0.78776799,0.61267134,-0.25990914,-0.57963946,0.77231164},{0.99219183,-0.10097522,0.073207455,0.081800869,0.96994043,0.22918156,-0.094148376,-0.22140372,0.97062687},{0.96939676,-0.24140462,0.044649916,0.24092427,0.97041334,0.015926173,-0.047173349,-0.0046816167,0.99887571},{0.98423172,-0.17230416,0.039988269,0.17353265,0.98438382,-0.029579618,-0.034267001,0.036052375,0.99876228},{0.98753735,-0.095158211,-0.12535906,0.05680682,0.95833228,-0.27995041,0.1467752,0.26934022,0.95179456},{0.97732821,-0.14089356,-0.15804612,0.09244089,0.95549296,-0.28015691,0.19048425,0.25919531,0.94685455},{0.97005794,-0.1945093,-0.14544322,0.15972168,0.96203792,-0.22129623,0.18296606,0.19143975,0.96429987},{0.95583273,-0.24410439,-0.1636974,0.18048274,0.92706678,-0.32859272,0.23196932,0.28453513,0.9301774},{0.85542824,-0.31256302,-0.41297313,0.23441912,0.94467776,-0.22941591,0.46183346,0.099440117,0.8813748},{0.37600187,0.82033346,-0.43090093,0.449479,0.24518332,0.85898419,0.81030315,-0.51666052,-0.27653325},{0.59320756,0.67022276,-0.44598912,0.20723134,0.40819423,0.8890628,0.77792023,-0.61982166,0.1032528},{0.97722692,-0.20372905,-0.05934648,0.17885556,0.94130723,-0.28627168,0.11418513,0.26913785,0.9563088},{0.92554581,-0.11931174,-0.35934596,-0.29033766,0.38554946,-0.87581722,0.243041,0.91494059,0.32220303},{0.99973191,-0.020808809,0.010140814,0.021814972,0.99346213,-0.11205935,-0.0077426052,0.11225048,0.99364981},{0.94523937,0.17538665,-0.27524851,-0.25825487,0.91759641,-0.30219453,0.19956618,0.35673039,0.91264276},{0.97841476,-0.055371724,-0.19909426,0.021722657,0.98565384,-0.16737573,0.20550589,0.15943803,0.96558109},{0.99723386,0.015240489,-0.072748569,-0.0099741895,0.99733938,0.072212801,0.073655568,-0.07128746,0.9947326},{0.99723386,0.015241349,-0.072748408,-0.0099752044,0.99733951,0.072210859,0.073655444,-0.071285419,0.99473276}},{{0.93922169,0.18590796,0.28861893,-0.071935653,0.92859897,-0.36404559,-0.33569021,0.32115753,0.88553369},{0.97011012,0.10224054,0.22007556,0.06416176,0.76656492,-0.63895342,-0.23402917,0.63397559,0.73709244},{0.98929492,0.14536581,-0.012821048,0.0028128845,-0.10683679,-0.99427258,-0.14590309,0.98359273,-0.10610199},{0.99525334,0.095237367,-0.020017063,0.059366477,-0.75712988,-0.65056127,-0.077113346,0.64628485,-0.75918994},{0.99989011,0.012100852,0.0085672845,0.014814643,-0.8386107,-0.54452974,0.00059526102,0.54459679,-0.83869774},{0.96886971,-0.19009344,0.15860629,0.069458656,0.82363607,0.56284908,-0.23762772,-0.53431089,0.81119972},{0.99330251,-0.11313384,0.023469763,0.091291695,0.89296829,0.44076462,-0.070823078,-0.43567007,0.89731585},{0.97272004,-0.23135424,-0.017055163,0.23052981,0.97222836,-0.04034818,0.025916301,0.03531576,0.99904016},{0.97974882,-0.19449712,-0.047571585,0.1988347,0.97306434,0.11666412,0.023599453,-0.12376047,0.9920315},{0.99199868,-0.09233494,-0.086098049,0.059719785,0.94404732,-0.32435814,0.11123019,0.31662111,0.94200792},{0.98427481,-0.13709044,-0.11139715,0.096553069,0.94562143,-0.31060843,0.14792094,0.29496833,0.94398786},{0.97862845,-0.16703636,-0.11993845,0.1384948,0.96651762,-0.21601592,0.1520051,0.19478849,0.9689953},{0.95717914,-0.15015596,-0.24751023,0.064731306,0.94433203,-0.32256291,0.2821665,0.29272888,0.91361473},{0.89722878,-0.24770965,-0.36554126,0.073877757,0.90037177,-0.42880385,0.43534198,0.35772983,0.82613968},{0.47711116,0.68126765,-0.55519311,0.15327509,0.55754585,0.81587338,0.8653737,-0.47435947,0.16159015},{0.58410068,0.62025345,-0.52355719,0.053000797,0.61450612,0.78712966,0.80994893,-0.48751186,0.32605965},{0.98183946,-0.18940927,-0.010742731,0.17913849,0.94426293,-0.27618269,0.06245545,0.26924272,0.96104511},{0.94559339,-0.086161767,-0.31373461,-0.22964413,0.50632974,-0.83120016,0.23047066,0.85802475,0.45899538},{0.99507113,-0.039282146,0.091051789,0.032772768,0.99687208,0.071916297,-0.093592007,-0.068577749,0.99324599},{0.96252225,0.26327654,-0.065087045,-0.26563228,0.96359149,-0.030512017,0.054684218,0.046657683,0.99741301},{0.98654483,-0.058654861,-0.15260706,0.036306585,0.98871995,-0.14530894,0.15940869,0.13781316,0.97754611},{0.99803796,0.016324906,-0.060446088,-0.009186639,0.9931436,0.11653919,0.061934129,-0.11575523,0.99134499},{0.99803796,0.016325807,-0.060445912,-0.0091876779,0.9931438,0.11653744,0.061934029,-0.11575342,0.99134521}},{{0.94967517,0.172194,0.26166063,-0.066497609,0.92713409,-0.36878236,-0.30609662,0.33282366,0.89192673},{0.98057953,0.10540358,0.16539015,0.016637583,0.79555552,-0.6056522,-0.19541496,0.59664183,0.77835179},{0.98998342,0.13637836,-0.03652041,0.012469368,-0.34212275,-0.93957254,-0.14063165,0.92970589,-0.3403964},{0.9984923,0.044774714,-0.031753653,0.015802367,-0.78846388,-0.61487801,-0.052567418,0.61344927,-0.78798271},{0.99917682,-0.040462857,0.0028886214,-0.033304936,-0.85890279,-0.51105456,0.023159963,0.51053771,-0.85954347},{0.98660992,-0.15532553,0.049747837,0.11481469,0.87807482,0.46454516,-0.11583803,-0.45261308,0.88415098},{0.98909347,-0.13117636,-0.066983995,0.14654844,0.922013,0.35835118,0.014752916,-0.36425925,0.93118074},{0.97558994,-0.21158821,-0.058776658,0.19165099,0.95103017,-0.24251089,0.10721082,0.22532657,0.96836654},{0.98209703,-0.16747594,-0.086239502,0.16133246,0.98412881,-0.073907517,0.097248506,0.058671104,0.99352928},{0.99622426,-0.077412512,-0.039300549,0.056996375,0.924647,-0.376536,0.06548767,0.37287428,0.925568},{0.99251688,-0.10957218,-0.05389052,0.084300199,0.93415293,-0.34677341,0.088338644,0.33963546,0.9363995},{0.99061867,-0.11182149,-0.078553288,0.091586537,0.96988917,-0.22566991,0.10142267,0.21635837,0.97103166},{0.96082619,-0.035985524,-0.27480546,-0.057772399,0.94374884,-0.32557708,0.27106347,0.32869921,0.90469968},{0.94367653,-0.19075557,-0.27034553,-0.0057700565,0.80746484,-0.58988763,0.33081903,0.5582231,0.76088486},{0.65578096,0.44247938,-0.61168884,-0.081423119,0.84696353,0.52537905,0.75054756,-0.29472799,0.59145057},{0.67816903,0.49764559,-0.54077302,-0.14315655,0.81119907,0.56697653,0.72082807,-0.30709079,0.62137123},{0.9877755,-0.15295906,0.030050582,0.15490398,0.94158401,-0.29903893,0.017445409,0.30003845,0.95376761},{0.97376519,-0.027472668,-0.22589055,-0.16778029,0.58392443,-0.79428088,0.15372387,0.81134311,0.56399586},{0.97108295,-0.092360275,0.2201529,0.035866797,0.9681102,0.24794376,-0.23603232,-0.23287775,0.94342832},{0.95457967,0.21246255,0.20889489,-0.28010621,0.87891634,0.38606541,-0.10157655,-0.42704303,0.89850808},{0.99536042,-0.046253044,-0.084370007,0.032847951,0.987546,-0.15386328,0.090435843,0.150378,0.98448352},{0.99938582,0.015582446,-0.031387521,-0.011967923,0.99361122,0.11222092,0.032935602,-0.11177638,0.99318743},{0.99938581,0.01558342,-0.031387334,-0.011968969,0.99361141,0.11221896,0.032935504,-0.11177441,0.99318767}},{{0.9662283,0.1521812,0.20795127,-0.066792162,0.92731441,-0.36827542,-0.24888083,0.34194862,0.90616196},{0.97460041,0.048921403,0.21854228,0.07065408,0.85884437,-0.50734044,-0.21251362,0.50989515,0.8335736},{0.98338322,0.17166183,0.059072709,0.13597066,-0.48084374,-0.86619929,-0.12028848,0.85983813,-0.49619472},{0.99363285,0.10609828,0.037905667,0.10267851,-0.71426892,-0.69229837,-0.04637666,0.69178256,-0.72061514},{0.99770252,0.026263112,0.06244841,0.058736178,-0.79467329,-0.60418906,0.033758374,0.60646897,-0.79439026},{0.98276139,-0.17575227,-0.05736869,0.18173259,0.86135258,0.47438908,-0.033960272,-0.47663704,0.878444},{0.99068218,-0.1356364,0.012312048,0.13602637,0.98989539,-0.040048577,-0.0067555968,0.041350265,0.9991219},{0.99535984,-0.094890136,0.015957587,0.096221294,0.98241194,-0.16002557,-0.00049208236,0.16081851,0.98698391},{0.99961408,-0.026913529,0.0068799503,0.027750177,0.97873911,-0.2032232,-0.0012642064,0.20333573,0.97910828},{0.99718695,-0.074305295,0.0098438125,0.071440152,0.90245789,-0.42481297,0.02268227,0.42432121,0.90522762},{0.99580596,-0.091154668,0.0078304201,0.087359873,0.92193322,-0.37736904,0.027179868,0.37647041,0.92602985},{0.997694,-0.061246564,-0.02924962,0.052582463,0.96996922,-0.23747588,0.042915854,0.23539021,0.97095297},{0.95924568,0.089206289,-0.268123,-0.17829708,0.92720534,-0.32939405,0.21922109,0.36377534,0.90532293},{0.97636162,-0.13979396,-0.16485031,-0.017918979,0.70771262,-0.70627319,0.21539935,0.69253195,0.68847845},{0.82442983,0.18818933,-0.53376047,-0.18043326,0.98128333,0.067282126,0.53643197,0.040838747,0.84295487},{0.83821936,0.286665,-0.46390892,-0.23585766,0.95758093,0.16555953,0.49169041,-0.029358731,0.870275},{0.9920846,-0.11184613,0.057084006,0.12450649,0.93523125,-0.33142219,-0.016318509,0.33590617,0.94175407},{0.99235505,0.072840483,-0.09962795,-0.12186752,0.70581063,-0.69783935,0.019487429,0.7046458,0.70929151},{0.92755682,-0.14982379,0.34233198,-0.00078224407,0.91532404,0.40271737,-0.37368134,-0.37381098,0.84889788},{0.95079349,-0.06107607,0.30374565,-0.20545142,0.60953548,0.76567372,-0.23190813,-0.79040252,0.56699423},{0.99948855,-0.029313104,-0.012782546,0.026531466,0.9832575,-0.18027972,0.017853125,0.17984834,0.98353232},{0.99995829,0.0081559501,0.0041120587,-0.008479254,0.99626353,0.0859482,-0.0033956712,-0.085979511,0.99629111},{0.99995828,0.008157005,0.0041122638,-0.0084803091,0.99626368,0.085946239,-0.0033957948,-0.085977567,0.99629129}},{{0.98044759,0.11447226,0.16005813,-0.052241853,0.93561563,-0.34913345,-0.18971901,0.33394533,0.92330235},{0.96615073,-0.024304449,0.25683075,0.10093034,0.95180836,-0.28960996,-0.23741485,0.30572887,0.92204341},{0.96615421,0.13497345,0.21983663,0.25669589,-0.41859732,-0.87113918,-0.025557533,0.89808603,-0.43907675},{0.95163378,0.23116702,0.20237319,0.30124309,-0.57260688,-0.76247882,-0.060379575,0.78656418,-0.61454956},{0.96350735,0.16766661,0.20866582,0.26677681,-0.66551211,-0.69708231,0.021992302,0.72731117,-0.68595546},{0.97994734,-0.16888163,-0.10574504,0.19560057,0.91651592,0.34891123,0.037992534,-0.36259848,0.93117079},{0.99032893,-0.12789433,0.053773305,0.13819982,0.94350551,-0.30116147,-0.012218422,0.30568032,0.95205582},{0.99499948,-0.073842047,0.067255005,0.088010418,0.9665687,-0.24083031,-0.047222963,0.24554511,0.96823428},{0.99791063,-0.022664961,0.060501982,0.034525061,0.97860001,-0.20285478,-0.054609343,0.20451975,0.97733805},{0.99658719,-0.062999125,0.053339466,0.080023728,0.89587906,-0.43703196,-0.020253056,0.43980885,0.897863},{0.99493696,-0.077541661,0.063935454,0.095840019,0.92353264,-0.37135182,-0.030251218,0.37559919,0.92628834},{0.99936903,-0.02757629,0.02238518,0.031812042,0.97524667,-0.21881938,-0.015796823,0.2193934,0.97550858},{0.95731467,0.18124245,-0.22516607,-0.24674988,0.91814488,-0.31003952,0.15054278,0.3523651,0.92367512},{0.99044386,-0.11212691,-0.08030281,0.0065601934,0.6198999,-0.78465352,0.13776052,0.77662842,0.61471151},{0.91580754,0.033174446,-0.40024494,-0.17041265,0.93451829,-0.31246627,0.36367023,0.35436582,0.86149217},{0.94094195,0.089105645,-0.32663198,-0.1739609,0.9548983,-0.24063847,0.29045801,0.28324811,0.9140047},{0.99527312,-0.056421069,0.079044761,0.079504557,0.94078759,-0.32954167,-0.055771223,0.3342684,0.94082635},{0.98514135,0.1621605,0.056572515,-0.11443116,0.86538286,-0.48787091,-0.12807036,0.47414822,0.87108065},{0.87227461,-0.21104637,0.44113085,-0.085412767,0.82245971,0.56237415,-0.48149937,-0.5282229,0.69938468},{0.92448452,-0.32862606,0.19321799,-0.076115273,0.33751684,0.93823714,-0.37354351,-0.88209254,0.28701565},{0.99849618,-0.022082422,0.050177099,0.031230313,0.98136927,-0.18957594,-0.045055942,0.19085785,0.9805831},{0.99948778,-0.011916455,0.029701588,0.0093915844,0.99644324,0.083741832,-0.030593829,-0.083420035,0.99604473},{0.99948778,-0.011915345,0.029701837,0.0093905241,0.9964434,0.083739895,-0.030593963,-0.083418101,0.99604489}},{{0.98900618,0.096792999,0.11179405,-0.057744852,0.94877933,-0.31061763,-0.13613349,0.30074723,0.94393791},{0.97919181,-0.028237681,0.20096282,0.022713676,0.99929953,0.029741016,-0.20166186,-0.024557542,0.97914729},{0.96975924,0.064091956,0.23549793,0.2417996,-0.12117832,-0.96272981,-0.033165985,0.99055948,-0.13301124},{0.95398449,0.12895769,0.27070939,0.29944342,-0.36236949,-0.8826222,-0.015724055,0.92307001,-0.3843104},{0.95608822,0.066072678,0.28553421,0.28361657,-0.45414853,-0.84457722,0.073871496,0.88847257,-0.45294537},{0.97751044,-0.14986901,-0.14836637,0.16915106,0.97734682,0.12720513,0.12594133,-0.14944066,0.98071723},{0.99161627,-0.12862878,0.012320907,0.11919612,0.87372758,-0.47158504,0.049894232,0.4691,0.8817345},{0.99439897,-0.033465306,0.10025355,0.070718404,0.9156056,-0.39580974,-0.078546843,0.40068255,0.91284382},{0.99455493,-0.024560239,0.10127829,0.044852513,0.97809652,-0.203262,-0.09406779,0.20669782,0.9738723},{0.99445781,-0.028086564,0.10131542,0.067090113,0.9114776,-0.40584171,-0.080948047,0.41038974,0.90831035},{0.99093989,-0.052296321,0.1237062,0.090922952,0.93912745,-0.33131953,-0.098849112,0.33956549,0.9353738},{0.99660645,0.0017970123,0.082294288,0.0129233,0.98394731,-0.17799068,-0.081293115,0.17845021,0.98058501},{0.96097513,0.23293815,-0.1492202,-0.26643001,0.92448953,-0.27264271,0.074443632,0.30175971,0.95047319},{0.99456553,-0.1037564,0.0086004515,0.06123792,0.51618903,-0.85428259,0.08419795,0.85016679,0.51973766},{0.94668489,-0.013604396,-0.32187371,-0.15074799,0.86427216,-0.47990486,0.28471541,0.50284053,0.81614245},{0.97657543,0.020974328,-0.21415073,-0.12151337,0.87511073,-0.46841832,0.17758094,0.48346808,0.85716019},{0.99454794,0.012185681,0.10356594,0.01962185,0.95354091,-0.30062381,-0.1024177,0.30101702,0.94810306},{0.95874911,0.22083632,0.17897366,-0.16111492,0.94090201,-0.29790149,-0.23418422,0.2567775,0.93766895},{0.77937433,-0.34596548,0.52238255,-0.21594913,0.63432583,0.74229154,-0.58816805,-0.69133098,0.41966633},{0.8906558,-0.42208058,0.16905683,-0.060922835,0.25767955,0.96430786,-0.45057812,-0.86916583,0.20378943},{0.99317606,-0.016694442,0.1154236,0.03854033,0.98108055,-0.18972503,-0.1100725,0.19287885,0.97502913},{0.99834638,-0.031752999,0.047919205,0.027446777,0.99574311,0.087990483,-0.050509196,-0.086529724,0.99496806},{0.9983464,-0.031751858,0.047919504,0.027445705,0.99574332,0.087988529,-0.05050935,-0.086527834,0.99496821}},{{0.99384709,0.083726578,0.07251084,-0.060331955,0.95823818,-0.27953466,-0.092887153,0.27343997,0.95739364},{0.99275262,0.015833643,0.11912812,-0.044158688,0.96999756,0.23907053,-0.11176864,-0.24259846,0.96366685},{0.97548347,0.036774933,0.21697851,0.20169339,0.24505093,-0.94829834,-0.088044345,0.96881249,0.23162592},{0.96181359,0.045599329,0.26988027,0.27272149,-0.076131224,-0.95907607,-0.023186908,0.99605462,-0.085659995},{0.95693264,-0.020258363,0.28960245,0.28218609,-0.16943374,-0.94427917,0.068198009,0.98533335,-0.15642003},{0.97600668,-0.15208735,-0.15582167,0.1334222,0.98327117,-0.12400139,0.17207399,0.10023611,0.97997105},{0.99339418,-0.11463337,0.0052124711,0.099288819,0.83587271,-0.53986902,0.05753009,0.53682027,0.84173291},{0.9943543,0.0049814693,0.10599379,0.053842731,0.83706186,-0.54445239,-0.0914355,0.54708556,0.83206788},{0.99201511,-0.035641162,0.12097813,0.059457416,0.97811522,-0.19938762,-0.11122412,0.20498859,0.97242424},{0.98992305,0.0077070319,0.14139644,0.045006487,0.92961916,-0.3657631,-0.1342638,0.36844108,0.91990456},{0.98502186,-0.023111454,0.17087363,0.073775982,0.95217764,-0.29650439,-0.15584943,0.30466966,0.93962086},{0.99082133,0.029031614,0.13202367,-0.0087459991,0.98838695,-0.15170613,-0.13489476,0.14915898,0.97956879},{0.95958149,0.2680288,-0.085812943,-0.28112329,0.9271395,-0.2477542,0.013155307,0.2618643,0.96501502},{0.99196391,-0.088946323,0.089978107,0.11888618,0.41198175,-0.90340308,0.043285109,0.90684047,0.41924558},{0.95578935,-0.0048358205,-0.29401238,-0.15354154,0.84452622,-0.51303066,0.2507821,0.53549227,0.80644678},{0.98857868,0.051454521,-0.14164957,-0.12180088,0.82630366,-0.54989711,0.088750847,0.56086951,0.82313346},{0.98948079,0.075283565,0.12353194,-0.038073437,0.95933775,-0.27968107,-0.13956421,0.27203579,0.95211258},{0.93107149,0.28319608,0.2300122,-0.22776399,0.94369436,-0.23992658,-0.28500752,0.17100033,0.94314877},{0.65447029,-0.52994319,0.53928544,-0.36077459,0.40794042,0.83870512,-0.66446256,-0.74346808,0.075794714},{0.85692769,-0.43641109,0.274263,-0.16783287,0.26685348,0.94901075,-0.48734697,-0.85926394,0.15542991},{0.98612328,-0.0052588559,0.16593132,0.038652174,0.97930364,-0.19867159,-0.16145239,0.2023283,0.96591739},{0.99768927,-0.033959621,0.058846121,0.029806928,0.99709715,0.070063038,-0.061054625,-0.068147111,0.99580536},{0.99768929,-0.033958454,0.058846439,0.029805867,0.99709731,0.070061077,-0.061054798,-0.068145235,0.99580547}},{{0.99384709,0.083726578,0.07251084,-0.060331955,0.95823818,-0.27953466,-0.092887153,0.27343997,0.95739364},{0.99275262,0.015833643,0.11912812,-0.044158688,0.96999756,0.23907053,-0.11176864,-0.24259846,0.96366685},{0.97548347,0.036774933,0.21697851,0.20169339,0.24505093,-0.94829834,-0.088044345,0.96881249,0.23162592},{0.96181359,0.045599329,0.26988027,0.27272149,-0.076131224,-0.95907607,-0.023186908,0.99605462,-0.085659995},{0.95693264,-0.020258363,0.28960245,0.28218609,-0.16943374,-0.94427917,0.068198009,0.98533335,-0.15642003},{0.97600668,-0.15208735,-0.15582167,0.1334222,0.98327117,-0.12400139,0.17207399,0.10023611,0.97997105},{0.99339418,-0.11463337,0.0052124711,0.099288819,0.83587271,-0.53986902,0.05753009,0.53682027,0.84173291},{0.9943543,0.0049814693,0.10599379,0.053842731,0.83706186,-0.54445239,-0.0914355,0.54708556,0.83206788},{0.99201511,-0.035641162,0.12097813,0.059457416,0.97811522,-0.19938762,-0.11122412,0.20498859,0.97242424},{0.98992305,0.0077070319,0.14139644,0.045006487,0.92961916,-0.3657631,-0.1342638,0.36844108,0.91990456},{0.98502186,-0.023111454,0.17087363,0.073775982,0.95217764,-0.29650439,-0.15584943,0.30466966,0.93962086},{0.99082133,0.029031614,0.13202367,-0.0087459991,0.98838695,-0.15170613,-0.13489476,0.14915898,0.97956879},{0.95958149,0.2680288,-0.085812943,-0.28112329,0.9271395,-0.2477542,0.013155307,0.2618643,0.96501502},{0.99196391,-0.088946323,0.089978107,0.11888618,0.41198175,-0.90340308,0.043285109,0.90684047,0.41924558},{0.95578935,-0.0048358205,-0.29401238,-0.15354154,0.84452622,-0.51303066,0.2507821,0.53549227,0.80644678},{0.98857868,0.051454521,-0.14164957,-0.12180088,0.82630366,-0.54989711,0.088750847,0.56086951,0.82313346},{0.98948079,0.075283565,0.12353194,-0.038073437,0.95933775,-0.27968107,-0.13956421,0.27203579,0.95211258},{0.93107149,0.28319608,0.2300122,-0.22776399,0.94369436,-0.23992658,-0.28500752,0.17100033,0.94314877},{0.65447029,-0.52994319,0.53928544,-0.36077459,0.40794042,0.83870512,-0.66446256,-0.74346808,0.075794714},{0.85692769,-0.43641109,0.274263,-0.16783287,0.26685348,0.94901075,-0.48734697,-0.85926394,0.15542991},{0.98612328,-0.0052588559,0.16593132,0.038652174,0.97930364,-0.19867159,-0.16145239,0.2023283,0.96591739},{0.99768927,-0.033959621,0.058846121,0.029806928,0.99709715,0.070063038,-0.061054625,-0.068147111,0.99580536},{0.99768929,-0.033958454,0.058846439,0.029805867,0.99709731,0.070061077,-0.061054798,-0.068145235,0.99580547}}},["hips"]={{0.03325113,-0.11604702,-0.04823162},{0.034849955,-0.11667236,-0.04469118},{0.039297315,-0.11601623,-0.04234867},{0.042427317,-0.10775848,-0.047373256},{0.042020289,-0.092384222,-0.059476374},{0.037792806,-0.076755751,-0.073052176},{0.033376664,-0.084332159,-0.077259348},{0.020283107,-0.093798139,-0.077485922},{0.004815379,-0.10294929,-0.079624422},{-0.0090046666,-0.11140655,-0.076559466},{-0.017568948,-0.11868404,-0.061544226},{-0.014325047,-0.11972805,-0.055061873},{-0.017939221,-0.11093147,-0.056135462},{-0.023505351,-0.095866087,-0.059535769},{-0.025655682,-0.07834152,-0.063619593},{-0.021591756,-0.066933669,-0.067096156},{-0.015072808,-0.082441099,-0.067979411},{0.00056269466,-0.095894315,-0.067800406},{0.014292535,-0.10424919,-0.069211844},{0.025676138,-0.11080349,-0.061908129},{0.033250186,-0.11604812,-0.04823141},{0.033250264,-0.11604816,-0.048231219}}}}}
]====]})
local installer=(function()
local M={}
function M.run(updates)
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
 local P=game.ReplicatedStorage.RodeoFantasy
 local source
 for _,m in ipairs(workspace:GetChildren()) do
  if m:IsA("Model") and m:FindFirstChild("mixamorig:Hips",true) then assert(not source,"Multiple imports") source=m end
 end
 assert(source,"Provided S6 import missing")
 local meshes={} local bones=0
 for _,n in ipairs(source:GetDescendants()) do
  assert(not n:IsA("LuaSourceContainer"),"Unexpected script")
  if n:IsA("MeshPart") then table.insert(meshes,n) end
  if n:IsA("Bone") then bones+=1 end
 end
 assert(#meshes==1 and bones==23,"Expected 1 mesh / 23 bones")
 local mesh=meshes[1] assert(mesh.MeshId~="")
 for _,u in ipairs(updates) do
  local old=u.parent:FindFirstChild(u.name)
  assert(not old and u.before==nil or old and old:IsA("ModuleScript") and (old.Source:gsub("\r\n","\n")==u.before or old.Source:gsub("\r\n","\n")==u.after),"Changed module: "..u.name)
 end
 local prepared={}
 for _,target in ipairs({{P,"VisualTemplate_S6"},{P,"MeshyMossratHuntTemplate_S6"},{game.ServerStorage,"RodeoMonsterTemplate_S6"}}) do
  local old=assert(target[1]:FindFirstChild(target[2])) local model=old:Clone()
  for _,n in ipairs(model:GetChildren()) do if n:IsA("BasePart") and n~=model.PrimaryPart then n:Destroy() end end
  local part=mesh:Clone() part.Name="Body" local scale=7/part.Size.Y
  local box,size=source:GetBoundingBox()
  local relative=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0)):ToObjectSpace(part.CFrame)
  local rootHeight=old:GetAttribute("RootHeight") or require(P.MonsterCatalog).MeadowMouse.RootHeight*1.9
  local rest=CFrame.Angles(0,math.pi,0)*CFrame.new(relative.Position*scale-Vector3.new(0,rootHeight,0))*relative.Rotation
  part.Size*=scale part.CFrame=model.PrimaryPart.CFrame*rest
  for _,b in ipairs(part:GetDescendants()) do if b:IsA("Bone") then b.CFrame=CFrame.new(b.CFrame.Position*scale)*b.CFrame.Rotation b.Transform=CFrame.identity end end
  part.Anchored=true part.CanCollide=false part.CanQuery=false part.CanTouch=false
  part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position) part.Parent=model
  model:SetAttribute("MossratUserRigRevision","ProvidedBiped-v1")
  model:SetAttribute("MeshyFacingRevision","ProvidedBiped-v1")
  model:SetAttribute("NativeMeshyReady",false)
  table.insert(prepared,{old=old,model=model,parent=target[1]})
 end
 local backup=Instance.new("Folder") backup.Name="ProvidedBipedBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
 game:GetService("ChangeHistoryService"):SetWaypoint("Before provided biped")
 for _,u in ipairs(updates) do
  local n=u.parent:FindFirstChild(u.name)
  if n then n:Clone().Parent=backup else n=Instance.new("ModuleScript") n.Name=u.name n.Parent=u.parent end
  n.Source=u.after
 end
 for _,p in ipairs(prepared) do p.old.Parent=backup p.model.Parent=p.parent end
 source.Parent=backup
 game:GetService("ChangeHistoryService"):SetWaypoint("Provided biped installed")
 print("PROVIDED_BIPED_INSTALLED",mesh.MeshId,"23 bones; height 7; shared walking/running")
end
return M

end)() installer.run(updates)
