assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"RodeoLobby 없음")
local shared=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"시스템 없음")
local server=game:GetService("ServerScriptService")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local changes={{parent=server,name="LobbyWorld",kind="ModuleScript",new=false,after=[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,14,-72)
local departureRadius=38
local function centerDeparture()
 local rocket=map.Airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then
  local box=rocket:GetBoundingBox()
  Lobby.Departure.Position=Vector3.new(box.Position.X,Lobby.Departure.Position.Y,box.Position.Z)
 end
 Lobby.Departure.Transparency=1
 Lobby.Departure.CanCollide=false
end
centerDeparture()
function Lobby.prepareCharacter(character)
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",10)
 if root then character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
 local head=character:FindFirstChild("Head") or character:WaitForChild("Head",10)
 if head and not character:FindFirstChild("AstronautHelmet") then
  local helmet=Instance.new("Accessory") helmet.Name="AstronautHelmet"
  local bubble=Instance.new("Part") bubble.Name="Handle" bubble.Shape=Enum.PartType.Ball
  bubble.Size=Vector3.one*math.max(2.8,head.Size.Magnitude*1.5)
  bubble.Material=Enum.Material.Glass bubble.Color=Color3.fromRGB(196,232,245) bubble.Transparency=.78
  bubble.CanCollide=false bubble.CanTouch=false bubble.CanQuery=false bubble.Massless=true bubble.CastShadow=false
  bubble.CFrame=head.CFrame bubble.Parent=helmet
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=bubble weld.Parent=bubble
  helmet.Parent=character
 end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
end
local function label(index,name)
 local board=plots["Plot_"..index].OwnerBoard
 for _,gui in ipairs(board:GetChildren()) do
  if gui:IsA("SurfaceGui") then gui.Text.Text=name end
 end
end
for index=1,8 do label(index,"") end
function Lobby.assign(player)
 if owned[player] then return owned[player] end
 for index=1,8 do
  if not occupants[index] then
   occupants[index]=player owned[player]=index
   plots["Plot_"..index]:SetAttribute("OwnerUserId",player.UserId)
   player:SetAttribute("LobbySlot",index)
   label(index,player.DisplayName or player.Name)
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
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=departureRadius
end
function Lobby.getPen(player,index)
 if index~=1 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=departureRadius prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========],allowed={[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,14,-72)
local departureRadius=38
local function centerDeparture()
 local rocket=map.Airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then
  local box=rocket:GetBoundingBox()
  Lobby.Departure.Position=Vector3.new(box.Position.X,Lobby.Departure.Position.Y,box.Position.Z)
 end
 Lobby.Departure.Transparency=1
 Lobby.Departure.CanCollide=false
end
centerDeparture()
function Lobby.prepareCharacter(character)
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",10)
 if root then character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
 local head=character:FindFirstChild("Head") or character:WaitForChild("Head",10)
 if head and not character:FindFirstChild("AstronautHelmet") then
  local helmet=Instance.new("Accessory") helmet.Name="AstronautHelmet"
  local bubble=Instance.new("Part") bubble.Name="Handle" bubble.Shape=Enum.PartType.Ball
  bubble.Size=Vector3.one*math.max(2.8,head.Size.Magnitude*1.5)
  bubble.Material=Enum.Material.Glass bubble.Color=Color3.fromRGB(196,232,245) bubble.Transparency=.78
  bubble.CanCollide=false bubble.CanTouch=false bubble.CanQuery=false bubble.Massless=true bubble.CastShadow=false
  bubble.CFrame=head.CFrame bubble.Parent=helmet
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=bubble weld.Parent=bubble
  helmet.Parent=character
 end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
end
local function label(index,name)
 local board=plots["Plot_"..index].OwnerBoard
 for _,gui in ipairs(board:GetChildren()) do
  if gui:IsA("SurfaceGui") then gui.Text.Text=name end
 end
end
for index=1,8 do label(index,"") end
function Lobby.assign(player)
 if owned[player] then return owned[player] end
 for index=1,8 do
  if not occupants[index] then
   occupants[index]=player owned[player]=index
   plots["Plot_"..index]:SetAttribute("OwnerUserId",player.UserId)
   player:SetAttribute("LobbySlot",index)
   label(index,player.DisplayName or player.Name)
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
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=departureRadius
end
function Lobby.getPen(player,index)
 if index~=1 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=departureRadius prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========],[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,4,-72)
function Lobby.prepareCharacter(character)
 if not character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
 local head=character:FindFirstChild("Head") or character:WaitForChild("Head",10)
 if head and not character:FindFirstChild("AstronautHelmet") then
  local helmet=Instance.new("Accessory") helmet.Name="AstronautHelmet"
  local bubble=Instance.new("Part") bubble.Name="Handle" bubble.Shape=Enum.PartType.Ball
  bubble.Size=Vector3.one*math.max(2.8,head.Size.Magnitude*1.5)
  bubble.Material=Enum.Material.Glass bubble.Color=Color3.fromRGB(196,232,245) bubble.Transparency=.78
  bubble.CanCollide=false bubble.CanTouch=false bubble.CanQuery=false bubble.Massless=true bubble.CastShadow=false
  bubble.CFrame=head.CFrame bubble.Parent=helmet
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=bubble weld.Parent=bubble
  helmet.Parent=character
 end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
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
   label(index,(player.DisplayName or player.Name).."\n@"..player.Name.." · 알 부화실")
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
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"빈 부화실")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=16
end
function Lobby.getPen(player,index)
 if index~=1 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========],[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,4,-72)
function Lobby.prepareCharacter(character)
 if not character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
 local head=character:FindFirstChild("Head") or character:WaitForChild("Head",10)
 if head and not character:FindFirstChild("AstronautHelmet") then
  local helmet=Instance.new("Accessory") helmet.Name="AstronautHelmet"
  local bubble=Instance.new("Part") bubble.Name="Handle" bubble.Shape=Enum.PartType.Ball
  bubble.Size=Vector3.one*math.max(2.8,head.Size.Magnitude*1.5)
  bubble.Material=Enum.Material.Glass bubble.Color=Color3.fromRGB(196,232,245) bubble.Transparency=.78
  bubble.CanCollide=false bubble.CanTouch=false bubble.CanQuery=false bubble.Massless=true bubble.CastShadow=false
  bubble.CFrame=head.CFrame bubble.Parent=helmet
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=bubble weld.Parent=bubble
  helmet.Parent=character
 end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
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
   label(index,(player.DisplayName or player.Name).."\n@"..player.Name.." · 알 부화실")
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
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"빈 부화실")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=16
end
function Lobby.getPen(player,index)
 if index~=1 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========],[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,4,-72)
function Lobby.prepareCharacter(character)
 if not character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
 local head=character:FindFirstChild("Head") or character:WaitForChild("Head",10)
 if head and not character:FindFirstChild("AstronautHelmet") then
  local helmet=Instance.new("Accessory") helmet.Name="AstronautHelmet"
  local bubble=Instance.new("Part") bubble.Name="Handle" bubble.Shape=Enum.PartType.Ball
  bubble.Size=Vector3.one*math.max(2.8,head.Size.Magnitude*1.5)
  bubble.Material=Enum.Material.Glass bubble.Color=Color3.fromRGB(196,232,245) bubble.Transparency=.78
  bubble.CanCollide=false bubble.CanTouch=false bubble.CanQuery=false bubble.Massless=true bubble.CastShadow=false
  bubble.CFrame=head.CFrame bubble.Parent=helmet
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=bubble weld.Parent=bubble
  helmet.Parent=character
 end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
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
   label(index,(player.DisplayName or player.Name).."\n@"..player.Name.." · 알 부화실")
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
 label(index,"빈 부화실")
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
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========],[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,4,-72)
function Lobby.prepareCharacter(character)
 if not character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
 local head=character:FindFirstChild("Head") or character:WaitForChild("Head",10)
 if head and not character:FindFirstChild("AstronautHelmet") then
  local helmet=Instance.new("Accessory") helmet.Name="AstronautHelmet"
  local bubble=Instance.new("Part") bubble.Name="Handle" bubble.Shape=Enum.PartType.Ball
  bubble.Size=Vector3.one*math.max(2.8,head.Size.Magnitude*1.5)
  bubble.Material=Enum.Material.Glass bubble.Color=Color3.fromRGB(196,232,245) bubble.Transparency=.78
  bubble.CanCollide=false bubble.CanTouch=false bubble.CanQuery=false bubble.Massless=true bubble.CastShadow=false
  bubble.CFrame=head.CFrame bubble.Parent=helmet
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=bubble weld.Parent=bubble
  helmet.Parent=character
 end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
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
   label(index,(player.DisplayName or player.Name).."\n@"..player.Name.." · 알 부화실")
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
 label(index,"빈 부화실")
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
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========]}},{parent=server,name="CaptureServer",kind="Script",new=false,after=[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canManage(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0)
 local wildIds={}
 if state then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 model:SetAttribute("StartingOwnedMount",true)
 model:SetAttribute("Tamed_"..player.UserId,true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}}) end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if (not state or state.phase=="GameOver" or state.phase=="CourseEnd") and not player:GetAttribute("ReturningLobby") then
   player:SetAttribute("ReturningLobby",true)
   restoreAvatar(state)
   states[player]=nil
   if worldRoots[player] then worldRoots[player]:Destroy() end
   worlds[player],worldRoots[player]=nil,nil
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not humanoid or humanoid.Health<=0 then
    local ok,err=pcall(function() player:LoadCharacterAsync() end)
    if not ok then states[player]=state player:SetAttribute("ReturningLobby",nil) warn("LOBBY_RESPAWN_FAILED: "..tostring(err)) send(player,"다시 로비로 돌아가기를 눌러 주세요.") return end
    character=player.Character
   end
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then root.Anchored=false root.AssemblyLinearVelocity=Vector3.zero character:PivotTo(Lobby.Spawn) end
   humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.PlatformStand=false humanoid.AutoRotate=true end
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(character)
   player:SetAttribute("ReturningLobby",nil)
   send(player,"로비로 돌아왔습니다.") sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or clock
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if not state.tamed and clock-state.started>=Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
    state.angerAt=state.angerAt or clock
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 Lobby.display(player,1,bag.eggs or {})
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========],allowed={[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canManage(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0)
 local wildIds={}
 if state then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 model:SetAttribute("StartingOwnedMount",true)
 model:SetAttribute("Tamed_"..player.UserId,true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}}) end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if (not state or state.phase=="GameOver" or state.phase=="CourseEnd") and not player:GetAttribute("ReturningLobby") then
   player:SetAttribute("ReturningLobby",true)
   restoreAvatar(state)
   states[player]=nil
   if worldRoots[player] then worldRoots[player]:Destroy() end
   worlds[player],worldRoots[player]=nil,nil
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not humanoid or humanoid.Health<=0 then
    local ok,err=pcall(function() player:LoadCharacterAsync() end)
    if not ok then states[player]=state player:SetAttribute("ReturningLobby",nil) warn("LOBBY_RESPAWN_FAILED: "..tostring(err)) send(player,"다시 로비로 돌아가기를 눌러 주세요.") return end
    character=player.Character
   end
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then root.Anchored=false root.AssemblyLinearVelocity=Vector3.zero character:PivotTo(Lobby.Spawn) end
   humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.PlatformStand=false humanoid.AutoRotate=true end
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(character)
   player:SetAttribute("ReturningLobby",nil)
   send(player,"로비로 돌아왔습니다.") sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or clock
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if not state.tamed and clock-state.started>=Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
    state.angerAt=state.angerAt or clock
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 Lobby.display(player,1,bag.eggs or {})
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canManage(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0)
 local wildIds={}
 if state then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=false}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}}) end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if state and (state.phase=="GameOver" or state.phase=="CourseEnd") then
   finish(player,"Welcome back to the lobby.")
   restoreAvatar(state)
   state.root.CFrame=Lobby.Spawn
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(player.Character)
   states[player]=nil send(player) sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or clock
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if not state.tamed and clock-state.started>=Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
    state.angerAt=state.angerAt or clock
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 Lobby.display(player,1,bag.eggs or {})
 player.CharacterRemoving:Connect(function() companions.clear(player) finish(player,"Hunt ended") states[player]=nil end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canManage(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0)
 local wildIds={}
 if state then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=false}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}}) end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if state and (state.phase=="GameOver" or state.phase=="CourseEnd") then
   finish(player,"Welcome back to the lobby.")
   restoreAvatar(state)
   state.root.CFrame=Lobby.Spawn
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(player.Character)
   states[player]=nil send(player) sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or clock
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if not state.tamed and clock-state.started>=Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
    state.angerAt=state.angerAt or clock
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 Lobby.display(player,1,bag.eggs or {})
 player.CharacterRemoving:Connect(function() companions.clear(player) finish(player,"Hunt ended") states[player]=nil end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canManage(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0)
 local wildIds={}
 if state then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=false}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}}) end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if state and (state.phase=="GameOver" or state.phase=="CourseEnd") then
   finish(player,"Welcome back to the lobby.")
   restoreAvatar(state)
   state.root.CFrame=Lobby.Spawn
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(player.Character)
   states[player]=nil send(player) sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or clock
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if not state.tamed and clock-state.started>=Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
    state.angerAt=state.angerAt or clock
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 for pen=1,4 do Lobby.display(player,pen,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function() companions.clear(player) finish(player,"Hunt ended") states[player]=nil end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canManage(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0)
 local wildIds={}
 if state then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=false}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}}) end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if state and (state.phase=="GameOver" or state.phase=="CourseEnd") then
   finish(player,"Welcome back to the lobby.")
   restoreAvatar(state)
   state.root.CFrame=Lobby.Spawn
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(player.Character)
   states[player]=nil send(player) sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or clock
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if not state.tamed and clock-state.started>=Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
    state.angerAt=state.angerAt or clock
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 for pen=1,4 do Lobby.display(player,pen,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function() companions.clear(player) finish(player,"Hunt ended") states[player]=nil end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========]}},{parent=clients,name="NativeMossrat",kind="ModuleScript",new=false,after=[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],allowed={[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========]}},{parent=clients,name="UserMossratRigAnimator",kind="ModuleScript",new=false,after=[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],allowed={[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========]}},{parent=server,name="LobbyPresentation",kind="Script",new=true,after=[========[-- Applies the requested smooth surfaces to the installed lobby only.
local lobby=workspace:WaitForChild("RodeoLobby")
local roof=lobby:FindFirstChild("Roof") or Instance.new("Model")
roof.Name="Roof" roof.Parent=lobby
if not roof:FindFirstChild("FullOpaqueCeiling") then
 local cap=Instance.new("Part") cap.Name="FullOpaqueCeiling"
 cap.Size=Vector3.new(512,8,512) cap.Position=Vector3.new(6000,102,0)
 cap.Anchored=true cap.CanTouch=false cap.Material=Enum.Material.SmoothPlastic
 cap.Color=Color3.fromRGB(25,35,57) cap.Parent=roof
end
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("Part") then
  part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth
  part.FrontSurface=Enum.SurfaceType.Smooth part.BackSurface=Enum.SurfaceType.Smooth
  part.LeftSurface=Enum.SurfaceType.Smooth part.RightSurface=Enum.SurfaceType.Smooth
  if part.Material==Enum.Material.Plastic then part.Material=Enum.Material.SmoothPlastic end
 end
end
]========],allowed={[========[-- Applies the requested smooth surfaces to the installed lobby only.
local lobby=workspace:WaitForChild("RodeoLobby")
local roof=lobby:FindFirstChild("Roof") or Instance.new("Model")
roof.Name="Roof" roof.Parent=lobby
if not roof:FindFirstChild("FullOpaqueCeiling") then
 local cap=Instance.new("Part") cap.Name="FullOpaqueCeiling"
 cap.Size=Vector3.new(512,8,512) cap.Position=Vector3.new(6000,102,0)
 cap.Anchored=true cap.CanTouch=false cap.Material=Enum.Material.SmoothPlastic
 cap.Color=Color3.fromRGB(25,35,57) cap.Parent=roof
end
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("Part") then
  part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth
  part.FrontSurface=Enum.SurfaceType.Smooth part.BackSurface=Enum.SurfaceType.Smooth
  part.LeftSurface=Enum.SurfaceType.Smooth part.RightSurface=Enum.SurfaceType.Smooth
  if part.Material==Enum.Material.Plastic then part.Material=Enum.Material.SmoothPlastic end
 end
end
]========]}},{parent=server,name="LobbyRankings",kind="ModuleScript",new=true,after=[========[local M={}
function M.ensure(lobby)
 local boards=lobby:FindFirstChild("Leaderboards")
 if not boards then boards=Instance.new("Folder") boards.Name="Leaderboards" boards.Parent=lobby end
 local center=Vector3.new(6000,0,0)
 local airport=lobby:FindFirstChild("Airport")
 local rocket=airport and airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then local cf=rocket:GetBoundingBox() center=Vector3.new(cf.X,0,cf.Z) end
 for i,entry in ipairs({{"Distance","최고 거리"},{"Income","도감 수집"}}) do
  local board=boards:FindFirstChild(entry[1])
  if not board then
   board=Instance.new("Part") board.Name=entry[1] board.Size=Vector3.new(26,30,2)
   board.Anchored=true board.Material=Enum.Material.SmoothPlastic board.Color=Color3.fromRGB(24,38,64)
   board.TopSurface=Enum.SurfaceType.Smooth board.BottomSurface=Enum.SurfaceType.Smooth board.Parent=boards
  end
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,23,-16))
  if board:IsA("BasePart") then board.CFrame=target elseif board:IsA("Model") then board:PivotTo(target) end
  local gui=board:FindFirstChild("Ranking")
  if not gui then
   gui=Instance.new("SurfaceGui") gui.Name="Ranking" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(780,900) gui.Parent=board
   for _,spec in ipairs({{"Heading",0,120,entry[2],52},{"Entries",140,740,"기록을 불러오는 중입니다.",34}}) do
    local text=Instance.new("TextLabel") text.Name=spec[1] text.Position=UDim2.fromOffset(24,spec[2]) text.Size=UDim2.new(1,-48,0,spec[3])
    text.Text=spec[4] text.TextSize=spec[5] text.TextWrapped=true text.Font=Enum.Font.GothamBold text.BackgroundTransparency=1
    text.TextColor3=spec[1]=="Heading" and Color3.fromRGB(126,219,255) or Color3.fromRGB(229,240,255)
    text.TextYAlignment=Enum.TextYAlignment.Top text.Parent=gui
   end
  end
 end
 return boards
end
return M
]========],allowed={[========[local M={}
function M.ensure(lobby)
 local boards=lobby:FindFirstChild("Leaderboards")
 if not boards then boards=Instance.new("Folder") boards.Name="Leaderboards" boards.Parent=lobby end
 local center=Vector3.new(6000,0,0)
 local airport=lobby:FindFirstChild("Airport")
 local rocket=airport and airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then local cf=rocket:GetBoundingBox() center=Vector3.new(cf.X,0,cf.Z) end
 for i,entry in ipairs({{"Distance","최고 거리"},{"Income","도감 수집"}}) do
  local board=boards:FindFirstChild(entry[1])
  if not board then
   board=Instance.new("Part") board.Name=entry[1] board.Size=Vector3.new(26,30,2)
   board.Anchored=true board.Material=Enum.Material.SmoothPlastic board.Color=Color3.fromRGB(24,38,64)
   board.TopSurface=Enum.SurfaceType.Smooth board.BottomSurface=Enum.SurfaceType.Smooth board.Parent=boards
  end
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,23,-16))
  if board:IsA("BasePart") then board.CFrame=target elseif board:IsA("Model") then board:PivotTo(target) end
  local gui=board:FindFirstChild("Ranking")
  if not gui then
   gui=Instance.new("SurfaceGui") gui.Name="Ranking" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(780,900) gui.Parent=board
   for _,spec in ipairs({{"Heading",0,120,entry[2],52},{"Entries",140,740,"기록을 불러오는 중입니다.",34}}) do
    local text=Instance.new("TextLabel") text.Name=spec[1] text.Position=UDim2.fromOffset(24,spec[2]) text.Size=UDim2.new(1,-48,0,spec[3])
    text.Text=spec[4] text.TextSize=spec[5] text.TextWrapped=true text.Font=Enum.Font.GothamBold text.BackgroundTransparency=1
    text.TextColor3=spec[1]=="Heading" and Color3.fromRGB(126,219,255) or Color3.fromRGB(229,240,255)
    text.TextYAlignment=Enum.TextYAlignment.Top text.Parent=gui
   end
  end
 end
 return boards
end
return M
]========]}},{parent=server,name="RecordService",kind="ModuleScript",new=false,after=[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters)
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>entry.distance
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.merge(old,entry.id,produced,best,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   distance:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.distance) end)
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=require(script.Parent.LobbyRankings).ensure(workspace.RodeoLobby)
 boards.Income.Ranking.Heading.Text="도감 수집"
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========],allowed={[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters)
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>entry.distance
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.merge(old,entry.id,produced,best,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   distance:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.distance) end)
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=require(script.Parent.LobbyRankings).ensure(workspace.RodeoLobby)
 boards.Income.Ranking.Heading.Text="도감 수집"
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========],[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters)
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>entry.distance
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.merge(old,entry.id,produced,best,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   distance:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.distance) end)
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=workspace.RodeoLobby.Leaderboards
 boards.Income.Ranking.Heading.Text="Collection discoveries"
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========],[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters)
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>entry.distance
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.merge(old,entry.id,produced,best,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   distance:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.distance) end)
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=workspace.RodeoLobby.Leaderboards
 boards.Income.Ranking.Heading.Text="Collection discoveries"
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========],[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters)
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>entry.distance
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.merge(old,entry.id,produced,best,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   distance:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.distance) end)
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=workspace.RodeoLobby.Leaderboards
 boards.Income.Ranking.Heading.Text="Collection discoveries"
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========],[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters)
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>entry.distance
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.merge(old,entry.id,produced,best,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   distance:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.distance) end)
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=workspace.RodeoLobby.Leaderboards
 boards.Income.Ranking.Heading.Text="Collection discoveries"
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========]}},{parent=clients,name="LobbyMenus",kind="ModuleScript",new=true,after=[========[-- Lobby entries only; products, odds and rewards remain undecided.
local M={}
function M.new(gui)
 local api={}
 local function make(kind,props,parent)
  local n=Instance.new(kind) for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
 end
 local panel=make("Frame",{Name="LobbyMenus",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.9,.65),BackgroundColor3=Color3.fromRGB(23,35,58),BorderSizePixel=0,ZIndex=30},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(520,330)},panel)
 make("UICorner",{CornerRadius=UDim.new(0,16)},panel)
 make("UIStroke",{Color=Color3.fromRGB(98,202,255),Thickness=2},panel)
 make("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(47,66,105),Color3.fromRGB(17,25,45)),Rotation=90},panel)
 local title=make("TextLabel",{Size=UDim2.new(1,-88,0,56),Position=UDim2.fromOffset(20,8),BackgroundTransparency=1,Text="",TextSize=26,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(232,245,255),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=31},panel)
 local body=make("TextLabel",{Size=UDim2.new(1,-40,1,-90),Position=UDim2.fromOffset(20,76),BackgroundTransparency=1,Text="",TextSize=20,TextWrapped=true,Font=Enum.Font.Gotham,TextColor3=Color3.fromRGB(205,223,245),ZIndex=31},panel)
 local close=make("TextButton",{Name="Close",Text="×",TextSize=30,Size=UDim2.fromOffset(48,48),Position=UDim2.new(1,-56,0,8),BackgroundColor3=Color3.fromRGB(49,69,99),TextColor3=Color3.new(1,1,1),ZIndex=31},panel)
 make("UICorner",{CornerRadius=UDim.new(0,10)},close)
 function api.close() panel.Visible=false end
 close.Activated:Connect(api.close)
 local buttons={}
 for i,entry in ipairs({{"OpenShop","상점","상점 1 · 상점 2\n상품은 준비 중입니다."},{"OpenRoulette","룰렛","룰렛 규칙과 보상은 준비 중입니다."}}) do
  local button=make("TextButton",{Name=entry[1],Text=entry[2],TextSize=18,Font=Enum.Font.GothamBold,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18-(i-1)*74,1,-92),Size=UDim2.fromOffset(64,56),BackgroundColor3=Color3.fromRGB(34,58,88),TextColor3=Color3.fromRGB(231,246,255),Visible=false},gui)
  make("UICorner",{CornerRadius=UDim.new(0,12)},button)
  make("UIStroke",{Color=Color3.fromRGB(93,187,231),Thickness=1},button)
  button.Activated:Connect(function()
   if not button.Visible then return end
   if api.onOpen then api.onOpen() end
   title.Text=entry[2] body.Text=entry[3] panel.Visible=true
  end)
  table.insert(buttons,button)
 end
 function api.state(data)
  local lobby=data.phase=="Idle" or data.phase=="Lobby"
  for _,button in ipairs(buttons) do button.Visible=lobby end
  if not lobby then api.close() end
 end
 return api
end
return M
]========],allowed={[========[-- Lobby entries only; products, odds and rewards remain undecided.
local M={}
function M.new(gui)
 local api={}
 local function make(kind,props,parent)
  local n=Instance.new(kind) for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
 end
 local panel=make("Frame",{Name="LobbyMenus",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.9,.65),BackgroundColor3=Color3.fromRGB(23,35,58),BorderSizePixel=0,ZIndex=30},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(520,330)},panel)
 make("UICorner",{CornerRadius=UDim.new(0,16)},panel)
 make("UIStroke",{Color=Color3.fromRGB(98,202,255),Thickness=2},panel)
 make("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(47,66,105),Color3.fromRGB(17,25,45)),Rotation=90},panel)
 local title=make("TextLabel",{Size=UDim2.new(1,-88,0,56),Position=UDim2.fromOffset(20,8),BackgroundTransparency=1,Text="",TextSize=26,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(232,245,255),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=31},panel)
 local body=make("TextLabel",{Size=UDim2.new(1,-40,1,-90),Position=UDim2.fromOffset(20,76),BackgroundTransparency=1,Text="",TextSize=20,TextWrapped=true,Font=Enum.Font.Gotham,TextColor3=Color3.fromRGB(205,223,245),ZIndex=31},panel)
 local close=make("TextButton",{Name="Close",Text="×",TextSize=30,Size=UDim2.fromOffset(48,48),Position=UDim2.new(1,-56,0,8),BackgroundColor3=Color3.fromRGB(49,69,99),TextColor3=Color3.new(1,1,1),ZIndex=31},panel)
 make("UICorner",{CornerRadius=UDim.new(0,10)},close)
 function api.close() panel.Visible=false end
 close.Activated:Connect(api.close)
 local buttons={}
 for i,entry in ipairs({{"OpenShop","상점","상점 1 · 상점 2\n상품은 준비 중입니다."},{"OpenRoulette","룰렛","룰렛 규칙과 보상은 준비 중입니다."}}) do
  local button=make("TextButton",{Name=entry[1],Text=entry[2],TextSize=18,Font=Enum.Font.GothamBold,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18-(i-1)*74,1,-92),Size=UDim2.fromOffset(64,56),BackgroundColor3=Color3.fromRGB(34,58,88),TextColor3=Color3.fromRGB(231,246,255),Visible=false},gui)
  make("UICorner",{CornerRadius=UDim.new(0,12)},button)
  make("UIStroke",{Color=Color3.fromRGB(93,187,231),Thickness=1},button)
  button.Activated:Connect(function()
   if not button.Visible then return end
   if api.onOpen then api.onOpen() end
   title.Text=entry[2] body.Text=entry[3] panel.Visible=true
  end)
  table.insert(buttons,button)
 end
 function api.state(data)
  local lobby=data.phase=="Idle" or data.phase=="Lobby"
  for _,button in ipairs(buttons) do button.Visible=lobby end
  if not lobby then api.close() end
 end
 return api
end
return M
]========]}},{parent=clients,name="CaptureClient",kind="LocalScript",new=false,after=[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local atmosphere=require(script.Parent:WaitForChild("HuntEffects"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
local isolation=require(script.Parent:WaitForChild("HuntIsolation"))
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local socialUI=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bagUI,journalUI)
local settingsUI=require(script.Parent:WaitForChild("SettingsUI")).new(gui,audio)
local lobbyMenus=require(script.Parent:WaitForChild("LobbyMenus")).new(gui)
settingsUI.onOpen=function() bagUI.close() journalUI.close() lobbyMenus.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() lobbyMenus.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() lobbyMenus.close() end
lobbyMenus.onOpen=function() bagUI.close() journalUI.close() settingsUI.close() held=false pointerOrigin,pointerX=nil,nil end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
 if prompt.Name=="PetOwnCompanion" then
  local model=prompt:FindFirstAncestorOfClass("Model")
  prompt.Enabled=model and model:GetAttribute("OwnerUserId")==player.UserId or false
 end
end)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
task.spawn(function() require(script.Parent:WaitForChild("CreatureMesh")).prepare() end)
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,12),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
settingsUI.refreshLayout()
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if settingsUI.isOpen() then return 0 end
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if settingsUI.isOpen() then return Enum.ContextActionResult.Sink end
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsUI.isOpen() or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="LobbyPet" then atmosphere.pet(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind=="EvolutionResult" then bagUI.evolutionResult(data) return end
 if kind=="BagIncome" then bagUI.income(data) return end
 if kind~="State" then socialUI.event(kind,data) return end
 if data.huntRoot and data.huntRoot:FindFirstChild("Monsters") and monsters~=data.huntRoot.Monsters then
  monsters=data.huntRoot.Monsters
  monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
 end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data) socialUI.state(data) lobbyMenus.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then  end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 isolation.update(player,state.area=="Hunt")
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 atmosphere.update(state,visualFrame,clock)
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 crashEffect.updateKnocks(clock,state.area=="Hunt" and monsters or nil)
 catch.crates(state.huntRoot and state.huntRoot:FindFirstChild("Obstacles") or workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
]========],allowed={[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local atmosphere=require(script.Parent:WaitForChild("HuntEffects"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
local isolation=require(script.Parent:WaitForChild("HuntIsolation"))
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local socialUI=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bagUI,journalUI)
local settingsUI=require(script.Parent:WaitForChild("SettingsUI")).new(gui,audio)
local lobbyMenus=require(script.Parent:WaitForChild("LobbyMenus")).new(gui)
settingsUI.onOpen=function() bagUI.close() journalUI.close() lobbyMenus.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() lobbyMenus.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() lobbyMenus.close() end
lobbyMenus.onOpen=function() bagUI.close() journalUI.close() settingsUI.close() held=false pointerOrigin,pointerX=nil,nil end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
 if prompt.Name=="PetOwnCompanion" then
  local model=prompt:FindFirstAncestorOfClass("Model")
  prompt.Enabled=model and model:GetAttribute("OwnerUserId")==player.UserId or false
 end
end)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
task.spawn(function() require(script.Parent:WaitForChild("CreatureMesh")).prepare() end)
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,12),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
settingsUI.refreshLayout()
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if settingsUI.isOpen() then return 0 end
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if settingsUI.isOpen() then return Enum.ContextActionResult.Sink end
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsUI.isOpen() or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="LobbyPet" then atmosphere.pet(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind=="EvolutionResult" then bagUI.evolutionResult(data) return end
 if kind=="BagIncome" then bagUI.income(data) return end
 if kind~="State" then socialUI.event(kind,data) return end
 if data.huntRoot and data.huntRoot:FindFirstChild("Monsters") and monsters~=data.huntRoot.Monsters then
  monsters=data.huntRoot.Monsters
  monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
 end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data) socialUI.state(data) lobbyMenus.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then  end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 isolation.update(player,state.area=="Hunt")
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 atmosphere.update(state,visualFrame,clock)
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 crashEffect.updateKnocks(clock,state.area=="Hunt" and monsters or nil)
 catch.crates(state.huntRoot and state.huntRoot:FindFirstChild("Obstacles") or workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local atmosphere=require(script.Parent:WaitForChild("HuntEffects"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
local isolation=require(script.Parent:WaitForChild("HuntIsolation"))
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local socialUI=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bagUI,journalUI)
local settingsUI=require(script.Parent:WaitForChild("SettingsUI")).new(gui,audio)
settingsUI.onOpen=function() bagUI.close() journalUI.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
 if prompt.Name=="PetOwnCompanion" then
  local model=prompt:FindFirstAncestorOfClass("Model")
  prompt.Enabled=model and model:GetAttribute("OwnerUserId")==player.UserId or false
 end
end)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
task.spawn(function() require(script.Parent:WaitForChild("CreatureMesh")).prepare() end)
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,12),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
settingsUI.refreshLayout()
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if settingsUI.isOpen() then return 0 end
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if settingsUI.isOpen() then return Enum.ContextActionResult.Sink end
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsUI.isOpen() or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="LobbyPet" then atmosphere.pet(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind=="EvolutionResult" then bagUI.evolutionResult(data) return end
 if kind=="BagIncome" then bagUI.income(data) return end
 if kind~="State" then socialUI.event(kind,data) return end
 if data.huntRoot and data.huntRoot:FindFirstChild("Monsters") and monsters~=data.huntRoot.Monsters then
  monsters=data.huntRoot.Monsters
  monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
 end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data) socialUI.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then  end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 isolation.update(player,state.area=="Hunt")
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 atmosphere.update(state,visualFrame,clock)
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 crashEffect.updateKnocks(clock,state.area=="Hunt" and monsters or nil)
 catch.crates(state.huntRoot and state.huntRoot:FindFirstChild("Obstacles") or workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local atmosphere=require(script.Parent:WaitForChild("HuntEffects"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
local isolation=require(script.Parent:WaitForChild("HuntIsolation"))
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local socialUI=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bagUI,journalUI)
local settingsUI=require(script.Parent:WaitForChild("SettingsUI")).new(gui,audio)
settingsUI.onOpen=function() bagUI.close() journalUI.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
 if prompt.Name=="PetOwnCompanion" then
  local model=prompt:FindFirstAncestorOfClass("Model")
  prompt.Enabled=model and model:GetAttribute("OwnerUserId")==player.UserId or false
 end
end)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
task.spawn(function() require(script.Parent:WaitForChild("CreatureMesh")).prepare() end)
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,12),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
settingsUI.refreshLayout()
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if settingsUI.isOpen() then return 0 end
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if settingsUI.isOpen() then return Enum.ContextActionResult.Sink end
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsUI.isOpen() or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="LobbyPet" then atmosphere.pet(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind=="EvolutionResult" then bagUI.evolutionResult(data) return end
 if kind=="BagIncome" then bagUI.income(data) return end
 if kind~="State" then socialUI.event(kind,data) return end
 if data.huntRoot and data.huntRoot:FindFirstChild("Monsters") and monsters~=data.huntRoot.Monsters then
  monsters=data.huntRoot.Monsters
  monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
 end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data) socialUI.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then  end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 isolation.update(player,state.area=="Hunt")
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 atmosphere.update(state,visualFrame,clock)
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 crashEffect.updateKnocks(clock,state.area=="Hunt" and monsters or nil)
 catch.crates(state.huntRoot and state.huntRoot:FindFirstChild("Obstacles") or workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local atmosphere=require(script.Parent:WaitForChild("HuntEffects"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
local isolation=require(script.Parent:WaitForChild("HuntIsolation"))
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local socialUI=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bagUI,journalUI)
local settingsUI=require(script.Parent:WaitForChild("SettingsUI")).new(gui,audio)
settingsUI.onOpen=function() bagUI.close() journalUI.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
 if prompt.Name=="PetOwnCompanion" then
  local model=prompt:FindFirstAncestorOfClass("Model")
  prompt.Enabled=model and model:GetAttribute("OwnerUserId")==player.UserId or false
 end
end)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
task.spawn(function() require(script.Parent:WaitForChild("CreatureMesh")).prepare() end)
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,12),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
settingsUI.refreshLayout()
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if settingsUI.isOpen() then return 0 end
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if settingsUI.isOpen() then return Enum.ContextActionResult.Sink end
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsUI.isOpen() or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="LobbyPet" then atmosphere.pet(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind=="EvolutionResult" then bagUI.evolutionResult(data) return end
 if kind=="BagIncome" then bagUI.income(data) return end
 if kind~="State" then socialUI.event(kind,data) return end
 if data.huntRoot and data.huntRoot:FindFirstChild("Monsters") and monsters~=data.huntRoot.Monsters then
  monsters=data.huntRoot.Monsters
  monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
 end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data) socialUI.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then  end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 isolation.update(player,state.area=="Hunt")
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 atmosphere.update(state,visualFrame,clock)
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 crashEffect.updateKnocks(clock,state.area=="Hunt" and monsters or nil)
 catch.crates(state.huntRoot and state.huntRoot:FindFirstChild("Obstacles") or workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
]========],[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local atmosphere=require(script.Parent:WaitForChild("HuntEffects"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
local isolation=require(script.Parent:WaitForChild("HuntIsolation"))
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local socialUI=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bagUI,journalUI)
local settingsUI=require(script.Parent:WaitForChild("SettingsUI")).new(gui,audio)
settingsUI.onOpen=function() bagUI.close() journalUI.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
 if prompt.Name=="PetOwnCompanion" then
  local model=prompt:FindFirstAncestorOfClass("Model")
  prompt.Enabled=model and model:GetAttribute("OwnerUserId")==player.UserId or false
 end
end)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
task.spawn(function() require(script.Parent:WaitForChild("CreatureMesh")).prepare() end)
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,12),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
settingsUI.refreshLayout()
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",Visible=false,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if settingsUI.isOpen() then return 0 end
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if settingsUI.isOpen() then return Enum.ContextActionResult.Sink end
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or settingsUI.isOpen() or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="LobbyPet" then atmosphere.pet(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind=="EvolutionResult" then bagUI.evolutionResult(data) return end
 if kind=="BagIncome" then bagUI.income(data) return end
 if kind~="State" then socialUI.event(kind,data) return end
 if data.huntRoot and data.huntRoot:FindFirstChild("Monsters") and monsters~=data.huntRoot.Monsters then
  monsters=data.huntRoot.Monsters
  monsters.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end)
 end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data) socialUI.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then  end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 isolation.update(player,state.area=="Hunt")
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 atmosphere.update(state,visualFrame,clock)
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 crashEffect.updateKnocks(clock,state.area=="Hunt" and monsters or nil)
 catch.crates(state.huntRoot and state.huntRoot:FindFirstChild("Obstacles") or workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
]========]}}}
local function norm(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name)
 if c.node then
  assert(c.node.ClassName==c.kind,"종류 불일치: "..c.name)
  local valid=false for _,s in ipairs(c.allowed) do if norm(s)==norm(c.node.Source) then valid=true break end end
  assert(valid,"다른 코드가 있어 중단: "..c.name) c.before=c.node.Source
 else assert(c.new,"코드 없음: "..c.name) end
end
local backup=Instance.new("Folder") backup.Name="LobbyHuntFixBackup_"..game:GetService("HttpService"):GenerateGUID(false)
backup.Parent=game:GetService("ServerStorage")
lobby:Clone().Parent=backup
local parts,pivots,texts,removed,made={},{},{},{},{}
local leftovers={InstalledMossratPreview=true,InstalledRocketPreview=true,MossratImport=true,MossratMeshOnly=true,MossratS1Rigged=true,Mossrat=true,RocketImport=true,Rocket=true}
for _,n in ipairs(workspace:GetChildren()) do
 if leftovers[n.Name] and n:IsA("Model") and n:FindFirstChildWhichIsA("MeshPart",true) then table.insert(removed,{n,n.Parent}) end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby and hunt fixes")
local ok,err=pcall(function()
 for _,c in ipairs(changes) do
  if c.node then c.node:Clone().Parent=backup else c.node=Instance.new(c.kind) c.node.Name=c.name c.node.Parent=c.parent table.insert(made,c.node) end
  c.node.Source=c.after
 end
 for _,p in ipairs(lobby:GetDescendants()) do
  if p:IsA("Part") then
   table.insert(parts,{p,p.Material,p.TopSurface,p.BottomSurface,p.FrontSurface,p.BackSurface,p.LeftSurface,p.RightSurface})
   p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.FrontSurface=Enum.SurfaceType.Smooth p.BackSurface=Enum.SurfaceType.Smooth p.LeftSurface=Enum.SurfaceType.Smooth p.RightSurface=Enum.SurfaceType.Smooth
   if p.Material==Enum.Material.Plastic then p.Material=Enum.Material.SmoothPlastic end
  end
 end
 local oldBoards=lobby:FindFirstChild("Leaderboards")
 if oldBoards then
  for _,b in ipairs(oldBoards:GetChildren()) do if b:IsA("BasePart") or b:IsA("Model") then table.insert(pivots,{b,b:GetPivot()}) end end
 else
  oldBoards=Instance.new("Folder") oldBoards.Name="Leaderboards" oldBoards.Parent=lobby table.insert(made,oldBoards)
 end
 local oldChildren={} for _,b in ipairs(oldBoards:GetChildren()) do oldChildren[b]=true end
 local rankings=assert(loadstring(server.LobbyRankings.Source))()
 rankings.ensure(lobby)
 for _,b in ipairs(oldBoards:GetChildren()) do if not oldChildren[b] then table.insert(made,b) end end
 local rocket=lobby.Airport:FindFirstChild("Rocket")
 local center=Vector3.new(6000,0,0)
 if rocket and rocket:IsA("Model") then local box=rocket:GetBoundingBox() center=Vector3.new(box.X,0,box.Z) end
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  local base=room:FindFirstChild("RoomBase") local sensor=room:FindFirstChild("DoorSensor")
  if base and sensor then
   table.insert(pivots,{room,room:GetPivot()})
   local origin=base.Position
   local offset=sensor.Position-origin local towards=center-origin
   local delta=math.atan2(towards.X,towards.Z)-math.atan2(offset.X,offset.Z)
   room:PivotTo(CFrame.new(origin)*CFrame.Angles(0,delta,0)*CFrame.new(-origin)*room:GetPivot())
  end
  local board=room:FindFirstChild("OwnerBoard")
  if board then for _,t in ipairs(board:GetDescendants()) do if t:IsA("TextLabel") then table.insert(texts,{t,t.Text}) t.Text="" end end end
 end
 for _,row in ipairs(removed) do row[1].Parent=backup end
 local roof=lobby:FindFirstChild("Roof")
 if not roof then roof=Instance.new("Model") roof.Name="Roof" roof.Parent=lobby table.insert(made,roof) end
 if not roof:FindFirstChild("FullOpaqueCeiling") then
  local cap=Instance.new("Part") cap.Name="FullOpaqueCeiling" cap.Size=Vector3.new(512,8,512) cap.Position=Vector3.new(6000,102,0)
  cap.Anchored=true cap.CanTouch=false cap.Material=Enum.Material.SmoothPlastic cap.Color=Color3.fromRGB(25,35,57)
  cap.TopSurface=Enum.SurfaceType.Smooth cap.BottomSurface=Enum.SurfaceType.Smooth cap.Parent=roof table.insert(made,cap)
 end
end)
if not ok then
 for _,row in ipairs(removed) do row[1].Parent=row[2] end
 for _,row in ipairs(pivots) do row[1]:PivotTo(row[2]) end
 for _,row in ipairs(texts) do row[1].Text=row[2] end
 for _,r in ipairs(parts) do local p=r[1] p.Material=r[2] p.TopSurface=r[3] p.BottomSurface=r[4] p.FrontSurface=r[5] p.BackSurface=r[6] p.LeftSurface=r[7] p.RightSurface=r[8] end
 for _,c in ipairs(changes) do if c.before then c.node.Source=c.before end end
 for _,n in ipairs(made) do n:Destroy() end
 backup:Destroy() error("기존 상태 복원 완료: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby and hunt fixes installed")
print("LOBBY_HUNT_FIXES_INSTALLED — Ctrl+S 저장 후 Play. 미리보기 정리 수:",#removed)
