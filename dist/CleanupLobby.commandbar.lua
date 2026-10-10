do
assert(not game:GetService("RunService"):IsRunning(),"Play 중지")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"로비 없음")
assert(lobby:GetAttribute("OpenHatcheriesInstalled"),"열린 부화소를 먼저 설치하세요.")
local server=game.ServerScriptService
local function normal(s) return s:gsub("\r\n","\n") end
local changes={
{node=server.LobbyWorld,before=[========[local Lobby={}
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
]========]},
{node=server.LobbyRankings,before=[========[local M={}
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
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,2.04,-16))
  if board:IsA("BasePart") then board.Size=Vector3.new(26,.08,30) board.CanCollide=false board.CanTouch=false board.CanQuery=false end
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
  gui.Face=Enum.NormalId.Top
 end
 return boards
end
return M
]========],after=[========[local M={}
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
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,17,24))
  if board:IsA("BasePart") then board.Size=Vector3.new(26,30,1.5) board.CanCollide=false board.CanTouch=false board.CanQuery=false end
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
  gui.Face=Enum.NormalId.Front
 end
 return boards
end
return M
]========]},
{node=server.LobbyPresentation,before=[========[-- Applies the requested smooth surfaces to the installed lobby only.
local lobby=workspace:WaitForChild("RodeoLobby")
local safety=lobby:FindFirstChild("LobbyCollisionFloor")
if not safety then
 safety=Instance.new("Part") safety.Name="LobbyCollisionFloor" safety.Size=Vector3.new(512,4,512) safety.Position=Vector3.new(6000,0,0)
 safety.Anchored=true safety.Transparency=1 safety.CanCollide=true safety.CanTouch=false safety.CollisionGroup="Default" safety.Parent=lobby
end
local decor=lobby:FindFirstChild("SpaceDiorama")
if decor then for _,p in ipairs(decor:GetDescendants()) do if p.Name=="PlanetLayer" or p.Name=="PlanetRing" then p:Destroy() end end end
local sign=lobby.Airport:FindFirstChild("DepartureSign") if sign then sign:Destroy() end
local roof=lobby:FindFirstChild("Roof") or Instance.new("Model")
roof.Name="Roof" roof.Parent=lobby
for _,p in ipairs(roof:GetChildren()) do if p.Name=="Ceiling" or p.Name=="FullOpaqueCeiling" then p:Destroy() end end
if not roof:FindFirstChild("FullGlassCeiling") then
 local cap=Instance.new("Part") cap.Name="FullGlassCeiling"
 cap.Size=Vector3.new(512,2,512) cap.Position=Vector3.new(6000,102,0)
 cap.Anchored=true cap.CanTouch=false cap.Material=Enum.Material.Glass cap.Transparency=.65
 cap.Color=Color3.fromRGB(173,212,232) cap.Parent=roof
end
for _,p in ipairs(lobby.ShipShell:GetDescendants()) do if p:IsA("BasePart") and p.Name=="WindowSpace" then p.Material=Enum.Material.Metal p.Transparency=0 p.CanCollide=true p.Color=Color3.fromRGB(62,78,103) end end
if not lobby:FindFirstChild("OverheadSpace") then
 local space=Instance.new("Model") space.Name="OverheadSpace" space.Parent=lobby
 local back=Instance.new("Part") back.Name="SpaceBackdrop" back.Size=Vector3.new(1200,2,1200) back.Position=Vector3.new(6000,500,0)
 back.Anchored=true back.CanCollide=false back.CanTouch=false back.CanQuery=false back.CastShadow=false back.Color=Color3.fromRGB(8,11,29) back.Parent=space
 local random=Random.new(731)
 for i=1,70 do
  local star=Instance.new("Part") star.Name="Star" star.Shape=Enum.PartType.Ball star.Size=Vector3.one*random:NextNumber(.8,2)
  star.Position=Vector3.new(6000+random:NextNumber(-470,470),495,random:NextNumber(-470,470)) star.Color=Color3.fromRGB(193,217,255) star.Material=Enum.Material.Neon
  star.Anchored=true star.CanCollide=false star.CanTouch=false star.CanQuery=false star.CastShadow=false star.Parent=space
 end
end
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("Part") then
  part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth
  part.FrontSurface=Enum.SurfaceType.Smooth part.BackSurface=Enum.SurfaceType.Smooth
  part.LeftSurface=Enum.SurfaceType.Smooth part.RightSurface=Enum.SurfaceType.Smooth
  if part.Material==Enum.Material.Plastic then part.Material=Enum.Material.SmoothPlastic end
 end
end
]========],after=[========[-- Applies the requested smooth surfaces to the installed lobby only.
local lobby=workspace:WaitForChild("RodeoLobby")
local safety=lobby:FindFirstChild("LobbyCollisionFloor")
if not safety then
 safety=Instance.new("Part") safety.Name="LobbyCollisionFloor" safety.Size=Vector3.new(512,4,512) safety.Position=Vector3.new(6000,0,0)
 safety.Anchored=true safety.Transparency=1 safety.CanCollide=true safety.CanTouch=false safety.CollisionGroup="Default" safety.Parent=lobby
end
local decor=lobby:FindFirstChild("SpaceDiorama")
if decor then for _,p in ipairs(decor:GetDescendants()) do if p.Name=="PlanetLayer" or p.Name=="PlanetRing" then p:Destroy() end end end
local sign=lobby.Airport:FindFirstChild("DepartureSign") if sign then sign:Destroy() end
if not lobby:GetAttribute("LobbyCleanupInstalled") then
local roof=lobby:FindFirstChild("Roof") or Instance.new("Model")
roof.Name="Roof" roof.Parent=lobby
for _,p in ipairs(roof:GetChildren()) do if p.Name=="Ceiling" or p.Name=="FullOpaqueCeiling" then p:Destroy() end end
if not roof:FindFirstChild("FullGlassCeiling") then
 local cap=Instance.new("Part") cap.Name="FullGlassCeiling"
 cap.Size=Vector3.new(512,2,512) cap.Position=Vector3.new(6000,102,0)
 cap.Anchored=true cap.CanTouch=false cap.Material=Enum.Material.Glass cap.Transparency=.65
 cap.Color=Color3.fromRGB(173,212,232) cap.Parent=roof
end
end
local shell=lobby:FindFirstChild("ShipShell")
if shell then for _,p in ipairs(shell:GetDescendants()) do if p:IsA("BasePart") and p.Name=="WindowSpace" then p.Material=Enum.Material.Metal p.Transparency=0 p.CanCollide=true p.Color=Color3.fromRGB(62,78,103) end end end
if not lobby:FindFirstChild("OverheadSpace") then
 local space=Instance.new("Model") space.Name="OverheadSpace" space.Parent=lobby
 local back=Instance.new("Part") back.Name="SpaceBackdrop" back.Size=Vector3.new(1200,2,1200) back.Position=Vector3.new(6000,500,0)
 back.Anchored=true back.CanCollide=false back.CanTouch=false back.CanQuery=false back.CastShadow=false back.Color=Color3.fromRGB(8,11,29) back.Parent=space
 local random=Random.new(731)
 for i=1,70 do
  local star=Instance.new("Part") star.Name="Star" star.Shape=Enum.PartType.Ball star.Size=Vector3.one*random:NextNumber(.8,2)
  star.Position=Vector3.new(6000+random:NextNumber(-470,470),495,random:NextNumber(-470,470)) star.Color=Color3.fromRGB(193,217,255) star.Material=Enum.Material.Neon
  star.Anchored=true star.CanCollide=false star.CanTouch=false star.CanQuery=false star.CastShadow=false star.Parent=space
 end
end
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("Part") then
  part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth
  part.FrontSurface=Enum.SurfaceType.Smooth part.BackSurface=Enum.SurfaceType.Smooth
  part.LeftSurface=Enum.SurfaceType.Smooth part.RightSurface=Enum.SurfaceType.Smooth
  if part.Material==Enum.Material.Plastic then part.Material=Enum.Material.SmoothPlastic end
 end
end
]========]}
}
for _,c in ipairs(changes) do assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"코드가 달라 중단: "..c.node.Name) c.original=c.node.Source end
local backup=Instance.new("Folder") backup.Name="LobbyCleanupBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
local moved,added,properties={},{},{}
local function archive(n) if n then table.insert(moved,{n,n.Parent}) n.Parent=backup end end
local function set(n,key,value) table.insert(properties,{n,key,n[key]}) n[key]=value end
local function block(parent,name,size,cf,color)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Reflectance=0 p.Parent=parent table.insert(added,p) return p
end
local planet=lobby:FindFirstChild("CeilingPlanet")
local planetOld=planet and {scale=planet:GetScale(),pivot=planet:GetPivot()}
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby cleanup")
local ok,err=pcall(function()
 for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
 for _,name in ipairs({"Roof","Amenities","SpaceDiorama","ShipShell","SolidShipWalls"}) do archive(lobby:FindFirstChild(name)) end
 local shell=Instance.new("Model") shell.Name="SolidShipWalls" shell.Parent=lobby table.insert(added,shell)
 local color=Color3.fromRGB(56,69,86)
 block(shell,"WallNorth",Vector3.new(496,80,8),CFrame.new(6000,42,-252),color)
 block(shell,"WallSouth",Vector3.new(496,80,8),CFrame.new(6000,42,252),color)
 block(shell,"WallEast",Vector3.new(8,80,512),CFrame.new(6252,42,0),color)
 block(shell,"WallWest",Vector3.new(8,80,512),CFrame.new(5748,42,0),color)
 -- Opaque backing stops sky showing through the octagonal tile seams.
 local floor=assert(lobby:FindFirstChild("LobbyCollisionFloor"),"안전 바닥 없음")
 set(floor,"Transparency",0) set(floor,"Color",Color3.fromRGB(62,77,99))
 set(floor,"Material",Enum.Material.SmoothPlastic) set(floor,"Reflectance",0)
 set(floor,"Size",Vector3.new(512,4,512)) set(floor,"CFrame",CFrame.new(6000,-.15,0)) set(floor,"CanCollide",true)
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  local base=room.RoomBase local top=base.Position.Y+base.Size.Y/2
  local origin=CFrame.new(base.Position.X,top,base.Position.Z)*base.CFrame.Rotation
  local board=room:FindFirstChild("OwnerBoard") local label=board and board:FindFirstChildWhichIsA("TextLabel",true)
  local existingGlow=room.Pens.Pen_1:FindFirstChild("StandGlow")
  local accent=label and label.TextColor3 or existingGlow and existingGlow.Color or Color3.fromRGB(69,167,172)
  for _,pen in ipairs(room.Pens:GetChildren()) do local glow=pen:FindFirstChild("StandGlow") if glow then set(glow,"Color",accent) end end
  for _,n in ipairs(room:GetChildren()) do
   if ({RoomRoof=true,OwnerBoard=true,Planter=true,Stem=true,LeafPlate=true,SideWall=true,RearWall=true,FrontWall=true,SolidRoomWalls=true})[n.Name] then archive(n) end
  end
  local walls=Instance.new("Model") walls.Name="SolidRoomWalls" walls.Parent=room table.insert(added,walls)
  local c=Color3.fromRGB(180,191,198)
  -- Butt joints meet exactly, without duplicate coplanar faces. Opening width 28.
  for _,x in ipairs({-39,39}) do block(walls,"SideWall",Vector3.new(2,32,80),origin*CFrame.new(x,16,0),c) end
  block(walls,"RearWall",Vector3.new(76,32,2),origin*CFrame.new(0,16,39),c)
  for _,x in ipairs({-26,26}) do block(walls,"FrontWall",Vector3.new(24,32,2),origin*CFrame.new(x,16,-39),c) end
 end
 if planet then
  local _,size=planet:GetBoundingBox()
  planet:ScaleTo(planet:GetScale()*360/math.max(size.X,size.Y,size.Z))
  local box=planet:GetBoundingBox()
  planet:PivotTo(CFrame.new(Vector3.new(6000,330,60)-box.Position)*planet:GetPivot())
  for _,p in ipairs(planet:GetDescendants()) do if p:IsA("BasePart") then set(p,"CanCollide",false) set(p,"CanTouch",false) set(p,"CanQuery",false) end end
 end
 -- Remove decorative signs; ranking entries remain functional.
 local title=lobby.Airport:FindFirstChild("GameTitle") if title then archive(title) end
 for _,n in ipairs(lobby:GetDescendants()) do
  if n:IsA("BasePart") then
   if n.Reflectance~=0 then set(n,"Reflectance",0) end
   if n.Material~=Enum.Material.Neon and n.Material~=Enum.Material.Glass then set(n,"TopSurface",Enum.SurfaceType.Smooth) set(n,"BottomSurface",Enum.SurfaceType.Smooth) end
  end
 end
 local rankings=(function()
local M={}
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
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,17,24))
  if board:IsA("BasePart") then board.Size=Vector3.new(26,30,1.5) board.CanCollide=false board.CanTouch=false board.CanQuery=false end
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
  gui.Face=Enum.NormalId.Front
 end
 return boards
end
return M

end)()
 local boards=lobby:FindFirstChild("Leaderboards")
 for _,n in ipairs(boards:GetChildren()) do
  table.insert(properties,{n,"Size",n.Size}) table.insert(properties,{n,"CFrame",n.CFrame})
  local gui=n:FindFirstChild("Ranking") if gui then table.insert(properties,{gui,"Face",gui.Face}) end
 end
 rankings.ensure(lobby)
 lobby:SetAttribute("LobbyCleanupInstalled",true)
end)
if not ok then
 for i=#properties,1,-1 do local r=properties[i] r[1][r[2]]=r[3] end
 for i=#added,1,-1 do added[i]:Destroy() end
 for i=#moved,1,-1 do moved[i][1].Parent=moved[i][2] end
 for _,c in ipairs(changes) do c.node.Source=c.original end
 if planetOld then planet:ScaleTo(planetOld.scale) planet:PivotTo(planetOld.pivot) end
 backup:Destroy() error("정리 실패·복원: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby cleanup complete")
game:GetService("Selection"):Set({})
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(6000,50,-95),Vector3.new(6000,16,0)) workspace.CurrentCamera.Focus=CFrame.new(6000,16,0)
print("LOBBY_CLEANUP_INSTALLED — 천장·나무·장식 간판 제거 / 벽 이음새·바닥 메움 / 랭킹 로켓 양옆 / 행성 최대 폭360. Ctrl+S 저장.")
end
