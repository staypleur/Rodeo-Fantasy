local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,4,-60)
function Lobby.prepareCharacter(character)
 if not character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed end
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
