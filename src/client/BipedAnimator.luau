-- One decoded clip cache; each creature owns only its skeleton and playback state.
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
