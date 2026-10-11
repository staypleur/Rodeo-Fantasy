assert(not game.RunService:IsRunning(),"Stop Play first")
local P=game.ReplicatedStorage.RodeoFantasy local C=game.StarterPlayer.StarterPlayerScripts local S=game.ServerScriptService
local updates={{node=C:FindFirstChild([=[BagUI]=]),before=[=[local UI={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Query=require(game.ReplicatedStorage.RodeoFantasy.CollectionQuery)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Income=require(script.Parent:WaitForChild("IncomeEffects"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamBold end
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
function UI.iconButton(gui,kind,key,right)
 local bag=kind=="Bag"
 local button=make("TextButton",{Name=bag and "OpenBag" or "OpenJournal",Text="",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-right,1,-18),Size=UDim2.fromOffset(64,64),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.08,BorderSizePixel=0},gui)
 make("UICorner",{CornerRadius=UDim.new(0,16)},button)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},button)
 local function shape(name,x,y,w,h,color,radius)
  local node=make("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,BorderSizePixel=0},button)
  make("UICorner",{CornerRadius=UDim.new(0,radius or 3)},node) return node
 end
 if bag then
  local leather=Color3.fromRGB(178,126,84)
  shape("Handle",25,10,14,12,leather,5)
  shape("Backpack",18,17,28,32,leather,8)
  shape("Pocket",23,31,18,12,Color3.fromRGB(133,88,58),4)
  shape("Clasp",30,28,4,5,Color3.fromRGB(250,213,131),1)
 else
  shape("Cover",12,15,40,32,Color3.fromRGB(178,126,84),4)
  shape("LeftPage",15,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("RightPage",33,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("Spine",31,16,2,29,Color3.fromRGB(120,91,61),1)
  for _,x in ipairs({18,36}) do for y=23,35,6 do shape("Ink",x,y,10,2,Color3.fromRGB(136,156,119),1) end end
 end
 make("TextLabel",{Name="Shortcut",Text=key,BackgroundTransparency=1,Position=UDim2.fromOffset(42,45),Size=UDim2.fromOffset(18,16),TextSize=11,TextColor3=Color3.fromRGB(246,229,193)},button)
 return button
end
function UI.new(gui,remote)
 local self={area="Lobby",items={},count=-1,pen=nil,region="All",page=1,query="",evolutionMode=false,selected={}}
 local button=UI.iconButton(gui,"Bag","R",18)
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 make("ImageLabel",{Name="BagMoneyIcon",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.fromOffset(34,34),ScaleType=Enum.ScaleType.Fit,ZIndex=21},window)
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(58,55),Size=UDim2.new(.31,-62,0,34),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=20},money)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve","en-us"),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters","en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("Frame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolvePreview)
 local evolveCancel=make("TextButton",{Name="CancelEvolution",Text=L.text("Cancel","en-us"),Position=UDim2.new(1,-194,0,12),Size=UDim2.fromOffset(80,34),TextSize=13,BackgroundColor3=Color3.fromRGB(164,139,107),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 local evolveConfirm=make("TextButton",{Name="ConfirmEvolution",Text=L.text("Evolve","en-us"),Position=UDim2.new(1,-108,0,12),Size=UDim2.fromOffset(100,34),TextSize=13,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolveCancel) make("UICorner",{CornerRadius=UDim.new(0,8)},evolveConfirm)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,245),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 local search=make("TextBox",{Name="BagSearch",PlaceholderText="Search",Text="",ClearTextOnFocus=false,Position=UDim2.new(.32,0,0,55),Size=UDim2.new(.27,0,0,34),BackgroundColor3=Color3.fromRGB(255,250,237),TextColor3=Color3.fromRGB(71,58,40),TextSize=17,ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,8)},search)
 local tabs=make("ScrollingFrame",{Name="BagRegions",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(20,136),Size=UDim2.new(1,-40,0,32),AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=0,ZIndex=23},window)
 make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)},tabs)
 local previous=make("TextButton",{Name="BagPrevious",Text="‹",BackgroundTransparency=1,Position=UDim2.new(.35,-45,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 local pageLabel=make("TextLabel",{Name="BagPage",Text="1 / 1",BackgroundTransparency=1,Position=UDim2.new(.35,0,1,-45),Size=UDim2.new(.3,0,0,30),TextSize=15,ZIndex=23},window)
 local nextPage=make("TextButton",{Name="BagNext",Text="›",BackgroundTransparency=1,Position=UDim2.new(.65,5,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 function self.filter(region,query)
  self.region,self.query,self.page=region or self.region,query or self.query,1
  self.snapshot(self.items)
 end
 for _,region in ipairs(Query.regions(Catalog)) do
  local tab=make("TextButton",{Name="Region_"..region,Text=L.text(region,"en-us"),Size=UDim2.fromOffset(112,30),BackgroundColor3=Color3.fromRGB(213,193,159),TextColor3=Color3.fromRGB(65,53,37),TextSize=15,ZIndex=24},tabs)
  make("UICorner",{CornerRadius=UDim.new(0,8)},tab)
  tab.Activated:Connect(function() self.filter(region,nil) end)
 end
 local breed=make("TextButton",{Name="Breed",Text="Breed",Position=UDim2.new(.62,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},breed)
 breed.Activated:Connect(function() if self.onBreed then self.onBreed() end end)
 local chooser
 local revision=0
 local function selectedCount() local n=0 for _ in pairs(self.selected) do n+=1 end return n end
 local function selectionAnchor()
  for id in pairs(self.selected) do
   for _,item in ipairs(self.items) do if item.id==id then return item end end
  end
 end
 local function updateEvolutionControls()
  local count=selectedCount()
  local anchor=selectionAnchor()
  if anchor then
   evolveStatus.Text=L.text(anchor.monsterId,"en-us").." · "..anchor.stars.."★  →  "..(anchor.stars+1).."★    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
   if anchor.stars<10 then Portrait.fill(evolvePreview,anchor.monsterId,anchor.stars+1,false) end
  else
   evolveStatus.Text=L.text("Select three matching monsters","en-us").."    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
  end
  evolveConfirm.Active=count==3 and anchor~=nil and anchor.stars<10
  evolveConfirm.AutoButtonColor=evolveConfirm.Active
  evolveConfirm.BackgroundColor3=evolveConfirm.Active and Color3.fromRGB(80,134,104) or Color3.fromRGB(151,159,143)
 end
 function self.setEvolutionMode(enabled)
  self.evolutionMode=enabled==true
  if not self.evolutionMode then self.selected={} end
  self.mode=nil self.pen=nil chooser.Visible=false scroll.Visible=true
  evolveControls.Visible=self.evolutionMode
  scroll.Position=UDim2.fromOffset(16,self.evolutionMode and 240 or 175)
  scroll.Size=UDim2.new(1,-32,1,self.evolutionMode and -295 or -230)
  evolveToggle.Text=self.evolutionMode and L.text("Cancel","en-us") or L.text("Evolve","en-us")
  self.snapshot(self.items)
 end
 evolveToggle.Activated:Connect(function()
  if self.area~="Hunt" and not self.pen then self.setEvolutionMode(not self.evolutionMode) end
 end)
 evolveCancel.Activated:Connect(function() self.setEvolutionMode(false) end)
 evolveConfirm.Activated:Connect(function()
  if not evolveConfirm.Active or self.area=="Hunt" then return end
  local ids={} for id in pairs(self.selected) do table.insert(ids,id) end
  table.sort(ids)
  if #ids==3 then remote:FireServer("Evolve",ids) end
 end)
 search:GetPropertyChangedSignal("Text"):Connect(function()
  revision+=1 local current=revision
  task.delay(.12,function() if revision==current then self.filter(nil,search.Text) end end)
 end)
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("Frame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,4 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="Hatchery".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Manage",index) end end)
 end
 function self.openCompanionMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="Companion" self.pen=nil chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items) window.Visible=true self.opened() title.Text="Companion · Choose one" remote:FireServer("Bag")
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="Eggs · My hatcheries"
 end
 function self.toggle()
  if self.area=="Hunt" then return end
  self.mode=nil self.pen=nil self.setEvolutionMode(false) chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items)
  window.Visible=not window.Visible
  if window.Visible then self.opened() remote:FireServer("Bag") end
 end
 button.Activated:Connect(self.toggle)
 close.Activated:Connect(self.close)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.R then self.toggle() end
 end)
 function self.state(state)
  self.area=state.area
  local nextSummoned=state.summonedId
  if self.summonedId~=nextSummoned then self.summonedId=nextSummoned self.snapshot(self.items) end
  button.Visible=state.area~="Hunt"
  if state.area=="Hunt" then window.Visible=false self.pen=nil self.setEvolutionMode(false) end
  money.Text=tostring((state.pending or 0)+(state.balance or 0))
  button.Text=""
  if state.area~="Hunt" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.openPen(index)
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode=nil chooser.Visible=false scroll.Visible=true
  self.pen=index self.snapshot(self.items) window.Visible=true self.opened()
 end
 function self.snapshot(items)
  self.items=items self.cards={}
  local present={} for _,item in ipairs(items) do present[item.id]=true end
  for id in pairs(self.selected) do if not present[id] then self.selected[id]=nil end end
  local placed=0
  for _,item in ipairs(items) do if item.assignedPen==self.pen and self.pen then placed+=1 end end
  title.Text=L.text(self.mode=="Companion" and "Companion · Choose one" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag","en-us")..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,"en-us") end)
  table.sort(filtered,function(a,b)
   if a.stars~=b.stars then return a.stars>b.stars end
   if a.monsterId~=b.monsterId then return a.monsterId<b.monsterId end
   return tostring(a.id)<tostring(b.id)
  end)
  local pages=math.max(1,math.ceil(#filtered/12)) self.page=math.clamp(self.page,1,pages)
  pageLabel.Text=self.page.." / "..pages
  local show=self.mode~="RanchMenu"
  search.Visible=show tabs.Visible=show previous.Visible=show nextPage.Visible=show pageLabel.Visible=show
  evolveToggle.Visible=show and not self.pen breed.Visible=show and not self.pen
  evolveControls.Visible=show and self.evolutionMode and not self.pen
  if self.evolutionMode then
   scroll.Position=UDim2.fromOffset(16,240) scroll.Size=UDim2.new(1,-32,1,-295)
  else
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
  end
  empty.Visible=show and #filtered==0
  empty.Text=L.text(#items==0 and "No monsters caught yet" or "No matching monsters","en-us")
  for _,tab in ipairs(tabs:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundColor3=tab.Name=="Region_"..self.region and Color3.fromRGB(167,127,79) or Color3.fromRGB(213,193,159) end end
  scroll.CanvasPosition=Vector2.zero
  for index=(self.page-1)*12+1,math.min(self.page*12,#filtered) do
   local item=filtered[index]
   local card=make("Frame",{Name="MonsterCard",Size=UDim2.fromOffset(170,245),BackgroundColor3=Color3.fromRGB(237,225,204),ZIndex=22,LayoutOrder=index},scroll)
   make("UICorner",{CornerRadius=UDim.new(0,12)},card)
   local male=item.sex=="Male" local female=item.sex=="Female"
   local color=male and Color3.fromRGB(72,130,180) or female and Color3.fromRGB(183,88,115) or Color3.fromRGB(119,109,91)
   local badge=make("Frame",{Name="SexBadge",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-7,0,6),Size=UDim2.fromOffset(30,26),Visible=male or female,BackgroundColor3=Color3.fromRGB(255,241,213),BorderSizePixel=0,ZIndex=26},card)
   make("UICorner",{CornerRadius=UDim.new(0,6)},badge)
   local offset=male and 0 or 3
   local ring=make("Frame",{Name="SexRing",Position=UDim2.fromOffset(6+offset,5),Size=UDim2.fromOffset(11,11),BackgroundTransparency=1,ZIndex=27},badge)
   make("UICorner",{CornerRadius=UDim.new(1,0)},ring) make("UIStroke",{Color=color,Thickness=2},ring)
   local function line(name,x,y,w,h,rotation)
    make("Frame",{Name=name,Position=UDim2.fromOffset(x+offset,y),Size=UDim2.fromOffset(w,h),Rotation=rotation or 0,BackgroundColor3=color,BorderSizePixel=0,ZIndex=27},badge)
   end
   if male then line("MaleStem",14,4,9,2,-45) line("ArrowTop",18,2,6,2) line("ArrowRight",22,2,2,6)
   elseif female then line("FemaleStem",10,15,2,7) line("FemaleCross",7,18,8,2) end
   self.cards[item.id]=card
   local preview=make("Frame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   local income=make("Frame",{Name="Income",BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),ZIndex=23},card)
   make("ImageLabel",{Name="Money",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.new(.5,-66,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   local amount=make("TextLabel",{Name="Amount",Text=tostring(item.incomeAmount),BackgroundTransparency=1,Position=UDim2.new(.5,-34,0,0),Size=UDim2.fromOffset(38,30),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=17},amount)
   make("ImageLabel",{Name="Clock",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"ClockImage"),BackgroundTransparency=1,Position=UDim2.new(.5,5,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Seconds",Text=tostring(item.incomeSeconds),BackgroundTransparency=1,Position=UDim2.new(.5,33,0,0),Size=UDim2.fromOffset(32,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Summon",item.id) end end)
   elseif self.pen then
    local mine=item.assignedPen==self.pen
    local allowed=mine or (not item.assignedPen and placed<2)
    local label=mine and "Return to bag" or item.assignedPen and "Placed" or placed>=2 and "Full" or "Place"
    local choose=make("TextButton",{Name="ChooseMonster",Text=L.text(label,"en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=allowed and Color3.fromRGB(80,134,104) or Color3.fromRGB(154,167,151),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if allowed and self.pen and self.area=="Lobby" then remote:FireServer(mine and "Remove" or "Place",{id=item.id,pen=self.pen}) end
    end)
   elseif self.evolutionMode then
    local anchor=selectionAnchor()
    local compatible=not anchor or (anchor.monsterId==item.monsterId and anchor.stars==item.stars)
    local selected=self.selected[item.id]==true
    if selected then
     make("UIStroke",{Name="SelectedOutline",Color=Color3.fromRGB(32,184,128),Thickness=4},card)
     make("TextLabel",{Name="SelectedCheck",Text="✓",BackgroundColor3=Color3.fromRGB(32,184,128),Position=UDim2.fromOffset(6,6),Size=UDim2.fromOffset(30,30),TextSize=24,TextColor3=Color3.new(1,1,1),ZIndex=28},card)
    end
    local choose=make("TextButton",{Name="SelectForEvolution",Text=selected and L.text("Selected","en-us") or L.text("Select","en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=selected and Color3.fromRGB(80,134,104) or compatible and Color3.fromRGB(147,182,154) or Color3.fromRGB(184,181,168),TextColor3=Color3.new(1,1,1),Active=compatible and (selected or selectedCount()<3),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if self.selected[item.id] then self.selected[item.id]=nil
     elseif compatible and selectedCount()<3 and self.area~="Hunt" then self.selected[item.id]=true end
     self.snapshot(self.items)
    end)
   elseif self.area=="Cafe" or self.area=="Lobby" then
    if item.id==self.summonedId and self.area=="Cafe" then
     make("TextLabel",{Text="Summoned",BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
    elseif not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     summon.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed","en-us").." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve","en-us")
  else
   local key=result.reason=="MaxStars" and "Already at max stars" or "Evolution failed"
   evolveStatus.Text=L.text(key,"en-us")
  end
 end
 function self.income(gains)
  if self.area=="Hunt" or not window.Visible then return end
  for _,gain in ipairs(gains or {}) do
   local card=self.cards and self.cards[gain.id]
   if card and card.Parent then Income.card(card,gain.amount) end
  end
 end
 return self
end
return UI
]=],after=[=[local UI={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Query=require(game.ReplicatedStorage.RodeoFantasy.CollectionQuery)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Income=require(script.Parent:WaitForChild("IncomeEffects"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamBold end
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
function UI.iconButton(gui,kind,key,right)
 local bag=kind=="Bag"
 local button=make("TextButton",{Name=bag and "OpenBag" or "OpenJournal",Text="",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-right,1,-18),Size=UDim2.fromOffset(64,64),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.08,BorderSizePixel=0},gui)
 make("UICorner",{CornerRadius=UDim.new(0,16)},button)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},button)
 local function shape(name,x,y,w,h,color,radius)
  local node=make("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,BorderSizePixel=0},button)
  make("UICorner",{CornerRadius=UDim.new(0,radius or 3)},node) return node
 end
 if bag then
  local leather=Color3.fromRGB(178,126,84)
  shape("Handle",25,10,14,12,leather,5)
  shape("Backpack",18,17,28,32,leather,8)
  shape("Pocket",23,31,18,12,Color3.fromRGB(133,88,58),4)
  shape("Clasp",30,28,4,5,Color3.fromRGB(250,213,131),1)
 else
  shape("Cover",12,15,40,32,Color3.fromRGB(178,126,84),4)
  shape("LeftPage",15,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("RightPage",33,17,16,26,Color3.fromRGB(249,239,211),2)
  shape("Spine",31,16,2,29,Color3.fromRGB(120,91,61),1)
  for _,x in ipairs({18,36}) do for y=23,35,6 do shape("Ink",x,y,10,2,Color3.fromRGB(136,156,119),1) end end
 end
 make("TextLabel",{Name="Shortcut",Text=key,BackgroundTransparency=1,Position=UDim2.fromOffset(42,45),Size=UDim2.fromOffset(18,16),TextSize=11,TextColor3=Color3.fromRGB(246,229,193)},button)
 return button
end
function UI.new(gui,remote)
 local self={area="Lobby",items={},count=-1,pen=nil,region="All",page=1,query="",evolutionMode=false,selected={}}
 local button=UI.iconButton(gui,"Bag","R",18)
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 make("ImageLabel",{Name="BagMoneyIcon",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.fromOffset(34,34),ScaleType=Enum.ScaleType.Fit,ZIndex=21},window)
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(58,55),Size=UDim2.new(.31,-62,0,34),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=20},money)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve","en-us"),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters","en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("Frame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolvePreview)
 local evolveCancel=make("TextButton",{Name="CancelEvolution",Text=L.text("Cancel","en-us"),Position=UDim2.new(1,-194,0,12),Size=UDim2.fromOffset(80,34),TextSize=13,BackgroundColor3=Color3.fromRGB(164,139,107),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 local evolveConfirm=make("TextButton",{Name="ConfirmEvolution",Text=L.text("Evolve","en-us"),Position=UDim2.new(1,-108,0,12),Size=UDim2.fromOffset(100,34),TextSize=13,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolveCancel) make("UICorner",{CornerRadius=UDim.new(0,8)},evolveConfirm)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,245),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 local search=make("TextBox",{Name="BagSearch",PlaceholderText="Search",Text="",ClearTextOnFocus=false,Position=UDim2.new(.32,0,0,55),Size=UDim2.new(.27,0,0,34),BackgroundColor3=Color3.fromRGB(255,250,237),TextColor3=Color3.fromRGB(71,58,40),TextSize=17,ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,8)},search)
 local tabs=make("ScrollingFrame",{Name="BagRegions",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(20,136),Size=UDim2.new(1,-40,0,32),AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=0,ZIndex=23},window)
 make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)},tabs)
 local previous=make("TextButton",{Name="BagPrevious",Text="‹",BackgroundTransparency=1,Position=UDim2.new(.35,-45,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 local pageLabel=make("TextLabel",{Name="BagPage",Text="1 / 1",BackgroundTransparency=1,Position=UDim2.new(.35,0,1,-45),Size=UDim2.new(.3,0,0,30),TextSize=15,ZIndex=23},window)
 local nextPage=make("TextButton",{Name="BagNext",Text="›",BackgroundTransparency=1,Position=UDim2.new(.65,5,1,-45),Size=UDim2.fromOffset(40,30),TextSize=24,TextColor3=Color3.fromRGB(70,58,40),ZIndex=23},window)
 function self.filter(region,query)
  self.region,self.query,self.page=region or self.region,query or self.query,1
  self.snapshot(self.items)
 end
 for _,region in ipairs(Query.regions(Catalog)) do
  local tab=make("TextButton",{Name="Region_"..region,Text=L.text(region,"en-us"),Size=UDim2.fromOffset(112,30),BackgroundColor3=Color3.fromRGB(213,193,159),TextColor3=Color3.fromRGB(65,53,37),TextSize=15,ZIndex=24},tabs)
  make("UICorner",{CornerRadius=UDim.new(0,8)},tab)
  tab.Activated:Connect(function() self.filter(region,nil) end)
 end
 local breed=make("TextButton",{Name="Breed",Text="Breed",Position=UDim2.new(.62,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},breed)
 breed.Activated:Connect(function() if self.onBreed then self.onBreed() end end)
 local chooser
 local revision=0
 local function selectedCount() local n=0 for _ in pairs(self.selected) do n+=1 end return n end
 local function selectionAnchor()
  for id in pairs(self.selected) do
   for _,item in ipairs(self.items) do if item.id==id then return item end end
  end
 end
 local function updateEvolutionControls()
  local count=selectedCount()
  local anchor=selectionAnchor()
  if anchor then
   evolveStatus.Text=L.text(anchor.monsterId,"en-us").." · "..anchor.stars.."★  →  "..(anchor.stars+1).."★    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
   if anchor.stars<10 then Portrait.fill(evolvePreview,anchor.monsterId,anchor.stars+1,false) end
  else
   evolveStatus.Text=L.text("Select three matching monsters","en-us").."    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
  end
  evolveConfirm.Active=count==3 and anchor~=nil and anchor.stars<10
  evolveConfirm.AutoButtonColor=evolveConfirm.Active
  evolveConfirm.BackgroundColor3=evolveConfirm.Active and Color3.fromRGB(80,134,104) or Color3.fromRGB(151,159,143)
 end
 function self.setEvolutionMode(enabled)
  self.evolutionMode=enabled==true
  if not self.evolutionMode then self.selected={} end
  self.mode=nil self.pen=nil chooser.Visible=false scroll.Visible=true
  evolveControls.Visible=self.evolutionMode
  scroll.Position=UDim2.fromOffset(16,self.evolutionMode and 240 or 175)
  scroll.Size=UDim2.new(1,-32,1,self.evolutionMode and -295 or -230)
  evolveToggle.Text=self.evolutionMode and L.text("Cancel","en-us") or L.text("Evolve","en-us")
  self.snapshot(self.items)
 end
 evolveToggle.Activated:Connect(function()
  if self.area~="Hunt" and not self.pen then self.setEvolutionMode(not self.evolutionMode) end
 end)
 evolveCancel.Activated:Connect(function() self.setEvolutionMode(false) end)
 evolveConfirm.Activated:Connect(function()
  if not evolveConfirm.Active or self.area=="Hunt" then return end
  local ids={} for id in pairs(self.selected) do table.insert(ids,id) end
  table.sort(ids)
  if #ids==3 then remote:FireServer("Evolve",ids) end
 end)
 search:GetPropertyChangedSignal("Text"):Connect(function()
  revision+=1 local current=revision
  task.delay(.12,function() if revision==current then self.filter(nil,search.Text) end end)
 end)
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("Frame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,4 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="Hatchery".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Manage",index) end end)
 end
 function self.openCompanionMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="Companion" self.pen=nil chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items) window.Visible=true self.opened() title.Text="Companion · Choose one" remote:FireServer("Bag")
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="Eggs · My hatcheries"
 end
 function self.toggle()
  if self.area=="Hunt" then return end
  self.mode=nil self.pen=nil self.setEvolutionMode(false) chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items)
  window.Visible=not window.Visible
  if window.Visible then self.opened() remote:FireServer("Bag") end
 end
 button.Activated:Connect(self.toggle)
 close.Activated:Connect(self.close)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.R then self.toggle() end
 end)
 function self.state(state)
  self.area=state.area
  local nextSummoned=state.summonedId
  if self.summonedId~=nextSummoned then self.summonedId=nextSummoned self.snapshot(self.items) end
  button.Visible=state.area~="Hunt"
  if state.area=="Hunt" then window.Visible=false self.pen=nil self.setEvolutionMode(false) end
  money.Text=tostring((state.pending or 0)+(state.balance or 0))
  button.Text=""
  if state.area~="Hunt" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.openPen(index)
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode=nil chooser.Visible=false scroll.Visible=true
  self.pen=index self.snapshot(self.items) window.Visible=true self.opened()
 end
 function self.snapshot(items)
  self.items=items self.cards={}
  local present={} for _,item in ipairs(items) do present[item.id]=true end
  for id in pairs(self.selected) do if not present[id] then self.selected[id]=nil end end
  local placed=0
  for _,item in ipairs(items) do if item.assignedPen==self.pen and self.pen then placed+=1 end end
  title.Text=L.text(self.mode=="Companion" and "Companion · Choose one" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag","en-us")..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,"en-us") end)
  table.sort(filtered,function(a,b)
   if a.stars~=b.stars then return a.stars>b.stars end
   if a.monsterId~=b.monsterId then return a.monsterId<b.monsterId end
   return tostring(a.id)<tostring(b.id)
  end)
  local pages=math.max(1,math.ceil(#filtered/12)) self.page=math.clamp(self.page,1,pages)
  pageLabel.Text=self.page.." / "..pages
  local show=self.mode~="RanchMenu"
  search.Visible=show tabs.Visible=show previous.Visible=show nextPage.Visible=show pageLabel.Visible=show
  evolveToggle.Visible=show and not self.pen breed.Visible=show and not self.pen
  evolveControls.Visible=show and self.evolutionMode and not self.pen
  if self.evolutionMode then
   scroll.Position=UDim2.fromOffset(16,240) scroll.Size=UDim2.new(1,-32,1,-295)
  else
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
  end
  empty.Visible=show and #filtered==0
  empty.Text=L.text(#items==0 and "No monsters caught yet" or "No matching monsters","en-us")
  for _,tab in ipairs(tabs:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundColor3=tab.Name=="Region_"..self.region and Color3.fromRGB(167,127,79) or Color3.fromRGB(213,193,159) end end
  scroll.CanvasPosition=Vector2.zero
  for index=(self.page-1)*12+1,math.min(self.page*12,#filtered) do
   local item=filtered[index]
   local card=make("Frame",{Name="MonsterCard",Size=UDim2.fromOffset(170,245),BackgroundColor3=Color3.fromRGB(237,225,204),ZIndex=22,LayoutOrder=index},scroll)
   make("UICorner",{CornerRadius=UDim.new(0,12)},card)
   local male=item.sex=="Male" local female=item.sex=="Female"
   local color=male and Color3.fromRGB(72,130,180) or female and Color3.fromRGB(183,88,115) or Color3.fromRGB(119,109,91)
   local badge=make("Frame",{Name="SexBadge",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-7,0,6),Size=UDim2.fromOffset(30,26),Visible=male or female,BackgroundColor3=Color3.fromRGB(255,241,213),BorderSizePixel=0,ZIndex=26},card)
   make("UICorner",{CornerRadius=UDim.new(0,6)},badge)
   local offset=male and 0 or 3
   local ring=make("Frame",{Name="SexRing",Position=UDim2.fromOffset(6+offset,5),Size=UDim2.fromOffset(11,11),BackgroundTransparency=1,ZIndex=27},badge)
   make("UICorner",{CornerRadius=UDim.new(1,0)},ring) make("UIStroke",{Color=color,Thickness=2},ring)
   local function line(name,x,y,w,h,rotation)
    make("Frame",{Name=name,Position=UDim2.fromOffset(x+offset,y),Size=UDim2.fromOffset(w,h),Rotation=rotation or 0,BackgroundColor3=color,BorderSizePixel=0,ZIndex=27},badge)
   end
   if male then line("MaleStem",14,4,9,2,-45) line("ArrowTop",18,2,6,2) line("ArrowRight",22,2,2,6)
   elseif female then line("FemaleStem",10,15,2,7) line("FemaleCross",7,18,8,2) end
   self.cards[item.id]=card
   local preview=make("Frame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   local income=make("Frame",{Name="Income",BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),ZIndex=23},card)
   make("ImageLabel",{Name="Money",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.new(.5,-66,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   local amount=make("TextLabel",{Name="Amount",Text=tostring(item.incomeAmount),BackgroundTransparency=1,Position=UDim2.new(.5,-34,0,0),Size=UDim2.fromOffset(38,30),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=17},amount)
   make("ImageLabel",{Name="Clock",Image=require(script.Parent.HudIcons).imageId(game.ReplicatedStorage.RodeoFantasy,"ClockImage"),BackgroundTransparency=1,Position=UDim2.new(.5,5,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Seconds",Text=tostring(item.incomeSeconds),BackgroundTransparency=1,Position=UDim2.new(.5,33,0,0),Size=UDim2.fromOffset(32,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Summon",item.id) end end)
   elseif self.pen then
    local mine=item.assignedPen==self.pen
    local allowed=mine or (not item.assignedPen and placed<2)
    local label=mine and "Return to bag" or item.assignedPen and "Placed" or placed>=2 and "Full" or "Place"
    local choose=make("TextButton",{Name="ChooseMonster",Text=L.text(label,"en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=allowed and Color3.fromRGB(80,134,104) or Color3.fromRGB(154,167,151),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if allowed and self.pen and self.area=="Lobby" then remote:FireServer(mine and "Remove" or "Place",{id=item.id,pen=self.pen}) end
    end)
   elseif self.evolutionMode then
    local anchor=selectionAnchor()
    local compatible=not anchor or (anchor.monsterId==item.monsterId and anchor.stars==item.stars)
    local selected=self.selected[item.id]==true
    if selected then
     make("UIStroke",{Name="SelectedOutline",Color=Color3.fromRGB(32,184,128),Thickness=4},card)
     make("TextLabel",{Name="SelectedCheck",Text="✓",BackgroundColor3=Color3.fromRGB(32,184,128),Position=UDim2.fromOffset(6,6),Size=UDim2.fromOffset(30,30),TextSize=24,TextColor3=Color3.new(1,1,1),ZIndex=28},card)
    end
    local choose=make("TextButton",{Name="SelectForEvolution",Text=selected and L.text("Selected","en-us") or L.text("Select","en-us"),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=selected and Color3.fromRGB(80,134,104) or compatible and Color3.fromRGB(147,182,154) or Color3.fromRGB(184,181,168),TextColor3=Color3.new(1,1,1),Active=compatible and (selected or selectedCount()<3),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if self.selected[item.id] then self.selected[item.id]=nil
     elseif compatible and selectedCount()<3 and self.area~="Hunt" then self.selected[item.id]=true end
     self.snapshot(self.items)
    end)
   elseif self.area=="Cafe" or self.area=="Lobby" then
    if item.id==self.summonedId and self.area=="Cafe" then
     make("TextLabel",{Text="Summoned",BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
    elseif not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     summon.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed","en-us").." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve","en-us")
  else
   local key=result.reason=="MaxStars" and "Already at max stars" or "Evolution failed"
   evolveStatus.Text=L.text(key,"en-us")
  end
 end
 function self.income(gains)
  if self.area=="Hunt" or not window.Visible then return end
  for _,gain in ipairs(gains or {}) do
   local card=self.cards and self.cards[gain.id]
   if card and card.Parent then Income.card(card,gain.amount) end
  end
 end
 return self
end
return UI
]=]},{node=C:FindFirstChild([=[BipedAnimator]=]),before=[=[-- One decoded clip cache; each creature owns only its skeleton and playback state.
local raw=require(game.ReplicatedStorage.RodeoFantasy.BipedMotionData)
local A={}
local clips={}
local index={}
for i,name in ipairs(raw.bones) do index[name]=i end
for name,clip in pairs(raw.clips) do
 local frames={}
 for i,row in ipairs(clip.frames) do
  local decoded={}
  for j,r in ipairs(row) do decoded[j]=CFrame.new(0,0,0,table.unpack(r)) end
  frames[i]=decoded
 end
 clips[name]={frames=frames,duration=clip.duration,hips=clip.hips}
end
local mapping={Pelvis="Hips",Spine="Spine",Chest="Spine2",Neck="Neck",Head="Head"}
for _,side in ipairs({"Left","Right"}) do
 mapping[side.."FrontUpper"]=side.."Arm"
 mapping[side.."FrontLower"]=side.."ForeArm"
 mapping[side.."FrontPaw"]=side.."Hand"
 mapping[side.."RearUpper"]=side.."UpLeg"
 mapping[side.."RearLower"]=side.."Leg"
 mapping[side.."RearPaw"]=side.."Foot"
end
local cache=setmetatable({},{__mode="k"})
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,phase=0}
  local function visit(parent,parentEntry,world)
   for _,b in ipairs(parent:GetChildren()) do
    if b:IsA("Bone") then
     local rest=world*b.CFrame
     local name=b.Name local source=index[name] or index["mixamorig:"..(mapping[name] or name)]
     local entry={bone=b,rest=rest,localRest=b.CFrame,parent=parentEntry,source=source}
     c.bones[#c.bones+1]=entry visit(b,entry,rest)
    end
   end
  end
  visit(body,nil,CFrame.identity) cache[model]=c
 end
 local now=os.clock() local camera=workspace.CurrentCamera
 local distance=camera and (body.Position-camera.CFrame.Position).Magnitude or 0
 if distance>150 and model:GetAttribute("RiderUserId")~=game.Players.LocalPlayer.UserId then return end
 local interval=distance>70 and .1 or moving and 1/30 or 1/15
 if now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 0 c.last=now
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=moving and speed>18
 local clip=clips[running and "Running" or "Walking"]
 if moving then c.phase=(c.phase+dt/clip.duration)%1 end
 local sample=(moving and c.phase or 0)*(#clip.frames-1)
 local i=math.floor(sample)+1 local t=sample-math.floor(sample)
 local first,second=clip.frames[i],clip.frames[math.min(i+1,#clip.frames)]
 local hipA,hipB=clip.hips[i],clip.hips[math.min(i+1,#clip.hips)]
 local translationScale=body.Size.Y/1.71
 local hip=Vector3.new(hipA[1]+(hipB[1]-hipA[1])*t,hipA[2]+(hipB[2]-hipA[2])*t,hipA[3]+(hipB[3]-hipA[3])*t)*translationScale
 if not moving then hip=Vector3.zero end
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bondTime=workspace:GetServerTimeNow()
 local bonding=(model:GetAttribute("Stars") or 6)<3 and bondUntil>bondTime
 local stage=model:GetAttribute("Stars") or 6
 local ease=bonding and math.min(math.clamp((bondTime-(model:GetAttribute("PetBondStarted") or bondTime))/.4,0,1),math.clamp((bondUntil-bondTime)/.4,0,1)) or 0
 for _,e in ipairs(c.bones) do
  local parentRotation=e.parent and e.parent.currentRotation or CFrame.identity
  local desired=e.source and (moving and first[e.source]:Lerp(second[e.source],t) or CFrame.identity)*e.rest.Rotation or parentRotation*e.localRest.Rotation
  local name=e.bone.Name:gsub("mixamorig:","")
  if bonding then
   local side=name:find("Left",1,true) and 1 or -1
   local pose=CFrame.identity
   local mapped=mapping[name] or name
   if stage>=9 then
    if mapped=="Spine2" then pose=CFrame.Angles(-.28,0,0)
    elseif mapped=="Head" then pose=CFrame.Angles(-.4,0,0)
    elseif mapped=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(.15,0,side*.6)
    elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-.5,0,0) end
   elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(-.25,0,side*1.15)
   elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-1.3,0,0)
   elseif mapped=="Spine2" then pose=CFrame.Angles(-.12,0,0) end
   desired=desired:Lerp(pose*e.rest.Rotation,ease)
  end
  local transform=e.localRest.Rotation:Inverse()*parentRotation:Inverse()*desired
  local tailIndex=tonumber(name:match("^Tail(%d+)$"))
  if tailIndex then transform=CFrame.identity end
  if name=="Hips" or name=="Pelvis" then
   transform=CFrame.new(e.localRest.Rotation:VectorToObjectSpace(parentRotation:VectorToObjectSpace(hip)))*transform
  end
  e.bone.Transform=e.bone.Transform:Lerp(transform,1-math.exp(-18*dt))
  e.currentRotation=parentRotation*e.localRest.Rotation*e.bone.Transform.Rotation
 end
end
return A
]=],after=[=[-- One decoded clip cache; each creature owns only its skeleton and playback state.
local raw=require(game.ReplicatedStorage.RodeoFantasy.BipedMotionData)
local A={}
local clips={}
local index={}
for i,name in ipairs(raw.bones) do index[name]=i end
for name,clip in pairs(raw.clips) do
 local frames={}
 for i,row in ipairs(clip.frames) do
  local decoded={}
  for j,r in ipairs(row) do decoded[j]=CFrame.new(0,0,0,table.unpack(r)) end
  frames[i]=decoded
 end
 clips[name]={frames=frames,duration=clip.duration,hips=clip.hips}
end
local mapping={Pelvis="Hips",Spine="Spine",Chest="Spine2",Neck="Neck",Head="Head"}
for _,side in ipairs({"Left","Right"}) do
 mapping[side.."FrontUpper"]=side.."Arm"
 mapping[side.."FrontLower"]=side.."ForeArm"
 mapping[side.."FrontPaw"]=side.."Hand"
 mapping[side.."RearUpper"]=side.."UpLeg"
 mapping[side.."RearLower"]=side.."Leg"
 mapping[side.."RearPaw"]=side.."Foot"
end
local cache=setmetatable({},{__mode="k"})
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,phase=0}
  local function visit(parent,parentEntry,world)
   for _,b in ipairs(parent:GetChildren()) do
    if b:IsA("Bone") then
     local rest=world*b.CFrame
     local name=b.Name local source=index[name] or index["mixamorig:"..(mapping[name] or name)]
     local entry={bone=b,rest=rest,localRest=b.CFrame,parent=parentEntry,source=source}
     c.bones[#c.bones+1]=entry visit(b,entry,rest)
    end
   end
  end
  visit(body,nil,CFrame.identity) cache[model]=c
 end
 local now=os.clock() local camera=workspace.CurrentCamera
 local distance=camera and (body.Position-camera.CFrame.Position).Magnitude or 0
 if distance>150 and model:GetAttribute("RiderUserId")~=game.Players.LocalPlayer.UserId then return end
 local interval=distance>70 and .1 or moving and 1/30 or 1/15
 if now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 0 c.last=now
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=moving and speed>18
 local clip=clips[running and "Running" or "Walking"]
 if moving then c.phase=(c.phase+dt/clip.duration)%1 end
 local sample=(moving and c.phase or 0)*(#clip.frames-1)
 local i=math.floor(sample)+1 local t=sample-math.floor(sample)
 local first,second=clip.frames[i],clip.frames[math.min(i+1,#clip.frames)]
 local hipA,hipB=clip.hips[i],clip.hips[math.min(i+1,#clip.hips)]
 local translationScale=body.Size.Y/1.71
 local hip=Vector3.new(hipA[1]+(hipB[1]-hipA[1])*t,hipA[2]+(hipB[2]-hipA[2])*t,hipA[3]+(hipB[3]-hipA[3])*t)*translationScale
 if not moving then hip=Vector3.zero end
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bondTime=workspace:GetServerTimeNow()
 local bonding=(model:GetAttribute("Stars") or 6)<3 and bondUntil>bondTime
 local stage=model:GetAttribute("Stars") or 6
 local ease=bonding and math.min(math.clamp((bondTime-(model:GetAttribute("PetBondStarted") or bondTime))/.4,0,1),math.clamp((bondUntil-bondTime)/.4,0,1)) or 0
 for _,e in ipairs(c.bones) do
  local parentRotation=e.parent and e.parent.currentRotation or CFrame.identity
  local desired=e.source and (moving and first[e.source]:Lerp(second[e.source],t) or CFrame.identity)*e.rest.Rotation or parentRotation*e.localRest.Rotation
  local name=e.bone.Name:gsub("mixamorig:","")
  if bonding then
   local side=name:find("Left",1,true) and 1 or -1
   local pose=CFrame.identity
   local mapped=mapping[name] or name
   if stage>=9 then
    if mapped=="Spine2" then pose=CFrame.Angles(-.28,0,0)
    elseif mapped=="Head" then pose=CFrame.Angles(-.4,0,0)
    elseif mapped=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(.15,0,side*.6)
    elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-.5,0,0) end
   elseif mapped:find("Arm",1,true) and not mapped:find("Fore",1,true) then pose=CFrame.Angles(-.25,0,side*1.15)
   elseif mapped:find("ForeArm",1,true) then pose=CFrame.Angles(-1.3,0,0)
   elseif mapped=="Spine2" then pose=CFrame.Angles(-.12,0,0) end
   desired=desired:Lerp(pose*e.rest.Rotation,ease)
  end
  local transform=e.localRest.Rotation:Inverse()*parentRotation:Inverse()*desired
  local tailIndex=tonumber(name:match("^Tail(%d+)$"))
  if tailIndex then transform=CFrame.identity end
  if name=="Hips" or name=="Pelvis" then
   transform=CFrame.new(e.localRest.Rotation:VectorToObjectSpace(parentRotation:VectorToObjectSpace(hip)))*transform
  end
  e.bone.Transform=e.bone.Transform:Lerp(transform,1-math.exp(-18*dt))
  e.currentRotation=parentRotation*e.localRest.Rotation*e.bone.Transform.Rotation
 end
end
return A
]=]},{node=C:FindFirstChild([=[PetPromptUI]=]),before=[=[-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local rules=require(package.LobbyRideRules)
 local presentation=require(script.Parent.RideAnimator)
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent.HudIcons).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
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
  current=nearby() local mounted=player:GetAttribute("LobbyRiding")==true
  button.Visible=current~=nil and rules.canBond(current:GetAttribute("Stars")) and not mounted
  ride.Visible=mounted or current~=nil and rules.canRide(current:GetAttribute("Stars"))
  button.Position=UDim2.new(.5,0,1,-76) ride.Position=button.Position ring.Enabled=mounted
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current and rules.canBond(pet:GetAttribute("Stars")) then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 ride.Activated:Connect(function()
  local pet=nearby()
  if player:GetAttribute("LobbyRiding") or pet and rules.canRide(pet:GetAttribute("Stars")) then package.CaptureRemote:FireServer("RidePet",pet and pet:GetAttribute("BagItemId")) end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0 local lastInput
 local cameraTarget local cameraHeading local cameraPet
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView} end
   camera.CameraType=Enum.CameraType.Scriptable
   local pet=current and current.Parent and current local part=pet and pet.PrimaryPart
   -- Match rider and camera to the pet's interpolated visual frame, not its
   -- server root, which intentionally arrives at a lower network frequency.
   local frame=pet and presentation.frame(pet) or (part and part.CFrame or root.CFrame)
   local height=pet and pet:FindFirstChild("Body") and pet.Body.Size.Y or 4
   if pet and part and root.Anchored then
    local rootHeight=pet:GetAttribute("RootHeight") or 2
    local upright=(pet:GetAttribute("Stars") or 1)>=6
    local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
    root.CFrame=frame*CFrame.new(offset)
   end
   local travel=pet and presentation.travelFrame(pet) or (part and part.CFrame or root.CFrame)
   local forward=Vector3.new(travel.LookVector.X,0,travel.LookVector.Z)
   if forward.Magnitude<.001 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
   local rootHeight=pet and pet:GetAttribute("RootHeight") or 2
   local upright=pet and (pet:GetAttribute("Stars") or 1)>=6
   local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
   local target=(travel*CFrame.new(offset)).Position+Vector3.new(0,1,0)
   local heading=CFrame.lookAt(Vector3.zero,forward)
   if cameraPet~=pet or not cameraTarget or (target-cameraTarget).Magnitude>30 then
    cameraTarget=target cameraHeading=heading cameraPet=pet
   else
    cameraTarget=cameraTarget:Lerp(target,1-math.exp(-14*dt))
    cameraHeading=cameraHeading:Lerp(heading,1-math.exp(-8*dt))
   end
   camera.CFrame=CFrame.lookAt(cameraTarget-cameraHeading.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),cameraTarget)
   inputTime+=dt
   local direction=hum.MoveDirection
   if inputTime>=.08 and (not lastInput or (direction-lastInput).Magnitude>.02 or inputTime>=.25) then
    inputTime=0 lastInput=direction package.CaptureRemote:FireServer("RideInput",direction)
   end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
   inputTime=0 lastInput=nil cameraTarget=nil cameraHeading=nil cameraPet=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]=],after=[=[-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local rules=require(package.LobbyRideRules)
 local presentation=require(script.Parent.RideAnimator)
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent.HudIcons).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
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
  current=nearby() local mounted=player:GetAttribute("LobbyRiding")==true
  button.Visible=current~=nil and rules.canBond(current:GetAttribute("Stars")) and not mounted
  ride.Visible=mounted or current~=nil and rules.canRide(current:GetAttribute("Stars"))
  button.Position=UDim2.new(.5,0,1,-76) ride.Position=button.Position ring.Enabled=mounted
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current and rules.canBond(pet:GetAttribute("Stars")) then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 ride.Activated:Connect(function()
  local pet=nearby()
  if player:GetAttribute("LobbyRiding") or pet and rules.canRide(pet:GetAttribute("Stars")) then package.CaptureRemote:FireServer("RidePet",pet and pet:GetAttribute("BagItemId")) end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0 local lastInput
 local cameraTarget local cameraHeading local cameraPet
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView} end
   camera.CameraType=Enum.CameraType.Scriptable
   local pet=current and current.Parent and current local part=pet and pet.PrimaryPart
   -- Match rider and camera to the pet's interpolated visual frame, not its
   -- server root, which intentionally arrives at a lower network frequency.
   local frame=pet and presentation.frame(pet) or (part and part.CFrame or root.CFrame)
   local height=pet and pet:FindFirstChild("Body") and pet.Body.Size.Y or 4
   if pet and part and root.Anchored then
    local rootHeight=pet:GetAttribute("RootHeight") or 2
    local upright=(pet:GetAttribute("Stars") or 1)>=6
    local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
    root.CFrame=frame*CFrame.new(offset)
   end
   local travel=pet and presentation.travelFrame(pet) or (part and part.CFrame or root.CFrame)
   local forward=Vector3.new(travel.LookVector.X,0,travel.LookVector.Z)
   if forward.Magnitude<.001 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
   local rootHeight=pet and pet:GetAttribute("RootHeight") or 2
   local upright=pet and (pet:GetAttribute("Stars") or 1)>=6
   local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
   local target=(travel*CFrame.new(offset)).Position+Vector3.new(0,1,0)
   local heading=CFrame.lookAt(Vector3.zero,forward)
   if cameraPet~=pet or not cameraTarget or (target-cameraTarget).Magnitude>30 then
    cameraTarget=target cameraHeading=heading cameraPet=pet
   else
    cameraTarget=cameraTarget:Lerp(target,1-math.exp(-14*dt))
    cameraHeading=cameraHeading:Lerp(heading,1-math.exp(-8*dt))
   end
   camera.CFrame=CFrame.lookAt(cameraTarget-cameraHeading.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),cameraTarget)
   inputTime+=dt
   local direction=hum.MoveDirection
   if inputTime>=.08 and (not lastInput or (direction-lastInput).Magnitude>.02 or inputTime>=.25) then
    inputTime=0 lastInput=direction package.CaptureRemote:FireServer("RideInput",direction)
   end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
   inputTime=0 lastInput=nil cameraTarget=nil cameraHeading=nil cameraPet=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]=]},{node=C:FindFirstChild([=[RocketDeparture]=]),before=[=[local Players=game:GetService("Players")
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
]=],after=[=[local Players=game:GetService("Players")
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
]=]},{node=C:FindFirstChild([=[UserMossratRigAnimator]=]),before=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local quadruped=require(script.Parent.QuadrupedAnimator)
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local dataS3=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS3"))
local dataS6=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS6"))
local dataS9=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS9"))
local function rigData(model)
 local revision=model:GetAttribute("MossratUserRigRevision")
 return revision=="UserS9-v1" and dataS9 or revision=="UserS6-v1" and dataS6 or revision=="UserS3-v1" and dataS3 or data
end
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local s3=rigData(model)~=data
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=not s3 and torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" and not s3 then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local data=rigData(model)
 local s9=data==dataS9
 local s6=data==dataS6 or s9
 local s3=data==dataS3 or s6
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},poses={},sample={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 local interval=moving and 1/30 or 1/15
 local camera=workspace.CurrentCamera
 if model:GetAttribute("OwnerUserId") and camera then
  local distance=(body.Position-camera.CFrame.Position).Magnitude
  if distance>150 then return end
  if distance>70 then interval=1/10 end
 end
 if c.mode and now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 1/30 c.last=now
 local serverNow=workspace:GetServerTimeNow()
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=not s3 and bondUntil>serverNow
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={} table.clear(c.poses)
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses=c.poses
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v=c.sample
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=not s3 and torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" and not s3 then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding and not s3 then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-serverNow)/.35,0,1))
    local pose=CFrame.identity
    if name=="Pelvis" then pose=CFrame.new(0,-.08*scale,0)*CFrame.Angles(math.rad(-32),0,0)
    elseif name=="Spine" then pose=CFrame.Angles(math.rad(-18),0,0)
    elseif name=="Chest" then pose=CFrame.Angles(math.rad(8),0,0)
    elseif name=="Neck" then pose=CFrame.Angles(math.rad(22),0,0)
    elseif name=="Head" then pose=CFrame.Angles(math.rad(20),math.sin(t*4)*.12,math.sin(t*4)*.20)
    elseif legLimb=="Rear" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(50),0,0)
    elseif legLimb=="Rear" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(-55),0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(-50),0,0)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(40),0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif legSide and legLimb and moving and s6 then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*(s6 and (legLimb=="Front" and .22 or .45) or .65),0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*(s6 and .28 or .65),0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   local tailIndex=tonumber(name:match("^Tail(%d+)$"))
   if tailIndex and s3 then
    frame=CFrame.identity
   elseif tailIndex then
    frame=frame*CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035)
   end
   if bonding and data==dataS3 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local progress=math.clamp((t-.35)/1.7,0,1)
    if name=="Root" then
     local height=data.height*scale local lift=math.sin(progress*math.pi)*height*.65
     frame=CFrame.new(0,height*.5+lift,0)*CFrame.Angles(-math.pi*2*progress,0,0)*CFrame.new(0,-height*.5,0)
    elseif legLimb and progress>0 and progress<1 then
     frame=CFrame.Angles(math.sin(progress*math.pi)*(legLimb=="Front" and -.6 or .6),0,0)
    end
   elseif bonding and s9 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.5,0,1),math.clamp((bondUntil-serverNow)/.5,0,1))
    local pose=CFrame.identity
    if name=="Chest" then pose=CFrame.Angles(-.28,0,0)
    elseif name=="Head" then pose=CFrame.Angles(-.40,0,math.sin(t*8)*.025)
    elseif name=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(.15,0,(legSide=="Left" and 1 or -1)*.6)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-.5,0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif bonding and s6 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.4,0,1),math.clamp((bondUntil-serverNow)/.4,0,1))
    local sign=legSide=="Left" and 1 or -1
    local pose=CFrame.identity
    if legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(-.25,0,sign*1.35)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-1.5,0,0)
    elseif name=="Chest" then pose=CFrame.Angles(-.12,math.sin(t*2)*.12,0)
    elseif name=="Head" then pose=CFrame.Angles(-.1,math.sin(t*2)*.12,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
 if not s6 and not bonding then quadruped.apply(model,moving,dt) end
end
return A
]=],after=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local quadruped=require(script.Parent.QuadrupedAnimator)
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local dataS3=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS3"))
local dataS6=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS6"))
local dataS9=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS9"))
local function rigData(model)
 local revision=model:GetAttribute("MossratUserRigRevision")
 return revision=="UserS9-v1" and dataS9 or revision=="UserS6-v1" and dataS6 or revision=="UserS3-v1" and dataS3 or data
end
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local s3=rigData(model)~=data
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=not s3 and torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" and not s3 then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local data=rigData(model)
 local s9=data==dataS9
 local s6=data==dataS6 or s9
 local s3=data==dataS3 or s6
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},poses={},sample={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 local interval=moving and 1/30 or 1/15
 local camera=workspace.CurrentCamera
 if model:GetAttribute("OwnerUserId") and camera then
  local distance=(body.Position-camera.CFrame.Position).Magnitude
  if distance>150 then return end
  if distance>70 then interval=1/10 end
 end
 if c.mode and now-c.last<interval then return end
 local dt=c.last>0 and math.min(now-c.last,.15) or 1/30 c.last=now
 local serverNow=workspace:GetServerTimeNow()
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=not s3 and bondUntil>serverNow
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={} table.clear(c.poses)
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses=c.poses
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v=c.sample
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=not s3 and torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" and not s3 then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding and not s3 then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-serverNow)/.35,0,1))
    local pose=CFrame.identity
    if name=="Pelvis" then pose=CFrame.new(0,-.08*scale,0)*CFrame.Angles(math.rad(-32),0,0)
    elseif name=="Spine" then pose=CFrame.Angles(math.rad(-18),0,0)
    elseif name=="Chest" then pose=CFrame.Angles(math.rad(8),0,0)
    elseif name=="Neck" then pose=CFrame.Angles(math.rad(22),0,0)
    elseif name=="Head" then pose=CFrame.Angles(math.rad(20),math.sin(t*4)*.12,math.sin(t*4)*.20)
    elseif legLimb=="Rear" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(50),0,0)
    elseif legLimb=="Rear" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(-55),0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(-50),0,0)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(40),0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif legSide and legLimb and moving and s6 then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*(s6 and (legLimb=="Front" and .22 or .45) or .65),0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*(s6 and .28 or .65),0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   local tailIndex=tonumber(name:match("^Tail(%d+)$"))
   if tailIndex and s3 then
    frame=CFrame.identity
   elseif tailIndex then
    frame=frame*CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035)
   end
   if bonding and data==dataS3 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local progress=math.clamp((t-.35)/1.7,0,1)
    if name=="Root" then
     local height=data.height*scale local lift=math.sin(progress*math.pi)*height*.65
     frame=CFrame.new(0,height*.5+lift,0)*CFrame.Angles(-math.pi*2*progress,0,0)*CFrame.new(0,-height*.5,0)
    elseif legLimb and progress>0 and progress<1 then
     frame=CFrame.Angles(math.sin(progress*math.pi)*(legLimb=="Front" and -.6 or .6),0,0)
    end
   elseif bonding and s9 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.5,0,1),math.clamp((bondUntil-serverNow)/.5,0,1))
    local pose=CFrame.identity
    if name=="Chest" then pose=CFrame.Angles(-.28,0,0)
    elseif name=="Head" then pose=CFrame.Angles(-.40,0,math.sin(t*8)*.025)
    elseif name=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(.15,0,(legSide=="Left" and 1 or -1)*.6)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-.5,0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif bonding and s6 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.4,0,1),math.clamp((bondUntil-serverNow)/.4,0,1))
    local sign=legSide=="Left" and 1 or -1
    local pose=CFrame.identity
    if legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(-.25,0,sign*1.35)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-1.5,0,0)
    elseif name=="Chest" then pose=CFrame.Angles(-.12,math.sin(t*2)*.12,0)
    elseif name=="Head" then pose=CFrame.Angles(-.1,math.sin(t*2)*.12,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
 if not s6 and not bonding then quadruped.apply(model,moving,dt) end
end
return A
]=]},{node=S:FindFirstChild([=[LobbyCompanions]=]),before=[=[-- One owned companion per lobby player; riding remains server authoritative.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
local RideRules=require(P.LobbyRideRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.dismount(p)
  local pet=pets[p] local ride=pet and pet.ride
  if not ride then return end
  pet.ride=nil pet.input=Vector3.zero
  p:SetAttribute("LobbyRiding",nil) pet.model:SetAttribute("RiderUserId",nil)
  local r,h=ride.root,ride.humanoid
  if r.Parent and h.Parent then
   local frame=pet.model.PrimaryPart.CFrame
   for _,offset in ipairs({Vector3.new(5,0,0),Vector3.new(-5,0,0),Vector3.new(0,0,6)}) do
    local pos=frame:PointToWorldSpace(offset) local y=ground(pos)
    if y and not workspace:Blockcast(CFrame.new(frame.Position),Vector3.new(2,2,2),pos-frame.Position,params) then
     r.CFrame=CFrame.new(pos.X,y+h.HipHeight+r.Size.Y/2,pos.Z)*frame.Rotation break
    end
   end
   r.Anchored=ride.anchored h.AutoRotate=ride.autoRotate h.PlatformStand=ride.platformStand h.Sit=ride.sit
   r.AssemblyLinearVelocity=Vector3.zero
  end
 end
 function api.ride(p,id)
  local pet=pets[p] local r=root(p)
  if pet and pet.ride then api.dismount(p) return true end
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if not pet or pet.id~=id or not r or not h or h.Health<=0 or not context.canAct(p) or not context.inLobby(p)
   or not RideRules.canRide(pet.model:GetAttribute("Stars"))
   or not Rules.available(Rules.find(context.bag(p),id)) or (r.Position-pet.model.PrimaryPart.Position).Magnitude>10
   or (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then return false end
  pet.ride={root=r,humanoid=h,anchored=r.Anchored,autoRotate=h.AutoRotate,platformStand=h.PlatformStand,sit=h.Sit}
  pet.input=Vector3.zero pet.inputAt=os.clock()
  r.Anchored=true h.AutoRotate=false h.PlatformStand=false h.Sit=true
  h:ChangeState(Enum.HumanoidStateType.Seated)
  pet.model:SetAttribute("RiderUserId",p.UserId) p:SetAttribute("LobbyRiding",true)
  return true
 end
 function api.input(p,value)
  local pet=pets[p] if not pet or not pet.ride then return end
  local direction=RideRules.direction(value) if not direction then return end
  pet.input=direction pet.inputAt=os.clock()
 end
 function api.bond(p,id)
  local pet=pets[p] local rr=root(p)
  if not pet or pet.ride or pet.id~=id or not context.canAct(p) or not context.inLobby(p)
   or not RideRules.canBond(pet.model:GetAttribute("Stars"))
   or not Rules.available(Rules.find(context.bag(p),id)) or not rr
   or (rr.Position-pet.model.PrimaryPart.Position).Magnitude>10 or os.clock()-(pet.lastBond or -math.huge)<3.5 then return false end
  pet.lastBond=os.clock()
  local at=workspace:GetServerTimeNow()
  pet.model:SetAttribute("PetBondStarted",at) pet.model:SetAttribute("PetBondUntil",at+3)
  P.CaptureRemote:FireAllClients("LobbyPet",{model=pet.model,at=at})
  return true
 end
 function api.clear(p)
  api.dismount(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","Summon your companion in the lobby.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  local revision=source and source:GetAttribute("MossratUserRigRevision")
  if revision~="ApprovedS1-v1" and revision~="UserS3-v1" and revision~="UserS6-v1" and revision~="UserS9-v1" and revision~="ProvidedBiped-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false,blocked=0}
  p:SetAttribute("SummonedId",id)

 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if pet.ride then
    local ride=pet.ride
    if r~=ride.root or not ride.humanoid.Parent or ride.humanoid.Health<=0 then api.dismount(p) continue end
    local direction=context.canAct(p) and Rules.available(Rules.find(context.bag(p),pet.id)) and os.clock()-pet.inputAt<.5 and pet.input or Vector3.zero
    local old=pet.model.PrimaryPart.CFrame
    local heading=RideRules.turn(old.LookVector,direction,step)
    local delta=heading*direction.Magnitude*RideRules.speed(pet.model:GetAttribute("Stars"))*step
    local position=old.Position+delta
    local frame=old local moving=delta.Magnitude>.01
    if moving then
     local y=ground(position)
     local hit=workspace:Blockcast(CFrame.new(old.X,old.Y+1,old.Z),Vector3.new(2.5,2.5,2.5),delta,params)
     if y and not hit and math.abs(y+pet.height-old.Y)<=3 then
      position=Vector3.new(position.X,y+pet.height,position.Z) frame=CFrame.lookAt(position,position+heading)
     else
      moving=false
      -- Keep steering when translation is blocked, so a wall cannot trap a rider.
      frame=CFrame.lookAt(old.Position,old.Position+heading)
     end
     if frame~=old then pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot()) end
    end
    local stage=Catalog.stage(pet.model:GetAttribute("Stars"))
    local body=pet.model:FindFirstChild("Body") local tall=body and body.Size.Y or pet.height*2
    local offset=stage>=6 and Vector3.new(0,tall*.62-pet.height,1.35) or Vector3.new(0,tall*.62-pet.height+1.25,.15)
    local riderFrame=frame*CFrame.new(offset)
    if r.CFrame~=riderFrame then r.CFrame=riderFrame end
    if r.AssemblyLinearVelocity~=Vector3.zero then r.AssemblyLinearVelocity=Vector3.zero end
    pet.model:SetAttribute("Running",moving) pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
    continue
   end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A pet stranded behind a wall must not be left outside the visible lobby.
   -- Recover only onto a collidable surface near its owner, never into the sky.
   if toOwner.Magnitude>70 or pet.blocked>=1.5 then
    for _,offset in ipairs({Vector3.new(4,0,4),Vector3.new(-4,0,4),Vector3.new(4,0,-4),Vector3.new(-4,0,-4)}) do
     local position=r.Position+offset
     local y=ground(position)
     if y and math.abs(y-r.Position.Y)<10 then
      local frame=CFrame.new(position.X,y+pet.height,position.Z)*old.Rotation
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
      pet.following=false pet.blocked=0 old=frame
      toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
      break
     end
    end
   end
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    -- Match the owner's pace; the lobby player walks at 40 studs/sec.
    local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
    local speed=humanoid and humanoid.WalkSpeed or 40
    delta=delta.Unit*math.min(delta.Magnitude-6,speed*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     pet.blocked=0
    else
     pet.blocked+=step
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]=],after=[=[-- One owned companion per lobby player; riding remains server authoritative.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
local RideRules=require(P.LobbyRideRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.dismount(p)
  local pet=pets[p] local ride=pet and pet.ride
  if not ride then return end
  pet.ride=nil pet.input=Vector3.zero
  p:SetAttribute("LobbyRiding",nil) pet.model:SetAttribute("RiderUserId",nil)
  local r,h=ride.root,ride.humanoid
  if r.Parent and h.Parent then
   local frame=pet.model.PrimaryPart.CFrame
   for _,offset in ipairs({Vector3.new(5,0,0),Vector3.new(-5,0,0),Vector3.new(0,0,6)}) do
    local pos=frame:PointToWorldSpace(offset) local y=ground(pos)
    if y and not workspace:Blockcast(CFrame.new(frame.Position),Vector3.new(2,2,2),pos-frame.Position,params) then
     r.CFrame=CFrame.new(pos.X,y+h.HipHeight+r.Size.Y/2,pos.Z)*frame.Rotation break
    end
   end
   r.Anchored=ride.anchored h.AutoRotate=ride.autoRotate h.PlatformStand=ride.platformStand h.Sit=ride.sit
   r.AssemblyLinearVelocity=Vector3.zero
  end
 end
 function api.ride(p,id)
  local pet=pets[p] local r=root(p)
  if pet and pet.ride then api.dismount(p) return true end
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if not pet or pet.id~=id or not r or not h or h.Health<=0 or not context.canAct(p) or not context.inLobby(p)
   or not RideRules.canRide(pet.model:GetAttribute("Stars"))
   or not Rules.available(Rules.find(context.bag(p),id)) or (r.Position-pet.model.PrimaryPart.Position).Magnitude>10
   or (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then return false end
  pet.ride={root=r,humanoid=h,anchored=r.Anchored,autoRotate=h.AutoRotate,platformStand=h.PlatformStand,sit=h.Sit}
  pet.input=Vector3.zero pet.inputAt=os.clock()
  r.Anchored=true h.AutoRotate=false h.PlatformStand=false h.Sit=true
  h:ChangeState(Enum.HumanoidStateType.Seated)
  pet.model:SetAttribute("RiderUserId",p.UserId) p:SetAttribute("LobbyRiding",true)
  return true
 end
 function api.input(p,value)
  local pet=pets[p] if not pet or not pet.ride then return end
  local direction=RideRules.direction(value) if not direction then return end
  pet.input=direction pet.inputAt=os.clock()
 end
 function api.bond(p,id)
  local pet=pets[p] local rr=root(p)
  if not pet or pet.ride or pet.id~=id or not context.canAct(p) or not context.inLobby(p)
   or not RideRules.canBond(pet.model:GetAttribute("Stars"))
   or not Rules.available(Rules.find(context.bag(p),id)) or not rr
   or (rr.Position-pet.model.PrimaryPart.Position).Magnitude>10 or os.clock()-(pet.lastBond or -math.huge)<3.5 then return false end
  pet.lastBond=os.clock()
  local at=workspace:GetServerTimeNow()
  pet.model:SetAttribute("PetBondStarted",at) pet.model:SetAttribute("PetBondUntil",at+3)
  P.CaptureRemote:FireAllClients("LobbyPet",{model=pet.model,at=at})
  return true
 end
 function api.clear(p)
  api.dismount(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","Summon your companion in the lobby.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  local revision=source and source:GetAttribute("MossratUserRigRevision")
  if revision~="ApprovedS1-v1" and revision~="UserS3-v1" and revision~="UserS6-v1" and revision~="UserS9-v1" and revision~="ProvidedBiped-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false,blocked=0}
  p:SetAttribute("SummonedId",id)

 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if pet.ride then
    local ride=pet.ride
    if r~=ride.root or not ride.humanoid.Parent or ride.humanoid.Health<=0 then api.dismount(p) continue end
    local direction=context.canAct(p) and Rules.available(Rules.find(context.bag(p),pet.id)) and os.clock()-pet.inputAt<.5 and pet.input or Vector3.zero
    local old=pet.model.PrimaryPart.CFrame
    local heading=RideRules.turn(old.LookVector,direction,step)
    local delta=heading*direction.Magnitude*RideRules.speed(pet.model:GetAttribute("Stars"))*step
    local position=old.Position+delta
    local frame=old local moving=delta.Magnitude>.01
    if moving then
     local y=ground(position)
     local hit=workspace:Blockcast(CFrame.new(old.X,old.Y+1,old.Z),Vector3.new(2.5,2.5,2.5),delta,params)
     if y and not hit and math.abs(y+pet.height-old.Y)<=3 then
      position=Vector3.new(position.X,y+pet.height,position.Z) frame=CFrame.lookAt(position,position+heading)
     else
      moving=false
      -- Keep steering when translation is blocked, so a wall cannot trap a rider.
      frame=CFrame.lookAt(old.Position,old.Position+heading)
     end
     if frame~=old then pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot()) end
    end
    local stage=Catalog.stage(pet.model:GetAttribute("Stars"))
    local body=pet.model:FindFirstChild("Body") local tall=body and body.Size.Y or pet.height*2
    local offset=stage>=6 and Vector3.new(0,tall*.62-pet.height,1.35) or Vector3.new(0,tall*.62-pet.height+1.25,.15)
    local riderFrame=frame*CFrame.new(offset)
    if r.CFrame~=riderFrame then r.CFrame=riderFrame end
    if r.AssemblyLinearVelocity~=Vector3.zero then r.AssemblyLinearVelocity=Vector3.zero end
    pet.model:SetAttribute("Running",moving) pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
    continue
   end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A pet stranded behind a wall must not be left outside the visible lobby.
   -- Recover only onto a collidable surface near its owner, never into the sky.
   if toOwner.Magnitude>70 or pet.blocked>=1.5 then
    for _,offset in ipairs({Vector3.new(4,0,4),Vector3.new(-4,0,4),Vector3.new(4,0,-4),Vector3.new(-4,0,-4)}) do
     local position=r.Position+offset
     local y=ground(position)
     if y and math.abs(y-r.Position.Y)<10 then
      local frame=CFrame.new(position.X,y+pet.height,position.Z)*old.Rotation
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
      pet.following=false pet.blocked=0 old=frame
      toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
      break
     end
    end
   end
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    -- Match the owner's pace; the lobby player walks at 40 studs/sec.
    local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
    local speed=humanoid and humanoid.WalkSpeed or 40
    delta=delta.Unit*math.min(delta.Magnitude-6,speed*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     pet.blocked=0
    else
     pet.blocked+=step
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]=]},{node=P:FindFirstChild([=[BagRules]=]),before=[=[-- Session-only bag income. Summoning/display never affects income.
local BagRules = {}

function BagRules.new()
 return { monsters = {}, eggs={}, breedingTeams={}, profile={}, pending = 0, balance = 0, serial = 0, totalProduced = 0 }
end

function BagRules.grant(session, monsterId, clock, incomeSeconds, incomeAmount)
	session.serial=(session.serial or 0)+1
	table.insert(session.monsters, { id=session.serial, monsterId = monsterId, stars = 1, lastIncome = clock, incomeSeconds=incomeSeconds, incomeAmount=incomeAmount,sex=BagRules.sexForRoll(math.random()) })
end
function BagRules.sexForRoll(roll) return roll<.5 and "Male" or "Female" end

function BagRules.income(monster, fallback)
 return (monster.incomeAmount or fallback or 1)*3^(math.clamp(math.floor(monster.stars or 1),1,10)-1)
end

function BagRules.accrue(session, clock, seconds, amount)
 local gains={}
	for _, monster in ipairs(session.monsters) do
		local interval=monster.incomeSeconds or seconds
        local rate=BagRules.income(monster,amount)
		local ticks = math.floor(math.max(0, clock - monster.lastIncome) / interval)
		session.pending += ticks * rate
        session.totalProduced = (session.totalProduced or 0) + ticks * rate
		monster.lastIncome += ticks * interval
  if ticks>0 then table.insert(gains,{id=monster.id,amount=ticks*rate}) end
	end
 return gains
end

function BagRules.find(session,id)
 if type(id)~="number" or id~=id or id%1~=0 then return nil end
 for _,item in ipairs(session.monsters) do if item.id==id then return item end end
end
function BagRules.place(session,id,pen)
 if type(pen)~="number" or pen~=pen or pen%1~=0 or pen<1 or pen>4 then return false end
 local item=BagRules.find(session,id)
 if not item or item.assignedPen then return false end
 local count=0
 for _,other in ipairs(session.monsters) do if other.assignedPen==pen then count+=1 end end
 if count>=2 then return false end
 item.assignedPen=pen return true
end
function BagRules.remove(session,id,pen)
 local item=BagRules.find(session,id)
 if not item or item.assignedPen~=pen then return false end
 item.assignedPen=nil return true
end

-- Consumes exactly three distinct copies of the same species and star tier.
-- Returns the new monster and the affected ranches, or nil plus a reason.
function BagRules.evolve(session,ids,clock)
 if type(ids)~="table" or #ids~=3 then return nil,"NeedThree" end
 local unique,selected={},{}
 for _,id in ipairs(ids) do
  if type(id)~="number" or id~=id or id%1~=0 or unique[id] then return nil,"InvalidSelection" end
  unique[id]=true
  local item=BagRules.find(session,id)
  if not item then return nil,"MissingMonster" end
  if item.breedingTeam or item.tradeLock then return nil,"MonsterBusy" end
  table.insert(selected,item)
 end
 local first=selected[1]
 if math.floor(first.stars or 1)>=10 then return nil,"MaxStars" end
 for index=2,3 do
  local item=selected[index]
  if item.monsterId~=first.monsterId then return nil,"DifferentSpecies" end
  if item.stars~=first.stars then return nil,"DifferentStars" end
 end
 local affected={}
 for _,item in ipairs(selected) do if item.assignedPen then affected[item.assignedPen]=true end end
 for index=#session.monsters,1,-1 do
  if unique[session.monsters[index].id] then table.remove(session.monsters,index) end
 end
 if session.profile then for index=#session.profile,1,-1 do if unique[session.profile[index]] then table.remove(session.profile,index) end end end
 session.serial=(session.serial or 0)+1
 local evolved={id=session.serial,monsterId=first.monsterId,stars=first.stars+1,lastIncome=clock,
  incomeSeconds=first.incomeSeconds,incomeAmount=first.incomeAmount}
 table.insert(session.monsters,evolved)
 return evolved,affected
end

-- Prepared for direct collection; the UI/action remains to be confirmed.
function BagRules.collect(session)
	local amount = session.pending
	session.pending = 0
	session.balance += amount
	return amount
end

return BagRules
]=],after=[=[-- Session-only bag income. Summoning/display never affects income.
local BagRules = {}

function BagRules.new()
 return { monsters = {}, eggs={}, breedingTeams={}, profile={}, pending = 0, balance = 0, serial = 0, totalProduced = 0 }
end

function BagRules.grant(session, monsterId, clock, incomeSeconds, incomeAmount)
	session.serial=(session.serial or 0)+1
	table.insert(session.monsters, { id=session.serial, monsterId = monsterId, stars = 1, lastIncome = clock, incomeSeconds=incomeSeconds, incomeAmount=incomeAmount,sex=BagRules.sexForRoll(math.random()) })
end
function BagRules.sexForRoll(roll) return roll<.5 and "Male" or "Female" end

function BagRules.income(monster, fallback)
 return (monster.incomeAmount or fallback or 1)*3^(math.clamp(math.floor(monster.stars or 1),1,10)-1)
end

function BagRules.accrue(session, clock, seconds, amount)
 local gains={}
	for _, monster in ipairs(session.monsters) do
		local interval=monster.incomeSeconds or seconds
        local rate=BagRules.income(monster,amount)
		local ticks = math.floor(math.max(0, clock - monster.lastIncome) / interval)
		session.pending += ticks * rate
        session.totalProduced = (session.totalProduced or 0) + ticks * rate
		monster.lastIncome += ticks * interval
  if ticks>0 then table.insert(gains,{id=monster.id,amount=ticks*rate}) end
	end
 return gains
end

function BagRules.find(session,id)
 if type(id)~="number" or id~=id or id%1~=0 then return nil end
 for _,item in ipairs(session.monsters) do if item.id==id then return item end end
end
function BagRules.place(session,id,pen)
 if type(pen)~="number" or pen~=pen or pen%1~=0 or pen<1 or pen>4 then return false end
 local item=BagRules.find(session,id)
 if not item or item.assignedPen then return false end
 local count=0
 for _,other in ipairs(session.monsters) do if other.assignedPen==pen then count+=1 end end
 if count>=2 then return false end
 item.assignedPen=pen return true
end
function BagRules.remove(session,id,pen)
 local item=BagRules.find(session,id)
 if not item or item.assignedPen~=pen then return false end
 item.assignedPen=nil return true
end

-- Consumes exactly three distinct copies of the same species and star tier.
-- Returns the new monster and the affected ranches, or nil plus a reason.
function BagRules.evolve(session,ids,clock)
 if type(ids)~="table" or #ids~=3 then return nil,"NeedThree" end
 local unique,selected={},{}
 for _,id in ipairs(ids) do
  if type(id)~="number" or id~=id or id%1~=0 or unique[id] then return nil,"InvalidSelection" end
  unique[id]=true
  local item=BagRules.find(session,id)
  if not item then return nil,"MissingMonster" end
  if item.breedingTeam or item.tradeLock then return nil,"MonsterBusy" end
  table.insert(selected,item)
 end
 local first=selected[1]
 if math.floor(first.stars or 1)>=10 then return nil,"MaxStars" end
 for index=2,3 do
  local item=selected[index]
  if item.monsterId~=first.monsterId then return nil,"DifferentSpecies" end
  if item.stars~=first.stars then return nil,"DifferentStars" end
 end
 local affected={}
 for _,item in ipairs(selected) do if item.assignedPen then affected[item.assignedPen]=true end end
 for index=#session.monsters,1,-1 do
  if unique[session.monsters[index].id] then table.remove(session.monsters,index) end
 end
 if session.profile then for index=#session.profile,1,-1 do if unique[session.profile[index]] then table.remove(session.profile,index) end end end
 session.serial=(session.serial or 0)+1
 local evolved={id=session.serial,monsterId=first.monsterId,stars=first.stars+1,lastIncome=clock,
  incomeSeconds=first.incomeSeconds,incomeAmount=first.incomeAmount}
 table.insert(session.monsters,evolved)
 return evolved,affected
end

-- Prepared for direct collection; the UI/action remains to be confirmed.
function BagRules.collect(session)
	local amount = session.pending
	session.pending = 0
	session.balance += amount
	return amount
end

return BagRules
]=]},{node=P:FindFirstChild([=[LobbyRideRules]=]),before=[=[-- Lobby riding uses owned pets and server-limited movement.
local R={}
function R.canRide(stars) return (tonumber(stars) or 1)>=3 end
function R.canBond(stars) return not R.canRide(stars) end
-- Signed yaw handles even a 180-degree reversal without a zero-vector lerp.
function R.turn(forward,target,dt)
 if target.Magnitude<.001 then return forward end
 target=target.Unit
 local angle=math.atan2(forward:Cross(target).Y,forward:Dot(target))
 local step=math.clamp(angle,-math.pi*1.5*dt,math.pi*1.5*dt)
 return CFrame.Angles(0,step,0):VectorToWorldSpace(forward)
end
function R.speed(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 return 26+(stars-1)*3
end
function R.direction(value)
 if typeof(value)~="Vector3" or value.X~=value.X or value.Y~=value.Y or value.Z~=value.Z then return nil end
 if math.abs(value.X)>1000 or math.abs(value.Z)>1000 or math.abs(value.Y)>1000 then return nil end
 local flat=Vector3.new(value.X,0,value.Z)
 return flat.Magnitude>1 and flat.Unit or flat
end
return R
]=],after=[=[-- Lobby riding uses owned pets and server-limited movement.
local R={}
function R.canRide(stars) return (tonumber(stars) or 1)>=3 end
function R.canBond(stars) return not R.canRide(stars) end
-- Signed yaw handles even a 180-degree reversal without a zero-vector lerp.
function R.turn(forward,target,dt)
 if target.Magnitude<.001 then return forward end
 target=target.Unit
 local angle=math.atan2(forward:Cross(target).Y,forward:Dot(target))
 local step=math.clamp(angle,-math.pi*1.5*dt,math.pi*1.5*dt)
 return CFrame.Angles(0,step,0):VectorToWorldSpace(forward)
end
function R.speed(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 return 26+(stars-1)*3
end
function R.direction(value)
 if typeof(value)~="Vector3" or value.X~=value.X or value.Y~=value.Y or value.Z~=value.Z then return nil end
 if math.abs(value.X)>1000 or math.abs(value.Z)>1000 or math.abs(value.Y)>1000 then return nil end
 local flat=Vector3.new(value.X,0,value.Z)
 return flat.Magnitude>1 and flat.Unit or flat
end
return R
]=]},{node=C:FindFirstChild([=[MonsterPortrait]=]),before=[=[-- Shared 2D portraits: inventory/catalog never clone 3D rigs or cameras.
local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local defaults={[1]="rbxassetid://136157716828140",[3]="rbxassetid://132856650627155",[6]="rbxassetid://105207783752500",[9]="rbxassetid://85299683248138"}
function P.fill(container,id,stars,silhouette,_distanceScale)
 local stage=C.stage(stars)
 local imageId=id=="MeadowMouse" and (package:GetAttribute("MossratPortraitS"..stage) or defaults[stage]) or nil
 local image=Instance.new("ImageLabel") image.Name="MonsterPortraitImage"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ScaleType=Enum.ScaleType.Fit image.ZIndex=container.ZIndex+1
 image.Image=type(imageId)=="string" and imageId or ""
 image.ImageColor3=silhouette and Color3.new(0,0,0) or Color3.new(1,1,1)
 image.Parent=container
 if image.Image=="" then
  local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
  label.Text="?" label.TextScaled=true label.TextColor3=Color3.fromRGB(160,180,170) label.Parent=container
 end
 return image
end
return P
]=],after=[=[-- Shared 2D portraits: inventory/catalog never clone 3D rigs or cameras.
local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local defaults={[1]="rbxassetid://136157716828140",[3]="rbxassetid://132856650627155",[6]="rbxassetid://105207783752500",[9]="rbxassetid://85299683248138"}
function P.fill(container,id,stars,silhouette,_distanceScale)
 local stage=C.stage(stars)
 local imageId=id=="MeadowMouse" and (package:GetAttribute("MossratPortraitS"..stage) or defaults[stage]) or nil
 local image=Instance.new("ImageLabel") image.Name="MonsterPortraitImage"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ScaleType=Enum.ScaleType.Fit image.ZIndex=container.ZIndex+1
 image.Image=type(imageId)=="string" and imageId or ""
 image.ImageColor3=silhouette and Color3.new(0,0,0) or Color3.new(1,1,1)
 image.Parent=container
 if image.Image=="" then
  local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
  label.Text="?" label.TextScaled=true label.TextColor3=Color3.fromRGB(160,180,170) label.Parent=container
 end
 return image
end
return P
]=]},{node=C:FindFirstChild([=[QuadrupedAnimator]=]),before=[=[local motion=require(game.ReplicatedStorage.RodeoFantasy.QuadrupedMotion)
local A={}
local cache=setmetatable({},{__mode="k"})
function A.apply(model,moving,dt)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,legs={},phase=0,weight=0,gait=0}
  for _,side in ipairs({"Left","Right"}) do
   for _,limb in ipairs({"Front","Rear"}) do
    local name=side..limb
    local upper=body:FindFirstChild(name.."Upper",true)
    local lower=body:FindFirstChild(name.."Lower",true)
    local paw=body:FindFirstChild(name.."Paw",true)
    if upper and lower and paw and lower.Parent==upper and paw.Parent==lower then
     local u,l=lower.CFrame.Position,paw.CFrame.Position
     local a,b=Vector2.new(u.Y,u.Z).Magnitude,Vector2.new(l.Y,l.Z).Magnitude
     if a>.001 and b>.001 then
      c.legs[#c.legs+1]={name=name,upper=upper,lower=lower,paw=paw,a=a,b=b,
       y=u.Y+l.Y,z=u.Z+l.Z,restA=math.atan2(u.Z,-u.Y),restB=math.atan2(l.Z,-l.Y),bend=limb=="Front" and -1 or 1}
     end
    end
   end
  end
  cache[model]=c
 end
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=speed>18
 c.gait+=((running and 1 or 0)-c.gait)*(1-math.exp(-8*dt))
 c.weight+=( (moving and 1 or 0)-c.weight)*(1-math.exp(-12*dt))
 if moving then c.phase=(c.phase+dt*math.clamp(speed/math.max(body.Size.Y*2,1),.7,2.8))%1 end
 for _,leg in ipairs(c.legs) do
  local length=leg.a+leg.b
  local walkZ,walkLift=motion.foot(c.phase,leg.name,false)
  local runZ,runLift=motion.foot(c.phase,leg.name,true)
  local z=walkZ+(runZ-walkZ)*c.gait
  local lift=walkLift+(runLift-walkLift)*c.gait
  local a,b=motion.solve(leg.y+length*(.06+lift*.22),leg.z+z*length*(.45+.20*c.gait),leg.a,leg.b,leg.bend)
  local upper=-(a-leg.restA)
  local lower=-(b-leg.restB)-upper
  leg.upper.Transform=CFrame.identity:Lerp(CFrame.Angles(upper,0,0),c.weight)
  leg.lower.Transform=CFrame.identity:Lerp(CFrame.Angles(lower,0,0),c.weight)
  leg.paw.Transform=CFrame.identity:Lerp(CFrame.Angles(-upper-lower,0,0),c.weight)
 end
end
return A
]=],after=[=[local motion=require(game.ReplicatedStorage.RodeoFantasy.QuadrupedMotion)
local A={}
local cache=setmetatable({},{__mode="k"})
function A.apply(model,moving,dt)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,legs={},phase=0,weight=0,gait=0}
  for _,side in ipairs({"Left","Right"}) do
   for _,limb in ipairs({"Front","Rear"}) do
    local name=side..limb
    local upper=body:FindFirstChild(name.."Upper",true)
    local lower=body:FindFirstChild(name.."Lower",true)
    local paw=body:FindFirstChild(name.."Paw",true)
    if upper and lower and paw and lower.Parent==upper and paw.Parent==lower then
     local u,l=lower.CFrame.Position,paw.CFrame.Position
     local a,b=Vector2.new(u.Y,u.Z).Magnitude,Vector2.new(l.Y,l.Z).Magnitude
     if a>.001 and b>.001 then
      c.legs[#c.legs+1]={name=name,upper=upper,lower=lower,paw=paw,a=a,b=b,
       y=u.Y+l.Y,z=u.Z+l.Z,restA=math.atan2(u.Z,-u.Y),restB=math.atan2(l.Z,-l.Y),bend=limb=="Front" and -1 or 1}
     end
    end
   end
  end
  cache[model]=c
 end
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=speed>18
 c.gait+=((running and 1 or 0)-c.gait)*(1-math.exp(-8*dt))
 c.weight+=( (moving and 1 or 0)-c.weight)*(1-math.exp(-12*dt))
 if moving then c.phase=(c.phase+dt*math.clamp(speed/math.max(body.Size.Y*2,1),.7,2.8))%1 end
 for _,leg in ipairs(c.legs) do
  local length=leg.a+leg.b
  local walkZ,walkLift=motion.foot(c.phase,leg.name,false)
  local runZ,runLift=motion.foot(c.phase,leg.name,true)
  local z=walkZ+(runZ-walkZ)*c.gait
  local lift=walkLift+(runLift-walkLift)*c.gait
  local a,b=motion.solve(leg.y+length*(.06+lift*.22),leg.z+z*length*(.45+.20*c.gait),leg.a,leg.b,leg.bend)
  local upper=-(a-leg.restA)
  local lower=-(b-leg.restB)-upper
  leg.upper.Transform=CFrame.identity:Lerp(CFrame.Angles(upper,0,0),c.weight)
  leg.lower.Transform=CFrame.identity:Lerp(CFrame.Angles(lower,0,0),c.weight)
  leg.paw.Transform=CFrame.identity:Lerp(CFrame.Angles(-upper-lower,0,0),c.weight)
 end
end
return A
]=]},{node=C:FindFirstChild([=[JournalUI]=]),before=[=[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local BagRules=require(package.BagRules)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
local Planets=require(package.PlanetCatalog)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Buttons=require(script.Parent:WaitForChild("BagUI"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(kind,props,parent)
 local n=Instance.new(kind)
 if n:IsA("TextLabel") or n:IsA("TextButton") then
  n.Font=Enum.Font.GothamBlack n.TextColor3=Color3.new(1,1,1)
  n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0
 end
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
local function label(parent,name,value,x,y,w,h,max)
 local n=make("TextLabel",{Name=name,Text=value,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundTransparency=1,TextScaled=true,TextWrapped=true,ZIndex=45},parent)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=max},n) return n
end
local function panel(parent,name,x,y,w,h,color)
 local n=make("Frame",{Name=name,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color,BorderSizePixel=0,ZIndex=42},parent)
 make("UIStroke",{Color=Color3.fromRGB(10,14,20),Thickness=2},n) return n
end
local function gradient(parent,a,b)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new(a,b)},parent)
end
local function T(v) return L.text(v,"en-us") end
function J.new(gui,remote)
 local allEntries=Q.entries(C)
 local self={area="Lobby",planet="GreenStar",page=1,seen={},data={},entries=allEntries,perSpread=8,selected=1}
 local button=Buttons.iconButton(gui,"Journal","T",92)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.91,.82),BackgroundColor3=Color3.fromRGB(54,58,72),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1000,620)},book)
 make("UIStroke",{Color=Color3.fromRGB(8,12,19),Thickness=3},book)
 gradient(book,Color3.fromRGB(71,77,96),Color3.fromRGB(37,39,52))
 -- Smooth plate seams, rather than studs, carry the reference's dark framing.
 for i=1,15 do
  make("Frame",{Name="FrameSeam",Position=UDim2.fromScale(i/16,0),Size=UDim2.fromScale(.002,1),BackgroundColor3=Color3.fromRGB(100,108,129),BackgroundTransparency=.8,BorderSizePixel=0,ZIndex=40},book)
 end
 local header=panel(book,"IndexHeader",.008,.012,.984,.12,Color3.fromRGB(22,204,247))
 gradient(header,Color3.fromRGB(117,241,255),Color3.fromRGB(0,167,228))
 label(header,"Title","Pet Index",.02,.05,.7,.85,30).TextXAlignment=Enum.TextXAlignment.Left
 local close=make("TextButton",{Name="CloseJournal",Text="X",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(255,56,60),TextSize=30,BorderSizePixel=0,ZIndex=47},header)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},close)
 gradient(close,Color3.fromRGB(255,131,129),Color3.fromRGB(241,24,34))
 local region=panel(book,"PlanetLandscape",.02,.16,.14,.68,Color3.fromRGB(37,93,29))
 gradient(region,Color3.fromRGB(127,186,62),Color3.fromRGB(24,73,39))
 label(region,"PlanetName","Green Star",.04,.04,.92,.2,23)
 label(region,"Biome","Meadow",.08,.66,.84,.18,22)
 local planet=make("Frame",{Name="GreenStarPlanet",Position=UDim2.fromScale(.13,.30),Size=UDim2.fromScale(.74,.28),BackgroundColor3=Color3.fromRGB(98,209,45),BorderSizePixel=0,ZIndex=43},region)
 make("UICorner",{CornerRadius=UDim.new(1,0)},planet)
 make("UIAspectRatioConstraint",{AspectRatio=1},planet)
 gradient(planet,Color3.fromRGB(166,237,66),Color3.fromRGB(19,100,55))
 make("UIStroke",{Color=Color3.fromRGB(158,255,157),Thickness=2},planet)
 local art=make("ImageLabel",{Name="GreenStarArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.01,.23),Size=UDim2.fromScale(.98,.42),ScaleType=Enum.ScaleType.Fit,ZIndex=44},region)
 task.spawn(function() while art.Parent and not art.IsLoaded do task.wait(.25) end if art.Parent then planet.Visible=false end end)
 local pages=panel(book,"JournalEntries",.18,.16,.50,.53,Color3.fromRGB(23,27,35))
 local progress=panel(book,"CollectionProgress",.18,.72,.50,.12,Color3.fromRGB(14,18,25))
 local progressFill=make("Frame",{Name="ProgressFill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(26,220,84),BorderSizePixel=0,ZIndex=43},progress)
 gradient(progressFill,Color3.fromRGB(103,255,68),Color3.fromRGB(8,138,55))
 local progressText=label(progress,"ProgressCount","",0,0,1,1,32)
 local detail=panel(book,"SelectedMonster",.70,.16,.28,.42,Color3.fromRGB(14,99,181))
 gradient(detail,Color3.fromRGB(30,148,235),Color3.fromRGB(8,31,60))
 local info=panel(book,"MonsterInformation",.70,.61,.28,.23,Color3.fromRGB(21,68,40))
 gradient(info,Color3.fromRGB(35,110,57),Color3.fromRGB(13,37,24))
 local bottom=panel(book,"UnlockSummary",.02,.88,.96,.095,Color3.fromRGB(17,20,29))
 local summary=label(bottom,"JournalCount","",.1,0,.68,1,24)
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(2,0),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-2,0,0),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local pageNumber=label(bottom,"JournalPage","",.79,0,.12,1,15)
 local planetTab=make("Frame",{Name="PlanetTabs",Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.68),BackgroundTransparency=1,ZIndex=46},book)
 local planetButtons={}
 for index,id in ipairs(Planets.Order) do
  local p=Planets[id]
  local tab=make("TextButton",{Name="Planet_"..id,Text="",Position=UDim2.fromScale(0,(index-1)/4),Size=UDim2.fromScale(1,.23),BackgroundColor3=Color3.fromRGB(42,99,112),BorderSizePixel=0,ZIndex=46},planetTab)
  make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},tab)
  local text=label(tab,"PlanetTabLabel",p.Name,.36,.04,.62,.92,21) text.ZIndex=47
  make("ImageLabel",{Name=id.."TabArtwork",Image=p.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.015,.08),Size=UDim2.fromScale(.34,.84),ScaleType=Enum.ScaleType.Fit,ZIndex=47},tab)
  table.insert(planetButtons,tab)
  tab.Activated:Connect(function()
   self.planet=id self.page=1 self.selected=1 self.entries={}
   for _,entry in ipairs(allEntries) do if (C[entry.monsterId].Planet or "GreenStar")==id then table.insert(self.entries,entry) end end
   art.Image=p.Image region.PlanetName.Text=p.Name region.Biome.Visible=id=="GreenStar"
   self.render()
  end)
 end
 local compact=false
 local lockedHumanoid,savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h and h~=lockedHumanoid then
   lockedHumanoid=h savedWalk=h.WalkSpeed savedJump=h.JumpPower savedRotate=h.AutoRotate savedHeight=h.JumpHeight
   h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0 h.AutoRotate=false
  end
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid:Move(Vector3.zero) end
 end
 local function unlock()
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.WalkSpeed=savedWalk lockedHumanoid.JumpPower=savedJump lockedHumanoid.JumpHeight=savedHeight lockedHumanoid.AutoRotate=savedRotate end
  lockedHumanoid=nil CAS:UnbindAction("JournalPages")
 end
 function self.close() book.Visible=false unlock() end
 local function selectedDetail()
  for _,n in ipairs(detail:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  for _,n in ipairs(info:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local entry=self.entries[self.selected] if not entry then return end
  local species=C[entry.monsterId] local revealed=self.seen[entry.key]==true
  local viewport=make("Frame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income(BagRules.income({stars=entry.stars,incomeAmount=species.IncomeAmount}),species.IncomeSeconds or 3,"en-us") or "???",.04,.87,.92,.12,20)
  income.TextColor3=Color3.fromRGB(97,255,61)
  label(info,"Acquisition",revealed and (entry.stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,"en-us") or L.evolutionHint(entry.stars,"en-us")) or "Collect to reveal details",.05,.05,.9,.58,16)
  label(info,"Caught",T("Caught").." "..(self.data.caught and self.data.caught[entry.key] or 0),.05,.67,.9,.26,17)
 end
 function self.render()
  for _,n in ipairs(pages:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) self.page=math.clamp(self.page,1,max)
  self.selected=math.clamp(self.selected,1,math.max(1,#self.entries))
  pageNumber.Text=self.page.." / "..max
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text=T("Unlocked")..": "..discovered.."/"..#self.entries
  progressText.Text=discovered.."/"..#self.entries progressFill.Size=UDim2.fromScale(#self.entries>0 and discovered/#self.entries or 0,1)
  previous.Visible=max>1 nextPage.Visible=max>1
  local colors={Color3.fromRGB(83,181,78),Color3.fromRGB(26,139,232),Color3.fromRGB(203,73,229),Color3.fromRGB(242,190,32)}
  local columns=(compact or #self.entries<=4) and 2 or 4
  for slot=1,self.perSpread do
   local index=(self.page-1)*self.perSpread+slot local entry=self.entries[index] if not entry then break end
   local revealed=self.seen[entry.key]==true
   local rows=math.max(2,math.ceil(math.min(self.perSpread,#self.entries)/columns))
   local card=make("TextButton",{Name="JournalEntry",Text="",Position=UDim2.fromScale(((slot-1)%columns)/columns+.01,math.floor((slot-1)/columns)/rows+.015),Size=UDim2.fromScale(1/columns-.02,1/rows-.03),BackgroundColor3=colors[((slot-1)%4)+1],BorderSizePixel=0,ZIndex=44},pages)
   make("UIStroke",{Color=index==self.selected and Color3.fromRGB(232,250,255) or Color3.new(0,0,0),Thickness=index==self.selected and 3 or 2},card)
   gradient(card,Color3.fromRGB(218,230,235),Color3.fromRGB(50,86,108))
   local viewport=make("Frame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,ZIndex=45},card)
   Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
   label(card,"EntryName",revealed and T(entry.monsterId) or "???",.02,.01,.96,.19,17)
   label(card,"Stars",entry.stars.."★",0,.82,1,.18,16)
   card.Activated:Connect(function() self.selected=index self.render() end)
  end
  selectedDetail()
  if #self.entries==0 then label(pages,"NoEntries","No entries here yet",.05,.35,.90,.25,22) end
  for index,tab in ipairs(planetButtons) do tab.BackgroundColor3=Planets.Order[index]==self.planet and Color3.fromRGB(59,160,90) or Color3.fromRGB(42,99,112) end
 end
 function self.turn(direction)
  if not book.Visible then return end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) local page=math.clamp(self.page+direction,1,max)
  if self.page==page then return end self.page=page self.render() Audio.ui("PageTurn")
 end
 function self.open()
  if self.area=="Hunt" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze() self.render() Audio.ui("BookOpen")
  if not self.other then remote:FireServer("Journal") end
  CAS:BindActionAtPriority("JournalPages",function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then self.turn(-1)
    elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then self.turn(1) end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
 end
 function self.viewOther(data) self.other=true self.close() self.snapshot(data) self.open() end
 function self.snapshot(data) self.data=data self.seen=data.seen or self.seen if book.Visible then self.render() end end
 function self.state(data)
  self.area=data.area button.Visible=self.area~="Hunt"
  if self.area=="Hunt" then self.close() end
  if book.Visible and not self.other and data.count~=self.lastCount then remote:FireServer("Journal") end self.lastCount=data.count
 end
 local function resize()
  local camera=workspace.CurrentCamera
  compact=camera and camera.ViewportSize.X<860 or false
  if compact then
   book.Position=UDim2.fromScale(.5,.5) book.Size=UDim2.fromScale(.92,.86)
   region.Visible=false planetTab.Position=UDim2.fromScale(.02,.15) planetTab.Size=UDim2.fromScale(.96,.13)
   pages.Position=UDim2.fromScale(.02,.30) pages.Size=UDim2.fromScale(.65,.44)
   progress.Position=UDim2.fromScale(.02,.76) progress.Size=UDim2.fromScale(.65,.08)
   detail.Position=UDim2.fromScale(.70,.30) detail.Size=UDim2.fromScale(.28,.51)
   info.Visible=false
  else
   book.Position=UDim2.fromScale(.44,.5) book.Size=UDim2.fromScale(.76,.82)
   region.Visible=true planetTab.Position=UDim2.fromScale(1.025,.17) planetTab.Size=UDim2.fromScale(.18,.68)
   pages.Position=UDim2.fromScale(.18,.16) pages.Size=UDim2.fromScale(.50,.53)
   progress.Position=UDim2.fromScale(.18,.72) progress.Size=UDim2.fromScale(.50,.12)
   detail.Position=UDim2.fromScale(.70,.16) detail.Size=UDim2.fromScale(.28,.42) info.Visible=true
  end
  for index,tab in ipairs(planetButtons) do
   tab.Position=compact and UDim2.fromScale((index-1)/4,0) or UDim2.fromScale(0,(index-1)/4)
   tab.Size=compact and UDim2.fromScale(.24,1) or UDim2.fromScale(1,.23)
  end
  if book.Visible then self.render() end
 end
 -- Decide from screen width, not a size this callback itself changes.
 local function screenLayout()
  resize()
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(screenLayout) end
 task.defer(screenLayout)
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]=],after=[=[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local BagRules=require(package.BagRules)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
local Planets=require(package.PlanetCatalog)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Buttons=require(script.Parent:WaitForChild("BagUI"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(kind,props,parent)
 local n=Instance.new(kind)
 if n:IsA("TextLabel") or n:IsA("TextButton") then
  n.Font=Enum.Font.GothamBlack n.TextColor3=Color3.new(1,1,1)
  n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0
 end
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
local function label(parent,name,value,x,y,w,h,max)
 local n=make("TextLabel",{Name=name,Text=value,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundTransparency=1,TextScaled=true,TextWrapped=true,ZIndex=45},parent)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=max},n) return n
end
local function panel(parent,name,x,y,w,h,color)
 local n=make("Frame",{Name=name,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color,BorderSizePixel=0,ZIndex=42},parent)
 make("UIStroke",{Color=Color3.fromRGB(10,14,20),Thickness=2},n) return n
end
local function gradient(parent,a,b)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new(a,b)},parent)
end
local function T(v) return L.text(v,"en-us") end
function J.new(gui,remote)
 local allEntries=Q.entries(C)
 local self={area="Lobby",planet="GreenStar",page=1,seen={},data={},entries=allEntries,perSpread=8,selected=1}
 local button=Buttons.iconButton(gui,"Journal","T",92)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.91,.82),BackgroundColor3=Color3.fromRGB(54,58,72),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1000,620)},book)
 make("UIStroke",{Color=Color3.fromRGB(8,12,19),Thickness=3},book)
 gradient(book,Color3.fromRGB(71,77,96),Color3.fromRGB(37,39,52))
 -- Smooth plate seams, rather than studs, carry the reference's dark framing.
 for i=1,15 do
  make("Frame",{Name="FrameSeam",Position=UDim2.fromScale(i/16,0),Size=UDim2.fromScale(.002,1),BackgroundColor3=Color3.fromRGB(100,108,129),BackgroundTransparency=.8,BorderSizePixel=0,ZIndex=40},book)
 end
 local header=panel(book,"IndexHeader",.008,.012,.984,.12,Color3.fromRGB(22,204,247))
 gradient(header,Color3.fromRGB(117,241,255),Color3.fromRGB(0,167,228))
 label(header,"Title","Pet Index",.02,.05,.7,.85,30).TextXAlignment=Enum.TextXAlignment.Left
 local close=make("TextButton",{Name="CloseJournal",Text="X",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(255,56,60),TextSize=30,BorderSizePixel=0,ZIndex=47},header)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},close)
 gradient(close,Color3.fromRGB(255,131,129),Color3.fromRGB(241,24,34))
 local region=panel(book,"PlanetLandscape",.02,.16,.14,.68,Color3.fromRGB(37,93,29))
 gradient(region,Color3.fromRGB(127,186,62),Color3.fromRGB(24,73,39))
 label(region,"PlanetName","Green Star",.04,.04,.92,.2,23)
 label(region,"Biome","Meadow",.08,.66,.84,.18,22)
 local planet=make("Frame",{Name="GreenStarPlanet",Position=UDim2.fromScale(.13,.30),Size=UDim2.fromScale(.74,.28),BackgroundColor3=Color3.fromRGB(98,209,45),BorderSizePixel=0,ZIndex=43},region)
 make("UICorner",{CornerRadius=UDim.new(1,0)},planet)
 make("UIAspectRatioConstraint",{AspectRatio=1},planet)
 gradient(planet,Color3.fromRGB(166,237,66),Color3.fromRGB(19,100,55))
 make("UIStroke",{Color=Color3.fromRGB(158,255,157),Thickness=2},planet)
 local art=make("ImageLabel",{Name="GreenStarArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.01,.23),Size=UDim2.fromScale(.98,.42),ScaleType=Enum.ScaleType.Fit,ZIndex=44},region)
 task.spawn(function() while art.Parent and not art.IsLoaded do task.wait(.25) end if art.Parent then planet.Visible=false end end)
 local pages=panel(book,"JournalEntries",.18,.16,.50,.53,Color3.fromRGB(23,27,35))
 local progress=panel(book,"CollectionProgress",.18,.72,.50,.12,Color3.fromRGB(14,18,25))
 local progressFill=make("Frame",{Name="ProgressFill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(26,220,84),BorderSizePixel=0,ZIndex=43},progress)
 gradient(progressFill,Color3.fromRGB(103,255,68),Color3.fromRGB(8,138,55))
 local progressText=label(progress,"ProgressCount","",0,0,1,1,32)
 local detail=panel(book,"SelectedMonster",.70,.16,.28,.42,Color3.fromRGB(14,99,181))
 gradient(detail,Color3.fromRGB(30,148,235),Color3.fromRGB(8,31,60))
 local info=panel(book,"MonsterInformation",.70,.61,.28,.23,Color3.fromRGB(21,68,40))
 gradient(info,Color3.fromRGB(35,110,57),Color3.fromRGB(13,37,24))
 local bottom=panel(book,"UnlockSummary",.02,.88,.96,.095,Color3.fromRGB(17,20,29))
 local summary=label(bottom,"JournalCount","",.1,0,.68,1,24)
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(2,0),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-2,0,0),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local pageNumber=label(bottom,"JournalPage","",.79,0,.12,1,15)
 local planetTab=make("Frame",{Name="PlanetTabs",Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.68),BackgroundTransparency=1,ZIndex=46},book)
 local planetButtons={}
 for index,id in ipairs(Planets.Order) do
  local p=Planets[id]
  local tab=make("TextButton",{Name="Planet_"..id,Text="",Position=UDim2.fromScale(0,(index-1)/4),Size=UDim2.fromScale(1,.23),BackgroundColor3=Color3.fromRGB(42,99,112),BorderSizePixel=0,ZIndex=46},planetTab)
  make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},tab)
  local text=label(tab,"PlanetTabLabel",p.Name,.36,.04,.62,.92,21) text.ZIndex=47
  make("ImageLabel",{Name=id.."TabArtwork",Image=p.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.015,.08),Size=UDim2.fromScale(.34,.84),ScaleType=Enum.ScaleType.Fit,ZIndex=47},tab)
  table.insert(planetButtons,tab)
  tab.Activated:Connect(function()
   self.planet=id self.page=1 self.selected=1 self.entries={}
   for _,entry in ipairs(allEntries) do if (C[entry.monsterId].Planet or "GreenStar")==id then table.insert(self.entries,entry) end end
   art.Image=p.Image region.PlanetName.Text=p.Name region.Biome.Visible=id=="GreenStar"
   self.render()
  end)
 end
 local compact=false
 local lockedHumanoid,savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h and h~=lockedHumanoid then
   lockedHumanoid=h savedWalk=h.WalkSpeed savedJump=h.JumpPower savedRotate=h.AutoRotate savedHeight=h.JumpHeight
   h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0 h.AutoRotate=false
  end
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid:Move(Vector3.zero) end
 end
 local function unlock()
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.WalkSpeed=savedWalk lockedHumanoid.JumpPower=savedJump lockedHumanoid.JumpHeight=savedHeight lockedHumanoid.AutoRotate=savedRotate end
  lockedHumanoid=nil CAS:UnbindAction("JournalPages")
 end
 function self.close() book.Visible=false unlock() end
 local function selectedDetail()
  for _,n in ipairs(detail:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  for _,n in ipairs(info:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local entry=self.entries[self.selected] if not entry then return end
  local species=C[entry.monsterId] local revealed=self.seen[entry.key]==true
  local viewport=make("Frame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income(BagRules.income({stars=entry.stars,incomeAmount=species.IncomeAmount}),species.IncomeSeconds or 3,"en-us") or "???",.04,.87,.92,.12,20)
  income.TextColor3=Color3.fromRGB(97,255,61)
  label(info,"Acquisition",revealed and (entry.stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,"en-us") or L.evolutionHint(entry.stars,"en-us")) or "Collect to reveal details",.05,.05,.9,.58,16)
  label(info,"Caught",T("Caught").." "..(self.data.caught and self.data.caught[entry.key] or 0),.05,.67,.9,.26,17)
 end
 function self.render()
  for _,n in ipairs(pages:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) self.page=math.clamp(self.page,1,max)
  self.selected=math.clamp(self.selected,1,math.max(1,#self.entries))
  pageNumber.Text=self.page.." / "..max
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text=T("Unlocked")..": "..discovered.."/"..#self.entries
  progressText.Text=discovered.."/"..#self.entries progressFill.Size=UDim2.fromScale(#self.entries>0 and discovered/#self.entries or 0,1)
  previous.Visible=max>1 nextPage.Visible=max>1
  local colors={Color3.fromRGB(83,181,78),Color3.fromRGB(26,139,232),Color3.fromRGB(203,73,229),Color3.fromRGB(242,190,32)}
  local columns=(compact or #self.entries<=4) and 2 or 4
  for slot=1,self.perSpread do
   local index=(self.page-1)*self.perSpread+slot local entry=self.entries[index] if not entry then break end
   local revealed=self.seen[entry.key]==true
   local rows=math.max(2,math.ceil(math.min(self.perSpread,#self.entries)/columns))
   local card=make("TextButton",{Name="JournalEntry",Text="",Position=UDim2.fromScale(((slot-1)%columns)/columns+.01,math.floor((slot-1)/columns)/rows+.015),Size=UDim2.fromScale(1/columns-.02,1/rows-.03),BackgroundColor3=colors[((slot-1)%4)+1],BorderSizePixel=0,ZIndex=44},pages)
   make("UIStroke",{Color=index==self.selected and Color3.fromRGB(232,250,255) or Color3.new(0,0,0),Thickness=index==self.selected and 3 or 2},card)
   gradient(card,Color3.fromRGB(218,230,235),Color3.fromRGB(50,86,108))
   local viewport=make("Frame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,ZIndex=45},card)
   Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
   label(card,"EntryName",revealed and T(entry.monsterId) or "???",.02,.01,.96,.19,17)
   label(card,"Stars",entry.stars.."★",0,.82,1,.18,16)
   card.Activated:Connect(function() self.selected=index self.render() end)
  end
  selectedDetail()
  if #self.entries==0 then label(pages,"NoEntries","No entries here yet",.05,.35,.90,.25,22) end
  for index,tab in ipairs(planetButtons) do tab.BackgroundColor3=Planets.Order[index]==self.planet and Color3.fromRGB(59,160,90) or Color3.fromRGB(42,99,112) end
 end
 function self.turn(direction)
  if not book.Visible then return end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) local page=math.clamp(self.page+direction,1,max)
  if self.page==page then return end self.page=page self.render() Audio.ui("PageTurn")
 end
 function self.open()
  if self.area=="Hunt" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze() self.render() Audio.ui("BookOpen")
  if not self.other then remote:FireServer("Journal") end
  CAS:BindActionAtPriority("JournalPages",function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then self.turn(-1)
    elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then self.turn(1) end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
 end
 function self.viewOther(data) self.other=true self.close() self.snapshot(data) self.open() end
 function self.snapshot(data) self.data=data self.seen=data.seen or self.seen if book.Visible then self.render() end end
 function self.state(data)
  self.area=data.area button.Visible=self.area~="Hunt"
  if self.area=="Hunt" then self.close() end
  if book.Visible and not self.other and data.count~=self.lastCount then remote:FireServer("Journal") end self.lastCount=data.count
 end
 local function resize()
  local camera=workspace.CurrentCamera
  compact=camera and camera.ViewportSize.X<860 or false
  if compact then
   book.Position=UDim2.fromScale(.5,.5) book.Size=UDim2.fromScale(.92,.86)
   region.Visible=false planetTab.Position=UDim2.fromScale(.02,.15) planetTab.Size=UDim2.fromScale(.96,.13)
   pages.Position=UDim2.fromScale(.02,.30) pages.Size=UDim2.fromScale(.65,.44)
   progress.Position=UDim2.fromScale(.02,.76) progress.Size=UDim2.fromScale(.65,.08)
   detail.Position=UDim2.fromScale(.70,.30) detail.Size=UDim2.fromScale(.28,.51)
   info.Visible=false
  else
   book.Position=UDim2.fromScale(.44,.5) book.Size=UDim2.fromScale(.76,.82)
   region.Visible=true planetTab.Position=UDim2.fromScale(1.025,.17) planetTab.Size=UDim2.fromScale(.18,.68)
   pages.Position=UDim2.fromScale(.18,.16) pages.Size=UDim2.fromScale(.50,.53)
   progress.Position=UDim2.fromScale(.18,.72) progress.Size=UDim2.fromScale(.50,.12)
   detail.Position=UDim2.fromScale(.70,.16) detail.Size=UDim2.fromScale(.28,.42) info.Visible=true
  end
  for index,tab in ipairs(planetButtons) do
   tab.Position=compact and UDim2.fromScale((index-1)/4,0) or UDim2.fromScale(0,(index-1)/4)
   tab.Size=compact and UDim2.fromScale(.24,1) or UDim2.fromScale(1,.23)
  end
  if book.Visible then self.render() end
 end
 -- Decide from screen width, not a size this callback itself changes.
 local function screenLayout()
  resize()
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(screenLayout) end
 task.defer(screenLayout)
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]=]}}
for _,u in ipairs(updates) do assert(u.node and (u.node.Source:gsub("\r\n","\n")==u.before or u.node.Source:gsub("\r\n","\n")==u.after),"Source changed") end
local backup=Instance.new("Folder") backup.Name="PetRulesBackup_"..game.HttpService:GenerateGUID(false) backup.Parent=game.ServerStorage
game.ChangeHistoryService:SetWaypoint("Before pet rules update")
for _,u in ipairs(updates) do u.node:Clone().Parent=backup u.node.Source=u.after end
local fix=(function()
-- Reversible, idempotent repair: inset the buried core faces from the trim.
local M={}
function M.apply(airport)
 local count=0
 for _,part in ipairs(airport:GetChildren()) do
  if part:IsA("BasePart") and part.Name=="DockLayer" and not part:GetAttribute("DockSurfaceV2") then
   part:SetAttribute("DockOriginalSize",part.Size)
   part.Size-=Vector3.new(.08,0,.08)
   part:SetAttribute("DockSurfaceV2",true) count+=1
  end
 end
 return count
end
return M

end)()
local airport=workspace.RodeoLobby.Airport
for _,n in ipairs(airport:GetChildren()) do if n.Name=="DockLayer" then n:Clone().Parent=backup end end
local fixed=fix.apply(airport)
P:SetAttribute("MossratPortraitS6","rbxassetid://105207783752500")
P:SetAttribute("MossratPortraitS9","rbxassetid://85299683248138")
game.ChangeHistoryService:SetWaypoint("Pet rules updated")
print("PET_RULES_INSTALLED",#updates,"scripts",fixed,"dock cores")
