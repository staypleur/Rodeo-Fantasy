do
assert(not game:GetService("RunService"):IsRunning(),"Play 중지")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"로비 없음")
local changes={
{name="LobbyWorld",before=[========[local Lobby={}
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
]========],after=[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
require(script.Parent.LobbyAppearance).ensure(map)
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
   label(index,player.Name)
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
{name="LobbyRankings",before=[========[local M={}
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
]========],after=[========[local M={}
local mirrored=setmetatable({},{__mode="k"})
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
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,17,24))*CFrame.Angles(0,math.pi/2,0)
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
  local back=board:FindFirstChild("RankingBack")
  if not back then back=gui:Clone() back.Name="RankingBack" back.Parent=board end
  back.Face=Enum.NormalId.Back
  back.Heading.Text=gui.Heading.Text back.Entries.Text=gui.Entries.Text
  if not mirrored[board] then
   mirrored[board]=true
   gui.Entries:GetPropertyChangedSignal("Text"):Connect(function() back.Entries.Text=gui.Entries.Text end)
   gui.Heading:GetPropertyChangedSignal("Text"):Connect(function() back.Heading.Text=gui.Heading.Text end)
  end
 end
 return boards
end
return M
]========]},
{name="LobbyPresentation",before=[========[-- Applies the requested smooth surfaces to the installed lobby only.
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
]========],after=[========[-- Applies the requested smooth surfaces to the installed lobby only.
local lobby=workspace:WaitForChild("RodeoLobby")
require(script.Parent.LobbyAppearance).ensure(lobby)
local safety=lobby:FindFirstChild("LobbyCollisionFloor")
if not safety then
 safety=Instance.new("Part") safety.Name="LobbyCollisionFloor" safety.Size=Vector3.new(512,4,512) safety.Position=Vector3.new(6000,0,0)
 safety.Anchored=true safety.Transparency=1 safety.CanCollide=true safety.CanTouch=false safety.CollisionGroup="Default" safety.Parent=lobby
end
local decor=lobby:FindFirstChild("SpaceDiorama")
if decor then for _,p in ipairs(decor:GetDescendants()) do if p.Name=="PlanetLayer" or p.Name=="PlanetRing" then p:Destroy() end end end
local sign=lobby.Airport:FindFirstChild("DepartureSign") if sign then sign:Destroy() end
local shell=lobby:FindFirstChild("ShipShell")
if shell then for _,p in ipairs(shell:GetDescendants()) do if p:IsA("BasePart") and p.Name=="WindowSpace" then p.Material=Enum.Material.Metal p.Transparency=0 p.CanCollide=true p.Color=Color3.fromRGB(62,78,103) end end end
if not lobby:FindFirstChild("OverheadSpace") then
 local space=Instance.new("Model") space.Name="OverheadSpace" space.Parent=lobby
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
]========]},
{name="LobbyCompanions",before=[========[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.clear(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","내 부화실 안에서 소환해주세요.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  if not source or source:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","이 몬스터의 모델을 준비 중입니다.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height}
  p:SetAttribute("SummonedId",id)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="교감"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<1.5 then return end
   last=os.clock() P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=workspace:GetServerTimeNow()})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then api.clear(p) continue end
   local old=pet.model.PrimaryPart.CFrame
   local target=r.Position-r.CFrame.LookVector*5+r.CFrame.RightVector*4
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=delta.Magnitude>2
   if moving then
    delta=delta.Unit*math.min(delta.Magnitude,48*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
    else
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]========],after=[========[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.clear(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","내 부화실 안에서 소환해주세요.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  if not source or source:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","이 몬스터의 모델을 준비 중입니다.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false}
  p:SetAttribute("SummonedId",id)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="교감"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  prompt.Style=Enum.ProximityPromptStyle.Custom
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<1.5 then return end
   last=os.clock() P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=workspace:GetServerTimeNow()})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then api.clear(p) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    delta=delta.Unit*math.min(delta.Magnitude-6,32*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
    else
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]========]},
{name="CaptureClient",before=[========[local Players=game:GetService("Players")
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
local lobbyMenus=require(script.Parent:WaitForChild("LobbyMenus")).new(gui,bagUI,journalUI,remote)
settingsUI.onOpen=function() bagUI.close() journalUI.close() socialUI.close() lobbyMenus.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() socialUI.close() lobbyMenus.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() socialUI.close() lobbyMenus.close() end
lobbyMenus.onOpen=function() bagUI.close() journalUI.close() settingsUI.close() socialUI.close() held=false pointerOrigin,pointerX=nil,nil end
socialUI.onOpen=function() lobbyMenus.close() settingsUI.close() end
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
local hudStats=require(script.Parent:WaitForChild("HudStats")).new(gui)
local bag=gui:FindFirstChild("LobbyStats")
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
 if not enabled and state.area=="Lobby" then
  local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if humanoid then camera.CameraSubject=humanoid camera.CameraType=Enum.CameraType.Custom end
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
 hudStats.state(state)
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
]========],after=[========[local Players=game:GetService("Players")
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
local wasFirstPerson=false
RunService:BindToRenderStep("RodeoLobbyFirstPerson",Enum.RenderPriority.Camera.Value+1,function()
 local camera=workspace.CurrentCamera
 local first=state.area=="Lobby" and camera.CameraType==Enum.CameraType.Custom and (camera.CFrame.Position-camera.Focus.Position).Magnitude<2.5
 if (first or wasFirstPerson) and player.Character then
  -- Large avatar accessories and our helmet can otherwise block the lens.
  for _,p in ipairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.LocalTransparencyModifier=first and 1 or 0 end end
 end
 wasFirstPerson=first
end)
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
local lobbyMenus=require(script.Parent:WaitForChild("LobbyMenus")).new(gui,bagUI,journalUI,remote)
settingsUI.onOpen=function() bagUI.close() journalUI.close() socialUI.close() lobbyMenus.close() held=false pointerOrigin,pointerX=nil,nil end
bagUI.onOpen=function() journalUI.close() settingsUI.close() socialUI.close() lobbyMenus.close() end
journalUI.onOpen=function() bagUI.close() settingsUI.close() socialUI.close() lobbyMenus.close() end
lobbyMenus.onOpen=function() bagUI.close() journalUI.close() settingsUI.close() socialUI.close() held=false pointerOrigin,pointerX=nil,nil end
socialUI.onOpen=function() lobbyMenus.close() settingsUI.close() end
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
require(script.Parent:WaitForChild("PetPromptUI")).new(gui,player)
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
local hudStats=require(script.Parent:WaitForChild("HudStats")).new(gui)
local bag=gui:FindFirstChild("LobbyStats")
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
 if not enabled and state.area=="Lobby" then
  player.CameraMode=Enum.CameraMode.Classic
  player.CameraMinZoomDistance=.5 player.CameraMaxZoomDistance=48
  local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if humanoid then camera.CameraSubject=humanoid camera.CameraType=Enum.CameraType.Custom end
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
 hudStats.state(state)
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
]========]},
{name="HudIcons",before=[========[-- Small native shapes: no external images are required for the menu symbols.
local I={}
-- IDs supplied by the user from their uploaded image list.
I.ImageIds={ShopButtonImage="rbxassetid://84295507284264",IndexButtonImage="rbxassetid://135277525783308",
 EggButtonImage="rbxassetid://87551432940862",PawButtonImage="rbxassetid://85966265063532",MossratFaceImage="rbxassetid://98296663869747"}
function I.imageId(package,key)
 local id=package:GetAttribute(key)
 if key=="PawButtonImage" and id=="rbxassetid://8596625063532" then return I.ImageIds[key] end
 if type(id)=="string" and id~="rbxassetid://0" and id:match("^rbxassetid://%d+$") then return id end
 return I.ImageIds[key] or ""
end
-- User-supplied PNGs become Roblox image assets only after upload. Keep the
-- native controls usable until their content IDs are configured.
function I.bindArtwork(button,key)
 local package=game.ReplicatedStorage.RodeoFantasy
 local image=Instance.new("ImageLabel") image.Name="UploadedArtwork"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ZIndex=button.ZIndex+2 image.ScaleType=Enum.ScaleType.Fit image.Parent=button
 local background=button.BackgroundTransparency
 local originals,strokes={},{}
 for _,n in ipairs(button:GetChildren()) do
  if n:IsA("GuiObject") and n~=image then originals[n]=n.Visible
  elseif n:IsA("UIStroke") then strokes[n]=n.Enabled end
 end
 local function display()
  local ready=image.Image~="" and image.IsLoaded
  image.Visible=ready
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
 local function refresh()
  local id=I.imageId(package,key)
  if image.Image~=id then image.Image=id end
  display()
 end
 image:GetPropertyChangedSignal("IsLoaded"):Connect(display)
 package:GetAttributeChangedSignal(key):Connect(refresh) refresh()
end
function I.draw(parent,kind,size)
 local root=Instance.new("Frame") root.Name=kind.."Icon" root.Size=UDim2.fromOffset(size,size) root.BackgroundTransparency=1 root.Parent=parent
 local function shape(x,y,w,h,color,radius,rotation)
  local n=Instance.new("Frame") n.Position=UDim2.fromScale(x,y) n.Size=UDim2.fromScale(w,h) n.BackgroundColor3=color n.BorderSizePixel=0 n.Rotation=rotation or 0 n.Parent=root
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(radius or 0,0) c.Parent=n
  local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(15,18,20) s.Thickness=2 s.Parent=n return n
 end
 local white=Color3.fromRGB(255,249,229)
 if kind=="Egg" then shape(.23,.08,.54,.82,Color3.fromRGB(255,211,145),.5)
 elseif kind=="Paw" then
  shape(.27,.48,.48,.4,Color3.fromRGB(255,198,124),.45)
  for _,p in ipairs({{.08,.3},{.28,.1},{.53,.1},{.75,.3}}) do shape(p[1],p[2],.18,.28,Color3.fromRGB(255,209,151),.5) end
 elseif kind=="Shop" then
  shape(.2,.34,.65,.42,white,.12,-6) shape(.07,.17,.23,.09,white,.15)
  for _,x in ipairs({.3,.68}) do shape(x,.84,.15,.15,white,.5) end
 elseif kind=="Journal" then
  shape(.18,.17,.64,.66,white,.07,-8)
  for _,y in ipairs({.33,.48,.63}) do shape(.32,y,.36,.025,Color3.fromRGB(60,74,82),0) end
 elseif kind=="Money" then
  shape(.06,.25,.78,.52,Color3.fromRGB(92,226,39),.05,-12)
  shape(.2,.12,.75,.5,Color3.fromRGB(130,255,59),.05,-12)
  shape(.44,.16,.13,.51,Color3.fromRGB(240,215,35),0,-12)
 elseif kind=="Roulette" then
  shape(.08,.08,.84,.84,Color3.fromRGB(255,219,48),.5)
  for i=0,5 do local a=i*math.pi/3 shape(.43+math.cos(a)*.25,.43+math.sin(a)*.25,.16,.16,i%2==0 and Color3.fromRGB(255,93,104) or white,.5) end
  shape(.4,.4,.2,.2,Color3.fromRGB(250,250,250),.5)
 end
 return root
end
return I
]========],after=[========[-- Small native shapes: no external images are required for the menu symbols.
local I={}
-- IDs supplied by the user from their uploaded image list.
I.ImageIds={ShopButtonImage="rbxassetid://135776139567636",RouletteButtonImage="rbxassetid://103655794024864",IndexButtonImage="rbxassetid://135277525783308",
 EggButtonImage="rbxassetid://87551432940862",PawButtonImage="rbxassetid://85966265063532",MossratFaceImage="rbxassetid://87383094549038",MoneyImage="rbxassetid://71604722538432"}
function I.imageId(package,key)
 local id=package:GetAttribute(key)
 if key=="PawButtonImage" and id=="rbxassetid://8596625063532" then return I.ImageIds[key] end
 if type(id)=="string" and id~="rbxassetid://0" and id:match("^rbxassetid://%d+$") then return id end
 return I.ImageIds[key] or ""
end
-- User-supplied PNGs become Roblox image assets only after upload. Keep the
-- native controls usable until their content IDs are configured.
function I.bindArtwork(button,key)
 local package=game.ReplicatedStorage.RodeoFantasy
 local image=Instance.new("ImageLabel") image.Name="UploadedArtwork"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ZIndex=button.ZIndex+2 image.ScaleType=Enum.ScaleType.Fit image.Parent=button
 local background=button.BackgroundTransparency
 local originals,strokes={},{}
 for _,n in ipairs(button:GetChildren()) do
  if n:IsA("GuiObject") and n~=image then originals[n]=n.Visible
  elseif n:IsA("UIStroke") then strokes[n]=n.Enabled end
 end
 local function display()
  local ready=image.Image~="" and image.IsLoaded
  -- Keep the label renderable while Roblox requests the image. Hiding it until
  -- IsLoaded can leave it waiting indefinitely; a faint image permits loading.
  image.Visible=true image.ImageTransparency=ready and 0 or .99
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
 local function refresh()
  local id=I.imageId(package,key)
  if image.Image~=id then image.Image=id end
  display()
  -- IsLoaded may update without a property signal. Poll only this request and
  -- stop when it loads, changes, or the control is removed.
  task.spawn(function()
   while image.Parent and image.Image==id and not image.IsLoaded do task.wait(.25) end
   if image.Parent and image.Image==id then display() end
  end)
 end
 image:GetPropertyChangedSignal("IsLoaded"):Connect(display)
 package:GetAttributeChangedSignal(key):Connect(refresh) refresh()
end
function I.draw(parent,kind,size)
 local root=Instance.new("Frame") root.Name=kind.."Icon" root.Size=UDim2.fromOffset(size,size) root.BackgroundTransparency=1 root.Parent=parent
 local function shape(x,y,w,h,color,radius,rotation)
  local n=Instance.new("Frame") n.Position=UDim2.fromScale(x,y) n.Size=UDim2.fromScale(w,h) n.BackgroundColor3=color n.BorderSizePixel=0 n.Rotation=rotation or 0 n.Parent=root
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(radius or 0,0) c.Parent=n
  local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(15,18,20) s.Thickness=2 s.Parent=n return n
 end
 local white=Color3.fromRGB(255,249,229)
 if kind=="Egg" then shape(.23,.08,.54,.82,Color3.fromRGB(255,211,145),.5)
 elseif kind=="Paw" then
  shape(.27,.48,.48,.4,Color3.fromRGB(255,198,124),.45)
  for _,p in ipairs({{.08,.3},{.28,.1},{.53,.1},{.75,.3}}) do shape(p[1],p[2],.18,.28,Color3.fromRGB(255,209,151),.5) end
 elseif kind=="Shop" then
  shape(.2,.34,.65,.42,white,.12,-6) shape(.07,.17,.23,.09,white,.15)
  for _,x in ipairs({.3,.68}) do shape(x,.84,.15,.15,white,.5) end
 elseif kind=="Journal" then
  shape(.18,.17,.64,.66,white,.07,-8)
  for _,y in ipairs({.33,.48,.63}) do shape(.32,y,.36,.025,Color3.fromRGB(60,74,82),0) end
 elseif kind=="Money" then
  shape(.06,.25,.78,.52,Color3.fromRGB(92,226,39),.05,-12)
  shape(.2,.12,.75,.5,Color3.fromRGB(130,255,59),.05,-12)
  shape(.44,.16,.13,.51,Color3.fromRGB(240,215,35),0,-12)
 elseif kind=="Roulette" then
  shape(.08,.08,.84,.84,Color3.fromRGB(255,219,48),.5)
  for i=0,5 do local a=i*math.pi/3 shape(.43+math.cos(a)*.25,.43+math.sin(a)*.25,.16,.16,i%2==0 and Color3.fromRGB(255,93,104) or white,.5) end
  shape(.4,.4,.2,.2,Color3.fromRGB(250,250,250),.5)
 end
 return root
end
return I
]========]},
{name="HudStats",before=[========[local H={}
local Icons=require(script.Parent:WaitForChild("HudIcons"))
function H.new(gui)
 local root=Instance.new("Frame") root.Name="LobbyStats" root:SetAttribute("BottomHud",true) root.AnchorPoint=Vector2.new(0,1)
 root.Position=UDim2.new(0,8,1,-8) root.Size=UDim2.fromOffset(240,82) root.BackgroundTransparency=1 root.Parent=gui
 local function label(name,y,color)
  local n=Instance.new("TextLabel") n.Name=name n.Position=UDim2.fromOffset(48,y) n.Size=UDim2.fromOffset(186,40) n.BackgroundTransparency=1
  n.Text="0" n.TextColor3=color n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0 n.Font=Enum.Font.GothamBlack n.TextSize=30 n.TextXAlignment=Enum.TextXAlignment.Left n.Parent=root return n
 end
 local count=label("BagCount",0,Color3.new(1,1,1));local money=label("MoneyCount",42,Color3.fromRGB(54,255,9))
 local cash=Icons.draw(root,"Money",40) cash.Position=UDim2.fromOffset(0,42)
 local face=Instance.new("ImageLabel") face.Name="MossratFace" face.Size=UDim2.fromOffset(40,40) face.BackgroundTransparency=1 face.Parent=root
 local package=game.ReplicatedStorage.RodeoFantasy
 face.Image=Icons.imageId(package,"MossratFaceImage")
 -- Native fallback until the prepared transparent PNG is uploaded once.
 local fallback=Instance.new("Frame") fallback.Name="FaceFallback" fallback.BackgroundTransparency=1 fallback.Size=UDim2.fromScale(1,1) fallback.Visible=face.Image=="" fallback.Parent=face
 for _,v in ipairs({{.02,.03,.32,.6},{.66,.03,.32,.6},{.2,.28,.6,.65}}) do
  local f=Instance.new("Frame") f.Position=UDim2.fromScale(v[1],v[2]) f.Size=UDim2.fromScale(v[3],v[4]) f.BackgroundColor3=Color3.fromRGB(141,201,56) f.BorderSizePixel=0 f.Parent=fallback
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(.3,0) c.Parent=f
 end
 for _,x in ipairs({.33,.6}) do local eye=Instance.new("Frame") eye.Position=UDim2.fromScale(x,.5) eye.Size=UDim2.fromScale(.12,.17) eye.BackgroundColor3=Color3.fromRGB(36,30,21) eye.BorderSizePixel=0 eye.Parent=fallback end
 local function showFace() fallback.Visible=not face.IsLoaded end
 face:GetPropertyChangedSignal("IsLoaded"):Connect(showFace)
 game.ReplicatedStorage.RodeoFantasy:GetAttributeChangedSignal("MossratFaceImage"):Connect(function()
  face.Image=Icons.imageId(package,"MossratFaceImage") showFace()
 end)
 showFace()
 local function short(n)
  n=math.max(0,tonumber(n) or 0)
  for _,v in ipairs({{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do if n>=v[1] then return string.format("%.1f%s",n/v[1],v[2]):gsub("%.0([KMB])","%1") end end
  return tostring(math.floor(n))
 end
 return {state=function(data) count.Text=short(data.count) money.Text="$"..short((data.balance or 0)+(data.pending or 0)) end}
end
return H
]========],after=[========[local H={}
local Icons=require(script.Parent:WaitForChild("HudIcons"))
function H.new(gui)
 local root=Instance.new("Frame") root.Name="LobbyStats" root:SetAttribute("BottomHud",true) root.AnchorPoint=Vector2.new(0,1)
 root.Position=UDim2.new(0,8,1,-8) root.Size=UDim2.fromOffset(240,82) root.BackgroundTransparency=1 root.Parent=gui
 local function label(name,y,color)
  local n=Instance.new("TextLabel") n.Name=name n.Position=UDim2.fromOffset(48,y) n.Size=UDim2.fromOffset(186,40) n.BackgroundTransparency=1
  n.Text="0" n.TextColor3=color n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0 n.Font=Enum.Font.GothamBlack n.TextSize=30 n.TextXAlignment=Enum.TextXAlignment.Left n.Parent=root return n
 end
 local count=label("BagCount",0,Color3.new(1,1,1));local money=label("MoneyCount",42,Color3.fromRGB(54,255,9))
 local cash=Icons.draw(root,"Money",40) cash.Position=UDim2.fromOffset(0,42)
 Icons.bindArtwork(cash,"MoneyImage")
 local face=Instance.new("ImageLabel") face.Name="MossratFace" face.Size=UDim2.fromOffset(40,40) face.BackgroundTransparency=1 face.Parent=root
 local package=game.ReplicatedStorage.RodeoFantasy
 face.Image=Icons.imageId(package,"MossratFaceImage")
 -- Native fallback until the prepared transparent PNG is uploaded once.
 local fallback=Instance.new("Frame") fallback.Name="FaceFallback" fallback.BackgroundTransparency=1 fallback.Size=UDim2.fromScale(1,1) fallback.Visible=face.Image=="" fallback.Parent=face
 for _,v in ipairs({{.02,.03,.32,.6},{.66,.03,.32,.6},{.2,.28,.6,.65}}) do
  local f=Instance.new("Frame") f.Position=UDim2.fromScale(v[1],v[2]) f.Size=UDim2.fromScale(v[3],v[4]) f.BackgroundColor3=Color3.fromRGB(141,201,56) f.BorderSizePixel=0 f.Parent=fallback
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(.3,0) c.Parent=f
 end
 for _,x in ipairs({.33,.6}) do local eye=Instance.new("Frame") eye.Position=UDim2.fromScale(x,.5) eye.Size=UDim2.fromScale(.12,.17) eye.BackgroundColor3=Color3.fromRGB(36,30,21) eye.BorderSizePixel=0 eye.Parent=fallback end
 local function showFace() fallback.Visible=not face.IsLoaded end
 face:GetPropertyChangedSignal("IsLoaded"):Connect(showFace)
 game.ReplicatedStorage.RodeoFantasy:GetAttributeChangedSignal("MossratFaceImage"):Connect(function()
  face.Image=Icons.imageId(package,"MossratFaceImage") showFace()
 end)
 showFace()
 task.spawn(function()
  while face.Parent do showFace() task.wait(.5) end
 end)
 local function short(n)
  n=math.max(0,tonumber(n) or 0)
  for _,v in ipairs({{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do if n>=v[1] then return string.format("%.1f%s",n/v[1],v[2]):gsub("%.0([KMB])","%1") end end
  return tostring(math.floor(n))
 end
 return {state=function(data) count.Text=short(data.count) money.Text="$"..short((data.balance or 0)+(data.pending or 0)) end}
end
return H
]========]},
}
local function normal(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 local parent=(c.name=="CaptureClient" or c.name=="HudIcons" or c.name=="HudStats") and game.StarterPlayer.StarterPlayerScripts or game.ServerScriptService
 c.node=assert(parent:FindFirstChild(c.name),c.name.." 없음")
 assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"코드 불일치: "..c.name)
end
local backup=Instance.new("Folder") backup.Name="LobbyPolishBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby polish")
for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
local appearance=game.ServerScriptService:FindFirstChild("LobbyAppearance")
if appearance then appearance:Clone().Parent=backup else appearance=Instance.new("ModuleScript") appearance.Name="LobbyAppearance" appearance.Parent=game.ServerScriptService end
appearance.Source=[========[-- Lobby roof and owner labels; personal rooms deliberately remain open above.
local M={}
local function part(parent,name,size,cf,color,material)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material
 p.Anchored=true p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Reflectance=0 p.Parent=parent return p
end
function M.ensure(lobby)
 local roof=lobby:FindFirstChild("Roof")
 if not roof then roof=Instance.new("Model") roof.Name="Roof" roof.Parent=lobby end
 if not roof:FindFirstChild("FullGlassCeiling") then
  local glass=part(roof,"FullGlassCeiling",Vector3.new(512,2,512),CFrame.new(6000,102,0),Color3.fromRGB(173,212,232),Enum.Material.Glass)
  glass.Transparency=.9 glass.CastShadow=false
 end
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  if not room:FindFirstChild("OwnerBoard") then
   local base=room.RoomBase
   local origin=CFrame.new(base.Position.X,base.Position.Y+base.Size.Y/2,base.Position.Z)*base.CFrame.Rotation
   local board=part(room,"OwnerBoard",Vector3.new(28,5,1),origin*CFrame.new(0,34,-39),Color3.fromRGB(18,30,49),Enum.Material.SmoothPlastic)
   board.CanCollide=false
   local gui=Instance.new("SurfaceGui") gui.Name="OwnerName" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(840,150) gui.Parent=board
   local label=Instance.new("TextLabel") label.Name="Text" label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
   label.Text="" label.TextSize=68 label.Font=Enum.Font.GothamBold label.TextColor3=Color3.fromRGB(163,227,255) label.Parent=gui
  end
 end
 local planet=lobby:FindFirstChild("CeilingPlanet")
 if planet and not lobby:FindFirstChild("PlanetAura") then
  local aura=Instance.new("Model") aura.Name="PlanetAura" aura.Parent=lobby
  local box=planet:GetBoundingBox()
  for i,size in ipairs({250,272,294}) do
   local glow=part(aura,"VioletHalo"..i,Vector3.one*size,CFrame.new(box.Position),Color3.fromRGB(151,58,255),Enum.Material.Neon)
   glow.Shape=Enum.PartType.Ball glow.Transparency=({.9,.96,.98})[i]
   glow.CanCollide=false glow.CanQuery=false glow.CastShadow=false
  end
 end
end
return M
]========]
local promptSource=[========[-- A screen button avoids placing a large prompt over the companion model.
local M={}
function M.new(gui,player)
 local UIS=game:GetService("UserInputService")
 local service=game:GetService("ProximityPromptService")
 local current,held,connections=nil,nil,{}
 local button=Instance.new("TextButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,0,1,-100) button.Size=UDim2.fromOffset(150,48)
 button.BackgroundColor3=Color3.fromRGB(34,45,64) button.TextColor3=Color3.new(1,1,1) button.Font=Enum.Font.GothamBold
 button.TextSize=18 button.ZIndex=10 button.Parent=gui
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=button
 local bar=Instance.new("Frame") bar.Name="HoldProgress" bar.Size=UDim2.new(0,0,0,4) bar.Position=UDim2.new(0,0,1,-4)
 bar.BackgroundColor3=Color3.fromRGB(184,121,255) bar.BorderSizePixel=0 bar.ZIndex=11 bar.Parent=button
 local tween
 local function reset()
  if tween then tween:Cancel() tween=nil end bar.Size=UDim2.new(0,0,0,4)
 end
 local function hide()
  if held and current then current:InputHoldEnd() end held=nil current=nil button.Visible=false reset()
  for _,c in ipairs(connections) do c:Disconnect() end table.clear(connections)
 end
 service.PromptShown:Connect(function(prompt)
  if prompt.Name~="PetOwnCompanion" then return end
  local model=prompt:FindFirstAncestorOfClass("Model")
  if not model or model:GetAttribute("OwnerUserId")~=player.UserId then prompt.Enabled=false return end
  hide() current=prompt button.Visible=true button.Text=UIS.TouchEnabled and "교감 · 꾹 누르기" or "교감 · E 꾹"
  table.insert(connections,prompt.PromptButtonHoldBegan:Connect(function()
   reset() tween=game:GetService("TweenService"):Create(bar,TweenInfo.new(prompt.HoldDuration,Enum.EasingStyle.Linear),{Size=UDim2.new(1,0,0,4)}) tween:Play()
  end))
  table.insert(connections,prompt.PromptButtonHoldEnded:Connect(reset))
  table.insert(connections,prompt.Triggered:Connect(reset))
 end)
 service.PromptHidden:Connect(function(prompt) if current==prompt then hide() end end)
 button.InputBegan:Connect(function(input)
  if current and not held and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then held=input current:InputHoldBegin() end
 end)
 UIS.InputEnded:Connect(function(input) if input==held then if current then current:InputHoldEnd() end held=nil end end)
 UIS.WindowFocusReleased:Connect(function() if held and current then current:InputHoldEnd() end held=nil reset() end)
 gui.Destroying:Connect(hide)
end
return M
]========]
local promptUI=game.StarterPlayer.StarterPlayerScripts:FindFirstChild("PetPromptUI")
if promptUI then assert(normal(promptUI.Source)==normal(promptSource),"PetPromptUI 코드 불일치") else promptUI=Instance.new("ModuleScript") promptUI.Name="PetPromptUI" promptUI.Source=promptSource promptUI.Parent=game.StarterPlayer.StarterPlayerScripts end
local apply=(function()
-- Lobby roof and owner labels; personal rooms deliberately remain open above.
local M={}
local function part(parent,name,size,cf,color,material)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material
 p.Anchored=true p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Reflectance=0 p.Parent=parent return p
end
function M.ensure(lobby)
 local roof=lobby:FindFirstChild("Roof")
 if not roof then roof=Instance.new("Model") roof.Name="Roof" roof.Parent=lobby end
 if not roof:FindFirstChild("FullGlassCeiling") then
  local glass=part(roof,"FullGlassCeiling",Vector3.new(512,2,512),CFrame.new(6000,102,0),Color3.fromRGB(173,212,232),Enum.Material.Glass)
  glass.Transparency=.9 glass.CastShadow=false
 end
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  if not room:FindFirstChild("OwnerBoard") then
   local base=room.RoomBase
   local origin=CFrame.new(base.Position.X,base.Position.Y+base.Size.Y/2,base.Position.Z)*base.CFrame.Rotation
   local board=part(room,"OwnerBoard",Vector3.new(28,5,1),origin*CFrame.new(0,34,-39),Color3.fromRGB(18,30,49),Enum.Material.SmoothPlastic)
   board.CanCollide=false
   local gui=Instance.new("SurfaceGui") gui.Name="OwnerName" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(840,150) gui.Parent=board
   local label=Instance.new("TextLabel") label.Name="Text" label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
   label.Text="" label.TextSize=68 label.Font=Enum.Font.GothamBold label.TextColor3=Color3.fromRGB(163,227,255) label.Parent=gui
  end
 end
 local planet=lobby:FindFirstChild("CeilingPlanet")
 if planet and not lobby:FindFirstChild("PlanetAura") then
  local aura=Instance.new("Model") aura.Name="PlanetAura" aura.Parent=lobby
  local box=planet:GetBoundingBox()
  for i,size in ipairs({250,272,294}) do
   local glow=part(aura,"VioletHalo"..i,Vector3.one*size,CFrame.new(box.Position),Color3.fromRGB(151,58,255),Enum.Material.Neon)
   glow.Shape=Enum.PartType.Ball glow.Transparency=({.9,.96,.98})[i]
   glow.CanCollide=false glow.CanQuery=false glow.CastShadow=false
  end
 end
end
return M

end)()
apply.ensure(lobby)
local oldSpace=lobby:FindFirstChild("OverheadSpace") if oldSpace then oldSpace.Parent=backup end
if not lobby:FindFirstChild("BlackSpaceSphere") then
 local outer=Instance.new("Part") outer.Shape=Enum.PartType.Ball outer.Size=Vector3.one*1600 outer.Position=Vector3.new(6000,150,0)
 local inner=outer:Clone() inner.Size=Vector3.one*1580
 local ok,result=pcall(function() return game:GetService("GeometryService"):SubtractAsync(outer,{inner}) end)
 outer:Destroy() inner:Destroy() assert(ok,tostring(result))
 for _,n in ipairs(result) do n.Name="BlackSpaceSphere" n.UsePartColor=true n.Anchored=true n.CanCollide=false n.CanTouch=false n.CanQuery=false n.CastShadow=false n.Color=Color3.new(0,0,0) n.Material=Enum.Material.Neon n.Parent=lobby end
end
if lobby.BlackSpaceSphere:IsA("UnionOperation") then lobby.BlackSpaceSphere.UsePartColor=true end
local rankings=(function()
local M={}
local mirrored=setmetatable({},{__mode="k"})
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
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,17,24))*CFrame.Angles(0,math.pi/2,0)
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
  local back=board:FindFirstChild("RankingBack")
  if not back then back=gui:Clone() back.Name="RankingBack" back.Parent=board end
  back.Face=Enum.NormalId.Back
  back.Heading.Text=gui.Heading.Text back.Entries.Text=gui.Entries.Text
  if not mirrored[board] then
   mirrored[board]=true
   gui.Entries:GetPropertyChangedSignal("Text"):Connect(function() back.Entries.Text=gui.Entries.Text end)
   gui.Heading:GetPropertyChangedSignal("Text"):Connect(function() back.Heading.Text=gui.Heading.Text end)
  end
 end
 return boards
end
return M

end)()
for _,n in ipairs(lobby.Leaderboards:GetChildren()) do n:Clone().Parent=backup end
rankings.ensure(lobby)
local package=game.ReplicatedStorage.RodeoFantasy
local ids={ShopButtonImage="135776139567636",RouletteButtonImage="103655794024864",IndexButtonImage="135277525783308",EggButtonImage="87551432940862",PawButtonImage="85966265063532",MossratFaceImage="87383094549038",MoneyImage="71604722538432"}
for key,id in pairs(ids) do package:SetAttribute(key,"rbxassetid://"..id) end
lobby:SetAttribute("LobbyPolishInstalled",true)
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby polish installed")
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(6000,48,-90),Vector3.new(6000,260,60))
workspace.CurrentCamera.Focus=CFrame.new(6000,260,60)
print("LOBBY_POLISH_INSTALLED — 이름·유리천장·검은구·보라오라·이미지7개·카메라·펫·양면랭킹")
end
