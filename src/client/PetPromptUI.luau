-- Nearby companion image uses a single click/tap, with server ownership checks.
local M={}
function M.new(gui,player)
 local service=game:GetService("ProximityPromptService")
 local package=game.ReplicatedStorage.RodeoFantasy
 local current
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,0,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local function hide() current=nil button.Visible=false end
 service.PromptShown:Connect(function(prompt)
  if prompt.Name~="PetOwnCompanion" then return end
  local model=prompt:FindFirstAncestorOfClass("Model")
  if not model or model:GetAttribute("OwnerUserId")~=player.UserId then return end
  current=prompt button.Visible=true
 end)
 service.PromptHidden:Connect(function(prompt) if current==prompt then hide() end end)
 button.Activated:Connect(function()
  local model=current and current:FindFirstAncestorOfClass("Model")
  if model then package.CaptureRemote:FireServer("BondPet",model:GetAttribute("BagItemId")) end
 end)
 gui.Destroying:Connect(hide)
end
return M
