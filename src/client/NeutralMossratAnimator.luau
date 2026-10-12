-- Shared locomotion for the supplied straight-pose S1/S3 meshes.
-- Bone lengths come from each mesh; there are no old head/torso corrections.
local A={}
local quadruped=require(script.Parent.QuadrupedAnimator)
local cache=setmetatable({},{__mode="k"})
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 local ownRide=model:GetAttribute("RiderUserId")==game.Players.LocalPlayer.UserId
 local distance=(body.Position-workspace.CurrentCamera.CFrame.Position).Magnitude
 if distance>150 and not ownRide then return end
 local interval=distance>70 and not ownRide and .1 or moving and 1/30 or 1/15
 if now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 1/30 c.last=now
 local first=(model:GetAttribute("Stars") or 1)<3
 local time=workspace:GetServerTimeNow()
 local untilTime=model:GetAttribute("PetBondUntil") or 0
 local bonding=first and untilTime>time
 for name,b in pairs(c.bones) do
  local target=CFrame.identity
  if not moving and not bonding and (name=="Spine" or name=="Chest") then
   target=CFrame.Angles(math.sin(now*1.8)*.012,0,0)
  end
  local tail=tonumber(name:match("^Tail(%d+)$"))
  if first and tail then target=CFrame.Angles(0,math.sin(now*1.6-tail*.45)*.075,0) end
  if bonding then
   local t=time-(model:GetAttribute("PetBondStarted") or time)
   local weight=math.min(math.clamp(t/.35,0,1),math.clamp((untilTime-time)/.4,0,1))
   -- The supplied face blends Neck/Head weights. Rotating Head alone pulls
   -- only the forehead. Tilt their shared parent and leave Head neutral.
   if name=="Neck" then target=CFrame.Angles(0,0,math.sin(t*4)*.10) end
   target=CFrame.identity:Lerp(target,weight)
  end
  -- Locomotion owns leg transforms; retain them until its smooth stop is done.
  if bonding or not name:match("Front") and not name:match("Rear") then
   b.Transform=b.Transform:Lerp(target,1-math.exp(-18*dt))
  end
 end
 if not bonding then quadruped.apply(model,moving,dt,true) end
end
return A
