assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local client=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local server=game:GetService("ServerScriptService")
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local updates={}
updates[#updates+1]={node=assert(client:FindFirstChild("NativeMossrat",true),"Missing NativeMossrat"),source=[====[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
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
]====]}
updates[#updates+1]={node=assert(client:FindFirstChild("RideAnimator",true),"Missing RideAnimator"),source=[====[-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}
local visibility={}
local warnings = {}
local package = game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local template = package:WaitForChild("VisualTemplate")
local templateRoot=template:WaitForChild("MountRoot")
local tuning = require(package:WaitForChild("Config")).Prototype
local Rules = require(package:WaitForChild("HuntRules"))
local Catalog=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
local Crash=require(script.Parent:WaitForChild("CrashEffect"))
local dust={}
local contexts=setmetatable({},{__mode="k"})
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
 local referenceRoot=referenceTemplate:WaitForChild("MountRoot")
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
 for model in pairs(visibility) do if not model:IsDescendantOf(monsters) then visibility[model]=nil end end
	for model, pose in pairs(poses) do
		if not model:IsDescendantOf(monsters) then poses[model] = nil end
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
	for _, model in ipairs(monsters.Name=="RodeoLobby" and monsters:GetDescendants() or monsters:GetChildren()) do
  if not model:IsA("Model") then continue end
  if not model:GetAttribute("MonsterId") or model:GetAttribute("NativeMeshyAirship") then continue end
		local root = model.PrimaryPart
		if not root then continue end
  if model:GetAttribute("KnockedAway") then
   Crash.knock(model,clock)
   for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=1 end end
   continue
  end
  local nameplate = root:FindFirstChild("Nameplate")
  if nameplate then nameplate.Enabled = false end
		if cameraPosition then
   local hidden=(root.Position-cameraPosition).Magnitude>220 or (selected and not model:GetAttribute("Occupied") and not selected[model])
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
  local moving=running and velocity.Magnitude>1
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
   if shown and not shown.hidden then entry.part.LocalTransparencyModifier=math.clamp(1-(clock-(shown.revealed or clock-.3))/.25,0,1) end
		end
		-- Keep cached canonical poses while resting; late parts still align.
	end
 return displayed
end

return RideAnimator
]====]}
updates[#updates+1]={node=assert(client:FindFirstChild("CreatureMesh",true),"Missing CreatureMesh"),source=[====[-- Shared original geometry: faceted young bodies, pointed leaves, smooth final forms.
-- Mesh content is reused across all visible creatures; authoritative roots stay untouched.
local M={}
local Asset=game:GetService("AssetService")
local FacetedMouse=require(script.Parent:WaitForChild("FacetedMouse"))
local NativeMossrat=require(script.Parent:WaitForChild("NativeMossrat"))
local cache,contents,pending={},{},{}
local builder
local function build(kind)
 local mesh=assert(Asset:CreateEditableMesh(),"Editable mesh budget unavailable")
 builder=mesh
 local function vertex(x,y,z) return mesh:AddVertex(Vector3.new(x,y,z)) end
 local function triangle(a,b,c)
  local face=mesh:AddTriangle(a,b,c)
  local normal=(mesh:GetPosition(b)-mesh:GetPosition(a)):Cross(mesh:GetPosition(c)-mesh:GetPosition(a))
  if normal.Magnitude>.00001 then
   if kind=="Smooth" then
    local normals={} for _,id in ipairs({a,b,c}) do normals[#normals+1]=mesh:AddNormal(mesh:GetPosition(id).Unit) end
    mesh:SetFaceNormals(face,normals)
   else local n=mesh:AddNormal(normal.Unit) mesh:SetFaceNormals(face,{n,n,n}) end
  end
 end
 if kind=="Leaf" then
  local rows={}
  for j=0,8 do
   local t=j/8 local width=.5*math.sin(math.pi*t)^.8+.005
   local y=.38*math.sin(math.pi*t) local z=t-.5
   rows[j+1]={vertex(-width,y-.15,z),vertex(0,y,z),vertex(width,y-.15,z),vertex(0,y-.3,z)}
  end
  for j=1,8 do
   for k=1,4 do local n=k%4+1
    triangle(rows[j][k],rows[j+1][k],rows[j+1][n]) triangle(rows[j][k],rows[j+1][n],rows[j][n])
   end
  end
 elseif kind=="Clover" then
  local upper,lower={},{}
  for j=1,24 do
   local a=2*math.pi*(j-1)/24
   local x=math.sin(a)^3*.5 local z=-(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/32
   upper[j]=vertex(x,.5,z) lower[j]=vertex(x,-.5,z)
  end
  local top,bottom=vertex(0,.5,0),vertex(0,-.5,0)
  for j=1,24 do local n=j%24+1 triangle(top,upper[j],upper[n]) triangle(bottom,lower[n],lower[j]) triangle(upper[j],lower[j],lower[n]) triangle(upper[j],lower[n],upper[n]) end
 else
  local sides=kind=="Smooth" and 24 or 10
  local rings=kind=="Smooth" and 14 or 6
  local top=vertex(0,.5,0) local bottom=vertex(0,-.5,0) local rows={}
  for r=1,rings-1 do
   local latitude=math.pi*r/rings rows[r]={}
   for i=1,sides do
    local a=2*math.pi*(i-1)/sides
    rows[r][i]=vertex(math.sin(latitude)*math.cos(a)*.5,math.cos(latitude)*.5,math.sin(latitude)*math.sin(a)*.5)
   end
  end
  for i=1,sides do
   local j=i%sides+1 triangle(top,rows[1][j],rows[1][i])
   triangle(bottom,rows[#rows][i],rows[#rows][j])
   for r=1,#rows-1 do
    triangle(rows[r][i],rows[r][j],rows[r+1][j]) triangle(rows[r][i],rows[r+1][j],rows[r+1][i])
   end
  end
 end
 local fixed=assert(Asset:CreateEditableMeshAsync(Content.fromObject(mesh),{FixedSize=true}),"Fixed mesh budget unavailable")
 contents[kind]=fixed
 mesh:Destroy() builder=nil
 local part=Asset:CreateMeshPartAsync(Content.fromObject(fixed),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
 cache[kind]=part
 part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
 part.DoubleSided=true
 return part
end
function M.prepare()
 if M.failed then return false end
 while pending.prepare do task.wait() end
 if M.ready then return true end
 pending.prepare=true
 local ok,err=pcall(function() for _,kind in ipairs({"Faceted","Smooth","Leaf","Clover"}) do if not cache[kind] then build(kind) end end end)
 if not ok then
  if builder then builder:Destroy() builder=nil end
  for _,part in pairs(cache) do part:Destroy() end cache={}
  for _,mesh in pairs(contents) do mesh:Destroy() end contents={}
  warn("Creature mesh unavailable; native models retained: "..tostring(err))
 end
 M.ready=ok M.failed=not ok pending.prepare=false return ok
end
function M.huntFrame(model,frame)
 return NativeMossrat.huntFrame(model,frame)
end
function M.animate(model,phase,moving,angry)
 NativeMossrat.animate(model,phase,moving,angry)
end
function M.materialize(model)
 if not model:GetAttribute("MonsterId") or model:GetAttribute("NativeMeshyAirship") then return end
 if NativeMossrat.isTarget(model) then NativeMossrat.apply(model) return end
 if not FacetedMouse.failed and FacetedMouse.isTarget(model) and not model:GetAttribute("FacetedMouseRevision") then task.spawn(FacetedMouse.apply,model) end
 if model:FindFirstChild("Body") or not model.PrimaryPart then return end
 local package=game.ReplicatedStorage.RodeoFantasy
 local C=require(package.MonsterCatalog)
 local id=model:GetAttribute("MonsterId") or "MeadowMouse"
 local template=package[C.visual(id,model:GetAttribute("Stars") or 1)]
 for _,original in ipairs(template:GetChildren()) do
  if original:IsA("BasePart") and original~=template.PrimaryPart then
   local part=original:Clone()
   part.CFrame=model.PrimaryPart.CFrame*template.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   part.Parent=model
  end
 end
end
function M.decorate(model)
 if not model:GetAttribute("MonsterId") or model:GetAttribute("NativeMeshyAirship") then return end
 if NativeMossrat.isTarget(model) then NativeMossrat.apply(model) return end
 if FacetedMouse.isTarget(model) then FacetedMouse.apply(model) return end
 if model:GetAttribute("MeshDecorated") or pending[model] then return end
 pending[model]=true
 if not M.ready then M.prepare() end
 if not M.ready then pending[model]=nil return end
 for _,old in ipairs(model:GetChildren()) do
  if not old:IsA("Part") or old==model.PrimaryPart or old.Transparency>=1 then continue end
  local leaf=(old.Name:find("Leaf") or old.Name:find("Sprout") or old.Name:find("Clover") or old.Name:find("Grass")) and not old.Name:find("Vein")
  local kind=old.Name:find("Clover") and "Clover" or leaf and "Leaf" or old.Shape==Enum.PartType.Ball and ((model:GetAttribute("Stars") or 1)>=9 and "Smooth" or "Faceted") or nil
  if not kind then continue end
  local template=cache[kind] if not template then continue end
  local part=template:Clone()
  part.Name=old.Name part.Size=old.Size part.CFrame=old.CFrame part.Color=old.Color
  part.Transparency=old.Transparency part.LocalTransparencyModifier=old.LocalTransparencyModifier
  part.Material=old.Material part.CastShadow=old.CastShadow
  for _,child in ipairs(old:GetChildren()) do child.Parent=part end
  part.Parent=model old:Destroy()
 end
 model:SetAttribute("MeshDecorated",true) pending[model]=nil
end
return M
]====]}
updates[#updates+1]={node=assert(client:FindFirstChild("CaptureClient",true),"Missing CaptureClient"),source=[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
local isolation=require(script.Parent:WaitForChild("HuntIsolation"))
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
require(script.Parent:WaitForChild("OperatorPrompt")).new(player.PlayerGui,remote)
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local socialUI=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bagUI,journalUI)
local settingsUI=require(script.Parent:WaitForChild("SettingsUI")).new(gui,audio)
settingsUI.onOpen=function() bagUI.close() journalUI.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
local airship=workspace.RodeoLobby.Airport.Airship
local whaleMotion=require(script.Parent:WaitForChild("SkyWhaleMotion"))
local shipAnchor=CFrame.new(6000,24,-5)
local shipParts={}
local function rememberShip(node)
 if node:IsA("BasePart") then shipParts[node]=shipAnchor:ToObjectSpace(node.CFrame) end
end
for _,node in ipairs(airship:GetDescendants()) do rememberShip(node) end
airship.DescendantAdded:Connect(rememberShip)
task.spawn(function()
 require(script.Parent:WaitForChild("FacetedMouse")).prepare()
 require(script.Parent:WaitForChild("SkyWhaleRuntime")).install(airship)
 require(script.Parent:WaitForChild("CreatureMesh")).prepare()
end)
local function animateShip(clock)
 if airship:GetAttribute("SkyWhaleRevision") then whaleMotion.step(airship,clock) return end
 local sway=shipAnchor*CFrame.new(math.sin(clock*.7)*.35,math.sin(clock*.9)*.25,0)*CFrame.Angles(0,0,math.sin(clock*.7)*.018)
 for node,rest in pairs(shipParts) do
  if not node.Parent then shipParts[node]=nil continue end
  local pose=rest
  if node.Name=="SeaWingRoot" or node.Name=="SeaWingFeather" then
   local sign=rest.X<0 and -1 or 1
   local pivot=CFrame.new(sign*18,23,-4)
   pose=pivot*CFrame.Angles(0,0,sign*math.sin(clock*1.1)*.18)*pivot:Inverse()*rest
  end
  node.CFrame=sway*pose
 end
end
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,12),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
settingsUI.refreshLayout()
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if settingsUI.isOpen() then return 0 end
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if settingsUI.isOpen() then return Enum.ContextActionResult.Sink end
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsUI.isOpen() or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind=="EvolutionResult" then bagUI.evolutionResult(data) return end
 if kind=="BagIncome" then bagUI.income(data) return end
 if kind~="State" then socialUI.event(kind,data) return end
 if data.huntRoot and data.huntRoot:FindFirstChild("Monsters") and monsters~=data.huntRoot.Monsters then
  monsters=data.huntRoot.Monsters
  monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
 end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data) socialUI.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then animateShip(clock) end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 isolation.update(player,state.area=="Hunt")
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 crashEffect.updateKnocks(clock,state.area=="Hunt" and monsters or nil)
 catch.crates(state.huntRoot and state.huntRoot:FindFirstChild("Obstacles") or workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
]====]}
updates[#updates+1]={node=assert(server:FindFirstChild("InventoryStore",true),"Missing InventoryStore"),source=[====[-- Shared by lobby and cafe. Fenced sessions and recoverable two-player trades.
local S={}
local DS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.BagRules)
local localOnly=Run:IsStudio() and (game.GameId==0 or game.PlaceId==0)
local suffix=Run:IsStudio() and "_Studio_v1" or "_v1"
local store,transactions
-- Unpublished Studio sessions cannot even acquire DataStore handles.
if not localOnly then
 store=DS:GetDataStore("RodeoInventory"..suffix)
 transactions=DS:GetDataStore("RodeoTrades"..suffix)
end
local entries={}
local function copy(value)
 if type(value)~="table" then return value end
 local out={} for k,v in pairs(value) do out[k]=copy(v) end return out
end
local function normalize(data)
 data=data or Rules.new()
 data.eggs=data.eggs or {} data.profile=data.profile or {} data.breedingTeams=data.breedingTeams or {}
 data.balance=data.balance or 0 data.pending=data.pending or 0 data.serial=data.serial or 0
 -- No unapproved offline income; begin the next interval on this server.
 for _,m in ipairs(data.monsters) do m.lastIncome=workspace:GetServerTimeNow() m.assignedPen=nil m.tradeLock=nil end
 return data
end
function S.open(player)
 local token=Http:GenerateGUID(false)
 if localOnly then local data=Rules.new() entries[player]={token=token,data=data} return data end
 local ok,result=pcall(function()
  return store:UpdateAsync(tostring(player.UserId),function(old)
   old=old or {data=Rules.new()}
   if old.lock and old.lock.expires>os.time() then return nil end
   old.lock={token=token,expires=os.time()+120} return old
  end)
 end)
 if not ok or not result or not result.lock or result.lock.token~=token then return nil,"가방을 안전하게 불러오지 못했습니다. 잠시 후 다시 접속해주세요." end
 if result.pendingTrade then
  local pending=result.pendingTrade
  local found,tx=pcall(function() return transactions:GetAsync(pending.id) end)
  if not found then return nil,"거래 기록 확인 중입니다. 잠시 후 다시 접속해주세요." end
  if tx and tx.committed then result.data=pending.after end
  local resolved,saved=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=token then return nil end
    old.data=result.data old.pendingTrade=nil return old
   end)
  end)
  if not resolved or not saved then return nil,"거래 복구 중입니다. 잠시 후 다시 접속해주세요." end
 end
 local data=normalize(result.data)
 entries[player]={token=token,data=data} return data
end
function S.busy(player) local e=entries[player] return not e or e.busy or e.closed end
function S.save(player,release)
 local e=entries[player] if not e or e.busy or e.closed then return false end
 e.busy=true
 local snapshot=copy(e.data)
 local ok,result=true,true
 if not localOnly then
  ok,result=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
    old.data=snapshot old.lock=not release and {token=e.token,expires=os.time()+120} or nil return old
   end)
  end)
 end
 e.busy=false
 if ok and result then if release then e.closed=true end return true end
 e.closed=true player:Kick("가방 저장 연결이 끊겨 안전하게 종료합니다. 다시 접속해주세요.") return false
end
function S.trade(a,b,after)
 local ea,eb=entries[a],entries[b]
 if S.busy(a) or S.busy(b) then return false end
 ea.busy=true eb.busy=true
 local id=Http:GenerateGUID(false)
 local ok=true
 if not localOnly then
  ok=pcall(function()
   -- Both before/after images persist before a single durable commit decision.
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
     old.data=copy(e.data) old.pendingTrade={id=id,after=copy(after[i])}
     old.lock.expires=os.time()+120 return old
    end)
    assert(written and written.pendingTrade and written.pendingTrade.id==id,"Trade checkpoint rejected")
   end
   transactions:UpdateAsync(id,function(old) return old or {committed=true,users={a.UserId,b.UserId},at=os.time()} end)
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or not old.pendingTrade or old.pendingTrade.id~=id then return nil end
     old.data=copy(after[i]) old.pendingTrade=nil return old
    end)
    assert(written and not written.pendingTrade,"Trade settlement pending")
   end
  end)
 end
 if ok then
  for i,e in ipairs({ea,eb}) do table.clear(e.data) for k,v in pairs(after[i]) do e.data[k]=v end end
 else
  -- Never overwrite uncertain durable transaction state with stale RAM.
  ea.closed=true eb.closed=true
  a:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.") b:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.")
 end
 ea.busy=false eb.busy=false return ok
end
function S.close(player)
 local e=entries[player] if not e then return end
 local deadline=os.clock()+25
 while e.busy and os.clock()<deadline do task.wait(.1) end
 if not e.closed then S.save(player,true) end
 entries[player]=nil
end
task.spawn(function()
 while task.wait(30) do for player,e in pairs(entries) do if not e.closed and not e.busy then S.save(player) end end end
end)
game:BindToClose(function()
 local remaining=0
 for p in pairs(entries) do remaining+=1 task.spawn(function() S.close(p) remaining-=1 end) end
 local deadline=os.clock()+27 while remaining>0 and os.clock()<deadline do task.wait(.1) end
end)
return S
]====]}
updates[#updates+1]={node=assert(package:FindFirstChild("MeshyAirshipInstaller",true),"Missing MeshyAirshipInstaller"),source=[====[-- The supplied untouched Meshy lobby creature faces +Z. Install in EDIT mode.
local M={}
local D=require(script.Parent.MeshyAirshipData)
local function bodyRotation(world,importedForward)
 assert(importedForward=="+Z" or importedForward=="-Z","Imported mesh forward must be +Z or -Z")
 return world.Rotation*CFrame.Angles(0,importedForward=="-Z" and math.pi or 0,0)
end
function M.realignInstalled(importedForward)
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
 local ship=workspace.RodeoLobby.Airport.Airship
 assert(ship:GetAttribute("NativeMeshyAirship"),"Expected installed native airship")
 local body=assert(ship:FindFirstChild("MeshyAirshipBody"),"Missing airship body")
 local world=CFrame.new(unpack(D.WorldAnchor))*CFrame.Angles(0,math.pi,0)
 local center=world:PointToWorldSpace((Vector3.new(.0124306679,5,-.0058398247)-Vector3.new(unpack(D.SourceAnchor)))*(D.Height/D.SourceHeight))
 body.CFrame=CFrame.new(center)*bodyRotation(world,importedForward)
 body:SetAttribute("WhaleRest",body.CFrame)
 ship:SetAttribute("WhaleAnchor",CFrame.new(center))
 ship:SetAttribute("MeshyImportedForward",importedForward)
 return ship
end
function M.installSelected(importedForward)
 assert(not game:GetService("RunService"):IsRunning(),"재생을 정지한 뒤 설치해주세요.")
 local selected=game:GetService("Selection"):Get()
 assert(#selected==1,"가져온 새 로비 모델 하나를 선택해주세요.")
 local source=selected[1]
 assert(source:IsA("Model") or source:IsA("MeshPart"),"가져온 Model 또는 MeshPart를 선택해주세요.")
 local airport=workspace.RodeoLobby.Airport
 assert(source:IsDescendantOf(workspace) and not source:IsDescendantOf(airport),"새로 가져온 모델을 선택해주세요.")
 local original=source:IsA("MeshPart") and {source} or source:GetDescendants()
 local meshes={}
 for _,p in ipairs(original) do
  assert(not p:IsA("LuaSourceContainer"),"가져온 모델에 스크립트가 있습니다. 설치를 중단합니다.")
  if p:IsA("MeshPart") then
   local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
   assert(p.MeshId~="" and (p.TextureID~="" or appearance and appearance.ColorMap~=""),"메시와 텍스처 업로드를 완료해주세요.")
   table.insert(meshes,p)
  end
 end
 assert(#meshes==1,"제공된 단일 메시 모델을 병합/분할 없이 가져와주세요.")
 local current=assert(airport:FindFirstChild("Airship"),"기존 Airship을 찾지 못했습니다.")
 local p=meshes[1]
 local scale=D.Height/p.Size.Y
 -- MeshPart origin is imported bounds centre. Reconstruct source coordinates.
 local sourceCenter=Vector3.new(.0124306679,5,-.0058398247)
 local world=CFrame.new(unpack(D.WorldAnchor))*CFrame.Angles(0,math.pi,0)
 local center=world:PointToWorldSpace((sourceCenter-Vector3.new(unpack(D.SourceAnchor)))*(D.Height/D.SourceHeight))
 local clone=Instance.new("Model") clone.Name="Airship"
 local body=p:Clone() body.Name="MeshyAirshipBody" body.Size*=scale
 body.CFrame=CFrame.new(center)*bodyRotation(world,importedForward or "+Z") body.Anchored=true body.CanCollide=false body.CanTouch=false body.CanQuery=false
 body.Color=Color3.new(1,1,1) body.DoubleSided=true body.RenderFidelity=Enum.RenderFidelity.Precise
 body:SetAttribute("WhaleRest",body.CFrame) body.Parent=clone
 clone:SetAttribute("MeshyImportedForward",importedForward or "+Z")
 clone.PrimaryPart=body clone:SetAttribute("NativeMeshyAirship",true) clone:SetAttribute("SkyWhaleRevision","MeshyLobby-v1") clone:SetAttribute("WhaleAnchor",CFrame.new(center))
 local changes={}
 for _,cable in ipairs(airport.BoardingArea:GetChildren()) do
  if cable:IsA("BasePart") and cable.Name=="Cable" then
   for _,c in ipairs(D.Cables) do
    if math.abs(cable.Position.X-c[1])<.1 and math.abs(cable.Position.Z-c[2])<.1 then table.insert(changes,{part=cable,data=c}) end
   end
  end
 end
 if #changes~=4 then clone:Destroy() error("탑승 줄 위치가 예상과 달라 설치하지 않았습니다.") end
 local archive=Instance.new("Folder") archive.Name="MeshyAirshipBackup" archive.Parent=game.ServerStorage
 current.Parent=archive clone.Parent=airport
 for _,change in ipairs(changes) do local c=change.data local cable=change.part cable.Size=Vector3.new(cable.Size.X,c[4]-c[3],cable.Size.Z) cable.CFrame=CFrame.new(c[1],(c[4]+c[3])/2,c[2]) end
 source.Parent=archive
 print("새 로비 모델 설치 완료. 원본 텍스처 보존 / 배 아래 줄 4개 연결. Ctrl+S 후 Play로 확인해주세요.")
 return clone
end
return M
]====]}
updates[#updates+1]={node=assert(package:FindFirstChild("MeshyMossratInstaller",true),"Missing MeshyMossratInstaller"),source=[====[-- Run once in Studio EDIT mode after importing the two supplied GLBs.
local M={}
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local C=require(RS.RodeoFantasy.MonsterCatalog)
local function prepare(source,old,name,sourceForward)
 assert(source and (source:IsA("Model") or source:IsA("MeshPart")),"Missing imported model: "..name)
 local meshes={}
 local descendants=source:IsA("MeshPart") and {source} or source:GetDescendants()
 for _,part in ipairs(descendants) do
  if part:IsA("MeshPart") then
   assert(part.MeshId~="","Mesh must be uploaded by Studio importer")
   table.insert(meshes,part)
  end
 end
 assert(#meshes>0,"Imported model has no MeshParts")
 local box,size
 if source:IsA("MeshPart") then box,size=source.CFrame,source.Size else box,size=source:GetBoundingBox() end
 local scale=2.5/size.Y
 local frame=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0))
 local model=old:Clone()
 model.Name=name
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 local root=model.PrimaryPart
 assert(root,"Existing template has no root")
 for i,original in ipairs(meshes) do
  local part=original:Clone()
  local relative=frame:ToObjectSpace(original.CFrame)
  -- Supplied Hunt/Detail GLBs already face -Z. Raw Meshy +Z is explicit opt-in.
  local rest=CFrame.Angles(0,sourceForward=="+Z" and math.pi or 0,0)*CFrame.new(relative.Position*scale-Vector3.new(0,C.MeadowMouse.RootHeight,0))*relative.Rotation
  part.Name=i==1 and "Body" or "BodyDetail"..i
  part.Size*=scale part.CFrame=root.CFrame*rest
  for _,bone in ipairs(part:GetDescendants()) do
   if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
  end
  part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
  part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position)
  -- Preserve imported SurfaceAppearance and material textures unchanged.
  part.Parent=model
 end
 model:SetAttribute("MeshyVisualYawDegrees",0)
 model:SetAttribute("MeshyFacingRevision","Imported-"..sourceForward)
 model:SetAttribute("NativeMeshyMossrat",true)
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",1)
 model:SetAttribute("MeshyBackHeight",1.18)
 model:SetAttribute("MeshyFacingCorrected",true)
 return model
end
function M.install(hunt,detail,sourceForward)
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play before installing and saving")
 assert(hunt,"사냥터용 가져온 모델을 찾지 못했습니다. 탐색기에서 가져온 모스랫을 선택한 뒤 installSelected()를 사용하세요.")
 detail=detail or hunt
 sourceForward=sourceForward or "-Z"
 assert(sourceForward=="-Z" or sourceForward=="+Z","sourceForward must be -Z (prepared files) or +Z (original Meshy files)")
 local package=RS.RodeoFantasy
 -- Prepare every replacement before touching any existing template.
 local replacements={
  {SS,"RodeoMonsterTemplate",prepare(hunt,SS.RodeoMonsterTemplate,"RodeoMonsterTemplate",sourceForward)},
  {package,"VisualTemplate",prepare(detail,package.VisualTemplate,"VisualTemplate",sourceForward)},
  {package,"MeshyMossratHuntTemplate",prepare(hunt,package.VisualTemplate,"MeshyMossratHuntTemplate",sourceForward)},
 }
 for _,entry in ipairs(replacements) do
  local old=entry[1]:FindFirstChild(entry[2])
  if old then old:Destroy() end
  entry[3].Parent=entry[1]
 end
 print("모스랫 1성 설치 완료: "..(hunt==detail and "선택한 모델을 공용으로 사용" or "사냥터/상세 모델 분리")..". Ctrl+S로 저장하세요.")
end
function M.installSelected()
 local selected=game:GetService("Selection"):Get()
 assert(#selected>=1 and #selected<=2,"탐색기에서 가져온 모스랫 Model 또는 MeshPart 1~2개를 선택하세요.")
 local hunt,detail
 for _,source in ipairs(selected) do
  assert(source:IsA("Model") or source:IsA("MeshPart"),"가져온 모델 전체 또는 MeshPart를 선택하세요. 텍스처/폴더는 설치할 수 없습니다.")
  assert(source:IsDescendantOf(workspace),"Workspace에 가져온 모스랫을 선택하세요.")
  local name=source.Name:lower()
  if name:find("hunt",1,true) then hunt=source end
  if name:find("detail",1,true) then detail=source end
 end
 if #selected==1 then hunt,detail=selected[1],selected[1]
 else assert(hunt and detail and hunt~=detail,"두 모델 선택 시 이름에 각각 Hunt와 Detail이 있어야 합니다. 한 모델만 선택하면 이름과 관계없이 공용으로 설치합니다.") end
 return M.install(hunt,detail)
end
return M
]====]}
for _,entry in ipairs(updates) do entry.node.Source=entry.source end
local fresh=Instance.new("ModuleScript") fresh.Name="MeshyLobbyRepairOnce" fresh.Parent=package
fresh.Source=[====[-- Apply in EDIT mode. Preserve uploaded mesh/PBR assets and owner configuration.
local M={}
function M.apply()
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play before repairing")
 local package=game:GetService("ReplicatedStorage").RodeoFantasy
 local ss=game:GetService("ServerStorage")
 local hunt=assert(package:FindFirstChild("MeshyMossratHuntTemplate"),"Missing hunt visual template")
 local server=assert(ss:FindFirstChild("RodeoMonsterTemplate"),"Missing server monster template")
 local ship=workspace.RodeoLobby.Airport.Airship
 assert(ship:GetAttribute("NativeMeshyAirship") and ship:FindFirstChild("MeshyAirshipBody"),"Missing installed native airship")
 for _,model in ipairs({hunt,server}) do
  assert(model:GetAttribute("NativeMeshyMossrat") and model.PrimaryPart and model:FindFirstChild("Body"),"Missing installed native Mossrat")
 end
 local backup=ss:FindFirstChild("LobbyRepairBackup20261010")
 if not backup then
  backup=Instance.new("Folder") backup.Name="LobbyRepairBackup20261010" backup.Parent=ss
  for _,model in ipairs({hunt,server,ship}) do model:Clone().Parent=backup end
 end
 for _,model in ipairs({hunt,server}) do
  -- Undo the earlier direct-body patch before applying an explicit runtime yaw.
  if model:GetAttribute("HuntFacingRepair20261010") then
   for _,part in ipairs(model:GetChildren()) do
    if part:IsA("MeshPart") then
     local rest=model.PrimaryPart.CFrame:ToObjectSpace(part.CFrame)
     rest=CFrame.new(rest.Position)*CFrame.Angles(0,math.pi,0)*rest.Rotation
     part.CFrame=model.PrimaryPart.CFrame*rest
     part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position)
    end
   end
   model:SetAttribute("HuntFacingRepair20261010",nil)
  end
  model:SetAttribute("MeshyVisualYawDegrees",180)
  model:SetAttribute("MeshyFacingRevision",model:GetAttribute("HeadShapeStraightened") and "HeadStraight-v1" or "HuntFacing-v2")
  model:SetAttribute("FaceCourseForward",false)
 end
 -- Use a fresh ModuleScript instance: require caches an already-loaded installer.
 local fresh=package.MeshyAirshipInstaller:Clone() fresh.Name="AirshipRealignOnce" fresh.Parent=package
 local ok,result=pcall(function() return require(fresh).realignInstalled("-Z") end)
 fresh:Destroy()
 assert(ok,result)
 print("LOBBY_MODEL_REPAIR_APPLIED: runtime hunt facing and airship orientation; uploaded assets preserved")
 return true
end
function M.retryTextures()
 -- SurfaceAppearance renders a processed PBR pack. Individual image preloading
 -- cannot certify that pack, and rewriting map URIs can invalidate it.
 print("AIRSHIP_PBR_PRESERVED: uploaded appearance unchanged; verify color in Play")
end
return M
]====]
local ok,err=pcall(function() local repair=require(fresh) repair.apply() repair.retryTextures() end)
fresh:Destroy()
assert(ok,err)