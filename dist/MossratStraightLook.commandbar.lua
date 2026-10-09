assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local client=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local hunt=assert(game:GetService("ReplicatedStorage").RodeoFantasy:FindFirstChild("MeshyMossratHuntTemplate"),"Missing native hunt template")
assert(hunt:GetAttribute("NativeMeshyMossrat"),"Expected installed native Mossrat")
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
for _,entry in ipairs(updates) do entry.node.Source=entry.source end
hunt:SetAttribute("FaceCourseForward",true)
print("MOSSRAT_STRAIGHT_LOOK_APPLIED: save and restart Play")