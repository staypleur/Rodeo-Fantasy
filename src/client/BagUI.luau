local UI={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local template=game.ReplicatedStorage.RodeoFantasy.VisualTemplate
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamBold end
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
function UI.new(gui,remote)
 local self={area="Lobby",items={},count=-1}
 local button=make("TextButton",{Name="OpenBag",Text="Bag [R]",Size=UDim2.fromOffset(110,44),Position=UDim2.new(1,-125,1,-60),BackgroundColor3=Color3.fromRGB(72,112,92),TextColor3=Color3.new(1,1,1),TextSize=18},gui)
 make("UICorner",{CornerRadius=UDim.new(0,12)},button)
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.8,.75),BackgroundColor3=Color3.fromRGB(249,242,222),ZIndex=20},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(760,580)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="Close",Position=UDim2.new(1,-90,0,12),Size=UDim2.fromOffset(75,34),ZIndex=21},window)
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(1,-40,0,34),TextSize=20,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,100),Size=UDim2.new(1,-32,1,-116),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,210),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 function self.toggle()
  if self.area~="Lobby" then return end
  window.Visible=not window.Visible
  if window.Visible then remote:FireServer("Bag") end
 end
 button.Activated:Connect(self.toggle)
 close.Activated:Connect(function() window.Visible=false end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.R then self.toggle() end
 end)
 function self.state(state)
  self.area=state.area
  button.Visible=state.area=="Lobby"
  if state.area~="Lobby" then window.Visible=false end
  money.Text=L.text("Uncollected coins",player.LocaleId)..": "..tostring(state.pending or 0)
  button.Text=L.text("Bag",player.LocaleId).." [R]"
  if state.area=="Lobby" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.snapshot(items)
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  empty.Visible=#items==0
  for index,item in ipairs(items) do
   local card=make("Frame",{Name="MonsterCard",Size=UDim2.fromOffset(170,210),BackgroundColor3=Color3.fromRGB(225,237,213),ZIndex=22,LayoutOrder=index},scroll)
   make("UICorner",{CornerRadius=UDim.new(0,12)},card)
   local preview=make("ViewportFrame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23,Ambient=Color3.fromRGB(195,195,195),LightColor=Color3.new(1,1,1)},card)
   local world=Instance.new("WorldModel") world.Parent=preview
   local model=template:Clone() model.Parent=world model:PivotTo(CFrame.new())
   for _,node in ipairs(model:GetDescendants()) do if node:IsA("BillboardGui") then node:Destroy() end end
   local frame,size=model:GetBoundingBox()
   local camera=Instance.new("Camera") camera.FieldOfView=32
   camera.CFrame=CFrame.lookAt(frame.Position+Vector3.new(1,.55,-1.5).Unit*math.max(size.X,size.Y,size.Z)*2.3,frame.Position)
   camera.Parent=preview preview.CurrentCamera=camera
   make("TextLabel",{Text=L.text(item.monsterId,player.LocaleId).." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   make("TextLabel",{Name="Income",Text=L.income(item.incomeAmount,item.incomeSeconds,player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),TextSize=14,TextWrapped=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
  end
 end
 return self
end
return UI
