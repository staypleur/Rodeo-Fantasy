do
local package=game.ReplicatedStorage.RodeoFantasy
local updates={
{name="NativeMossrat",parent=game.StarterPlayer.StarterPlayerScripts,before=[=[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
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
function M.posePortrait(model)
 if not M.isTarget(model) then return end
 rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
 rigAnimator.poseFront(model)
end
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
]=],after=[=[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local stage=C.stage(model:GetAttribute("Stars") or 1)
 local visual=package:FindFirstChild(C.visual("MeadowMouse",stage))
 return model:GetAttribute("MonsterId")=="MeadowMouse" and (stage==1 or stage==3) and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
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
]=]},
{name="UserMossratRigAnimator",parent=game.StarterPlayer.StarterPlayerScripts,before=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
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
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=bondUntil>workspace:GetServerTimeNow()
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
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
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=workspace:GetServerTimeNow()-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-workspace:GetServerTimeNow())/.35,0,1))
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
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]=],after=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local dataS3=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS3"))
local function rigData(model) return model:GetAttribute("MossratUserRigRevision")=="UserS3-v1" and dataS3 or data end
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local s3=rigData(model)==dataS3
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
 local s3=data==dataS3
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=bondUntil>workspace:GetServerTimeNow()
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
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
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=not s3 and torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" and not s3 then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=workspace:GetServerTimeNow()-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-workspace:GetServerTimeNow())/.35,0,1))
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
   elseif legSide and legLimb and moving and not s3 then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]=]},
{name="LobbyCompanions",parent=game.ServerScriptService,before=[=[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.clear(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","Summon your companion in the lobby.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  if not source or source:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false,blocked=0}
  p:SetAttribute("SummonedId",id)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="Bond"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  prompt.Style=Enum.ProximityPromptStyle.Custom
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<3.5 then return end
   last=os.clock()
   local at=workspace:GetServerTimeNow()
   model:SetAttribute("PetBondStarted",at) model:SetAttribute("PetBondUntil",at+3)
   P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=at})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A pet stranded behind a wall must not be left outside the visible lobby.
   -- Recover only onto a collidable surface near its owner, never into the sky.
   if toOwner.Magnitude>70 or pet.blocked>=1.5 then
    for _,offset in ipairs({Vector3.new(4,0,4),Vector3.new(-4,0,4),Vector3.new(4,0,-4),Vector3.new(-4,0,-4)}) do
     local position=r.Position+offset
     local y=ground(position)
     if y and math.abs(y-r.Position.Y)<10 then
      local frame=CFrame.new(position.X,y+pet.height,position.Z)*old.Rotation
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
      pet.following=false pet.blocked=0 old=frame
      toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
      break
     end
    end
   end
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    -- Match the owner's pace; the lobby player walks at 40 studs/sec.
    local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
    local speed=humanoid and humanoid.WalkSpeed or 40
    delta=delta.Unit*math.min(delta.Magnitude-6,speed*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     pet.blocked=0
    else
     pet.blocked+=step
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]=],after=[=[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.clear(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","Summon your companion in the lobby.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  local revision=source and source:GetAttribute("MossratUserRigRevision")
  if revision~="ApprovedS1-v1" and revision~="UserS3-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false,blocked=0}
  p:SetAttribute("SummonedId",id)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="Bond"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  prompt.Style=Enum.ProximityPromptStyle.Custom
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<3.5 then return end
   last=os.clock()
   local at=workspace:GetServerTimeNow()
   model:SetAttribute("PetBondStarted",at) model:SetAttribute("PetBondUntil",at+3)
   P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=at})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A pet stranded behind a wall must not be left outside the visible lobby.
   -- Recover only onto a collidable surface near its owner, never into the sky.
   if toOwner.Magnitude>70 or pet.blocked>=1.5 then
    for _,offset in ipairs({Vector3.new(4,0,4),Vector3.new(-4,0,4),Vector3.new(4,0,-4),Vector3.new(-4,0,-4)}) do
     local position=r.Position+offset
     local y=ground(position)
     if y and math.abs(y-r.Position.Y)<10 then
      local frame=CFrame.new(position.X,y+pet.height,position.Z)*old.Rotation
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
      pet.following=false pet.blocked=0 old=frame
      toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
      break
     end
    end
   end
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    -- Match the owner's pace; the lobby player walks at 40 studs/sec.
    local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
    local speed=humanoid and humanoid.WalkSpeed or 40
    delta=delta.Unit*math.min(delta.Magnitude-6,speed*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     pet.blocked=0
    else
     pet.blocked+=step
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]=]},
{name="MonsterCatalog",parent=package,before=[=[-- User-approved meadow species. All current wild spawns are one-star.
local C={
 MeadowMouse={RunSpeed=64,HerdSpeed=44,SizeClass="Small",Flying=false,RootHeight=2.05,SaddleHeight=2,TameSeconds=5,UnlockMeters=0,IncomeSeconds=3,IncomeAmount=1,Template="RodeoMonsterTemplate",Visual="VisualTemplate"},
 GrassBoar={RunSpeed=64,HerdSpeed=44,SizeClass="Medium",Flying=false,RootHeight=3.0625,SaddleHeight=2.8125,TameSeconds=6,UnlockMeters=150,IncomeSeconds=3,IncomeAmount=2,Template="GrassBoarTemplate",Visual="GrassBoarVisualTemplate"},
 TreeWolf={RunSpeed=76.8,HerdSpeed=52.8,SizeClass="Medium",Flying=false,RootHeight=2.9375,SaddleHeight=2.75,TameSeconds=6,UnlockMeters=300,TripleHop=true,IncomeSeconds=3,IncomeAmount=2,Template="TreeWolfTemplate",Visual="TreeWolfVisualTemplate"},
 Weedcrow={RunSpeed=80,HerdSpeed=55,SizeClass="Small",Flying=true,RootHeight=16,SaddleHeight=1.9,TameSeconds=5,UnlockMeters=400,IncomeSeconds=3,IncomeAmount=2,Template="WeedcrowTemplate",Visual="WeedcrowVisualTemplate"},
 RockElephant={RunSpeed=64,HerdSpeed=44,SizeClass="Large",Flying=false,RootHeight=5.3625,SaddleHeight=5.0325,TameSeconds=7,UnlockMeters=500,IncomeSeconds=3,IncomeAmount=3,Template="RockElephantTemplate",Visual="RockElephantVisualTemplate"},
}
C.Order={"MeadowMouse"}
C.MeadowEndMeters=1000 -- Meadow wildlife spawns only at 0 <= metres < 1000.
for _,id in ipairs(C.Order) do C[id].Region=C[id].Region or (C[id].Acquisition=="Breeding" and "Breeding" or "Meadow") C[id].Acquisition=C[id].Acquisition or "Hunt" end
C.Scales={[1]=1,[3]=1.4,[6]=1.9,[9]=2.5}
function C.stage(stars) return stars>=9 and 9 or stars>=6 and 6 or stars>=3 and 3 or 1 end
function C.scale(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 local lower=C.stage(stars)
 if lower==9 then return 2.5+(stars-9)*.2 end
 local upper=lower==1 and 3 or lower+3
 local alpha=(stars-lower)/(upper-lower)
 return C.Scales[lower]+(C.Scales[upper]-C.Scales[lower])*alpha
end
function C.visual(id,stars) local stage=C.stage(stars or 1) return C[id].Visual..(stage==1 and "" or "_S"..stage) end
function C.template(id,stars) local stage=C.stage(stars or 1) return C[id].Template..(stage==1 and "" or "_S"..stage) end
function C.saddleHeight(id,stars)
 stars=stars or 1
 if id=="GrassBoar" then
  local stage=C.stage(stars)
  local back={[1]=2.804463,[3]=3.880880,[6]=7.230789,[9]=11.021101}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 if id=="MeadowMouse" then
  local stage=C.stage(stars)
  if stage==1 then
   local package=game and game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
   local visual=package and package:FindFirstChild("VisualTemplate")
   local back=visual and visual:GetAttribute("MeshyBackHeight")
   if back then return back*C.scale(stars)+1.36-C[id].RootHeight*C.scale(stars) end
   return 1.2*C.scale(stars)
  end
  -- Meshes already contain their approved stage size. Seat above the back,
  -- with a constant clearance for the unscaled player rather than its crown.
  local back={[3]=2.212572,[6]=3.232653,[9]=7.460891}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 return C[id].SaddleHeight*C.scale(stars)
end
function C.pick(meters,serial)
 if meters<0 or meters>=C.MeadowEndMeters then return nil end
 local unlocked={}
 for _,id in ipairs(C.Order) do if meters>=C[id].UnlockMeters then table.insert(unlocked,id) end end
 return unlocked[serial%#unlocked+1]
end
return C
]=],after=[=[-- User-approved meadow species. All current wild spawns are one-star.
local C={
 MeadowMouse={RunSpeed=64,HerdSpeed=44,SizeClass="Small",Flying=false,RootHeight=2.05,SaddleHeight=2,TameSeconds=5,UnlockMeters=0,IncomeSeconds=3,IncomeAmount=1,Template="RodeoMonsterTemplate",Visual="VisualTemplate"},
 GrassBoar={RunSpeed=64,HerdSpeed=44,SizeClass="Medium",Flying=false,RootHeight=3.0625,SaddleHeight=2.8125,TameSeconds=6,UnlockMeters=150,IncomeSeconds=3,IncomeAmount=2,Template="GrassBoarTemplate",Visual="GrassBoarVisualTemplate"},
 TreeWolf={RunSpeed=76.8,HerdSpeed=52.8,SizeClass="Medium",Flying=false,RootHeight=2.9375,SaddleHeight=2.75,TameSeconds=6,UnlockMeters=300,TripleHop=true,IncomeSeconds=3,IncomeAmount=2,Template="TreeWolfTemplate",Visual="TreeWolfVisualTemplate"},
 Weedcrow={RunSpeed=80,HerdSpeed=55,SizeClass="Small",Flying=true,RootHeight=16,SaddleHeight=1.9,TameSeconds=5,UnlockMeters=400,IncomeSeconds=3,IncomeAmount=2,Template="WeedcrowTemplate",Visual="WeedcrowVisualTemplate"},
 RockElephant={RunSpeed=64,HerdSpeed=44,SizeClass="Large",Flying=false,RootHeight=5.3625,SaddleHeight=5.0325,TameSeconds=7,UnlockMeters=500,IncomeSeconds=3,IncomeAmount=3,Template="RockElephantTemplate",Visual="RockElephantVisualTemplate"},
}
C.Order={"MeadowMouse"}
C.MeadowEndMeters=1000 -- Meadow wildlife spawns only at 0 <= metres < 1000.
for _,id in ipairs(C.Order) do C[id].Region=C[id].Region or (C[id].Acquisition=="Breeding" and "Breeding" or "Meadow") C[id].Acquisition=C[id].Acquisition or "Hunt" end
C.Scales={[1]=1,[3]=1.4,[6]=1.9,[9]=2.5}
function C.stage(stars) return stars>=9 and 9 or stars>=6 and 6 or stars>=3 and 3 or 1 end
function C.scale(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 local lower=C.stage(stars)
 if lower==9 then return 2.5+(stars-9)*.2 end
 local upper=lower==1 and 3 or lower+3
 local alpha=(stars-lower)/(upper-lower)
 return C.Scales[lower]+(C.Scales[upper]-C.Scales[lower])*alpha
end
function C.visual(id,stars) local stage=C.stage(stars or 1) return C[id].Visual..(stage==1 and "" or "_S"..stage) end
function C.template(id,stars) local stage=C.stage(stars or 1) return C[id].Template..(stage==1 and "" or "_S"..stage) end
function C.saddleHeight(id,stars)
 stars=stars or 1
 if id=="GrassBoar" then
  local stage=C.stage(stars)
  local back={[1]=2.804463,[3]=3.880880,[6]=7.230789,[9]=11.021101}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 if id=="MeadowMouse" then
  local stage=C.stage(stars)
  if stage==1 or stage==3 then
   local package=game and game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
   local visual=package and package:FindFirstChild(C.visual(id,stars))
   local back=visual and visual:GetAttribute("MeshyBackHeight")
   if back then return back*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars) end
   return 1.2*C.scale(stars)
  end
  -- Meshes already contain their approved stage size. Seat above the back,
  -- with a constant clearance for the unscaled player rather than its crown.
  local back={[3]=2.212572,[6]=3.232653,[9]=7.460891}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 return C[id].SaddleHeight*C.scale(stars)
end
function C.pick(meters,serial)
 if meters<0 or meters>=C.MeadowEndMeters then return nil end
 local unlocked={}
 for _,id in ipairs(C.Order) do if meters>=C[id].UnlockMeters then table.insert(unlocked,id) end end
 return unlocked[serial%#unlocked+1]
end
return C
]=]},
}
local modules={{parent=package,name="UserMossratRigDataS3",source=[=[-- Generated exact S3 glTF samples.
return {height=1.26,bones={
"Root",
"Pelvis",
"Spine",
"Chest",
"Neck",
"Head",
"Jaw",
"EyeLeft",
"EyeRight",
"EarLeft",
"EarTipLeft",
"EarRight",
"EarTipRight",
"Sprout",
"SproutTip",
"WhiskerLeft",
"WhiskerRight",
"LeftFrontUpper",
"LeftFrontLower",
"LeftFrontPaw",
"LeftRearUpper",
"LeftRearLower",
"LeftRearPaw",
"RightFrontUpper",
"RightFrontLower",
"RightFrontPaw",
"RightRearUpper",
"RightRearLower",
"RightRearPaw",
"Tail1",
"Tail2",
"Tail3",
"Tail4",
"Tail5",
},clips={
Idle={duration=4.0,fps=24,channels={
{bone="Root",path="translation",values={{0,0,0},{0,0.000137346578,0},{0,0.000274104998,0},{0,0.000409689674,0},{0,0.000543519971,0},{0,0.000675022893,0},{0,0.000803635223,0},{0,0.000928806257,0},{0,0.00104999996,0},{0,0.00116669748,0},{0,0.00127839902,0},{0,0.00138462626,0},{0,0.00148492423,0},{0,0.00157886359,0},{0,0.00166604202,0},{0,0.00174608617,0},{0,0.00181865331,0},{0,0.00188343273,0},{0,0.00194014702,0},{0,0.00198855321,0},{0,0.00202844432,0},{0,0.00205964898,0},{0,0.00208203425,0},{0,0.00209550373,0},{0,0.00209999993,0},{0,0.00209550373,0},{0,0.00208203425,0},{0,0.00205964898,0},{0,0.00202844432,0},{0,0.00198855321,0},{0,0.00194014702,0},{0,0.00188343273,0},{0,0.00181865331,0},{0,0.00174608617,0},{0,0.00166604202,0},{0,0.00157886359,0},{0,0.00148492423,0},{0,0.00138462626,0},{0,0.00127839902,0},{0,0.00116669748,0},{0,0.00104999996,0},{0,0.000928806257,0},{0,0.000803635223,0},{0,0.000675022893,0},{0,0.000543519971,0},{0,0.000409689674,0},{0,0.000274104998,0},{0,0.000137346578,0},{0,2.57175829e-19,0},{0,-0.000137346578,0},{0,-0.000274104998,0},{0,-0.000409689674,0},{0,-0.000543519971,0},{0,-0.000675022893,0},{0,-0.000803635223,0},{0,-0.000928806257,0},{0,-0.00104999996,0},{0,-0.00116669748,0},{0,-0.00127839902,0},{0,-0.00138462626,0},{0,-0.00148492423,0},{0,-0.00157886359,0},{0,-0.00166604202,0},{0,-0.00174608617,0},{0,-0.00181865331,0},{0,-0.00188343273,0},{0,-0.00194014702,0},{0,-0.00198855321,0},{0,-0.00202844432,0},{0,-0.00205964898,0},{0,-0.00208203425,0},{0,-0.00209550373,0},{0,-0.00209999993,0},{0,-0.00209550373,0},{0,-0.00208203425,0},{0,-0.00205964898,0},{0,-0.00202844432,0},{0,-0.00198855321,0},{0,-0.00194014702,0},{0,-0.00188343273,0},{0,-0.00181865331,0},{0,-0.00174608617,0},{0,-0.00166604202,0},{0,-0.00157886359,0},{0,-0.00148492423,0},{0,-0.00138462626,0},{0,-0.00127839902,0},{0,-0.00116669748,0},{0,-0.00104999996,0},{0,-0.000928806257,0},{0,-0.000803635223,0},{0,-0.000675022893,0},{0,-0.000543519971,0},{0,-0.000409689674,0},{0,-0.000274104998,0},{0,-0.000137346578,0},{0,-5.14351658e-19,0}}},
{bone="Spine",path="rotation",values={{0.00354623515,0,0,0.999993742},{0.00428842055,0,0,0.999990821},{0.00501224026,0,0,0.999987423},{0.00571459439,0,0,0.999983668},{0.00639247522,0,0,0.999979556},{0.00704297982,0,0,0.999975204},{0.00766332308,0,0,0.999970615},{0.00825084932,0,0,0.999965966},{0.00880304165,0,0,0.999961257},{0.00931753591,0,0,0.999956608},{0.00979213044,0,0,0.999952078},{0.0102247931,0,0,0.999947727},{0.0106136715,0,0,0.999943674},{0.0109571014,0,0,0.999939978},{0.0112536112,0,0,0.9999367},{0.0115019325,0,0,0.999933839},{0.0117010018,0,0,0.999931514},{0.0118499687,0,0,0.999929786},{0.0119481934,0,0,0.999928594},{0.0119952578,0,0,0.999928057},{0.0119909579,0,0,0.999928117},{0.0119353142,0,0,0.999928772},{0.0118285632,0,0,0.999930024},{0.0116711631,0,0,0.999931872},{0.0114637865,0,0,0.999934316},{0.0112073226,0,0,0.999937177},{0.0109028677,0,0,0.999940574},{0.0105517264,0,0,0.999944329},{0.0101554003,0,0,0.999948442},{0.00971558783,0,0,0.999952793},{0.00923417043,0,0,0.999957383},{0.00871321,0,0,0.999962032},{0.00815493613,0,0,0.999966741},{0.00756174047,0,0,0.99997139},{0.00693616131,0,0,0.99997592},{0.00628087856,0,0,0.999980271},{0.00559869735,0,0,0.999984324},{0.0048925397,0,0,0.999988019},{0.00416542869,0,0,0.999991298},{0.00342047866,0,0,0.999994159},{0.00266087963,0,0,0.999996483},{0.00188988494,0,0,0.999998212},{0.00111079623,0,0,0.999999404},{0.000326950336,0,0,0.99999994},{-0.000458295835,0,0,0.999999881},{-0.0012415793,0,0,0.999999225},{-0.0020195453,0,0,0.999997973},{-0.00278886221,0,0,0.999996126},{-0.00354623515,0,0,0.999993742},{-0.00428842055,0,0,0.999990821},{-0.00501224026,0,0,0.999987423},{-0.00571459439,0,0,0.999983668},{-0.00639247522,0,0,0.999979556},{-0.00704297982,0,0,0.999975204},{-0.00766332308,0,0,0.999970615},{-0.00825084932,0,0,0.999965966},{-0.00880304165,0,0,0.999961257},{-0.00931753591,0,0,0.999956608},{-0.00979213044,0,0,0.999952078},{-0.0102247931,0,0,0.999947727},{-0.0106136715,0,0,0.999943674},{-0.0109571014,0,0,0.999939978},{-0.0112536112,0,0,0.9999367},{-0.0115019325,0,0,0.999933839},{-0.0117010018,0,0,0.999931514},{-0.0118499687,0,0,0.999929786},{-0.0119481934,0,0,0.999928594},{-0.0119952578,0,0,0.999928057},{-0.0119909579,0,0,0.999928117},{-0.0119353142,0,0,0.999928772},{-0.0118285632,0,0,0.999930024},{-0.0116711631,0,0,0.999931872},{-0.0114637865,0,0,0.999934316},{-0.0112073226,0,0,0.999937177},{-0.0109028677,0,0,0.999940574},{-0.0105517264,0,0,0.999944329},{-0.0101554003,0,0,0.999948442},{-0.00971558783,0,0,0.999952793},{-0.00923417043,0,0,0.999957383},{-0.00871321,0,0,0.999962032},{-0.00815493613,0,0,0.999966741},{-0.00756174047,0,0,0.99997139},{-0.00693616131,0,0,0.99997592},{-0.00628087856,0,0,0.999980271},{-0.00559869735,0,0,0.999984324},{-0.0048925397,0,0,0.999988019},{-0.00416542869,0,0,0.999991298},{-0.00342047866,0,0,0.999994159},{-0.00266087963,0,0,0.999996483},{-0.00188988494,0,0,0.999998212},{-0.00111079623,0,0,0.999999404},{-0.000326950336,0,0,0.99999994},{0.000458295835,0,0,0.999999881},{0.0012415793,0,0,0.999999225},{0.0020195453,0,0,0.999997973},{0.00278886221,0,0,0.999996126},{0.00354623515,0,0,0.999993742}}},
{bone="Chest",path="rotation",values={{0,0,0.003504758,0.999993861},{0,0,0.00403941236,0.999991834},{0,0,0.00455676904,0.999989629},{0,0,0.00505461125,0.999987245},{0,0,0.00553080812,0.999984682},{0,0,0.00598332006,0.999982119},{0,0,0.00641020993,0.999979436},{0,0,0.00680964952,0.999976814},{0,0,0.00717992848,0.999974251},{0,0,0.00751946121,0.999971747},{0,0,0.00782679487,0.999969363},{0,0,0.00810061302,0.999967217},{0,0,0.00833974313,0.99996525},{0,0,0.00854316074,0.999963522},{0,0,0.00870999694,0.999962091},{0,0,0.00883953646,0.999960959},{0,0,0.00893122423,0.999960124},{0,0,0.00898466725,0.999959648},{0,0,0.00899963826,0.999959528},{0,0,0.008976073,0.999959707},{0,0,0.00891407114,0.999960244},{0,0,0.00881389901,0.999961138},{0,0,0.00867598504,0.999962389},{0,0,0.00850092061,0.99996388},{0,0,0.00828945357,0.999965668},{0,0,0.00804249104,0.999967635},{0,0,0.00776108913,0.9999699},{0,0,0.00744645298,0.999972284},{0,0,0.00709992973,0.999974787},{0,0,0.006723003,0.99997741},{0,0,0.00631728722,0.999980032},{0,0,0.00588451838,0.999982715},{0,0,0.00542655075,0.999985278},{0,0,0.00494534476,0.999987781},{0,0,0.00444296096,0.999990106},{0,0,0.0039215507,0.999992311},{0,0,0.0033833466,0.999994278},{0,0,0.00283065368,0.999996006},{0,0,0.00226583867,0.999997437},{0,0,0.00169132021,0.999998569},{0,0,0.00110955862,0.999999404},{0,0,0.000523045484,0.999999881},{0,0,-6.57076816e-05,1},{0,0,-0.000654179428,0.999999762},{0,0,-0.0012398496,0.999999225},{0,0,-0.00182021025,0.999998331},{0,0,-0.00239277584,0.999997139},{0,0,-0.00295509445,0.999995649},{0,0,-0.003504758,0.999993861},{0,0,-0.00403941236,0.999991834},{0,0,-0.00455676904,0.999989629},{0,0,-0.00505461125,0.999987245},{0,0,-0.00553080812,0.999984682},{0,0,-0.00598332006,0.999982119},{0,0,-0.00641020993,0.999979436},{0,0,-0.00680964952,0.999976814},{0,0,-0.00717992848,0.999974251},{0,0,-0.00751946121,0.999971747},{0,0,-0.00782679487,0.999969363},{0,0,-0.00810061302,0.999967217},{0,0,-0.00833974313,0.99996525},{0,0,-0.00854316074,0.999963522},{0,0,-0.00870999694,0.999962091},{0,0,-0.00883953646,0.999960959},{0,0,-0.00893122423,0.999960124},{0,0,-0.00898466725,0.999959648},{0,0,-0.00899963826,0.999959528},{0,0,-0.008976073,0.999959707},{0,0,-0.00891407114,0.999960244},{0,0,-0.00881389901,0.999961138},{0,0,-0.00867598504,0.999962389},{0,0,-0.00850092061,0.99996388},{0,0,-0.00828945357,0.999965668},{0,0,-0.00804249104,0.999967635},{0,0,-0.00776108913,0.9999699},{0,0,-0.00744645298,0.999972284},{0,0,-0.00709992973,0.999974787},{0,0,-0.006723003,0.99997741},{0,0,-0.00631728722,0.999980032},{0,0,-0.00588451838,0.999982715},{0,0,-0.00542655075,0.999985278},{0,0,-0.00494534476,0.999987781},{0,0,-0.00444296096,0.999990106},{0,0,-0.0039215507,0.999992311},{0,0,-0.0033833466,0.999994278},{0,0,-0.00283065368,0.999996006},{0,0,-0.00226583867,0.999997437},{0,0,-0.00169132021,0.999998569},{0,0,-0.00110955862,0.999999404},{0,0,-0.000523045484,0.999999881},{0,0,6.57076816e-05,1},{0,0,0.000654179428,0.999999762},{0,0,0.0012398496,0.999999225},{0,0,0.00182021025,0.999998331},{0,0,0.00239277584,0.999997139},{0,0,0.00295509445,0.999995649},{0,0,0.003504758,0.999993861}}},
{bone="Neck",path="rotation",values={{0,0,0,1},{0,0.000817538996,0,0.999999642},{0,0.00163157668,0,0.999998689},{0,0.00243862672,0,0.99999702},{0,0.00323523232,0,0.999994755},{0,0.00401798263,0,0.999991953},{0,0.00478352467,0,0.999988556},{0,0.0055285804,0,0.999984741},{0,0.00624995911,0,0.99998045},{0,0.00694457209,0,0.99997586},{0,0.0076094442,0,0.999971032},{0,0.00824172981,0,0.999966025},{0,0.00883871969,0,0.999960959},{0,0.00939785969,0,0.999955833},{0,0.00991675444,0,0.999950826},{0,0.0103931827,0,0.999945998},{0,0.0108251059,0,0.999941409},{0,0.0112106744,0,0.999937177},{0,0.0115482379,0,0.999933302},{0,0.01183635,0,0.999929965},{0,0.0120737795,0,0.999927104},{0,0.0122595085,0,0.999924839},{0,0.0123927435,0,0.999923229},{0,0.0124729127,0,0.999922216},{0,0.0124996742,0,0.999921858},{0,0.0124729127,0,0.999922216},{0,0.0123927435,0,0.999923229},{0,0.0122595085,0,0.999924839},{0,0.0120737795,0,0.999927104},{0,0.01183635,0,0.999929965},{0,0.0115482379,0,0.999933302},{0,0.0112106744,0,0.999937177},{0,0.0108251059,0,0.999941409},{0,0.0103931827,0,0.999945998},{0,0.00991675444,0,0.999950826},{0,0.00939785969,0,0.999955833},{0,0.00883871969,0,0.999960959},{0,0.00824172981,0,0.999966025},{0,0.0076094442,0,0.999971032},{0,0.00694457209,0,0.99997586},{0,0.00624995911,0,0.99998045},{0,0.0055285804,0,0.999984741},{0,0.00478352467,0,0.999988556},{0,0.00401798263,0,0.999991953},{0,0.00323523232,0,0.999994755},{0,0.00243862672,0,0.99999702},{0,0.00163157668,0,0.999998689},{0,0.000817538996,0,0.999999642},{0,1.53080846e-18,0,1},{0,-0.000817538996,0,0.999999642},{0,-0.00163157668,0,0.999998689},{0,-0.00243862672,0,0.99999702},{0,-0.00323523232,0,0.999994755},{0,-0.00401798263,0,0.999991953},{0,-0.00478352467,0,0.999988556},{0,-0.0055285804,0,0.999984741},{0,-0.00624995911,0,0.99998045},{0,-0.00694457209,0,0.99997586},{0,-0.0076094442,0,0.999971032},{0,-0.00824172981,0,0.999966025},{0,-0.00883871969,0,0.999960959},{0,-0.00939785969,0,0.999955833},{0,-0.00991675444,0,0.999950826},{0,-0.0103931827,0,0.999945998},{0,-0.0108251059,0,0.999941409},{0,-0.0112106744,0,0.999937177},{0,-0.0115482379,0,0.999933302},{0,-0.01183635,0,0.999929965},{0,-0.0120737795,0,0.999927104},{0,-0.0122595085,0,0.999924839},{0,-0.0123927435,0,0.999923229},{0,-0.0124729127,0,0.999922216},{0,-0.0124996742,0,0.999921858},{0,-0.0124729127,0,0.999922216},{0,-0.0123927435,0,0.999923229},{0,-0.0122595085,0,0.999924839},{0,-0.0120737795,0,0.999927104},{0,-0.01183635,0,0.999929965},{0,-0.0115482379,0,0.999933302},{0,-0.0112106744,0,0.999937177},{0,-0.0108251059,0,0.999941409},{0,-0.0103931827,0,0.999945998},{0,-0.00991675444,0,0.999950826},{0,-0.00939785969,0,0.999955833},{0,-0.00883871969,0,0.999960959},{0,-0.00824172981,0,0.999966025},{0,-0.0076094442,0,0.999971032},{0,-0.00694457209,0,0.99997586},{0,-0.00624995911,0,0.99998045},{0,-0.0055285804,0,0.999984741},{0,-0.00478352467,0,0.999988556},{0,-0.00401798263,0,0.999991953},{0,-0.00323523232,0,0.999994755},{0,-0.00243862672,0,0.99999702},{0,-0.00163157668,0,0.999998689},{0,-0.000817538996,0,0.999999642},{0,-3.06161692e-18,0,1}}},
{bone="Head",path="rotation",values={{0.00705797225,0,0,0.999975085},{0.00771758659,0,0,0.999970198},{0.00834415015,0,0,0.999965191},{0.00893498119,0,0,0.999960065},{0.00948754884,0,0,0.999954998},{0.00999948848,0,0,0.999949992},{0.0104686078,0,0,0.999945223},{0.0108928978,0,0,0.999940693},{0.0112705426,0,0,0.999936461},{0.0115999272,0,0,0.999932706},{0.0118796388,0,0,0.999929428},{0.0121084824,0,0,0.999926686},{0.0122854775,0,0,0.999924541},{0.0124098668,0,0,0.999922991},{0.0124811176,0,0,0.999922097},{0.0124989245,0,0,0.999921858},{0.0124632129,0,0,0.999922335},{0.0123741338,0,0,0.999923408},{0.0122320699,0,0,0.999925196},{0.0120376283,0,0,0.999927521},{0.0117916418,0,0,0.999930501},{0.0114951627,0,0,0.999933958},{0.0111494614,0,0,0.999937832},{0.0107560167,0,0,0.999942124},{0.0103165125,0,0,0.999946773},{0.00983283017,0,0,0.999951661},{0.00930704176,0,0,0.999956667},{0.00874139834,0,0,0.999961793},{0.00813831948,0,0,0.99996686},{0.00750038959,0,0,0.999971867},{0.00683033885,0,0,0.999976695},{0.00613103714,0,0,0.999981225},{0.00540547818,0,0,0.999985397},{0.0046567698,0,0,0.999989152},{0.00388811785,0,0,0.99999243},{0.00310281408,0,0,0.999995172},{0.0023042215,0,0,0.999997318},{0.00149576063,0,0,0.999998868},{0.00068089366,0,0,0.999999762},{-0.000136889488,0,0,1},{-0.00095408631,0,0,0.999999523},{-0.00176719704,0,0,0.99999845},{-0.00257273903,0,0,0.999996662},{-0.00336726289,0,0,0.999994338},{-0.00414736522,0,0,0.999991417},{-0.00490970584,0,0,0.99998796},{-0.00565101951,0,0,0.999984026},{-0.00636813184,0,0,0.999979734},{-0.00705797225,0,0,0.999975085},{-0.00771758659,0,0,0.999970198},{-0.00834415015,0,0,0.999965191},{-0.00893498119,0,0,0.999960065},{-0.00948754884,0,0,0.999954998},{-0.00999948848,0,0,0.999949992},{-0.0104686078,0,0,0.999945223},{-0.0108928978,0,0,0.999940693},{-0.0112705426,0,0,0.999936461},{-0.0115999272,0,0,0.999932706},{-0.0118796388,0,0,0.999929428},{-0.0121084824,0,0,0.999926686},{-0.0122854775,0,0,0.999924541},{-0.0124098668,0,0,0.999922991},{-0.0124811176,0,0,0.999922097},{-0.0124989245,0,0,0.999921858},{-0.0124632129,0,0,0.999922335},{-0.0123741338,0,0,0.999923408},{-0.0122320699,0,0,0.999925196},{-0.0120376283,0,0,0.999927521},{-0.0117916418,0,0,0.999930501},{-0.0114951627,0,0,0.999933958},{-0.0111494614,0,0,0.999937832},{-0.0107560167,0,0,0.999942124},{-0.0103165125,0,0,0.999946773},{-0.00983283017,0,0,0.999951661},{-0.00930704176,0,0,0.999956667},{-0.00874139834,0,0,0.999961793},{-0.00813831948,0,0,0.99996686},{-0.00750038959,0,0,0.999971867},{-0.00683033885,0,0,0.999976695},{-0.00613103714,0,0,0.999981225},{-0.00540547818,0,0,0.999985397},{-0.0046567698,0,0,0.999989152},{-0.00388811785,0,0,0.99999243},{-0.00310281408,0,0,0.999995172},{-0.0023042215,0,0,0.999997318},{-0.00149576063,0,0,0.999998868},{-0.00068089366,0,0,0.999999762},{0.000136889488,0,0,1},{0.00095408631,0,0,0.999999523},{0.00176719704,0,0,0.99999845},{0.00257273903,0,0,0.999996662},{0.00336726289,0,0,0.999994338},{0.00414736522,0,0,0.999991417},{0.00490970584,0,0,0.99998796},{0.00565101951,0,0,0.999984026},{0.00636813184,0,0,0.999979734},{0.00705797225,0,0,0.999975085}}},
{bone="Jaw",path="rotation",values={{0,0,0,1},{0.000261612528,0,0,0.99999994},{0.000522104732,0,0,0.999999881},{0.000780361181,0,0,0.999999702},{0.00103527599,0,0,0.999999464},{0.00128575752,0,0,0.999999166},{0.00153073308,0,0,0.999998808},{0.00176915387,0,0,0.99999845},{0.0019999987,0,0,0.999997973},{0.00222227909,0,0,0.999997556},{0.00243504322,0,0,0.99999702},{0.00263738027,0,0,0.999996543},{0.0028284234,0,0,0.999996006},{0.00300735468,0,0,0.99999547},{0.0031734081,0,0,0.999994993},{0.00332587236,0,0,0.999994457},{0.0034640946,0,0,0.99999398},{0.0035874832,0,0,0.999993563},{0.00369550963,0,0,0.999993145},{0.0037877115,0,0,0.999992847},{0.00386369368,0,0,0.999992549},{0.00392313115,0,0,0.999992311},{0.00396576896,0,0,0.999992132},{0.00399142504,0,0,0.999992013},{0.00399998948,0,0,0.999992013},{0.00399142504,0,0,0.999992013},{0.00396576896,0,0,0.999992132},{0.00392313115,0,0,0.999992311},{0.00386369368,0,0,0.999992549},{0.0037877115,0,0,0.999992847},{0.00369550963,0,0,0.999993145},{0.0035874832,0,0,0.999993563},{0.0034640946,0,0,0.99999398},{0.00332587236,0,0,0.999994457},{0.0031734081,0,0,0.999994993},{0.00300735468,0,0,0.99999547},{0.0028284234,0,0,0.999996006},{0.00263738027,0,0,0.999996543},{0.00243504322,0,0,0.99999702},{0.00222227909,0,0,0.999997556},{0.0019999987,0,0,0.999997973},{0.00176915387,0,0,0.99999845},{0.00153073308,0,0,0.999998808},{0.00128575752,0,0,0.999999166},{0.00103527599,0,0,0.999999464},{0.000780361181,0,0,0.999999702},{0.000522104732,0,0,0.999999881},{0.000261612528,0,0,0.99999994},{4.89858737e-19,0,0,1},{-0.000261612528,0,0,0.99999994},{-0.000522104732,0,0,0.999999881},{-0.000780361181,0,0,0.999999702},{-0.00103527599,0,0,0.999999464},{-0.00128575752,0,0,0.999999166},{-0.00153073308,0,0,0.999998808},{-0.00176915387,0,0,0.99999845},{-0.0019999987,0,0,0.999997973},{-0.00222227909,0,0,0.999997556},{-0.00243504322,0,0,0.99999702},{-0.00263738027,0,0,0.999996543},{-0.0028284234,0,0,0.999996006},{-0.00300735468,0,0,0.99999547},{-0.0031734081,0,0,0.999994993},{-0.00332587236,0,0,0.999994457},{-0.0034640946,0,0,0.99999398},{-0.0035874832,0,0,0.999993563},{-0.00369550963,0,0,0.999993145},{-0.0037877115,0,0,0.999992847},{-0.00386369368,0,0,0.999992549},{-0.00392313115,0,0,0.999992311},{-0.00396576896,0,0,0.999992132},{-0.00399142504,0,0,0.999992013},{-0.00399998948,0,0,0.999992013},{-0.00399142504,0,0,0.999992013},{-0.00396576896,0,0,0.999992132},{-0.00392313115,0,0,0.999992311},{-0.00386369368,0,0,0.999992549},{-0.0037877115,0,0,0.999992847},{-0.00369550963,0,0,0.999993145},{-0.0035874832,0,0,0.999993563},{-0.0034640946,0,0,0.99999398},{-0.00332587236,0,0,0.999994457},{-0.0031734081,0,0,0.999994993},{-0.00300735468,0,0,0.99999547},{-0.0028284234,0,0,0.999996006},{-0.00263738027,0,0,0.999996543},{-0.00243504322,0,0,0.99999702},{-0.00222227909,0,0,0.999997556},{-0.0019999987,0,0,0.999997973},{-0.00176915387,0,0,0.99999845},{-0.00153073308,0,0,0.999998808},{-0.00128575752,0,0,0.999999166},{-0.00103527599,0,0,0.999999464},{-0.000780361181,0,0,0.999999702},{-0.000522104732,0,0,0.999999881},{-0.000261612528,0,0,0.99999994},{-9.79717474e-19,0,0,1}}},
{bone="EarLeft",path="rotation",values={{0,0,0.0116822841,0.999931753},{0,0,0.0134643381,0.999909341},{0,0,0.0151886977,0.999884665},{0,0,0.0168479793,0.999858081},{0,0,0.0184350759,0.999830067},{0,0,0.0199431963,0.999801099},{0,0,0.0213658866,0.999771714},{0,0,0.0226970576,0.999742389},{0,0,0.0239310153,0.9997136},{0,0,0.0250624828,0.999685884},{0,0,0.0260866228,0.999659657},{0,0,0.0269990563,0.999635458},{0,0,0.0277958848,0.999613643},{0,0,0.0284737013,0.999594569},{0,0,0.0290296115,0.999578536},{0,0,0.0294612404,0.999565899},{0,0,0.029766744,0.999556899},{0,0,0.0299448185,0.999551535},{0,0,0.0299947001,0.999550045},{0,0,0.0299161803,0.999552429},{0,0,0.0297095925,0.999558568},{0,0,0.0293758176,0.999568462},{0,0,0.0289162826,0.999581814},{0,0,0.0283329505,0.999598563},{0,0,0.0276283138,0.999618292},{0,0,0.0268053822,0.999640644},{0,0,0.0258676708,0.99966538},{0,0,0.0248191915,0.999691963},{0,0,0.0236644223,0.999719977},{0,0,0.0224083029,0.999748886},{0,0,0.0210562069,0.999778271},{0,0,0.0196139179,0.999807656},{0,0,0.018087605,0.999836385},{0,0,0.0164838023,0.999864161},{0,0,0.0148093775,0.999890327},{0,0,0.013071497,0.999914587},{0,0,0.0112776048,0.999936402},{0,0,0.00943538547,0.999955475},{0,0,0.00755272992,0.999971449},{0,0,0.00563770672,0.999984086},{0,0,0.00369852106,0.999993145},{0,0,0.00174348406,0.99999851},{0,0,-0.000219025605,1},{0,0,-0.00218059658,0.999997616},{0,0,-0.00413282122,0.999991477},{0,0,-0.00606733374,0.999981582},{0,0,-0.00797584187,0.999968171},{0,0,-0.00985016953,0.999951482},{0,0,-0.0116822841,0.999931753},{0,0,-0.0134643381,0.999909341},{0,0,-0.0151886977,0.999884665},{0,0,-0.0168479793,0.999858081},{0,0,-0.0184350759,0.999830067},{0,0,-0.0199431963,0.999801099},{0,0,-0.0213658866,0.999771714},{0,0,-0.0226970576,0.999742389},{0,0,-0.0239310153,0.9997136},{0,0,-0.0250624828,0.999685884},{0,0,-0.0260866228,0.999659657},{0,0,-0.0269990563,0.999635458},{0,0,-0.0277958848,0.999613643},{0,0,-0.0284737013,0.999594569},{0,0,-0.0290296115,0.999578536},{0,0,-0.0294612404,0.999565899},{0,0,-0.029766744,0.999556899},{0,0,-0.0299448185,0.999551535},{0,0,-0.0299947001,0.999550045},{0,0,-0.0299161803,0.999552429},{0,0,-0.0297095925,0.999558568},{0,0,-0.0293758176,0.999568462},{0,0,-0.0289162826,0.999581814},{0,0,-0.0283329505,0.999598563},{0,0,-0.0276283138,0.999618292},{0,0,-0.0268053822,0.999640644},{0,0,-0.0258676708,0.99966538},{0,0,-0.0248191915,0.999691963},{0,0,-0.0236644223,0.999719977},{0,0,-0.0224083029,0.999748886},{0,0,-0.0210562069,0.999778271},{0,0,-0.0196139179,0.999807656},{0,0,-0.018087605,0.999836385},{0,0,-0.0164838023,0.999864161},{0,0,-0.0148093775,0.999890327},{0,0,-0.013071497,0.999914587},{0,0,-0.0112776048,0.999936402},{0,0,-0.00943538547,0.999955475},{0,0,-0.00755272992,0.999971449},{0,0,-0.00563770672,0.999984086},{0,0,-0.00369852106,0.999993145},{0,0,-0.00174348406,0.99999851},{0,0,0.000219025605,1},{0,0,0.00218059658,0.999997616},{0,0,0.00413282122,0.999991477},{0,0,0.00606733374,0.999981582},{0,0,0.00797584187,0.999968171},{0,0,0.00985016953,0.999951482},{0,0,0.0116822841,0.999931753}}},
{bone="EarTipLeft",path="rotation",values={{0.00149937451,0,0,0.999998868},{0.00345579977,0,0,0.99999404},{0.00539741339,0,0,0.999985456},{0.00731589505,0,0,0.999973238},{0.00920302328,0,0,0.999957681},{0.0110507114,0,0,0.999938965},{0.0128510436,0,0,0.999917448},{0.0145963086,0,0,0.999893486},{0.0162790325,0,0,0.999867499},{0.0178920068,0,0,0.999839902},{0.0194283314,0,0,0.999811232},{0.0208814256,0,0,0.999781966},{0.0222450756,0,0,0.999752522},{0.0235134456,0,0,0.999723494},{0.0246811118,0,0,0.999695361},{0.0257430784,0,0,0.999668598},{0.0266948082,0,0,0.999643624},{0.0275322329,0,0,0.999620914},{0.0282517746,0,0,0.999600828},{0.0288503561,0,0,0.999583721},{0.0293254219,0,0,0.999569893},{0.0296749435,0,0,0.999559581},{0.0298974272,0,0,0.999552965},{0.029991921,0,0,0.999550164},{0.0299580246,0,0,0.999551177},{0.0297958814,0,0,0.999556005},{0.0295061842,0,0,0.999564588},{0.029090168,0,0,0.999576807},{0.0285496134,0,0,0.999592364},{0.0278868265,0,0,0.99961108},{0.0271046422,0,0,0.999632597},{0.0262063984,0,0,0.999656558},{0.0251959395,0,0,0.999682546},{0.0240775794,0,0,0.999710083},{0.0228561033,0,0,0.999738753},{0.021536734,0,0,0.999768078},{0.0201251153,0,0,0.999797463},{0.0186272878,0,0,0.999826491},{0.017049659,0,0,0.999854624},{0.0153989838,0,0,0.999881446},{0.01368233,0,0,0.999906421},{0.0119070485,0,0,0.99992913},{0.0100807426,0,0,0.999949217},{0.00821123645,0,0,0.999966264},{0.00630654069,0,0,0.999980092},{0.00437481655,0,0,0.999990404},{0.00242434186,0,0,0.999997079},{0.000463476958,0,0,0.999999881},{-0.00149937451,0,0,0.999998868},{-0.00345579977,0,0,0.99999404},{-0.00539741339,0,0,0.999985456},{-0.00731589505,0,0,0.999973238},{-0.00920302328,0,0,0.999957681},{-0.0110507114,0,0,0.999938965},{-0.0128510436,0,0,0.999917448},{-0.0145963086,0,0,0.999893486},{-0.0162790325,0,0,0.999867499},{-0.0178920068,0,0,0.999839902},{-0.0194283314,0,0,0.999811232},{-0.0208814256,0,0,0.999781966},{-0.0222450756,0,0,0.999752522},{-0.0235134456,0,0,0.999723494},{-0.0246811118,0,0,0.999695361},{-0.0257430784,0,0,0.999668598},{-0.0266948082,0,0,0.999643624},{-0.0275322329,0,0,0.999620914},{-0.0282517746,0,0,0.999600828},{-0.0288503561,0,0,0.999583721},{-0.0293254219,0,0,0.999569893},{-0.0296749435,0,0,0.999559581},{-0.0298974272,0,0,0.999552965},{-0.029991921,0,0,0.999550164},{-0.0299580246,0,0,0.999551177},{-0.0297958814,0,0,0.999556005},{-0.0295061842,0,0,0.999564588},{-0.029090168,0,0,0.999576807},{-0.0285496134,0,0,0.999592364},{-0.0278868265,0,0,0.99961108},{-0.0271046422,0,0,0.999632597},{-0.0262063984,0,0,0.999656558},{-0.0251959395,0,0,0.999682546},{-0.0240775794,0,0,0.999710083},{-0.0228561033,0,0,0.999738753},{-0.021536734,0,0,0.999768078},{-0.0201251153,0,0,0.999797463},{-0.0186272878,0,0,0.999826491},{-0.017049659,0,0,0.999854624},{-0.0153989838,0,0,0.999881446},{-0.01368233,0,0,0.999906421},{-0.0119070485,0,0,0.99992913},{-0.0100807426,0,0,0.999949217},{-0.00821123645,0,0,0.999966264},{-0.00630654069,0,0,0.999980092},{-0.00437481655,0,0,0.999990404},{-0.00242434186,0,0,0.999997079},{-0.000463476958,0,0,0.999999881},{0.00149937451,0,0,0.999998868}}},
{bone="WhiskerLeft",path="rotation",values={{0,0.00778828794,0,0.999969661},{0,0.00897637662,0,0.999959707},{0,0.0101260152,0,0.99994874},{0,0.0112322811,0,0.999936938},{0,0.0122904377,0,0.999924481},{0,0.0132959541,0,0.999911606},{0,0.0142445266,0,0.999898553},{0,0.0151320938,0,0.999885499},{0,0.0159548558,0,0.999872684},{0,0.0167092942,0,0.999860406},{0,0.0173921771,0,0.999848723},{0,0.018000586,0,0.999837995},{0,0.0185319148,0,0.999828279},{0,0.0189838931,0,0.999819815},{0,0.0193545856,0,0.999812663},{0,0.0196424052,0,0.99980706},{0,0.0198461246,0,0.999803066},{0,0.0199648701,0,0.999800682},{0,0.0199981332,0,0.999800026},{0,0.0199457742,0,0.99980104},{0,0.0198080149,0,0.999803782},{0,0.0195854437,0,0.999808192},{0,0.0192790143,0,0.999814153},{0,0.0188900381,0,0.999821544},{0,0.0184201784,0,0.999830306},{0,0.0178714432,0,0.999840319},{0,0.017246183,0,0.999851286},{0,0.0165470708,0,0.999863088},{0,0.0157770999,0,0.999875546},{0,0.0149395643,0,0.99988842},{0,0.0140380478,0,0.999901474},{0,0.0130764106,0,0.999914527},{0,0.0120587684,0,0.999927282},{0,0.0109894788,0,0.99993962},{0,0.00987311825,0,0.999951243},{0,0.00871446915,0,0.999962032},{0,0.00751849171,0,0.999971747},{0,0.00629030867,0,0.999980211},{0,0.00503518013,0,0.999987304},{0,0.00375848217,0,0.999992967},{0,0.00246568397,0,0.99999696},{0,0.00116232305,0,0.999999344},{0,-0.000146017075,0,1},{0,-0.00145373167,0,0.999998927},{0,-0.00275521865,0,0.999996185},{0,-0.00404490298,0,0.999991834},{0,-0.00531725958,0,0.999985874},{0,-0.00656683883,0,0.999978423},{0,-0.00778828794,0,0.999969661},{0,-0.00897637662,0,0.999959707},{0,-0.0101260152,0,0.99994874},{0,-0.0112322811,0,0.999936938},{0,-0.0122904377,0,0.999924481},{0,-0.0132959541,0,0.999911606},{0,-0.0142445266,0,0.999898553},{0,-0.0151320938,0,0.999885499},{0,-0.0159548558,0,0.999872684},{0,-0.0167092942,0,0.999860406},{0,-0.0173921771,0,0.999848723},{0,-0.018000586,0,0.999837995},{0,-0.0185319148,0,0.999828279},{0,-0.0189838931,0,0.999819815},{0,-0.0193545856,0,0.999812663},{0,-0.0196424052,0,0.99980706},{0,-0.0198461246,0,0.999803066},{0,-0.0199648701,0,0.999800682},{0,-0.0199981332,0,0.999800026},{0,-0.0199457742,0,0.99980104},{0,-0.0198080149,0,0.999803782},{0,-0.0195854437,0,0.999808192},{0,-0.0192790143,0,0.999814153},{0,-0.0188900381,0,0.999821544},{0,-0.0184201784,0,0.999830306},{0,-0.0178714432,0,0.999840319},{0,-0.017246183,0,0.999851286},{0,-0.0165470708,0,0.999863088},{0,-0.0157770999,0,0.999875546},{0,-0.0149395643,0,0.99988842},{0,-0.0140380478,0,0.999901474},{0,-0.0130764106,0,0.999914527},{0,-0.0120587684,0,0.999927282},{0,-0.0109894788,0,0.99993962},{0,-0.00987311825,0,0.999951243},{0,-0.00871446915,0,0.999962032},{0,-0.00751849171,0,0.999971747},{0,-0.00629030867,0,0.999980211},{0,-0.00503518013,0,0.999987304},{0,-0.00375848217,0,0.999992967},{0,-0.00246568397,0,0.99999696},{0,-0.00116232305,0,0.999999344},{0,0.000146017075,0,1},{0,0.00145373167,0,0.999998927},{0,0.00275521865,0,0.999996185},{0,0.00404490298,0,0.999991834},{0,0.00531725958,0,0.999985874},{0,0.00656683883,0,0.999978423},{0,0.00778828794,0,0.999969661}}},
{bone="EyeLeft",path="translation",values={{1.78813936e-09,-7.45058126e-10,-4.76837159e-09},{0.000137345791,-7.45058126e-10,-4.76837159e-09},{0.000274108648,-7.45058126e-10,-4.76837159e-09},{0.000409694314,-7.45058126e-10,-4.76837159e-09},{0.000543521643,-7.45058126e-10,-4.76837159e-09},{0.00067502439,-7.45058126e-10,-4.76837159e-09},{0.000803636312,-7.45058126e-10,-4.76837159e-09},{0.000928806067,-7.45058126e-10,-4.76837159e-09},{0.00104999721,-7.45058126e-10,-4.76837159e-09},{0.0011667031,-7.45058126e-10,-4.76837159e-09},{0.00127840221,-7.45058126e-10,-4.76837159e-09},{0.00138463259,-7.45058126e-10,-4.76837159e-09},{0.0014849174,-7.45058126e-10,-4.76837159e-09},{0.00157886922,-7.45058126e-10,-4.76837159e-09},{0.00166604102,-7.45058126e-10,-4.76837159e-09},{0.00174609005,-7.45058126e-10,-4.76837159e-09},{0.00181865871,-7.45058126e-10,-4.76837159e-09},{0.00188343406,-7.45058126e-10,-4.76837159e-09},{0.00194014788,-7.45058126e-10,-4.76837159e-09},{0.00198854685,-7.45058126e-10,-4.76837159e-09},{0.00202843726,-7.45058126e-10,-4.76837159e-09},{0.00205965519,-7.45058126e-10,-4.76837159e-09},{0.00208203673,-7.45058126e-10,-4.76837159e-09},{0.00209550738,-7.45058126e-10,-4.76837159e-09},{0.00209999263,-7.45058126e-10,-4.76837159e-09},{0.00209550738,-7.45058126e-10,-4.76837159e-09},{0.00208203673,-7.45058126e-10,-4.76837159e-09},{0.00205965519,-7.45058126e-10,-4.76837159e-09},{0.00202843726,-7.45058126e-10,-4.76837159e-09},{0.00198854685,-7.45058126e-10,-4.76837159e-09},{0.00194014788,-7.45058126e-10,-4.76837159e-09},{0.00188343406,-7.45058126e-10,-4.76837159e-09},{0.00181865871,-7.45058126e-10,-4.76837159e-09},{0.00174609005,-7.45058126e-10,-4.76837159e-09},{0.00166604102,-7.45058126e-10,-4.76837159e-09},{0.00157886922,-7.45058126e-10,-4.76837159e-09},{0.0014849174,-7.45058126e-10,-4.76837159e-09},{0.00138463259,-7.45058126e-10,-4.76837159e-09},{0.00127840221,-7.45058126e-10,-4.76837159e-09},{0.0011667031,-7.45058126e-10,-4.76837159e-09},{0.00104999721,-7.45058126e-10,-4.76837159e-09},{0.000928806067,-7.45058126e-10,-4.76837159e-09},{0.000803636312,-7.45058126e-10,-4.76837159e-09},{0.00067502439,-7.45058126e-10,-4.76837159e-09},{0.000543521643,-7.45058126e-10,-4.76837159e-09},{0.000409694314,-7.45058126e-10,-4.76837159e-09},{0.000274108648,-7.45058126e-10,-4.76837159e-09},{0.000137345791,-7.45058126e-10,-4.76837159e-09},{1.78813936e-09,-7.45058126e-10,-4.76837159e-09},{-0.000137342215,-7.45058126e-10,-4.76837159e-09},{-0.000274105072,-7.45058126e-10,-4.76837159e-09},{-0.000409690738,-7.45058126e-10,-4.76837159e-09},{-0.000543518066,-7.45058126e-10,-4.76837159e-09},{-0.000675020814,-7.45058126e-10,-4.76837159e-09},{-0.000803632736,-7.45058126e-10,-4.76837159e-09},{-0.00092880249,-7.45058126e-10,-4.76837159e-09},{-0.00104999363,-7.45058126e-10,-4.76837159e-09},{-0.00116669953,-7.45058126e-10,-4.76837159e-09},{-0.00127839863,-7.45058126e-10,-4.76837159e-09},{-0.00138462901,-7.45058126e-10,-4.76837159e-09},{-0.00148492873,-7.45058126e-10,-4.76837159e-09},{-0.00157886565,-7.45058126e-10,-4.76837159e-09},{-0.00166603744,-7.45058126e-10,-4.76837159e-09},{-0.00174608648,-7.45058126e-10,-4.76837159e-09},{-0.00181865513,-7.45058126e-10,-4.76837159e-09},{-0.00188343048,-7.45058126e-10,-4.76837159e-09},{-0.0019401443,-7.45058126e-10,-4.76837159e-09},{-0.00198855817,-7.45058126e-10,-4.76837159e-09},{-0.00202844858,-7.45058126e-10,-4.76837159e-09},{-0.00205965161,-7.45058126e-10,-4.76837159e-09},{-0.00208203316,-7.45058126e-10,-4.76837159e-09},{-0.00209550381,-7.45058126e-10,-4.76837159e-09},{-0.00210000396,-7.45058126e-10,-4.76837159e-09},{-0.00209550381,-7.45058126e-10,-4.76837159e-09},{-0.00208203316,-7.45058126e-10,-4.76837159e-09},{-0.00205965161,-7.45058126e-10,-4.76837159e-09},{-0.00202844858,-7.45058126e-10,-4.76837159e-09},{-0.00198855817,-7.45058126e-10,-4.76837159e-09},{-0.0019401443,-7.45058126e-10,-4.76837159e-09},{-0.00188343048,-7.45058126e-10,-4.76837159e-09},{-0.00181865513,-7.45058126e-10,-4.76837159e-09},{-0.00174608648,-7.45058126e-10,-4.76837159e-09},{-0.00166603744,-7.45058126e-10,-4.76837159e-09},{-0.00157886565,-7.45058126e-10,-4.76837159e-09},{-0.00148492873,-7.45058126e-10,-4.76837159e-09},{-0.00138462901,-7.45058126e-10,-4.76837159e-09},{-0.00127839863,-7.45058126e-10,-4.76837159e-09},{-0.00116669953,-7.45058126e-10,-4.76837159e-09},{-0.00104999363,-7.45058126e-10,-4.76837159e-09},{-0.00092880249,-7.45058126e-10,-4.76837159e-09},{-0.000803632736,-7.45058126e-10,-4.76837159e-09},{-0.000675020814,-7.45058126e-10,-4.76837159e-09},{-0.000543518066,-7.45058126e-10,-4.76837159e-09},{-0.000409690738,-7.45058126e-10,-4.76837159e-09},{-0.000274105072,-7.45058126e-10,-4.76837159e-09},{-0.000137342215,-7.45058126e-10,-4.76837159e-09},{1.78813936e-09,-7.45058126e-10,-4.76837159e-09}}},
{bone="EarRight",path="rotation",values={{0,0,-0.0116822841,0.999931753},{0,0,-0.00985016953,0.999951482},{0,0,-0.00797584187,0.999968171},{0,0,-0.00606733374,0.999981582},{0,0,-0.00413282122,0.999991477},{0,0,-0.00218059658,0.999997616},{0,0,-0.000219025605,1},{0,0,0.00174348406,0.99999851},{0,0,0.00369852106,0.999993145},{0,0,0.00563770672,0.999984086},{0,0,0.00755272992,0.999971449},{0,0,0.00943538547,0.999955475},{0,0,0.0112776048,0.999936402},{0,0,0.013071497,0.999914587},{0,0,0.0148093775,0.999890327},{0,0,0.0164838023,0.999864161},{0,0,0.018087605,0.999836385},{0,0,0.0196139179,0.999807656},{0,0,0.0210562069,0.999778271},{0,0,0.0224083029,0.999748886},{0,0,0.0236644223,0.999719977},{0,0,0.0248191915,0.999691963},{0,0,0.0258676708,0.99966538},{0,0,0.0268053822,0.999640644},{0,0,0.0276283138,0.999618292},{0,0,0.0283329505,0.999598563},{0,0,0.0289162826,0.999581814},{0,0,0.0293758176,0.999568462},{0,0,0.0297095925,0.999558568},{0,0,0.0299161803,0.999552429},{0,0,0.0299947001,0.999550045},{0,0,0.0299448185,0.999551535},{0,0,0.029766744,0.999556899},{0,0,0.0294612404,0.999565899},{0,0,0.0290296115,0.999578536},{0,0,0.0284737013,0.999594569},{0,0,0.0277958848,0.999613643},{0,0,0.0269990563,0.999635458},{0,0,0.0260866228,0.999659657},{0,0,0.0250624828,0.999685884},{0,0,0.0239310153,0.9997136},{0,0,0.0226970576,0.999742389},{0,0,0.0213658866,0.999771714},{0,0,0.0199431963,0.999801099},{0,0,0.0184350759,0.999830067},{0,0,0.0168479793,0.999858081},{0,0,0.0151886977,0.999884665},{0,0,0.0134643381,0.999909341},{0,0,0.0116822841,0.999931753},{0,0,0.00985016953,0.999951482},{0,0,0.00797584187,0.999968171},{0,0,0.00606733374,0.999981582},{0,0,0.00413282122,0.999991477},{0,0,0.00218059658,0.999997616},{0,0,0.000219025605,1},{0,0,-0.00174348406,0.99999851},{0,0,-0.00369852106,0.999993145},{0,0,-0.00563770672,0.999984086},{0,0,-0.00755272992,0.999971449},{0,0,-0.00943538547,0.999955475},{0,0,-0.0112776048,0.999936402},{0,0,-0.013071497,0.999914587},{0,0,-0.0148093775,0.999890327},{0,0,-0.0164838023,0.999864161},{0,0,-0.018087605,0.999836385},{0,0,-0.0196139179,0.999807656},{0,0,-0.0210562069,0.999778271},{0,0,-0.0224083029,0.999748886},{0,0,-0.0236644223,0.999719977},{0,0,-0.0248191915,0.999691963},{0,0,-0.0258676708,0.99966538},{0,0,-0.0268053822,0.999640644},{0,0,-0.0276283138,0.999618292},{0,0,-0.0283329505,0.999598563},{0,0,-0.0289162826,0.999581814},{0,0,-0.0293758176,0.999568462},{0,0,-0.0297095925,0.999558568},{0,0,-0.0299161803,0.999552429},{0,0,-0.0299947001,0.999550045},{0,0,-0.0299448185,0.999551535},{0,0,-0.029766744,0.999556899},{0,0,-0.0294612404,0.999565899},{0,0,-0.0290296115,0.999578536},{0,0,-0.0284737013,0.999594569},{0,0,-0.0277958848,0.999613643},{0,0,-0.0269990563,0.999635458},{0,0,-0.0260866228,0.999659657},{0,0,-0.0250624828,0.999685884},{0,0,-0.0239310153,0.9997136},{0,0,-0.0226970576,0.999742389},{0,0,-0.0213658866,0.999771714},{0,0,-0.0199431963,0.999801099},{0,0,-0.0184350759,0.999830067},{0,0,-0.0168479793,0.999858081},{0,0,-0.0151886977,0.999884665},{0,0,-0.0134643381,0.999909341},{0,0,-0.0116822841,0.999931753}}},
{bone="EarTipRight",path="rotation",values={{-0.0204477385,0,0,0.999790907},{-0.0189685989,0,0,0.999820054},{-0.0174082015,0,0,0.999848485},{-0.0157732219,0,0,0.999875605},{-0.0140706599,0,0,0.999900997},{-0.0123078069,0,0,0.999924242},{-0.010492214,0,0,0.999944985},{-0.00863165781,0,0,0.999962747},{-0.00673411041,0,0,0.99997735},{-0.00480770227,0,0,0.999988437},{-0.00286068884,0,0,0.999995887},{-0.000901414664,0,0,0.999999583},{0.00106172299,0,0,0.999999464},{0.00302031008,0,0,0.99999541},{0.00496595213,0,0,0.999987662},{0.00689031137,0,0,0.999976277},{0.00878513977,0,0,0.999961436},{0.0106423199,0,0,0.999943376},{0.0124538932,0,0,0.999922454},{0.0142121008,0,0,0.99989903},{0.015909411,0,0,0.999873459},{0.0175385568,0,0,0.99984616},{0.0190925635,0,0,0.999817729},{0.0205647796,0,0,0.999788523},{0.0219489038,0,0,0.999759078},{0.0232390147,0,0,0.999729931},{0.0244295951,0,0,0.99970156},{0.0255155545,0,0,0.999674439},{0.0264922474,0,0,0.999649048},{0.0273555014,0,0,0.999625742},{0.0281016268,0,0,0.99960506},{0.0287274346,0,0,0.999587297},{0.0292302519,0,0,0.999572694},{0.0296079312,0,0,0.999561608},{0.0298588574,0,0,0.999554098},{0.0299819615,0,0,0.999550462},{0.0299767144,0,0,0.999550581},{0.0298431423,0,0,0.999554574},{0.029581815,0,0,0.999562383},{0.0291938465,0,0,0.999573767},{0.0286808945,0,0,0.999588609},{0.0280451495,0,0,0.999606669},{0.027289331,0,0,0.99962759},{0.0264166649,0,0,0.999651015},{0.0254308823,0,0,0.999676585},{0.0243361983,0,0,0.999703825},{0.02313729,0,0,0.999732316},{0.0218392853,0,0,0.999761522},{0.0204477385,0,0,0.999790907},{0.0189685989,0,0,0.999820054},{0.0174082015,0,0,0.999848485},{0.0157732219,0,0,0.999875605},{0.0140706599,0,0,0.999900997},{0.0123078069,0,0,0.999924242},{0.010492214,0,0,0.999944985},{0.00863165781,0,0,0.999962747},{0.00673411041,0,0,0.99997735},{0.00480770227,0,0,0.999988437},{0.00286068884,0,0,0.999995887},{0.000901414664,0,0,0.999999583},{-0.00106172299,0,0,0.999999464},{-0.00302031008,0,0,0.99999541},{-0.00496595213,0,0,0.999987662},{-0.00689031137,0,0,0.999976277},{-0.00878513977,0,0,0.999961436},{-0.0106423199,0,0,0.999943376},{-0.0124538932,0,0,0.999922454},{-0.0142121008,0,0,0.99989903},{-0.015909411,0,0,0.999873459},{-0.0175385568,0,0,0.99984616},{-0.0190925635,0,0,0.999817729},{-0.0205647796,0,0,0.999788523},{-0.0219489038,0,0,0.999759078},{-0.0232390147,0,0,0.999729931},{-0.0244295951,0,0,0.99970156},{-0.0255155545,0,0,0.999674439},{-0.0264922474,0,0,0.999649048},{-0.0273555014,0,0,0.999625742},{-0.0281016268,0,0,0.99960506},{-0.0287274346,0,0,0.999587297},{-0.0292302519,0,0,0.999572694},{-0.0296079312,0,0,0.999561608},{-0.0298588574,0,0,0.999554098},{-0.0299819615,0,0,0.999550462},{-0.0299767144,0,0,0.999550581},{-0.0298431423,0,0,0.999554574},{-0.029581815,0,0,0.999562383},{-0.0291938465,0,0,0.999573767},{-0.0286808945,0,0,0.999588609},{-0.0280451495,0,0,0.999606669},{-0.027289331,0,0,0.99962759},{-0.0264166649,0,0,0.999651015},{-0.0254308823,0,0,0.999676585},{-0.0243361983,0,0,0.999703825},{-0.02313729,0,0,0.999732316},{-0.0218392853,0,0,0.999761522},{-0.0204477385,0,0,0.999790907}}},
{bone="WhiskerRight",path="rotation",values={{0,-0.00778828794,0,0.999969661},{0,-0.00656683883,0,0.999978423},{0,-0.00531725958,0,0.999985874},{0,-0.00404490298,0,0.999991834},{0,-0.00275521865,0,0.999996185},{0,-0.00145373167,0,0.999998927},{0,-0.000146017075,0,1},{0,0.00116232305,0,0.999999344},{0,0.00246568397,0,0.99999696},{0,0.00375848217,0,0.999992967},{0,0.00503518013,0,0.999987304},{0,0.00629030867,0,0.999980211},{0,0.00751849171,0,0.999971747},{0,0.00871446915,0,0.999962032},{0,0.00987311825,0,0.999951243},{0,0.0109894788,0,0.99993962},{0,0.0120587684,0,0.999927282},{0,0.0130764106,0,0.999914527},{0,0.0140380478,0,0.999901474},{0,0.0149395643,0,0.99988842},{0,0.0157770999,0,0.999875546},{0,0.0165470708,0,0.999863088},{0,0.017246183,0,0.999851286},{0,0.0178714432,0,0.999840319},{0,0.0184201784,0,0.999830306},{0,0.0188900381,0,0.999821544},{0,0.0192790143,0,0.999814153},{0,0.0195854437,0,0.999808192},{0,0.0198080149,0,0.999803782},{0,0.0199457742,0,0.99980104},{0,0.0199981332,0,0.999800026},{0,0.0199648701,0,0.999800682},{0,0.0198461246,0,0.999803066},{0,0.0196424052,0,0.99980706},{0,0.0193545856,0,0.999812663},{0,0.0189838931,0,0.999819815},{0,0.0185319148,0,0.999828279},{0,0.018000586,0,0.999837995},{0,0.0173921771,0,0.999848723},{0,0.0167092942,0,0.999860406},{0,0.0159548558,0,0.999872684},{0,0.0151320938,0,0.999885499},{0,0.0142445266,0,0.999898553},{0,0.0132959541,0,0.999911606},{0,0.0122904377,0,0.999924481},{0,0.0112322811,0,0.999936938},{0,0.0101260152,0,0.99994874},{0,0.00897637662,0,0.999959707},{0,0.00778828794,0,0.999969661},{0,0.00656683883,0,0.999978423},{0,0.00531725958,0,0.999985874},{0,0.00404490298,0,0.999991834},{0,0.00275521865,0,0.999996185},{0,0.00145373167,0,0.999998927},{0,0.000146017075,0,1},{0,-0.00116232305,0,0.999999344},{0,-0.00246568397,0,0.99999696},{0,-0.00375848217,0,0.999992967},{0,-0.00503518013,0,0.999987304},{0,-0.00629030867,0,0.999980211},{0,-0.00751849171,0,0.999971747},{0,-0.00871446915,0,0.999962032},{0,-0.00987311825,0,0.999951243},{0,-0.0109894788,0,0.99993962},{0,-0.0120587684,0,0.999927282},{0,-0.0130764106,0,0.999914527},{0,-0.0140380478,0,0.999901474},{0,-0.0149395643,0,0.99988842},{0,-0.0157770999,0,0.999875546},{0,-0.0165470708,0,0.999863088},{0,-0.017246183,0,0.999851286},{0,-0.0178714432,0,0.999840319},{0,-0.0184201784,0,0.999830306},{0,-0.0188900381,0,0.999821544},{0,-0.0192790143,0,0.999814153},{0,-0.0195854437,0,0.999808192},{0,-0.0198080149,0,0.999803782},{0,-0.0199457742,0,0.99980104},{0,-0.0199981332,0,0.999800026},{0,-0.0199648701,0,0.999800682},{0,-0.0198461246,0,0.999803066},{0,-0.0196424052,0,0.99980706},{0,-0.0193545856,0,0.999812663},{0,-0.0189838931,0,0.999819815},{0,-0.0185319148,0,0.999828279},{0,-0.018000586,0,0.999837995},{0,-0.0173921771,0,0.999848723},{0,-0.0167092942,0,0.999860406},{0,-0.0159548558,0,0.999872684},{0,-0.0151320938,0,0.999885499},{0,-0.0142445266,0,0.999898553},{0,-0.0132959541,0,0.999911606},{0,-0.0122904377,0,0.999924481},{0,-0.0112322811,0,0.999936938},{0,-0.0101260152,0,0.99994874},{0,-0.00897637662,0,0.999959707},{0,-0.00778828794,0,0.999969661}}},
{bone="EyeRight",path="translation",values={{-5.96046434e-10,-7.45058126e-10,-4.76837159e-09},{0.000137343407,-7.45058126e-10,-4.76837159e-09},{0.000274106264,-7.45058126e-10,-4.76837159e-09},{0.00040969193,-7.45058126e-10,-4.76837159e-09},{0.000543519258,-7.45058126e-10,-4.76837159e-09},{0.000675022006,-7.45058126e-10,-4.76837159e-09},{0.000803633928,-7.45058126e-10,-4.76837159e-09},{0.000928803682,-7.45058126e-10,-4.76837159e-09},{0.00104999483,-7.45058126e-10,-4.76837159e-09},{0.00116670072,-7.45058126e-10,-4.76837159e-09},{0.00127839983,-7.45058126e-10,-4.76837159e-09},{0.0013846302,-7.45058126e-10,-4.76837159e-09},{0.00148492992,-7.45058126e-10,-4.76837159e-09},{0.00157886684,-7.45058126e-10,-4.76837159e-09},{0.00166603863,-7.45058126e-10,-4.76837159e-09},{0.00174608767,-7.45058126e-10,-4.76837159e-09},{0.00181865633,-7.45058126e-10,-4.76837159e-09},{0.00188343167,-7.45058126e-10,-4.76837159e-09},{0.00194014549,-7.45058126e-10,-4.76837159e-09},{0.00198855937,-7.45058126e-10,-4.76837159e-09},{0.00202844977,-7.45058126e-10,-4.76837159e-09},{0.00205965281,-7.45058126e-10,-4.76837159e-09},{0.00208203435,-7.45058126e-10,-4.76837159e-09},{0.002095505,-7.45058126e-10,-4.76837159e-09},{0.00210000515,-7.45058126e-10,-4.76837159e-09},{0.002095505,-7.45058126e-10,-4.76837159e-09},{0.00208203435,-7.45058126e-10,-4.76837159e-09},{0.00205965281,-7.45058126e-10,-4.76837159e-09},{0.00202844977,-7.45058126e-10,-4.76837159e-09},{0.00198855937,-7.45058126e-10,-4.76837159e-09},{0.00194014549,-7.45058126e-10,-4.76837159e-09},{0.00188343167,-7.45058126e-10,-4.76837159e-09},{0.00181865633,-7.45058126e-10,-4.76837159e-09},{0.00174608767,-7.45058126e-10,-4.76837159e-09},{0.00166603863,-7.45058126e-10,-4.76837159e-09},{0.00157886684,-7.45058126e-10,-4.76837159e-09},{0.00148492992,-7.45058126e-10,-4.76837159e-09},{0.0013846302,-7.45058126e-10,-4.76837159e-09},{0.00127839983,-7.45058126e-10,-4.76837159e-09},{0.00116670072,-7.45058126e-10,-4.76837159e-09},{0.00104999483,-7.45058126e-10,-4.76837159e-09},{0.000928803682,-7.45058126e-10,-4.76837159e-09},{0.000803633928,-7.45058126e-10,-4.76837159e-09},{0.000675022006,-7.45058126e-10,-4.76837159e-09},{0.000543519258,-7.45058126e-10,-4.76837159e-09},{0.00040969193,-7.45058126e-10,-4.76837159e-09},{0.000274106264,-7.45058126e-10,-4.76837159e-09},{0.000137343407,-7.45058126e-10,-4.76837159e-09},{-5.96046434e-10,-7.45058126e-10,-4.76837159e-09},{-0.000137344599,-7.45058126e-10,-4.76837159e-09},{-0.000274107456,-7.45058126e-10,-4.76837159e-09},{-0.000409693122,-7.45058126e-10,-4.76837159e-09},{-0.000543520451,-7.45058126e-10,-4.76837159e-09},{-0.000675023198,-7.45058126e-10,-4.76837159e-09},{-0.00080363512,-7.45058126e-10,-4.76837159e-09},{-0.000928804874,-7.45058126e-10,-4.76837159e-09},{-0.00104999602,-7.45058126e-10,-4.76837159e-09},{-0.00116670191,-7.45058126e-10,-4.76837159e-09},{-0.00127840102,-7.45058126e-10,-4.76837159e-09},{-0.0013846314,-7.45058126e-10,-4.76837159e-09},{-0.00148493111,-7.45058126e-10,-4.76837159e-09},{-0.00157886803,-7.45058126e-10,-4.76837159e-09},{-0.00166603982,-7.45058126e-10,-4.76837159e-09},{-0.00174608886,-7.45058126e-10,-4.76837159e-09},{-0.00181865752,-7.45058126e-10,-4.76837159e-09},{-0.00188343287,-7.45058126e-10,-4.76837159e-09},{-0.00194014668,-7.45058126e-10,-4.76837159e-09},{-0.00198856056,-7.45058126e-10,-4.76837159e-09},{-0.00202845097,-7.45058126e-10,-4.76837159e-09},{-0.002059654,-7.45058126e-10,-4.76837159e-09},{-0.00208203554,-7.45058126e-10,-4.76837159e-09},{-0.00209550619,-7.45058126e-10,-4.76837159e-09},{-0.00210000634,-7.45058126e-10,-4.76837159e-09},{-0.00209550619,-7.45058126e-10,-4.76837159e-09},{-0.00208203554,-7.45058126e-10,-4.76837159e-09},{-0.002059654,-7.45058126e-10,-4.76837159e-09},{-0.00202845097,-7.45058126e-10,-4.76837159e-09},{-0.00198856056,-7.45058126e-10,-4.76837159e-09},{-0.00194014668,-7.45058126e-10,-4.76837159e-09},{-0.00188343287,-7.45058126e-10,-4.76837159e-09},{-0.00181865752,-7.45058126e-10,-4.76837159e-09},{-0.00174608886,-7.45058126e-10,-4.76837159e-09},{-0.00166603982,-7.45058126e-10,-4.76837159e-09},{-0.00157886803,-7.45058126e-10,-4.76837159e-09},{-0.00148493111,-7.45058126e-10,-4.76837159e-09},{-0.0013846314,-7.45058126e-10,-4.76837159e-09},{-0.00127840102,-7.45058126e-10,-4.76837159e-09},{-0.00116670191,-7.45058126e-10,-4.76837159e-09},{-0.00104999602,-7.45058126e-10,-4.76837159e-09},{-0.000928804874,-7.45058126e-10,-4.76837159e-09},{-0.00080363512,-7.45058126e-10,-4.76837159e-09},{-0.000675023198,-7.45058126e-10,-4.76837159e-09},{-0.000543520451,-7.45058126e-10,-4.76837159e-09},{-0.000409693122,-7.45058126e-10,-4.76837159e-09},{-0.000274107456,-7.45058126e-10,-4.76837159e-09},{-0.000137344599,-7.45058126e-10,-4.76837159e-09},{-5.96046434e-10,-7.45058126e-10,-4.76837159e-09}}},
{bone="Sprout",path="rotation",values={{0,0,-0.0107087996,0.99994266},{0,0,-0.00902934559,0.99995923},{0,0,-0.00731120119,0.999973297},{0,0,-0.00556172803,0.999984562},{0,0,-0.0037884214,0.999992847},{0,0,-0.00199888041,0.999997973},{0,0,-0.000200773473,1},{0,0,0.00159819389,0.999998748},{0,0,0.00339031219,0.999994278},{0,0,0.00516790198,0.999986649},{0,0,0.00692334631,0.999976039},{0,0,0.00864912383,0.999962568},{0,0,0.0103378389,0.999946535},{0,0,0.0119822603,0.999928236},{0,0,0.0135753416,0.999907851},{0,0,0.0151102617,0.999885857},{0,0,0.0165804494,0.999862552},{0,0,0.0179796088,0.999838352},{0,0,0.0193017516,0.999813676},{0,0,0.020541219,0.999789},{0,0,0.02169271,0.999764681},{0,0,0.0227512978,0.999741137},{0,0,0.0237124544,0.999718845},{0,0,0.0245720707,0.999698043},{0,0,0.0253264699,0.999679208},{0,0,0.0259724278,0.999662638},{0,0,0.0265071839,0.999648631},{0,0,0.0269284528,0.999637365},{0,0,0.0272344332,0.99962908},{0,0,0.0274238195,0.999623895},{0,0,0.0274958014,0.999621928},{0,0,0.0274500716,0.999623179},{0,0,0.0272868257,0.99962765},{0,0,0.0270067621,0.999635279},{0,0,0.0266110748,0.999645889},{0,0,0.026101457,0.9996593},{0,0,0.0254800841,0.999675333},{0,0,0.0247496162,0.999693692},{0,0,0.0239131711,0.999714017},{0,0,0.0229743272,0.999736071},{0,0,0.0219370984,0.999759376},{0,0,0.0208059214,0.999783516},{0,0,0.0195856337,0.999808192},{0,0,0.0182814579,0.999832869},{0,0,0.0168989729,0.999857187},{0,0,0.0154440971,0.999880731},{0,0,0.0139230583,0.999903083},{0,0,0.0123423701,0.999923825},{0,0,0.0107087996,0.99994266},{0,0,0.00902934559,0.99995923},{0,0,0.00731120119,0.999973297},{0,0,0.00556172803,0.999984562},{0,0,0.0037884214,0.999992847},{0,0,0.00199888041,0.999997973},{0,0,0.000200773473,1},{0,0,-0.00159819389,0.999998748},{0,0,-0.00339031219,0.999994278},{0,0,-0.00516790198,0.999986649},{0,0,-0.00692334631,0.999976039},{0,0,-0.00864912383,0.999962568},{0,0,-0.0103378389,0.999946535},{0,0,-0.0119822603,0.999928236},{0,0,-0.0135753416,0.999907851},{0,0,-0.0151102617,0.999885857},{0,0,-0.0165804494,0.999862552},{0,0,-0.0179796088,0.999838352},{0,0,-0.0193017516,0.999813676},{0,0,-0.020541219,0.999789},{0,0,-0.02169271,0.999764681},{0,0,-0.0227512978,0.999741137},{0,0,-0.0237124544,0.999718845},{0,0,-0.0245720707,0.999698043},{0,0,-0.0253264699,0.999679208},{0,0,-0.0259724278,0.999662638},{0,0,-0.0265071839,0.999648631},{0,0,-0.0269284528,0.999637365},{0,0,-0.0272344332,0.99962908},{0,0,-0.0274238195,0.999623895},{0,0,-0.0274958014,0.999621928},{0,0,-0.0274500716,0.999623179},{0,0,-0.0272868257,0.99962765},{0,0,-0.0270067621,0.999635279},{0,0,-0.0266110748,0.999645889},{0,0,-0.026101457,0.9996593},{0,0,-0.0254800841,0.999675333},{0,0,-0.0247496162,0.999693692},{0,0,-0.0239131711,0.999714017},{0,0,-0.0229743272,0.999736071},{0,0,-0.0219370984,0.999759376},{0,0,-0.0208059214,0.999783516},{0,0,-0.0195856337,0.999808192},{0,0,-0.0182814579,0.999832869},{0,0,-0.0168989729,0.999857187},{0,0,-0.0154440971,0.999880731},{0,0,-0.0139230583,0.999903083},{0,0,-0.0123423701,0.999923825},{0,0,-0.0107087996,0.99994266}}},
{bone="SproutTip",path="rotation",values={{0,0,-0.0197260138,0.99980545},{0,0,-0.018430924,0.999830127},{0,0,-0.017056888,0.999854505},{0,0,-0.0156097841,0.999878168},{0,0,-0.0140958084,0.999900639},{0,0,-0.012521442,0.99992162},{0,0,-0.0108934278,0.999940693},{0,0,-0.00921873935,0.999957502},{0,0,-0.00750454888,0.999971867},{0,0,-0.00575820077,0.99998343},{0,0,-0.00398717821,0.999992073},{0,0,-0.00219906913,0.999997556},{0,0,-0.000401536236,0.99999994},{0,0,0.00139771739,0.999999046},{0,0,0.00319098122,0.999994934},{0,0,0.00497057056,0.999987662},{0,0,0.00672886008,0.99997735},{0,0,0.00845831539,0.999964237},{0,0,0.0101515269,0.999948502},{0,0,0.0118012419,0.999930382},{0,0,0.0134003926,0.999910235},{0,0,0.014942131,0.999888361},{0,0,0.0164198559,0.999865174},{0,0,0.0178272408,0.999841094},{0,0,0.0191582628,0.999816477},{0,0,0.0204072222,0.999791741},{0,0,0.0215687789,0.999767363},{0,0,0.0226379614,0.9997437},{0,0,0.023610197,0.999721229},{0,0,0.0244813301,0.999700308},{0,0,0.0252476335,0.999681234},{0,0,0.0259058345,0.999664366},{0,0,0.0264531169,0.999650061},{0,0,0.026887143,0.999638498},{0,0,0.0272060595,0.999629855},{0,0,0.0274085011,0.999624312},{0,0,0.0274936035,0.999621987},{0,0,0.0274610035,0.999622881},{0,0,0.0273108426,0.999626994},{0,0,0.027043758,0.999634266},{0,0,0.026660895,0.999644518},{0,0,0.0261638854,0.999657691},{0,0,0.0255548581,0.999673426},{0,0,0.0248364117,0.999691546},{0,0,0.0240116194,0.999711692},{0,0,0.0230840072,0.999733508},{0,0,0.0220575426,0.999756694},{0,0,0.020936612,0.999780834},{0,0,0.0197260138,0.99980545},{0,0,0.018430924,0.999830127},{0,0,0.017056888,0.999854505},{0,0,0.0156097841,0.999878168},{0,0,0.0140958084,0.999900639},{0,0,0.012521442,0.99992162},{0,0,0.0108934278,0.999940693},{0,0,0.00921873935,0.999957502},{0,0,0.00750454888,0.999971867},{0,0,0.00575820077,0.99998343},{0,0,0.00398717821,0.999992073},{0,0,0.00219906913,0.999997556},{0,0,0.000401536236,0.99999994},{0,0,-0.00139771739,0.999999046},{0,0,-0.00319098122,0.999994934},{0,0,-0.00497057056,0.999987662},{0,0,-0.00672886008,0.99997735},{0,0,-0.00845831539,0.999964237},{0,0,-0.0101515269,0.999948502},{0,0,-0.0118012419,0.999930382},{0,0,-0.0134003926,0.999910235},{0,0,-0.014942131,0.999888361},{0,0,-0.0164198559,0.999865174},{0,0,-0.0178272408,0.999841094},{0,0,-0.0191582628,0.999816477},{0,0,-0.0204072222,0.999791741},{0,0,-0.0215687789,0.999767363},{0,0,-0.0226379614,0.9997437},{0,0,-0.023610197,0.999721229},{0,0,-0.0244813301,0.999700308},{0,0,-0.0252476335,0.999681234},{0,0,-0.0259058345,0.999664366},{0,0,-0.0264531169,0.999650061},{0,0,-0.026887143,0.999638498},{0,0,-0.0272060595,0.999629855},{0,0,-0.0274085011,0.999624312},{0,0,-0.0274936035,0.999621987},{0,0,-0.0274610035,0.999622881},{0,0,-0.0273108426,0.999626994},{0,0,-0.027043758,0.999634266},{0,0,-0.026660895,0.999644518},{0,0,-0.0261638854,0.999657691},{0,0,-0.0255548581,0.999673426},{0,0,-0.0248364117,0.999691546},{0,0,-0.0240116194,0.999711692},{0,0,-0.0230840072,0.999733508},{0,0,-0.0220575426,0.999756694},{0,0,-0.020936612,0.999780834},{0,0,-0.0197260138,0.99980545}}},
{bone="Tail1",path="rotation",values={{0,-0.0141359093,0,0.999900103},{0,-0.012191819,0,0.999925673},{0,-0.0101954769,0,0.999948025},{0,-0.00815543626,0,0.999966741},{0,-0.00608043885,0,0.999981523},{0,-0.00397937838,0,0.999992073},{0,-0.00186125981,0,0.999998271},{0,0.000264837261,0,0.99999994},{0,0.00238979911,0,0.999997139},{0,0.00450451672,0,0.999989867},{0,0.00659992546,0,0.999978244},{0,0.00866704434,0,0.999962449},{0,0.0106970137,0,0.99994278},{0,0.0126811368,0,0.999919593},{0,0.0146109108,0,0.999893248},{0,0.016478071,0,0.999864221},{0,0.0182746202,0,0.999832988},{0,0.0199928675,0,0.999800146},{0,0.0216254573,0,0.999766171},{0,0.0231654029,0,0.99973166},{0,0.024606118,0,0.999697208},{0,0.025941439,0,0.999663472},{0,0.0271656588,0,0.999630928},{0,0.0282735415,0,0.999600232},{0,0.0292603541,0,0.9995718},{0,0.0301218797,0,0.99954623},{0,0.0308544394,0,0.999523878},{0,0.0314549021,0,0.999505162},{0,0.0319207087,0,0.99949038},{0,0.0322498642,0,0.99947983},{0,0.0324409679,0,0.999473631},{0,0.0324932002,0,0.999471962},{0,0.0324063413,0,0.999474764},{0,0.0321807638,0,0.999482036},{0,0.031817425,0,0.999493718},{0,0.0313178822,0,0.999509454},{0,0.0306842607,0,0.999529123},{0,0.0299192742,0,0.99955231},{0,0.0290261842,0,0.999578655},{0,0.0280088093,0,0.999607682},{0,0.0268714949,0,0.999638915},{0,0.0256191008,0,0.999671757},{0,0.0242569838,0,0.999705732},{0,0.0227909666,0,0.999740243},{0,0.0212273169,0,0.999774694},{0,0.0195727292,0,0.999808431},{0,0.0178342834,0,0.999840975},{0,0.0160194188,0,0.999871671},{0,0.0141359093,0,0.999900103},{0,0.012191819,0,0.999925673},{0,0.0101954769,0,0.999948025},{0,0.00815543626,0,0.999966741},{0,0.00608043885,0,0.999981523},{0,0.00397937838,0,0.999992073},{0,0.00186125981,0,0.999998271},{0,-0.000264837261,0,0.99999994},{0,-0.00238979911,0,0.999997139},{0,-0.00450451672,0,0.999989867},{0,-0.00659992546,0,0.999978244},{0,-0.00866704434,0,0.999962449},{0,-0.0106970137,0,0.99994278},{0,-0.0126811368,0,0.999919593},{0,-0.0146109108,0,0.999893248},{0,-0.016478071,0,0.999864221},{0,-0.0182746202,0,0.999832988},{0,-0.0199928675,0,0.999800146},{0,-0.0216254573,0,0.999766171},{0,-0.0231654029,0,0.99973166},{0,-0.024606118,0,0.999697208},{0,-0.025941439,0,0.999663472},{0,-0.0271656588,0,0.999630928},{0,-0.0282735415,0,0.999600232},{0,-0.0292603541,0,0.9995718},{0,-0.0301218797,0,0.99954623},{0,-0.0308544394,0,0.999523878},{0,-0.0314549021,0,0.999505162},{0,-0.0319207087,0,0.99949038},{0,-0.0322498642,0,0.99947983},{0,-0.0324409679,0,0.999473631},{0,-0.0324932002,0,0.999471962},{0,-0.0324063413,0,0.999474764},{0,-0.0321807638,0,0.999482036},{0,-0.031817425,0,0.999493718},{0,-0.0313178822,0,0.999509454},{0,-0.0306842607,0,0.999529123},{0,-0.0299192742,0,0.99955231},{0,-0.0290261842,0,0.999578655},{0,-0.0280088093,0,0.999607682},{0,-0.0268714949,0,0.999638915},{0,-0.0256191008,0,0.999671757},{0,-0.0242569838,0,0.999705732},{0,-0.0227909666,0,0.999740243},{0,-0.0212273169,0,0.999774694},{0,-0.0195727292,0,0.999808431},{0,-0.0178342834,0,0.999840975},{0,-0.0160194188,0,0.999871671},{0,-0.0141359093,0,0.999900103}}},
{bone="Tail2",path="rotation",values={{0,-0.0254553743,0,0.999675989},{0,-0.0240799934,0,0.999710023},{0,-0.0226014704,0,0.999744534},{0,-0.021026127,0,0.999778926},{0,-0.0193607043,0,0.999812543},{0,-0.0176123306,0,0.999844909},{0,-0.01578849,0,0.999875367},{0,-0.0138969915,0,0.99990344},{0,-0.0119459368,0,0.999928653},{0,-0.00994368363,0,0.999950588},{0,-0.00789881032,0,0.999968827},{0,-0.00582008064,0,0.999983072},{0,-0.00371640362,0,0.999993086},{0,-0.00159679586,0,0.999998748},{0,0.000529656885,0,0.999999881},{0,0.00265383907,0,0.999996483},{0,0.00476664538,0,0.999988616},{0,0.0068590194,0,0.999976456},{0,0.00892199297,0,0.999960184},{0,0.0109467246,0,0.999940097},{0,0.0129245389,0,0.999916494},{0,0.0148469629,0,0.999889791},{0,0.0167057607,0,0.999860466},{0,0.0184929743,0,0.999828994},{0,0.0202009492,0,0.999795914},{0,0.021822378,0,0.999761879},{0,0.0233503208,0,0.999727368},{0,0.0247782394,0,0.999692976},{0,0.0261000302,0,0.999659359},{0,0.0273100398,0,0.999626994},{0,0.0284030959,0,0.999596536},{0,0.0293745287,0,0.999568462},{0,0.0302201863,0,0.99954325},{0,0.0309364572,0,0.999521375},{0,0.0315202847,0,0.999503136},{0,0.031969171,0,0.999488831},{0,0.0322812051,0,0.999478817},{0,0.0324550495,0,0.999473214},{0,0.0324899666,0,0.999472082},{0,0.0323858038,0,0.99947542},{0,0.032143008,0,0.999483287},{0,0.0317626148,0,0.999495447},{0,0.0312462486,0,0.999511719},{0,0.0305961147,0,0.999531806},{0,0.0298149865,0,0.999555409},{0,0.0289062038,0,0.999582112},{0,0.0278736483,0,0.999611437},{0,0.0267217308,0,0.999642909},{0,0.0254553743,0,0.999675989},{0,0.0240799934,0,0.999710023},{0,0.0226014704,0,0.999744534},{0,0.021026127,0,0.999778926},{0,0.0193607043,0,0.999812543},{0,0.0176123306,0,0.999844909},{0,0.01578849,0,0.999875367},{0,0.0138969915,0,0.99990344},{0,0.0119459368,0,0.999928653},{0,0.00994368363,0,0.999950588},{0,0.00789881032,0,0.999968827},{0,0.00582008064,0,0.999983072},{0,0.00371640362,0,0.999993086},{0,0.00159679586,0,0.999998748},{0,-0.000529656885,0,0.999999881},{0,-0.00265383907,0,0.999996483},{0,-0.00476664538,0,0.999988616},{0,-0.0068590194,0,0.999976456},{0,-0.00892199297,0,0.999960184},{0,-0.0109467246,0,0.999940097},{0,-0.0129245389,0,0.999916494},{0,-0.0148469629,0,0.999889791},{0,-0.0167057607,0,0.999860466},{0,-0.0184929743,0,0.999828994},{0,-0.0202009492,0,0.999795914},{0,-0.021822378,0,0.999761879},{0,-0.0233503208,0,0.999727368},{0,-0.0247782394,0,0.999692976},{0,-0.0261000302,0,0.999659359},{0,-0.0273100398,0,0.999626994},{0,-0.0284030959,0,0.999596536},{0,-0.0293745287,0,0.999568462},{0,-0.0302201863,0,0.99954325},{0,-0.0309364572,0,0.999521375},{0,-0.0315202847,0,0.999503136},{0,-0.031969171,0,0.999488831},{0,-0.0322812051,0,0.999478817},{0,-0.0324550495,0,0.999473214},{0,-0.0324899666,0,0.999472082},{0,-0.0323858038,0,0.99947542},{0,-0.032143008,0,0.999483287},{0,-0.0317626148,0,0.999495447},{0,-0.0312462486,0,0.999511719},{0,-0.0305961147,0,0.999531806},{0,-0.0298149865,0,0.999555409},{0,-0.0289062038,0,0.999582112},{0,-0.0278736483,0,0.999611437},{0,-0.0267217308,0,0.999642909},{0,-0.0254553743,0,0.999675989}}},
{bone="Tail3",path="rotation",values={{0,-0.0317056961,0,0.999497235},{0,-0.0311725419,0,0.999514043},{0,-0.0305059347,0,0.999534607},{0,-0.0297087207,0,0.999558628},{0,-0.0287843049,0,0.999585629},{0,-0.0277366377,0,0.999615252},{0,-0.0265701916,0,0.999646962},{0,-0.0252899565,0,0.999680161},{0,-0.0239014048,0,0.999714315},{0,-0.0224104729,0,0.999748826},{0,-0.0208235383,0,0.999783158},{0,-0.0191473924,0,0.999816656},{0,-0.0173892062,0,0.999848783},{0,-0.0155565105,0,0.999879003},{0,-0.0136571499,0,0.999906719},{0,-0.0116992602,0,0.999931574},{0,-0.00969122909,0,0.999953032},{0,-0.00764165958,0,0.999970794},{0,-0.00555933593,0,0.999984562},{0,-0.00345318206,0,0.99999404},{0,-0.00133222574,0,0.999999106},{0,0.000794441323,0,0.999999702},{0,0.00291770278,0,0.999995768},{0,0.00502845738,0,0.999987364},{0,0.00711765746,0,0.999974668},{0,0.00917634834,0,0.999957919},{0,0.0111957081,0,0.999937356},{0,0.0131670833,0,0.999913335},{0,0.0150820287,0,0.999886274},{0,0.0169323422,0,0.999856651},{0,0.0187100992,0,0.999824941},{0,0.0204076897,0,0.999791741},{0,0.0220178496,0,0.999757588},{0,0.0235336851,0,0.999723017},{0,0.0249487143,0,0.999688745},{0,0.0262568872,0,0.999655247},{0,0.0274526067,0,0.99962312},{0,0.0285307635,0,0.9995929},{0,0.029486753,0,0.999565184},{0,0.030316487,0,0.999540329},{0,0.0310164224,0,0.999518871},{0,0.0315835737,0,0.999501109},{0,0.0320155136,0,0.9994874},{0,0.0323104002,0,0.999477863},{0,0.0324669778,0,0.999472797},{0,0.0324845724,0,0.99947226},{0,0.032363113,0,0.999476194},{0,0.0321031176,0,0.999484539},{0,0.0317056961,0,0.999497235},{0,0.0311725419,0,0.999514043},{0,0.0305059347,0,0.999534607},{0,0.0297087207,0,0.999558628},{0,0.0287843049,0,0.999585629},{0,0.0277366377,0,0.999615252},{0,0.0265701916,0,0.999646962},{0,0.0252899565,0,0.999680161},{0,0.0239014048,0,0.999714315},{0,0.0224104729,0,0.999748826},{0,0.0208235383,0,0.999783158},{0,0.0191473924,0,0.999816656},{0,0.0173892062,0,0.999848783},{0,0.0155565105,0,0.999879003},{0,0.0136571499,0,0.999906719},{0,0.0116992602,0,0.999931574},{0,0.00969122909,0,0.999953032},{0,0.00764165958,0,0.999970794},{0,0.00555933593,0,0.999984562},{0,0.00345318206,0,0.99999404},{0,0.00133222574,0,0.999999106},{0,-0.000794441323,0,0.999999702},{0,-0.00291770278,0,0.999995768},{0,-0.00502845738,0,0.999987364},{0,-0.00711765746,0,0.999974668},{0,-0.00917634834,0,0.999957919},{0,-0.0111957081,0,0.999937356},{0,-0.0131670833,0,0.999913335},{0,-0.0150820287,0,0.999886274},{0,-0.0169323422,0,0.999856651},{0,-0.0187100992,0,0.999824941},{0,-0.0204076897,0,0.999791741},{0,-0.0220178496,0,0.999757588},{0,-0.0235336851,0,0.999723017},{0,-0.0249487143,0,0.999688745},{0,-0.0262568872,0,0.999655247},{0,-0.0274526067,0,0.99962312},{0,-0.0285307635,0,0.9995929},{0,-0.029486753,0,0.999565184},{0,-0.030316487,0,0.999540329},{0,-0.0310164224,0,0.999518871},{0,-0.0315835737,0,0.999501109},{0,-0.0320155136,0,0.9994874},{0,-0.0323104002,0,0.999477863},{0,-0.0324669778,0,0.999472797},{0,-0.0324845724,0,0.99947226},{0,-0.032363113,0,0.999476194},{0,-0.0321031176,0,0.999484539},{0,-0.0317056961,0,0.999497235}}},
{bone="Tail4",path="rotation",values={{0,-0.0316447653,0,0.999499202},{0,-0.0320597291,0,0.99948597},{0,-0.0323374532,0,0.999477029},{0,-0.0324767493,0,0.999472499},{0,-0.0324770249,0,0.999472499},{0,-0.0323382765,0,0.999476969},{0,-0.0320610963,0,0.99948591},{0,-0.0316466689,0,0.999499142},{0,-0.0310967658,0,0.999516368},{0,-0.0304137301,0,0.999537408},{0,-0.0296004824,0,0.999561787},{0,-0.0286604948,0,0.999589205},{0,-0.0275977831,0,0.999619126},{0,-0.0264168903,0,0.999651015},{0,-0.0251228604,0,0.999684393},{0,-0.0237212274,0,0.999718606},{0,-0.0222179871,0,0.999753177},{0,-0.0206195656,0,0.99978739},{0,-0.0189328063,0,0.999820769},{0,-0.0171649288,0,0.999852657},{0,-0.0153234974,0,0.999882579},{0,-0.0134164011,0,0.999909997},{0,-0.0114518059,0,0.999934435},{0,-0.00943813007,0,0.999955475},{0,-0.00738400081,0,0.999972761},{0,-0.00529822148,0,0.999985993},{0,-0.00318973069,0,0.999994934},{0,-0.00106756703,0,0.999999404},{0,0.00105917291,0,0.999999464},{0,0.00318137254,0,0.999994934},{0,0.00528993504,0,0.999985993},{0,0.00737582194,0,0.99997282},{0,0.00943009369,0,0.999955535},{0,0.0114439465,0,0.999934494},{0,0.0134087512,0,0.999910116},{0,0.0153160915,0,0.999882698},{0,0.0171577968,0,0.999852777},{0,0.0189259816,0,0.999820888},{0,0.0206130762,0,0.999787509},{0,0.0222118571,0,0.999753296},{0,0.0237154886,0,0.999718726},{0,0.0251175333,0,0.999684513},{0,0.026411999,0,0.999651134},{0,0.02759335,0,0.999619246},{0,0.0286565386,0,0.999589324},{0,0.0295970179,0,0.999561906},{0,0.0304107741,0,0.999537468},{0,0.0310943294,0,0.999516428},{0,0.0316447653,0,0.999499202},{0,0.0320597291,0,0.99948597},{0,0.0323374532,0,0.999477029},{0,0.0324767493,0,0.999472499},{0,0.0324770249,0,0.999472499},{0,0.0323382765,0,0.999476969},{0,0.0320610963,0,0.99948591},{0,0.0316466689,0,0.999499142},{0,0.0310967658,0,0.999516368},{0,0.0304137301,0,0.999537408},{0,0.0296004824,0,0.999561787},{0,0.0286604948,0,0.999589205},{0,0.0275977831,0,0.999619126},{0,0.0264168903,0,0.999651015},{0,0.0251228604,0,0.999684393},{0,0.0237212274,0,0.999718606},{0,0.0222179871,0,0.999753177},{0,0.0206195656,0,0.99978739},{0,0.0189328063,0,0.999820769},{0,0.0171649288,0,0.999852657},{0,0.0153234974,0,0.999882579},{0,0.0134164011,0,0.999909997},{0,0.0114518059,0,0.999934435},{0,0.00943813007,0,0.999955475},{0,0.00738400081,0,0.999972761},{0,0.00529822148,0,0.999985993},{0,0.00318973069,0,0.999994934},{0,0.00106756703,0,0.999999404},{0,-0.00105917291,0,0.999999464},{0,-0.00318137254,0,0.999994934},{0,-0.00528993504,0,0.999985993},{0,-0.00737582194,0,0.99997282},{0,-0.00943009369,0,0.999955535},{0,-0.0114439465,0,0.999934494},{0,-0.0134087512,0,0.999910116},{0,-0.0153160915,0,0.999882698},{0,-0.0171577968,0,0.999852777},{0,-0.0189259816,0,0.999820888},{0,-0.0206130762,0,0.999787509},{0,-0.0222118571,0,0.999753296},{0,-0.0237154886,0,0.999718726},{0,-0.0251175333,0,0.999684513},{0,-0.026411999,0,0.999651134},{0,-0.02759335,0,0.999619246},{0,-0.0286565386,0,0.999589324},{0,-0.0295970179,0,0.999561906},{0,-0.0304107741,0,0.999537468},{0,-0.0310943294,0,0.999516428},{0,-0.0316447653,0,0.999499202}}},
{bone="Tail5",path="rotation",values={{0,-0.0252846833,0,0.999680281},{0,-0.026565358,0,0.999647081},{0,-0.0277322624,0,0.999615371},{0,-0.0287804082,0,0.999585748},{0,-0.0297053196,0,0.999558687},{0,-0.030503042,0,0.999534667},{0,-0.0311701708,0,0.999514103},{0,-0.0317038558,0,0.999497294},{0,-0.0321018174,0,0.999484599},{0,-0.0323623605,0,0.999476194},{0,-0.0324843675,0,0.99947226},{0,-0.0324673206,0,0.999472797},{0,-0.0323112905,0,0.999477863},{0,-0.0320169479,0,0.99948734},{0,-0.0315855443,0,0.99950105},{0,-0.0310189258,0,0.999518812},{0,-0.0303195082,0,0.999540269},{0,-0.029490279,0,0.999565065},{0,-0.0285347812,0,0.999592781},{0,-0.0274570975,0,0.999623001},{0,-0.0262618326,0,0.999655128},{0,-0.0249540936,0,0.999688625},{0,-0.0235394742,0,0.999722898},{0,-0.0220240243,0,0.999757469},{0,-0.0204142239,0,0.999791622},{0,-0.0187169649,0,0.999824822},{0,-0.0169395078,0,0.999856532},{0,-0.0150894662,0,0.999886155},{0,-0.0131747602,0,0.999913216},{0,-0.0112035917,0,0.999937236},{0,-0.00918440428,0,0.9999578},{0,-0.0071258517,0,0.999974608},{0,-0.00503675453,0,0.999987304},{0,-0.00292606745,0,0.999995708},{0,-0.00080283737,0,0.999999702},{0,0.00132383418,0,0.999999106},{0,0.00344483089,0,0.99999404},{0,0.00555106113,0,0.999984622},{0,0.00763349654,0,0.999970853},{0,0.00968321227,0,0.999953091},{0,0.011691425,0,0.999931633},{0,0.0136495288,0,0.999906838},{0,0.0155491373,0,0.999879122},{0,0.0173821114,0,0.999848902},{0,0.0191406067,0,0.999816775},{0,0.0208170917,0,0.999783278},{0,0.0224043913,0,0.999749005},{0,0.0238957144,0,0.999714434},{0,0.0252846833,0,0.999680281},{0,0.026565358,0,0.999647081},{0,0.0277322624,0,0.999615371},{0,0.0287804082,0,0.999585748},{0,0.0297053196,0,0.999558687},{0,0.030503042,0,0.999534667},{0,0.0311701708,0,0.999514103},{0,0.0317038558,0,0.999497294},{0,0.0321018174,0,0.999484599},{0,0.0323623605,0,0.999476194},{0,0.0324843675,0,0.99947226},{0,0.0324673206,0,0.999472797},{0,0.0323112905,0,0.999477863},{0,0.0320169479,0,0.99948734},{0,0.0315855443,0,0.99950105},{0,0.0310189258,0,0.999518812},{0,0.0303195082,0,0.999540269},{0,0.029490279,0,0.999565065},{0,0.0285347812,0,0.999592781},{0,0.0274570975,0,0.999623001},{0,0.0262618326,0,0.999655128},{0,0.0249540936,0,0.999688625},{0,0.0235394742,0,0.999722898},{0,0.0220240243,0,0.999757469},{0,0.0204142239,0,0.999791622},{0,0.0187169649,0,0.999824822},{0,0.0169395078,0,0.999856532},{0,0.0150894662,0,0.999886155},{0,0.0131747602,0,0.999913216},{0,0.0112035917,0,0.999937236},{0,0.00918440428,0,0.9999578},{0,0.0071258517,0,0.999974608},{0,0.00503675453,0,0.999987304},{0,0.00292606745,0,0.999995708},{0,0.00080283737,0,0.999999702},{0,-0.00132383418,0,0.999999106},{0,-0.00344483089,0,0.99999404},{0,-0.00555106113,0,0.999984622},{0,-0.00763349654,0,0.999970853},{0,-0.00968321227,0,0.999953091},{0,-0.011691425,0,0.999931633},{0,-0.0136495288,0,0.999906838},{0,-0.0155491373,0,0.999879122},{0,-0.0173821114,0,0.999848902},{0,-0.0191406067,0,0.999816775},{0,-0.0208170917,0,0.999783278},{0,-0.0224043913,0,0.999749005},{0,-0.0238957144,0,0.999714434},{0,-0.0252846833,0,0.999680281}}},
}},
Walk={duration=2.0,fps=24,channels={
{bone="Root",path="translation",values={{0,0,0},{0,0.00108703994,0},{0,0.00209999993,0},{0,0.00296984846,0},{0,0.00363730663,0},{0,0.00405688863,0},{0,0.00419999985,0},{0,0.00405688863,0},{0,0.00363730663,0},{0,0.00296984846,0},{0,0.00209999993,0},{0,0.00108703994,0},{0,5.14351658e-19,0},{0,-0.00108703994,0},{0,-0.00209999993,0},{0,-0.00296984846,0},{0,-0.00363730663,0},{0,-0.00405688863,0},{0,-0.00419999985,0},{0,-0.00405688863,0},{0,-0.00363730663,0},{0,-0.00296984846,0},{0,-0.00209999993,0},{0,-0.00108703994,0},{0,-1.02870332e-18,0},{0,0.00108703994,0},{0,0.00209999993,0},{0,0.00296984846,0},{0,0.00363730663,0},{0,0.00405688863,0},{0,0.00419999985,0},{0,0.00405688863,0},{0,0.00363730663,0},{0,0.00296984846,0},{0,0.00209999993,0},{0,0.00108703994,0},{0,1.54305497e-18,0},{0,-0.00108703994,0},{0,-0.00209999993,0},{0,-0.00296984846,0},{0,-0.00363730663,0},{0,-0.00405688863,0},{0,-0.00419999985,0},{0,-0.00405688863,0},{0,-0.00363730663,0},{0,-0.00296984846,0},{0,-0.00209999993,0},{0,-0.00108703994,0},{0,-2.05740663e-18,0}}},
{bone="Spine",path="rotation",values={{0,0,0,1},{0.00156631367,0,0,0.999998748},{0.00310582365,0,0,0.999995172},{0.00459218491,0,0,0.99998945},{0.0059999642,0,0,0.999981999},{0.00730507215,0,0,0.999973297},{0.00848517939,0,0,0.999963999},{0.0095200967,0,0,0.9999547},{0.0103921182,0,0,0.999945998},{0.011086327,0,0,0.999938548},{0.0115908505,0,0,0.999932826},{0.0118970573,0,0,0.999929249},{0.0119997123,0,0,0.999927998},{0.0118970573,0,0,0.999929249},{0.0115908505,0,0,0.999932826},{0.011086327,0,0,0.999938548},{0.0103921182,0,0,0.999945998},{0.0095200967,0,0,0.9999547},{0.00848517939,0,0,0.999963999},{0.00730507215,0,0,0.999973297},{0.0059999642,0,0,0.999981999},{0.00459218491,0,0,0.99998945},{0.00310582365,0,0,0.999995172},{0.00156631367,0,0,0.999998748},{1.46957611e-18,0,0,1},{-0.00156631367,0,0,0.999998748},{-0.00310582365,0,0,0.999995172},{-0.00459218491,0,0,0.99998945},{-0.0059999642,0,0,0.999981999},{-0.00730507215,0,0,0.999973297},{-0.00848517939,0,0,0.999963999},{-0.0095200967,0,0,0.9999547},{-0.0103921182,0,0,0.999945998},{-0.011086327,0,0,0.999938548},{-0.0115908505,0,0,0.999932826},{-0.0118970573,0,0,0.999929249},{-0.0119997123,0,0,0.999927998},{-0.0118970573,0,0,0.999929249},{-0.0115908505,0,0,0.999932826},{-0.011086327,0,0,0.999938548},{-0.0103921182,0,0,0.999945998},{-0.0095200967,0,0,0.9999547},{-0.00848517939,0,0,0.999963999},{-0.00730507215,0,0,0.999973297},{-0.0059999642,0,0,0.999981999},{-0.00459218491,0,0,0.99998945},{-0.00310582365,0,0,0.999995172},{-0.00156631367,0,0,0.999998748},{-2.93915221e-18,0,0,1}}},
{bone="Chest",path="rotation",values={{0,0,0.003504758,0.999993861},{0,0,0.00455676904,0.999989629},{0,0,0.00553080812,0.999984682},{0,0,0.00641020993,0.999979436},{0,0,0.00717992848,0.999974251},{0,0,0.00782679487,0.999969363},{0,0,0.00833974313,0.99996525},{0,0,0.00870999694,0.999962091},{0,0,0.00893122423,0.999960124},{0,0,0.00899963826,0.999959528},{0,0,0.00891407114,0.999960244},{0,0,0.00867598504,0.999962389},{0,0,0.00828945357,0.999965668},{0,0,0.00776108913,0.9999699},{0,0,0.00709992973,0.999974787},{0,0,0.00631728722,0.999980032},{0,0,0.00542655075,0.999985278},{0,0,0.00444296096,0.999990106},{0,0,0.0033833466,0.999994278},{0,0,0.00226583867,0.999997437},{0,0,0.00110955862,0.999999404},{0,0,-6.57076816e-05,1},{0,0,-0.0012398496,0.999999225},{0,0,-0.00239277584,0.999997139},{0,0,-0.003504758,0.999993861},{0,0,-0.00455676904,0.999989629},{0,0,-0.00553080812,0.999984682},{0,0,-0.00641020993,0.999979436},{0,0,-0.00717992848,0.999974251},{0,0,-0.00782679487,0.999969363},{0,0,-0.00833974313,0.99996525},{0,0,-0.00870999694,0.999962091},{0,0,-0.00893122423,0.999960124},{0,0,-0.00899963826,0.999959528},{0,0,-0.00891407114,0.999960244},{0,0,-0.00867598504,0.999962389},{0,0,-0.00828945357,0.999965668},{0,0,-0.00776108913,0.9999699},{0,0,-0.00709992973,0.999974787},{0,0,-0.00631728722,0.999980032},{0,0,-0.00542655075,0.999985278},{0,0,-0.00444296096,0.999990106},{0,0,-0.0033833466,0.999994278},{0,0,-0.00226583867,0.999997437},{0,0,-0.00110955862,0.999999404},{0,0,6.57076816e-05,1},{0,0,0.0012398496,0.999999225},{0,0,0.00239277584,0.999997139},{0,0,0.003504758,0.999993861}}},
{bone="Neck",path="rotation",values={{0,0,0,1},{0,0.00163157668,0,0.999998689},{0,0.00323523232,0,0.999994755},{0,0.00478352467,0,0.999988556},{0,0.00624995911,0,0.99998045},{0,0.0076094442,0,0.999971032},{0,0.00883871969,0,0.999960959},{0,0.00991675444,0,0.999950826},{0,0.0108251059,0,0.999941409},{0,0.0115482379,0,0.999933302},{0,0.0120737795,0,0.999927104},{0,0.0123927435,0,0.999923229},{0,0.0124996742,0,0.999921858},{0,0.0123927435,0,0.999923229},{0,0.0120737795,0,0.999927104},{0,0.0115482379,0,0.999933302},{0,0.0108251059,0,0.999941409},{0,0.00991675444,0,0.999950826},{0,0.00883871969,0,0.999960959},{0,0.0076094442,0,0.999971032},{0,0.00624995911,0,0.99998045},{0,0.00478352467,0,0.999988556},{0,0.00323523232,0,0.999994755},{0,0.00163157668,0,0.999998689},{0,1.53080846e-18,0,1},{0,-0.00163157668,0,0.999998689},{0,-0.00323523232,0,0.999994755},{0,-0.00478352467,0,0.999988556},{0,-0.00624995911,0,0.99998045},{0,-0.0076094442,0,0.999971032},{0,-0.00883871969,0,0.999960959},{0,-0.00991675444,0,0.999950826},{0,-0.0108251059,0,0.999941409},{0,-0.0115482379,0,0.999933302},{0,-0.0120737795,0,0.999927104},{0,-0.0123927435,0,0.999923229},{0,-0.0124996742,0,0.999921858},{0,-0.0123927435,0,0.999923229},{0,-0.0120737795,0,0.999927104},{0,-0.0115482379,0,0.999933302},{0,-0.0108251059,0,0.999941409},{0,-0.00991675444,0,0.999950826},{0,-0.00883871969,0,0.999960959},{0,-0.0076094442,0,0.999971032},{0,-0.00624995911,0,0.99998045},{0,-0.00478352467,0,0.999988556},{0,-0.00323523232,0,0.999994755},{0,-0.00163157668,0,0.999998689},{0,-3.06161692e-18,0,1}}},
{bone="Head",path="rotation",values={{0.00705797225,0,0,0.999975085},{0.00834415015,0,0,0.999965191},{0.00948754884,0,0,0.999954998},{0.0104686078,0,0,0.999945223},{0.0112705426,0,0,0.999936461},{0.0118796388,0,0,0.999929428},{0.0122854775,0,0,0.999924541},{0.0124811176,0,0,0.999922097},{0.0124632129,0,0,0.999922335},{0.0122320699,0,0,0.999925196},{0.0117916418,0,0,0.999930501},{0.0111494614,0,0,0.999937832},{0.0103165125,0,0,0.999946773},{0.00930704176,0,0,0.999956667},{0.00813831948,0,0,0.99996686},{0.00683033885,0,0,0.999976695},{0.00540547818,0,0,0.999985397},{0.00388811785,0,0,0.99999243},{0.0023042215,0,0,0.999997318},{0.00068089366,0,0,0.999999762},{-0.00095408631,0,0,0.999999523},{-0.00257273903,0,0,0.999996662},{-0.00414736522,0,0,0.999991417},{-0.00565101951,0,0,0.999984026},{-0.00705797225,0,0,0.999975085},{-0.00834415015,0,0,0.999965191},{-0.00948754884,0,0,0.999954998},{-0.0104686078,0,0,0.999945223},{-0.0112705426,0,0,0.999936461},{-0.0118796388,0,0,0.999929428},{-0.0122854775,0,0,0.999924541},{-0.0124811176,0,0,0.999922097},{-0.0124632129,0,0,0.999922335},{-0.0122320699,0,0,0.999925196},{-0.0117916418,0,0,0.999930501},{-0.0111494614,0,0,0.999937832},{-0.0103165125,0,0,0.999946773},{-0.00930704176,0,0,0.999956667},{-0.00813831948,0,0,0.99996686},{-0.00683033885,0,0,0.999976695},{-0.00540547818,0,0,0.999985397},{-0.00388811785,0,0,0.99999243},{-0.0023042215,0,0,0.999997318},{-0.00068089366,0,0,0.999999762},{0.00095408631,0,0,0.999999523},{0.00257273903,0,0,0.999996662},{0.00414736522,0,0,0.999991417},{0.00565101951,0,0,0.999984026},{0.00705797225,0,0,0.999975085}}},
{bone="Jaw",path="rotation",values={{0,0,0,1},{0.000522104732,0,0,0.999999881},{0.00103527599,0,0,0.999999464},{0.00153073308,0,0,0.999998808},{0.0019999987,0,0,0.999997973},{0.00243504322,0,0,0.99999702},{0.0028284234,0,0,0.999996006},{0.0031734081,0,0,0.999994993},{0.0034640946,0,0,0.99999398},{0.00369550963,0,0,0.999993145},{0.00386369368,0,0,0.999992549},{0.00396576896,0,0,0.999992132},{0.00399998948,0,0,0.999992013},{0.00396576896,0,0,0.999992132},{0.00386369368,0,0,0.999992549},{0.00369550963,0,0,0.999993145},{0.0034640946,0,0,0.99999398},{0.0031734081,0,0,0.999994993},{0.0028284234,0,0,0.999996006},{0.00243504322,0,0,0.99999702},{0.0019999987,0,0,0.999997973},{0.00153073308,0,0,0.999998808},{0.00103527599,0,0,0.999999464},{0.000522104732,0,0,0.999999881},{4.89858737e-19,0,0,1},{-0.000522104732,0,0,0.999999881},{-0.00103527599,0,0,0.999999464},{-0.00153073308,0,0,0.999998808},{-0.0019999987,0,0,0.999997973},{-0.00243504322,0,0,0.99999702},{-0.0028284234,0,0,0.999996006},{-0.0031734081,0,0,0.999994993},{-0.0034640946,0,0,0.99999398},{-0.00369550963,0,0,0.999993145},{-0.00386369368,0,0,0.999992549},{-0.00396576896,0,0,0.999992132},{-0.00399998948,0,0,0.999992013},{-0.00396576896,0,0,0.999992132},{-0.00386369368,0,0,0.999992549},{-0.00369550963,0,0,0.999993145},{-0.0034640946,0,0,0.99999398},{-0.0031734081,0,0,0.999994993},{-0.0028284234,0,0,0.999996006},{-0.00243504322,0,0,0.99999702},{-0.0019999987,0,0,0.999997973},{-0.00153073308,0,0,0.999998808},{-0.00103527599,0,0,0.999999464},{-0.000522104732,0,0,0.999999881},{-9.79717474e-19,0,0,1}}},
{bone="EarLeft",path="rotation",values={{0,0,0.0116822841,0.999931753},{0,0,0.0151886977,0.999884665},{0,0,0.0184350759,0.999830067},{0,0,0.0213658866,0.999771714},{0,0,0.0239310153,0.9997136},{0,0,0.0260866228,0.999659657},{0,0,0.0277958848,0.999613643},{0,0,0.0290296115,0.999578536},{0,0,0.029766744,0.999556899},{0,0,0.0299947001,0.999550045},{0,0,0.0297095925,0.999558568},{0,0,0.0289162826,0.999581814},{0,0,0.0276283138,0.999618292},{0,0,0.0258676708,0.99966538},{0,0,0.0236644223,0.999719977},{0,0,0.0210562069,0.999778271},{0,0,0.018087605,0.999836385},{0,0,0.0148093775,0.999890327},{0,0,0.0112776048,0.999936402},{0,0,0.00755272992,0.999971449},{0,0,0.00369852106,0.999993145},{0,0,-0.000219025605,1},{0,0,-0.00413282122,0.999991477},{0,0,-0.00797584187,0.999968171},{0,0,-0.0116822841,0.999931753},{0,0,-0.0151886977,0.999884665},{0,0,-0.0184350759,0.999830067},{0,0,-0.0213658866,0.999771714},{0,0,-0.0239310153,0.9997136},{0,0,-0.0260866228,0.999659657},{0,0,-0.0277958848,0.999613643},{0,0,-0.0290296115,0.999578536},{0,0,-0.029766744,0.999556899},{0,0,-0.0299947001,0.999550045},{0,0,-0.0297095925,0.999558568},{0,0,-0.0289162826,0.999581814},{0,0,-0.0276283138,0.999618292},{0,0,-0.0258676708,0.99966538},{0,0,-0.0236644223,0.999719977},{0,0,-0.0210562069,0.999778271},{0,0,-0.018087605,0.999836385},{0,0,-0.0148093775,0.999890327},{0,0,-0.0112776048,0.999936402},{0,0,-0.00755272992,0.999971449},{0,0,-0.00369852106,0.999993145},{0,0,0.000219025605,1},{0,0,0.00413282122,0.999991477},{0,0,0.00797584187,0.999968171},{0,0,0.0116822841,0.999931753}}},
{bone="EarTipLeft",path="rotation",values={{0.00149937451,0,0,0.999998868},{0.00539741339,0,0,0.999985456},{0.00920302328,0,0,0.999957681},{0.0128510436,0,0,0.999917448},{0.0162790325,0,0,0.999867499},{0.0194283314,0,0,0.999811232},{0.0222450756,0,0,0.999752522},{0.0246811118,0,0,0.999695361},{0.0266948082,0,0,0.999643624},{0.0282517746,0,0,0.999600828},{0.0293254219,0,0,0.999569893},{0.0298974272,0,0,0.999552965},{0.0299580246,0,0,0.999551177},{0.0295061842,0,0,0.999564588},{0.0285496134,0,0,0.999592364},{0.0271046422,0,0,0.999632597},{0.0251959395,0,0,0.999682546},{0.0228561033,0,0,0.999738753},{0.0201251153,0,0,0.999797463},{0.017049659,0,0,0.999854624},{0.01368233,0,0,0.999906421},{0.0100807426,0,0,0.999949217},{0.00630654069,0,0,0.999980092},{0.00242434186,0,0,0.999997079},{-0.00149937451,0,0,0.999998868},{-0.00539741339,0,0,0.999985456},{-0.00920302328,0,0,0.999957681},{-0.0128510436,0,0,0.999917448},{-0.0162790325,0,0,0.999867499},{-0.0194283314,0,0,0.999811232},{-0.0222450756,0,0,0.999752522},{-0.0246811118,0,0,0.999695361},{-0.0266948082,0,0,0.999643624},{-0.0282517746,0,0,0.999600828},{-0.0293254219,0,0,0.999569893},{-0.0298974272,0,0,0.999552965},{-0.0299580246,0,0,0.999551177},{-0.0295061842,0,0,0.999564588},{-0.0285496134,0,0,0.999592364},{-0.0271046422,0,0,0.999632597},{-0.0251959395,0,0,0.999682546},{-0.0228561033,0,0,0.999738753},{-0.0201251153,0,0,0.999797463},{-0.017049659,0,0,0.999854624},{-0.01368233,0,0,0.999906421},{-0.0100807426,0,0,0.999949217},{-0.00630654069,0,0,0.999980092},{-0.00242434186,0,0,0.999997079},{0.00149937451,0,0,0.999998868}}},
{bone="WhiskerLeft",path="rotation",values={{0,0.00778828794,0,0.999969661},{0,0.0101260152,0,0.99994874},{0,0.0122904377,0,0.999924481},{0,0.0142445266,0,0.999898553},{0,0.0159548558,0,0.999872684},{0,0.0173921771,0,0.999848723},{0,0.0185319148,0,0.999828279},{0,0.0193545856,0,0.999812663},{0,0.0198461246,0,0.999803066},{0,0.0199981332,0,0.999800026},{0,0.0198080149,0,0.999803782},{0,0.0192790143,0,0.999814153},{0,0.0184201784,0,0.999830306},{0,0.017246183,0,0.999851286},{0,0.0157770999,0,0.999875546},{0,0.0140380478,0,0.999901474},{0,0.0120587684,0,0.999927282},{0,0.00987311825,0,0.999951243},{0,0.00751849171,0,0.999971747},{0,0.00503518013,0,0.999987304},{0,0.00246568397,0,0.99999696},{0,-0.000146017075,0,1},{0,-0.00275521865,0,0.999996185},{0,-0.00531725958,0,0.999985874},{0,-0.00778828794,0,0.999969661},{0,-0.0101260152,0,0.99994874},{0,-0.0122904377,0,0.999924481},{0,-0.0142445266,0,0.999898553},{0,-0.0159548558,0,0.999872684},{0,-0.0173921771,0,0.999848723},{0,-0.0185319148,0,0.999828279},{0,-0.0193545856,0,0.999812663},{0,-0.0198461246,0,0.999803066},{0,-0.0199981332,0,0.999800026},{0,-0.0198080149,0,0.999803782},{0,-0.0192790143,0,0.999814153},{0,-0.0184201784,0,0.999830306},{0,-0.017246183,0,0.999851286},{0,-0.0157770999,0,0.999875546},{0,-0.0140380478,0,0.999901474},{0,-0.0120587684,0,0.999927282},{0,-0.00987311825,0,0.999951243},{0,-0.00751849171,0,0.999971747},{0,-0.00503518013,0,0.999987304},{0,-0.00246568397,0,0.99999696},{0,0.000146017075,0,1},{0,0.00275521865,0,0.999996185},{0,0.00531725958,0,0.999985874},{0,0.00778828794,0,0.999969661}}},
{bone="EyeLeft",path="translation",values={{1.78813936e-09,-7.45058126e-10,-4.76837159e-09},{0.000274108648,-7.45058126e-10,-4.76837159e-09},{0.000543521643,-7.45058126e-10,-4.76837159e-09},{0.000803636312,-7.45058126e-10,-4.76837159e-09},{0.00104999721,-7.45058126e-10,-4.76837159e-09},{0.00127840221,-7.45058126e-10,-4.76837159e-09},{0.0014849174,-7.45058126e-10,-4.76837159e-09},{0.00166604102,-7.45058126e-10,-4.76837159e-09},{0.00181865871,-7.45058126e-10,-4.76837159e-09},{0.00194014788,-7.45058126e-10,-4.76837159e-09},{0.00202843726,-7.45058126e-10,-4.76837159e-09},{0.00208203673,-7.45058126e-10,-4.76837159e-09},{0.00209999263,-7.45058126e-10,-4.76837159e-09},{0.00208203673,-7.45058126e-10,-4.76837159e-09},{0.00202843726,-7.45058126e-10,-4.76837159e-09},{0.00194014788,-7.45058126e-10,-4.76837159e-09},{0.00181865871,-7.45058126e-10,-4.76837159e-09},{0.00166604102,-7.45058126e-10,-4.76837159e-09},{0.0014849174,-7.45058126e-10,-4.76837159e-09},{0.00127840221,-7.45058126e-10,-4.76837159e-09},{0.00104999721,-7.45058126e-10,-4.76837159e-09},{0.000803636312,-7.45058126e-10,-4.76837159e-09},{0.000543521643,-7.45058126e-10,-4.76837159e-09},{0.000274108648,-7.45058126e-10,-4.76837159e-09},{1.78813936e-09,-7.45058126e-10,-4.76837159e-09},{-0.000274105072,-7.45058126e-10,-4.76837159e-09},{-0.000543518066,-7.45058126e-10,-4.76837159e-09},{-0.000803632736,-7.45058126e-10,-4.76837159e-09},{-0.00104999363,-7.45058126e-10,-4.76837159e-09},{-0.00127839863,-7.45058126e-10,-4.76837159e-09},{-0.00148492873,-7.45058126e-10,-4.76837159e-09},{-0.00166603744,-7.45058126e-10,-4.76837159e-09},{-0.00181865513,-7.45058126e-10,-4.76837159e-09},{-0.0019401443,-7.45058126e-10,-4.76837159e-09},{-0.00202844858,-7.45058126e-10,-4.76837159e-09},{-0.00208203316,-7.45058126e-10,-4.76837159e-09},{-0.00210000396,-7.45058126e-10,-4.76837159e-09},{-0.00208203316,-7.45058126e-10,-4.76837159e-09},{-0.00202844858,-7.45058126e-10,-4.76837159e-09},{-0.0019401443,-7.45058126e-10,-4.76837159e-09},{-0.00181865513,-7.45058126e-10,-4.76837159e-09},{-0.00166603744,-7.45058126e-10,-4.76837159e-09},{-0.00148492873,-7.45058126e-10,-4.76837159e-09},{-0.00127839863,-7.45058126e-10,-4.76837159e-09},{-0.00104999363,-7.45058126e-10,-4.76837159e-09},{-0.000803632736,-7.45058126e-10,-4.76837159e-09},{-0.000543518066,-7.45058126e-10,-4.76837159e-09},{-0.000274105072,-7.45058126e-10,-4.76837159e-09},{1.78813936e-09,-7.45058126e-10,-4.76837159e-09}}},
{bone="EarRight",path="rotation",values={{0,0,-0.0116822841,0.999931753},{0,0,-0.00797584187,0.999968171},{0,0,-0.00413282122,0.999991477},{0,0,-0.000219025605,1},{0,0,0.00369852106,0.999993145},{0,0,0.00755272992,0.999971449},{0,0,0.0112776048,0.999936402},{0,0,0.0148093775,0.999890327},{0,0,0.018087605,0.999836385},{0,0,0.0210562069,0.999778271},{0,0,0.0236644223,0.999719977},{0,0,0.0258676708,0.99966538},{0,0,0.0276283138,0.999618292},{0,0,0.0289162826,0.999581814},{0,0,0.0297095925,0.999558568},{0,0,0.0299947001,0.999550045},{0,0,0.029766744,0.999556899},{0,0,0.0290296115,0.999578536},{0,0,0.0277958848,0.999613643},{0,0,0.0260866228,0.999659657},{0,0,0.0239310153,0.9997136},{0,0,0.0213658866,0.999771714},{0,0,0.0184350759,0.999830067},{0,0,0.0151886977,0.999884665},{0,0,0.0116822841,0.999931753},{0,0,0.00797584187,0.999968171},{0,0,0.00413282122,0.999991477},{0,0,0.000219025605,1},{0,0,-0.00369852106,0.999993145},{0,0,-0.00755272992,0.999971449},{0,0,-0.0112776048,0.999936402},{0,0,-0.0148093775,0.999890327},{0,0,-0.018087605,0.999836385},{0,0,-0.0210562069,0.999778271},{0,0,-0.0236644223,0.999719977},{0,0,-0.0258676708,0.99966538},{0,0,-0.0276283138,0.999618292},{0,0,-0.0289162826,0.999581814},{0,0,-0.0297095925,0.999558568},{0,0,-0.0299947001,0.999550045},{0,0,-0.029766744,0.999556899},{0,0,-0.0290296115,0.999578536},{0,0,-0.0277958848,0.999613643},{0,0,-0.0260866228,0.999659657},{0,0,-0.0239310153,0.9997136},{0,0,-0.0213658866,0.999771714},{0,0,-0.0184350759,0.999830067},{0,0,-0.0151886977,0.999884665},{0,0,-0.0116822841,0.999931753}}},
{bone="EarTipRight",path="rotation",values={{-0.0204477385,0,0,0.999790907},{-0.0174082015,0,0,0.999848485},{-0.0140706599,0,0,0.999900997},{-0.010492214,0,0,0.999944985},{-0.00673411041,0,0,0.99997735},{-0.00286068884,0,0,0.999995887},{0.00106172299,0,0,0.999999464},{0.00496595213,0,0,0.999987662},{0.00878513977,0,0,0.999961436},{0.0124538932,0,0,0.999922454},{0.015909411,0,0,0.999873459},{0.0190925635,0,0,0.999817729},{0.0219489038,0,0,0.999759078},{0.0244295951,0,0,0.99970156},{0.0264922474,0,0,0.999649048},{0.0281016268,0,0,0.99960506},{0.0292302519,0,0,0.999572694},{0.0298588574,0,0,0.999554098},{0.0299767144,0,0,0.999550581},{0.029581815,0,0,0.999562383},{0.0286808945,0,0,0.999588609},{0.027289331,0,0,0.99962759},{0.0254308823,0,0,0.999676585},{0.02313729,0,0,0.999732316},{0.0204477385,0,0,0.999790907},{0.0174082015,0,0,0.999848485},{0.0140706599,0,0,0.999900997},{0.010492214,0,0,0.999944985},{0.00673411041,0,0,0.99997735},{0.00286068884,0,0,0.999995887},{-0.00106172299,0,0,0.999999464},{-0.00496595213,0,0,0.999987662},{-0.00878513977,0,0,0.999961436},{-0.0124538932,0,0,0.999922454},{-0.015909411,0,0,0.999873459},{-0.0190925635,0,0,0.999817729},{-0.0219489038,0,0,0.999759078},{-0.0244295951,0,0,0.99970156},{-0.0264922474,0,0,0.999649048},{-0.0281016268,0,0,0.99960506},{-0.0292302519,0,0,0.999572694},{-0.0298588574,0,0,0.999554098},{-0.0299767144,0,0,0.999550581},{-0.029581815,0,0,0.999562383},{-0.0286808945,0,0,0.999588609},{-0.027289331,0,0,0.99962759},{-0.0254308823,0,0,0.999676585},{-0.02313729,0,0,0.999732316},{-0.0204477385,0,0,0.999790907}}},
{bone="WhiskerRight",path="rotation",values={{0,-0.00778828794,0,0.999969661},{0,-0.00531725958,0,0.999985874},{0,-0.00275521865,0,0.999996185},{0,-0.000146017075,0,1},{0,0.00246568397,0,0.99999696},{0,0.00503518013,0,0.999987304},{0,0.00751849171,0,0.999971747},{0,0.00987311825,0,0.999951243},{0,0.0120587684,0,0.999927282},{0,0.0140380478,0,0.999901474},{0,0.0157770999,0,0.999875546},{0,0.017246183,0,0.999851286},{0,0.0184201784,0,0.999830306},{0,0.0192790143,0,0.999814153},{0,0.0198080149,0,0.999803782},{0,0.0199981332,0,0.999800026},{0,0.0198461246,0,0.999803066},{0,0.0193545856,0,0.999812663},{0,0.0185319148,0,0.999828279},{0,0.0173921771,0,0.999848723},{0,0.0159548558,0,0.999872684},{0,0.0142445266,0,0.999898553},{0,0.0122904377,0,0.999924481},{0,0.0101260152,0,0.99994874},{0,0.00778828794,0,0.999969661},{0,0.00531725958,0,0.999985874},{0,0.00275521865,0,0.999996185},{0,0.000146017075,0,1},{0,-0.00246568397,0,0.99999696},{0,-0.00503518013,0,0.999987304},{0,-0.00751849171,0,0.999971747},{0,-0.00987311825,0,0.999951243},{0,-0.0120587684,0,0.999927282},{0,-0.0140380478,0,0.999901474},{0,-0.0157770999,0,0.999875546},{0,-0.017246183,0,0.999851286},{0,-0.0184201784,0,0.999830306},{0,-0.0192790143,0,0.999814153},{0,-0.0198080149,0,0.999803782},{0,-0.0199981332,0,0.999800026},{0,-0.0198461246,0,0.999803066},{0,-0.0193545856,0,0.999812663},{0,-0.0185319148,0,0.999828279},{0,-0.0173921771,0,0.999848723},{0,-0.0159548558,0,0.999872684},{0,-0.0142445266,0,0.999898553},{0,-0.0122904377,0,0.999924481},{0,-0.0101260152,0,0.99994874},{0,-0.00778828794,0,0.999969661}}},
{bone="EyeRight",path="translation",values={{-5.96046434e-10,-7.45058126e-10,-4.76837159e-09},{0.000274106264,-7.45058126e-10,-4.76837159e-09},{0.000543519258,-7.45058126e-10,-4.76837159e-09},{0.000803633928,-7.45058126e-10,-4.76837159e-09},{0.00104999483,-7.45058126e-10,-4.76837159e-09},{0.00127839983,-7.45058126e-10,-4.76837159e-09},{0.00148492992,-7.45058126e-10,-4.76837159e-09},{0.00166603863,-7.45058126e-10,-4.76837159e-09},{0.00181865633,-7.45058126e-10,-4.76837159e-09},{0.00194014549,-7.45058126e-10,-4.76837159e-09},{0.00202844977,-7.45058126e-10,-4.76837159e-09},{0.00208203435,-7.45058126e-10,-4.76837159e-09},{0.00210000515,-7.45058126e-10,-4.76837159e-09},{0.00208203435,-7.45058126e-10,-4.76837159e-09},{0.00202844977,-7.45058126e-10,-4.76837159e-09},{0.00194014549,-7.45058126e-10,-4.76837159e-09},{0.00181865633,-7.45058126e-10,-4.76837159e-09},{0.00166603863,-7.45058126e-10,-4.76837159e-09},{0.00148492992,-7.45058126e-10,-4.76837159e-09},{0.00127839983,-7.45058126e-10,-4.76837159e-09},{0.00104999483,-7.45058126e-10,-4.76837159e-09},{0.000803633928,-7.45058126e-10,-4.76837159e-09},{0.000543519258,-7.45058126e-10,-4.76837159e-09},{0.000274106264,-7.45058126e-10,-4.76837159e-09},{-5.96046434e-10,-7.45058126e-10,-4.76837159e-09},{-0.000274107456,-7.45058126e-10,-4.76837159e-09},{-0.000543520451,-7.45058126e-10,-4.76837159e-09},{-0.00080363512,-7.45058126e-10,-4.76837159e-09},{-0.00104999602,-7.45058126e-10,-4.76837159e-09},{-0.00127840102,-7.45058126e-10,-4.76837159e-09},{-0.00148493111,-7.45058126e-10,-4.76837159e-09},{-0.00166603982,-7.45058126e-10,-4.76837159e-09},{-0.00181865752,-7.45058126e-10,-4.76837159e-09},{-0.00194014668,-7.45058126e-10,-4.76837159e-09},{-0.00202845097,-7.45058126e-10,-4.76837159e-09},{-0.00208203554,-7.45058126e-10,-4.76837159e-09},{-0.00210000634,-7.45058126e-10,-4.76837159e-09},{-0.00208203554,-7.45058126e-10,-4.76837159e-09},{-0.00202845097,-7.45058126e-10,-4.76837159e-09},{-0.00194014668,-7.45058126e-10,-4.76837159e-09},{-0.00181865752,-7.45058126e-10,-4.76837159e-09},{-0.00166603982,-7.45058126e-10,-4.76837159e-09},{-0.00148493111,-7.45058126e-10,-4.76837159e-09},{-0.00127840102,-7.45058126e-10,-4.76837159e-09},{-0.00104999602,-7.45058126e-10,-4.76837159e-09},{-0.00080363512,-7.45058126e-10,-4.76837159e-09},{-0.000543520451,-7.45058126e-10,-4.76837159e-09},{-0.000274107456,-7.45058126e-10,-4.76837159e-09},{-5.96046434e-10,-7.45058126e-10,-4.76837159e-09}}},
{bone="Sprout",path="rotation",values={{0,0,-0.0107087996,0.99994266},{0,0,-0.00731120119,0.999973297},{0,0,-0.0037884214,0.999992847},{0,0,-0.000200773473,1},{0,0,0.00339031219,0.999994278},{0,0,0.00692334631,0.999976039},{0,0,0.0103378389,0.999946535},{0,0,0.0135753416,0.999907851},{0,0,0.0165804494,0.999862552},{0,0,0.0193017516,0.999813676},{0,0,0.02169271,0.999764681},{0,0,0.0237124544,0.999718845},{0,0,0.0253264699,0.999679208},{0,0,0.0265071839,0.999648631},{0,0,0.0272344332,0.99962908},{0,0,0.0274958014,0.999621928},{0,0,0.0272868257,0.99962765},{0,0,0.0266110748,0.999645889},{0,0,0.0254800841,0.999675333},{0,0,0.0239131711,0.999714017},{0,0,0.0219370984,0.999759376},{0,0,0.0195856337,0.999808192},{0,0,0.0168989729,0.999857187},{0,0,0.0139230583,0.999903083},{0,0,0.0107087996,0.99994266},{0,0,0.00731120119,0.999973297},{0,0,0.0037884214,0.999992847},{0,0,0.000200773473,1},{0,0,-0.00339031219,0.999994278},{0,0,-0.00692334631,0.999976039},{0,0,-0.0103378389,0.999946535},{0,0,-0.0135753416,0.999907851},{0,0,-0.0165804494,0.999862552},{0,0,-0.0193017516,0.999813676},{0,0,-0.02169271,0.999764681},{0,0,-0.0237124544,0.999718845},{0,0,-0.0253264699,0.999679208},{0,0,-0.0265071839,0.999648631},{0,0,-0.0272344332,0.99962908},{0,0,-0.0274958014,0.999621928},{0,0,-0.0272868257,0.99962765},{0,0,-0.0266110748,0.999645889},{0,0,-0.0254800841,0.999675333},{0,0,-0.0239131711,0.999714017},{0,0,-0.0219370984,0.999759376},{0,0,-0.0195856337,0.999808192},{0,0,-0.0168989729,0.999857187},{0,0,-0.0139230583,0.999903083},{0,0,-0.0107087996,0.99994266}}},
{bone="SproutTip",path="rotation",values={{0,0,-0.0197260138,0.99980545},{0,0,-0.017056888,0.999854505},{0,0,-0.0140958084,0.999900639},{0,0,-0.0108934278,0.999940693},{0,0,-0.00750454888,0.999971867},{0,0,-0.00398717821,0.999992073},{0,0,-0.000401536236,0.99999994},{0,0,0.00319098122,0.999994934},{0,0,0.00672886008,0.99997735},{0,0,0.0101515269,0.999948502},{0,0,0.0134003926,0.999910235},{0,0,0.0164198559,0.999865174},{0,0,0.0191582628,0.999816477},{0,0,0.0215687789,0.999767363},{0,0,0.023610197,0.999721229},{0,0,0.0252476335,0.999681234},{0,0,0.0264531169,0.999650061},{0,0,0.0272060595,0.999629855},{0,0,0.0274936035,0.999621987},{0,0,0.0273108426,0.999626994},{0,0,0.026660895,0.999644518},{0,0,0.0255548581,0.999673426},{0,0,0.0240116194,0.999711692},{0,0,0.0220575426,0.999756694},{0,0,0.0197260138,0.99980545},{0,0,0.017056888,0.999854505},{0,0,0.0140958084,0.999900639},{0,0,0.0108934278,0.999940693},{0,0,0.00750454888,0.999971867},{0,0,0.00398717821,0.999992073},{0,0,0.000401536236,0.99999994},{0,0,-0.00319098122,0.999994934},{0,0,-0.00672886008,0.99997735},{0,0,-0.0101515269,0.999948502},{0,0,-0.0134003926,0.999910235},{0,0,-0.0164198559,0.999865174},{0,0,-0.0191582628,0.999816477},{0,0,-0.0215687789,0.999767363},{0,0,-0.023610197,0.999721229},{0,0,-0.0252476335,0.999681234},{0,0,-0.0264531169,0.999650061},{0,0,-0.0272060595,0.999629855},{0,0,-0.0274936035,0.999621987},{0,0,-0.0273108426,0.999626994},{0,0,-0.026660895,0.999644518},{0,0,-0.0255548581,0.999673426},{0,0,-0.0240116194,0.999711692},{0,0,-0.0220575426,0.999756694},{0,0,-0.0197260138,0.99980545}}},
{bone="Tail1",path="rotation",values={{0,-0.00978656858,0,0.999952137},{0,-0.00705847051,0,0.999975085},{0,-0.00420954823,0,0.999991119},{0,-0.00128856488,0,0.999999166},{0,0.00165447709,0,0.999998629},{0,0.00456919661,0,0.999989569},{0,0.00740569877,0,0.999972582},{0,0.0101154335,0,0.999948859},{0,0.0126520265,0,0.999919951},{0,0.0149720777,0,0.999887884},{0,0.0170358997,0,0.999854863},{0,0.0188081991,0,0.999823093},{0,0.0202586744,0,0.999794781},{0,0.0213625301,0,0.999771774},{0,0.0221009068,0,0.99975574},{0,0.0224611834,0,0.999747694},{0,0.0224372055,0,0.99974823},{0,0.022029385,0,0.999757349},{0,0.0212446861,0,0.999774277},{0,0.02009652,0,0.999798059},{0,0.0186045077,0,0.999826908},{0,0.0167941544,0,0.999858975},{0,0.0146964099,0,0.999891996},{0,0.0123471525,0,0.999923766},{0,0.00978656858,0,0.999952137},{0,0.00705847051,0,0.999975085},{0,0.00420954823,0,0.999991119},{0,0.00128856488,0,0.999999166},{0,-0.00165447709,0,0.999998629},{0,-0.00456919661,0,0.999989569},{0,-0.00740569877,0,0.999972582},{0,-0.0101154335,0,0.999948859},{0,-0.0126520265,0,0.999919951},{0,-0.0149720777,0,0.999887884},{0,-0.0170358997,0,0.999854863},{0,-0.0188081991,0,0.999823093},{0,-0.0202586744,0,0.999794781},{0,-0.0213625301,0,0.999771774},{0,-0.0221009068,0,0.99975574},{0,-0.0224611834,0,0.999747694},{0,-0.0224372055,0,0.99974823},{0,-0.022029385,0,0.999757349},{0,-0.0212446861,0,0.999774277},{0,-0.02009652,0,0.999798059},{0,-0.0186045077,0,0.999826908},{0,-0.0167941544,0,0.999858975},{0,-0.0146964099,0,0.999891996},{0,-0.0123471525,0,0.999923766},{0,-0.00978656858,0,0.999952137}}},
{bone="Tail2",path="rotation",values={{0,-0.0176239423,0,0.99984467},{0,-0.0156478658,0,0.999877572},{0,-0.0134040006,0,0.999910176},{0,-0.0109307291,0,0.999940276},{0,-0.00827036612,0,0.999965787},{0,-0.00546843698,0,0.999985039},{0,-0.00257289805,0,0.999996662},{0,0.000366685534,0,0.99999994},{0,0.00329999183,0,0.999994576},{0,0.00617680699,0,0.999980927},{0,0.00894788746,0,0.999959946},{0,0.0115658073,0,0.999933124},{0,0.013985768,0,0.999902189},{0,0.0161663704,0,0.999869287},{0,0.0180703197,0,0.999836743},{0,0.0196650587,0,0.999806643},{0,0.0209233258,0,0.999781072},{0,0.0218236167,0,0.99976182},{0,0.0223505478,0,0.999750197},{0,0.0224951133,0,0.999746978},{0,0.022254847,0,0.999752343},{0,0.0216338523,0,0.999765933},{0,0.0206427388,0,0.999786913},{0,0.0192984436,0,0.999813795},{0,0.0176239423,0,0.99984467},{0,0.0156478658,0,0.999877572},{0,0.0134040006,0,0.999910176},{0,0.0109307291,0,0.999940276},{0,0.00827036612,0,0.999965787},{0,0.00546843698,0,0.999985039},{0,0.00257289805,0,0.999996662},{0,-0.000366685534,0,0.99999994},{0,-0.00329999183,0,0.999994576},{0,-0.00617680699,0,0.999980927},{0,-0.00894788746,0,0.999959946},{0,-0.0115658073,0,0.999933124},{0,-0.013985768,0,0.999902189},{0,-0.0161663704,0,0.999869287},{0,-0.0180703197,0,0.999836743},{0,-0.0196650587,0,0.999806643},{0,-0.0209233258,0,0.999781072},{0,-0.0218236167,0,0.99976182},{0,-0.0223505478,0,0.999750197},{0,-0.0224951133,0,0.999746978},{0,-0.022254847,0,0.999752343},{0,-0.0216338523,0,0.999765933},{0,-0.0206427388,0,0.999786913},{0,-0.0192984436,0,0.999813795},{0,-0.0176239423,0,0.99984467}}},
{bone="Tail3",path="rotation",values={{0,-0.0219520126,0,0.999759018},{0,-0.0211212002,0,0.9997769},{0,-0.019929029,0,0.999801397},{0,-0.0183958765,0,0.999830782},{0,-0.0165479463,0,0.999863088},{0,-0.0144168381,0,0.999896049},{0,-0.0120389974,0,0.999927521},{0,-0.0094551025,0,0.999955297},{0,-0.00670936704,0,0.999977469},{0,-0.00384878134,0,0.999992609},{0,-0.000922310224,0,0.999999583},{0,0.00201994972,0,0.999997973},{0,0.00492763054,0,0.999987841},{0,0.00775095867,0,0.999969959},{0,0.0104416106,0,0.999945462},{0,0.0129535394,0,0.999916077},{0,0.0152437678,0,0.999883831},{0,0.0172731206,0,0.99985081},{0,0.0190068949,0,0.999819338},{0,0.0204154458,0,0.999791563},{0,0.0214747023,0,0.99976939},{0,0.0221665576,0,0.99975431},{0,0.0224791951,0,0.999747336},{0,0.0224072691,0,0.999748945},{0,0.0219520126,0,0.999759018},{0,0.0211212002,0,0.9997769},{0,0.019929029,0,0.999801397},{0,0.0183958765,0,0.999830782},{0,0.0165479463,0,0.999863088},{0,0.0144168381,0,0.999896049},{0,0.0120389974,0,0.999927521},{0,0.0094551025,0,0.999955297},{0,0.00670936704,0,0.999977469},{0,0.00384878134,0,0.999992609},{0,0.000922310224,0,0.999999583},{0,-0.00201994972,0,0.999997973},{0,-0.00492763054,0,0.999987841},{0,-0.00775095867,0,0.999969959},{0,-0.0104416106,0,0.999945462},{0,-0.0129535394,0,0.999916077},{0,-0.0152437678,0,0.999883831},{0,-0.0172731206,0,0.99985081},{0,-0.0190068949,0,0.999819338},{0,-0.0204154458,0,0.999791563},{0,-0.0214747023,0,0.99976939},{0,-0.0221665576,0,0.99975431},{0,-0.0224791951,0,0.999747336},{0,-0.0224072691,0,0.999748945},{0,-0.0219520126,0,0.999759018}}},
{bone="Tail4",path="rotation",values={{0,-0.0219098181,0,0.999759972},{0,-0.0223894995,0,0.999749303},{0,-0.0224861521,0,0.999747157},{0,-0.0221981257,0,0.999753594},{0,-0.0215303376,0,0.999768198},{0,-0.0204942003,0,0.999789953},{0,-0.0191074219,0,0.999817431},{0,-0.0173937026,0,0.999848723},{0,-0.015382342,0,0.999881685},{0,-0.0131077357,0,0.99991411},{0,-0.0106087914,0,0.999943733},{0,-0.0079282634,0,0.999968588},{0,-0.00511202496,0,0.999986947},{0,-0.00220827712,0,0.999997556},{0,0.000733273628,0,0.999999702},{0,0.00366227166,0,0.999993265},{0,0.00652857684,0,0.999978662},{0,0.00928312633,0,0.999956906},{0,0.0118787782,0,0.999929428},{0,0.0142711168,0,0.999898136},{0,0.016419217,0,0.999865174},{0,0.0182863381,0,0.999832809},{0,0.0198405553,0,0.999803185},{0,0.0210553035,0,0.99977833},{0,0.0219098181,0,0.999759972},{0,0.0223894995,0,0.999749303},{0,0.0224861521,0,0.999747157},{0,0.0221981257,0,0.999753594},{0,0.0215303376,0,0.999768198},{0,0.0204942003,0,0.999789953},{0,0.0191074219,0,0.999817431},{0,0.0173937026,0,0.999848723},{0,0.015382342,0,0.999881685},{0,0.0131077357,0,0.99991411},{0,0.0106087914,0,0.999943733},{0,0.0079282634,0,0.999968588},{0,0.00511202496,0,0.999986947},{0,0.00220827712,0,0.999997556},{0,-0.000733273628,0,0.999999702},{0,-0.00366227166,0,0.999993265},{0,-0.00652857684,0,0.999978662},{0,-0.00928312633,0,0.999956906},{0,-0.0118787782,0,0.999929428},{0,-0.0142711168,0,0.999898136},{0,-0.016419217,0,0.999865174},{0,-0.0182863381,0,0.999832809},{0,-0.0198405553,0,0.999803185},{0,-0.0210553035,0,0.99977833},{0,-0.0219098181,0,0.999759972}}},
{bone="Tail5",path="rotation",values={{0,-0.0175057519,0,0.999846756},{0,-0.0192005411,0,0.999815643},{0,-0.0205667969,0,0.999788463},{0,-0.0215811692,0,0.999767125},{0,-0.0222263243,0,0.999752939},{0,-0.0224912371,0,0.999747038},{0,-0.0223713834,0,0.99974972},{0,-0.0218688101,0,0.999760866},{0,-0.020992104,0,0.999779642},{0,-0.0197562445,0,0.999804854},{0,-0.0181823578,0,0.999834716},{0,-0.0162973441,0,0.999867201},{0,-0.0141334357,0,0.999900103},{0,-0.0117276441,0,0.999931216},{0,-0.00912112556,0,0.999958396},{0,-0.00635848055,0,0.999979794},{0,-0.00348699163,0,0.99999392},{0,-0.000555810519,0,0.999999821},{0,0.00238488545,0,0.999997139},{0,0.00528475503,0,0.999986053},{0,0.00809415895,0,0.999967217},{0,0.0107650133,0,0.999942064},{0,0.0132516101,0,0.999912202},{0,0.0155114084,0,0.999879718},{0,0.0175057519,0,0.999846756},{0,0.0192005411,0,0.999815643},{0,0.0205667969,0,0.999788463},{0,0.0215811692,0,0.999767125},{0,0.0222263243,0,0.999752939},{0,0.0224912371,0,0.999747038},{0,0.0223713834,0,0.99974972},{0,0.0218688101,0,0.999760866},{0,0.020992104,0,0.999779642},{0,0.0197562445,0,0.999804854},{0,0.0181823578,0,0.999834716},{0,0.0162973441,0,0.999867201},{0,0.0141334357,0,0.999900103},{0,0.0117276441,0,0.999931216},{0,0.00912112556,0,0.999958396},{0,0.00635848055,0,0.999979794},{0,0.00348699163,0,0.99999392},{0,0.000555810519,0,0.999999821},{0,-0.00238488545,0,0.999997139},{0,-0.00528475503,0,0.999986053},{0,-0.00809415895,0,0.999967217},{0,-0.0107650133,0,0.999942064},{0,-0.0132516101,0,0.999912202},{0,-0.0155114084,0,0.999879718},{0,-0.0175057519,0,0.999846756}}},
{bone="LeftFrontUpper",path="rotation",values={{0,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{1.46957619e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-2.93915238e-17,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{4.4087284e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-5.87830476e-17,0,0,1}}},
{bone="LeftFrontLower",path="rotation",values={{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-1.22464677e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-3.67394056e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1}}},
{bone="LeftFrontPaw",path="rotation",values={{0,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{4.89858716e-18,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{1.46957619e-17,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{1.46957619e-17,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{2.93915238e-17,0,0,1}}},
{bone="LeftRearUpper",path="rotation",values={{1.46957619e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-2.93915238e-17,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{4.4087284e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-5.87830476e-17,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{7.34788112e-17,0,0,1}}},
{bone="LeftRearLower",path="rotation",values={{-1.22464677e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-3.67394056e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-6.12323426e-17,0,0,1}}},
{bone="LeftRearPaw",path="rotation",values={{4.89858716e-18,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{1.46957619e-17,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{1.46957619e-17,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{2.93915238e-17,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{2.44929354e-17,0,0,1}}},
{bone="RightFrontUpper",path="rotation",values={{1.46957619e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-2.93915238e-17,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{4.4087284e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-5.87830476e-17,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{7.34788112e-17,0,0,1}}},
{bone="RightFrontLower",path="rotation",values={{-1.22464677e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-3.67394056e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-6.12323426e-17,0,0,1}}},
{bone="RightFrontPaw",path="rotation",values={{4.89858716e-18,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{1.46957619e-17,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{1.46957619e-17,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{2.93915238e-17,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{2.44929354e-17,0,0,1}}},
{bone="RightRearUpper",path="rotation",values={{0,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{1.46957619e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-2.93915238e-17,0,0,1},{0.0310532916,0,0,0.999517739},{0.0599640049,0,0,0.998200536},{0.0847510248,0,0,0.996402144},{0.103736088,0,0,0.994604886},{0.115651719,0,0,0.993289828},{0.119712204,0,0,0.99280864},{0.115651719,0,0,0.993289828},{0.103736088,0,0,0.994604886},{0.0847510248,0,0,0.996402144},{0.0599640049,0,0,0.998200536},{0.0310532916,0,0,0.999517739},{4.4087284e-17,0,0,1},{-0.0310532916,0,0,0.999517739},{-0.0599640049,0,0,0.998200536},{-0.0847510248,0,0,0.996402144},{-0.103736088,0,0,0.994604886},{-0.115651719,0,0,0.993289828},{-0.119712204,0,0,0.99280864},{-0.115651719,0,0,0.993289828},{-0.103736088,0,0,0.994604886},{-0.0847510248,0,0,0.996402144},{-0.0599640049,0,0,0.998200536},{-0.0310532916,0,0,0.999517739},{-5.87830476e-17,0,0,1}}},
{bone="RightRearLower",path="rotation",values={{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-1.22464677e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0.0258790143,0,0,0.999665082},{-0.0499791689,0,0,0.998750269},{-0.0706517696,0,0,0.997501016},{-0.0864943266,0,0,0.996252358},{-0.0964424461,0,0,0.995338559},{-0.099833414,0,0,0.995004177},{-0.0964424461,0,0,0.995338559},{-0.0864943266,0,0,0.996252358},{-0.0706517696,0,0,0.997501016},{-0.0499791689,0,0,0.998750269},{-0.0258790143,0,0,0.999665082},{-3.67394056e-17,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1},{-0,0,0,1}}},
{bone="RightRearPaw",path="rotation",values={{0,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{4.89858716e-18,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{1.46957619e-17,0,0,1},{0.0103525771,0,0,0.999946415},{0.0199986659,0,0,0.999800026},{0.0282805003,0,0,0.999600053},{0.0346340872,0,0,0.999400079},{0.0386274196,0,0,0.99925369},{0.0399893336,0,0,0.999200106},{0.0386274196,0,0,0.99925369},{0.0346340872,0,0,0.999400079},{0.0282805003,0,0,0.999600053},{0.0199986659,0,0,0.999800026},{0.0103525771,0,0,0.999946415},{1.46957619e-17,0,0,1},{0.0155285187,0,0,0.99987942},{0.029995501,0,0,0.999550045},{0.0424136817,0,0,0.999100149},{0.0519381464,0,0,0.998650312},{0.0579231121,0,0,0.998321056},{0.0599640049,0,0,0.998200536},{0.0579231121,0,0,0.998321056},{0.0519381464,0,0,0.998650312},{0.0424136817,0,0,0.999100149},{0.029995501,0,0,0.999550045},{0.0155285187,0,0,0.99987942},{2.93915238e-17,0,0,1}}},
}},
}}
]=]}}
local install=(function()
-- Reviewed user rig installation. Existing objects survive in ServerStorage backups.
local M={}
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local function normalized(s) return s:gsub("\r\n","\n") end
function M.run(updates,modules)
 assert(not game:GetService("RunService"):IsRunning(),"Play를 먼저 중지하세요.")
 local package=assert(RS:FindFirstChild("RodeoFantasy"),"RodeoFantasy 없음")
 local source
 for _,candidate in ipairs(workspace:GetChildren()) do
  if candidate:IsA("Model") and candidate.Name:match("^MossratS3Rigged") then
   local count=0 for _,b in ipairs(candidate:GetDescendants()) do if b:IsA("Bone") then count+=1 end end
   if count==34 then source=candidate break end
  end
 end
 local prepared,changes,additions={},{},{}
 for _,u in ipairs(updates) do
  local parent=u.parent
  local node=assert(parent:FindFirstChild(u.name,true),u.name.." 없음")
  local current=normalized(node.Source)
  assert(current==u.before or current==u.after,u.name.." 코드 버전이 달라 설치를 중단합니다. 기존 코드 보존.")
  if current~=u.after then table.insert(changes,{node=node,before=node.Source,after=u.after}) end
 end
 for _,m in ipairs(modules) do
  local old=m.parent:FindFirstChild(m.name)
  if old then assert(old:IsA("ModuleScript") and normalized(old.Source)==m.source,"이미 있는 모듈 버전 불일치: "..m.name)
  else
   local node=Instance.new("ModuleScript") node.Name=m.name node.Source=m.source
   table.insert(additions,{node=node,parent=m.parent})
  end
 end
 local targets={{SS,"RodeoMonsterTemplate_S3"},{package,"VisualTemplate_S3"},{package,"MeshyMossratHuntTemplate_S3"}}
 local current=true
 for _,t in ipairs(targets) do local old=t[1]:FindFirstChild(t[2]) if not old or old:GetAttribute("MossratUserRigRevision")~="UserS3-v1" then current=false end end
 if current and #changes==0 and #additions==0 then print("MOSSRAT_S3_RIG_ALREADY_CURRENT") return end
 assert(source and source:IsA("Model"),"가져온 리그 Model 이름을 Workspace.MossratS3Rigged로 바꿔 주세요.")
 local meshes,bones={},{}
 for _,p in ipairs(source:GetDescendants()) do
  assert(not p:IsA("LuaSourceContainer"),"입력 모델의 스크립트는 허용하지 않습니다.")
  if p:IsA("MeshPart") then assert(p.MeshId~="","Studio에서 메시 업로드 필요") table.insert(meshes,p) end
  if p:IsA("Bone") then assert(not bones[p.Name],"중복 관절 이름: "..p.Name) bones[p.Name]=p end
 end
 assert(#meshes==1,"승인 모델은 MeshPart 한 개여야 합니다.")
 local expected={["Root"]="",["Pelvis"]="Root",["Spine"]="Pelvis",["Chest"]="Spine",["Neck"]="Chest",["Head"]="Neck",["Jaw"]="Head",["EyeLeft"]="Head",["EyeRight"]="Head",["EarLeft"]="Head",["EarTipLeft"]="EarLeft",["EarRight"]="Head",["EarTipRight"]="EarRight",["Sprout"]="Head",["SproutTip"]="Sprout",["WhiskerLeft"]="Head",["WhiskerRight"]="Head",["LeftFrontUpper"]="Chest",["LeftFrontLower"]="LeftFrontUpper",["LeftFrontPaw"]="LeftFrontLower",["LeftRearUpper"]="Pelvis",["LeftRearLower"]="LeftRearUpper",["LeftRearPaw"]="LeftRearLower",["RightFrontUpper"]="Chest",["RightFrontLower"]="RightFrontUpper",["RightFrontPaw"]="RightFrontLower",["RightRearUpper"]="Pelvis",["RightRearLower"]="RightRearUpper",["RightRearPaw"]="RightRearLower",["Tail1"]="Pelvis",["Tail2"]="Tail1",["Tail3"]="Tail2",["Tail4"]="Tail3",["Tail5"]="Tail4"}
 for name,parent in pairs(expected) do
  local b=assert(bones[name],"리깅 관절 없음: "..name)
  assert(b:IsDescendantOf(meshes[1]),"관절이 메시 밖에 있습니다: "..name)
  assert(parent=="" and b.Parent==meshes[1] or parent~="" and b.Parent==bones[parent],"관절 계층 불일치: "..name)
 end
 local count=0 for _ in pairs(bones) do count+=1 end assert(count==34,"34관절 모델을 가져오세요.")
 local box,size=source:GetBoundingBox()
 assert(size.Y>0 and size.Y<math.huge,"유효하지 않은 모델 높이")
 local scale=3.5/size.Y
 local base=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0))
 local catalog=require(package.MonsterCatalog)
 for _,t in ipairs(targets) do
  local old=t[1]:FindFirstChild(t[2])
  local prototype=old or package:FindFirstChild("VisualTemplate")
  assert(prototype and prototype:IsA("Model") and prototype.PrimaryPart,"기존 템플릿 Root 없음: "..t[2])
  local model=prototype:Clone() model.Name=t[2]
  for _,child in ipairs(model:GetChildren()) do if child:IsA("BasePart") and child~=model.PrimaryPart then child:Destroy() end end
  local part=meshes[1]:Clone() part.Name="Body"
  local relative=base:ToObjectSpace(meshes[1].CFrame)
  local rest=CFrame.Angles(0,math.pi,0)*CFrame.new(relative.Position*scale-Vector3.new(0,catalog.MeadowMouse.RootHeight*catalog.Scales[3],0))*relative.Rotation
  part.Size*=scale part.CFrame=model.PrimaryPart.CFrame*rest
  for _,b in ipairs(part:GetDescendants()) do if b:IsA("Bone") then b.CFrame=CFrame.new(b.CFrame.Position*scale)*b.CFrame.Rotation b.Transform=CFrame.identity end end
  part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
  part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position) part.Parent=model
  for _,name in ipairs({"NativeMeshyMossrat","NativeMeshyReady","MeshDecorated","ImportedA","MeshyFacingCorrected","UserApprovedHuntModel"}) do model:SetAttribute(name,true) end
  model:SetAttribute("FaceCourseForward",true)
  model:SetAttribute("NativeMeshyStars",3) model:SetAttribute("MeshyVisualYawDegrees",0)
  model:SetAttribute("MeshyFacingRevision","UserS3-v1") model:SetAttribute("MossratUserRigRevision","UserS3-v1")
  model:SetAttribute("MossratRigTranslationScale",3.5/1.26)
  model:SetAttribute("MeshyBackHeight",1.50)
  model:SetAttribute("UserModelSourceSha256","db41ce805303eacff7e6565e58aef96b7dc25708b332350904789e2136acbda0")
  table.insert(prepared,{parent=t[1],old=old,node=model})
 end
 local backup=Instance.new("Folder") backup.Name="MossratS3RigBackup_"..game:GetService("HttpService"):GenerateGUID(false)
 for _,c in ipairs(changes) do local clone=c.node:Clone() clone.Parent=backup end
 game:GetService("ChangeHistoryService"):SetWaypoint("Before approved Mossrat rig")
 local ok,err=pcall(function()
  backup.Parent=SS
  for _,p in ipairs(prepared) do if p.old then p.old.Parent=backup end p.node.Parent=p.parent end
  for _,a in ipairs(additions) do a.node.Parent=a.parent end
  for _,c in ipairs(changes) do c.node.Source=c.after end
  source.Parent=backup
 end)
 if not ok then
  for _,c in ipairs(changes) do c.node.Source=c.before end
  for _,a in ipairs(additions) do a.node:Destroy() end
  for _,p in ipairs(prepared) do p.node:Destroy() if p.old then p.old.Parent=p.parent end end
  source.Parent=workspace backup:Destroy() error("설치 복구 완료: "..tostring(err))
 end
 game:GetService("ChangeHistoryService"):SetWaypoint("Approved Mossrat rig installed")
 print("MOSSRAT_S3_RIG_INSTALLED — Ctrl+S로 저장. 새 숲 준비 여부는 별도입니다.")
end
return M

end)()
install.run(updates,modules)
end
