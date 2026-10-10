-- Lobby entries only; products, odds and rewards remain undecided.
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
