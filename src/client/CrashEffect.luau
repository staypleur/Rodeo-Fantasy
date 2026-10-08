-- Cartoon breakup using temporary visual clones; never destroys the real avatar.
local Effect={}
local shards,hidden={},{}
local character,started
local function clear()
 for _,entry in ipairs(shards) do entry.part:Destroy() end
 for part,value in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=value end end
 shards,hidden={},{}
 character,started=nil,nil
end
function Effect.start(model,clock)
 clear()
 if not model then return end
 character,started=model,clock
 local root=model:FindFirstChild("HumanoidRootPart")
 local center=root and root.Position or Vector3.zero
 local index=0
 for _,original in ipairs(model:GetDescendants()) do
  if not original:IsA("BasePart") then continue end
  hidden[original]=original.LocalTransparencyModifier
  original.LocalTransparencyModifier=1
  if original.Name=="HumanoidRootPart" or original.Transparency>=1 then continue end
  index+=1
  local archived=original.Archivable original.Archivable=true
  local shard=original:Clone() original.Archivable=archived
  for _,item in ipairs(shard:GetDescendants()) do
   if item:IsA("JointInstance") or item:IsA("Constraint") or item:IsA("LuaSourceContainer") or item:IsA("Attachment") or item:IsA("ParticleEmitter") or item:IsA("Sound") or item:IsA("Trail") or item:IsA("Beam") then item:Destroy() end
  end
  shard.Name="LocalCrashShard" shard.Anchored=true
  shard.LocalTransparencyModifier=0
  shard.CanCollide,shard.CanTouch,shard.CanQuery=false,false,false
  shard.Parent=workspace
  local direction=original.Position-center
  local radial=Vector3.new(direction.X,0,direction.Z)
  if radial.Magnitude<0.1 then radial=Vector3.new(math.cos(index*2.4),0,math.sin(index*2.4)) end
  local velocity=radial.Unit*12+Vector3.new(0,12+index%4,10)
  table.insert(shards,{part=shard,origin=shard.CFrame,velocity=velocity,alpha=original.Transparency,spin=Vector3.new(index%3+1,1,index%2+1)})
 end
end
function Effect.update(model,phase,clock)
 if character and (model~=character or phase~="GameOver") then clear() end
 if not started then return end
 for part in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=1 end end
 local elapsed=clock-started
 for i=#shards,1,-1 do
  local entry=shards[i]
  if elapsed>=1.15 then entry.part:Destroy() table.remove(shards,i)
  else
   local position=entry.origin.Position+entry.velocity*elapsed+Vector3.new(0,-20*elapsed*elapsed,0)
   position=Vector3.new(position.X,math.max(0.3,position.Y),position.Z)
   local spin=entry.spin*elapsed*4
   entry.part.CFrame=CFrame.new(position)*entry.origin.Rotation*CFrame.Angles(spin.X,spin.Y,spin.Z)
   entry.part.Transparency=entry.alpha+(1-entry.alpha)*math.clamp((elapsed-0.65)/0.5,0,1)
  end
 end
end
function Effect.clear() clear() end
return Effect
