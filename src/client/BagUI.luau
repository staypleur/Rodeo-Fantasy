local UI={}
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
 local money=make("TextLabel",{Name="BagMoney",BackgroundTransparency=1,Position=UDim2.fromOffset(20,55),Size=UDim2.new(.56,-20,0,34),TextSize=20,TextColor3=Color3.fromRGB(43,74,55),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},window)
 local evolveToggle=make("TextButton",{Name="EvolutionMode",Text=L.text("Evolve",player.LocaleId),Position=UDim2.new(.81,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
 make("UICorner",{CornerRadius=UDim.new(0,9)},evolveToggle)
 local evolveControls=make("Frame",{Name="EvolutionControls",Visible=false,BackgroundColor3=Color3.fromRGB(235,222,194),Position=UDim2.fromOffset(16,174),Size=UDim2.new(1,-32,0,58),ZIndex=22},window)
 make("UICorner",{CornerRadius=UDim.new(0,10)},evolveControls)
 local evolveStatus=make("TextLabel",{Name="EvolutionStatus",Text=L.text("Select three matching monsters",player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-258,1,0),TextSize=14,TextColor3=Color3.fromRGB(70,58,40),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=23},evolveControls)
 local evolvePreview=make("ViewportFrame",{Name="EvolutionPreview",BackgroundColor3=Color3.fromRGB(249,242,222),BackgroundTransparency=.12,Position=UDim2.new(1,-248,0,5),Size=UDim2.fromOffset(48,48),ZIndex=23},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolvePreview)
 local evolveCancel=make("TextButton",{Name="CancelEvolution",Text=L.text("Cancel",player.LocaleId),Position=UDim2.new(1,-194,0,12),Size=UDim2.fromOffset(80,34),TextSize=13,BackgroundColor3=Color3.fromRGB(164,139,107),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 local evolveConfirm=make("TextButton",{Name="ConfirmEvolution",Text=L.text("Evolve",player.LocaleId),Position=UDim2.new(1,-108,0,12),Size=UDim2.fromOffset(100,34),TextSize=13,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},evolveControls)
 make("UICorner",{CornerRadius=UDim.new(0,8)},evolveCancel) make("UICorner",{CornerRadius=UDim.new(0,8)},evolveConfirm)
 local scroll=make("ScrollingFrame",{Name="BagCards",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,175),Size=UDim2.new(1,-32,1,-230),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,ZIndex=21},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,245),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
 local empty=make("TextLabel",{Name="EmptyBag",Text="No monsters caught yet",BackgroundTransparency=1,Position=UDim2.fromScale(.1,.45),Size=UDim2.fromScale(.8,.15),TextSize=20,TextWrapped=true,ZIndex=22},window)
 local search=make("TextBox",{Name="BagSearch",PlaceholderText=L.text("Search monsters",player.LocaleId),Text="",ClearTextOnFocus=false,Position=UDim2.fromOffset(20,95),Size=UDim2.new(1,-40,0,34),BackgroundColor3=Color3.fromRGB(255,250,237),TextColor3=Color3.fromRGB(71,58,40),TextSize=17,ZIndex=23},window)
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
  local tab=make("TextButton",{Name="Region_"..region,Text=L.text(region,player.LocaleId),Size=UDim2.fromOffset(112,30),BackgroundColor3=Color3.fromRGB(213,193,159),TextColor3=Color3.fromRGB(65,53,37),TextSize=15,ZIndex=24},tabs)
  make("UICorner",{CornerRadius=UDim.new(0,8)},tab)
  tab.Activated:Connect(function() self.filter(region,nil) end)
 end
 local breed=make("TextButton",{Name="Breed",Text="교배",Position=UDim2.new(.62,0,0,55),Size=UDim2.new(.17,0,0,34),TextSize=16,BackgroundColor3=Color3.fromRGB(110,133,91),TextColor3=Color3.new(1,1,1),ZIndex=23},window)
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
   evolveStatus.Text=L.text(anchor.monsterId,player.LocaleId).." · "..anchor.stars.."★  →  "..(anchor.stars+1).."★    "..count.." / 3"
   for _,child in ipairs(evolvePreview:GetChildren()) do child:Destroy() end
   if anchor.stars<10 then Portrait.fill(evolvePreview,anchor.monsterId,anchor.stars+1,false) end
  else
   evolveStatus.Text=L.text("Select three matching monsters",player.LocaleId).."    "..count.." / 3"
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
  evolveToggle.Text=self.evolutionMode and L.text("Cancel",player.LocaleId) or L.text("Evolve",player.LocaleId)
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
  local choice=make("TextButton",{Name="RanchChoice"..index,Text="부화소".." "..index,BackgroundColor3=Color3.fromRGB(147,182,154),TextColor3=Color3.fromRGB(37,61,46),TextSize=22,ZIndex=24},chooser)
  make("UICorner",{CornerRadius=UDim.new(0,14)},choice)
  choice.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Manage",index) end end)
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="알 관리 · 부화소 선택"
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
  money.Text="코인: "..tostring((state.pending or 0)+(state.balance or 0))
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
  title.Text=L.text(self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag",player.LocaleId)..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
  for _,node in ipairs(scroll:GetChildren()) do if node:IsA("Frame") then node:Destroy() end end
  local filtered=Query.filter(items,Catalog,self.region,self.query,function(id) return L.text(id,player.LocaleId) end)
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
  empty.Text=L.text(#items==0 and "No monsters caught yet" or "No matching monsters",player.LocaleId)
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
   make("TextLabel",{Text=L.text(item.monsterId,player.LocaleId).." · "..tostring(item.stars).."★",BackgroundTransparency=1,Position=UDim2.fromOffset(4,140),Size=UDim2.new(1,-8,0,28),TextSize=18,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   make("TextLabel",{Name="Income",Text=L.income(item.incomeAmount,item.incomeSeconds,player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromOffset(4,172),Size=UDim2.new(1,-8,0,30),TextSize=14,TextWrapped=true,TextColor3=Color3.fromRGB(43,74,55),ZIndex=23},card)
   if self.pen then
    local mine=item.assignedPen==self.pen
    local allowed=mine or (not item.assignedPen and placed<2)
    local label=mine and "Return to bag" or item.assignedPen and "Placed" or placed>=2 and "Full" or "Place"
    local choose=make("TextButton",{Name="ChooseMonster",Text=L.text(label,player.LocaleId),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=allowed and Color3.fromRGB(80,134,104) or Color3.fromRGB(154,167,151),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if allowed and self.pen and self.area=="Lobby" then remote:FireServer(mine and "Remove" or "Place",{id=item.id,pen=self.pen}) end
    end)
   elseif self.evolutionMode then
    local anchor=selectionAnchor()
    local compatible=not anchor or (anchor.monsterId==item.monsterId and anchor.stars==item.stars)
    local selected=self.selected[item.id]==true
    local choose=make("TextButton",{Name="SelectForEvolution",Text=selected and L.text("Selected",player.LocaleId) or L.text("Select",player.LocaleId),Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=selected and Color3.fromRGB(80,134,104) or compatible and Color3.fromRGB(147,182,154) or Color3.fromRGB(184,181,168),TextColor3=Color3.new(1,1,1),Active=compatible and (selected or selectedCount()<3),ZIndex=24},card)
    make("UICorner",{CornerRadius=UDim.new(0,8)},choose)
    choose.Activated:Connect(function()
     if self.selected[item.id] then self.selected[item.id]=nil
     elseif compatible and selectedCount()<3 and self.area~="Hunt" then self.selected[item.id]=true end
     self.snapshot(self.items)
    end)
   elseif self.area=="Cafe" or self.area=="Lobby" then
    if item.id==self.summonedId and self.area=="Cafe" then
     make("TextLabel",{Text="소환 중",BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
    elseif not item.breedingTeam then
     local summon=make("TextButton",{Text=item.id==self.summonedId and "E 꾹 · 소환 해제" or "E 꾹 · 소환",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     card.MouseEnter:Connect(function() hovered=item.id end) card.MouseLeave:Connect(function() if hovered==item.id then hovered=nil hold=nil end end)
     summon.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then hovered=item.id hold={id=item.id,at=os.clock()} end end)
     summon.InputEnded:Connect(function() hold=nil end)
    end
   elseif item.assignedPen then
    make("TextLabel",{Text=L.text("Placed",player.LocaleId).." · "..item.assignedPen,BackgroundTransparency=1,Position=UDim2.fromOffset(4,208),Size=UDim2.new(1,-8,0,29),TextSize=14,ZIndex=23},card)
   end

  end
  updateEvolutionControls()
 end
 function self.evolutionResult(result)
  if type(result)~="table" then return end
  if result.ok then
   self.selected={} self.evolutionMode=false evolveControls.Visible=false
   scroll.Position=UDim2.fromOffset(16,175) scroll.Size=UDim2.new(1,-32,1,-230)
   evolveToggle.Text=L.text("Evolve",player.LocaleId)
  else
   local key=result.reason=="MaxStars" and "Already at max stars" or "Evolution failed"
   evolveStatus.Text=L.text(key,player.LocaleId)
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
