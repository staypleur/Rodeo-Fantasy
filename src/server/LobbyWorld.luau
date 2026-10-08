local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,4,120)
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
 label(index," ")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=16
end
local departed={}
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="Fly to hunt" prompt.ObjectText="Airship"
 prompt.HoldDuration=0.3 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false
 prompt.Parent=Lobby.Departure
 game:GetService("RunService").Heartbeat:Connect(function()
  for player in pairs(owned) do
   local close=Lobby.canDepart(player)
   if close and not departed[player] then departed[player]=true callback(player) end
   if not close then departed[player]=nil end
  end
 end)
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
