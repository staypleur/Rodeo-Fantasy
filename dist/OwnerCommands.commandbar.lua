do
assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local SS=game.ServerStorage local P=game.ReplicatedStorage.RodeoFantasy
local backup=Instance.new("Folder") backup.Name="OwnerCommandsBackup_"..game:GetService("HttpService"):GenerateGUID(false)
local rows={
{node=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("BagUI",true)),before=[=[local UI={}
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
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(.31,-24,0,34),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=20},money)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve","en-us"),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters","en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("ViewportFrame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
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
 local hovered,hold
 UIS.InputBegan:Connect(function(input,processed) if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.E and hovered and window.Visible and (self.area=="Cafe" or self.area=="Lobby") then hold={id=hovered,at=os.clock()} end end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.E then hold=nil end end)
 game:GetService("RunService").RenderStepped:Connect(function() if hold and window.Visible and hovered==hold.id and os.clock()-hold.at>=1 then remote:FireServer("Summon",hold.id) hold=nil end end)
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
  money.Text="Coins: "..tostring((state.pending or 0)+(state.balance or 0))
  button.Text=""
  if state.area~="Hunt" and self.count~=state.count then self.count=state.count remote:FireServer("Bag") end
 end
 function self.openPen(index)
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode=nil chooser.Visible=false scroll.Visible=true
  self.pen=index self.snapshot(self.items) window.Visible=true self.opened()
 end
 function self.snapshot(items)
  self.items=items self.cards={} hovered=nil hold=nil
  local present={} for _,item in ipairs(items) do present[item.id]=true end
  for id in pairs(self.selected) do if not present[id] then self.selected[id]=nil end end
  local placed=0
  for _,item in ipairs(items) do if item.assignedPen==self.pen and self.pen then placed+=1 end end
  title.Text=L.text(self.mode=="Companion" and "Companion · Choose one" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag","en-us")..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,"en-us") end)
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
   local preview=make("ViewportFrame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23,Ambient=Color3.fromRGB(195,195,195),LightColor=Color3.new(1,1,1)},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   make("TextLabel",{Name="Income",Text=L.income(item.incomeAmount,item.incomeSeconds,"en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),TextSize=14,TextWrapped=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
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
     card.MouseEnter:Connect(function() hovered=item.id end) card.MouseLeave:Connect(function() if hovered==item.id then hovered=nil hold=nil end end)
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
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(.31,-24,0,34),TextScaled=true,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=20},money)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve","en-us"),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters","en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("ViewportFrame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
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
  money.Text="Coins: "..tostring((state.pending or 0)+(state.balance or 0))
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
   local preview=make("ViewportFrame",{Name="MonsterImage",BackgroundTransparency=1,Size=UDim2.new(1,0,0,140),ZIndex=23,Ambient=Color3.fromRGB(195,195,195),LightColor=Color3.new(1,1,1)},card)
   Portrait.fill(preview,item.monsterId,item.stars,false)
   make("TextLabel",{Text=L.text(item.monsterId,"en-us").." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   make("TextLabel",{Name="Income",Text=L.income(item.incomeAmount,item.incomeSeconds,"en-us"),BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),TextSize=14,TextWrapped=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
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
]=]},
{node=assert(game.ServerScriptService:FindFirstChild("CaptureServer",true)),before=[=[local Players=game:GetService("Players")
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
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0,"GreenStar")
 local wildIds={}
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
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
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
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
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
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
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 companions.clear(player)
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
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" and action~="BondPet" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="BondPet" then companions.bond(player,value) return end
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
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
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
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 for index=1,4 do Lobby.display(player,index,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
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
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0,"GreenStar")
 local wildIds={}
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
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
  remote:FireClient(player,"SocialMessage","Added "..count.." Mossrat ("..stars.." stars).")
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
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
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
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
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
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 companions.clear(player)
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
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" and action~="BondPet" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="BondPet" then companions.bond(player,value) return end
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
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
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
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 for index=1,4 do Lobby.display(player,index,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]=]},
}
for _,r in ipairs(rows) do assert(r.node.Source:gsub("\r\n","\n")==r.before or r.node.Source:gsub("\r\n","\n")==r.after,"Code changed: "..r.node.Name) end
local imported=assert(workspace:FindFirstChild("Scene"),"6-star imported Scene missing")
local meshes={} for _,n in ipairs(imported:GetDescendants()) do if n:IsA("MeshPart") then table.insert(meshes,n) end end assert(#meshes==1,"Expected one 6-star mesh")
local box,size=imported:GetBoundingBox() local scale=4.75/size.Y local base=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0))
local template=assert(P:FindFirstChild("VisualTemplate_S3")):Clone() template.Name="VisualTemplate_S6"
for _,n in ipairs(template:GetChildren()) do if n:IsA("BasePart") and n~=template.PrimaryPart then n:Destroy() end end
local body=meshes[1]:Clone() body.Name="Body" local relative=base:ToObjectSpace(body.CFrame)
local rest=CFrame.new(relative.Position*scale-Vector3.new(0,2.05*1.9,0))*relative.Rotation
body.Size*=scale body.CFrame=template.PrimaryPart.CFrame*rest body.Anchored=true body.CanCollide=false body.CanQuery=false body.CanTouch=false body:SetAttribute("ApprovedRest",rest) body.Parent=template
template:SetAttribute("MossratUserRigRevision","UserS6Preview") template:SetAttribute("NativeMeshyStars",6) template:SetAttribute("NativeMeshyFacingRevision",nil) template:SetAttribute("UserApprovedHuntModel",false)
game:GetService("ChangeHistoryService"):SetWaypoint("Before owner chat and 6-star preview")
backup.Parent=SS
for _,r in ipairs(rows) do r.node:Clone().Parent=backup r.node.Source=r.after end
local old=P:FindFirstChild("VisualTemplate_S6") if old then old.Parent=backup end template.Parent=P imported.Parent=backup
local operator=game.ServerScriptService:FindFirstChild("OperatorCommands") if operator then operator:Clone().Parent=backup else operator=Instance.new("ModuleScript") operator.Name="OperatorCommands" operator.Parent=game.ServerScriptService end
operator.Source=[=[-- Owner-only chat commands. No client privilege flag or operator button.
local M={}
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
-- Verified in Studio: puller3313, UserId 3116679300.
local ownerId=3116679300
function M.register(context)
 local function run(player,text)
  if not ownerId or player.UserId~=ownerId then return end
  local parts=string.split(text," ")
  local command=string.lower(parts[1] or "")
  if command=="/operator" then context.message(player,"Commands: /monster Mossrat <stars 1-10> [count 1-10]") return end
  if command~="/monster" then return end
  local species=string.lower(parts[2] or "")
  local stars,count=tonumber(parts[3]),tonumber(parts[4] or "1")
  if (species~="mossrat" and species~="meadowmouse" and species~="모스랫") or not stars or stars%1~=0 or stars<1 or stars>10
   or not count or count%1~=0 or count<1 or count>10 or #parts>4 then
   context.message(player,"Usage: /monster Mossrat <stars 1-10> [count 1-10]") return
  end
  context.grant(player,"MeadowMouse",stars,count)
 end
 if TextChatService.ChatVersion==Enum.ChatVersion.TextChatService then
  for _,alias in ipairs({"/monster","/operator"}) do
   local command=Instance.new("TextChatCommand") command.Name=alias=="/monster" and "RodeoOwnerMonster" or "RodeoOwnerHelp"
   command.PrimaryAlias=alias command.Parent=TextChatService
   command.Triggered:Connect(function(source,text)
    local player=source and Players:GetPlayerByUserId(source.UserId)
    if player then run(player,text) end
   end)
  end
 else
  local function added(player) player.Chatted:Connect(function(text) run(player,text) end) end
  Players.PlayerAdded:Connect(added)
  for _,player in ipairs(Players:GetPlayers()) do added(player) end
 end
end
return M
]=]
game:GetService("ChangeHistoryService"):SetWaypoint("Owner chat and 6-star preview installed")
print("OWNER_COMMANDS_AND_S6_PREVIEW_INSTALLED")
end
