-- Cartoon breakup using temporary visual clones; never destroys the real avatar.
local Effect={}
local shards,hidden={},{}
local character,started
local labels={}
local function clear()
 for _,entry in ipairs(shards) do entry.part:Destroy() end
 for part,value in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=value end end
 for gui,value in pairs(labels) do if gui.Parent then gui.Enabled=value end end
 labels={}
 shards,hidden={},{}
 character,started=nil,nil
end
function Effect.start(model,clock,monsterFrame,monsterId)
 clear()
 if not model then return end
 character,started=model,clock
 for _,gui in ipairs(model:GetDescendants()) do if gui:IsA("BillboardGui") then local enabled=gui:GetAttribute("CrashEnabled") if enabled==nil then enabled=gui.Enabled end labels[gui]=enabled gui.Enabled=false end end
 local root=model:FindFirstChild("HumanoidRootPart")
 local center=root and root.Position or Vector3.zero
 local index=0
 for _,original in ipairs(model:GetDescendants()) do
  if not original:IsA("BasePart") then continue end
  hidden[original]=original.LocalTransparencyModifier
  original.LocalTransparencyModifier=1
  local alpha=original:GetAttribute("CrashAlpha") or original.Transparency
  if original.Name=="HumanoidRootPart" or alpha>=1 then continue end
  index+=1
  local archived=original.Archivable original.Archivable=true
  local shard=original:Clone() original.Archivable=archived
  for _,item in ipairs(shard:GetDescendants()) do
   if item:IsA("BillboardGui") or item:IsA("JointInstance") or item:IsA("Constraint") or item:IsA("LuaSourceContainer") or item:IsA("Attachment") or item:IsA("ParticleEmitter") or item:IsA("Sound") or item:IsA("Trail") or item:IsA("Beam") then item:Destroy() end
  end
  shard.Name="LocalCrashShard" shard.Anchored=true
  shard.LocalTransparencyModifier=0 shard.Transparency=alpha
  shard.CanCollide,shard.CanTouch,shard.CanQuery=false,false,false
  shard.Parent=workspace
  local direction=original.Position-center
  local radial=Vector3.new(direction.X,0,direction.Z)
  if radial.Magnitude<0.1 then radial=Vector3.new(math.cos(index*2.4),0,math.sin(index*2.4)) end
  local velocity=radial.Unit*12+Vector3.new(0,12+index%4,10)
  table.insert(shards,{part=shard,origin=shard.CFrame,velocity=velocity,alpha=alpha,spin=Vector3.new(index%3+1,1,index%2+1)})
 end
 if monsterFrame then
  local package=game.ReplicatedStorage.RodeoFantasy
  local species=require(package.MonsterCatalog)[monsterId or "MeadowMouse"]
  local template=package[species.Visual]:Clone()
  require(script.Parent.CreatureMesh).decorate(template)
  for _,original in ipairs(template:GetChildren()) do
   if not original:IsA("BasePart") or original==template.PrimaryPart or original.Transparency>=1 then continue end
   index+=1
   local shard=original:Clone()
   for _,item in ipairs(shard:GetDescendants()) do if not item:IsA("SpecialMesh") and not item:IsA("Decal") then item:Destroy() end end
   shard.Name="LocalMonsterCrashShard" shard.Anchored=true
   shard.CanCollide,shard.CanTouch,shard.CanQuery=false,false,false
   shard.CFrame=monsterFrame*template.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   shard.Parent=workspace
   local angle=index*2.4
   table.insert(shards,{part=shard,origin=shard.CFrame,velocity=Vector3.new(math.cos(angle)*14,9+index%5,math.sin(angle)*14+10),alpha=original.Transparency,spin=Vector3.new(1,index%3+1,1)})
  end
  template:Destroy()
 end
end
function Effect.update(model,phase,clock)
 if character and (model~=character or phase~="GameOver") then clear() end
 if not started then return end
 for gui in pairs(labels) do if gui.Parent then gui.Enabled=false end end
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
