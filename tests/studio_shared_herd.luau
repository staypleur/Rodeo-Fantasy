local World=require(game.ServerScriptService.HuntWorld)
local cfg=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Rules=require(game.ReplicatedStorage.RodeoFantasy.HuntRules)
local View=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
World.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,cfg,Rules)
local minimum=1000 local maximum=0 local checks=0 local monsterSum,obstacleSum=0,0
local positions={}
local viewers={} for i=1,8 do viewers[i]={} end
for i=1,8 do positions[i]=-(i-1)*42 World.ensure(positions[i]) World.replenish(positions[i],1,nil,true) end
for tick=1,550 do

 local watchers={}
 for i=1,8 do
  local base=i%3==0 and 80 or i%3==1 and 76.8 or 64
  local speed=(tick%70<6 and i%2==0) and base*1.5 or base
  positions[i]-=speed*.1
  World.ensure(positions[i])
  table.insert(watchers,{viewer=viewers[i],z=positions[i],aspect=i%3==0 and .5625 or i%3==1 and 1 or 16/9})
 end
 World.step(.1)
 if tick%2==0 then World.maintain(watchers) end
 for _,watch in ipairs(watchers) do
  local count=0
  for _,model in ipairs(workspace.RodeoPrototype.Monsters:GetChildren()) do
   local p=model.PrimaryPart.Position
   if not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and View.visible(p.X,p.Y,p.Z-watch.z,watch.aspect,cfg.Prototype,1) then count+=1 end
  end
  monsterSum+=count
  for _,rock in ipairs(workspace.RodeoPrototype.Obstacles:GetChildren()) do
   if View.visible(rock.Position.X,2,rock.Position.Z-watch.z,watch.aspect,cfg.Prototype) then obstacleSum+=1 end
  end
  local shown=0 for model in pairs(World.visibleSet(watch.z,watch.aspect,watch.viewer)) do
   shown+=1 local p=model.PrimaryPart.Position assert(View.visible(p.X,p.Y,p.Z-watch.z,watch.aspect,cfg.Prototype,1),"selected animal must remain inside full camera")
  end
  assert(shown>=4 and shown<=6,"displayed shared wild herd tick="..tick.." z="..watch.z.." shown="..shown.." raw="..count)
  minimum=math.min(minimum,count) checks+=1
  assert(count>=4,"SHARED_HERD_LOW tick="..tick.." z="..watch.z.." count="..count)
 end
 maximum=math.max(maximum,#workspace.RodeoPrototype.Monsters:GetChildren())
 local z={0} for _,watch in ipairs(watchers) do table.insert(z,watch.z) end
 World.cleanup(z)
end
print("SHARED_HERD_PASS: "..checks.." quotas; minimum="..minimum.." peak="..maximum.." visible average="..monsterSum/checks.." obstacles="..obstacleSum/checks)
