local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,4,0)
function Lobby.prepareCharacter(character)
 if not character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",2) end
end
local function label(index,name)
 local board=plots["Plot_"..index].OwnerBoard
 for _,gui in ipairs(board:GetChildren()) do
  if gui:IsA("SurfaceGui") then gui.Text.Text=name end
 end
end
function Lobby.assign(player)
 if owned[player] then return owned[player] end
 for index=1,8 do
  if not occupants[index] then
   occupants[index]=player owned[player]=index
   plots["Plot_"..index]:SetAttribute("OwnerUserId",player.UserId)
   player:SetAttribute("LobbySlot",index)
   label(index,player.Name or player.DisplayName or "Player")
   return index
  end
 end
 return nil
end
function Lobby.release(player)
 local index=owned[player]
 if not index then return end
 occupants[index]=nil owned[player]=nil
 player:SetAttribute("LobbySlot",nil)
 plots["Plot_"..index]:SetAttribute("OwnerUserId",nil)
 for _,pen in ipairs(plots["Plot_"..index].Pens:GetChildren()) do
  local display=pen:FindFirstChild("DisplayMonsters") if display then display:Destroy() end
 end
 label(index," ")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=16
end
function Lobby.getPen(player,index)
 if type(index)~="number" or index~=index or index%1~=0 or index<1 or index>4 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=16
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
local roaming={}
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 local old=pen:FindFirstChild("DisplayMonsters") if old then old:Destroy() end
 local folder=Instance.new("Folder") folder.Name="DisplayMonsters" folder.Parent=pen
 local slot=0
 for _,item in ipairs(items) do
  if item.assignedPen==index then
   slot+=1
   local species=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)[item.monsterId]
   local model=game.ServerStorage[require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog).template(item.monsterId,item.stars)]:Clone()
   model.Name="Pet_"..item.id model:SetAttribute("BagItemId",item.id)
   model:SetAttribute("Running",true)
   model:SetAttribute("MonsterId",item.monsterId) model:SetAttribute("Stars",item.stars) model:SetAttribute("Flying",species.Flying)
   model:SetAttribute("RunStarted",workspace:GetServerTimeNow())
   for _,node in ipairs(model:GetDescendants()) do if node:IsA("BillboardGui") then node:Destroy() end end
   local catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
   local stage=catalog.stage(item.stars)
   local scale=catalog.scale(item.stars)
   model:ScaleTo(scale/catalog.Scales[stage])
   local height=species.Flying and 3*scale or species.RootHeight*scale
   local boxFrame,boxSize=model:GetBoundingBox()
   local offset=model.PrimaryPart.CFrame:ToObjectSpace(boxFrame).Position
   local margin=boxSize/2+Vector3.new(math.abs(offset.X)+.2,0,math.abs(offset.Z)+.2)
   local startX=math.clamp(slot==1 and -3 or 3,-math.max(0,pen.PenGrass.Size.X/2-margin.X),math.max(0,pen.PenGrass.Size.X/2-margin.X))
   local target=pen.PenGrass.CFrame*CFrame.new(startX,height+pen.PenGrass.Size.Y/2,0)
   model:PivotTo(target*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
   model.Parent=folder
   height+=pen.PenGrass.Size.Y/2
   roaming[model]={pen=pen,height=height,margin=margin,position=Vector3.new(startX,height,0),goal=Vector3.new(startX,height,0),pause=0,seed=Random.new(item.id+player.UserId)}
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="Manage ranch" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
local roamClock=0
game:GetService("RunService").Heartbeat:Connect(function(dt)
 roamClock+=dt if roamClock<.1 then return end local step=math.min(roamClock,.2) roamClock=0
 for model,motion in pairs(roaming) do
  if not model.Parent then roaming[model]=nil continue end
  local delta=motion.goal-motion.position
  if delta.Magnitude<.1 then
   model:SetAttribute("Running",false) motion.pause-=step
   if motion.pause<=0 then
    local size=motion.pen.PenGrass.Size
    local x=math.max(.1,size.X/2-motion.margin.X) local z=math.max(.1,size.Z/2-motion.margin.Z)
    motion.goal=Vector3.new(motion.seed:NextNumber(-x,x),motion.height,motion.seed:NextNumber(-z,z))
    motion.pause=motion.seed:NextNumber(.8,2.2)
   end
  else
   model:SetAttribute("Running",true)
   motion.position+=delta.Unit*math.min(delta.Magnitude,step*2.5)
   local localFrame=CFrame.lookAt(motion.position,motion.position+delta.Unit)
   model.PrimaryPart.CFrame=motion.pen.PenGrass.CFrame*localFrame
   model:SetAttribute("HerdVelocity",motion.pen.PenGrass.CFrame:VectorToWorldSpace(delta.Unit*2.5))
  end
 end
end)
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="Fly to hunt" prompt.ObjectText="Airship"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
