-- Lobby entries only; products, odds and rewards remain undecided.
local M={}
function M.new(gui,bag,journal,remote)
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
 local Icons=require(script.Parent:WaitForChild("HudIcons"))
 for i,entry in ipairs({{"OpenShop","Shop","Shop · Coming soon"},{"OpenRoulette","Roulette","Roulette · Coming soon"}}) do
  local color=i==1 and Color3.fromRGB(100,255,12) or Color3.fromRGB(255,191,31)
  local button=make("TextButton",{Name=entry[1],Text="",Position=UDim2.new(0,8,.42,i==1 and -26 or -90),Size=UDim2.fromOffset(64,64),BackgroundColor3=color,BorderSizePixel=0,Visible=false},gui)
  make("UICorner",{CornerRadius=UDim.new(0,5)},button)
  make("UIStroke",{Color=Color3.fromRGB(0,0,0),Thickness=2},button)
  make("UIGradient",{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(150,214,135)),Rotation=90},button)
  local icon=Icons.draw(button,i==1 and "Shop" or "Roulette",38) icon.Position=UDim2.fromOffset(8,9)
  make("TextLabel",{Text=entry[2],BackgroundTransparency=1,Position=UDim2.fromOffset(54,0),Size=UDim2.new(1,-58,1,0),Font=Enum.Font.GothamBlack,TextSize=24,TextColor3=Color3.new(1,1,1),TextStrokeColor3=Color3.new(0,0,0),TextStrokeTransparency=0},button)
  Icons.bindArtwork(button,i==1 and "ShopButtonImage" or "RouletteButtonImage")
  button.Activated:Connect(function()
   if not button.Visible then return end
   if api.onOpen then api.onOpen() end
   title.Text=entry[2] body.Text=entry[3] panel.Visible=true
  end)
  table.insert(buttons,button)
 end
 local journalButton=gui:FindFirstChild("OpenJournal")
 if journalButton then
  for _,n in ipairs(journalButton:GetChildren()) do n:Destroy() end
  journalButton.AnchorPoint=Vector2.zero journalButton.Position=UDim2.new(0,8,.42,46) journalButton.Size=UDim2.fromOffset(64,64)
  journalButton.BackgroundColor3=Color3.fromRGB(15,216,255) journalButton.BackgroundTransparency=0
  make("UICorner",{CornerRadius=UDim.new(0,5)},journalButton) make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},journalButton)
  local icon=Icons.draw(journalButton,"Journal",38) icon.Position=UDim2.fromOffset(8,9)
  make("TextLabel",{Text="Index",BackgroundTransparency=1,Position=UDim2.fromOffset(54,0),Size=UDim2.new(1,-58,1,0),Font=Enum.Font.GothamBlack,TextSize=24,TextColor3=Color3.new(1,1,1),TextStrokeColor3=Color3.new(0,0,0),TextStrokeTransparency=0},journalButton)
  Icons.bindArtwork(journalButton,"IndexButtonImage")
 end
 for i,kind in ipairs({"Egg","Paw"}) do
  local button=make("TextButton",{Name="Open"..kind,Text="",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,.42,i==1 and -26 or 38),Size=UDim2.fromOffset(56,56),BorderSizePixel=0,BackgroundColor3=i==1 and Color3.fromRGB(255,83,80) or Color3.fromRGB(255,160,54),Visible=false},gui)
  make("UICorner",{CornerRadius=UDim.new(0,5)},button) make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},button)
  local icon=Icons.draw(button,kind,42) icon.Position=UDim2.fromOffset(7,7)
  Icons.bindArtwork(button,kind.."ButtonImage")
  button.Activated:Connect(function()
   if not button.Visible then return end
   if api.onOpen then api.onOpen() end
   if kind=="Egg" then bag.openRanchMenu() else bag.openCompanionMenu() end
  end)
  table.insert(buttons,button)
 end
 local function layout()
  local camera=workspace.CurrentCamera
  local compact=camera and camera.ViewportSize.Y<420
  local factor=compact and .8 or 1
  for _,button in ipairs(buttons) do
   local scale=button:FindFirstChild("ResponsiveScale")
   if not scale then scale=make("UIScale",{Name="ResponsiveScale"},button) end
   scale.Scale=factor
   local left=button.Name=="OpenShop" or button.Name=="OpenRoulette"
   local offset=button.Name=="OpenRoulette" and -98 or button.Name=="OpenPaw" and 38 or -26
   button.Position=UDim2.new(left and 0 or 1,left and 8 or -8,compact and .36 or .42,offset*factor)
  end
  if journalButton then
   local scale=journalButton:FindFirstChild("ResponsiveScale") or make("UIScale",{Name="ResponsiveScale"},journalButton)
   scale.Scale=factor journalButton.Position=UDim2.new(0,8,compact and .36 or .42,46*factor)
  end
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
 layout()
 function api.state(data)
  local lobby=data.phase=="Idle" or data.phase=="Lobby"
  local oldBag=gui:FindFirstChild("OpenBag")
  if oldBag then oldBag.Visible=not lobby and data.area~="Hunt" end
  for _,button in ipairs(buttons) do button.Visible=lobby end
  if not lobby then api.close() end
 end
 return api
end
return M
