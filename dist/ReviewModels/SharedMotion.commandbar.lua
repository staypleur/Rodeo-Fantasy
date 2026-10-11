assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local P=game.ReplicatedStorage.RodeoFantasy
local C=game.StarterPlayer.StarterPlayerScripts
local updates={{parent=C,name=[=[BipedAnimator]=],before=[=[-- One decoded clip cache; each creature owns only its skeleton and playback state.
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
 local stage=model:GetAttribute("Stars") or 6
 local ease=bonding and math.min(math.clamp((bondTime-(model:GetAttribute("PetBondStarted") or bondTime))/.4,0,1),math.clamp((bondUntil-bondTime)/.4,0,1)) or 0
 for _,e in ipairs(c.bones) do
  local parentRotation=e.parent and e.parent.currentRotation or CFrame.identity
  local desired=e.source and (moving and first[e.source]:Lerp(second[e.source],t) or CFrame.identity)*e.rest.Rotation or parentRotation*e.localRest.Rotation
  local name=e.bone.Name:gsub("mixamorig:","")
  if bonding then
   local side=name:find("Left",1,true) and 1 or -1
   local pose=CFrame.identity
   local mapped=mapping[name] or name
   if stage>=9 then
    if mapped=="Spine2" then pose=CFrame.Angles(-.28,0,0)
    elseif mapped=="Head" then pose=CFrame.Angles(-.4,0,0)
    elseif mapped=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(.15,0,side*.6)
    elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-.5,0,0) end
   elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(-.25,0,side*1.15)
   elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-1.3,0,0)
   elseif mapped=="Spine2" then pose=CFrame.Angles(-.12,0,0) end
   desired=desired:Lerp(pose*e.rest.Rotation,ease)
  end
  local transform=e.localRest.Rotation:Inverse()*parentRotation:Inverse()*desired
  local tailIndex=tonumber(name:match("^Tail(%d+)$"))
  if tailIndex then transform*=CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035) end
  if name=="Hips" or name=="Pelvis" then
   transform=CFrame.new(e.localRest.Rotation:VectorToObjectSpace(parentRotation:VectorToObjectSpace(hip)))*transform
  end
  e.bone.Transform=e.bone.Transform:Lerp(transform,1-math.exp(-18*dt))
  e.currentRotation=parentRotation*e.localRest.Rotation*e.bone.Transform.Rotation
 end
end
return A
]=],after=[=[-- One decoded clip cache; each creature owns only its skeleton and playback state.
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
 local stage=model:GetAttribute("Stars") or 6
 local ease=bonding and math.min(math.clamp((bondTime-(model:GetAttribute("PetBondStarted") or bondTime))/.4,0,1),math.clamp((bondUntil-bondTime)/.4,0,1)) or 0
 for _,e in ipairs(c.bones) do
  local parentRotation=e.parent and e.parent.currentRotation or CFrame.identity
  local desired=e.source and (moving and first[e.source]:Lerp(second[e.source],t) or CFrame.identity)*e.rest.Rotation or parentRotation*e.localRest.Rotation
  local name=e.bone.Name:gsub("mixamorig:","")
  if bonding then
   local side=name:find("Left",1,true) and 1 or -1
   local pose=CFrame.identity
   local mapped=mapping[name] or name
   if stage>=9 then
    if mapped=="Spine2" then pose=CFrame.Angles(-.28,0,0)
    elseif mapped=="Head" then pose=CFrame.Angles(-.4,0,0)
    elseif mapped=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(.15,0,side*.6)
    elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-.5,0,0) end
   elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(-.25,0,side*1.15)
   elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-1.3,0,0)
   elseif mapped=="Spine2" then pose=CFrame.Angles(-.12,0,0) end
   desired=desired:Lerp(pose*e.rest.Rotation,ease)
  end
  local transform=e.localRest.Rotation:Inverse()*parentRotation:Inverse()*desired
  local tailIndex=tonumber(name:match("^Tail(%d+)$"))
  if tailIndex then transform*=CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035) end
  if name=="Hips" or name=="Pelvis" then
   transform=CFrame.new(e.localRest.Rotation:VectorToObjectSpace(parentRotation:VectorToObjectSpace(hip)))*transform
  end
  e.bone.Transform=e.bone.Transform:Lerp(transform,1-math.exp(-18*dt))
  e.currentRotation=parentRotation*e.localRest.Rotation*e.bone.Transform.Rotation
 end
end
return A
]=]},{parent=C,name=[=[QuadrupedAnimator]=],before=[=[local motion=require(game.ReplicatedStorage.RodeoFantasy.QuadrupedMotion)
local A={}
local cache=setmetatable({},{__mode="k"})
function A.apply(model,moving,dt)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,legs={},phase=0,weight=0}
  for _,side in ipairs({"Left","Right"}) do
   for _,limb in ipairs({"Front","Rear"}) do
    local name=side..limb
    local upper=body:FindFirstChild(name.."Upper",true)
    local lower=body:FindFirstChild(name.."Lower",true)
    local paw=body:FindFirstChild(name.."Paw",true)
    if upper and lower and paw and lower.Parent==upper and paw.Parent==lower then
     local u,l=lower.CFrame.Position,paw.CFrame.Position
     local a,b=Vector2.new(u.Y,u.Z).Magnitude,Vector2.new(l.Y,l.Z).Magnitude
     if a>.001 and b>.001 then
      c.legs[#c.legs+1]={name=name,upper=upper,lower=lower,paw=paw,a=a,b=b,
       y=u.Y+l.Y,z=u.Z+l.Z,restA=math.atan2(u.Z,-u.Y),restB=math.atan2(l.Z,-l.Y),bend=limb=="Front" and -1 or 1}
     end
    end
   end
  end
  cache[model]=c
 end
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=speed>18
 c.weight+=( (moving and 1 or 0)-c.weight)*(1-math.exp(-12*dt))
 c.phase=(c.phase+dt*(running and 2.2 or 1.35))%1
 for _,leg in ipairs(c.legs) do
  local length=leg.a+leg.b
  local z,lift=motion.foot(c.phase,leg.name,running)
  local a,b=motion.solve(leg.y+length*(.06+lift*.22),leg.z+z*length*(running and .65 or .45),leg.a,leg.b,leg.bend)
  local upper=-(a-leg.restA)
  local lower=-(b-leg.restB)-upper
  leg.upper.Transform=CFrame.identity:Lerp(CFrame.Angles(upper,0,0),c.weight)
  leg.lower.Transform=CFrame.identity:Lerp(CFrame.Angles(lower,0,0),c.weight)
  leg.paw.Transform=CFrame.identity:Lerp(CFrame.Angles(-upper-lower,0,0),c.weight)
 end
end
return A
]=],after=[=[local motion=require(game.ReplicatedStorage.RodeoFantasy.QuadrupedMotion)
local A={}
local cache=setmetatable({},{__mode="k"})
function A.apply(model,moving,dt)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,legs={},phase=0,weight=0}
  for _,side in ipairs({"Left","Right"}) do
   for _,limb in ipairs({"Front","Rear"}) do
    local name=side..limb
    local upper=body:FindFirstChild(name.."Upper",true)
    local lower=body:FindFirstChild(name.."Lower",true)
    local paw=body:FindFirstChild(name.."Paw",true)
    if upper and lower and paw and lower.Parent==upper and paw.Parent==lower then
     local u,l=lower.CFrame.Position,paw.CFrame.Position
     local a,b=Vector2.new(u.Y,u.Z).Magnitude,Vector2.new(l.Y,l.Z).Magnitude
     if a>.001 and b>.001 then
      c.legs[#c.legs+1]={name=name,upper=upper,lower=lower,paw=paw,a=a,b=b,
       y=u.Y+l.Y,z=u.Z+l.Z,restA=math.atan2(u.Z,-u.Y),restB=math.atan2(l.Z,-l.Y),bend=limb=="Front" and -1 or 1}
     end
    end
   end
  end
  cache[model]=c
 end
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=speed>18
 c.weight+=( (moving and 1 or 0)-c.weight)*(1-math.exp(-12*dt))
 c.phase=(c.phase+dt*(running and 2.2 or 1.35))%1
 for _,leg in ipairs(c.legs) do
  local length=leg.a+leg.b
  local z,lift=motion.foot(c.phase,leg.name,running)
  local a,b=motion.solve(leg.y+length*(.06+lift*.22),leg.z+z*length*(running and .65 or .45),leg.a,leg.b,leg.bend)
  local upper=-(a-leg.restA)
  local lower=-(b-leg.restB)-upper
  leg.upper.Transform=CFrame.identity:Lerp(CFrame.Angles(upper,0,0),c.weight)
  leg.lower.Transform=CFrame.identity:Lerp(CFrame.Angles(lower,0,0),c.weight)
  leg.paw.Transform=CFrame.identity:Lerp(CFrame.Angles(-upper-lower,0,0),c.weight)
 end
end
return A
]=]},{parent=C,name=[=[UserMossratRigAnimator]=],before=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local quadruped=require(script.Parent.QuadrupedAnimator)
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
 if c.mode and now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 1/30 c.last=now
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
   elseif legSide and legLimb and moving and s6 then
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
 if not s6 and not bonding then quadruped.apply(model,moving,dt) end
end
return A
]=],after=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local quadruped=require(script.Parent.QuadrupedAnimator)
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
 if c.mode and now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 1/30 c.last=now
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
   elseif legSide and legLimb and moving and s6 then
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
 if not s6 and not bonding then quadruped.apply(model,moving,dt) end
end
return A
]=]},{parent=C,name=[=[NativeMossrat]=],before=[=[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
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
 -- Legacy S9 weights stretch under the full clip. Keep its existing playback
 -- until its skin is fitted to the shared skeleton; name mapping is not enough.
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
]=],after=[=[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
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
 -- Legacy S9 weights stretch under the full clip. Keep its existing playback
 -- until its skin is fitted to the shared skeleton; name mapping is not enough.
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
]=]},{parent=C,name=[=[RideAnimator]=],before=[=[-- Procedural visual motion for the native part model. Never changes its mount root.
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
  -- The supplied biped clip already contains its own hip travel.
  if model:GetAttribute("MossratUserRigRevision")=="ProvidedBiped-v1" then bounce=0 gallopPitch=0 end
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
]=],after=[=[-- Procedural visual motion for the native part model. Never changes its mount root.
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
  -- The supplied biped clip already contains its own hip travel.
  if model:GetAttribute("MossratUserRigRevision")=="ProvidedBiped-v1" then bounce=0 gallopPitch=0 end
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
]=]},{parent=C,name=[=[PetPromptUI]=],before=[=[-- Only this bounded image button can request bonding; no world-touch prompt.
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
]=],after=[=[-- Only this bounded image button can request bonding; no world-touch prompt.
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
]=]},{parent=P,name=[=[QuadrupedMotion]=],before=[=[-- Shared normalized foot paths and two-segment inverse kinematics.
-- One module for every compatible quadruped; dimensions come from its bind pose.
local M={}
local walk={LeftRear=0,LeftFront=.25,RightRear=.5,RightFront=.75}
local trot={LeftRear=0,RightFront=0,RightRear=.5,LeftFront=.5}
function M.foot(phase,limb,running)
 local p=(phase+(running and trot or walk)[limb])%1
 local stance=running and .52 or .72
 if p<stance then return .5-p/stance,0 end
 local t=(p-stance)/(1-stance)
 local smooth=t*t*(3-2*t)
 return -.5+smooth,math.sin(math.pi*t)^2
end
function M.solve(y,z,upper,lower,bend)
 local d=math.clamp(math.sqrt(y*y+z*z),math.abs(upper-lower)+1e-5,upper+lower-1e-5)
 local direction=math.atan2(z,-y)
 local angle=math.acos(math.clamp((upper*upper+d*d-lower*lower)/(2*upper*d),-1,1))
 local a=direction+bend*angle
 local kneeY=-math.cos(a)*upper local kneeZ=math.sin(a)*upper
 -- Use the clamped endpoint to remain finite when the requested foot is unreachable.
 local targetY=-math.cos(direction)*d local targetZ=math.sin(direction)*d
 local b=math.atan2(targetZ-kneeZ,-(targetY-kneeY))
 return a,b
end
return M
]=],after=[=[-- Shared normalized foot paths and two-segment inverse kinematics.
-- One module for every compatible quadruped; dimensions come from its bind pose.
local M={}
local walk={LeftRear=0,LeftFront=.25,RightRear=.5,RightFront=.75}
local trot={LeftRear=0,RightFront=0,RightRear=.5,LeftFront=.5}
function M.foot(phase,limb,running)
 local p=(phase+(running and trot or walk)[limb])%1
 local stance=running and .52 or .72
 if p<stance then return .5-p/stance,0 end
 local t=(p-stance)/(1-stance)
 local smooth=t*t*(3-2*t)
 return -.5+smooth,math.sin(math.pi*t)^2
end
function M.solve(y,z,upper,lower,bend)
 local d=math.clamp(math.sqrt(y*y+z*z),math.abs(upper-lower)+1e-5,upper+lower-1e-5)
 local direction=math.atan2(z,-y)
 local angle=math.acos(math.clamp((upper*upper+d*d-lower*lower)/(2*upper*d),-1,1))
 local a=direction+bend*angle
 local kneeY=-math.cos(a)*upper local kneeZ=math.sin(a)*upper
 -- Use the clamped endpoint to remain finite when the requested foot is unreachable.
 local targetY=-math.cos(direction)*d local targetZ=math.sin(direction)*d
 local b=math.atan2(targetZ-kneeZ,-(targetY-kneeY))
 return a,b
end
return M
]=]}}
for _,u in ipairs(updates) do
 local n=u.parent:FindFirstChild(u.name)
 assert(not n and not u.before or n and n:IsA("ModuleScript") and (n.Source:gsub("\r\n","\n")==u.before or n.Source:gsub("\r\n","\n")==u.after),u.name.." changed")
end
for _,m in ipairs({P.VisualTemplate_S6,P.MeshyMossratHuntTemplate_S6,game.ServerStorage.RodeoMonsterTemplate_S6}) do
 assert(m:GetAttribute("MossratUserRigRevision")=="ProvidedBiped-v1","S6 rig changed")
 assert(m:FindFirstChild("Body") and m.Body:FindFirstChildOfClass("SurfaceAppearance"),"S6 surface missing")
end
local backup=Instance.new("Folder") backup.Name="SharedMotionBackup_"..game.HttpService:GenerateGUID(false) backup.Parent=game.ServerStorage
game.ChangeHistoryService:SetWaypoint("Before shared motion")
for _,u in ipairs(updates) do
 local n=u.parent:FindFirstChild(u.name)
 if n then n:Clone().Parent=backup else n=Instance.new("ModuleScript") n.Name=u.name n.Parent=u.parent end
 n.Source=u.after
end
for _,m in ipairs({P.VisualTemplate_S6,P.MeshyMossratHuntTemplate_S6,game.ServerStorage.RodeoMonsterTemplate_S6}) do
 assert(m:GetAttribute("MossratUserRigRevision")=="ProvidedBiped-v1")
 m:Clone().Parent=backup
 local b=m.Body
 if not m:GetAttribute("ProvidedBipedFacingFixed") then
  local rest=b:GetAttribute("ApprovedRest")
  rest=CFrame.new(rest.Position)*rest.Rotation*CFrame.Angles(0,math.pi,0)
  b:SetAttribute("ApprovedRest",rest) b.CFrame=m.PrimaryPart.CFrame*rest
  m:SetAttribute("ProvidedBipedFacingFixed",true)
  m:SetAttribute("MeshyFacingRevision","ProvidedBiped-Forward-v2")
 end
 local s=b:FindFirstChildOfClass("SurfaceAppearance") assert(s)
 s.ColorMap="rbxassetid://122822919155461"
end
game.ChangeHistoryService:SetWaypoint("Shared motion updated")
print("SHARED_MOTION_INSTALLED",#updates,"modules; S6 texture and facing")
