do
-- Remove supplied room machinery; preserve room shells, planet, rocket and inventory.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"RodeoLobby 없음")
local shared=game.ReplicatedStorage.RodeoFantasy
local server=game:GetService("ServerScriptService")
local clients=game.StarterPlayer.StarterPlayerScripts
local function normal(s) return s:gsub("\r\n","\n") end
local changes={{parent=server,name="LobbyWorld",before=[========[local Lobby={}
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
 if root then
  root.Anchored=true
  character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  local owner=game:GetService("Players"):GetPlayerFromCharacter(character)
  if owner and workspace.StreamingEnabled then pcall(function() owner:RequestStreamAroundAsync(Lobby.Spawn.Position,3) end) end
 end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed humanoid.PlatformStand=false humanoid.AutoRotate=true end
 if root then
  task.delay(.35,function()
   if character.Parent and root.Parent then
    character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
    root.Anchored=false
    if humanoid and humanoid.Health>0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
   end
  end)
 end
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
function Lobby.canSummon(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and math.abs(root.Position.X-6000)<=256 and math.abs(root.Position.Z)<=256
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
]========],after=[========[local Lobby={}
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
 if root then
  root.Anchored=true
  character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  local owner=game:GetService("Players"):GetPlayerFromCharacter(character)
  if owner and workspace.StreamingEnabled then pcall(function() owner:RequestStreamAroundAsync(Lobby.Spawn.Position,3) end) end
 end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed humanoid.PlatformStand=false humanoid.AutoRotate=true end
 if root then
  task.delay(.35,function()
   if character.Parent and root.Parent then
    character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
    root.Anchored=false
    if humanoid and humanoid.Health>0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
   end
  end)
 end
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
 local board=plots["Plot_"..index]:FindFirstChild("OwnerBoard")
 if not board then return end
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
 if type(index)~="number" or index%1~=0 or index<1 or index>4 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canSummon(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and math.abs(root.Position.X-6000)<=256 and math.abs(root.Position.Z)<=256
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
]========]},{parent=clients,name="BagUI",before=[========[local UI={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Query=require(game.ReplicatedStorage.RodeoFantasy.CollectionQuery)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Income=require(script.Parent:WaitForChild("IncomeEffects"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamBold end
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
function UI.iconButton(gui,kind,key,right)
 local bag=kind=="Bag"
 local button=make("TextButton",{Name=bag and "OpenBag" or "OpenJournal",Text="",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-right,1,-18),Size=UDim2.fromOffset(64,64),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.08,BorderSizePixel=0},gui)
 make("UICorner",{CornerRadius=UDim.new(0,16)},button)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},button)
 local function shape(name,x,y,w,h,color,radius)
  local node=make("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,BorderSizePixel=0},button)
  make("UICorner",{CornerRadius=UDim.new(0,radius or 3)},node) return node
 end
 if bag then
  local leather=Color3.fromRGB(178,126,84)
  shape("Handle",25,10,14,12,leather,5)
  shape("Backpack",18,17,28,32,leather,8)
  shape("Pocket",23,31,18,12,Color3.fromRGB(133,88,58),4)
  shape("Clasp",30,28,4,5,Color3.fromRGB(250,213,131),1)
 else
  shape("Cover",12,15,40,32,Color3.fromRGB(178,126,84),4)
  shape("LeftPage",15,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("RightPage",33,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("Spine",31,16,2,29,Color3.fromRGB(120,91,61),1)
  for _,x in ipairs({18,36}) do for y=23,35,6 do shape("Ink",x,y,10,2,Color3.fromRGB(136,156,119),1) end end
 end
 make("TextLabel",{Name="Shortcut",Text=key,BackgroundTransparency=1,Position=UDim2.fromOffset(42,45),Size=UDim2.fromOffset(18,16),TextSize=11,TextColor3=Color3.fromRGB(246,229,193)},button)
 return button
end
function UI.new(gui,remote)
 local self={area="Lobby",items={},count=-1,pen=nil,region="All",page=1,query="",evolutionMode=false,selected={}}
 local button=UI.iconButton(gui,"Bag","R",18)
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(.56,-20,0,34),TextSize=20,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve",player.LocaleId),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,9)},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters",player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("ViewportFrame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolvePreview)
 local evolveCancel=make("TextButton",{Name="CancelEvolution",Text=L.text("Cancel",player.LocaleId),Position=UDim2.new(1,-194,0,12),Size=UDim2.fromOffset(80,34),TextSize=13,BackgroundColor3=Color3.fromRGB(164,139,107),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 local evolveConfirm=make("TextButton",{Name="ConfirmEvolution",Text=L.text("Evolve",player.LocaleId),Position=UDim2.new(1,-108,0,12),Size=UDim2.fromOffset(100,34),TextSize=13,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolveCancel) make("UICorner",{CornerRadius=UDim.new(0,8)},evolveConfirm)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,245),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 local search=make("TextBox",{Name="BagSearch",PlaceholderText=L.text("Search monsters",player.LocaleId),Text="",ClearTextOnFocus=false,Position=UDim2.fromOffset(20,95),Size=UDim2.new(1,-40,0,34),BackgroundColor3=Color3.fromRGB(255,250,237),TextColor3=Color3.fromRGB(71,58,40),TextSize=17,ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,8)},search)
 local tabs=make("ScrollingFrame",{Name="BagRegions",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(20,136),Size=UDim2.new(1,-40,0,32),AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=0,ZIndex=23},window)
 make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)},tabs)
 local previous=make("TextButton",{Name="BagPrevious",Text="‹",BackgroundTransparency=1,Position=UDim2.new(.35,-45,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 local pageLabel=make("TextLabel",{Name="BagPage",Text="1 / 1",BackgroundTransparency=1,Position=UDim2.new(.35,0,1,-45),Size=UDim2.new(.3,0,0,30),TextSize=15,ZIndex=23},window)
 local nextPage=make("TextButton",{Name="BagNext",Text="›",BackgroundTransparency=1,Position=UDim2.new(.65,5,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 function self.filter(region,query)
  self.region,self.query,self.page=region or self.region,query or self.query,1
  self.snapshot(self.items)
 end
 for _,region in ipairs(Query.regions(Catalog)) do
  local tab=make("TextButton",{Name="Region_"..region,Text=L.text(region,player.LocaleId),Size=UDim2.fromOffset(112,30),BackgroundColor3=Color3.fromRGB(213,193,159),TextColor3=Color3.fromRGB(65,53,37),TextSize=15,ZIndex=24},tabs)
  make("UICorner",{CornerRadius=UDim.new(0,8)},tab)
  tab.Activated:Connect(function() self.filter(region,nil) end)
 end
 local breed=make("TextButton",{Name="Breed",Text="교배",Position=UDim2.new(.62,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 breed.Activated:Connect(function() if self.onBreed then self.onBreed() end end)
 local hovered,hold
 UIS.InputBegan:Connect(function(input,processed) if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.E and hovered and window.Visible and (self.area=="Cafe" or self.area=="Lobby") then hold={id=hovered,at=os.clock()} end end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.E then hold=nil end end)
 game:GetService("RunService").RenderStepped:Connect(function() if hold and window.Visible and hovered==hold.id and os.clock()-hold.at>=1 then remote:FireServer("Summon",hold.id) hold=nil end end)
 local chooser
 local revision=0
 local function selectedCount() local n=0 for _ in pairs(self.selected) do n+=1 end return n end
 local function selectionAnchor()
  for id in pairs(self.selected) do
   for _,item in ipairs(self.items) do if item.id==id then return item end end
  end
 end
 local function updateEvolutionControls()
  local count=selectedCount()
  local anchor=selectionAnchor()
  if anchor then
   evolveStatus.Text=L.text(anchor.monsterId,player.LocaleId).." · "..anchor.stars.."★  →  "..(anchor.stars+1).."★    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
   if anchor.stars<10 then Portrait.fill(evolvePreview,anchor.monsterId,anchor.stars+1,false) end
  else
   evolveStatus.Text=L.text("Select three matching monsters",player.LocaleId).."    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
  end
  evolveConfirm.Active=count==3 and anchor~=nil and anchor.stars<10
  evolveConfirm.AutoButtonColor=evolveConfirm.Active
  evolveConfirm.BackgroundColor3=evolveConfirm.Active and Color3.fromRGB(80,134,104) or Color3.fromRGB(151,159,143)
 end
 function self.setEvolutionMode(enabled)
  self.evolutionMode=enabled==true
  if not self.evolutionMode then self.selected={} end
  self.mode=nil self.pen=nil chooser.Visible=false scroll.Visible=true
  evolveControls.Visible=self.evolutionMode
  scroll.Position=UDim2.fromOffset(16,self.evolutionMode and 240 or 175)
  scroll.Size=UDim2.new(1,-32,1,self.evolutionMode and -295 or -230)
  evolveToggle.Text=self.evolutionMode and L.text("Cancel",player.LocaleId) or L.text("Evolve",player.LocaleId)
  self.snapshot(self.items)
 end
 evolveToggle.Activated:Connect(function()
  if self.area~="Hunt" and not self.pen then self.setEvolutionMode(not self.evolutionMode) end
 end)
 evolveCancel.Activated:Connect(function() self.setEvolutionMode(false) end)
 evolveConfirm.Activated:Connect(function()
  if not evolveConfirm.Active or self.area=="Hunt" then return end
  local ids={} for id in pairs(self.selected) do table.insert(ids,id) end
  table.sort(ids)
  if #ids==3 then remote:FireServer("Evolve",ids) end
 end)
 search:GetPropertyChangedSignal("Text"):Connect(function()
  revision+=1 local current=revision
  task.delay(.12,function() if revision==current then self.filter(nil,search.Text) end end)
 end)
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("Frame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,1 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="부화소".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Manage",index) end end)
 end
 local babies=make("TextButton",{Name="BabyCapsules",Text="새끼 캡슐 4칸 · 설정 준비 중",BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=18,TextWrapped=true,ZIndex=24},chooser)
 make("UICorner",{CornerRadius=UDim.new(0,14)},babies)
 function self.openCompanionMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="Companion" self.pen=nil chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items) window.Visible=true self.opened() title.Text="동행 몬스터 · 1마리 선택" remote:FireServer("Bag")
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="알 관리 · 개인 부화소"
 end
 function self.toggle()
  if self.area=="Hunt" then return end
  self.mode=nil self.pen=nil self.setEvolutionMode(false) chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items)
  window.Visible=not window.Visible
  if window.Visible then self.opened() remote:FireServer("Bag") end
 end
 button.Activated:Connect(self.toggle)
 close.Activated:Connect(self.close)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.R then self.toggle() end
 end)
 function self.state(state)
  self.area=state.area
  local nextSummoned=state.summonedId
  if self.summonedId~=nextSummoned then self.summonedId=nextSummoned self.snapshot(self.items) end
  button.Visible=state.area~="Hunt"
  if state.area=="Hunt" then window.Visible=false self.pen=nil self.setEvolutionMode(false) end
  money.Text="코인: "..tostring((state.pending or 0)+(state.balance or 0))
  button.Text=""
  if state.area~="Hunt" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.openPen(index)
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode=nil chooser.Visible=false scroll.Visible=true
  self.pen=index self.snapshot(self.items) window.Visible=true self.opened()
 end
 function self.snapshot(items)
  self.items=items self.cards={} hovered=nil hold=nil
  local present={} for _,item in ipairs(items) do present[item.id]=true end
  for id in pairs(self.selected) do if not present[id] then self.selected[id]=nil end end
  local placed=0
  for _,item in ipairs(items) do if item.assignedPen==self.pen and self.pen then placed+=1 end end
  title.Text=L.text(self.mode=="Companion" and "동행 몬스터 · 1마리 선택" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag",player.LocaleId)..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,player.LocaleId) end)
  local pages=math.max(1,math.ceil(#filtered/12)) self.page=math.clamp(self.page,1,pages)
  pageLabel.Text=self.page.." / "..pages
  local show=self.mode~="RanchMenu"
  search.Visible=show tabs.Visible=show previous.Visible=show nextPage.Visible=show pageLabel.Visible=show
  evolveToggle.Visible=show and not self.pen breed.Visible=show and not self.pen
  evolveControls.Visible=show and self.evolutionMode and not self.pen
  if self.evolutionMode then
   scroll.Position=UDim2.fromOffset(16,240) scroll.Size=UDim2.new(1,-32,1,-295)
  else
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
  end
  empty.Visible=show and #filtered==0
  empty.Text=L.text(#items==0 and "No monsters caught yet" or "No matching monsters",player.LocaleId)
  for _,tab in ipairs(tabs:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundColor3=tab.Name=="Region_"..self.region and Color3.fromRGB(167,127,79) or Color3.fromRGB(213,193,159) end end
  scroll.CanvasPosition=Vector2.zero
  for index=(self.page-1)*12+1,math.min(self.page*12,#filtered) do
   local item=filtered[index]
   local card=make("Frame",{Name="MonsterCard",Size=UDim2.fromOffset(170,245),BackgroundColor3=Color3.fromRGB(237,225,204),ZIndex=22,LayoutOrder=index},scroll)
   make("UICorner",{CornerRadius=UDim.new(0,12)},card)
   local male=item.sex=="Male" local female=item.sex=="Female"
   local color=male and Color3.fromRGB(72,130,180) or female and Color3.fromRGB(183,88,115) or Color3.fromRGB(119,109,91)
   local badge=make("Frame",{Name="SexBadge",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-7,0,6),Size=UDim2.fromOffset(30,26),Visible=male or female,BackgroundColor3=Color3.fromRGB(255,241,213),BorderSizePixel=0,ZIndex=26},card)
   make("UICorner",{CornerRadius=UDim.new(0,6)},badge)
   local offset=male and 0 or 3
   local ring=make("Frame",{Name="SexRing",Position=UDim2.fromOffset(6+offset,5),Size=UDim2.fromOffset(11,11),BackgroundTransparency=1,ZIndex=27},badge)
   make("UICorner",{CornerRadius=UDim.new(1,0)},ring) make("UIStroke",{Color=color,Thickness=2},ring)
   local function line(name,x,y,w,h,rotation)
    make("Frame",{Name=name,Position=UDim2.fromOffset(x+offset,y),Size=UDim2.fromOffset(w,h),Rotation=rotation or 0,BackgroundColor3=color,BorderSizePixel=0,ZIndex=27},badge)
   end
   if male then line("MaleStem",14,4,9,2,-45) line("ArrowTop",18,2,6,2) line("ArrowRight",22,2,2,6)
   elseif female then line("FemaleStem",10,15,2,7) line("FemaleCross",7,18,8,2) end
   self.cards[item.id]=card
   local preview=make("ViewportFrame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23,Ambient=Color3.fromRGB(195,195,195),LightColor=Color3.new(1,1,1)},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,player.LocaleId).." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   make("TextLabel",{Name="Income",Text=L.income(item.incomeAmount,item.incomeSeconds,player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),TextSize=14,TextWrapped=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "소환 해제" or "동행 선택",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Summon",item.id) end end)
   elseif self.pen then
    local mine=item.assignedPen==self.pen
    local allowed=mine or (not item.assignedPen and placed<2)
    local label=mine and "Return to bag" or item.assignedPen and "Placed" or placed>=2 and "Full" or "Place"
    local choose=make("TextButton",{Name="ChooseMonster",Text=L.text(label,player.LocaleId),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=allowed and Color3.fromRGB(80,134,104) or Color3.fromRGB(154,167,151),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if allowed and self.pen and self.area=="Lobby" then remote:FireServer(mine and "Remove" or "Place",{id=item.id,pen=self.pen}) end
    end)
   elseif self.evolutionMode then
    local anchor=selectionAnchor()
    local compatible=not anchor or (anchor.monsterId==item.monsterId and anchor.stars==item.stars)
    local selected=self.selected[item.id]==true
    local choose=make("TextButton",{Name="SelectForEvolution",Text=selected and L.text("Selected",player.LocaleId) or L.text("Select",player.LocaleId),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=selected and Color3.fromRGB(80,134,104) or compatible and Color3.fromRGB(147,182,154) or Color3.fromRGB(184,181,168),TextColor3=Color3.new(1,1,1),Active=compatible and (selected or selectedCount()<3),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if self.selected[item.id] then self.selected[item.id]=nil
     elseif compatible and selectedCount()<3 and self.area~="Hunt" then self.selected[item.id]=true end
     self.snapshot(self.items)
    end)
   elseif self.area=="Cafe" or self.area=="Lobby" then
    if item.id==self.summonedId and self.area=="Cafe" then
     make("TextLabel",{Text="소환 중",BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
    elseif not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "E 꾹 · 소환 해제" or "E 꾹 · 소환",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     card.MouseEnter:Connect(function() hovered=item.id end) card.MouseLeave:Connect(function() if hovered==item.id then hovered=nil hold=nil end end)
     summon.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then hovered=item.id hold={id=item.id,at=os.clock()} end end)
     summon.InputEnded:Connect(function() hold=nil end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed",player.LocaleId).." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve",player.LocaleId)
  else
   local key=result.reason=="MaxStars" and "Already at max stars" or "Evolution failed"
   evolveStatus.Text=L.text(key,player.LocaleId)
  end
 end
 function self.income(gains)
  if self.area=="Hunt" or not window.Visible then return end
  for _,gain in ipairs(gains or {}) do
   local card=self.cards and self.cards[gain.id]
   if card and card.Parent then Income.card(card,gain.amount) end
  end
 end
 return self
end
return UI
]========],after=[========[local UI={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Query=require(game.ReplicatedStorage.RodeoFantasy.CollectionQuery)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Income=require(script.Parent:WaitForChild("IncomeEffects"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamBold end
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
function UI.iconButton(gui,kind,key,right)
 local bag=kind=="Bag"
 local button=make("TextButton",{Name=bag and "OpenBag" or "OpenJournal",Text="",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-right,1,-18),Size=UDim2.fromOffset(64,64),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.08,BorderSizePixel=0},gui)
 make("UICorner",{CornerRadius=UDim.new(0,16)},button)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},button)
 local function shape(name,x,y,w,h,color,radius)
  local node=make("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,BorderSizePixel=0},button)
  make("UICorner",{CornerRadius=UDim.new(0,radius or 3)},node) return node
 end
 if bag then
  local leather=Color3.fromRGB(178,126,84)
  shape("Handle",25,10,14,12,leather,5)
  shape("Backpack",18,17,28,32,leather,8)
  shape("Pocket",23,31,18,12,Color3.fromRGB(133,88,58),4)
  shape("Clasp",30,28,4,5,Color3.fromRGB(250,213,131),1)
 else
  shape("Cover",12,15,40,32,Color3.fromRGB(178,126,84),4)
  shape("LeftPage",15,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("RightPage",33,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("Spine",31,16,2,29,Color3.fromRGB(120,91,61),1)
  for _,x in ipairs({18,36}) do for y=23,35,6 do shape("Ink",x,y,10,2,Color3.fromRGB(136,156,119),1) end end
 end
 make("TextLabel",{Name="Shortcut",Text=key,BackgroundTransparency=1,Position=UDim2.fromOffset(42,45),Size=UDim2.fromOffset(18,16),TextSize=11,TextColor3=Color3.fromRGB(246,229,193)},button)
 return button
end
function UI.new(gui,remote)
 local self={area="Lobby",items={},count=-1,pen=nil,region="All",page=1,query="",evolutionMode=false,selected={}}
 local button=UI.iconButton(gui,"Bag","R",18)
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(.56,-20,0,34),TextSize=20,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve",player.LocaleId),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,9)},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters",player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("ViewportFrame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolvePreview)
 local evolveCancel=make("TextButton",{Name="CancelEvolution",Text=L.text("Cancel",player.LocaleId),Position=UDim2.new(1,-194,0,12),Size=UDim2.fromOffset(80,34),TextSize=13,BackgroundColor3=Color3.fromRGB(164,139,107),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 local evolveConfirm=make("TextButton",{Name="ConfirmEvolution",Text=L.text("Evolve",player.LocaleId),Position=UDim2.new(1,-108,0,12),Size=UDim2.fromOffset(100,34),TextSize=13,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolveCancel) make("UICorner",{CornerRadius=UDim.new(0,8)},evolveConfirm)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,245),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 local search=make("TextBox",{Name="BagSearch",PlaceholderText=L.text("Search monsters",player.LocaleId),Text="",ClearTextOnFocus=false,Position=UDim2.fromOffset(20,95),Size=UDim2.new(1,-40,0,34),BackgroundColor3=Color3.fromRGB(255,250,237),TextColor3=Color3.fromRGB(71,58,40),TextSize=17,ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,8)},search)
 local tabs=make("ScrollingFrame",{Name="BagRegions",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(20,136),Size=UDim2.new(1,-40,0,32),AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=0,ZIndex=23},window)
 make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)},tabs)
 local previous=make("TextButton",{Name="BagPrevious",Text="‹",BackgroundTransparency=1,Position=UDim2.new(.35,-45,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 local pageLabel=make("TextLabel",{Name="BagPage",Text="1 / 1",BackgroundTransparency=1,Position=UDim2.new(.35,0,1,-45),Size=UDim2.new(.3,0,0,30),TextSize=15,ZIndex=23},window)
 local nextPage=make("TextButton",{Name="BagNext",Text="›",BackgroundTransparency=1,Position=UDim2.new(.65,5,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 function self.filter(region,query)
  self.region,self.query,self.page=region or self.region,query or self.query,1
  self.snapshot(self.items)
 end
 for _,region in ipairs(Query.regions(Catalog)) do
  local tab=make("TextButton",{Name="Region_"..region,Text=L.text(region,player.LocaleId),Size=UDim2.fromOffset(112,30),BackgroundColor3=Color3.fromRGB(213,193,159),TextColor3=Color3.fromRGB(65,53,37),TextSize=15,ZIndex=24},tabs)
  make("UICorner",{CornerRadius=UDim.new(0,8)},tab)
  tab.Activated:Connect(function() self.filter(region,nil) end)
 end
 local breed=make("TextButton",{Name="Breed",Text="교배",Position=UDim2.new(.62,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 breed.Activated:Connect(function() if self.onBreed then self.onBreed() end end)
 local hovered,hold
 UIS.InputBegan:Connect(function(input,processed) if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.E and hovered and window.Visible and (self.area=="Cafe" or self.area=="Lobby") then hold={id=hovered,at=os.clock()} end end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.E then hold=nil end end)
 game:GetService("RunService").RenderStepped:Connect(function() if hold and window.Visible and hovered==hold.id and os.clock()-hold.at>=1 then remote:FireServer("Summon",hold.id) hold=nil end end)
 local chooser
 local revision=0
 local function selectedCount() local n=0 for _ in pairs(self.selected) do n+=1 end return n end
 local function selectionAnchor()
  for id in pairs(self.selected) do
   for _,item in ipairs(self.items) do if item.id==id then return item end end
  end
 end
 local function updateEvolutionControls()
  local count=selectedCount()
  local anchor=selectionAnchor()
  if anchor then
   evolveStatus.Text=L.text(anchor.monsterId,player.LocaleId).." · "..anchor.stars.."★  →  "..(anchor.stars+1).."★    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
   if anchor.stars<10 then Portrait.fill(evolvePreview,anchor.monsterId,anchor.stars+1,false) end
  else
   evolveStatus.Text=L.text("Select three matching monsters",player.LocaleId).."    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
  end
  evolveConfirm.Active=count==3 and anchor~=nil and anchor.stars<10
  evolveConfirm.AutoButtonColor=evolveConfirm.Active
  evolveConfirm.BackgroundColor3=evolveConfirm.Active and Color3.fromRGB(80,134,104) or Color3.fromRGB(151,159,143)
 end
 function self.setEvolutionMode(enabled)
  self.evolutionMode=enabled==true
  if not self.evolutionMode then self.selected={} end
  self.mode=nil self.pen=nil chooser.Visible=false scroll.Visible=true
  evolveControls.Visible=self.evolutionMode
  scroll.Position=UDim2.fromOffset(16,self.evolutionMode and 240 or 175)
  scroll.Size=UDim2.new(1,-32,1,self.evolutionMode and -295 or -230)
  evolveToggle.Text=self.evolutionMode and L.text("Cancel",player.LocaleId) or L.text("Evolve",player.LocaleId)
  self.snapshot(self.items)
 end
 evolveToggle.Activated:Connect(function()
  if self.area~="Hunt" and not self.pen then self.setEvolutionMode(not self.evolutionMode) end
 end)
 evolveCancel.Activated:Connect(function() self.setEvolutionMode(false) end)
 evolveConfirm.Activated:Connect(function()
  if not evolveConfirm.Active or self.area=="Hunt" then return end
  local ids={} for id in pairs(self.selected) do table.insert(ids,id) end
  table.sort(ids)
  if #ids==3 then remote:FireServer("Evolve",ids) end
 end)
 search:GetPropertyChangedSignal("Text"):Connect(function()
  revision+=1 local current=revision
  task.delay(.12,function() if revision==current then self.filter(nil,search.Text) end end)
 end)
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("Frame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,4 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="부화소".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Manage",index) end end)
 end
 function self.openCompanionMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="Companion" self.pen=nil chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items) window.Visible=true self.opened() title.Text="동행 몬스터 · 1마리 선택" remote:FireServer("Bag")
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="알 관리 · 개인 부화소"
 end
 function self.toggle()
  if self.area=="Hunt" then return end
  self.mode=nil self.pen=nil self.setEvolutionMode(false) chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items)
  window.Visible=not window.Visible
  if window.Visible then self.opened() remote:FireServer("Bag") end
 end
 button.Activated:Connect(self.toggle)
 close.Activated:Connect(self.close)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.R then self.toggle() end
 end)
 function self.state(state)
  self.area=state.area
  local nextSummoned=state.summonedId
  if self.summonedId~=nextSummoned then self.summonedId=nextSummoned self.snapshot(self.items) end
  button.Visible=state.area~="Hunt"
  if state.area=="Hunt" then window.Visible=false self.pen=nil self.setEvolutionMode(false) end
  money.Text="코인: "..tostring((state.pending or 0)+(state.balance or 0))
  button.Text=""
  if state.area~="Hunt" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.openPen(index)
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode=nil chooser.Visible=false scroll.Visible=true
  self.pen=index self.snapshot(self.items) window.Visible=true self.opened()
 end
 function self.snapshot(items)
  self.items=items self.cards={} hovered=nil hold=nil
  local present={} for _,item in ipairs(items) do present[item.id]=true end
  for id in pairs(self.selected) do if not present[id] then self.selected[id]=nil end end
  local placed=0
  for _,item in ipairs(items) do if item.assignedPen==self.pen and self.pen then placed+=1 end end
  title.Text=L.text(self.mode=="Companion" and "동행 몬스터 · 1마리 선택" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag",player.LocaleId)..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,player.LocaleId) end)
  local pages=math.max(1,math.ceil(#filtered/12)) self.page=math.clamp(self.page,1,pages)
  pageLabel.Text=self.page.." / "..pages
  local show=self.mode~="RanchMenu"
  search.Visible=show tabs.Visible=show previous.Visible=show nextPage.Visible=show pageLabel.Visible=show
  evolveToggle.Visible=show and not self.pen breed.Visible=show and not self.pen
  evolveControls.Visible=show and self.evolutionMode and not self.pen
  if self.evolutionMode then
   scroll.Position=UDim2.fromOffset(16,240) scroll.Size=UDim2.new(1,-32,1,-295)
  else
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
  end
  empty.Visible=show and #filtered==0
  empty.Text=L.text(#items==0 and "No monsters caught yet" or "No matching monsters",player.LocaleId)
  for _,tab in ipairs(tabs:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundColor3=tab.Name=="Region_"..self.region and Color3.fromRGB(167,127,79) or Color3.fromRGB(213,193,159) end end
  scroll.CanvasPosition=Vector2.zero
  for index=(self.page-1)*12+1,math.min(self.page*12,#filtered) do
   local item=filtered[index]
   local card=make("Frame",{Name="MonsterCard",Size=UDim2.fromOffset(170,245),BackgroundColor3=Color3.fromRGB(237,225,204),ZIndex=22,LayoutOrder=index},scroll)
   make("UICorner",{CornerRadius=UDim.new(0,12)},card)
   local male=item.sex=="Male" local female=item.sex=="Female"
   local color=male and Color3.fromRGB(72,130,180) or female and Color3.fromRGB(183,88,115) or Color3.fromRGB(119,109,91)
   local badge=make("Frame",{Name="SexBadge",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-7,0,6),Size=UDim2.fromOffset(30,26),Visible=male or female,BackgroundColor3=Color3.fromRGB(255,241,213),BorderSizePixel=0,ZIndex=26},card)
   make("UICorner",{CornerRadius=UDim.new(0,6)},badge)
   local offset=male and 0 or 3
   local ring=make("Frame",{Name="SexRing",Position=UDim2.fromOffset(6+offset,5),Size=UDim2.fromOffset(11,11),BackgroundTransparency=1,ZIndex=27},badge)
   make("UICorner",{CornerRadius=UDim.new(1,0)},ring) make("UIStroke",{Color=color,Thickness=2},ring)
   local function line(name,x,y,w,h,rotation)
    make("Frame",{Name=name,Position=UDim2.fromOffset(x+offset,y),Size=UDim2.fromOffset(w,h),Rotation=rotation or 0,BackgroundColor3=color,BorderSizePixel=0,ZIndex=27},badge)
   end
   if male then line("MaleStem",14,4,9,2,-45) line("ArrowTop",18,2,6,2) line("ArrowRight",22,2,2,6)
   elseif female then line("FemaleStem",10,15,2,7) line("FemaleCross",7,18,8,2) end
   self.cards[item.id]=card
   local preview=make("ViewportFrame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23,Ambient=Color3.fromRGB(195,195,195),LightColor=Color3.new(1,1,1)},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,player.LocaleId).." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   make("TextLabel",{Name="Income",Text=L.income(item.incomeAmount,item.incomeSeconds,player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),TextSize=14,TextWrapped=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "소환 해제" or "동행 선택",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Summon",item.id) end end)
   elseif self.pen then
    local mine=item.assignedPen==self.pen
    local allowed=mine or (not item.assignedPen and placed<2)
    local label=mine and "Return to bag" or item.assignedPen and "Placed" or placed>=2 and "Full" or "Place"
    local choose=make("TextButton",{Name="ChooseMonster",Text=L.text(label,player.LocaleId),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=allowed and Color3.fromRGB(80,134,104) or Color3.fromRGB(154,167,151),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if allowed and self.pen and self.area=="Lobby" then remote:FireServer(mine and "Remove" or "Place",{id=item.id,pen=self.pen}) end
    end)
   elseif self.evolutionMode then
    local anchor=selectionAnchor()
    local compatible=not anchor or (anchor.monsterId==item.monsterId and anchor.stars==item.stars)
    local selected=self.selected[item.id]==true
    local choose=make("TextButton",{Name="SelectForEvolution",Text=selected and L.text("Selected",player.LocaleId) or L.text("Select",player.LocaleId),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=selected and Color3.fromRGB(80,134,104) or compatible and Color3.fromRGB(147,182,154) or Color3.fromRGB(184,181,168),TextColor3=Color3.new(1,1,1),Active=compatible and (selected or selectedCount()<3),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if self.selected[item.id] then self.selected[item.id]=nil
     elseif compatible and selectedCount()<3 and self.area~="Hunt" then self.selected[item.id]=true end
     self.snapshot(self.items)
    end)
   elseif self.area=="Cafe" or self.area=="Lobby" then
    if item.id==self.summonedId and self.area=="Cafe" then
     make("TextLabel",{Text="소환 중",BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
    elseif not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "E 꾹 · 소환 해제" or "E 꾹 · 소환",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     card.MouseEnter:Connect(function() hovered=item.id end) card.MouseLeave:Connect(function() if hovered==item.id then hovered=nil hold=nil end end)
     summon.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then hovered=item.id hold={id=item.id,at=os.clock()} end end)
     summon.InputEnded:Connect(function() hold=nil end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed",player.LocaleId).." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve",player.LocaleId)
  else
   local key=result.reason=="MaxStars" and "Already at max stars" or "Evolution failed"
   evolveStatus.Text=L.text(key,player.LocaleId)
  end
 end
 function self.income(gains)
  if self.area=="Hunt" or not window.Visible then return end
  for _,gain in ipairs(gains or {}) do
   local card=self.cards and self.cards[gain.id]
   if card and card.Parent then Income.card(card,gain.amount) end
  end
 end
 return self
end
return UI
]========]},{parent=shared,name="LobbyIncubatorRules",before=[========[-- Retain every egg when moving from four lobby incubators to one.
local R={}
function R.migrate(bag)
 local occupied=false
 local returned=0
 for _,egg in ipairs(bag.eggs or {}) do
  if egg.assignedPen==1 and not occupied then occupied=true
  elseif egg.assignedPen~=nil then egg.assignedPen=nil returned+=1 end
 end
 return returned
end
return R
]========],after=[========[-- Preserve one egg in each of the four open hatchery stands.
local R={}
function R.migrate(bag)
 local occupied={}
 local returned=0
 for _,egg in ipairs(bag.eggs or {}) do
  local slot=egg.assignedPen
  if type(slot)=="number" and slot%1==0 and slot>=1 and slot<=4 and not occupied[slot] then occupied[slot]=true
  elseif slot~=nil then egg.assignedPen=nil returned+=1 end
 end
 return returned
end
return R
]========]},{parent=server,name="CaptureServer",before=[========[local Players=game:GetService("Players")
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
 canSummon=function(p) return Lobby.canSummon(p) end,
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
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
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
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}})
  elseif not states[player] then remote:FireClient(player,"SocialMessage","알 배치는 내 부화실 안에서 이용해주세요.") end
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
   if not humanoid or humanoid.Health<=0 or (state and (state.phase=="GameOver" or state.phase=="CourseEnd")) then
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
]========],after=[========[local Players=game:GetService("Players")
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
 canSummon=function(p) return Lobby.canSummon(p) end,
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
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
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
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}})
  elseif not states[player] then remote:FireClient(player,"SocialMessage","알 배치는 내 부화실 안에서 이용해주세요.") end
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
   if not humanoid or humanoid.Health<=0 or (state and (state.phase=="GameOver" or state.phase=="CourseEnd")) then
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
 for index=1,4 do Lobby.display(player,index,bag.eggs or {}) end
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
]========]}}
for _,c in ipairs(changes) do
 c.node=assert(c.parent:FindFirstChild(c.name),c.name.." 없음")
 assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"별도 변경된 코드: "..c.name)
 c.original=c.node.Source
end
local builder=(function()
-- Four low, open egg stands per player room. Existing room materials supply colors.
local M={}
function M.build(room)
 local base=assert(room:FindFirstChild("RoomBase"),"RoomBase 없음")
 local oldPen=room.Pens:FindFirstChild("Pen_1")
 local oldGrass=oldPen and oldPen:FindFirstChild("PenGrass")
 local board=room:FindFirstChild("OwnerBoard")
 local text=board and board:FindFirstChildWhichIsA("TextLabel",true)
 local accent=text and text.TextColor3 or Color3.fromRGB(69,167,172)
 if oldPen then
  for _,n in ipairs(oldPen:GetDescendants()) do
   if n:IsA("BasePart") and n.Material==Enum.Material.Neon then accent=n.Color break end
  end
 end
 local floor=base.Position.Y+base.Size.Y/2
 local origin=CFrame.new(base.Position.X,floor,base.Position.Z)*base.CFrame.Rotation
 local pens=Instance.new("Folder") pens.Name="Pens"
 local function part(parent,name,size,frame,color,material)
  local p=Instance.new("Part") p.Name=name p.Shape=Enum.PartType.Cylinder
  p.Size=size p.CFrame=frame*CFrame.Angles(0,0,math.pi/2)
  p.Color=color p.Material=material p.Anchored=true
  p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=parent
  return p
 end
 for index,pos in ipairs({{-12,-10},{12,-10},{-12,12},{12,12}}) do
  local pen=Instance.new("Model") pen.Name="Pen_"..index pen:SetAttribute("Capacity",1) pen.Parent=pens
  local frame=origin*CFrame.new(pos[1],0,pos[2])
  part(pen,"StandBase",Vector3.new(1,15,15),frame*CFrame.new(0,.5,0),Color3.fromRGB(42,55,73),Enum.Material.SmoothPlastic)
  part(pen,"StandGlow",Vector3.new(.18,14,14),frame*CFrame.new(0,1.08,0),accent,Enum.Material.Neon)
  -- PenGrass remains horizontal for the existing egg placement code.
  local socket=Instance.new("Part") socket.Name="PenGrass" socket.Size=Vector3.new(11,1.2,11)
  socket.CFrame=frame*CFrame.new(0,.7,0) socket.Color=oldGrass and oldGrass.Color or Color3.fromRGB(30,42,61)
  socket.Material=Enum.Material.SmoothPlastic socket.Anchored=true socket.Transparency=1
  socket.CanCollide=false socket.CanTouch=false socket.CanQuery=false socket.Parent=pen
  part(pen,"EggSeat",Vector3.new(.2,11,11),frame*CFrame.new(0,1.2,0),socket.Color,Enum.Material.SmoothPlastic)
  local number=Instance.new("Part") number.Name="StandNumber" number.Size=Vector3.new(4,.1,2)
  number.CFrame=frame*CFrame.new(0,1.34,-5) number.Transparency=1 number.Anchored=true number.CanCollide=false number.CanTouch=false number.CanQuery=false number.Parent=pen
  local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Top gui.CanvasSize=Vector2.new(200,100) gui.Parent=number
  local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text=tostring(index)
  label.Font=Enum.Font.GothamBold label.TextScaled=true label.TextColor3=Color3.new(1,1,1) label.Parent=gui
 end
 return pens
end
return M

end)()
local prepared={}
for i=1,8 do
 local room=assert(lobby.Plots:FindFirstChild("Plot_"..i),"부화실 없음")
 assert(room.Pens and room.RoomBase,"부화실 기준점 없음")
 table.insert(prepared,{room=room,pens=builder.build(room)})
end
local backup=Instance.new("Folder") backup.Name="OpenHatcheryBackup_"..game:GetService("HttpService"):GenerateGUID(false)
local moved={}
local targets={BabyCapsules=true,UserIncubator=true,UserDoorFrame=true,UserDoorConsole=true,DoorLeft=true,DoorRight=true,DoorSensor=true,SpaceLobbyDoors=true,ControlPedestal=true,IncubatorConsole=true,ConsoleBar=true,EggStatus=true}
local function archive(n)
 table.insert(moved,{node=n,parent=n.Parent}) n.Parent=backup
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before four open hatcheries")
local ok,err=pcall(function()
 backup.Parent=game.ServerStorage
 for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
 for _,row in ipairs(prepared) do
  local old=row.room.Pens
  -- Retain any edit-mode egg displays without duplicating inventory.
  for _,pen in ipairs(old:GetChildren()) do
   local target=row.pens:FindFirstChild(pen.Name)
   local display=pen:FindFirstChild("DisplayEggs")
   if target and display and pen:FindFirstChild("PenGrass") then
    local copy=display:Clone()
    local shift=target.PenGrass.CFrame*pen.PenGrass.CFrame:Inverse()
    for _,p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.CFrame=shift*p.CFrame end end
    copy.Parent=target
   end
  end
  archive(old) row.pens.Parent=row.room
  for _,n in ipairs(row.room:GetChildren()) do if targets[n.Name] then archive(n) end end
 end
 local doors=lobby:FindFirstChild("SpaceLobbyDoors") if doors then archive(doors) end
 for _,name in ipairs({"IncubatorImport","DoorImport","ConsoleImport","IncubatorTextureDiagnostic"}) do
  local n=workspace:FindFirstChild(name) if n then archive(n) end
 end
 lobby:SetAttribute("OpenHatcheriesInstalled",true)
end)
if not ok then
 for _,row in ipairs(prepared) do row.pens:Destroy() end
 for i=#moved,1,-1 do moved[i].node.Parent=moved[i].parent end
 for _,c in ipairs(changes) do c.node.Source=c.original end
 backup:Destroy() error("설치 복구: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Four open hatcheries installed")
local count=0
for _,row in ipairs(prepared) do assert(#row.pens:GetChildren()==4) count+=4 end
print("OPEN_HATCHERIES_INSTALLED — 8개 방 / 열린 알 받침 32개 / 캡슐·문·콘솔 제거. 원본은 ServerStorage 백업. Ctrl+S 저장.")
game:GetService("Selection"):Set({prepared[1].room})
local base=prepared[1].room.RoomBase
local center=base.Position+Vector3.new(0,3,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(center+base.CFrame:VectorToWorldSpace(Vector3.new(0,24,-42)),center)
workspace.CurrentCamera.Focus=CFrame.new(center)
end
