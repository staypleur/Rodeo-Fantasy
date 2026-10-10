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
local panel=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.94,.9),BackgroundColor3=Color3.fromRGB(17,38,54)},overlay)
make("UISizeConstraint",{MaxSize=Vector2.new(700,600)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local title=make("TextLabel",{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-80,0,40),Text="Planets",TextXAlignment=Enum.TextXAlignment.Left,TextSize=24,TextColor3=Color3.fromRGB(220,249,243),Font=Enum.Font.GothamBold,BackgroundTransparency=1},panel)
local close=make("TextButton",{Position=UDim2.new(1,-60,0,8),Size=UDim2.fromOffset(48,48),Text="×",TextSize=30,BackgroundColor3=Color3.fromRGB(35,65,78),TextColor3=Color3.new(1,1,1)},panel)
local hint=make("TextLabel",{Position=UDim2.fromOffset(16,58),Size=UDim2.new(1,-32,0,48),Text="",TextSize=16,TextWrapped=true,BackgroundTransparency=1,TextColor3=Color3.fromRGB(199,222,221)},panel)
local list=make("ScrollingFrame",{Position=UDim2.fromOffset(16,112),Size=UDim2.new(1,-32,1,-232),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=8,BackgroundTransparency=1,BorderSizePixel=0},panel)
local layout=make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},list)
local status=make("TextLabel",{Position=UDim2.new(0,16,1,-112),Size=UDim2.new(1,-32,0,48),Text="",TextWrapped=true,TextSize=16,BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,213,146)},panel)
local nextButton=make("TextButton",{Position=UDim2.new(0,16,1,-60),Size=UDim2.new(1,-32,0,48),Text="Next",TextSize=20,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(10,31,41),BackgroundColor3=Color3.fromRGB(92,216,182)},panel)
local function fit()
 local compact=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<430
 hint.Position=UDim2.fromOffset(16,58)
 hint.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 list.Position=UDim2.fromOffset(16,60)
 list.Size=UDim2.new(1,-32,1,compact and -152 or -180)
 status.Position=UDim2.new(0,16,1,compact and -88 or -112)
 status.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 nextButton.Position=UDim2.new(0,16,1,compact and -52 or -60)
 nextButton.Size=UDim2.new(1,-32,0,compact and 44 or 48)
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
 local b=make("TextButton",{Size=UDim2.new(1,-8,0,60),Text=text,TextSize=18,TextWrapped=true,Font=Enum.Font.GothamMedium,TextColor3=Color3.fromRGB(229,242,238),BackgroundColor3=Color3.fromRGB(35,69,82),LayoutOrder=order},list)
 make("UICorner",{CornerRadius=UDim.new(0,8)},b)
 b.Activated:Connect(callback) table.insert(rows,b) return b
end
local function hide(cancel)
 if cancel and menu then remote:FireServer("CancelDeparture") end
 gui.Enabled=false menu=nil busy=false clear()
end
local function chooseMonster()
 step=2 selected=nil clear() list.CanvasPosition=Vector2.zero
 title.Text="Choose Your Mount" hint.Text=""
 nextButton.Text="Next" status.Text="Select one monster."
 if #menu.items==0 then status.Text="No monsters available." end
 for index,item in ipairs(menu.items) do
  local id=item.monsterId
  local name=L.text(id,"en-us")
  local b
  b=button(name.." · "..tostring(item.stars).."★"..(item.ready and "" or " · Coming soon"),index,function()
   if busy then return end
   if not item.ready then status.Text=messages[item.reason] or "Unavailable." return end
   selected=item.id status.Text=name
   for _,row in ipairs(rows) do row.BackgroundColor3=Color3.fromRGB(35,69,82) end
   b.BackgroundColor3=Color3.fromRGB(47,125,112)
  end)
 end
end
close.Activated:Connect(function() hide(true) end)
nextButton.Activated:Connect(function()
 if not menu or busy then return end
 if step==1 then
  if not selected then status.Text="Select a planet." return end
  if not Planets[selected].Available then status.Text="Coming soon" return end
  selectedPlanet=selected
  chooseMonster()
 elseif selected then
  busy=true status.Text="Preparing hunt…"
  local launchMenu=menu
  remote:FireServer("LaunchSelection",{token=menu.token,planet=selectedPlanet,itemId=selected})
  task.delay(8,function()
   if gui.Enabled and menu==launchMenu and busy then busy=false status.Text="Waiting for a response. Try again or close this window." end
  end)
 end
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
    for _,row in ipairs(rows) do row.BackgroundColor3=Color3.fromRGB(35,69,82) end
    b.BackgroundColor3=Color3.fromRGB(47,125,112) status.Text=""
   end)
   b.Name="Planet_"..id b.Size=UDim2.new(1,-8,0,100)
   make("ImageLabel",{Name=id.."Artwork",Image=planet.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.02,.04),Size=UDim2.fromScale(.30,.92),ScaleType=Enum.ScaleType.Fit},b)
   make("TextLabel",{Name="PlanetLabel",Text=planet.Name,BackgroundTransparency=1,Position=UDim2.fromScale(.34,.1),Size=UDim2.fromScale(.64,.8),TextScaled=true,TextWrapped=true,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1)},b)
  end
 elseif action=="DepartureResult" and gui.Enabled then
  busy=false
  if data.ok then hide(false) else status.Text=messages[data.reason] or "Unable to depart. Please select again." end
 elseif action=="State" and data.area=="Hunt" then hide(false) end
end)
