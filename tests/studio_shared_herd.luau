local World=require(game.ServerScriptService.HuntWorld)
local cfg=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Rules=require(game.ReplicatedStorage.RodeoFantasy.HuntRules)
local View=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
World.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,cfg,Rules)
local minimum=1000 local maximum=0 local checks=0
local positions={}
for i=1,8 do positions[i]=-(i-1)*42 World.ensure(positions[i]) World.replenish(positions[i],1,nil,true) end
for tick=1,660 do
 if tick%10==0 then task.wait() end
 local watchers={}
 for i=1,8 do
  local speed=(tick%70<6 and i%2==0) and 96 or 64
  positions[i]-=speed*.1
  World.ensure(positions[i])
  table.insert(watchers,{z=positions[i],aspect=i%3==0 and .5625 or i%3==1 and 1 or 16/9})
 end
 World.step(.1)
 if tick%2==0 then World.maintain(watchers) end
 for _,watch in ipairs(watchers) do
  local count=0
  for _,model in ipairs(workspace.RodeoPrototype.Monsters:GetChildren()) do
   local p=model.PrimaryPart.Position
   if not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and View.visible(p.X,p.Y,p.Z-watch.z,watch.aspect,cfg.Prototype) then count+=1 end
  end
  minimum=math.min(minimum,count) checks+=1
  assert(count>=4,"SHARED_HERD_LOW tick="..tick.." z="..watch.z.." count="..count)
 end
 maximum=math.max(maximum,#workspace.RodeoPrototype.Monsters:GetChildren())
 local z={0} for _,watch in ipairs(watchers) do table.insert(z,watch.z) end
 World.cleanup(z)
end
print("SHARED_HERD_PASS: "..checks.." quotas; minimum="..minimum.." peak="..maximum)
