-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,0,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoLobby")
  local folder=map and map:FindFirstChild("LobbyCompanions")
  local pet=folder and folder:FindFirstChild("Companion_"..player.UserId)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if pet and root and pet.PrimaryPart and pet:GetAttribute("OwnerUserId")==player.UserId
   and (root.Position-pet.PrimaryPart.Position).Magnitude<=10 then return pet end
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  current=nearby() button.Visible=current~=nil
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() current=nil end)
end
return M
