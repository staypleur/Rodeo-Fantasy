local Lobby=require(game.ServerScriptService.LobbyWorld)
local plots=workspace.RodeoLobby.Plots
local pens=0
for _,plot in ipairs(plots:GetChildren()) do
 assert(#plot.Pens:GetChildren()==8)
 for _,pen in ipairs(plot.Pens:GetChildren()) do assert(pen:GetAttribute("Capacity")==2) pens+=1 end
end
assert(#plots:GetChildren()==8 and pens==64)
assert(workspace.RodeoLobby.Airport.PastelPlane.Fuselage.Shape==Enum.PartType.Cylinder)
assert(workspace.RodeoLobby.Shops.Shop_1.RoundWall.Shape==Enum.PartType.Cylinder)
local people={}
for i=1,9 do
 people[i]={UserId=i,DisplayName="검사 "..i,SetAttribute=function() end}
 local slot=Lobby.assign(people[i])
 assert(slot==(i<=8 and i or nil),"only eight players can own lobby plots")
end
Lobby.release(people[3])
assert(Lobby.assign(people[9])==3,"leaving player must free the plot")
for _,person in ipairs(people) do Lobby.release(person) end
print("LOBBY_MAP_SLOTS_PASS: 8 plots, 64 pens, rounded buildings and capacity/release")

local World=require(game.ServerScriptService.HuntWorld)
local cfg=require(game.ReplicatedStorage.RodeoFantasy.Config)
local rules=require(game.ReplicatedStorage.RodeoFantasy.HuntRules)
local View=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
World.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,cfg,rules)
for _,aspect in ipairs({0.5625,1,16/9}) do
 workspace.RodeoPrototype.Monsters:ClearAllChildren()
 for tick=1,750 do
  local z=-tick*6.4
  World.ensure(z) World.step(0.1) World.replenish(z,aspect)
  local count=0
  for _,model in ipairs(workspace.RodeoPrototype.Monsters:GetChildren()) do
   local p=model.PrimaryPart.Position
   if View.visible(p.X,p.Y,p.Z-z,aspect,cfg.Prototype) then count+=1 end
  end
  assert(count>=4,"running/restarting camera window must retain four visible animals")
  World.cleanup({z})
 end
end
print("CONTINUOUS_VISIBLE_HERD_PASS: minimum four across 75 seconds (the full 1,000m course) and three screen ratios")
