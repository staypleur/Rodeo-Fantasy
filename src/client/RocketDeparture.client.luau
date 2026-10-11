local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local remote=package:WaitForChild("CaptureRemote")
local Catalog=require(package:WaitForChild("MonsterCatalog"))
local L=require(package:WaitForChild("Localization"))
local Planets=require(package:WaitForChild("PlanetCatalog"))
local function make(class,props,parent)
 local p=Instance.new(class) for key,value in pairs(props) do p[key]=value end p.Parent=parent return p
end
local gui=make("ScreenGui",{Name="RocketDepartureUI",ResetOnSpawn=false,DisplayOrder=40,Enabled=false},player:WaitForChild("PlayerGui"))
require(script.Parent:WaitForChild("LocalizationController")).watch(gui)
local overlay=make("TextButton",{Size=UDim2.fromScale(1,1),Text="",AutoButtonColor=false,Modal=true,BackgroundColor3=Color3.fromRGB(5,14,24),BackgroundTransparency=.15},gui)
local panel=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.94,.9),BackgroundColor3=Color3.fromRGB(8,22,52)},overlay)
make("UISizeConstraint",{MaxSize=Vector2.new(740,820)},panel)
make("UICorner",{CornerRadius=UDim.new(0,28)},panel)
make("UIStroke",{Color=Color3.fromRGB(57,130,216),Thickness=2},panel)
make("ImageLabel",{Position=UDim2.fromOffset(18,8),Size=UDim2.fromOffset(48,48),Image=Planets.GreenStar.Image,ScaleType=Enum.ScaleType.Fit,BackgroundTransparency=1},panel)
local title=make("TextLabel",{Position=UDim2.fromOffset(74,12),Size=UDim2.new(1,-144,0,40),Text="Planets",TextXAlignment=Enum.TextXAlignment.Left,TextSize=32,TextColor3=Color3.fromRGB(220,249,243),Font=Enum.Font.GothamBold,BackgroundTransparency=1},panel)
local close=make("TextButton",{Position=UDim2.new(1,-60,0,8),Size=UDim2.fromOffset(48,48),Text="×",TextSize=30,BackgroundColor3=Color3.fromRGB(35,65,78),TextColor3=Color3.new(1,1,1)},panel)
make("UICorner",{CornerRadius=UDim.new(0,12)},close)
make("UIStroke",{Color=Color3.fromRGB(67,141,213),Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},close)
local hint=make("TextLabel",{Position=UDim2.fromOffset(16,58),Size=UDim2.new(1,-32,0,48),Text="",TextSize=16,TextWrapped=true,BackgroundTransparency=1,TextColor3=Color3.fromRGB(199,222,221)},panel)
local list=make("ScrollingFrame",{Position=UDim2.fromOffset(16,112),Size=UDim2.new(1,-32,1,-232),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=8,BackgroundTransparency=1,BorderSizePixel=0},panel)
local layout=make("UIGridLayout",{CellPadding=UDim2.fromOffset(14,14),SortOrder=Enum.SortOrder.LayoutOrder,FillDirectionMaxCells=2,HorizontalAlignment=Enum.HorizontalAlignment.Center},list)
make("UIPadding",{PaddingTop=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},list)
local status=make("TextLabel",{Position=UDim2.new(0,16,1,-112),Size=UDim2.new(1,-32,0,48),Text="",TextWrapped=true,TextSize=16,BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,213,146)},panel)
local nextButton=make("TextButton",{Position=UDim2.new(0,16,1,-60),Size=UDim2.new(1,-32,0,48),Text="Next",TextSize=20,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(10,31,41),BackgroundColor3=Color3.fromRGB(92,216,182)},panel)
make("UICorner",{CornerRadius=UDim.new(0,12)},nextButton)
local function fit()
 hint.Visible=false
 list.Position=UDim2.fromOffset(20,66)
 list.Size=UDim2.new(1,-40,1,-148)
 local width=math.max(100,math.min((panel.AbsoluteSize.X-68)/2,(panel.AbsoluteSize.Y-172)/2))
 layout.CellSize=UDim2.fromOffset(width,width)
 status.Position=UDim2.new(0,20,1,-78)
 status.Size=UDim2.new(1,-40,0,22)
 status.TextSize=13
 nextButton.Position=UDim2.new(0,20,1,-54)
 nextButton.Size=UDim2.new(1,-40,0,44)
end
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local messages={MenuExpired="Selection expired. Hold E at the rocket again.",ApproachRocket="Try again near the rocket.",ModelPending="This monster model is coming soon.",CoursePending="This hunt is coming soon.",MonsterBusy="This monster is busy.",NotOwned="Your inventory changed. Please select again.",LaunchFailed="Unable to prepare the hunt. Please try again."}
local menu,step,selected,busy=nil,1,nil,false
local selectedPlanet
local rows={}
local function clear()
 for _,row in ipairs(rows) do row:Destroy() end rows={}
end
local function button(text,order,callback)
 local b=make("TextButton",{Size=UDim2.new(1,-8,0,60),Text=text,TextSize=18,TextWrapped=true,Font=Enum.Font.GothamMedium,TextColor3=Color3.fromRGB(229,242,238),BackgroundColor3=Color3.fromRGB(18,36,64),LayoutOrder=order},list)
 make("UICorner",{CornerRadius=UDim.new(0,22)},b)
 b.Activated:Connect(callback) table.insert(rows,b) return b
end
local function hide(cancel)
 if cancel and menu then remote:FireServer("CancelDeparture") end
 gui.Enabled=false menu=nil busy=false clear()
end
close.Activated:Connect(function() hide(true) end)
nextButton.Activated:Connect(function()
 if not menu or busy then return end
 if not selected then status.Text="Select a planet." return end
 if not Planets[selected].Available then status.Text="Coming soon" return end
 busy=true status.Text="Preparing hunt…"
 local launchMenu=menu
 remote:FireServer("LaunchSelection",{token=menu.token,planet=selected})
 task.delay(8,function()
  if gui.Enabled and menu==launchMenu and busy then busy=false status.Text="Please try again." end
 end)
end)
UIS.InputBegan:Connect(function(input,processed)
 if not processed and gui.Enabled and input.KeyCode==Enum.KeyCode.Escape then hide(true) end
end)
player.CharacterRemoving:Connect(function() hide(true) end)
remote.OnClientEvent:Connect(function(action,data)
 if action=="DepartureMenu" then
  menu=data step=1 selected=nil busy=false gui.Enabled=true clear() list.CanvasPosition=Vector2.zero
  title.Text="Planets" hint.Text=""
  nextButton.Text="Next" status.Text=""
  for index,id in ipairs(Planets.Order) do
   local planet=Planets[id] local b
   b=button("",index,function()
    if busy then return end selected=id
    for _,row in ipairs(rows) do row.BackgroundColor3=Color3.fromRGB(18,36,64) row.Outline.Thickness=2 row.Outline.Color=row:GetAttribute("Accent") end
    b.BackgroundColor3=Color3.fromRGB(7,67,71) b.Outline.Thickness=5 b.Outline.Color=Color3.fromRGB(87,255,222) status.Text=""
   end)
   b.Name="Planet_"..id
   local accents={GreenStar=Color3.fromRGB(92,242,206),Zephyrus=Color3.fromRGB(247,201,107),Phyto=Color3.fromRGB(89,221,173),Celestia=Color3.fromRGB(180,137,252)}
   b:SetAttribute("Accent",accents[id])
   make("UIStroke",{Name="Outline",Color=accents[id],Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
   make("UIGradient",{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(145,180,235))},b)
   make("ImageLabel",{Name=id.."Artwork",Image=planet.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.05,.02),Size=UDim2.fromScale(.90,.80),ScaleType=Enum.ScaleType.Fit},b)
   make("TextLabel",{Name="PlanetLabel",Text=planet.Name,BackgroundTransparency=1,Position=UDim2.fromScale(.05,.82),Size=UDim2.fromScale(.90,.14),TextScaled=true,TextWrapped=true,Font=Enum.Font.GothamBold,TextColor3=accents[id]},b)
  end
 elseif action=="DepartureResult" and gui.Enabled then
  busy=false
  if data.ok then hide(false) else status.Text=messages[data.reason] or "Unable to depart. Please select again." end
 elseif action=="State" and data.area=="Hunt" then hide(false) end
end)
