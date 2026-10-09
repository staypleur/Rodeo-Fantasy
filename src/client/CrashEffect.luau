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
-- Independent wild-monster shards never alter bag entries or avatar crash state.
local knockShards={}
local knocked=setmetatable({},{__mode="k"})
local MAX_KNOCK_SHARDS=96
function Effect.knock(model,clock)
 if knocked[model] or not model.PrimaryPart then return 0 end
 knocked[model]=true
 local root=model.PrimaryPart
 local started=model:GetAttribute("KnockedAt") or clock
 if clock-started>1.1 then return 0 end
 local direction=model:GetAttribute("KnockDirection") or 1
 require(script.Parent.CreatureMesh).materialize(model)
 local parts={}
 for _,part in ipairs(model:GetChildren()) do
  if part:IsA("BasePart") and part~=root and part.Transparency<1 then table.insert(parts,part) end
 end
 -- Keep large recognisable pieces before tiny details when the budget is full.
 table.sort(parts,function(a,b) return a.Size.X*a.Size.Y*a.Size.Z>b.Size.X*b.Size.Y*b.Size.Z end)
 local made=0
 for index,original in ipairs(parts) do
  original.LocalTransparencyModifier=1
  if made>=32 then continue end
  if #knockShards>=MAX_KNOCK_SHARDS then
   knockShards[1].part:Destroy() table.remove(knockShards,1)
  end
  local archived=original.Archivable original.Archivable=true
  local shard=original:Clone() original.Archivable=archived
  for _,child in ipairs(shard:GetChildren()) do
   if not child:IsA("SpecialMesh") and not child:IsA("SurfaceAppearance") and not child:IsA("Decal") and not child:IsA("Texture") then child:Destroy() end
  end
  shard.Name="LocalKnockShard" shard.Anchored=true shard.LocalTransparencyModifier=0
  shard.CanCollide,shard.CanTouch,shard.CanQuery=false,false,false
  shard.Parent=workspace
  local angle=index*2.4
  local velocity=Vector3.new(direction*18+math.cos(angle)*11,12+index%5,-14+math.sin(angle)*9)
  table.insert(knockShards,{part=shard,origin=shard.CFrame,velocity=velocity,started=started,
   alpha=shard.Transparency,spin=Vector3.new(index%3+1,direction,index%2+1),world=model.Parent,
   floor=root.Position.Y-root.Size.Y/2})
  made+=1
 end
 local outline=model:FindFirstChild("LocalCreatureOutline") if outline then outline.Enabled=false end
 return made
end
function Effect.updateKnocks(clock,world)
 for i=#knockShards,1,-1 do
  local entry=knockShards[i] local elapsed=math.max(0,clock-entry.started)
  if elapsed>=1.1 or not world or entry.world~=world then
   entry.part:Destroy() table.remove(knockShards,i)
  else
   local position=entry.origin.Position+entry.velocity*elapsed+Vector3.new(0,-24*elapsed*elapsed,0)
   position=Vector3.new(position.X,math.max(entry.floor+.15,position.Y),position.Z)
   local spin=entry.spin*elapsed*5
   entry.part.CFrame=CFrame.new(position)*entry.origin.Rotation*CFrame.Angles(spin.X,spin.Y,spin.Z)
   entry.part.Transparency=entry.alpha+(1-entry.alpha)*math.clamp((elapsed-.65)/.45,0,1)
  end
 end
end
function Effect.clear() clear() Effect.updateKnocks(0,nil) end
return Effect
