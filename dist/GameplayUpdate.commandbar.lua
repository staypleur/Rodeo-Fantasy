assert(not game:GetService("RunService"):IsRunning(),"Stop Play")
assert(game.GameId==10770388358,"Wrong experience")
local package=game.ReplicatedStorage.RodeoFantasy
local client=game.StarterPlayer.StarterPlayerScripts
local server=game.ServerScriptService
local changes={{name=[=[BagUI]=],parent=client,optional=false,before=[=[local UI={}
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
 button.Visible=false
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 make("ImageLabel",{Name="BagMoneyIcon",Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.fromOffset(34,34),ScaleType=Enum.ScaleType.Fit,ZIndex=21},window)
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
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=8,Active=true,ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=21},window)
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
  scroll.CanvasPosition=Vector2.zero
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
 local layout
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
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) scroll.CanvasPosition=Vector2.zero self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 scroll.CanvasPosition=Vector2.zero self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("ScrollingFrame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,BorderSizePixel=0,Active=true,ScrollingDirection=Enum.ScrollingDirection.Y,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=8,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,4 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="Hatchery".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Manage",index) end end)
 end
 -- Use available safe-area height, rather than a fixed desktop header.
 layout=function()
  if not window.Parent then return end
  local size=gui.AbsoluteSize
  local compact=size.Y<600 or size.X<600
  window.Size=UDim2.fromScale(.94,compact and .94 or .84)
  local narrow=window.AbsoluteSize.X<560
  local row=compact and 42 or 55
  title.Position=UDim2.fromOffset(16,4)
  title.Size=UDim2.new(1,-76,0,compact and 32 or 40)
  title.TextSize=compact and 20 or 26
  close.Position=UDim2.new(1,-48,0,4) close.Size=UDim2.fromOffset(44,36)
  window.BagMoneyIcon.Position=UDim2.fromOffset(16,row)
  window.BagMoneyIcon.Size=UDim2.fromOffset(30,30)
  money.Position=UDim2.fromOffset(48,row)
  money.Size=UDim2.new(narrow and .48 or .30,-52,0,34)
  search.Position=UDim2.new(narrow and .50 or .32,0,0,row)
  search.Size=UDim2.new(narrow and .46 or .27,0,0,34)
  local actionY=narrow and row+40 or row
  breed.Position=UDim2.new(narrow and .04 or .62,0,0,actionY)
  breed.Size=UDim2.new(narrow and .44 or .17,0,0,34)
  evolveToggle.Position=UDim2.new(narrow and .52 or .81,0,0,actionY)
  evolveToggle.Size=breed.Size
  local tabsY=compact and actionY+42 or 136
  tabs.Position=UDim2.fromOffset(16,tabsY) tabs.Size=UDim2.new(1,-32,0,34)
  local top=tabsY+42
  evolveControls.Position=UDim2.fromOffset(16,top)
  if narrow then
   evolveControls.Size=UDim2.new(1,-32,0,90)
   evolveStatus.Size=UDim2.new(1,-64,0,38) evolveStatus.TextWrapped=true
   evolvePreview.Position=UDim2.new(1,-54,0,2)
   evolveCancel.Position=UDim2.new(0,8,0,48) evolveCancel.Size=UDim2.new(.45,-12,0,36)
   evolveConfirm.Position=UDim2.new(.5,0,0,48) evolveConfirm.Size=UDim2.new(.5,-8,0,36)
  else
   evolveControls.Size=UDim2.new(1,-32,0,58)
   evolveStatus.Size=UDim2.new(1,-258,1,0) evolveStatus.TextWrapped=false
   evolvePreview.Position=UDim2.new(1,-248,0,5)
   evolveCancel.Position=UDim2.new(1,-194,0,12) evolveCancel.Size=UDim2.fromOffset(80,34)
   evolveConfirm.Position=UDim2.new(1,-108,0,12) evolveConfirm.Size=UDim2.fromOffset(100,34)
  end
  if self.evolutionMode then top+=narrow and 96 or 66 end
  scroll.Position=UDim2.fromOffset(16,top)
  scroll.Size=UDim2.new(1,-32,1,-top-42)
  previous.Position=UDim2.new(.35,-45,1,-38)
  pageLabel.Position=UDim2.new(.35,0,1,-38)
  nextPage.Position=UDim2.new(.65,5,1,-38)
  local grid=scroll:FindFirstChildOfClass("UIGridLayout")
  local columns=math.max(1,math.floor((scroll.AbsoluteSize.X-10+12)/182))
  grid.CellSize=UDim2.fromOffset(math.min(190,math.floor((scroll.AbsoluteSize.X-10-(columns-1)*12)/columns)),compact and 194 or 245)
  for _,card in ipairs(scroll:GetChildren()) do
   if card:IsA("Frame") then
    local preview=card:FindFirstChild("MonsterImage")
    if preview then preview.Size=UDim2.new(1,0,0,compact and 90 or 140) end
    local name=card:FindFirstChild("MonsterName")
    if name then name.Position=UDim2.fromOffset(4,compact and 90 or 140) end
    local income=card:FindFirstChild("Income")
    if income then income.Position=UDim2.fromOffset(4,compact and 118 or 172) end
    for _,child in ipairs(card:GetChildren()) do
     if child:IsA("TextButton") then child.Position=UDim2.fromOffset(8,compact and 150 or 208) child.Size=UDim2.new(1,-16,0,compact and 38 or 32) end
    end
   end
  end
  chooser.Position=UDim2.fromOffset(16,row+44)
  chooser.Size=UDim2.new(1,-32,1,-row-58)
  local choiceGrid=chooser:FindFirstChildOfClass("UIGridLayout")
  local width=math.max(1,chooser.AbsoluteSize.X-10)
  choiceGrid.CellPadding=UDim2.fromOffset(12,12)
  choiceGrid.CellSize=UDim2.fromOffset(math.floor((width-12)/2),math.clamp(math.floor((chooser.AbsoluteSize.Y-12)/2),56,90))
 end
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 window:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 task.defer(layout)
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
  button.Visible=false -- The paw menu is the single visible bag entry.
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
   make("TextLabel",{Name="MonsterName",Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   local income=make("Frame",{Name="Income",BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),ZIndex=23},card)
   make("ImageLabel",{Name="Money",Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.new(.5,-66,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   local amount=make("TextLabel",{Name="Amount",Text=tostring(item.incomeAmount),BackgroundTransparency=1,Position=UDim2.new(.5,-34,0,0),Size=UDim2.fromOffset(38,30),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=17},amount)
   make("ImageLabel",{Name="Clock",Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"ClockImage"),BackgroundTransparency=1,Position=UDim2.new(.5,5,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Seconds",Text=tostring(item.incomeSeconds),BackgroundTransparency=1,Position=UDim2.new(.5,33,0,0),Size=UDim2.fromOffset(32,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
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
    if not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     summon.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed","en-us").." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
  layout()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve","en-us")
   layout()
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
 button.Visible=false
 local window=make("Frame",{Name="BagWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.92,.84),BackgroundColor3=Color3.new(1,1,1),ZIndex=20},gui)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,208,143)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(213,166,99)),ColorSequenceKeypoint.new(1,Color3.fromRGB(169,116,65))})},window)
 make("UISizeConstraint",{MaxSize=Vector2.new(1100,720)},window)
 make("UICorner",{CornerRadius=UDim.new(0,18)},window)
 make("UIStroke",{Color=Color3.fromRGB(177,151,108),Thickness=1},window)
 local title=make("TextLabel",{Text="Bag",BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-100,0,40),TextSize=26,TextColor3=Color3.fromRGB(43,74,55),ZIndex=21},window)
 local close=make("TextButton",{Name="CloseBag",Text="×",Position=UDim2.new(1,-54,0,12),Size=UDim2.fromOffset(38,34),BackgroundTransparency=1,TextSize=26,TextColor3=Color3.fromRGB(70,58,40),ZIndex=21},window)
 make("ImageLabel",{Name="BagMoneyIcon",Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.fromOffset(34,34),ScaleType=Enum.ScaleType.Fit,ZIndex=21},window)
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
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=8,Active=true,ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=21},window)
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
  scroll.CanvasPosition=Vector2.zero
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
 local discardId=nil
 local confirm=make("Frame",{Name="DiscardConfirmation",Visible=false,Active=true,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(30,24,18),BackgroundTransparency=.12,ZIndex=70},window)
 local prompt=make("TextLabel",{Text="",TextWrapped=true,TextSize=20,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.fromScale(.1,.2),Size=UDim2.fromScale(.8,.35),ZIndex=71},confirm)
 local cancel=make("TextButton",{Text="취소",Position=UDim2.fromScale(.1,.62),Size=UDim2.fromScale(.35,.2),TextSize=20,ZIndex=71},confirm)
 local accept=make("TextButton",{Text="버리기",BackgroundColor3=Color3.fromRGB(190,65,65),TextColor3=Color3.new(1,1,1),Position=UDim2.fromScale(.55,.62),Size=UDim2.fromScale(.35,.2),TextSize=20,ZIndex=71},confirm)
 cancel.Activated:Connect(function() discardId=nil confirm.Visible=false end)
 accept.Activated:Connect(function()
  local id=discardId discardId=nil confirm.Visible=false
  if id and self.area~="Hunt" then remote:FireServer("Discard",id) end
 end)
 window:GetPropertyChangedSignal("Visible"):Connect(function() if not window.Visible then discardId=nil confirm.Visible=false end end)
 local chooser
 local layout
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
 previous.Activated:Connect(function() self.page=math.max(1,self.page-1) scroll.CanvasPosition=Vector2.zero self.snapshot(self.items) end)
 nextPage.Activated:Connect(function() self.page+=1 scroll.CanvasPosition=Vector2.zero self.snapshot(self.items) end)
 function self.close() window.Visible=false self.pen=nil self.setEvolutionMode(false) end
 function self.opened() Audio.ui("BagOpen") if self.onOpen then self.onOpen() end end
 chooser=make("ScrollingFrame",{Name="RanchChooser",Visible=false,BackgroundTransparency=1,BorderSizePixel=0,Active=true,ScrollingDirection=Enum.ScrollingDirection.Y,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=8,Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-130),ZIndex=23},window)
 make("UIGridLayout",{CellSize=UDim2.new(.45,0,0,90),CellPadding=UDim2.fromOffset(18,18)},chooser)
 for index=1,4 do
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="Hatchery".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Manage",index) end end)
 end
 -- Use available safe-area height, rather than a fixed desktop header.
 layout=function()
  if not window.Parent then return end
  local size=gui.AbsoluteSize
  local compact=size.Y<600 or size.X<600
  window.Size=UDim2.fromScale(.94,compact and .94 or .84)
  local narrow=window.AbsoluteSize.X<560
  local row=compact and 42 or 55
  title.Position=UDim2.fromOffset(16,4)
  title.Size=UDim2.new(1,-76,0,compact and 32 or 40)
  title.TextSize=compact and 20 or 26
  close.Position=UDim2.new(1,-48,0,4) close.Size=UDim2.fromOffset(44,36)
  window.BagMoneyIcon.Position=UDim2.fromOffset(16,row)
  window.BagMoneyIcon.Size=UDim2.fromOffset(30,30)
  money.Position=UDim2.fromOffset(48,row)
  money.Size=UDim2.new(narrow and .48 or .30,-52,0,34)
  search.Position=UDim2.new(narrow and .50 or .32,0,0,row)
  search.Size=UDim2.new(narrow and .46 or .27,0,0,34)
  local actionY=narrow and row+40 or row
  breed.Position=UDim2.new(narrow and .04 or .62,0,0,actionY)
  breed.Size=UDim2.new(narrow and .44 or .17,0,0,34)
  evolveToggle.Position=UDim2.new(narrow and .52 or .81,0,0,actionY)
  evolveToggle.Size=breed.Size
  local tabsY=compact and actionY+42 or 136
  tabs.Position=UDim2.fromOffset(16,tabsY) tabs.Size=UDim2.new(1,-32,0,34)
  local top=tabsY+42
  evolveControls.Position=UDim2.fromOffset(16,top)
  if narrow then
   evolveControls.Size=UDim2.new(1,-32,0,90)
   evolveStatus.Size=UDim2.new(1,-64,0,38) evolveStatus.TextWrapped=true
   evolvePreview.Position=UDim2.new(1,-54,0,2)
   evolveCancel.Position=UDim2.new(0,8,0,48) evolveCancel.Size=UDim2.new(.45,-12,0,36)
   evolveConfirm.Position=UDim2.new(.5,0,0,48) evolveConfirm.Size=UDim2.new(.5,-8,0,36)
  else
   evolveControls.Size=UDim2.new(1,-32,0,58)
   evolveStatus.Size=UDim2.new(1,-258,1,0) evolveStatus.TextWrapped=false
   evolvePreview.Position=UDim2.new(1,-248,0,5)
   evolveCancel.Position=UDim2.new(1,-194,0,12) evolveCancel.Size=UDim2.fromOffset(80,34)
   evolveConfirm.Position=UDim2.new(1,-108,0,12) evolveConfirm.Size=UDim2.fromOffset(100,34)
  end
  if self.evolutionMode then top+=narrow and 96 or 66 end
  scroll.Position=UDim2.fromOffset(16,top)
  scroll.Size=UDim2.new(1,-32,1,-top-42)
  previous.Position=UDim2.new(.35,-45,1,-38)
  pageLabel.Position=UDim2.new(.35,0,1,-38)
  nextPage.Position=UDim2.new(.65,5,1,-38)
  local grid=scroll:FindFirstChildOfClass("UIGridLayout")
  local columns=math.max(1,math.floor((scroll.AbsoluteSize.X-10+12)/182))
  grid.CellSize=UDim2.fromOffset(math.min(190,math.floor((scroll.AbsoluteSize.X-10-(columns-1)*12)/columns)),compact and 194 or 245)
  for _,card in ipairs(scroll:GetChildren()) do
   if card:IsA("Frame") then
    local preview=card:FindFirstChild("MonsterImage")
    if preview then preview.Size=UDim2.new(1,0,0,compact and 90 or 140) end
    local name=card:FindFirstChild("MonsterName")
    if name then name.Position=UDim2.fromOffset(4,compact and 90 or 140) end
    local income=card:FindFirstChild("Income")
    if income then income.Position=UDim2.fromOffset(4,compact and 118 or 172) end
    for _,child in ipairs(card:GetChildren()) do
     if child:IsA("TextButton") and child.Name~="DiscardMonster" then child.Position=UDim2.fromOffset(8,compact and 150 or 208) child.Size=UDim2.new(1,-16,0,compact and 38 or 32) end
    end
   end
  end
  chooser.Position=UDim2.fromOffset(16,row+44)
  chooser.Size=UDim2.new(1,-32,1,-row-58)
  local choiceGrid=chooser:FindFirstChildOfClass("UIGridLayout")
  local width=math.max(1,chooser.AbsoluteSize.X-10)
  choiceGrid.CellPadding=UDim2.fromOffset(12,12)
  choiceGrid.CellSize=UDim2.fromOffset(math.floor((width-12)/2),math.clamp(math.floor((chooser.AbsoluteSize.Y-12)/2),56,90))
 end
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 window:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 task.defer(layout)
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
  button.Visible=false -- The paw menu is the single visible bag entry.
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
   local discard=make("TextButton",{Name="DiscardMonster",Text="×",Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(40,40),TextSize=30,BackgroundColor3=Color3.fromRGB(190,65,65),TextColor3=Color3.new(1,1,1),ZIndex=29,Visible=self.area~="Hunt" and not self.evolutionMode and not item.breedingTeam},card)
   discard.Activated:Connect(function()
    discardId=item.id prompt.Text=L.text(item.monsterId,"en-us").." · "..item.stars.."★\n정말 버릴까요? 되돌릴 수 없습니다." confirm.Visible=true
   end)
   self.cards[item.id]=card
   local preview=make("Frame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Name="MonsterName",Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   local income=make("Frame",{Name="Income",BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),ZIndex=23},card)
   make("ImageLabel",{Name="Money",Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage"),BackgroundTransparency=1,Position=UDim2.new(.5,-66,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   local amount=make("TextLabel",{Name="Amount",Text=tostring(item.incomeAmount),BackgroundTransparency=1,Position=UDim2.new(.5,-34,0,0),Size=UDim2.fromOffset(38,30),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=17},amount)
   make("ImageLabel",{Name="Clock",Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"ClockImage"),BackgroundTransparency=1,Position=UDim2.new(.5,5,0,0),Size=UDim2.fromOffset(30,30),ScaleType=Enum.ScaleType.Fit,ZIndex=24},income)
   make("TextLabel",{Name="Seconds",Text=tostring(item.incomeSeconds),BackgroundTransparency=1,Position=UDim2.new(.5,33,0,0),Size=UDim2.fromOffset(32,30),TextSize=17,TextColor3=Color3.fromRGB(43,74,55),ZIndex=24},income)
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
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
    if not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "Dismiss" or "Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     summon.Activated:Connect(function() if self.area=="Lobby" or self.area=="Cafe" then remote:FireServer("Summon",item.id) end end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed","en-us").." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
  layout()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve","en-us")
   layout()
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
]=]},{name=[=[IncomeEffects]=],parent=client,optional=false,before=[=[local E={}
local Tween=game:GetService("TweenService")
local active={}
local function content(parent,amount)
 local label=Instance.new("TextLabel") label.Name="GainAmount"
 label.BackgroundTransparency=1 label.Size=UDim2.new(1,-30,1,0) label.Position=UDim2.fromOffset(30,0)
 label.Text="+"..amount label.TextSize=28 label.Font=Enum.Font.GothamBlack
 label.TextColor3=Color3.fromRGB(255,230,117) label.TextStrokeColor3=Color3.fromRGB(44,64,39) label.TextStrokeTransparency=0
 label.ZIndex=parent:IsA("GuiObject") and parent.ZIndex+1 or 2 label.Parent=parent
 local coin=Instance.new("Frame") coin.Name="GoldCoin" coin.Size=UDim2.fromOffset(25,25) coin.Position=UDim2.new(0,0,.5,-12)
 coin.BackgroundColor3=Color3.fromRGB(250,197,72) coin.BorderSizePixel=0 coin.ZIndex=label.ZIndex coin.Parent=parent
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(1,0) corner.Parent=coin
 local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(170,113,38) stroke.Thickness=2 stroke.Parent=coin
 local shine=Instance.new("Frame") shine.Size=UDim2.fromOffset(4,16) shine.Position=UDim2.fromOffset(10,4)
 shine.BackgroundColor3=Color3.fromRGB(255,239,157) shine.BorderSizePixel=0 shine.ZIndex=label.ZIndex+1 shine.Parent=coin
 return label,coin,shine,stroke
end
local function animate(node,amount,goal)
 active[node]=true
 local label,coin,shine,stroke=content(node,amount)
 local info=TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 local motion=Tween:Create(node,info,goal) motion:Play()
 Tween:Create(label,info,{TextTransparency=1,TextStrokeTransparency=1}):Play()
 Tween:Create(coin,info,{BackgroundTransparency=1}):Play()
 Tween:Create(shine,info,{BackgroundTransparency=1}):Play()
 Tween:Create(stroke,info,{Transparency=1}):Play()
 motion.Completed:Connect(function() active[node]=nil node:Destroy() end)
 return node
end
function E.card(card,amount)
 local node=Instance.new("Frame") node.Name="CoinGain" node.AnchorPoint=Vector2.new(.5,.5)
 node.Position=UDim2.new(.5,0,0,93) node.Size=UDim2.fromOffset(100,38) node.BackgroundTransparency=1 node.ZIndex=30 node.Parent=card
 return animate(node,amount,{Position=UDim2.new(.5,0,0,38)})
end
function E.pet(model,amount)
 local node=Instance.new("BillboardGui") node.Name="PetCoinGain" node.Adornee=model.PrimaryPart
 local height=math.max(3,model:GetExtentsSize().Y*.5+.7)
 node.Size=UDim2.fromOffset(108,45) node.StudsOffset=Vector3.new(0,height,0) node.AlwaysOnTop=true node.MaxDistance=120 node.Parent=model.PrimaryPart
 return animate(node,amount,{StudsOffset=Vector3.new(0,height+2,0)})
end
function E.clear()
 for node in pairs(active) do node:Destroy() end table.clear(active)
end
return E
]=],after=[=[local E={}
local Tween=game:GetService("TweenService")
local active={}
local function content(parent,amount)
 local label=Instance.new("TextLabel") label.Name="GainAmount"
 label.BackgroundTransparency=1 label.Size=UDim2.new(1,-30,1,0) label.Position=UDim2.fromOffset(30,0)
 label.Text="+"..amount label.TextSize=28 label.Font=Enum.Font.GothamBlack
 label.TextColor3=Color3.fromRGB(255,230,117) label.TextStrokeColor3=Color3.fromRGB(44,64,39) label.TextStrokeTransparency=0
 label.ZIndex=parent:IsA("GuiObject") and parent.ZIndex+1 or 2 label.Parent=parent
 local coin=Instance.new("ImageLabel") coin.Name="MoneyGainIcon" coin.Size=UDim2.fromOffset(28,28) coin.Position=UDim2.new(0,0,.5,-14)
 coin.BackgroundTransparency=1 coin.ScaleType=Enum.ScaleType.Fit coin.ZIndex=label.ZIndex
 coin.Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage") coin.Parent=parent
 return label,coin
end
local function animate(node,amount,goal)
 active[node]=true
 local label,coin=content(node,amount)
 local info=TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 local motion=Tween:Create(node,info,goal) motion:Play()
 Tween:Create(label,info,{TextTransparency=1,TextStrokeTransparency=1}):Play()
 Tween:Create(coin,info,{ImageTransparency=1}):Play()
 motion.Completed:Connect(function() active[node]=nil node:Destroy() end)
 return node
end
function E.card(card,amount)
 local node=Instance.new("Frame") node.Name="CoinGain" node.AnchorPoint=Vector2.new(.5,.5)
 node.Position=UDim2.new(.5,0,0,93) node.Size=UDim2.fromOffset(100,38) node.BackgroundTransparency=1 node.ZIndex=30 node.Parent=card
 return animate(node,amount,{Position=UDim2.new(.5,0,0,38)})
end
function E.pet(model,amount)
 local node=Instance.new("BillboardGui") node.Name="PetCoinGain" node.Adornee=model.PrimaryPart
 local height=math.max(3,model:GetExtentsSize().Y*.5+.7)
 node.Size=UDim2.fromOffset(108,45) node.StudsOffset=Vector3.new(0,height,0) node.AlwaysOnTop=true node.MaxDistance=120 node.Parent=model.PrimaryPart
 return animate(node,amount,{StudsOffset=Vector3.new(0,height+2,0)})
end
function E.clear()
 for node in pairs(active) do node:Destroy() end table.clear(active)
end
return E
]=]},{name=[=[PetPromptUI]=],parent=client,optional=false,before=[=[-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local rules=require(package.LobbyRideRules)
 local presentation=require(script.Parent:WaitForChild("RideAnimator"))
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent:WaitForChild("HudIcons")).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent:WaitForChild("HudIcons")).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoCafe") or workspace:FindFirstChild("RodeoLobby")
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
   if not oldCamera then
    oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView}
    -- Clear any first-person fade left by the default camera on mounting.
    for _,node in ipairs(player.Character:GetDescendants()) do
     if node:IsA("BasePart") then node.LocalTransparencyModifier=0 end
    end
   end
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
   camera.Focus=CFrame.new(cameraTarget)
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
 local presentation=require(script.Parent:WaitForChild("RideAnimator"))
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent:WaitForChild("HudIcons")).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent:WaitForChild("HudIcons")).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoCafe") or workspace:FindFirstChild("RodeoLobby")
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
 local input=game:GetService("UserInputService")
 local jumpConnection=input.JumpRequest:Connect(function()
  if player:GetAttribute("LobbyRiding") and not input:GetFocusedTextBox() then package.CaptureRemote:FireServer("RideJump") end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0 local lastInput
 local cameraTarget local cameraHeading local cameraPet
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then
    oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView}
    -- Clear any first-person fade left by the default camera on mounting.
    for _,node in ipairs(player.Character:GetDescendants()) do
     if node:IsA("BasePart") then node.LocalTransparencyModifier=0 end
    end
   end
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
   camera.Focus=CFrame.new(cameraTarget)
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
 gui.Destroying:Connect(function() connection:Disconnect() jumpConnection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]=]},{name=[=[BagRules]=],parent=package,optional=false,before=[=[-- Session-only bag income. Summoning/display never affects income.
local BagRules = {}

function BagRules.new()
 return { monsters = {}, eggs={}, breedingTeams={}, profile={}, pending = 0, balance = 0, gems = 0, serial = 0, totalProduced = 0 }
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
BagRules.Capacity=30

function BagRules.new()
 return { monsters = {}, eggs={}, breedingTeams={}, profile={}, pending = 0, balance = 0, gems = 0, serial = 0, totalProduced = 0 }
end

function BagRules.grant(session, monsterId, clock, incomeSeconds, incomeAmount)
 if #session.monsters>=BagRules.Capacity then return nil,"BagFull" end
	session.serial=(session.serial or 0)+1
	table.insert(session.monsters, { id=session.serial, monsterId = monsterId, stars = 1, lastIncome = clock, incomeSeconds=incomeSeconds, incomeAmount=incomeAmount,sex=BagRules.sexForRoll(math.random()) })
 return session.monsters[#session.monsters]
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
function BagRules.discard(session,id)
 local item=BagRules.find(session,id)
 if not item or item.breedingTeam or item.tradeLock then return false end
 for index,m in ipairs(session.monsters) do if m==item then table.remove(session.monsters,index) break end end
 for index=#(session.profile or {}),1,-1 do if session.profile[index]==id then table.remove(session.profile,index) end end
 return true
end
function BagRules.offline(session,seconds)
 local amount=session.offlineRemainder or 0
 for _,m in ipairs(session.monsters) do amount+=math.max(0,seconds)*.3*BagRules.income(m,1)/(m.incomeSeconds or 3) end
 local whole=math.floor(amount)
 session.offlineRemainder=amount-whole session.pending+=whole
 session.totalProduced=(session.totalProduced or 0)+whole
 return whole
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
]=]},{name=[=[LobbyRideRules]=],parent=package,optional=false,before=[=[-- Lobby riding uses owned pets and server-limited movement.
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
 return 26*(stars>=9 and 1.5 or stars>=6 and 1.3 or stars>=3 and 1.2 or 1)
end
function R.direction(value)
 if typeof(value)~="Vector3" or value.X~=value.X or value.Y~=value.Y or value.Z~=value.Z then return nil end
 if math.abs(value.X)>1000 or math.abs(value.Z)>1000 or math.abs(value.Y)>1000 then return nil end
 local flat=Vector3.new(value.X,0,value.Z)
 return flat.Magnitude>1 and flat.Unit or flat
end
return R
]=]},{name=[=[MonsterCatalog]=],parent=package,optional=false,before=[=[-- User-approved meadow species. All current wild spawns are one-star.
local C={
 MeadowMouse={RunSpeed=64,HerdSpeed=44,SizeClass="Small",Flying=false,RootHeight=2.05,SaddleHeight=2,TameSeconds=5,UnlockMeters=0,IncomeSeconds=3,IncomeAmount=1,Template="RodeoMonsterTemplate",Visual="VisualTemplate"},
 GrassBoar={RunSpeed=64,HerdSpeed=44,SizeClass="Medium",Flying=false,RootHeight=3.0625,SaddleHeight=2.8125,TameSeconds=6,UnlockMeters=300,IncomeSeconds=3,IncomeAmount=2,Template="GrassBoarTemplate",Visual="GrassBoarVisualTemplate"},
 TreeWolf={RunSpeed=76.8,HerdSpeed=52.8,SizeClass="Medium",Flying=false,RootHeight=2.9375,SaddleHeight=2.75,TameSeconds=6,UnlockMeters=300,TripleHop=true,IncomeSeconds=3,IncomeAmount=2,Template="TreeWolfTemplate",Visual="TreeWolfVisualTemplate"},
 Weedcrow={RunSpeed=80,HerdSpeed=55,SizeClass="Small",Flying=true,RootHeight=16,SaddleHeight=1.9,TameSeconds=5,UnlockMeters=400,IncomeSeconds=3,IncomeAmount=2,Template="WeedcrowTemplate",Visual="WeedcrowVisualTemplate"},
 RockElephant={RunSpeed=64,HerdSpeed=44,SizeClass="Large",Flying=false,RootHeight=5.3625,SaddleHeight=5.0325,TameSeconds=7,UnlockMeters=500,IncomeSeconds=3,IncomeAmount=3,Template="RockElephantTemplate",Visual="RockElephantVisualTemplate"},
}
C.Order={"MeadowMouse","GrassBoar"} -- Supplied models and shared motion reviewed and installed.
C.MeadowEndMeters=2000 -- One-star wildlife continues through the approved course.
for _,id in ipairs(C.Order) do C[id].Region=C[id].Region or (C[id].Acquisition=="Breeding" and "Breeding" or "Meadow") C[id].Acquisition=C[id].Acquisition or "Hunt" end
C.Scales={[1]=1,[3]=1.4,[6]=1.9,[9]=2.5}
function C.stage(stars) return stars>=9 and 9 or stars>=6 and 6 or stars>=3 and 3 or 1 end
function C.scale(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 local lower=C.stage(stars)
 if lower==9 then return 2.5+(stars-9)*.2 end
 local upper=lower==1 and 3 or lower+3
 local alpha=(stars-lower)/(upper-lower)
 return C.Scales[lower]+(C.Scales[upper]-C.Scales[lower])*alpha
end
function C.visual(id,stars) local stage=C.stage(stars or 1) return C[id].Visual..(stage==1 and "" or "_S"..stage) end
function C.template(id,stars) local stage=C.stage(stars or 1) return C[id].Template..(stage==1 and "" or "_S"..stage) end
function C.saddleHeight(id,stars)
 stars=stars or 1
 if id=="GrassBoar" then
  local stage=C.stage(stars)
  local package=game and game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
  local visual=package and package:FindFirstChild(C.visual(id,stars))
  local fitted=visual and visual:GetAttribute("MeshyBackHeight")
  if fitted then return fitted*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars) end
  local back={[1]=2.804463,[3]=3.880880,[6]=7.230789,[9]=11.021101}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 if id=="MeadowMouse" then
  local stage=C.stage(stars)
  if stage==1 or stage==3 then
   local package=game and game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
   local visual=package and package:FindFirstChild(C.visual(id,stars))
   local back=visual and visual:GetAttribute("MeshyBackHeight")
   if back then return back*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars) end
   return 1.2*C.scale(stars)
  end
  -- Meshes already contain their approved stage size. Seat above the back,
  -- with a constant clearance for the unscaled player rather than its crown.
  local back={[3]=2.212572,[6]=3.232653,[9]=7.460891}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 return C[id].SaddleHeight*C.scale(stars)
end
function C.pick(meters,serial)
 if meters<0 or meters>=C.MeadowEndMeters then return nil end
 local unlocked={}
 for _,id in ipairs(C.Order) do if meters>=C[id].UnlockMeters then table.insert(unlocked,id) end end
 -- Rotate each equal-share cycle so alternating left/right births do not
 -- permanently assign one species to only one side of the road.
 return unlocked[(serial+math.floor(serial/#unlocked))%#unlocked+1]
end
return C
]=],after=[=[-- User-approved meadow species. All current wild spawns are one-star.
local C={
 MeadowMouse={RunSpeed=64,HerdSpeed=44,SizeClass="Small",Flying=false,RootHeight=2.05,SaddleHeight=2,TameSeconds=5,UnlockMeters=0,IncomeSeconds=3,IncomeAmount=1,Template="RodeoMonsterTemplate",Visual="VisualTemplate"},
 GrassBoar={RunSpeed=64,HerdSpeed=44,SizeClass="Medium",Flying=false,RootHeight=3.0625,SaddleHeight=2.8125,TameSeconds=6,UnlockMeters=300,IncomeSeconds=1,IncomeAmount=2,Template="GrassBoarTemplate",Visual="GrassBoarVisualTemplate"},
 TreeWolf={RunSpeed=76.8,HerdSpeed=52.8,SizeClass="Medium",Flying=false,RootHeight=2.9375,SaddleHeight=2.75,TameSeconds=6,UnlockMeters=300,TripleHop=true,IncomeSeconds=3,IncomeAmount=2,Template="TreeWolfTemplate",Visual="TreeWolfVisualTemplate"},
 Weedcrow={RunSpeed=80,HerdSpeed=55,SizeClass="Small",Flying=true,RootHeight=16,SaddleHeight=1.9,TameSeconds=5,UnlockMeters=400,IncomeSeconds=3,IncomeAmount=2,Template="WeedcrowTemplate",Visual="WeedcrowVisualTemplate"},
 RockElephant={RunSpeed=64,HerdSpeed=44,SizeClass="Large",Flying=false,RootHeight=5.3625,SaddleHeight=5.0325,TameSeconds=7,UnlockMeters=500,IncomeSeconds=3,IncomeAmount=3,Template="RockElephantTemplate",Visual="RockElephantVisualTemplate"},
}
C.Order={"MeadowMouse","GrassBoar"} -- Supplied models and shared motion reviewed and installed.
C.MeadowEndMeters=2000 -- One-star wildlife continues through the approved course.
for _,id in ipairs(C.Order) do C[id].Region=C[id].Region or (C[id].Acquisition=="Breeding" and "Breeding" or "Meadow") C[id].Acquisition=C[id].Acquisition or "Hunt" end
C.Scales={[1]=1,[3]=1.4,[6]=1.9,[9]=2.5}
function C.stage(stars) return stars>=9 and 9 or stars>=6 and 6 or stars>=3 and 3 or 1 end
function C.scale(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 local lower=C.stage(stars)
 if lower==9 then return 2.5+(stars-9)*.2 end
 local upper=lower==1 and 3 or lower+3
 local alpha=(stars-lower)/(upper-lower)
 return C.Scales[lower]+(C.Scales[upper]-C.Scales[lower])*alpha
end
function C.visual(id,stars) local stage=C.stage(stars or 1) return C[id].Visual..(stage==1 and "" or "_S"..stage) end
function C.template(id,stars) local stage=C.stage(stars or 1) return C[id].Template..(stage==1 and "" or "_S"..stage) end
function C.saddleHeight(id,stars)
 stars=stars or 1
 if id=="GrassBoar" then
  local stage=C.stage(stars)
  local package=game and game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
  local visual=package and package:FindFirstChild(C.visual(id,stars))
  local fitted=visual and visual:GetAttribute("MeshyBackHeight")
  if fitted then return fitted*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars) end
  local back={[1]=2.804463,[3]=3.880880,[6]=7.230789,[9]=11.021101}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 if id=="MeadowMouse" then
  local stage=C.stage(stars)
  if stage==1 or stage==3 then
   local package=game and game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
   local visual=package and package:FindFirstChild(C.visual(id,stars))
   local back=visual and visual:GetAttribute("MeshyBackHeight")
   if back then return back*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars) end
   return 1.2*C.scale(stars)
  end
  -- Meshes already contain their approved stage size. Seat above the back,
  -- with a constant clearance for the unscaled player rather than its crown.
  local back={[3]=2.212572,[6]=3.232653,[9]=7.460891}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 return C[id].SaddleHeight*C.scale(stars)
end
function C.pick(meters,serial)
 if meters<0 or meters>=C.MeadowEndMeters then return nil end
 local unlocked={}
 for _,id in ipairs(C.Order) do if meters>=C[id].UnlockMeters then table.insert(unlocked,id) end end
 -- Rotate each equal-share cycle so alternating left/right births do not
 -- permanently assign one species to only one side of the road.
 return unlocked[(serial+math.floor(serial/#unlocked))%#unlocked+1]
end
return C
]=]},{name=[=[SocialRules]=],parent=package,optional=false,before=[=[-- Pure ownership rules used by both servers. No client-authored monster data.
local R={}
local function find(bag,id)
 if type(id)~="number" or id~=id or id%1~=0 then return nil end
 for _,m in ipairs(bag.monsters) do if m.id==id then return m end end
end
R.find=find
function R.available(m) return m and not m.breedingTeam and not m.tradeLock end
function R.profile(bag,ids)
 if type(ids)~="table" or #ids>5 then return nil end
 local result,used={},{}
 for _,id in ipairs(ids) do
  if used[id] or not find(bag,id) then return nil end
  used[id]=true table.insert(result,id)
 end
 return result
end
function R.pair(bag,ids)
 if type(ids)~="table" or #ids~=2 or ids[1]==ids[2] then return false,"Select one female and one male." end
 local a,b=find(bag,ids[1]),find(bag,ids[2])
 if not R.available(a) or not R.available(b) then return false,"A selected monster is busy." end
 if not ((a.sex=="Male" and b.sex=="Female") or (a.sex=="Female" and b.sex=="Male")) then return false,"A female and a male are required." end
 local teams=0 for _ in pairs(bag.breedingTeams or {}) do teams+=1 end
 if teams>=4 then return false,"Up to four breeding pairs are allowed." end
 return true,"Breeding is coming soon. Pairing does not start breeding yet."
end
function R.egg(bag,id,slot,remove)
 if type(slot)~="number" or slot%1~=0 or slot<1 or slot>4 then return false end
 local target
 for _,egg in ipairs(bag.eggs or {}) do
  if egg.id==id then target=egg end
  if not remove and egg.assignedPen==slot then return false end
 end
 if not target then return false end
 if remove then if target.assignedPen~=slot then return false end target.assignedPen=nil
 else if target.assignedPen then return false end target.assignedPen=slot end
 return true
end
function R.offer(bag,offer)
 if type(offer)~="table" or type(offer.ids)~="table" or #offer.ids>100 then return nil end
 local coins=offer.coins
 if type(coins)~="number" or coins~=coins or coins<0 or coins%1~=0 or coins>9e12 or coins>(bag.pending or 0)+(bag.balance or 0) then return nil end
 local selected,used={},{}
 for _,id in ipairs(offer.ids) do
  local m=find(bag,id)
  if not R.available(m) or used[id] then return nil end
  used[id]=true table.insert(selected,m)
 end
 return {coins=coins,ids=table.clone(offer.ids),monsters=selected}
end
function R.exchange(a,b,offerA,offerB)
 local x,y=R.offer(a,offerA),R.offer(b,offerB)
 if not x or not y then return nil,"Your inventory or monster status has changed." end
 if (x.coins==0 and #x.ids==0) or (y.coins==0 and #y.ids==0) then return nil,"Both players must offer something." end
 if #x.ids+#y.ids==0 then return nil,"A trade must include a monster." end
 local function transfer(bag,outgoing,incoming)
  local result=table.clone(bag) result.monsters={} result.profile={}
  local remove={} for _,id in ipairs(outgoing.ids) do remove[id]=true end
  for _,m in ipairs(bag.monsters) do if not remove[m.id] then table.insert(result.monsters,table.clone(m)) end end
  for _,id in ipairs(bag.profile or {}) do if not remove[id] then table.insert(result.profile,id) end end
  for _,m in ipairs(incoming.monsters) do
   result.serial+=1 local copy=table.clone(m) copy.id=result.serial copy.assignedPen=nil copy.tradeLock=nil
   table.insert(result.monsters,copy)
  end
  result.balance=(bag.balance or 0)+(bag.pending or 0)-outgoing.coins+incoming.coins result.pending=0
  return result
 end
 return {transfer(a,x,y),transfer(b,y,x)}
end
return R
]=],after=[=[-- Pure ownership rules used by both servers. No client-authored monster data.
local R={}
local function find(bag,id)
 if type(id)~="number" or id~=id or id%1~=0 then return nil end
 for _,m in ipairs(bag.monsters) do if m.id==id then return m end end
end
R.find=find
function R.available(m) return m and not m.breedingTeam and not m.tradeLock end
function R.profile(bag,ids)
 if type(ids)~="table" or #ids>5 then return nil end
 local result,used={},{}
 for _,id in ipairs(ids) do
  if used[id] or not find(bag,id) then return nil end
  used[id]=true table.insert(result,id)
 end
 return result
end
function R.pair(bag,ids)
 if type(ids)~="table" or #ids~=2 or ids[1]==ids[2] then return false,"Select one female and one male." end
 local a,b=find(bag,ids[1]),find(bag,ids[2])
 if not R.available(a) or not R.available(b) then return false,"A selected monster is busy." end
 if not ((a.sex=="Male" and b.sex=="Female") or (a.sex=="Female" and b.sex=="Male")) then return false,"A female and a male are required." end
 local teams=0 for _ in pairs(bag.breedingTeams or {}) do teams+=1 end
 if teams>=4 then return false,"Up to four breeding pairs are allowed." end
 return true,"Breeding is coming soon. Pairing does not start breeding yet."
end
function R.egg(bag,id,slot,remove)
 if type(slot)~="number" or slot%1~=0 or slot<1 or slot>4 then return false end
 local target
 for _,egg in ipairs(bag.eggs or {}) do
  if egg.id==id then target=egg end
  if not remove and egg.assignedPen==slot then return false end
 end
 if not target then return false end
 if remove then if target.assignedPen~=slot then return false end target.assignedPen=nil
 else if target.assignedPen then return false end target.assignedPen=slot end
 return true
end
function R.offer(bag,offer)
 if type(offer)~="table" or type(offer.ids)~="table" or #offer.ids>100 then return nil end
 local coins=offer.coins
 if type(coins)~="number" or coins~=coins or coins<0 or coins%1~=0 or coins>9e12 or coins>(bag.pending or 0)+(bag.balance or 0) then return nil end
 local selected,used={},{}
 for _,id in ipairs(offer.ids) do
  local m=find(bag,id)
  if not R.available(m) or used[id] then return nil end
  used[id]=true table.insert(selected,m)
 end
 return {coins=coins,ids=table.clone(offer.ids),monsters=selected}
end
function R.exchange(a,b,offerA,offerB)
 local x,y=R.offer(a,offerA),R.offer(b,offerB)
 if not x or not y then return nil,"Your inventory or monster status has changed." end
 if #a.monsters-#x.ids+#y.ids>30 or #b.monsters-#y.ids+#x.ids>30 then return nil,"Bag capacity is 30 monsters." end
 if (x.coins==0 and #x.ids==0) or (y.coins==0 and #y.ids==0) then return nil,"Both players must offer something." end
 if #x.ids+#y.ids==0 then return nil,"A trade must include a monster." end
 local function transfer(bag,outgoing,incoming)
  local result=table.clone(bag) result.monsters={} result.profile={}
  local remove={} for _,id in ipairs(outgoing.ids) do remove[id]=true end
  for _,m in ipairs(bag.monsters) do if not remove[m.id] then table.insert(result.monsters,table.clone(m)) end end
  for _,id in ipairs(bag.profile or {}) do if not remove[id] then table.insert(result.profile,id) end end
  for _,m in ipairs(incoming.monsters) do
   result.serial+=1 local copy=table.clone(m) copy.id=result.serial copy.assignedPen=nil copy.tradeLock=nil
   table.insert(result.monsters,copy)
  end
  result.balance=(bag.balance or 0)+(bag.pending or 0)-outgoing.coins+incoming.coins result.pending=0
  return result
 end
 return {transfer(a,x,y),transfer(b,y,x)}
end
return R
]=]},{name=[=[CafeServer]=],parent=server,optional=true,before=[=[-- Cafe uses the same fenced inventory and companion rules as the lobby.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local Config=require(P.Config)
local Bag=require(P.BagRules)
local Rules=require(P.SocialRules)
local Catalog=require(P.MonsterCatalog)
local Store=require(script.Parent.InventoryStore)
local Progress=require(script.Parent.ProgressService)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local World=require(script.Parent.CafeWorld)
local map=World.build()
local remote=P.CaptureRemote
local bags,limits={},{}
local function active(p) return bags[p]~=nil and not p:GetAttribute("Travelling") end
local function canAct(p)
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 return active(p) and not Store.busy(p) and not Social.trading(p) and h and h.Health>0
end
local activities=require(script.Parent.CafeActivities).start(map,canAct)
local pets=require(script.Parent.LobbyCompanions).new({map=map,streamingMode=Enum.ModelStreamingMode.Atomic,
 bag=function(p) return bags[p] end,inLobby=active,canAct=canAct,canSummon=canAct})
local function accrue(b)
 return Bag.accrue(b,workspace:GetServerTimeNow(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
end
local function send(p,gains)
 local b=bags[p] if not b or not p.Parent then return end
 remote:FireClient(p,"State",{area="Cafe",phase="Idle",count=#b.monsters,pending=b.pending,balance=b.balance,gems=b.gems or 0,
 income=gains,summonedId=p:GetAttribute("SummonedId"),profile=b.profile,progress=Progress.snapshot(p)})
end
local function sendBag(p)
 local b=bags[p] if not b then return end local items={}
 for _,m in ipairs(b.monsters) do
  table.insert(items,{id=m.id,monsterId=m.monsterId,stars=m.stars,sex=m.sex,breedingTeam=m.breedingTeam,
   incomeSeconds=m.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=Bag.income(m,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(p,"Bag",items)
end
require(script.Parent:WaitForChild("OperatorCommands")).register({
 message=function(p,message) remote:FireClient(p,"SocialMessage",message) end,
 grant=function(p,id,stars,count)
  if not canAct(p) then remote:FireClient(p,"SocialMessage","Use this command when your bag is ready.") return end
  local b=bags[p] local species=Catalog[id]
  for _=1,count do
   Bag.grant(b,id,workspace:GetServerTimeNow(),species.IncomeSeconds,species.IncomeAmount)
   b.monsters[#b.monsters].stars=stars
   Progress.caught(p,id,stars)
  end
  sendBag(p) send(p)
  remote:FireClient(p,"SocialMessage","Added "..count.." "..require(P.Localization).text(id,"en").." ("..stars.." stars).")
 end,
})
Social.start(bags,canAct,sendBag,pets.clear)
remote.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" or not active(p) or Store.busy(p) then return end
 local allowed={Sync=true,Bag=true,Summon=true,BondPet=true,RidePet=true,RideInput=true,GoLobby=true,Journal=true,Evolve=true,Manage=true,PlaceEgg=true,RemoveEgg=true}
 if not allowed[action] then return end
 local stamps=limits[p] or {} limits[p]=stamps
 local interval=action=="RideInput" and .05 or .25
 if os.clock()-(stamps[action] or -1)<interval then return end stamps[action]=os.clock()
 if action=="Sync" then send(p,accrue(bags[p])) sendBag(p)
 elseif action=="Bag" then sendBag(p)
 elseif action=="Journal" then remote:FireClient(p,"Journal",Progress.snapshot(p,true))
 elseif action=="GoLobby" and canAct(p) then accrue(bags[p]) Travel.go(p,false)
 elseif action=="Summon" then pets.summon(p,value) send(p)
 elseif action=="BondPet" then pets.bond(p,value)
 elseif action=="RidePet" then pets.ride(p,value)
 elseif action=="RideInput" then pets.input(p,value)
 elseif action=="Evolve" and canAct(p) then
  local gains=accrue(bags[p]);local evolved,reason=Bag.evolve(bags[p],value,workspace:GetServerTimeNow())
  if evolved then pets.clear(p) Progress.discover(p,evolved.monsterId,evolved.stars) end
  remote:FireClient(p,"EvolutionResult",{ok=evolved~=nil,reason=reason}) sendBag(p) send(p,gains)
 elseif action=="Manage" and canAct(p) and type(value)=="number" and value%1==0 and value>=1 and value<=4 then
  remote:FireClient(p,"Eggs",{pen=value,eggs=bags[p].eggs or {}})
 elseif (action=="PlaceEgg" or action=="RemoveEgg") and canAct(p) and type(value)=="table" then
  if Rules.egg(bags[p],value.id,value.pen,action=="RemoveEgg") then remote:FireClient(p,"Eggs",{pen=value.pen,eggs=bags[p].eggs}) end
 end
end)
local function added(p)
 if #Players:GetPlayers()>require(P.SocialConfig).CafeCapacity then p:Kick("Cafe is full.") return end
 local b,message=Store.open(p) if not b then p:Kick(message) return end
 bags[p]=b;p:SetAttribute("Area","Cafe");Progress.join(p,b)
 local function character(c)
  pets.clear(p);local r=c:WaitForChild("HumanoidRootPart",10)
  if r then c:PivotTo(World.Spawn) end
  local h=c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=Config.CafeWalkSpeed end
 end
 p.CharacterAdded:Connect(character)
 p.CharacterRemoving:Connect(function() pets.clear(p) end)
 if p.Character then task.spawn(character,p.Character) end
 send(p) sendBag(p)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(p)
 if bags[p] and not p:GetAttribute("Travelling") and not Store.busy(p) then accrue(bags[p]) end
 pets.clear(p);Progress.leave(p);Store.close(p);bags[p]=nil;limits[p]=nil
end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
-- Income is based on server time, independent of input, movement or open UI.
task.spawn(function()
 while task.wait(.5) do
  for p,b in pairs(bags) do if active(p) and not Store.busy(p) then send(p,accrue(b)) end end
 end
end)
Progress.start()
]=],after=[=[-- Cafe uses the same fenced inventory and companion rules as the lobby.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local Config=require(P.Config)
local Bag=require(P.BagRules)
local Rules=require(P.SocialRules)
local Catalog=require(P.MonsterCatalog)
local Store=require(script.Parent.InventoryStore)
local Progress=require(script.Parent.ProgressService)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local World=require(script.Parent.CafeWorld)
local map=World.build()
local remote=P.CaptureRemote
local bags,limits={},{}
local function active(p) return bags[p]~=nil and not p:GetAttribute("Travelling") end
local function canAct(p)
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 return active(p) and not Store.busy(p) and not Social.trading(p) and h and h.Health>0
end
local activities=require(script.Parent.CafeActivities).start(map,canAct)
local pets=require(script.Parent.LobbyCompanions).new({map=map,speedMultiplier=2,streamingMode=Enum.ModelStreamingMode.Atomic,
 bag=function(p) return bags[p] end,inLobby=active,canAct=canAct,canSummon=canAct})
local function accrue(b)
 return Bag.accrue(b,workspace:GetServerTimeNow(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
end
local function send(p,gains)
 local b=bags[p] if not b or not p.Parent then return end
 remote:FireClient(p,"State",{area="Cafe",phase="Idle",count=#b.monsters,pending=b.pending,balance=b.balance,gems=b.gems or 0,
 income=gains,summonedId=p:GetAttribute("SummonedId"),profile=b.profile,progress=Progress.snapshot(p)})
end
local function sendBag(p)
 local b=bags[p] if not b then return end local items={}
 for _,m in ipairs(b.monsters) do
  table.insert(items,{id=m.id,monsterId=m.monsterId,stars=m.stars,sex=m.sex,breedingTeam=m.breedingTeam,
   incomeSeconds=m.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=Bag.income(m,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(p,"Bag",items)
end
require(script.Parent:WaitForChild("OperatorCommands")).register({
 message=function(p,message) remote:FireClient(p,"SocialMessage",message) end,
 grant=function(p,id,stars,count)
  if not canAct(p) then remote:FireClient(p,"SocialMessage","Use this command when your bag is ready.") return end
  local b=bags[p] local species=Catalog[id]
  local added=0
  for _=1,count do
   local granted=Bag.grant(b,id,workspace:GetServerTimeNow(),species.IncomeSeconds,species.IncomeAmount)
   if not granted then break end
   granted.stars=stars added+=1
   Progress.caught(p,id,stars)
  end
  sendBag(p) send(p)
  remote:FireClient(p,"SocialMessage","Added "..added.." "..require(P.Localization).text(id,"en").." ("..stars.." stars).")
 end,
})
Social.start(bags,canAct,sendBag,pets.clear)
remote.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" or not active(p) or Store.busy(p) then return end
 local allowed={Sync=true,Bag=true,Summon=true,BondPet=true,RidePet=true,RideInput=true,RideJump=true,Discard=true,GoLobby=true,Journal=true,Evolve=true,Manage=true,PlaceEgg=true,RemoveEgg=true}
 if not allowed[action] then return end
 local stamps=limits[p] or {} limits[p]=stamps
 local interval=action=="RideInput" and .05 or .25
 if os.clock()-(stamps[action] or -1)<interval then return end stamps[action]=os.clock()
 if action=="Sync" then send(p,accrue(bags[p])) sendBag(p)
 elseif action=="Bag" then sendBag(p)
 elseif action=="Journal" then remote:FireClient(p,"Journal",Progress.snapshot(p,true))
 elseif action=="GoLobby" and canAct(p) then accrue(bags[p]) Travel.go(p,false)
 elseif action=="Summon" then pets.summon(p,value) send(p)
 elseif action=="BondPet" then pets.bond(p,value)
 elseif action=="RidePet" then pets.ride(p,value)
 elseif action=="RideJump" then pets.jump(p)
 elseif action=="Discard" and canAct(p) then
  local gains=accrue(bags[p])
  if Bag.discard(bags[p],value) then
   if p:GetAttribute("SummonedId")==value then pets.clear(p) end
   sendBag(p) send(p,gains)
  end
 elseif action=="RideInput" then pets.input(p,value)
 elseif action=="Evolve" and canAct(p) then
  local gains=accrue(bags[p]);local evolved,reason=Bag.evolve(bags[p],value,workspace:GetServerTimeNow())
  if evolved then pets.clear(p) Progress.discover(p,evolved.monsterId,evolved.stars) end
  remote:FireClient(p,"EvolutionResult",{ok=evolved~=nil,reason=reason}) sendBag(p) send(p,gains)
 elseif action=="Manage" and canAct(p) and type(value)=="number" and value%1==0 and value>=1 and value<=4 then
  remote:FireClient(p,"Eggs",{pen=value,eggs=bags[p].eggs or {}})
 elseif (action=="PlaceEgg" or action=="RemoveEgg") and canAct(p) and type(value)=="table" then
  if Rules.egg(bags[p],value.id,value.pen,action=="RemoveEgg") then remote:FireClient(p,"Eggs",{pen=value.pen,eggs=bags[p].eggs}) end
 end
end)
local function added(p)
 if #Players:GetPlayers()>require(P.SocialConfig).CafeCapacity then p:Kick("Cafe is full.") return end
 local b,message=Store.open(p) if not b then p:Kick(message) return end
 bags[p]=b;p:SetAttribute("Area","Cafe");Progress.join(p,b)
 local function character(c)
  pets.clear(p);local r=c:WaitForChild("HumanoidRootPart",10)
  if r then c:PivotTo(World.Spawn) end
  local h=c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=Config.CafeWalkSpeed end
 end
 p.CharacterAdded:Connect(character)
 p.CharacterRemoving:Connect(function() pets.clear(p) end)
 if p.Character then task.spawn(character,p.Character) end
 send(p) sendBag(p)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(p)
 if bags[p] and not p:GetAttribute("Travelling") and not Store.busy(p) then accrue(bags[p]) end
 pets.clear(p);Progress.leave(p);Store.close(p);bags[p]=nil;limits[p]=nil
end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
-- Income is based on server time, independent of input, movement or open UI.
task.spawn(function()
 while task.wait(.5) do
  for p,b in pairs(bags) do if active(p) and not Store.busy(p) then send(p,accrue(b)) end end
 end
end)
Progress.start()
]=]},{name=[=[CaptureServer]=],parent=server,optional=true,before=[=[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local TravelProgress=require(script.Parent.TravelService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 inLobby=function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canSummon(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 if state then TravelProgress.sample(player,"GreenStar",state,state.distance) end
 local wildIds={}
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,gems=bag.gems or 0,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
require(script.Parent:WaitForChild("OperatorCommands")).register({
 message=function(player,message) remote:FireClient(player,"SocialMessage",message) end,
 grant=function(player,id,stars,count)
  local bag=bags[player]
  if not bag or states[player] or Store.busy(player) or Social.trading(player) or player:GetAttribute("Travelling") then
   remote:FireClient(player,"SocialMessage","Use this command in the lobby when your bag is ready.") return
  end
  local species=Catalog[id]
  for _=1,count do
   BagRules.grant(bag,id,now(),species.IncomeSeconds,species.IncomeAmount)
   bag.monsters[#bag.monsters].stars=stars
   Progress.caught(player,id,stars)
  end
  sendBag(player) send(player)
  remote:FireClient(player,"SocialMessage","Added "..count.." "..require(P.Localization).text(id,"en").." ("..stars.." stars).")
 end,
})
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle" or crashKind=="CanyonFall") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).starter("GreenStar",Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"This hunt or monster is coming soon.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"Unable to prepare the hunt. Please try again.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 model:SetAttribute("StartingOwnedMount",true)
 model:SetAttribute("Tamed_"..player.UserId,true)
 companions.clear(player)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="GoCafe" and action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" and action~="BondPet" and action~="RidePet" and action~="RideInput" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="RideInput" and .05 or action=="Jump" and 0.08 or action=="Steer" and 0.01 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="GoCafe" then
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if player:GetAttribute("Area")~="Lobby" or states[player] or Social.trading(player) or not hum or hum.Health<=0 then return end
  Travel.go(player,true) return
 end
 if action=="BondPet" then companions.bond(player,value) return end
 if action=="RidePet" then companions.ride(player,value) return end
 if action=="RideInput" then companions.input(player,value) return end
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}})
  elseif not states[player] then remote:FireClient(player,"SocialMessage","Manage your eggs in the lobby.") end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  Progress.discover(player,evolved.monsterId,evolved.stars)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if (not state or state.phase=="GameOver" or state.phase=="CourseEnd") and not player:GetAttribute("ReturningLobby") then
   player:SetAttribute("ReturningLobby",true)
   restoreAvatar(state)
   states[player]=nil
   if worldRoots[player] then worldRoots[player]:Destroy() end
   worlds[player],worldRoots[player]=nil,nil
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not humanoid or humanoid.Health<=0 or (state and (state.phase=="GameOver" or state.phase=="CourseEnd")) then
    local ok,err=pcall(function() player:LoadCharacterAsync() end)
    if not ok then states[player]=state player:SetAttribute("ReturningLobby",nil) warn("LOBBY_RESPAWN_FAILED: "..tostring(err)) send(player,"Please try Return to lobby again.") return end
    character=player.Character
   end
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then root.Anchored=false root.AssemblyLinearVelocity=Vector3.zero character:PivotTo(Lobby.Spawn) end
   humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.PlatformStand=false humanoid.AutoRotate=true end
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(character)
   player:SetAttribute("ReturningLobby",nil)
   send(player,"Welcome back to the lobby.") sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or state.started+Config.Hunt.AngerSeconds
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   local blocked,broken=World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing)
   if broken>0 then
    bags[player].gems=(bags[player].gems or 0)+broken
    send(player)
   end
   if blocked then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or contact=="CanyonFall" and "You fell into the canyon." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   local tameReady,warningReady=Rules.mountTimeline(clock-state.started,Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds,Config.Hunt.AngerSeconds,tuning.AngerWarningSeconds)
   if not state.tamed and tameReady then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and warningReady then
    state.angerAt=state.angerAt or state.started+Config.Hunt.AngerSeconds
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player,bag) TravelProgress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 for index=1,4 do Lobby.display(player,index,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) TravelProgress.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() TravelProgress.start() end
]=],after=[=[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local TravelProgress=require(script.Parent.TravelService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 inLobby=function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canSummon(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 if state then TravelProgress.sample(player,"GreenStar",state,state.distance) end
 local wildIds={}
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,gems=bag.gems or 0,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
require(script.Parent:WaitForChild("OperatorCommands")).register({
 message=function(player,message) remote:FireClient(player,"SocialMessage",message) end,
 grant=function(player,id,stars,count)
  local bag=bags[player]
  if not bag or states[player] or Store.busy(player) or Social.trading(player) or player:GetAttribute("Travelling") then
   remote:FireClient(player,"SocialMessage","Use this command in the lobby when your bag is ready.") return
  end
  local species=Catalog[id]
  local added=0
  for _=1,count do
   local granted=BagRules.grant(bag,id,now(),species.IncomeSeconds,species.IncomeAmount)
   if not granted then break end
   granted.stars=stars added+=1
   Progress.caught(player,id,stars)
  end
  sendBag(player) send(player)
  remote:FireClient(player,"SocialMessage","Added "..added.." "..require(P.Localization).text(id,"en").." ("..stars.." stars).")
 end,
})
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle" or crashKind=="CanyonFall") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).starter("GreenStar",Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"This hunt or monster is coming soon.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"Unable to prepare the hunt. Please try again.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 model:SetAttribute("StartingOwnedMount",true)
 model:SetAttribute("Tamed_"..player.UserId,true)
 companions.clear(player)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="GoCafe" and action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" and action~="BondPet" and action~="RidePet" and action~="RideInput" and action~="RideJump" and action~="Discard" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="RideInput" and .05 or action=="Jump" and 0.08 or action=="Steer" and 0.01 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="GoCafe" then
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if player:GetAttribute("Area")~="Lobby" or states[player] or Social.trading(player) or not hum or hum.Health<=0 then return end
  Travel.go(player,true) return
 end
 if action=="RideJump" then companions.jump(player) return end
 if action=="Discard" then
  if states[player] or Social.trading(player) then return end
  BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  if BagRules.discard(bags[player],value) then
   if player:GetAttribute("SummonedId")==value then companions.clear(player) end
   sendBag(player) send(player)
  end
  return
 end
 if action=="BondPet" then companions.bond(player,value) return end
 if action=="RidePet" then companions.ride(player,value) return end
 if action=="RideInput" then companions.input(player,value) return end
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}})
  elseif not states[player] then remote:FireClient(player,"SocialMessage","Manage your eggs in the lobby.") end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  Progress.discover(player,evolved.monsterId,evolved.stars)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if (not state or state.phase=="GameOver" or state.phase=="CourseEnd") and not player:GetAttribute("ReturningLobby") then
   player:SetAttribute("ReturningLobby",true)
   restoreAvatar(state)
   states[player]=nil
   if worldRoots[player] then worldRoots[player]:Destroy() end
   worlds[player],worldRoots[player]=nil,nil
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not humanoid or humanoid.Health<=0 or (state and (state.phase=="GameOver" or state.phase=="CourseEnd")) then
    local ok,err=pcall(function() player:LoadCharacterAsync() end)
    if not ok then states[player]=state player:SetAttribute("ReturningLobby",nil) warn("LOBBY_RESPAWN_FAILED: "..tostring(err)) send(player,"Please try Return to lobby again.") return end
    character=player.Character
   end
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then root.Anchored=false root.AssemblyLinearVelocity=Vector3.zero character:PivotTo(Lobby.Spawn) end
   humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.PlatformStand=false humanoid.AutoRotate=true end
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(character)
   player:SetAttribute("ReturningLobby",nil)
   send(player,"Welcome back to the lobby.") sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or state.started+Config.Hunt.AngerSeconds
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   local blocked,broken=World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing)
   if broken>0 then
    bags[player].gems=(bags[player].gems or 0)+broken
    send(player)
   end
   if blocked then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or contact=="CanyonFall" and "You fell into the canyon." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   local tameReady,warningReady=Rules.mountTimeline(clock-state.started,Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds,Config.Hunt.AngerSeconds,tuning.AngerWarningSeconds)
   if not state.tamed and tameReady then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true local granted=BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,granted and "Monster tamed! Added to your bag." or "Bag full (30/30). Caught monster released.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and warningReady then
    state.angerAt=state.angerAt or state.started+Config.Hunt.AngerSeconds
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player,bag) TravelProgress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 for index=1,4 do Lobby.display(player,index,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) TravelProgress.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() TravelProgress.start() end
]=]},{name=[=[HuntWorld]=],parent=server,optional=true,before=[=[-- Restored pre-Raise-Animal meadow/canyon map, with current rig and private sessions.
local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Layout=require(script.Parent.GreenStarCourseLayout)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local SpawnPlan=require(game.ReplicatedStorage.RodeoFantasy.HerdSpawnPlan)
local spawnSerial=0
local viewerMeters=0

local function part(parent, name, position, size, color)
	local item = Instance.new("Part")
	item.Name, item.Anchored = name, true
	item.Size, item.Position, item.Color = size, position, color
	item.Material = Enum.Material.Sand
	item.Parent = parent
	return item
end

local function decoration(parent,name,position,size,color)
 local node=part(parent,name,position,size,color)
 node.Material=Enum.Material.SmoothPlastic
 node.CanCollide,node.CanTouch,node.CanQuery=false,false,false
 node.TopSurface,node.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 return node
end

local function createCrate(x,z,index)
 local box=part(obstacles,"BreakableCrate",Vector3.new(x,2,z),Vector3.new(4,4,4),Color3.fromRGB(133,88,54))
 box.Transparency=1 box.CanCollide=false box:SetAttribute("Chunk",index) box:SetAttribute("BreakableCrate",true)
 decoration(box,"WoodCore",box.Position,Vector3.new(3.6,3.6,3.6),Color3.fromRGB(143,97,59))
 for _,side in ipairs({-1,1}) do
  for _,height in ipairs({0.25,3.75}) do
   decoration(box,"Frame",Vector3.new(x,height,z+side*1.94),Vector3.new(4,0.5,0.25),Color3.fromRGB(218,163,94))
  end
  for _,edge in ipairs({-1,1}) do
   decoration(box,"Corner",Vector3.new(x+edge*1.75,2,z+side*1.94),Vector3.new(0.5,4,0.25),Color3.fromRGB(218,163,94))
  end
  local brace=decoration(box,"DiagonalBrace",Vector3.new(x,2,z+side*2),Vector3.new(4.4,0.45,0.2),Color3.fromRGB(195,137,77))
  brace.CFrame*=CFrame.Angles(0,0,math.pi/4)
 end
 return box
end

local function dressObstacle(rock,style,scale)
 rock.Transparency=1 rock:SetAttribute("Style",style) rock:SetAttribute("Scale",scale)
 local base=Vector3.new(rock.Position.X,0,rock.Position.Z)
 local function detail(name,pos,size,color)
  return decoration(rock,name,base+pos*scale,size*scale,color)
 end
 if style=="Tree" then
  detail("TreeTrunk",Vector3.new(0,2.2,0),Vector3.new(1.25,4.4,1.25),Color3.fromRGB(146,101,70))
  detail("TreeRoots",Vector3.new(0,0.25,0),Vector3.new(2.4,0.5,2.4),Color3.fromRGB(165,117,77))
  detail("LeafCrown",Vector3.new(0,4.3,0),Vector3.new(3.8,2.1,3.8),Color3.fromRGB(112,165,85))
  detail("LeafTop",Vector3.new(-0.2,5.65,0.1),Vector3.new(2.8,0.7,2.8),Color3.fromRGB(153,195,105))
  detail("LeafHighlight",Vector3.new(0.7,5.25,-0.7),Vector3.new(1.8,0.25,1.5),Color3.fromRGB(174,210,119))
 else
  local stone=detail("Boulder",Vector3.new(0,1.15,0),Vector3.new(3.8,2.3,3.8),Color3.fromRGB(177,157,123))
  stone.CFrame*=CFrame.Angles(0,0,0.06)
  detail("StoneCap",Vector3.new(-0.3,2.5,0.15),Vector3.new(2.7,0.7,2.6),Color3.fromRGB(199,181,143))
  detail("Moss",Vector3.new(-0.6,2.91,0.1),Vector3.new(1.6,0.12,1.5),Color3.fromRGB(124,166,87))
  detail("StoneChip",Vector3.new(1.45,0.4,1.35),Vector3.new(0.9,0.8,0.9),Color3.fromRGB(163,146,113))
 end
end

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
	obstacles = Instance.new("Folder")
	obstacles.Name, obstacles.Parent = "Obstacles", root
	local preview = root:FindFirstChild("PreviewMonster")
	if preview then preview:Destroy() end
	local floor = root:FindFirstChild("PreviewGround")
	if floor then floor:Destroy() end
end

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height,position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
 if species.UnlockMeters>viewerMeters then model:SetAttribute("WaitingForUnlock",true) end
	return model
end

function World.groundHeight(x,z) return 0 end

function World.ensure(z)
	local center = math.floor(z / tuning.GroundChunkStuds + 0.5)
	for index = center - 2, center + 1 do
		if chunks[index] or index*tuning.GroundChunkStuds < -Course.LengthStuds-128 or index*tuning.GroundChunkStuds>128 then continue end
		local chunk = Instance.new("Folder")
		chunk.Name, chunk.Parent = "Road_" .. index, root
		chunks[index] = chunk
		local start = index * tuning.GroundChunkStuds
		local random = Random.new(9101 + math.abs(index) * 137)
  -- Short slices follow the changing width; canyon slices have no central floor.
  for offset=-tuning.GroundChunkStuds/2+8,tuning.GroundChunkStuds/2-8,16 do
   local rowZ=start+offset
   local edge=math.min(Course.width(rowZ-8),Course.width(rowZ),Course.width(rowZ+8))
   local _,kind,t=Course.fork(rowZ)
   local middle=Course.median(rowZ)
   if kind=="Canyon" and middle>.1 then
    for _,side in ipairs({-1,1}) do
     local lane=edge-middle
     local floor=part(chunk,"Meadow",Vector3.new(side*(middle+lane/2),-1,rowZ),Vector3.new(lane,2,16),Color3.fromRGB(178,211,117))
     floor.Material=Enum.Material.SmoothPlastic
     decoration(chunk,"InnerCliff",Vector3.new(side*(middle+1.5),-15,rowZ),Vector3.new(3,28,16),Color3.fromRGB(146,119,87))
     decoration(chunk,"CliffLayer",Vector3.new(side*(middle+1.5),-22,rowZ),Vector3.new(3.2,2,16),Color3.fromRGB(106,88,68))
    end
    decoration(chunk,"CanyonDepth",Vector3.new(0,-32,rowZ),Vector3.new(middle*2,2,16),Color3.fromRGB(46,71,72))
   else
    local floor=part(chunk,"Meadow",Vector3.new(0,-1,rowZ),Vector3.new(edge*2,2,16),Color3.fromRGB(178,211,117))
    floor.Material=Enum.Material.SmoothPlastic
   end
   if kind=="Mountain" and middle>.1 then
    local h=3+10*math.sin(math.pi*t)+3*math.sin(t*5*math.pi)
    for _,side in ipairs({-1,1}) do
     local slope=Instance.new("WedgePart") slope.Name="MountainSlope" slope.Anchored=true
     slope.CanCollide,slope.CanTouch,slope.CanQuery=false,false,false
     slope.Size=Vector3.new(16,h,middle) slope.CFrame=CFrame.new(side*middle/2,h/2,rowZ)*CFrame.Angles(0,-side*math.pi/2,0)
     slope.Color=Color3.fromRGB(110,151,80) slope.Material=Enum.Material.SmoothPlastic slope.Parent=chunk
    end
    if math.floor(rowZ/16)%4==0 and middle>3 then
     decoration(chunk,"RidgeTreeTrunk",Vector3.new(0,h+1.4,rowZ),Vector3.new(.8,2.8,.8),Color3.fromRGB(146,101,70))
     decoration(chunk,"RidgeTreeCrown",Vector3.new(0,h+3.2,rowZ),Vector3.new(3.4,2,3.4),Color3.fromRGB(112,165,85))
     decoration(chunk,"RidgeTreeTop",Vector3.new(0,h+4.4,rowZ),Vector3.new(2.2,.7,2.2),Color3.fromRGB(153,195,105))
    elseif math.floor(rowZ/16)%5==0 then
     decoration(chunk,"RidgeRock",Vector3.new(0,h+.4,rowZ),Vector3.new(2,.8,1.6),Color3.fromRGB(177,157,123))
    end
   end
  end
  local placements=Layout[index]
  if placements then
   for _,o in ipairs(placements.obstacles) do
    local rock=part(obstacles,"Rock",Vector3.new(o.x,o.height/2,o.z),Vector3.new(4*o.scale,o.height,4*o.scale),Color3.fromRGB(167,130,99))
    rock:SetAttribute("Chunk",index) rock:SetAttribute("ObstacleSize",o.tier)
    rock.CanCollide=false -- server swept collision is authoritative
    dressObstacle(rock,o.style,o.scale)
   end
   for _,c in ipairs(placements.crates) do createCrate(c.x,c.z,index) end
  end
		for offset = -112,112,32 do
			local rowZ = start + offset
   if rowZ < -Course.LengthStuds-160 or rowZ>128 then continue end
   local edge=Course.width(rowZ)
   for _, side in ipairs({-1,1}) do
    local height=18+random:NextInteger(0,3) -- wall top remains above flying creatures
    decoration(chunk,"CanyonBase",Vector3.new(side*(edge+5),2,rowZ),Vector3.new(10,4,32),Color3.fromRGB(220,151,97))
    decoration(chunk,"CanyonStratum",Vector3.new(side*(edge+7),4.5,rowZ),Vector3.new(10,1,32),Color3.fromRGB(249,191,128))
    decoration(chunk,"CanyonUpper",Vector3.new(side*(edge+9),5+height/2,rowZ),Vector3.new(12,height,32),Color3.fromRGB(201,126,80))
    decoration(chunk,"GrassCap",Vector3.new(side*(edge+9),5+height+0.25,rowZ),Vector3.new(12,0.5,32),Color3.fromRGB(122,170,92))
    decoration(chunk,"GrassEdge",Vector3.new(side*(edge-3),0.08,rowZ),Vector3.new(6,0.16,32),Color3.fromRGB(143,190,96))
    for i=1,3 do
     local z=rowZ+random:NextNumber(-14,14)
     local x=side*random:NextNumber(edge-3,edge-1)
     decoration(chunk,"GrassTuft",Vector3.new(x,0.45,z),Vector3.new(0.5,0.9,0.5),Color3.fromRGB(109,161,77))
    end
    if random:NextNumber()<0.4 then
     local treeZ=rowZ+random:NextNumber(-8,8)
     decoration(chunk,"TreeTrunk",Vector3.new(side*(edge+13),5+height+2,treeZ),Vector3.new(1.4,4,1.4),Color3.fromRGB(152,99,67))
     decoration(chunk,"TreeCrown",Vector3.new(side*(edge+13),5+height+5,treeZ),Vector3.new(6,4,6),Color3.fromRGB(115,163,90))
     decoration(chunk,"TreeTop",Vector3.new(side*(edge+13),5+height+7,treeZ),Vector3.new(4,2,4),Color3.fromRGB(146,190,107))
    end
   end
   for i=1,3 do
    local x,z=random:NextNumber(-29,29),rowZ+random:NextNumber(-14,14)
    local sx,sz=random:NextNumber(2,5),random:NextNumber(3,8)
    -- Ground colour patches need support across their entire footprint.
    if Course.contains(x-sx/2,z-sz/2,0) and Course.contains(x+sx/2,z-sz/2,0)
     and Course.contains(x-sx/2,z+sz/2,0) and Course.contains(x+sx/2,z+sz/2,0) then
     decoration(chunk,"MeadowPatch",Vector3.new(x,0.025,z),Vector3.new(sx,0.05,sz),Color3.fromRGB(187,218,128))
    end
   end
		end
	end
end

function World.step(dt)
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if rock:IsA("BasePart") and not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
   if model:GetAttribute("WaitingForUnlock") then
    if viewerMeters<Catalog[model:GetAttribute("MonsterId")].UnlockMeters then
     model:SetAttribute("HerdVelocity",Vector3.zero) model:SetAttribute("Running",false)
     continue
    end
    model:SetAttribute("WaitingForUnlock",nil) model:SetAttribute("Running",true)
   end
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,p.Y,z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

local displayed=setmetatable({},{__mode="k"})
local released=setmetatable({},{__mode="k"})
function World.resetVisibility(viewer) displayed[viewer]=nil released[viewer]=nil end
function World.releaseMount(model,viewer)
 if not model or not model.Parent or not animals[model] or not viewer then return end
 released[viewer]=released[viewer] or {}
 released[viewer][model]=true
end
function World.visibleSet(z,aspect,viewer)
 viewerMeters=math.max(0,-z*tuning.MetersPerStud)
 local candidates={}
 local riding=false
 for model in pairs(animals) do
  if model.Parent and model:GetAttribute("Occupied") then riding=true end
  if model.Parent and not model:GetAttribute("Occupied") then
   if viewerMeters<Catalog[model:GetAttribute("MonsterId")].UnlockMeters then continue end
   local p=model.PrimaryPart.Position
   table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,atDen=model:GetAttribute("WaitingForUnlock")==true})
  end
 end
 local preferred=viewer and released[viewer]
 if preferred then
  for model in pairs(preferred) do
   local p=model.Parent and model.PrimaryPart and model.PrimaryPart.Position
   if not p or model:GetAttribute("Occupied") or not Visibility.visible(p.X,p.Y,p.Z-z,aspect or 1,tuning,1) then preferred[model]=nil end
  end
 end
 -- Reserve the occupied runner's slot before launch, so releasing it cannot
 -- evict a different wild runner that is still in the middle of the screen.
 local target=Visibility.capacity(Course.width(z))-(riding and 1 or 0)
 local previous=viewer and displayed[viewer]
 local limit=Visibility.transitionLimit(candidates,z,aspect or 1,tuning,target,previous,preferred)
 local result=Visibility.select(candidates,z,aspect or 1,tuning,limit,previous,preferred,Course.median(z)>0)
 -- At an unlock boundary the retained old herd must not occupy every display
 -- slot. Admit one prepared new species without increasing the display cap.
 local speciesCounts={}
 for model in pairs(result) do local id=model:GetAttribute("MonsterId") speciesCounts[id]=(speciesCounts[id] or 0)+1 end
 for _,candidate in ipairs(candidates) do
  local id=candidate.key:GetAttribute("MonsterId")
  if candidate.atDen and not speciesCounts[id] and Visibility.visible(candidate.x,candidate.y,candidate.z-z,aspect or 1,tuning,1) then
   local replace,score
   for model in pairs(result) do
    if speciesCounts[model:GetAttribute("MonsterId")]>1 and not (preferred and preferred[model]) then
     local distance=math.abs(model.PrimaryPart.Position.Z-z)
     if not score or distance>score then replace,score=model,distance end
    end
   end
   if replace then
    local old=replace:GetAttribute("MonsterId") speciesCounts[old]-=1 result[replace]=nil
    result[candidate.key]=true speciesCounts[id]=1
   end
  end
 end
 if viewer then displayed[viewer]=result end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Private run: preload the opening scene; later births are strictly beyond the camera.
function World.replenish(z,aspect,watchers,prime,budget)
 viewerMeters=math.max(0,-z*tuning.MetersPerStud)
 aspect=aspect or 1
 local created=0
 local counts={[-1]=0,[1]=0}
 for model in pairs(animals) do
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   if p.Z<=z+30 and p.Z>=z-250 then counts[p.X<0 and -1 or 1]+=1 end
  end
 end
 local lanes={-0.72,-0.24,0.24,0.72}
 for offset=prime and -12 or 0,220,8 do
  if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
  local targetZ=z-offset
  if -targetZ*tuning.MetersPerStud>=Catalog.MeadowEndMeters then continue end
  local narrow=Course.width(targetZ)<30
  if narrow and (offset-(prime and -12 or 0))%16~=0 then continue end
  local candidates=SpawnPlan.candidates(Course.ranges(targetZ,5),narrow and {-0.5,0.5} or lanes,math.floor(offset/8)%2==1)
  local preferred=counts[-1]<counts[1] and -1 or counts[1]<counts[-1] and 1 or (spawnSerial%2==0 and 1 or -1)
  table.sort(candidates,function(a,b)
   local sa,sb=a<0 and -1 or 1,b<0 and -1 or 1
   if sa~=sb then return sa==preferred end
   return math.abs(a)<math.abs(b)
  end)
  for _,x in ipairs(candidates) do
   if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
    -- Choose for each successful birth at its course position, not the viewer's
    -- position: offscreen preloading must not delay a 300m species until 400m.
    local id=Catalog.pick(math.max(0,-targetZ*tuning.MetersPerStud),spawnSerial)
    if not id then break end
    local side=x<0 and -1 or 1
    if counts[side]>counts[-side] then continue end
    local onScreen=Visibility.visible(x,Catalog[id].RootHeight,targetZ-z,aspect,tuning,1.2)
    if onScreen and not prime then continue end
    local safe=true
    for other in pairs(animals) do
     if other.Parent then local p=other.PrimaryPart.Position if math.abs(p.X-x)<8 and math.abs(p.Z-targetZ)<18 then safe=false break end end
    end
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not Catalog[id].Flying and not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+5 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+10 then safe=false break end
    end
    if safe then
     local model=World.spawn(Vector3.new(x,2,targetZ),id)
     model:SetAttribute("BornOutsideView",not onScreen)
     model:SetAttribute("OpeningScene",prime==true)
     created+=1
     counts[side]+=1
    end
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect,nil,false,12) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  local hazard=Course.hazard(p.X,p.Z-half.Z,half.X,flying) or Course.hazard(p.X,p.Z+half.Z,half.X,flying)
  if hazard then return hazard end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

local function breakObstacle(rock,respawn)
 local appearance={}
 for _,piece in ipairs(rock:GetDescendants()) do
  if piece:IsA("BasePart") then appearance[piece]=piece.Transparency piece.Transparency=1 piece.CanQuery=false end
 end
 rock:SetAttribute("Broken",true) rock:SetAttribute("BrokenAt",workspace:GetServerTimeNow()) rock.CanQuery=false
 if respawn then task.delay(5,function()
  if not rock.Parent then return end
  for piece,transparency in pairs(appearance) do if piece.Parent then piece.Transparency=transparency end end
  rock:SetAttribute("Broken",false) rock.CanQuery=true
 end) end
end
function World.hit(from, to, flying,mount,dashing)
	for _, rock in ipairs(obstacles:GetChildren()) do
  if mount and rock:GetAttribute("BreakableCrate") then continue end -- dedicated crateHit rule
		if rock:GetAttribute("Broken") or (flying and rock:GetAttribute("WallClass")~="High" and rock:GetAttribute("ObstacleSize")~="Large") then continue end
		local p,s = rock.Position,rock.Size
		if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then
   local obstacleSize=rock:GetAttribute("ObstacleSize") or (rock:GetAttribute("Scale")==1 and "Small" or nil)
   if mount and Rules.canBreakObstacle(mount:GetAttribute("SizeClass"),obstacleSize,dashing) then breakObstacle(rock,true)
   else return true end
  end
	end
	return false
end

function World.crateHit(from,to,mount,sizeClass,dashing)
 if mount:GetAttribute("Flying") then return false,0 end
 local broken=0
 for _,box in ipairs(obstacles:GetChildren()) do
  if not box:GetAttribute("BreakableCrate") or box:GetAttribute("Broken") then continue end
  local p,s=box.Position,box.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0) then
   if not Rules.canBreakCrate(sizeClass) then return true,broken end
   box.CanQuery=false box.CanTouch=false
   box:SetAttribute("Broken",true) box:SetAttribute("BrokenAt",workspace:GetServerTimeNow())
   for _,piece in ipairs(box:GetDescendants()) do if piece:IsA("BasePart") then piece.Transparency=1 piece.CanQuery=false end end
   -- Marked Broken before counting; later frames cannot reward this crate again.
   broken+=1
  end
 end
 return false,broken
end

-- Preserve each active runner's vicinity, and avoid unlimited course/animal growth.
function World.cleanup(nearZ)
	for index, chunk in pairs(chunks) do
		local keep = false
		for _, z in ipairs(nearZ) do if math.abs(index*tuning.GroundChunkStuds-z) < tuning.GroundChunkStuds*4 then keep = true break end end
		if not keep then
			chunk:Destroy()
			chunks[index] = nil
			for _, rock in ipairs(obstacles:GetChildren()) do if rock:GetAttribute("Chunk") == index then rock:Destroy() end end
		end
	end
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]=],after=[=[-- Restored pre-Raise-Animal meadow/canyon map, with current rig and private sessions.
local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Layout=require(script.Parent.GreenStarCourseLayout)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local SpawnPlan=require(game.ReplicatedStorage.RodeoFantasy.HerdSpawnPlan)
local spawnSerial=0
local viewerMeters=0

local function part(parent, name, position, size, color)
	local item = Instance.new("Part")
	item.Name, item.Anchored = name, true
	item.Size, item.Position, item.Color = size, position, color
	item.Material = Enum.Material.Sand
	item.Parent = parent
	return item
end

local function decoration(parent,name,position,size,color)
 local node=part(parent,name,position,size,color)
 node.Material=Enum.Material.SmoothPlastic
 node.CanCollide,node.CanTouch,node.CanQuery=false,false,false
 node.TopSurface,node.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 return node
end

local function createCrate(x,z,index)
 local box=part(obstacles,"BreakableCrate",Vector3.new(x,2,z),Vector3.new(4,4,4),Color3.fromRGB(133,88,54))
 box.Transparency=1 box.CanCollide=false box:SetAttribute("Chunk",index) box:SetAttribute("BreakableCrate",true)
 decoration(box,"WoodCore",box.Position,Vector3.new(3.6,3.6,3.6),Color3.fromRGB(143,97,59))
 for _,side in ipairs({-1,1}) do
  for _,height in ipairs({0.25,3.75}) do
   decoration(box,"Frame",Vector3.new(x,height,z+side*1.94),Vector3.new(4,0.5,0.25),Color3.fromRGB(218,163,94))
  end
  for _,edge in ipairs({-1,1}) do
   decoration(box,"Corner",Vector3.new(x+edge*1.75,2,z+side*1.94),Vector3.new(0.5,4,0.25),Color3.fromRGB(218,163,94))
  end
  local brace=decoration(box,"DiagonalBrace",Vector3.new(x,2,z+side*2),Vector3.new(4.4,0.45,0.2),Color3.fromRGB(195,137,77))
  brace.CFrame*=CFrame.Angles(0,0,math.pi/4)
 end
 return box
end

local function dressObstacle(rock,style,scale)
 rock.Transparency=1 rock:SetAttribute("Style",style) rock:SetAttribute("Scale",scale)
 local base=Vector3.new(rock.Position.X,0,rock.Position.Z)
 local function detail(name,pos,size,color)
  return decoration(rock,name,base+pos*scale,size*scale,color)
 end
 if style=="Tree" then
  detail("TreeTrunk",Vector3.new(0,2.2,0),Vector3.new(1.25,4.4,1.25),Color3.fromRGB(146,101,70))
  detail("TreeRoots",Vector3.new(0,0.25,0),Vector3.new(2.4,0.5,2.4),Color3.fromRGB(165,117,77))
  detail("LeafCrown",Vector3.new(0,4.3,0),Vector3.new(3.8,2.1,3.8),Color3.fromRGB(112,165,85))
  detail("LeafTop",Vector3.new(-0.2,5.65,0.1),Vector3.new(2.8,0.7,2.8),Color3.fromRGB(153,195,105))
  detail("LeafHighlight",Vector3.new(0.7,5.25,-0.7),Vector3.new(1.8,0.25,1.5),Color3.fromRGB(174,210,119))
 else
  local stone=detail("Boulder",Vector3.new(0,1.15,0),Vector3.new(3.8,2.3,3.8),Color3.fromRGB(177,157,123))
  stone.CFrame*=CFrame.Angles(0,0,0.06)
  detail("StoneCap",Vector3.new(-0.3,2.5,0.15),Vector3.new(2.7,0.7,2.6),Color3.fromRGB(199,181,143))
  detail("Moss",Vector3.new(-0.6,2.91,0.1),Vector3.new(1.6,0.12,1.5),Color3.fromRGB(124,166,87))
  detail("StoneChip",Vector3.new(1.45,0.4,1.35),Vector3.new(0.9,0.8,0.9),Color3.fromRGB(163,146,113))
 end
end

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
	obstacles = Instance.new("Folder")
	obstacles.Name, obstacles.Parent = "Obstacles", root
	local preview = root:FindFirstChild("PreviewMonster")
	if preview then preview:Destroy() end
	local floor = root:FindFirstChild("PreviewGround")
	if floor then floor:Destroy() end
end

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height,position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
 if species.UnlockMeters>viewerMeters then model:SetAttribute("WaitingForUnlock",true) end
	return model
end

function World.groundHeight(x,z) return 0 end

function World.ensure(z)
	local center = math.floor(z / tuning.GroundChunkStuds + 0.5)
	for index = center - 2, center + 1 do
		if chunks[index] or index*tuning.GroundChunkStuds < -Course.LengthStuds-128 or index*tuning.GroundChunkStuds>128 then continue end
		local chunk = Instance.new("Folder")
		chunk.Name, chunk.Parent = "Road_" .. index, root
		chunks[index] = chunk
		local start = index * tuning.GroundChunkStuds
		local random = Random.new(9101 + math.abs(index) * 137)
  -- Short slices follow the changing width; canyon slices have no central floor.
  for offset=-tuning.GroundChunkStuds/2+8,tuning.GroundChunkStuds/2-8,16 do
   local rowZ=start+offset
   local edge=math.min(Course.width(rowZ-8),Course.width(rowZ),Course.width(rowZ+8))
   local _,kind,t=Course.fork(rowZ)
   local middle=Course.median(rowZ)
   if kind=="Canyon" and middle>.1 then
    for _,side in ipairs({-1,1}) do
     local lane=edge-middle
     local floor=part(chunk,"Meadow",Vector3.new(side*(middle+lane/2),-1,rowZ),Vector3.new(lane,2,16),Color3.fromRGB(178,211,117))
     floor.Material=Enum.Material.SmoothPlastic
     decoration(chunk,"InnerCliff",Vector3.new(side*(middle+1.5),-15,rowZ),Vector3.new(3,28,16),Color3.fromRGB(146,119,87))
     decoration(chunk,"CliffLayer",Vector3.new(side*(middle+1.5),-22,rowZ),Vector3.new(3.2,2,16),Color3.fromRGB(106,88,68))
    end
    decoration(chunk,"CanyonDepth",Vector3.new(0,-32,rowZ),Vector3.new(middle*2,2,16),Color3.fromRGB(46,71,72))
   else
    local floor=part(chunk,"Meadow",Vector3.new(0,-1,rowZ),Vector3.new(edge*2,2,16),Color3.fromRGB(178,211,117))
    floor.Material=Enum.Material.SmoothPlastic
   end
   if kind=="Mountain" and middle>.1 then
    local h=3+10*math.sin(math.pi*t)+3*math.sin(t*5*math.pi)
    for _,side in ipairs({-1,1}) do
     local slope=Instance.new("WedgePart") slope.Name="MountainSlope" slope.Anchored=true
     slope.CanCollide,slope.CanTouch,slope.CanQuery=false,false,false
     slope.Size=Vector3.new(16,h,middle) slope.CFrame=CFrame.new(side*middle/2,h/2,rowZ)*CFrame.Angles(0,-side*math.pi/2,0)
     slope.Color=Color3.fromRGB(110,151,80) slope.Material=Enum.Material.SmoothPlastic slope.Parent=chunk
    end
    if math.floor(rowZ/16)%4==0 and middle>3 then
     decoration(chunk,"RidgeTreeTrunk",Vector3.new(0,h+1.4,rowZ),Vector3.new(.8,2.8,.8),Color3.fromRGB(146,101,70))
     decoration(chunk,"RidgeTreeCrown",Vector3.new(0,h+3.2,rowZ),Vector3.new(3.4,2,3.4),Color3.fromRGB(112,165,85))
     decoration(chunk,"RidgeTreeTop",Vector3.new(0,h+4.4,rowZ),Vector3.new(2.2,.7,2.2),Color3.fromRGB(153,195,105))
    elseif math.floor(rowZ/16)%5==0 then
     decoration(chunk,"RidgeRock",Vector3.new(0,h+.4,rowZ),Vector3.new(2,.8,1.6),Color3.fromRGB(177,157,123))
    end
   end
  end
  local placements=Layout[index]
  if placements then
   for _,o in ipairs(placements.obstacles) do
    local rock=part(obstacles,"Rock",Vector3.new(o.x,o.height/2,o.z),Vector3.new(4*o.scale,o.height,4*o.scale),Color3.fromRGB(167,130,99))
    rock:SetAttribute("Chunk",index) rock:SetAttribute("ObstacleSize",o.tier)
    rock.CanCollide=false -- server swept collision is authoritative
    dressObstacle(rock,o.style,o.scale)
   end
   for _,c in ipairs(placements.crates) do createCrate(c.x,c.z,index) end
  end
		for offset = -112,112,32 do
			local rowZ = start + offset
   if rowZ < -Course.LengthStuds-160 or rowZ>128 then continue end
   local edge=Course.width(rowZ)
   for _, side in ipairs({-1,1}) do
    local height=18+random:NextInteger(0,3) -- wall top remains above flying creatures
    decoration(chunk,"CanyonBase",Vector3.new(side*(edge+5),2,rowZ),Vector3.new(10,4,32),Color3.fromRGB(220,151,97))
    decoration(chunk,"CanyonStratum",Vector3.new(side*(edge+7),4.5,rowZ),Vector3.new(10,1,32),Color3.fromRGB(249,191,128))
    decoration(chunk,"CanyonUpper",Vector3.new(side*(edge+9),5+height/2,rowZ),Vector3.new(12,height,32),Color3.fromRGB(201,126,80))
    decoration(chunk,"GrassCap",Vector3.new(side*(edge+9),5+height+0.25,rowZ),Vector3.new(12,0.5,32),Color3.fromRGB(122,170,92))
    decoration(chunk,"GrassEdge",Vector3.new(side*(edge-3),0.08,rowZ),Vector3.new(6,0.16,32),Color3.fromRGB(143,190,96))
    for i=1,3 do
     local z=rowZ+random:NextNumber(-14,14)
     local x=side*random:NextNumber(edge-3,edge-1)
     decoration(chunk,"GrassTuft",Vector3.new(x,0.45,z),Vector3.new(0.5,0.9,0.5),Color3.fromRGB(109,161,77))
    end
    if random:NextNumber()<0.4 then
     local treeZ=rowZ+random:NextNumber(-8,8)
     decoration(chunk,"TreeTrunk",Vector3.new(side*(edge+13),5+height+2,treeZ),Vector3.new(1.4,4,1.4),Color3.fromRGB(152,99,67))
     decoration(chunk,"TreeCrown",Vector3.new(side*(edge+13),5+height+5,treeZ),Vector3.new(6,4,6),Color3.fromRGB(115,163,90))
     decoration(chunk,"TreeTop",Vector3.new(side*(edge+13),5+height+7,treeZ),Vector3.new(4,2,4),Color3.fromRGB(146,190,107))
    end
   end
   for i=1,3 do
    local x,z=random:NextNumber(-29,29),rowZ+random:NextNumber(-14,14)
    local sx,sz=random:NextNumber(2,5),random:NextNumber(3,8)
    -- Ground colour patches need support across their entire footprint.
    if Course.contains(x-sx/2,z-sz/2,0) and Course.contains(x+sx/2,z-sz/2,0)
     and Course.contains(x-sx/2,z+sz/2,0) and Course.contains(x+sx/2,z+sz/2,0) then
     decoration(chunk,"MeadowPatch",Vector3.new(x,0.025,z),Vector3.new(sx,0.05,sz),Color3.fromRGB(187,218,128))
    end
   end
		end
	end
end

function World.step(dt)
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if rock:IsA("BasePart") and not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
   if model:GetAttribute("PreparedHerd") and -model.PrimaryPart.Position.Z*tuning.MetersPerStud-viewerMeters>22 then
    model:SetAttribute("HerdVelocity",Vector3.zero) model:SetAttribute("Running",false) continue
   end
   model:SetAttribute("Running",true)
   if model:GetAttribute("WaitingForUnlock") then
    if viewerMeters<Catalog[model:GetAttribute("MonsterId")].UnlockMeters then
     model:SetAttribute("HerdVelocity",Vector3.zero) model:SetAttribute("Running",false)
     continue
    end
    model:SetAttribute("WaitingForUnlock",nil) model:SetAttribute("Running",true)
   end
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,p.Y,z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

-- Fixed segment herds enter presentation well outside the widest mobile view.
function World.resetVisibility(viewer) end
function World.releaseMount(model,viewer) end
function World.visibleSet(z,aspect,viewer)
 viewerMeters=math.max(0,-z*tuning.MetersPerStud)
 local result={}
 for model in pairs(animals) do
  if model.Parent and not model:GetAttribute("Occupied") then
   local dz=model.PrimaryPart.Position.Z-z
   if dz<160 and dz>-380 then result[model]=true end
  end
 end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Prepare deterministic positions once. Instantiate only the approaching segments.
local planned=nil
local function prepareHerds()
 planned={}
 local placed={}
 for meters=0,1900,100 do
  local baseZ=-meters/tuning.MetersPerStud
  local ranges=Course.ranges(baseZ,5)
  local width=0 for _,r in ipairs(ranges) do width+=r[2]-r[1] end
  local count=width<24 and 3 or width<42 and 4 or 5
  for slot=1,count do
   local found=nil
   -- Stagger through the segment, alternate branches, and avoid approved obstacles.
   for attempt=0,49 do
    local z=baseZ-(slot-1)*14-math.floor(attempt/5)*8
    local lanes=SpawnPlan.candidates(Course.ranges(z,5),{-.65,0,.65},slot%2==0)
    if #lanes==0 then continue end
    local x=lanes[attempt%#lanes+1]
    local safe=Course.contains(x,z,5)
    for _,chunk in pairs(Layout) do
     for _,o in ipairs(chunk.obstacles) do
      if math.abs(o.x-x)<2*o.scale+5 and math.abs(o.z-z)<2*o.scale+8 then safe=false break end
     end
     for _,c in ipairs(chunk.crates) do if math.abs(c.x-x)<7 and math.abs(c.z-z)<10 then safe=false break end end
     if not safe then break end
    end
    for _,other in ipairs(placed) do if math.abs(other.x-x)<9 and math.abs(other.z-z)<18 then safe=false break end end
    if safe then found={x=x,z=z,id=Catalog.pick(meters,#placed),meters=meters} break end
   end
   if found then table.insert(planned,found) table.insert(placed,found) end
  end
 end
end
function World.replenish(z,aspect,watchers,prime,budget)
 viewerMeters=math.max(0,-z*tuning.MetersPerStud)
 if not planned then prepareHerds() end
 local created=0
 for _,entry in ipairs(planned) do
  if not entry.spawned and entry.z>=z-400 and entry.z<=z+40 then
   local model=World.spawn(Vector3.new(entry.x,2,entry.z),entry.id)
   model:SetAttribute("PreparedHerd",true)
   entry.spawned=true created+=1
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  local hazard=Course.hazard(p.X,p.Z-half.Z,half.X,flying) or Course.hazard(p.X,p.Z+half.Z,half.X,flying)
  if hazard then return hazard end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

local function breakObstacle(rock,respawn)
 local appearance={}
 for _,piece in ipairs(rock:GetDescendants()) do
  if piece:IsA("BasePart") then appearance[piece]=piece.Transparency piece.Transparency=1 piece.CanQuery=false end
 end
 rock:SetAttribute("Broken",true) rock:SetAttribute("BrokenAt",workspace:GetServerTimeNow()) rock.CanQuery=false
 if respawn then task.delay(5,function()
  if not rock.Parent then return end
  for piece,transparency in pairs(appearance) do if piece.Parent then piece.Transparency=transparency end end
  rock:SetAttribute("Broken",false) rock.CanQuery=true
 end) end
end
function World.hit(from, to, flying,mount,dashing)
	for _, rock in ipairs(obstacles:GetChildren()) do
  if mount and rock:GetAttribute("BreakableCrate") then continue end -- dedicated crateHit rule
		if rock:GetAttribute("Broken") or (flying and rock:GetAttribute("WallClass")~="High" and rock:GetAttribute("ObstacleSize")~="Large") then continue end
		local p,s = rock.Position,rock.Size
		if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then
   local obstacleSize=rock:GetAttribute("ObstacleSize") or (rock:GetAttribute("Scale")==1 and "Small" or nil)
   if mount and Rules.canBreakObstacle(mount:GetAttribute("SizeClass"),obstacleSize,dashing) then breakObstacle(rock,true)
   else return true end
  end
	end
	return false
end

function World.crateHit(from,to,mount,sizeClass,dashing)
 if mount:GetAttribute("Flying") then return false,0 end
 local broken=0
 for _,box in ipairs(obstacles:GetChildren()) do
  if not box:GetAttribute("BreakableCrate") or box:GetAttribute("Broken") then continue end
  local p,s=box.Position,box.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0) then
   if not Rules.canBreakCrate(sizeClass) then return true,broken end
   box.CanQuery=false box.CanTouch=false
   box:SetAttribute("Broken",true) box:SetAttribute("BrokenAt",workspace:GetServerTimeNow())
   for _,piece in ipairs(box:GetDescendants()) do if piece:IsA("BasePart") then piece.Transparency=1 piece.CanQuery=false end end
   -- Marked Broken before counting; later frames cannot reward this crate again.
   broken+=1
  end
 end
 return false,broken
end

-- Preserve each active runner's vicinity, and avoid unlimited course/animal growth.
function World.cleanup(nearZ)
	for index, chunk in pairs(chunks) do
		local keep = false
		for _, z in ipairs(nearZ) do if math.abs(index*tuning.GroundChunkStuds-z) < tuning.GroundChunkStuds*4 then keep = true break end end
		if not keep then
			chunk:Destroy()
			chunks[index] = nil
			for _, rock in ipairs(obstacles:GetChildren()) do if rock:GetAttribute("Chunk") == index then rock:Destroy() end end
		end
	end
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]=]},{name=[=[InventoryStore]=],parent=server,optional=false,before=[=[-- Shared by lobby and cafe. Fenced sessions and recoverable two-player trades.
local S={}
local DS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.BagRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local localOnly=Run:IsStudio() and (game.GameId==0 or game.PlaceId==0)
local suffix=Run:IsStudio() and "_Studio_v1" or "_v1"
local store,transactions
-- Unpublished Studio sessions cannot even acquire DataStore handles.
if not localOnly then
 store=DS:GetDataStore("RodeoInventory"..suffix)
 transactions=DS:GetDataStore("RodeoTrades"..suffix)
end
local entries={}
local function freshBag()
 local bag=Rules.new()
 local model=game:GetService("ServerStorage"):FindFirstChild("RodeoMonsterTemplate")
 if model and (model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" or model:GetAttribute("MossratUserRigRevision")=="NeutralQuadruped-v1") then
  local species=Catalog.MeadowMouse
  Rules.grant(bag,"MeadowMouse",workspace:GetServerTimeNow(),species.IncomeSeconds,species.IncomeAmount)
  bag.profile.starterMossratGranted=true
 end
 return bag
end
local function copy(value)
 if type(value)~="table" then return value end
 local out={} for k,v in pairs(value) do out[k]=copy(v) end return out
end
local function normalize(data)
 data=data or Rules.new()
 data.eggs=data.eggs or {} data.profile=data.profile or {} data.breedingTeams=data.breedingTeams or {}
 data.gems=data.gems or 0
 data.balance=data.balance or 0 data.pending=data.pending or 0 data.serial=data.serial or 0
 -- No unapproved offline income; begin the next interval on this server.
 for _,m in ipairs(data.monsters) do m.lastIncome=workspace:GetServerTimeNow() m.assignedPen=nil m.tradeLock=nil end
 return data
end
function S.open(player)
 local token=Http:GenerateGUID(false)
 if localOnly then local data=freshBag() entries[player]={token=token,data=data} player:SetAttribute("StarterMossratGranted",data.profile.starterMossratGranted==true) return data end
 local ok,result=pcall(function()
  return store:UpdateAsync(tostring(player.UserId),function(old)
   old=old or {data=freshBag()}
   if old.lock and old.lock.expires>os.time() then return nil end
   old.lock={token=token,expires=os.time()+120} return old
  end)
 end)
 if not ok or not result or not result.lock or result.lock.token~=token then return nil,"가방을 안전하게 불러오지 못했습니다. 잠시 후 다시 접속해주세요." end
 if result.pendingTrade then
  local pending=result.pendingTrade
  local found,tx=pcall(function() return transactions:GetAsync(pending.id) end)
  if not found then return nil,"거래 기록 확인 중입니다. 잠시 후 다시 접속해주세요." end
  if tx and tx.committed then result.data=pending.after end
  local resolved,saved=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=token then return nil end
    old.data=result.data old.pendingTrade=nil return old
   end)
  end)
  if not resolved or not saved then return nil,"거래 복구 중입니다. 잠시 후 다시 접속해주세요." end
 end
 local data=normalize(result.data)
 player:SetAttribute("StarterMossratGranted",data.profile.starterMossratGranted==true)
 entries[player]={token=token,data=data} return data
end
function S.busy(player) local e=entries[player] return not e or e.busy or e.closed end
function S.save(player,release)
 local e=entries[player] if not e or e.busy or e.closed then return false end
 e.busy=true
 local snapshot=copy(e.data)
 local ok,result=true,true
 if not localOnly then
  ok,result=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
    old.data=snapshot old.lock=not release and {token=e.token,expires=os.time()+120} or nil return old
   end)
  end)
 end
 e.busy=false
 if ok and result then if release then e.closed=true end return true end
 e.closed=true player:Kick("가방 저장 연결이 끊겨 안전하게 종료합니다. 다시 접속해주세요.") return false
end
function S.trade(a,b,after)
 local ea,eb=entries[a],entries[b]
 if S.busy(a) or S.busy(b) then return false end
 ea.busy=true eb.busy=true
 local id=Http:GenerateGUID(false)
 local ok=true
 if not localOnly then
  ok=pcall(function()
   -- Both before/after images persist before a single durable commit decision.
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
     old.data=copy(e.data) old.pendingTrade={id=id,after=copy(after[i])}
     old.lock.expires=os.time()+120 return old
    end)
    assert(written and written.pendingTrade and written.pendingTrade.id==id,"Trade checkpoint rejected")
   end
   transactions:UpdateAsync(id,function(old) return old or {committed=true,users={a.UserId,b.UserId},at=os.time()} end)
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or not old.pendingTrade or old.pendingTrade.id~=id then return nil end
     old.data=copy(after[i]) old.pendingTrade=nil return old
    end)
    assert(written and not written.pendingTrade,"Trade settlement pending")
   end
  end)
 end
 if ok then
  for i,e in ipairs({ea,eb}) do table.clear(e.data) for k,v in pairs(after[i]) do e.data[k]=v end end
 else
  -- Never overwrite uncertain durable transaction state with stale RAM.
  ea.closed=true eb.closed=true
  a:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.") b:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.")
 end
 ea.busy=false eb.busy=false return ok
end
function S.close(player)
 local e=entries[player] if not e then return end
 local deadline=os.clock()+25
 while e.busy and os.clock()<deadline do task.wait(.1) end
 if not e.closed then S.save(player,true) end
 entries[player]=nil
end
task.spawn(function()
 while task.wait(30) do for player,e in pairs(entries) do if not e.closed and not e.busy then S.save(player) end end end
end)
game:BindToClose(function()
 local remaining=0
 for p in pairs(entries) do remaining+=1 task.spawn(function() S.close(p) remaining-=1 end) end
 local deadline=os.clock()+27 while remaining>0 and os.clock()<deadline do task.wait(.1) end
end)
return S
]=],after=[=[-- Shared by lobby and cafe. Fenced sessions and recoverable two-player trades.
local S={}
local DS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.BagRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local localOnly=Run:IsStudio() and (game.GameId==0 or game.PlaceId==0)
local suffix=Run:IsStudio() and "_Studio_v1" or "_v1"
local store,transactions
-- Unpublished Studio sessions cannot even acquire DataStore handles.
if not localOnly then
 store=DS:GetDataStore("RodeoInventory"..suffix)
 transactions=DS:GetDataStore("RodeoTrades"..suffix)
end
local entries={}
local function freshBag()
 local bag=Rules.new()
 local model=game:GetService("ServerStorage"):FindFirstChild("RodeoMonsterTemplate")
 if model and (model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" or model:GetAttribute("MossratUserRigRevision")=="NeutralQuadruped-v1") then
  local species=Catalog.MeadowMouse
  Rules.grant(bag,"MeadowMouse",workspace:GetServerTimeNow(),species.IncomeSeconds,species.IncomeAmount)
  bag.profile.starterMossratGranted=true
 end
 return bag
end
local function copy(value)
 if type(value)~="table" then return value end
 local out={} for k,v in pairs(value) do out[k]=copy(v) end return out
end
local function normalize(data)
 data=data or Rules.new()
 data.eggs=data.eggs or {} data.profile=data.profile or {} data.breedingTeams=data.breedingTeams or {}
 data.gems=data.gems or 0
 data.balance=data.balance or 0 data.pending=data.pending or 0 data.serial=data.serial or 0
 -- Migrate stored income settings before awarding the offline fraction.
 for _,m in ipairs(data.monsters) do local c=Catalog[m.monsterId] if c then m.incomeSeconds=c.IncomeSeconds m.incomeAmount=c.IncomeAmount end end
 for _,m in ipairs(data.monsters) do m.lastIncome=workspace:GetServerTimeNow() m.assignedPen=nil m.tradeLock=nil end
 return data
end
function S.open(player)
 local token=Http:GenerateGUID(false)
 if localOnly then local data=freshBag() entries[player]={token=token,data=data} player:SetAttribute("StarterMossratGranted",data.profile.starterMossratGranted==true) return data end
 local ok,result=pcall(function()
  return store:UpdateAsync(tostring(player.UserId),function(old)
   old=old or {data=freshBag()}
   if old.lock and old.lock.expires>os.time() then return nil end
   old.lock={token=token,expires=os.time()+120} return old
  end)
 end)
 if not ok or not result or not result.lock or result.lock.token~=token then return nil,"가방을 안전하게 불러오지 못했습니다. 잠시 후 다시 접속해주세요." end
 if result.pendingTrade then
  local pending=result.pendingTrade
  local found,tx=pcall(function() return transactions:GetAsync(pending.id) end)
  if not found then return nil,"거래 기록 확인 중입니다. 잠시 후 다시 접속해주세요." end
  if tx and tx.committed then result.data=pending.after end
  local resolved,saved=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=token then return nil end
    old.data=result.data old.pendingTrade=nil return old
   end)
  end)
  if not resolved or not saved then return nil,"거래 복구 중입니다. 잠시 후 다시 접속해주세요." end
 end
 local claimed,claim=pcall(function()
  return store:UpdateAsync(tostring(player.UserId),function(old)
   if not old or not old.lock or old.lock.token~=token or old.pendingTrade then return nil end
   local data=normalize(old.data)
   if old.savedAt then Rules.offline(data,math.max(0,os.time()-old.savedAt)) end
   old.data=data old.savedAt=os.time() return old
  end)
 end)
 if not claimed or not claim then return nil,"오프라인 수익을 안전하게 불러오지 못했습니다. 다시 접속해주세요." end
 local data=normalize(claim.data)
 player:SetAttribute("StarterMossratGranted",data.profile.starterMossratGranted==true)
 entries[player]={token=token,data=data} return data
end
function S.busy(player) local e=entries[player] return not e or e.busy or e.closed end
function S.save(player,release)
 local e=entries[player] if not e or e.busy or e.closed then return false end
 e.busy=true
 local snapshot=copy(e.data)
 local ok,result=true,true
 if not localOnly then
  ok,result=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
    old.data=snapshot old.savedAt=os.time() old.lock=not release and {token=e.token,expires=os.time()+120} or nil return old
   end)
  end)
 end
 e.busy=false
 if ok and result then if release then e.closed=true end return true end
 e.closed=true player:Kick("가방 저장 연결이 끊겨 안전하게 종료합니다. 다시 접속해주세요.") return false
end
function S.trade(a,b,after)
 local ea,eb=entries[a],entries[b]
 if S.busy(a) or S.busy(b) then return false end
 ea.busy=true eb.busy=true
 local id=Http:GenerateGUID(false)
 local ok=true
 if not localOnly then
  ok=pcall(function()
   -- Both before/after images persist before a single durable commit decision.
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
     old.data=copy(e.data) old.savedAt=os.time() old.pendingTrade={id=id,after=copy(after[i])}
     old.lock.expires=os.time()+120 return old
    end)
    assert(written and written.pendingTrade and written.pendingTrade.id==id,"Trade checkpoint rejected")
   end
   transactions:UpdateAsync(id,function(old) return old or {committed=true,users={a.UserId,b.UserId},at=os.time()} end)
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or not old.pendingTrade or old.pendingTrade.id~=id then return nil end
     old.data=copy(after[i]) old.pendingTrade=nil return old
    end)
    assert(written and not written.pendingTrade,"Trade settlement pending")
   end
  end)
 end
 if ok then
  for i,e in ipairs({ea,eb}) do table.clear(e.data) for k,v in pairs(after[i]) do e.data[k]=v end end
 else
  -- Never overwrite uncertain durable transaction state with stale RAM.
  ea.closed=true eb.closed=true
  a:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.") b:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.")
 end
 ea.busy=false eb.busy=false return ok
end
function S.close(player)
 local e=entries[player] if not e then return end
 local deadline=os.clock()+25
 while e.busy and os.clock()<deadline do task.wait(.1) end
 if not e.closed then S.save(player,true) end
 entries[player]=nil
end
task.spawn(function()
 while task.wait(30) do for player,e in pairs(entries) do if not e.closed and not e.busy then S.save(player) end end end
end)
game:BindToClose(function()
 local remaining=0
 for p in pairs(entries) do remaining+=1 task.spawn(function() S.close(p) remaining-=1 end) end
 local deadline=os.clock()+27 while remaining>0 and os.clock()<deadline do task.wait(.1) end
end)
return S
]=]},{name=[=[LobbyCompanions]=],parent=server,optional=false,before=[=[-- One owned companion per lobby player; riding remains server authoritative.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
local RideRules=require(P.LobbyRideRules)
function M.new(context)
 local pets={}
 local map=context.map or workspace:WaitForChild("RodeoLobby")
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
  if revision~="ApprovedS1-v1" and revision~="UserS3-v1" and revision~="UserS6-v1" and revision~="UserS9-v1" and revision~="ProvidedBiped-v1" and revision~="NeutralQuadruped-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=context.streamingMode or Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  if item.monsterId=="GrassBoar" then model:SetAttribute("SummonedAt",workspace:GetServerTimeNow()) end
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
     local facing=CFrame.lookAt(position,position+delta).Rotation
     local frame=CFrame.new(position)*old.Rotation:Lerp(facing,1-math.exp(-9*step))
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
 local map=context.map or workspace:WaitForChild("RodeoLobby")
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
  pet.ride=nil pet.input=Vector3.zero pet.jumpAt=nil pet.jumpHeight=nil
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
 function api.jump(p)
  local pet=pets[p]
  if not pet or not pet.ride or pet.jumpAt or not context.canAct(p) then return end
  pet.jumpAt=os.clock() pet.jumpHeight=0
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
  if revision~="ApprovedS1-v1" and revision~="UserS3-v1" and revision~="UserS6-v1" and revision~="UserS9-v1" and revision~="ProvidedBiped-v1" and revision~="NeutralQuadruped-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=context.streamingMode or Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  if item.monsterId=="GrassBoar" then model:SetAttribute("SummonedAt",workspace:GetServerTimeNow()) end
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
    local old=pet.model.PrimaryPart.CFrame-Vector3.new(0,pet.jumpHeight or 0,0)
    local heading=RideRules.turn(old.LookVector,direction,step)
    local delta=heading*direction.Magnitude*RideRules.speed(pet.model:GetAttribute("Stars"))*(context.speedMultiplier or 1)*step
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
    local lift=0
    if pet.jumpAt then
     local t=(os.clock()-pet.jumpAt)/.8
     if t>=1 then pet.jumpAt=nil else lift=math.sin(math.pi*t)*5 end
    end
    pet.jumpHeight=lift frame+=Vector3.new(0,lift,0)
    pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
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
     local facing=CFrame.lookAt(position,position+delta).Rotation
     local frame=CFrame.new(position)*old.Rotation:Lerp(facing,1-math.exp(-9*step))
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
]=]}}
local function norm(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name,true)
 if (c.name=="CafeServer" and game.PlaceId~=133084853508719) or ((c.name=="CaptureServer" or c.name=="HuntWorld") and game.PlaceId~=131121026461681) then c.node=nil end
 assert(c.node or c.optional,"Missing "..c.name)
 if c.node then
  assert(c.node:IsA("LuaSourceContainer"),"Unexpected "..c.name)
  assert(norm(c.node.Source)==norm(c.before) or norm(c.node.Source)==norm(c.after) or (c.name=="BagUI" and norm(c.node.Source)==norm((c.after:gsub(' and child.Name~="DiscardMonster"','')))),"Other changes "..c.name)
  assert(loadstring(c.after),"Invalid "..c.name) c.original=c.node.Source
 end
end
local backup=Instance.new("Folder") backup.Name="GameplayUpdateBackup" backup.Archivable=false backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do if c.node then c.node:Clone().Parent=backup end end
game.ChangeHistoryService:SetWaypoint("Before gameplay update")
local ok,err=pcall(function() for _,c in ipairs(changes) do if c.node then c.node.Source=c.after end end end)
if not ok then for _,c in ipairs(changes) do if c.node then c.node.Source=c.original end end error(err) end
game.ChangeHistoryService:SetWaypoint("Gameplay updated")
print("GAMEPLAY_UPDATE_INSTALLED",game.PlaceId)
