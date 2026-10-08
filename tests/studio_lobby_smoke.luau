local Lobby=require(game.ServerScriptService.LobbyWorld)
local plots=workspace.RodeoLobby.Plots
local pens=0
for _,plot in ipairs(plots:GetChildren()) do
 assert(#plot.Pens:GetChildren()==4)
 assert(plot.OwnerBoard.Position.Y==10,"owner name must be on a high ranch sign")
 assert(math.abs((plot.GardenPad.Position-Vector3.new(6000,.12,0)).Magnitude-108)<.01,"eight private regions must surround the central plaza")
 local left,right=0,0
 for _,pen in ipairs(plot.Pens:GetChildren()) do
  local x=plot.GardenPad.CFrame:PointToObjectSpace(pen.PenGrass.Position).X
  if x<0 then left+=1 else right+=1 end
 end
 assert(left==2 and right==2,"each private path has two pens per side")
 for _,pen in ipairs(plot.Pens:GetChildren()) do assert(pen:GetAttribute("Capacity")==2) pens+=1 end
end
assert(#plots:GetChildren()==8 and pens==32)
assert(workspace.RodeoLobby.Airport.Airship.WalrusBody.Shape==Enum.PartType.Ball)
assert(#workspace.RodeoLobby.Boundary:GetChildren()==8)
local people={}
for i=1,9 do
 people[i]={UserId=i,DisplayName="검사 "..i,SetAttribute=function() end}
 local slot=Lobby.assign(people[i])
 assert(slot==(i<=8 and i or nil),"only eight players can own lobby plots")
end
Lobby.release(people[3])
assert(Lobby.assign(people[9])==3,"leaving player must free the plot")
for _,person in ipairs(people) do Lobby.release(person) end
print("LOBBY_MAP_SLOTS_PASS: 8 plots, 32 pens, rounded buildings and capacity/release")

local World=require(game.ServerScriptService.HuntWorld)
local cfg=require(game.ReplicatedStorage.RodeoFantasy.Config)
local rules=require(game.ReplicatedStorage.RodeoFantasy.HuntRules)
local View=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
World.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,cfg,rules)
for _,aspect in ipairs({0.5625,1,16/9}) do
 local viewer={}
 workspace.RodeoPrototype.Monsters:ClearAllChildren()
 for tick=1,750 do

  local z=-tick*6.4
  World.ensure(z)
  if tick==1 then World.replenish(z,aspect,nil,true) end
  World.step(0.1) World.maintain({{z=z,aspect=aspect}})
  local count=0
  for model in pairs(World.visibleSet(z,aspect,viewer)) do
   local p=model.PrimaryPart.Position
   if View.visible(p.X,p.Y,p.Z-z,aspect,cfg.Prototype,1) then count+=1 end
  end
  assert(count>=4 and count<=6,"visible herd aspect="..aspect.." tick="..tick.." z="..z.." count="..count)
  World.cleanup({z})
 end
end
print("CONTINUOUS_VISIBLE_HERD_PASS: four to six across 75 seconds (the full 1,000m course) and three screen ratios")
