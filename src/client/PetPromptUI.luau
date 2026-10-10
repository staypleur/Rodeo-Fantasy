-- A screen button avoids placing a large prompt over the companion model.
local M={}
function M.new(gui,player)
 local UIS=game:GetService("UserInputService")
 local service=game:GetService("ProximityPromptService")
 local current,held,connections=nil,nil,{}
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,0,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local key=Instance.new("TextLabel") key.Name="BondKey" key.BackgroundTransparency=1 key.Position=UDim2.new(1,0,0,0) key.Size=UDim2.fromOffset(24,24)
 key.Text=UIS.TouchEnabled and "" or "E" key.TextSize=18 key.TextColor3=Color3.new(1,1,1) key.TextStrokeTransparency=0 key.ZIndex=11 key.Parent=button
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
  hide() current=prompt button.Visible=true
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
