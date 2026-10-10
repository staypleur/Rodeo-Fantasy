do
assert(not game:GetService("RunService"):IsRunning(),"Stop Play before applying")
local package=game.ReplicatedStorage.RodeoFantasy
local changes={
{name="BagUI",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[local UI={}
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
 function self.openCompanionMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="Companion" self.pen=nil chooser.Visible=false scroll.Visible=true
  self.snapshot(self.items) window.Visible=true self.opened() title.Text="동행 몬스터 · 1마리 선택" remote:FireServer("Bag")
 end
 function self.openRanchMenu()
  if self.area=="Hunt" then return end
  self.setEvolutionMode(false) self.mode="RanchMenu" self.pen=nil self.snapshot(self.items) window.Visible=true self.opened() chooser.Visible=true scroll.Visible=false empty.Visible=false
  title.Text="알 관리 · 개인 부화소"
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
  title.Text=L.text(self.mode=="Companion" and "동행 몬스터 · 1마리 선택" or self.mode=="RanchMenu" and "Choose ranch" or self.pen and "Ranch" or "Bag",player.LocaleId)..(self.pen and (" "..self.pen.." · "..placed.."/2") or "")
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
   if self.mode=="Companion" then
    local choose=make("TextButton",{Name="ChooseCompanion",Text=self.summonedId==item.id and "소환 해제" or "동행 선택",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,32),TextSize=16,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
    choose.Activated:Connect(function() if self.area=="Lobby" then remote:FireServer("Summon",item.id) end end)
   elseif self.pen then
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
]========],after=[========[local UI={}
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
     local summon=make("TextButton",{Text=item.id==self.summonedId and "Hold E · Dismiss" or "Hold E · Summon",Position=UDim2.fromOffset(8,208),Size=UDim2.new(1,-16,0,29),TextSize=14,BackgroundColor3=Color3.fromRGB(80,134,104),TextColor3=Color3.new(1,1,1),ZIndex=24},card)
     card.MouseEnter:Connect(function() hovered=item.id end) card.MouseLeave:Connect(function() if hovered==item.id then hovered=nil hold=nil end end)
     summon.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then hovered=item.id hold={id=item.id,at=os.clock()} end end)
     summon.InputEnded:Connect(function() hold=nil end)
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
]========]},
{name="CafeClient",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[local Players=game:GetService("Players")
local player=Players.LocalPlayer
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local PPS=game:GetService("ProximityPromptService")
local remote=game.ReplicatedStorage:WaitForChild("RodeoFantasy"):WaitForChild("CaptureRemote")
local gui=Instance.new("ScreenGui") gui.Name="CafeUI" gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=player:WaitForChild("PlayerGui")
local bag=require(script.Parent.BagUI).new(gui,remote)
local journal=require(script.Parent.JournalUI).new(gui,remote)
local social=require(script.Parent.SocialUI).new(gui,remote,bag,journal)
local animator=require(script.Parent.RideAnimator)
local off=Instance.new("TextButton") off.Name="Dismount" off.Text="Q · 내려오기" off.AnchorPoint=Vector2.new(.5,1) off.Position=UDim2.new(.5,0,1,-24) off.Size=UDim2.fromOffset(170,45) off.BackgroundColor3=Color3.fromRGB(61,98,72) off.TextColor3=Color3.new(1,1,1) off.TextSize=18 off.Visible=false off.Parent=gui
off.Activated:Connect(function() remote:FireServer("Dismount") end)
bag.onOpen=function() journal.close() end journal.onOpen=function() bag.close() end
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="Bag" then bag.snapshot(data)
 elseif kind=="State" then bag.state(data) journal.state(data) social.state(data) bag.income(data.income)
 elseif kind=="EvolutionResult" then bag.evolutionResult(data)
 elseif kind=="Journal" then journal.snapshot(data)
 else social.event(kind,data) end
end)
PPS.PromptShown:Connect(function(prompt)
 if prompt.Name=="RideOwnMonster" then prompt.Enabled=prompt:FindFirstAncestorOfClass("Model"):GetAttribute("OwnerUserId")==player.UserId
 elseif prompt.Name=="ViewCafeProfile" then prompt.Enabled=Players:GetPlayerFromCharacter(prompt.Parent.Parent)~=player end
end)
PPS.PromptTriggered:Connect(function(prompt)
 if prompt.Name=="ViewCafeProfile" then local other=Players:GetPlayerFromCharacter(prompt.Parent.Parent) if other and other~=player then remote:FireServer("Profile",other.UserId) end end
end)
UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.Q and player:GetAttribute("CafeMounted") then remote:FireServer("Dismount") end end)
local controls=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local sent=0
Run.RenderStepped:Connect(function(dt)
 off.Visible=player:GetAttribute("CafeMounted")==true
 local clock=workspace:GetServerTimeNow() local camera=workspace.CurrentCamera
 local pets=workspace:FindFirstChild("CafePets") if pets then animator.update(pets,clock,camera.CFrame.Position,dt) end
 if player:GetAttribute("CafeMounted") and clock-sent>.08 then
  sent=clock local move=controls:GetMoveVector() local cf=camera.CFrame
  local v=cf.RightVector*move.X+cf.LookVector*(-move.Z) v=Vector3.new(v.X,0,v.Z)
  remote:FireServer("CafeMove",v.Magnitude>1 and v.Unit or v)
 end
end)
remote:FireServer("Sync")
]========],after=[========[local Players=game:GetService("Players")
local player=Players.LocalPlayer
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local PPS=game:GetService("ProximityPromptService")
local remote=game.ReplicatedStorage:WaitForChild("RodeoFantasy"):WaitForChild("CaptureRemote")
local gui=Instance.new("ScreenGui") gui.Name="CafeUI" gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=player:WaitForChild("PlayerGui")
local bag=require(script.Parent.BagUI).new(gui,remote)
local journal=require(script.Parent.JournalUI).new(gui,remote)
local social=require(script.Parent.SocialUI).new(gui,remote,bag,journal)
local animator=require(script.Parent.RideAnimator)
local off=Instance.new("TextButton") off.Name="Dismount" off.Text="Q · Dismount" off.AnchorPoint=Vector2.new(.5,1) off.Position=UDim2.new(.5,0,1,-24) off.Size=UDim2.fromOffset(170,45) off.BackgroundColor3=Color3.fromRGB(61,98,72) off.TextColor3=Color3.new(1,1,1) off.TextSize=18 off.Visible=false off.Parent=gui
off.Activated:Connect(function() remote:FireServer("Dismount") end)
bag.onOpen=function() journal.close() end journal.onOpen=function() bag.close() end
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="Bag" then bag.snapshot(data)
 elseif kind=="State" then bag.state(data) journal.state(data) social.state(data) bag.income(data.income)
 elseif kind=="EvolutionResult" then bag.evolutionResult(data)
 elseif kind=="Journal" then journal.snapshot(data)
 else social.event(kind,data) end
end)
PPS.PromptShown:Connect(function(prompt)
 if prompt.Name=="RideOwnMonster" then prompt.Enabled=prompt:FindFirstAncestorOfClass("Model"):GetAttribute("OwnerUserId")==player.UserId
 elseif prompt.Name=="ViewCafeProfile" then prompt.Enabled=Players:GetPlayerFromCharacter(prompt.Parent.Parent)~=player end
end)
PPS.PromptTriggered:Connect(function(prompt)
 if prompt.Name=="ViewCafeProfile" then local other=Players:GetPlayerFromCharacter(prompt.Parent.Parent) if other and other~=player then remote:FireServer("Profile",other.UserId) end end
end)
UIS.InputBegan:Connect(function(input,processed) if not processed and input.KeyCode==Enum.KeyCode.Q and player:GetAttribute("CafeMounted") then remote:FireServer("Dismount") end end)
local controls=require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local sent=0
Run.RenderStepped:Connect(function(dt)
 off.Visible=player:GetAttribute("CafeMounted")==true
 local clock=workspace:GetServerTimeNow() local camera=workspace.CurrentCamera
 local pets=workspace:FindFirstChild("CafePets") if pets then animator.update(pets,clock,camera.CFrame.Position,dt) end
 if player:GetAttribute("CafeMounted") and clock-sent>.08 then
  sent=clock local move=controls:GetMoveVector() local cf=camera.CFrame
  local v=cf.RightVector*move.X+cf.LookVector*(-move.Z) v=Vector3.new(v.X,0,v.Z)
  remote:FireServer("CafeMove",v.Magnitude>1 and v.Unit or v)
 end
end)
remote:FireServer("Sync")
]========]},
{name="HudIcons",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[-- Small native shapes: no external images are required for the menu symbols.
local I={}
-- IDs supplied by the user from their uploaded image list.
I.ImageIds={ShopButtonImage="rbxassetid://135776139567636",RouletteButtonImage="rbxassetid://103655794024864",IndexButtonImage="rbxassetid://135277525783308",
 EggButtonImage="rbxassetid://87551432940862",PawButtonImage="rbxassetid://85966265063532",MossratFaceImage="rbxassetid://87383094549038",MoneyImage="rbxassetid://71604722538432"}
function I.imageId(package,key)
 local id=package:GetAttribute(key)
 if key=="PawButtonImage" and id=="rbxassetid://8596625063532" then return I.ImageIds[key] end
 if type(id)=="string" and id~="rbxassetid://0" and id:match("^rbxassetid://%d+$") then return id end
 return I.ImageIds[key] or ""
end
-- User-supplied PNGs become Roblox image assets only after upload. Keep the
-- native controls usable until their content IDs are configured.
function I.bindArtwork(button,key)
 local package=game.ReplicatedStorage.RodeoFantasy
 local image=Instance.new("ImageLabel") image.Name="UploadedArtwork"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ZIndex=button.ZIndex+2 image.ScaleType=Enum.ScaleType.Fit image.Parent=button
 local background=button.BackgroundTransparency
 local originals,strokes={},{}
 for _,n in ipairs(button:GetChildren()) do
  if n:IsA("GuiObject") and n~=image then originals[n]=n.Visible
  elseif n:IsA("UIStroke") then strokes[n]=n.Enabled end
 end
 local function display()
  local ready=image.Image~="" and image.IsLoaded
  -- Keep the label renderable while Roblox requests the image. Hiding it until
  -- IsLoaded can leave it waiting indefinitely; a faint image permits loading.
  image.Visible=true image.ImageTransparency=ready and 0 or .99
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
 local function refresh()
  local id=I.imageId(package,key)
  if image.Image~=id then image.Image=id end
  display()
  -- IsLoaded may update without a property signal. Poll only this request and
  -- stop when it loads, changes, or the control is removed.
  task.spawn(function()
   while image.Parent and image.Image==id and not image.IsLoaded do task.wait(.25) end
   if image.Parent and image.Image==id then display() end
  end)
 end
 image:GetPropertyChangedSignal("IsLoaded"):Connect(display)
 package:GetAttributeChangedSignal(key):Connect(refresh) refresh()
end
function I.draw(parent,kind,size)
 local root=Instance.new("Frame") root.Name=kind.."Icon" root.Size=UDim2.fromOffset(size,size) root.BackgroundTransparency=1 root.Parent=parent
 local function shape(x,y,w,h,color,radius,rotation)
  local n=Instance.new("Frame") n.Position=UDim2.fromScale(x,y) n.Size=UDim2.fromScale(w,h) n.BackgroundColor3=color n.BorderSizePixel=0 n.Rotation=rotation or 0 n.Parent=root
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(radius or 0,0) c.Parent=n
  local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(15,18,20) s.Thickness=2 s.Parent=n return n
 end
 local white=Color3.fromRGB(255,249,229)
 if kind=="Egg" then shape(.23,.08,.54,.82,Color3.fromRGB(255,211,145),.5)
 elseif kind=="Paw" then
  shape(.27,.48,.48,.4,Color3.fromRGB(255,198,124),.45)
  for _,p in ipairs({{.08,.3},{.28,.1},{.53,.1},{.75,.3}}) do shape(p[1],p[2],.18,.28,Color3.fromRGB(255,209,151),.5) end
 elseif kind=="Shop" then
  shape(.2,.34,.65,.42,white,.12,-6) shape(.07,.17,.23,.09,white,.15)
  for _,x in ipairs({.3,.68}) do shape(x,.84,.15,.15,white,.5) end
 elseif kind=="Journal" then
  shape(.18,.17,.64,.66,white,.07,-8)
  for _,y in ipairs({.33,.48,.63}) do shape(.32,y,.36,.025,Color3.fromRGB(60,74,82),0) end
 elseif kind=="Money" then
  shape(.06,.25,.78,.52,Color3.fromRGB(92,226,39),.05,-12)
  shape(.2,.12,.75,.5,Color3.fromRGB(130,255,59),.05,-12)
  shape(.44,.16,.13,.51,Color3.fromRGB(240,215,35),0,-12)
 elseif kind=="Roulette" then
  shape(.08,.08,.84,.84,Color3.fromRGB(255,219,48),.5)
  for i=0,5 do local a=i*math.pi/3 shape(.43+math.cos(a)*.25,.43+math.sin(a)*.25,.16,.16,i%2==0 and Color3.fromRGB(255,93,104) or white,.5) end
  shape(.4,.4,.2,.2,Color3.fromRGB(250,250,250),.5)
 end
 return root
end
return I
]========],after=[========[-- Small native shapes: no external images are required for the menu symbols.
local I={}
-- IDs supplied by the user from their uploaded image list.
I.ImageIds={ShopButtonImage="rbxassetid://114640852127407",RouletteButtonImage="rbxassetid://71863210551741",IndexButtonImage="rbxassetid://110488541037597",BondButtonImage="rbxassetid://104399312241349",
 EggButtonImage="rbxassetid://87551432940862",PawButtonImage="rbxassetid://85966265063532",MossratFaceImage="rbxassetid://87383094549038",MoneyImage="rbxassetid://71604722538432"}
function I.imageId(package,key)
 local id=package:GetAttribute(key)
 if key=="PawButtonImage" and id=="rbxassetid://8596625063532" then return I.ImageIds[key] end
 if type(id)=="string" and id~="rbxassetid://0" and id:match("^rbxassetid://%d+$") then return id end
 return I.ImageIds[key] or ""
end
-- User-supplied PNGs become Roblox image assets only after upload. Keep the
-- native controls usable until their content IDs are configured.
function I.bindArtwork(button,key)
 local package=game.ReplicatedStorage.RodeoFantasy
 local image=Instance.new("ImageLabel") image.Name="UploadedArtwork"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ZIndex=button.ZIndex+2 image.ScaleType=Enum.ScaleType.Fit image.Parent=button
 local background=button.BackgroundTransparency
 local originals,strokes={},{}
 for _,n in ipairs(button:GetChildren()) do
  if n:IsA("GuiObject") and n~=image then originals[n]=n.Visible
  elseif n:IsA("UIStroke") then strokes[n]=n.Enabled end
 end
 local function display()
  local ready=image.Image~="" and image.IsLoaded
  -- Keep the label renderable while Roblox requests the image. Hiding it until
  -- IsLoaded can leave it waiting indefinitely; a faint image permits loading.
  image.Visible=true image.ImageTransparency=ready and 0 or .99
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
 local function refresh()
  local id=I.imageId(package,key)
  if image.Image~=id then image.Image=id end
  display()
  -- IsLoaded may update without a property signal. Poll only this request and
  -- stop when it loads, changes, or the control is removed.
  task.spawn(function()
   while image.Parent and image.Image==id and not image.IsLoaded do task.wait(.25) end
   if image.Parent and image.Image==id then display() end
  end)
 end
 image:GetPropertyChangedSignal("IsLoaded"):Connect(display)
 package:GetAttributeChangedSignal(key):Connect(refresh) refresh()
end
function I.draw(parent,kind,size)
 local root=Instance.new("Frame") root.Name=kind.."Icon" root.Size=UDim2.fromOffset(size,size) root.BackgroundTransparency=1 root.Parent=parent
 local function shape(x,y,w,h,color,radius,rotation)
  local n=Instance.new("Frame") n.Position=UDim2.fromScale(x,y) n.Size=UDim2.fromScale(w,h) n.BackgroundColor3=color n.BorderSizePixel=0 n.Rotation=rotation or 0 n.Parent=root
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(radius or 0,0) c.Parent=n
  local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(15,18,20) s.Thickness=2 s.Parent=n return n
 end
 local white=Color3.fromRGB(255,249,229)
 if kind=="Egg" then shape(.23,.08,.54,.82,Color3.fromRGB(255,211,145),.5)
 elseif kind=="Paw" then
  shape(.27,.48,.48,.4,Color3.fromRGB(255,198,124),.45)
  for _,p in ipairs({{.08,.3},{.28,.1},{.53,.1},{.75,.3}}) do shape(p[1],p[2],.18,.28,Color3.fromRGB(255,209,151),.5) end
 elseif kind=="Shop" then
  shape(.2,.34,.65,.42,white,.12,-6) shape(.07,.17,.23,.09,white,.15)
  for _,x in ipairs({.3,.68}) do shape(x,.84,.15,.15,white,.5) end
 elseif kind=="Journal" then
  shape(.18,.17,.64,.66,white,.07,-8)
  for _,y in ipairs({.33,.48,.63}) do shape(.32,y,.36,.025,Color3.fromRGB(60,74,82),0) end
 elseif kind=="Money" then
  shape(.06,.25,.78,.52,Color3.fromRGB(92,226,39),.05,-12)
  shape(.2,.12,.75,.5,Color3.fromRGB(130,255,59),.05,-12)
  shape(.44,.16,.13,.51,Color3.fromRGB(240,215,35),0,-12)
 elseif kind=="Roulette" then
  shape(.08,.08,.84,.84,Color3.fromRGB(255,219,48),.5)
  for i=0,5 do local a=i*math.pi/3 shape(.43+math.cos(a)*.25,.43+math.sin(a)*.25,.16,.16,i%2==0 and Color3.fromRGB(255,93,104) or white,.5) end
  shape(.4,.4,.2,.2,Color3.fromRGB(250,250,250),.5)
 end
 return root
end
return I
]========]},
{name="JournalUI",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
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
local function T(v) return L.text(v,player.LocaleId) end
function J.new(gui,remote)
 local self={area="Lobby",page=1,seen={},data={},entries=Q.entries(C),perSpread=8,selected=1}
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
 label(header,"Title","펫 인덱스",.02,.05,.7,.85,30).TextXAlignment=Enum.TextXAlignment.Left
 local close=make("TextButton",{Name="CloseJournal",Text="X",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(255,56,60),TextSize=30,BorderSizePixel=0,ZIndex=47},header)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},close)
 gradient(close,Color3.fromRGB(255,131,129),Color3.fromRGB(241,24,34))
 local region=panel(book,"PlanetLandscape",.02,.16,.14,.68,Color3.fromRGB(37,93,29))
 gradient(region,Color3.fromRGB(127,186,62),Color3.fromRGB(24,73,39))
 label(region,"PlanetName","Green Star",.04,.04,.92,.2,23)
 label(region,"Biome","초원",.08,.66,.84,.18,22)
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
 local planetTab=make("TextButton",{Name="Planet_GreenStar",Text="행성\nGreen Star",Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.18),BackgroundColor3=Color3.fromRGB(59,206,73),BorderSizePixel=0,TextScaled=true,ZIndex=46},book)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},planetTab)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=21},planetTab)
 gradient(planetTab,Color3.fromRGB(167,250,95),Color3.fromRGB(14,127,67))
 planetTab.Text=""
 local tabLabel=label(planetTab,"PlanetTabLabel","행성\nGreen Star",.36,.04,.62,.92,21) tabLabel.ZIndex=47
 make("ImageLabel",{Name="GreenStarTabArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.015,.08),Size=UDim2.fromScale(.34,.84),ScaleType=Enum.ScaleType.Fit,ZIndex=47},planetTab)
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
  local viewport=make("ViewportFrame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,Ambient=Color3.fromRGB(210,215,211),LightColor=Color3.new(1,1,1),ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income((species.IncomeAmount or 1)*2^(entry.stars-1),species.IncomeSeconds or 3,player.LocaleId) or "???",.04,.87,.92,.12,20)
  income.TextColor3=Color3.fromRGB(97,255,61)
  label(info,"Acquisition",revealed and (entry.stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,player.LocaleId) or L.evolutionHint(entry.stars,player.LocaleId)) or "수집하면 정보가 공개됩니다",.05,.05,.9,.58,16)
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
   local viewport=make("ViewportFrame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,Ambient=Color3.fromRGB(205,213,200),LightColor=Color3.new(1,1,1),ZIndex=45},card)
   Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
   label(card,"EntryName",revealed and T(entry.monsterId) or "???",.02,.01,.96,.19,17)
   label(card,"Stars",entry.stars.."★",0,.82,1,.18,16)
   card.Activated:Connect(function() self.selected=index self.render() end)
  end
  selectedDetail()
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
   region.Visible=false planetTab.Position=UDim2.fromScale(.70,.15) planetTab.Size=UDim2.fromScale(.28,.12)
   pages.Position=UDim2.fromScale(.02,.16) pages.Size=UDim2.fromScale(.65,.52)
   progress.Position=UDim2.fromScale(.02,.71) progress.Size=UDim2.fromScale(.65,.10)
   detail.Position=UDim2.fromScale(.70,.30) detail.Size=UDim2.fromScale(.28,.51)
   info.Visible=false
  else
   book.Position=UDim2.fromScale(.44,.5) book.Size=UDim2.fromScale(.76,.82)
   region.Visible=true planetTab.Position=UDim2.fromScale(1.025,.17) planetTab.Size=UDim2.fromScale(.18,.18)
   pages.Position=UDim2.fromScale(.18,.16) pages.Size=UDim2.fromScale(.50,.53)
   progress.Position=UDim2.fromScale(.18,.72) progress.Size=UDim2.fromScale(.50,.12)
   detail.Position=UDim2.fromScale(.70,.16) detail.Size=UDim2.fromScale(.28,.42) info.Visible=true
  end
  if book.Visible then self.render() end
 end
 -- Decide from screen width, not a size this callback itself changes.
 local function screenLayout()
  resize()
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(screenLayout) end
 task.defer(screenLayout)
 planetTab.Activated:Connect(function() self.page=1 self.render() end)
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]========],after=[========[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
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
  local viewport=make("ViewportFrame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,Ambient=Color3.fromRGB(210,215,211),LightColor=Color3.new(1,1,1),ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income((species.IncomeAmount or 1)*2^(entry.stars-1),species.IncomeSeconds or 3,"en-us") or "???",.04,.87,.92,.12,20)
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
   local viewport=make("ViewportFrame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,Ambient=Color3.fromRGB(205,213,200),LightColor=Color3.new(1,1,1),ZIndex=45},card)
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
]========]},
{name="LobbyMenus",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[-- Lobby entries only; products, odds and rewards remain undecided.
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
 for i,entry in ipairs({{"OpenShop","상점","상점 1 · 상점 2\n상품은 준비 중입니다."},{"OpenRoulette","룰렛","룰렛 규칙과 보상은 준비 중입니다."}}) do
  local color=i==1 and Color3.fromRGB(100,255,12) or Color3.fromRGB(255,191,31)
  local button=make("TextButton",{Name=entry[1],Text="",Position=UDim2.new(0,8,.42,i==1 and -26 or -90),Size=UDim2.fromOffset(144,56),BackgroundColor3=color,BorderSizePixel=0,Visible=false},gui)
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
  journalButton.AnchorPoint=Vector2.zero journalButton.Position=UDim2.new(0,8,.42,38) journalButton.Size=UDim2.fromOffset(144,56)
  journalButton.BackgroundColor3=Color3.fromRGB(15,216,255) journalButton.BackgroundTransparency=0
  make("UICorner",{CornerRadius=UDim.new(0,5)},journalButton) make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},journalButton)
  local icon=Icons.draw(journalButton,"Journal",38) icon.Position=UDim2.fromOffset(8,9)
  make("TextLabel",{Text="인덱스",BackgroundTransparency=1,Position=UDim2.fromOffset(54,0),Size=UDim2.new(1,-58,1,0),Font=Enum.Font.GothamBlack,TextSize=24,TextColor3=Color3.new(1,1,1),TextStrokeColor3=Color3.new(0,0,0),TextStrokeTransparency=0},journalButton)
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
   local offset=button.Name=="OpenRoulette" and -90 or button.Name=="OpenPaw" and 38 or -26
   button.Position=UDim2.new(left and 0 or 1,left and 8 or -8,compact and .36 or .42,offset*factor)
  end
  if journalButton then
   local scale=journalButton:FindFirstChild("ResponsiveScale") or make("UIScale",{Name="ResponsiveScale"},journalButton)
   scale.Scale=factor journalButton.Position=UDim2.new(0,8,compact and .36 or .42,38*factor)
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
]========],after=[========[-- Lobby entries only; products, odds and rewards remain undecided.
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
]========]},
{name="LocalizationController",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[local C={}
local service=game:GetService("LocalizationService")
local player=game:GetService("Players").LocalPlayer
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local records=setmetatable({},{__mode="k"})
local translator,cache,inflight=nil,{},{}
function C.locale() return player.LocaleId end
function C.text(source)
 local localText=L.text(source,C.locale())
 if localText~=source or string.sub(C.locale(),1,2)=="en" then return localText end
 if cache[source] then return cache[source] end
 if translator and not inflight[source] then
  inflight[source]=true
  task.spawn(function()
   local ok,value=pcall(function() return translator:Translate(workspace,source) end)
   cache[source]=ok and value or source inflight[source]=nil
   for node,record in pairs(records) do if record.source==source and node.Parent then record.apply() end end
  end)
 end
 return source
end
local function bind(node,property)
 local record={source=node[property],busy=false}
 records[node]=record
 function record.apply()
  if record.busy then return end
  record.busy=true
  local rankingRows=node.Name=="Entries" and node.Parent and (node.Parent.Name=="Ranking" or node.Parent.Name=="RankingBack")
  record.applied=(rankingRows and not L.entries[record.source]) and record.source or C.text(record.source)
  node[property]=record.applied record.busy=false
 end
 node:GetPropertyChangedSignal(property):Connect(function()
  if record.busy or node[property]==record.applied then return end
  record.source=node[property] record.apply()
 end)
 record.apply()
end
function C.watch(root)
 local function add(node)
  if node.Name=="LobbyStats" or node.Name=="BagMoney" or node.Name=="Income" or (node.Parent and node.Parent.Parent and node.Parent.Parent.Name=="OwnerBoard") then return end
  if node:IsA("TextLabel") or node:IsA("TextButton") then bind(node,"Text")
  elseif node:IsA("ProximityPrompt") then
   -- Prompt has two independently localized fields.
   node.ActionText=C.text(node.ActionText) node.ObjectText=C.text(node.ObjectText)
  end
 end
 for _,node in ipairs(root:GetDescendants()) do add(node) end
 root.DescendantAdded:Connect(add)
end
local function load()
 translator=nil cache={} inflight={}
 task.spawn(function()
  local ok,value=pcall(function() return service:GetTranslatorForPlayerAsync(player) end)
  if ok then translator=value end
  for _,record in pairs(records) do record.apply() end
 end)
 for _,record in pairs(records) do record.apply() end
end
player:GetPropertyChangedSignal("LocaleId"):Connect(load)
load()
return C
]========],after=[========[local C={}
local service=game:GetService("LocalizationService")
local player=game:GetService("Players").LocalPlayer
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local records=setmetatable({},{__mode="k"})
local translator,cache,inflight=nil,{},{}
-- The user chose English for all current game UI, regardless of account locale.
function C.locale() return "en-us" end
function C.text(source)
 local localText=L.text(source,C.locale())
 if localText~=source or string.sub(C.locale(),1,2)=="en" then return localText end
 if cache[source] then return cache[source] end
 if translator and not inflight[source] then
  inflight[source]=true
  task.spawn(function()
   local ok,value=pcall(function() return translator:Translate(workspace,source) end)
   cache[source]=ok and value or source inflight[source]=nil
   for node,record in pairs(records) do if record.source==source and node.Parent then record.apply() end end
  end)
 end
 return source
end
local function bind(node,property)
 local record={source=node[property],busy=false}
 records[node]=record
 function record.apply()
  if record.busy then return end
  record.busy=true
  local rankingRows=node.Name=="Entries" and node.Parent and (node.Parent.Name=="Ranking" or node.Parent.Name=="RankingBack")
  record.applied=(rankingRows and not L.entries[record.source]) and record.source or C.text(record.source)
  node[property]=record.applied record.busy=false
 end
 node:GetPropertyChangedSignal(property):Connect(function()
  if record.busy or node[property]==record.applied then return end
  record.source=node[property] record.apply()
 end)
 record.apply()
end
function C.watch(root)
 local function add(node)
  if node.Name=="LobbyStats" or node.Name=="BagMoney" or node.Name=="Income" or (node.Parent and node.Parent.Parent and node.Parent.Parent.Name=="OwnerBoard") then return end
  if node:IsA("TextLabel") or node:IsA("TextButton") then bind(node,"Text")
  elseif node:IsA("ProximityPrompt") then
   -- Prompt has two independently localized fields.
   node.ActionText=C.text(node.ActionText) node.ObjectText=C.text(node.ObjectText)
  end
 end
 for _,node in ipairs(root:GetDescendants()) do add(node) end
 root.DescendantAdded:Connect(add)
end
local function load()
 translator=nil cache={} inflight={}
 task.spawn(function()
  local ok,value=pcall(function() return service:GetTranslatorForPlayerAsync(player) end)
  if ok then translator=value end
  for _,record in pairs(records) do record.apply() end
 end)
 for _,record in pairs(records) do record.apply() end
end
player:GetPropertyChangedSignal("LocaleId"):Connect(load)
load()
return C
]========]},
{name="MonsterPortrait",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
function P.fill(viewport,id,stars,silhouette,distanceScale)
 local world=Instance.new("WorldModel") world.Parent=viewport
 local source=package:FindFirstChild(C.visual(id,stars))
 if not source or not source:GetAttribute("NativeMeshyMossrat") then
  local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
  label.Text="모델 준비 중" label.TextScaled=true label.TextColor3=Color3.fromRGB(160,180,170) label.Parent=viewport
  return nil
 end
 local model=source:Clone()
 local stage=C.stage(stars)
 model:ScaleTo(C.scale(stars)/C.Scales[stage])
 model.Parent=world model:PivotTo(CFrame.new())
 for _,node in ipairs(model:GetDescendants()) do
  if node:IsA("BillboardGui") or node:IsA("Light") then node:Destroy()
  elseif silhouette and node:IsA("SurfaceAppearance") then node:Destroy()
  elseif silhouette and node:IsA("BasePart") then node.Color=Color3.new(0,0,0) node.Material=Enum.Material.SmoothPlastic if node:IsA("MeshPart") then node.TextureID="" end end
 end
 model:SetAttribute("Stars",stars)
 model:SetAttribute("MonsterId",id) model:SetAttribute("PortraitSilhouette",silhouette==true)
 Mesh.decorate(model)
 Mesh.posePortrait(model)
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 -- Approved visual faces -Z. A straight camera avoids the old overhead
 -- three-quarter view, which made the face look turned in every menu.
 local direction=Vector3.new(0,0,-1)
 local function fit()
  local distance=math.max(size.X,size.Y,size.Z)*2.3
  if distanceScale then
   local aspect=viewport.AbsoluteSize.Y>0 and viewport.AbsoluteSize.X/viewport.AbsoluteSize.Y or 1
   local basis=CFrame.lookAt(Vector3.zero,-direction)
   local tangent=math.tan(math.rad(camera.FieldOfView/2))
   distance=0
   for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
    local p=basis:VectorToObjectSpace(frame:VectorToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
    distance=math.max(distance,p.Z+math.abs(p.Y)/tangent,p.Z+math.abs(p.X)/(tangent*math.max(.1,aspect)))
   end end end
   distance*=1.08
  end
  camera.CFrame=CFrame.lookAt(frame.Position+direction*distance,frame.Position)
 end
 fit()
 viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
 camera.Parent=viewport viewport.CurrentCamera=camera
 return model
end
return P
]========],after=[========[local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
function P.fill(viewport,id,stars,silhouette,distanceScale)
 local world=Instance.new("WorldModel") world.Parent=viewport
 local source=package:FindFirstChild(C.visual(id,stars))
 if not source or not source:GetAttribute("NativeMeshyMossrat") then
  local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
  label.Text="Model pending" label.TextScaled=true label.TextColor3=Color3.fromRGB(160,180,170) label.Parent=viewport
  return nil
 end
 local model=source:Clone()
 local stage=C.stage(stars)
 model:ScaleTo(C.scale(stars)/C.Scales[stage])
 model.Parent=world model:PivotTo(CFrame.new())
 for _,node in ipairs(model:GetDescendants()) do
  if node:IsA("BillboardGui") or node:IsA("Light") then node:Destroy()
  elseif silhouette and node:IsA("SurfaceAppearance") then node:Destroy()
  elseif silhouette and node:IsA("BasePart") then node.Color=Color3.new(0,0,0) node.Material=Enum.Material.SmoothPlastic if node:IsA("MeshPart") then node.TextureID="" end end
 end
 model:SetAttribute("Stars",stars)
 model:SetAttribute("MonsterId",id) model:SetAttribute("PortraitSilhouette",silhouette==true)
 Mesh.decorate(model)
 Mesh.posePortrait(model)
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 -- Approved visual faces -Z. A straight camera avoids the old overhead
 -- three-quarter view, which made the face look turned in every menu.
 local direction=Vector3.new(0,0,-1)
 local function fit()
  local distance=math.max(size.X,size.Y,size.Z)*2.3
  if distanceScale then
   local aspect=viewport.AbsoluteSize.Y>0 and viewport.AbsoluteSize.X/viewport.AbsoluteSize.Y or 1
   local basis=CFrame.lookAt(Vector3.zero,-direction)
   local tangent=math.tan(math.rad(camera.FieldOfView/2))
   distance=0
   for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
    local p=basis:VectorToObjectSpace(frame:VectorToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
    distance=math.max(distance,p.Z+math.abs(p.Y)/tangent,p.Z+math.abs(p.X)/(tangent*math.max(.1,aspect)))
   end end end
   distance*=1.08
  end
  camera.CFrame=CFrame.lookAt(frame.Position+direction*distance,frame.Position)
 end
 fit()
 viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
 camera.Parent=viewport viewport.CurrentCamera=camera
 return model
end
return P
]========]},
{name="PetPromptUI",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[-- A screen button avoids placing a large prompt over the companion model.
local M={}
function M.new(gui,player)
 local UIS=game:GetService("UserInputService")
 local service=game:GetService("ProximityPromptService")
 local current,held,connections=nil,nil,{}
 local button=Instance.new("TextButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,0,1,-100) button.Size=UDim2.fromOffset(150,48)
 button.BackgroundColor3=Color3.fromRGB(34,45,64) button.TextColor3=Color3.new(1,1,1) button.Font=Enum.Font.GothamBold
 button.TextSize=18 button.ZIndex=10 button.Parent=gui
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
  hide() current=prompt button.Visible=true button.Text=UIS.TouchEnabled and "교감" or "교감 E"
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
]========],after=[========[-- A screen button avoids placing a large prompt over the companion model.
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
]========]},
{name="RideAnimator",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}
local visibility={}
local warnings = {}
local package = game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local template = package:WaitForChild("VisualTemplate")
local templateRoot=assert(template.PrimaryPart,"VisualTemplate PrimaryPart 없음")
local tuning = require(package:WaitForChild("Config")).Prototype
local Rules = require(package:WaitForChild("HuntRules"))
local Catalog=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
local Crash=require(script.Parent:WaitForChild("CrashEffect"))
local dust={}
local contexts=setmetatable({},{__mode="k"})
local function clearHerdPath(from,to,root)
 local world=root:FindFirstAncestor("RodeoPrototype") or root:FindFirstAncestorWhichIsA("Folder")
 if world and world.Name=="Monsters" then world=world.Parent end
 local obstacles=world and world:FindFirstChild("Obstacles")
 if not obstacles then return true end
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:IsA("BasePart") or rock:GetAttribute("Broken") then continue end
  local p,s=rock.Position,rock.Size+root.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0.2) then return false end
 end
 return true
end
local function remember(model, existing)
	local root = model.PrimaryPart
 local speciesId=model:GetAttribute("MonsterId") or "MeadowMouse"
 local referenceTemplate=package:WaitForChild(Catalog.visual(speciesId,model:GetAttribute("Stars") or 1))
 local referenceRoot=assert(referenceTemplate.PrimaryPart,"몬스터 템플릿 PrimaryPart 없음")
	if not root then return nil end
	local pose = existing or {frame = root.CFrame, sample = root.CFrame, received = nil, tracked={}, restByPart={}}
 if existing and not pose.dirty then return pose end
 if not pose.watch then pose.watch=model.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then pose.dirty=true end end) end
 pose.dirty=false
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root and not pose.tracked[part] then
   local restFrame
   if part:GetAttribute("ApprovedRest") then
    -- Canonical mesh coordinates survive root movement during async installation.
    restFrame=part:GetAttribute("ApprovedRest")
   elseif model:GetAttribute("ImportedA") then
    -- Imported meshes already carry their correct per-model offsets; many are
    -- color-batched nodes whose names do not exist in the old part template.
    restFrame=root.CFrame:ToObjectSpace(part.CFrame)
   else
    local reference=referenceTemplate:FindFirstChild(part.Name,true)
    if not reference or not reference:IsA("BasePart") then
     part.LocalTransparencyModifier=1 pose.dirty=true continue
    end
    restFrame=referenceRoot.CFrame:ToObjectSpace(reference.CFrame)
   end
   part.LocalTransparencyModifier=0
			local side = string.sub(part.Name,1,4)=="Left" and "Left" or string.sub(part.Name,1,5)=="Right" and "Right" or nil
			local movingLeg = side and (string.find(part.Name,"Leg",1,true) or string.find(part.Name,"Paw",1,true) or string.find(part.Name,"Claw",1,true) or string.find(part.Name,"HoofLine",1,true))
			local leg = movingLeg and (string.find(part.Name,"Front",1,true) and "Front" or "Back") or nil
			if not leg then side=nil end
			pose.tracked[part]=true
   local entry={part=part,rest=restFrame,side=side,leg=leg}
   pose.restByPart[part]=restFrame
   table.insert(pose,entry)
		end
	end
	poses[model] = pose
	return pose
end

function RideAnimator.update(monsters, clock, cameraPosition, dt, selected)
 local context=contexts[monsters]
 if not context then context={poses={},visibility={},warnings={},dust={}} contexts[monsters]=context end
 poses,visibility,warnings,dust=context.poses,context.visibility,context.warnings,context.dust
 dt = dt or 1/60
 for i=#dust,1,-1 do
  local puff=dust[i] local age=clock-puff.started
  if age>=0.6 then puff.part:Destroy() table.remove(dust,i)
  else puff.part.Transparency=0.45+age/0.6*0.55 puff.part.Size=Vector3.one*(0.75+age*1.5) puff.part.Position+=Vector3.new(0,dt*0.7,0) end
 end
 local displayed = {}
 for model in pairs(visibility) do if not model:IsDescendantOf(monsters) then visibility[model]=nil end end
	for model, pose in pairs(poses) do
		if not model:IsDescendantOf(monsters) then poses[model] = nil end
	end
	for model, warning in pairs(warnings) do
		if not model:IsDescendantOf(monsters) then warning:Destroy() warnings[model] = nil end
	end
	if monsters.Name=="RodeoLobby" then
  local airport=monsters:FindFirstChild("Airport")
  local ship=airport and airport:FindFirstChild("Airship")
  if ship then
   context.airshipFrames=context.airshipFrames or {}
   for _,part in ipairs(ship:GetDescendants()) do
    if part:IsA("BasePart") and (part.Name=="SeaWingRoot" or part.Name=="SeaWingFeather") then
     local base=context.airshipFrames[part] or part.CFrame context.airshipFrames[part]=base
     local side=base.Position.X<6000 and -1 or 1
     local pivot=CFrame.new(6000+side*22,47,-9)
     local beat=math.sin(clock*1.15+1.2)*.21
     part.CFrame=pivot*CFrame.Angles(0,0,-side*beat)*pivot:Inverse()*base
    end
   end
  end
 end
 local outlineCount=0
	for _, model in ipairs(monsters.Name=="RodeoLobby" and monsters:GetDescendants() or monsters:GetChildren()) do
  if not model:IsA("Model") then continue end
  if not model:GetAttribute("MonsterId") or model:GetAttribute("NativeMeshyAirship") then continue end
		local root = model.PrimaryPart
		if not root then continue end
  if model:GetAttribute("KnockedAway") then
   Crash.knock(model,clock)
   for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=1 end end
   continue
  end
  local nameplate = root:FindFirstChild("Nameplate")
  if nameplate then nameplate.Enabled = false end
		if cameraPosition then
   local hidden=(root.Position-cameraPosition).Magnitude>220 or (selected and not model:GetAttribute("Occupied") and not selected[model])
   local record=visibility[model]
   if not record then
    record={} visibility[model]=record
    record.connection=model.DescendantAdded:Connect(function(part)
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=record.hidden and 1 or 0 end
    end)
   end
   if record.hidden~=hidden then
    record.hidden=hidden
    if not hidden then record.revealed=clock end
    for _,part in ipairs(model:GetChildren()) do
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=hidden and 1 or 0 end
    end
   end
   if hidden then
    local outline=model:FindFirstChild("LocalCreatureOutline") if outline then outline:Destroy() end
    continue
   end
  end
		Mesh.materialize(model)
  local outline=model:FindFirstChild("LocalCreatureOutline")
  if outlineCount<20 then
   if not outline then
    outline=Instance.new("Highlight") outline.Name="LocalCreatureOutline" outline.Adornee=model
    outline.FillTransparency=1 outline.OutlineTransparency=.05
    outline.OutlineColor=Color3.fromRGB(35,49,68) outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Parent=model
   end
   outline.Enabled=true outlineCount+=1
  elseif outline then outline:Destroy() end
  if not Mesh.failed and not model:GetAttribute("MeshDecorated") then task.spawn(Mesh.decorate,model) end
  local running = model:GetAttribute("Running") == true
		local pose = poses[model]
		if not pose and not running and not model:GetAttribute("BagItemId") then continue end
		pose = remember(model,pose) -- Include late replicated body parts on every frame.
  if pose.sample ~= root.CFrame or not pose.received then
   pose.sample, pose.received = root.CFrame, clock
  end
  local elapsed = math.clamp(clock-pose.received,0,0.08)
  local speed = model:GetAttribute("Occupied") and Rules.rideSpeed(clock,model:GetAttribute("DashUntil"),(model:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond),tuning.SwitchDashMultiplier) or (model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond)
  if model:GetAttribute("InitialLanding") then speed=0 end
  local steer = model:GetAttribute("Steering") or 0
  local velocity=Vector3.new(steer*tuning.SidewaysStudsPerSecond,0,-speed)
  if not model:GetAttribute("Occupied") then velocity=model:GetAttribute("HerdVelocity") or velocity end
  local target = pose.sample + velocity*(running and elapsed or 0)
  if not model:GetAttribute("Occupied") and not clearHerdPath(pose.sample.Position,target.Position,root) then target=pose.sample end
  if (target.Position-pose.frame.Position).Magnitude>30 or not running then
   pose.frame = target
  else
   local blended=pose.frame:Lerp(target,1-math.exp(-22*dt))
   if not model:GetAttribute("Occupied") and not clearHerdPath(pose.frame.Position,blended.Position,root) then blended=pose.sample end
   pose.frame = blended
  end

		local scale=Catalog.scale(model:GetAttribute("Stars") or 1)
		local phase = (clock - (model:GetAttribute("RunStarted") or clock)) * math.pi * 7
		local angry = model:GetAttribute("Angry") == true
		local warningActive = model:GetAttribute("AngerWarning") == true or angry
		local warning = warnings[model]
		if warningActive and not warning then
			warning = Instance.new("BillboardGui")
			warning.Name, warning.Size, warning.StudsOffset = "AngerWarning", UDim2.fromOffset(60, 70), Vector3.new(0, 4.5, 0)
			warning.AlwaysOnTop, warning.Adornee, warning.Parent = true, root, root
			local label = Instance.new("TextLabel")
			label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1, 1), 1, "!"
			label.Font, label.TextSize = Enum.Font.GothamBlack, 58
			label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(255, 104, 55), 0
			label.Parent = warning
			warnings[model] = warning
		end
		if warning then
   warning.Enabled = warningActive
   local label=warning:FindFirstChildWhichIsA("TextLabel")
   if label then label.TextTransparency=0.15+math.max(0,math.sin(clock*12))*0.45 end
  end
		local _,_,pitch=Rules.buck(clock-(model:GetAttribute("AngerStarted") or clock),tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[model:GetAttribute("MonsterId") or "MeadowMouse"].TripleHop)
		local facingFrame,straightFacing=Mesh.huntFrame(model,pose.frame)
		local lean = not straightFacing and running and (model:GetAttribute("Steering") or 0) * -0.18 or 0
  local moving=running and velocity.Magnitude>1
  Mesh.animate(model,phase,moving,angry)
  local flying=model:GetAttribute("Flying")==true
  local bounce=moving and (flying and (.55+math.sin(phase*.5)*.22) or (1-math.cos(phase))*.22) or 0
  local gallopPitch=moving and math.sin(phase)*0.085 or 0
		local frame = facingFrame * CFrame.new(0,bounce,0)*CFrame.Angles(angry and not flying and pitch or gallopPitch, 0, lean)
    if monsters.Name~="RodeoLobby" and monsters.Name~="CafePets" and moving and not flying and not model:GetAttribute("Occupied") and clock-(pose.lastDust or clock-1)>0.18 and #dust<80 then
   pose.lastDust=clock
   local puff=Instance.new("Part") puff.Name="LocalHerdDust" puff.Anchored=true
   puff.CanCollide,puff.CanTouch,puff.CanQuery=false,false,false
   puff.Color=Color3.fromRGB(239,220,176) puff.Size=Vector3.one*0.75 puff.Transparency=0.45
   puff.Position=Vector3.new(frame.X+math.sin(phase)*0.9,0.2,frame.Z+1.6)
   puff.Parent=workspace table.insert(dust,{part=puff,started=clock})
  end
  displayed[model] = frame
		for _, entry in ipairs(pose) do
			if not entry.part.Parent then continue end
			local localFrame = entry.rest
			if moving and flying and entry.part.Name:find("Wing",1,true) then
    local side=entry.part.Name:find("Left",1,true) and -1 or 1
    local pivot=CFrame.new(side*.8*scale,.3*scale,.15*scale)
    localFrame=pivot*CFrame.Angles(0,0,side*math.sin(phase*.7)*(angry and .85 or .55))*pivot:Inverse()*localFrame
   elseif moving and entry.side then
				local opposite = (entry.side == "Left") ~= (entry.leg == "Front")
				local swing = math.sin(phase + (opposite and math.pi or 0)) * 0.85
				local legPart=model:FindFirstChild(entry.side..entry.leg.."Leg")
			local legRest=legPart and pose.restByPart[legPart]
    local joint=CFrame.new(legRest and (legRest.Position+Vector3.new(0,legPart.Size.Y*.5,0)) or entry.rest.Position)
				localFrame = CFrame.new(0,math.max(0,math.sin(phase + (opposite and math.pi or 0)))*0.22,0) * joint * CFrame.Angles(swing, 0, 0) * joint:Inverse() * entry.rest
			end
   if running and entry.part.Name:find("Ear") then
    local sign=entry.part.Name:find("Left") and -1 or 1
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(sign*0.87*scale,1.3*scale,-1.21*scale)
    localFrame=pivot*CFrame.Angles(math.sin(phase)*0.12,0,sign*math.sin(phase)*0.1)*pivot:Inverse()*localFrame
   elseif running and entry.part.Name:find("Tail") then
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(0,-0.1*scale,1.7*scale)
    localFrame=pivot*CFrame.Angles(0,math.sin(phase*0.65)*0.3,0)*pivot:Inverse()*localFrame
   end
			entry.part.CFrame = frame * localFrame
   local shown=visibility[model]
   if shown and not shown.hidden then entry.part.LocalTransparencyModifier=math.clamp(1-(clock-(shown.revealed or clock-.3))/.25,0,1) end
		end
		-- Keep cached canonical poses while resting; late parts still align.
	end
 return displayed
end

return RideAnimator
]========],after=[========[-- Procedural visual motion for the native part model. Never changes its mount root.
local RideAnimator = {}
local poses = {}
local visibility={}
local warnings = {}
local package = game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local template = package:WaitForChild("VisualTemplate")
local templateRoot=assert(template.PrimaryPart,"VisualTemplate PrimaryPart 없음")
local tuning = require(package:WaitForChild("Config")).Prototype
local Rules = require(package:WaitForChild("HuntRules"))
local Catalog=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
local Crash=require(script.Parent:WaitForChild("CrashEffect"))
local dust={}
local contexts=setmetatable({},{__mode="k"})
local function clearHerdPath(from,to,root)
 local world=root:FindFirstAncestor("RodeoPrototype") or root:FindFirstAncestorWhichIsA("Folder")
 if world and world.Name=="Monsters" then world=world.Parent end
 local obstacles=world and world:FindFirstChild("Obstacles")
 if not obstacles then return true end
 for _,rock in ipairs(obstacles:GetChildren()) do
  if not rock:IsA("BasePart") or rock:GetAttribute("Broken") then continue end
  local p,s=rock.Position,rock.Size+root.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0.2) then return false end
 end
 return true
end
local function remember(model, existing)
	local root = model.PrimaryPart
 local speciesId=model:GetAttribute("MonsterId") or "MeadowMouse"
 local referenceTemplate=package:WaitForChild(Catalog.visual(speciesId,model:GetAttribute("Stars") or 1))
 local referenceRoot=assert(referenceTemplate.PrimaryPart,"몬스터 템플릿 PrimaryPart 없음")
	if not root then return nil end
	local pose = existing or {frame = root.CFrame, sample = root.CFrame, received = nil, tracked={}, restByPart={}}
 if existing and not pose.dirty then return pose end
 if not pose.watch then pose.watch=model.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then pose.dirty=true end end) end
 pose.dirty=false
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root and not pose.tracked[part] then
   local restFrame
   if part:GetAttribute("ApprovedRest") then
    -- Canonical mesh coordinates survive root movement during async installation.
    restFrame=part:GetAttribute("ApprovedRest")
   elseif model:GetAttribute("ImportedA") then
    -- Imported meshes already carry their correct per-model offsets; many are
    -- color-batched nodes whose names do not exist in the old part template.
    restFrame=root.CFrame:ToObjectSpace(part.CFrame)
   else
    local reference=referenceTemplate:FindFirstChild(part.Name,true)
    if not reference or not reference:IsA("BasePart") then
     part.LocalTransparencyModifier=1 pose.dirty=true continue
    end
    restFrame=referenceRoot.CFrame:ToObjectSpace(reference.CFrame)
   end
   part.LocalTransparencyModifier=0
			local side = string.sub(part.Name,1,4)=="Left" and "Left" or string.sub(part.Name,1,5)=="Right" and "Right" or nil
			local movingLeg = side and (string.find(part.Name,"Leg",1,true) or string.find(part.Name,"Paw",1,true) or string.find(part.Name,"Claw",1,true) or string.find(part.Name,"HoofLine",1,true))
			local leg = movingLeg and (string.find(part.Name,"Front",1,true) and "Front" or "Back") or nil
			if not leg then side=nil end
			pose.tracked[part]=true
   local entry={part=part,rest=restFrame,side=side,leg=leg}
   pose.restByPart[part]=restFrame
   table.insert(pose,entry)
		end
	end
	poses[model] = pose
	return pose
end

function RideAnimator.update(monsters, clock, cameraPosition, dt, selected)
 local context=contexts[monsters]
 if not context then context={poses={},visibility={},warnings={},dust={}} contexts[monsters]=context end
 poses,visibility,warnings,dust=context.poses,context.visibility,context.warnings,context.dust
 dt = dt or 1/60
 for i=#dust,1,-1 do
  local puff=dust[i] local age=clock-puff.started
  if age>=0.6 then puff.part:Destroy() table.remove(dust,i)
  else puff.part.Transparency=0.45+age/0.6*0.55 puff.part.Size=Vector3.one*(0.75+age*1.5) puff.part.Position+=Vector3.new(0,dt*0.7,0) end
 end
 local displayed = {}
 for model in pairs(visibility) do if not model:IsDescendantOf(monsters) then visibility[model]=nil end end
	for model, pose in pairs(poses) do
		if not model:IsDescendantOf(monsters) then poses[model] = nil end
	end
	for model, warning in pairs(warnings) do
		if not model:IsDescendantOf(monsters) then warning:Destroy() warnings[model] = nil end
	end
	if monsters.Name=="RodeoLobby" then
  local airport=monsters:FindFirstChild("Airport")
  local ship=airport and airport:FindFirstChild("Airship")
  if ship then
   context.airshipFrames=context.airshipFrames or {}
   for _,part in ipairs(ship:GetDescendants()) do
    if part:IsA("BasePart") and (part.Name=="SeaWingRoot" or part.Name=="SeaWingFeather") then
     local base=context.airshipFrames[part] or part.CFrame context.airshipFrames[part]=base
     local side=base.Position.X<6000 and -1 or 1
     local pivot=CFrame.new(6000+side*22,47,-9)
     local beat=math.sin(clock*1.15+1.2)*.21
     part.CFrame=pivot*CFrame.Angles(0,0,-side*beat)*pivot:Inverse()*base
    end
   end
  end
 end
 local outlineCount=0
	for _, model in ipairs(monsters.Name=="RodeoLobby" and monsters:GetDescendants() or monsters:GetChildren()) do
  if not model:IsA("Model") then continue end
  if not model:GetAttribute("MonsterId") or model:GetAttribute("NativeMeshyAirship") then continue end
		local root = model.PrimaryPart
		if not root then continue end
  if model:GetAttribute("KnockedAway") then
   Crash.knock(model,clock)
   for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=1 end end
   continue
  end
  local ownCompanion=model:GetAttribute("BagItemId") and model:GetAttribute("OwnerUserId")==game.Players.LocalPlayer.UserId
  local nameplate = root:FindFirstChild("Nameplate")
  if nameplate then nameplate.Enabled = false end
		if cameraPosition then
   local hidden=not ownCompanion and ((root.Position-cameraPosition).Magnitude>220 or (selected and not model:GetAttribute("Occupied") and not selected[model]))
   local record=visibility[model]
   if not record then
    record={} visibility[model]=record
    record.connection=model.DescendantAdded:Connect(function(part)
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=record.hidden and 1 or 0 end
    end)
   end
   if record.hidden~=hidden then
    record.hidden=hidden
    if not hidden then record.revealed=clock end
    for _,part in ipairs(model:GetChildren()) do
     if part:IsA("BasePart") and part~=root then part.LocalTransparencyModifier=hidden and 1 or 0 end
    end
   end
   if hidden then
    local outline=model:FindFirstChild("LocalCreatureOutline") if outline then outline:Destroy() end
    continue
   end
  end
		Mesh.materialize(model)
  local outline=model:FindFirstChild("LocalCreatureOutline")
  if outlineCount<20 then
   if not outline then
    outline=Instance.new("Highlight") outline.Name="LocalCreatureOutline" outline.Adornee=model
    outline.FillTransparency=1 outline.OutlineTransparency=.05
    outline.OutlineColor=Color3.fromRGB(35,49,68) outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Parent=model
   end
   outline.Enabled=true outlineCount+=1
  elseif outline then outline:Destroy() end
  if not Mesh.failed and not model:GetAttribute("MeshDecorated") then task.spawn(Mesh.decorate,model) end
  local running = model:GetAttribute("Running") == true
		local pose = poses[model]
		if not pose and not running and not model:GetAttribute("BagItemId") then continue end
		pose = remember(model,pose) -- Include late replicated body parts on every frame.
  if pose.sample ~= root.CFrame or not pose.received then
   pose.sample, pose.received = root.CFrame, clock
  end
  local elapsed = math.clamp(clock-pose.received,0,0.08)
  local speed = model:GetAttribute("Occupied") and Rules.rideSpeed(clock,model:GetAttribute("DashUntil"),(model:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond),tuning.SwitchDashMultiplier) or (model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond)
  if model:GetAttribute("InitialLanding") then speed=0 end
  local steer = model:GetAttribute("Steering") or 0
  local velocity=Vector3.new(steer*tuning.SidewaysStudsPerSecond,0,-speed)
  if not model:GetAttribute("Occupied") then velocity=model:GetAttribute("HerdVelocity") or velocity end
  local target = pose.sample + velocity*(running and elapsed or 0)
  if not model:GetAttribute("Occupied") and not clearHerdPath(pose.sample.Position,target.Position,root) then target=pose.sample end
  if (target.Position-pose.frame.Position).Magnitude>30 or not running then
   pose.frame = target
  else
   local blended=pose.frame:Lerp(target,1-math.exp(-22*dt))
   if not model:GetAttribute("Occupied") and not clearHerdPath(pose.frame.Position,blended.Position,root) then blended=pose.sample end
   pose.frame = blended
  end

		local scale=Catalog.scale(model:GetAttribute("Stars") or 1)
		local phase = (clock - (model:GetAttribute("RunStarted") or clock)) * math.pi * 7
		local angry = model:GetAttribute("Angry") == true
		local warningActive = model:GetAttribute("AngerWarning") == true or angry
		local warning = warnings[model]
		if warningActive and not warning then
			warning = Instance.new("BillboardGui")
			warning.Name, warning.Size, warning.StudsOffset = "AngerWarning", UDim2.fromOffset(60, 70), Vector3.new(0, 4.5, 0)
			warning.AlwaysOnTop, warning.Adornee, warning.Parent = true, root, root
			local label = Instance.new("TextLabel")
			label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1, 1), 1, "!"
			label.Font, label.TextSize = Enum.Font.GothamBlack, 58
			label.TextColor3, label.TextStrokeTransparency = Color3.fromRGB(255, 104, 55), 0
			label.Parent = warning
			warnings[model] = warning
		end
		if warning then
   warning.Enabled = warningActive
   local label=warning:FindFirstChildWhichIsA("TextLabel")
   if label then label.TextTransparency=0.15+math.max(0,math.sin(clock*12))*0.45 end
  end
		local _,_,pitch=Rules.buck(clock-(model:GetAttribute("AngerStarted") or clock),tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[model:GetAttribute("MonsterId") or "MeadowMouse"].TripleHop)
		local facingFrame,straightFacing=Mesh.huntFrame(model,pose.frame)
		local lean = not straightFacing and running and (model:GetAttribute("Steering") or 0) * -0.18 or 0
  local moving=running and (model:GetAttribute("BagItemId")~=nil or velocity.Magnitude>1)
  Mesh.animate(model,phase,moving,angry)
  local flying=model:GetAttribute("Flying")==true
  local bounce=moving and (flying and (.55+math.sin(phase*.5)*.22) or (1-math.cos(phase))*.22) or 0
  local gallopPitch=moving and math.sin(phase)*0.085 or 0
		local frame = facingFrame * CFrame.new(0,bounce,0)*CFrame.Angles(angry and not flying and pitch or gallopPitch, 0, lean)
    if monsters.Name~="RodeoLobby" and monsters.Name~="CafePets" and moving and not flying and not model:GetAttribute("Occupied") and clock-(pose.lastDust or clock-1)>0.18 and #dust<80 then
   pose.lastDust=clock
   local puff=Instance.new("Part") puff.Name="LocalHerdDust" puff.Anchored=true
   puff.CanCollide,puff.CanTouch,puff.CanQuery=false,false,false
   puff.Color=Color3.fromRGB(239,220,176) puff.Size=Vector3.one*0.75 puff.Transparency=0.45
   puff.Position=Vector3.new(frame.X+math.sin(phase)*0.9,0.2,frame.Z+1.6)
   puff.Parent=workspace table.insert(dust,{part=puff,started=clock})
  end
  displayed[model] = frame
		for _, entry in ipairs(pose) do
			if not entry.part.Parent then continue end
			local localFrame = entry.rest
			if moving and flying and entry.part.Name:find("Wing",1,true) then
    local side=entry.part.Name:find("Left",1,true) and -1 or 1
    local pivot=CFrame.new(side*.8*scale,.3*scale,.15*scale)
    localFrame=pivot*CFrame.Angles(0,0,side*math.sin(phase*.7)*(angry and .85 or .55))*pivot:Inverse()*localFrame
   elseif moving and entry.side then
				local opposite = (entry.side == "Left") ~= (entry.leg == "Front")
				local swing = math.sin(phase + (opposite and math.pi or 0)) * 0.85
				local legPart=model:FindFirstChild(entry.side..entry.leg.."Leg")
			local legRest=legPart and pose.restByPart[legPart]
    local joint=CFrame.new(legRest and (legRest.Position+Vector3.new(0,legPart.Size.Y*.5,0)) or entry.rest.Position)
				localFrame = CFrame.new(0,math.max(0,math.sin(phase + (opposite and math.pi or 0)))*0.22,0) * joint * CFrame.Angles(swing, 0, 0) * joint:Inverse() * entry.rest
			end
   if running and entry.part.Name:find("Ear") then
    local sign=entry.part.Name:find("Left") and -1 or 1
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(sign*0.87*scale,1.3*scale,-1.21*scale)
    localFrame=pivot*CFrame.Angles(math.sin(phase)*0.12,0,sign*math.sin(phase)*0.1)*pivot:Inverse()*localFrame
   elseif running and entry.part.Name:find("Tail") then
    local pivot=entry.part:GetAttribute("ApprovedPivot") and CFrame.new(entry.part:GetAttribute("ApprovedPivot")) or CFrame.new(0,-0.1*scale,1.7*scale)
    localFrame=pivot*CFrame.Angles(0,math.sin(phase*0.65)*0.3,0)*pivot:Inverse()*localFrame
   end
			entry.part.CFrame = frame * localFrame
   local shown=visibility[model]
   if shown and not shown.hidden then entry.part.LocalTransparencyModifier=ownCompanion and 0 or math.clamp(1-(clock-(shown.revealed or clock-.3))/.25,0,1) end
		end
		-- Keep cached canonical poses while resting; late parts still align.
	end
 return displayed
end

return RideAnimator
]========]},
{name="RocketDeparture",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[local Players=game:GetService("Players")
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
local title=make("TextLabel",{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-80,0,40),Text="행성 선택",TextXAlignment=Enum.TextXAlignment.Left,TextSize=24,TextColor3=Color3.fromRGB(220,249,243),Font=Enum.Font.GothamBold,BackgroundTransparency=1},panel)
local close=make("TextButton",{Position=UDim2.new(1,-60,0,8),Size=UDim2.fromOffset(48,48),Text="×",TextSize=30,BackgroundColor3=Color3.fromRGB(35,65,78),TextColor3=Color3.new(1,1,1)},panel)
local hint=make("TextLabel",{Position=UDim2.fromOffset(16,58),Size=UDim2.new(1,-32,0,48),Text="",TextSize=16,TextWrapped=true,BackgroundTransparency=1,TextColor3=Color3.fromRGB(199,222,221)},panel)
local list=make("ScrollingFrame",{Position=UDim2.fromOffset(16,112),Size=UDim2.new(1,-32,1,-232),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=8,BackgroundTransparency=1,BorderSizePixel=0},panel)
local layout=make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},list)
local status=make("TextLabel",{Position=UDim2.new(0,16,1,-112),Size=UDim2.new(1,-32,0,48),Text="",TextWrapped=true,TextSize=16,BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,213,146)},panel)
local nextButton=make("TextButton",{Position=UDim2.new(0,16,1,-60),Size=UDim2.new(1,-32,0,48),Text="다음",TextSize=20,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(10,31,41),BackgroundColor3=Color3.fromRGB(92,216,182)},panel)
local function fit()
 local compact=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<430
 hint.Position=UDim2.fromOffset(16,58)
 hint.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 list.Position=UDim2.fromOffset(16,compact and 96 or 112)
 list.Size=UDim2.new(1,-32,1,compact and -188 or -232)
 status.Position=UDim2.new(0,16,1,compact and -88 or -112)
 status.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 nextButton.Position=UDim2.new(0,16,1,compact and -52 or -60)
 nextButton.Size=UDim2.new(1,-32,0,compact and 44 or 48)
end
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local messages={MenuExpired="선택 시간이 지났어요. 로켓에서 E를 다시 길게 눌러 주세요.",ApproachRocket="로켓 가까이에서 다시 시도해 주세요.",ModelPending="새 몬스터 모델을 연결할 준비 중이에요.",CoursePending="Green Star 사냥터 연결을 준비 중이에요.",MonsterBusy="교배 또는 거래 중인 몬스터는 탈 수 없어요.",NotOwned="가방이 변경됐어요. 로켓에서 다시 선택해 주세요.",LaunchFailed="사냥터 준비에 실패했어요. 다시 시도해 주세요."}
local menu,step,selected,busy=nil,1,nil,false
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
 title.Text="출발할 몬스터 선택" hint.Text="Green Star · 숲 1,000m\n내 가방의 몬스터를 타고 시작해요."
 nextButton.Text="탑승하고 출발" status.Text="몬스터 한 마리를 선택해 주세요."
 if #menu.items==0 then status.Text="보유 몬스터가 없어요. 무료 1성 모스랫은 새 모델 연결 후 지급됩니다." end
 for index,item in ipairs(menu.items) do
  local id=item.monsterId
  local name=L.text(id,player.LocaleId)
  local b
  b=button(name.." · "..tostring(item.stars).."성"..(item.ready and "" or " · 준비 중"),index,function()
   if busy then return end
   if not item.ready then status.Text=messages[item.reason] or "현재 선택할 수 없어요." return end
   selected=item.id status.Text=name.."을(를) 타고 출발해요."
   for _,row in ipairs(rows) do row.BackgroundColor3=Color3.fromRGB(35,69,82) end
   b.BackgroundColor3=Color3.fromRGB(47,125,112)
  end)
 end
end
close.Activated:Connect(function() hide(true) end)
nextButton.Activated:Connect(function()
 if not menu or busy then return end
 if step==1 then
  if not selected then status.Text="Green Star를 선택해 주세요." return end
  chooseMonster()
 elseif selected then
  busy=true status.Text="사냥터를 준비하고 있어요…"
  local launchMenu=menu
  remote:FireServer("LaunchSelection",{token=menu.token,planet="GreenStar",itemId=selected})
  task.delay(8,function()
   if gui.Enabled and menu==launchMenu and busy then busy=false status.Text="응답을 기다리고 있어요. 다시 시도하거나 창을 닫아 주세요." end
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
  title.Text="행성 선택" hint.Text="로켓으로 떠날 행성을 선택해 주세요."
  nextButton.Text="다음 · 몬스터 선택" status.Text=""
  local b
  b=button("Green Star\n숲 · 1,000m",1,function() selected="GreenStar" b.BackgroundColor3=Color3.fromRGB(47,125,112) status.Text="Green Star를 선택했어요." end)
  b.Size=UDim2.new(1,-8,0,160) b.Text=""
  make("ImageLabel",{Name="GreenStarArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.02,.04),Size=UDim2.fromScale(.40,.92),ScaleType=Enum.ScaleType.Fit},b)
  make("TextLabel",{Name="PlanetLabel",Text=L.text("Green Star\n숲 · 1,000m",player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromScale(.44,.1),Size=UDim2.fromScale(.54,.8),TextScaled=true,TextWrapped=true,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1)},b)
 elseif action=="DepartureResult" and gui.Enabled then
  busy=false
  if data.ok then hide(false) else status.Text=messages[data.reason] or "출발할 수 없어요. 다시 선택해 주세요." end
 elseif action=="State" and data.area=="Hunt" then hide(false) end
end)
]========],after=[========[local Players=game:GetService("Players")
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
]========]},
{name="SocialUI",parent=game.StarterPlayer.StarterPlayerScripts,before=[========[local S={}
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local Portrait=require(script.Parent.MonsterPortrait)
function S.new(gui,remote,bag,journal)
 local self={}
 local function make(class,props,parent)
  local n=Instance.new(class) for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
 end
 local window=make("Frame",{Name="SocialWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.9,.82),BackgroundColor3=Color3.fromRGB(239,227,203),ZIndex=60},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1050,720)},window) make("UICorner",{CornerRadius=UDim.new(0,20)},window)
 local title=make("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-80,0,40),TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(48,77,55),ZIndex=61},window)
 local function button(text,x,y,w,parent,fn)
  local b=make("TextButton",{Text=text,Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,-10,0,38),BackgroundColor3=Color3.fromRGB(78,116,86),TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,ZIndex=64},parent)
  make("UICorner",{CornerRadius=UDim.new(0,8)},b) b.Activated:Connect(fn) return b
 end
 local content=make("ScrollingFrame",{Position=UDim2.fromOffset(18,110),Size=UDim2.new(1,-36,1,-178),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=6,ZIndex=61},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,205),CellPadding=UDim2.fromOffset(12,12)},content)
 local message=make("TextLabel",{Text="",Visible=false,AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,.08),Size=UDim2.new(.84,0,0,70),BackgroundColor3=Color3.fromRGB(44,70,52),TextColor3=Color3.fromRGB(255,242,204),TextSize=18,TextWrapped=true,ZIndex=100},gui)
 local noticeVersion=0
 function self.message(text) noticeVersion+=1 local v=noticeVersion message.Text=text message.Visible=true task.delay(5,function() if v==noticeVersion then message.Visible=false end end) end
 local controls=make("Frame",{Position=UDim2.fromOffset(18,63),Size=UDim2.new(1,-36,0,40),BackgroundTransparency=1,ZIndex=62},window)
 local footer=make("Frame",{Position=UDim2.new(0,18,1,-56),Size=UDim2.new(1,-36,0,42),BackgroundTransparency=1,ZIndex=62},window)
 local mode,selected,other,trade=nil,{},nil,nil
 local function clear(parent) for _,n in ipairs(parent:GetChildren()) do if not n:IsA("UIGridLayout") then n:Destroy() end end end
 local function open(name)
  if self.onOpen then self.onOpen() end
  bag.close() journal.close() window.Visible=true title.Text=name clear(content) clear(controls) clear(footer)
 end
 function self.close() window.Visible=false end
 local function ids() local out={} for id in pairs(selected) do table.insert(out,id) end table.sort(out) return out end
 local function card(m,fn)
  local frame=make("Frame",{BackgroundColor3=selected[m.id] and Color3.fromRGB(183,208,155) or Color3.fromRGB(251,243,224),Size=UDim2.fromOffset(170,205),ZIndex=62},content)
  make("UICorner",{CornerRadius=UDim.new(0,12)},frame)
  local v=make("ViewportFrame",{Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ZIndex=63},frame)
  Portrait.fill(v,m.monsterId,m.stars,false)
  make("TextLabel",{Text=(mode=="Trade" and not fn and "상대 · " or "")..L.text(m.monsterId,player.LocaleId).." · "..m.stars.."★",Size=UDim2.new(1,0,0,24),Position=UDim2.fromOffset(0,139),BackgroundTransparency=1,TextSize=15,ZIndex=63},frame)
  if fn then button((selected[m.id] and "✓ " or "")..(m.sex=="Male" and "♂ " or m.sex=="Female" and "♀ " or "").."선택",0,166,1,frame,fn) end
 end
 local renderSelection
 renderSelection=function()
  open(mode=="Breed" and "교배 · 최대 4팀 / 8마리" or "프로필 지정 · 최대 5마리")
  button(mode=="Breed" and "암컷 + 수컷 · 시작 준비 중" or (#ids().." / 5 선택"),0,0,1,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil elseif #ids()<(mode=="Breed" and 2 or 5) and not m.breedingTeam then selected[m.id]=true end renderSelection()
  end) end
  button(mode=="Breed" and "준비 중 · 선택 조건 확인" or "프로필 저장",.5,0,.5,footer,function() remote:FireServer(mode=="Breed" and "Breed" or "ProfileSave",ids()) end)
 end
 function self.breed() mode="Breed" selected={} renderSelection() end
 function self.edit() mode="Profile" selected={} for _,id in ipairs(self.profile or {}) do selected[id]=true end renderSelection() end
 local close=button("×",.93,10,.07,window,function() window.Visible=false if trade then remote:FireServer("TradeDecline") end end)
 close.Size=UDim2.fromOffset(38,38)
 local function showTrade(data)
  trade=data mode="Trade" open("거래 · "..data.name)
  selected={} for _,id in ipairs(data.mine.ids) do selected[id]=true end
  local coins=make("TextBox",{Text=tostring(data.mine.coins),PlaceholderText="보낼 코인",ClearTextOnFocus=false,Size=UDim2.new(.28,0,0,36),TextSize=18,ZIndex=64},controls)
  button("제안 갱신",.3,0,.23,controls,function() remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text)}) end)
  button("상대: "..data.theirs.coins.."코인 / "..#data.theirs.ids.."마리",.54,0,.46,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil else selected[m.id]=true end
   remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text) or 0})
  end) end
  for _,m in ipairs(data.theirs.monsters or {}) do card(m,nil) end
  button(data.accepted and "취소" or "거래 거절",0,0,.3,footer,function() remote:FireServer("TradeDecline") window.Visible=false end)
  if not data.accepted then button("거래 수락",.5,0,.5,footer,function() remote:FireServer("TradeAccept") end)
  elseif data.ready and data.otherReady then button(data.final and "상대 최종 확인 대기" or "최종 확인 · 교환 실행",.5,0,.5,footer,function() remote:FireServer("TradeConfirm",data.revision) end)
  else button(data.ready and "상대 확인 대기" or "제안 확인",.5,0,.5,footer,function() remote:FireServer("TradeReady",data.revision) end) end
 end
 function self.event(kind,data)
  if kind=="SocialMessage" then self.message(data)
  elseif kind=="Profile" then
   mode="View" other=data.userId open(data.name.."  @"..data.username)
   local avatar=make("ImageLabel",{BackgroundTransparency=1,Size=UDim2.fromOffset(170,205),ZIndex=63},content)
   task.spawn(function() local ok,url=pcall(function() return Players:GetUserThumbnailAsync(data.userId,Enum.ThumbnailType.AvatarThumbnail,Enum.ThumbnailSize.Size420x420) end) if ok and avatar.Parent then avatar.Image=url end end)
   for _,m in ipairs(data.monsters) do card(m,nil) end
   button("도감 보기",0,0,.5,footer,function() remote:FireServer("OtherJournal",other) end)
   button("거래 요청",.5,0,.5,footer,function() remote:FireServer("TradeRequest",other) end)
  elseif kind=="OtherJournal" then window.Visible=false journal.viewOther(data)
  elseif kind=="Trade" then showTrade(data)
  elseif kind=="TradeInvitation" then self.message(data.name.."님이 거래를 요청했습니다.")
  elseif kind=="TradeClosed" then trade=nil if mode=="Trade" then window.Visible=false end
  elseif kind=="Eggs" then
   mode="Eggs" open("알 관리 · 부화소 "..data.pen.." · 한 칸에 알 1개")
   if #data.eggs==0 then self.message("아직 알이 없습니다. 교배 시간·결과 설정 후 이용할 수 있습니다.") end
   for _,egg in ipairs(data.eggs) do
    button("알 "..tostring(egg.id)..(egg.assignedPen and " · 배치됨" or " · 가방"),0,0,1,content,function() remote:FireServer(egg.assignedPen==data.pen and "RemoveEgg" or "PlaceEgg",{id=egg.id,pen=data.pen}) end)
   end
  end
 end
 local tStart
 UIS.InputBegan:Connect(function(input,processed) if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Cafe" then tStart=os.clock() end end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.T then tStart=nil end end)
 Run.RenderStepped:Connect(function() if tStart and os.clock()-tStart>=1 then tStart=nil self.edit() end end)
 local edit=button("T 길게 · 프로필 지정",.02,14,.24,gui,self.edit)
 function self.state(data) self.area=data.area self.profile=data.profile or self.profile edit.Visible=data.area=="Cafe" end
 edit.Visible=false bag.onBreed=self.breed
 return self
end
return S
]========],after=[========[local S={}
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local Portrait=require(script.Parent.MonsterPortrait)
function S.new(gui,remote,bag,journal)
 local self={}
 local function make(class,props,parent)
  local n=Instance.new(class) for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
 end
 local window=make("Frame",{Name="SocialWindow",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.9,.82),BackgroundColor3=Color3.fromRGB(239,227,203),ZIndex=60},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1050,720)},window) make("UICorner",{CornerRadius=UDim.new(0,20)},window)
 local title=make("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,10),Size=UDim2.new(1,-80,0,40),TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(48,77,55),ZIndex=61},window)
 local function button(text,x,y,w,parent,fn)
  local b=make("TextButton",{Text=text,Position=UDim2.new(x,0,0,y),Size=UDim2.new(w,-10,0,38),BackgroundColor3=Color3.fromRGB(78,116,86),TextColor3=Color3.new(1,1,1),TextSize=15,TextWrapped=true,ZIndex=64},parent)
  make("UICorner",{CornerRadius=UDim.new(0,8)},b) b.Activated:Connect(fn) return b
 end
 local content=make("ScrollingFrame",{Position=UDim2.fromOffset(18,110),Size=UDim2.new(1,-36,1,-178),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=6,ZIndex=61},window)
 make("UIGridLayout",{CellSize=UDim2.fromOffset(170,205),CellPadding=UDim2.fromOffset(12,12)},content)
 local message=make("TextLabel",{Text="",Visible=false,AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,.08),Size=UDim2.new(.84,0,0,70),BackgroundColor3=Color3.fromRGB(44,70,52),TextColor3=Color3.fromRGB(255,242,204),TextSize=18,TextWrapped=true,ZIndex=100},gui)
 local noticeVersion=0
 function self.message(text) noticeVersion+=1 local v=noticeVersion message.Text=text message.Visible=true task.delay(5,function() if v==noticeVersion then message.Visible=false end end) end
 local controls=make("Frame",{Position=UDim2.fromOffset(18,63),Size=UDim2.new(1,-36,0,40),BackgroundTransparency=1,ZIndex=62},window)
 local footer=make("Frame",{Position=UDim2.new(0,18,1,-56),Size=UDim2.new(1,-36,0,42),BackgroundTransparency=1,ZIndex=62},window)
 local mode,selected,other,trade=nil,{},nil,nil
 local function clear(parent) for _,n in ipairs(parent:GetChildren()) do if not n:IsA("UIGridLayout") then n:Destroy() end end end
 local function open(name)
  if self.onOpen then self.onOpen() end
  bag.close() journal.close() window.Visible=true title.Text=name clear(content) clear(controls) clear(footer)
 end
 function self.close() window.Visible=false end
 local function ids() local out={} for id in pairs(selected) do table.insert(out,id) end table.sort(out) return out end
 local function card(m,fn)
  local frame=make("Frame",{BackgroundColor3=selected[m.id] and Color3.fromRGB(183,208,155) or Color3.fromRGB(251,243,224),Size=UDim2.fromOffset(170,205),ZIndex=62},content)
  make("UICorner",{CornerRadius=UDim.new(0,12)},frame)
  local v=make("ViewportFrame",{Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ZIndex=63},frame)
  Portrait.fill(v,m.monsterId,m.stars,false)
  make("TextLabel",{Text=(mode=="Trade" and not fn and "Partner · " or "")..L.text(m.monsterId,"en-us").." · "..m.stars.."★",Size=UDim2.new(1,0,0,24),Position=UDim2.fromOffset(0,139),BackgroundTransparency=1,TextSize=15,ZIndex=63},frame)
  if fn then button((selected[m.id] and "✓ " or "")..(m.sex=="Male" and "♂ " or m.sex=="Female" and "♀ " or "").."Select",0,166,1,frame,fn) end
 end
 local renderSelection
 renderSelection=function()
  open(mode=="Breed" and "Breed · Up to 4 pairs / 8 monsters" or "Profile · Up to 5 monsters")
  button(mode=="Breed" and "Female + Male · Coming soon" or (#ids().." / 5 selected"),0,0,1,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil elseif #ids()<(mode=="Breed" and 2 or 5) and not m.breedingTeam then selected[m.id]=true end renderSelection()
  end) end
  button(mode=="Breed" and "Check pairing" or "Save profile",.5,0,.5,footer,function() remote:FireServer(mode=="Breed" and "Breed" or "ProfileSave",ids()) end)
 end
 function self.breed() mode="Breed" selected={} renderSelection() end
 function self.edit() mode="Profile" selected={} for _,id in ipairs(self.profile or {}) do selected[id]=true end renderSelection() end
 local close=button("×",.93,10,.07,window,function() window.Visible=false if trade then remote:FireServer("TradeDecline") end end)
 close.Size=UDim2.fromOffset(38,38)
 local function showTrade(data)
  trade=data mode="Trade" open("Trade · "..data.name)
  selected={} for _,id in ipairs(data.mine.ids) do selected[id]=true end
  local coins=make("TextBox",{Text=tostring(data.mine.coins),PlaceholderText="Coins to offer",ClearTextOnFocus=false,Size=UDim2.new(.28,0,0,36),TextSize=18,ZIndex=64},controls)
  button("Update offer",.3,0,.23,controls,function() remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text)}) end)
  button("Partner: "..data.theirs.coins.." coins / "..#data.theirs.ids.." monsters",.54,0,.46,controls,function() end)
  for _,m in ipairs(bag.items) do card(m,function()
   if selected[m.id] then selected[m.id]=nil else selected[m.id]=true end
   remote:FireServer("TradeOffer",{ids=ids(),coins=tonumber(coins.Text) or 0})
  end) end
  for _,m in ipairs(data.theirs.monsters or {}) do card(m,nil) end
  button(data.accepted and "Cancel" or "Decline trade",0,0,.3,footer,function() remote:FireServer("TradeDecline") window.Visible=false end)
  if not data.accepted then button("Accept trade",.5,0,.5,footer,function() remote:FireServer("TradeAccept") end)
  elseif data.ready and data.otherReady then button(data.final and "Waiting for final confirmation" or "Confirm exchange",.5,0,.5,footer,function() remote:FireServer("TradeConfirm",data.revision) end)
  else button(data.ready and "Waiting for partner" or "Confirm offer",.5,0,.5,footer,function() remote:FireServer("TradeReady",data.revision) end) end
 end
 function self.event(kind,data)
  if kind=="SocialMessage" then self.message(data)
  elseif kind=="Profile" then
   mode="View" other=data.userId open(data.name.."  @"..data.username)
   local avatar=make("ImageLabel",{BackgroundTransparency=1,Size=UDim2.fromOffset(170,205),ZIndex=63},content)
   task.spawn(function() local ok,url=pcall(function() return Players:GetUserThumbnailAsync(data.userId,Enum.ThumbnailType.AvatarThumbnail,Enum.ThumbnailSize.Size420x420) end) if ok and avatar.Parent then avatar.Image=url end end)
   for _,m in ipairs(data.monsters) do card(m,nil) end
   button("View index",0,0,.5,footer,function() remote:FireServer("OtherJournal",other) end)
   button("Request trade",.5,0,.5,footer,function() remote:FireServer("TradeRequest",other) end)
  elseif kind=="OtherJournal" then window.Visible=false journal.viewOther(data)
  elseif kind=="Trade" then showTrade(data)
  elseif kind=="TradeInvitation" then self.message(data.name.." requested a trade.")
  elseif kind=="TradeClosed" then trade=nil if mode=="Trade" then window.Visible=false end
  elseif kind=="Eggs" then
   mode="Eggs" open("Eggs · Hatchery "..data.pen.." · One egg per slot")
   if #data.eggs==0 then self.message("No eggs yet. Breeding is coming soon.") end
   for _,egg in ipairs(data.eggs) do
    button("Egg "..tostring(egg.id)..(egg.assignedPen and " · Placed" or " · Bag"),0,0,1,content,function() remote:FireServer(egg.assignedPen==data.pen and "RemoveEgg" or "PlaceEgg",{id=egg.id,pen=data.pen}) end)
   end
  end
 end
 local tStart
 UIS.InputBegan:Connect(function(input,processed) if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Cafe" then tStart=os.clock() end end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.T then tStart=nil end end)
 Run.RenderStepped:Connect(function() if tStart and os.clock()-tStart>=1 then tStart=nil self.edit() end end)
 local edit=button("Hold T · Edit profile",.02,14,.24,gui,self.edit)
 function self.state(data) self.area=data.area self.profile=data.profile or self.profile edit.Visible=data.area=="Cafe" end
 edit.Visible=false bag.onBreed=self.breed
 return self
end
return S
]========]},
{name="CaptureServer",parent=game.ServerScriptService,before=[========[local Players=game:GetService("Players")
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
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
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
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
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
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
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
  elseif not states[player] then remote:FireClient(player,"SocialMessage","알 배치는 내 부화실 안에서 이용해주세요.") end
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
    if not ok then states[player]=state player:SetAttribute("ReturningLobby",nil) warn("LOBBY_RESPAWN_FAILED: "..tostring(err)) send(player,"다시 로비로 돌아가기를 눌러 주세요.") return end
    character=player.Character
   end
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then root.Anchored=false root.AssemblyLinearVelocity=Vector3.zero character:PivotTo(Lobby.Spawn) end
   humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.PlatformStand=false humanoid.AutoRotate=true end
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(character)
   player:SetAttribute("ReturningLobby",nil)
   send(player,"로비로 돌아왔습니다.") sendBag(player)
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
]========],after=[========[local Players=game:GetService("Players")
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
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
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
]========]},
{name="LobbyCompanions",parent=game.ServerScriptService,before=[========[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
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
 function api.clear(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","내 부화실 안에서 소환해주세요.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  if not source or source:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","이 몬스터의 모델을 준비 중입니다.") return
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
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false}
  p:SetAttribute("SummonedId",id)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="교감"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  prompt.Style=Enum.ProximityPromptStyle.Custom
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<3.5 then return end
   last=os.clock()
   local at=workspace:GetServerTimeNow()
   model:SetAttribute("PetBondStarted",at) model:SetAttribute("PetBondUntil",at+3)
   P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=at})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    delta=delta.Unit*math.min(delta.Magnitude-6,32*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
    else
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
]========],after=[========[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
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
 function api.clear(p)
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
  if not source or source:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then
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
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="Bond"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  prompt.Style=Enum.ProximityPromptStyle.Custom
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<3.5 then return end
   last=os.clock()
   local at=workspace:GetServerTimeNow()
   model:SetAttribute("PetBondStarted",at) model:SetAttribute("PetBondUntil",at+3)
   P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=at})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
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
]========]},
{name="LobbyWorld",parent=game.ServerScriptService,before=[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
require(script.Parent.LobbyAppearance).ensure(map)
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,14,-72)
local departureRadius=38
local function centerDeparture()
 local rocket=map.Airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then
  local box=rocket:GetBoundingBox()
  Lobby.Departure.Position=Vector3.new(box.Position.X,Lobby.Departure.Position.Y,box.Position.Z)
 end
 Lobby.Departure.Transparency=1
 Lobby.Departure.CanCollide=false
end
centerDeparture()
function Lobby.prepareCharacter(character)
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",10)
 if root then
  root.Anchored=true
  character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  local owner=game:GetService("Players"):GetPlayerFromCharacter(character)
  if owner and workspace.StreamingEnabled then pcall(function() owner:RequestStreamAroundAsync(Lobby.Spawn.Position,3) end) end
 end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed humanoid.PlatformStand=false humanoid.AutoRotate=true end
 if root then
  task.delay(.35,function()
   if character.Parent and root.Parent then
    character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
    root.Anchored=false
    if humanoid and humanoid.Health>0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
   end
  end)
 end
 local helmet=character:FindFirstChild("AstronautHelmet")
 if helmet then helmet:Destroy() end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
end
local function label(index,name)
 local board=plots["Plot_"..index]:FindFirstChild("OwnerBoard")
 if not board then return end
 for _,gui in ipairs(board:GetChildren()) do
  if gui:IsA("SurfaceGui") then gui.Text.Text=name end
 end
end
for index=1,8 do label(index,"") end
function Lobby.assign(player)
 if owned[player] then return owned[player] end
 for index=1,8 do
  if not occupants[index] then
   occupants[index]=player owned[player]=index
   plots["Plot_"..index]:SetAttribute("OwnerUserId",player.UserId)
   player:SetAttribute("LobbySlot",index)
   label(index,player.Name)
   return index
  end
 end
 return nil
end
function Lobby.release(player)
 local index=owned[player]
 if not index then return end
 occupants[index]=nil owned[player]=nil
 player:SetAttribute("LobbySlot",nil)
 plots["Plot_"..index]:SetAttribute("OwnerUserId",nil)
 for _,pen in ipairs(plots["Plot_"..index].Pens:GetChildren()) do
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=departureRadius
end
function Lobby.getPen(player,index)
 if type(index)~="number" or index%1~=0 or index<1 or index>4 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canSummon(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and math.abs(root.Position.X-6000)<=256 and math.abs(root.Position.Z)<=256
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=departureRadius prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========],after=[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
require(script.Parent.LobbyAppearance).ensure(map)
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,14,-72)
local departureRadius=38
local function centerDeparture()
 local rocket=map.Airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then
  local box=rocket:GetBoundingBox()
  Lobby.Departure.Position=Vector3.new(box.Position.X,Lobby.Departure.Position.Y,box.Position.Z)
 end
 Lobby.Departure.Transparency=1
 Lobby.Departure.CanCollide=false
end
centerDeparture()
function Lobby.prepareCharacter(character)
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",10)
 if root then
  root.Anchored=true
  character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  local owner=game:GetService("Players"):GetPlayerFromCharacter(character)
  if owner and workspace.StreamingEnabled then pcall(function() owner:RequestStreamAroundAsync(Lobby.Spawn.Position,3) end) end
 end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed humanoid.PlatformStand=false humanoid.AutoRotate=true end
 if root then
  task.delay(.35,function()
   if character.Parent and root.Parent then
    character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
    root.Anchored=false
    if humanoid and humanoid.Health>0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
   end
  end)
 end
 local helmet=character:FindFirstChild("AstronautHelmet")
 if helmet then helmet:Destroy() end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
end
local function label(index,name)
 local board=plots["Plot_"..index]:FindFirstChild("OwnerBoard")
 if not board then return end
 for _,gui in ipairs(board:GetChildren()) do
  if gui:IsA("SurfaceGui") then gui.Text.Text=name end
 end
end
for index=1,8 do label(index,"") end
function Lobby.assign(player)
 if owned[player] then return owned[player] end
 for index=1,8 do
  if not occupants[index] then
   occupants[index]=player owned[player]=index
   plots["Plot_"..index]:SetAttribute("OwnerUserId",player.UserId)
   player:SetAttribute("LobbySlot",index)
   label(index,player.Name)
   return index
  end
 end
 return nil
end
function Lobby.release(player)
 local index=owned[player]
 if not index then return end
 occupants[index]=nil owned[player]=nil
 player:SetAttribute("LobbySlot",nil)
 plots["Plot_"..index]:SetAttribute("OwnerUserId",nil)
 for _,pen in ipairs(plots["Plot_"..index].Pens:GetChildren()) do
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=departureRadius
end
function Lobby.getPen(player,index)
 if type(index)~="number" or index%1~=0 or index<1 or index>4 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canSummon(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and math.abs(root.Position.X-6000)<=256 and math.abs(root.Position.Z)<=256
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canSummon(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="Manage eggs" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="Planets" prompt.ObjectText="Rocket"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=departureRadius prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========]},
{name="SocialService",parent=game.ServerScriptService,before=[========[local S={}
local Players=game:GetService("Players")
local P=game.ReplicatedStorage.RodeoFantasy
local R=require(P.SocialRules)
local Store=require(script.Parent.InventoryStore)
local Progress=require(script.Parent.ProgressService)
local Catalog=require(P.MonsterCatalog)
local sessions={}
function S.trading(player) local t=sessions[player] return t and t.accepted end
local function close(t)
 if t.committing then return end
 for _,p in ipairs(t.users) do sessions[p]=nil P.CaptureRemote:FireClient(p,"TradeClosed") end
end
function S.start(bags,canAct,sendBag,beforeTrade)
 local remote=P.CaptureRemote
 local function near(a,b)
  local x=a.Character and a.Character:FindFirstChild("HumanoidRootPart")
  local y=b.Character and b.Character:FindFirstChild("HumanoidRootPart")
  return x and y and (x.Position-y.Position).Magnitude<=16
 end
 local function packet(t,p)
  local q=t.users[1]==p and t.users[2] or t.users[1]
  local theirs=table.clone(t.offers[q]) theirs.monsters={}
  for _,id in ipairs(theirs.ids) do local m=R.find(bags[q],id) if m then table.insert(theirs.monsters,{monsterId=m.monsterId,stars=m.stars}) end end
  return {other=q.UserId,name=q.DisplayName,accepted=t.accepted,mine=t.offers[p],theirs=theirs,ready=t.ready[p],otherReady=t.ready[q],final=t.final[p],revision=t.revision}
 end
 local function update(t) for _,p in ipairs(t.users) do remote:FireClient(p,"Trade",packet(t,p)) end end
 local stamps={}
 remote.OnServerEvent:Connect(function(player,action,value)
  if type(action)~="string" or not canAct(player) or Store.busy(player) then return end
  local allowed={Breed=true,ProfileSave=true,Profile=true,OtherJournal=true,TradeRequest=true,TradeAccept=true,TradeDecline=true,TradeOffer=true,TradeReady=true,TradeConfirm=true}
  if not allowed[action] then return end
  local clock=os.clock() local key=tostring(player.UserId)..action
  if clock-(stamps[key] or 0)<.25 then return end stamps[key]=clock
  local bag=bags[player] if not bag then return end
  if action=="Breed" then
   local _,message=R.pair(bag,value) remote:FireClient(player,"SocialMessage",message) return
  end
  if action=="ProfileSave" then
   local ids=R.profile(bag,value) if ids and not S.trading(player) then bag.profile=ids remote:FireClient(player,"SocialMessage","프로필을 저장했습니다.") end return
  end
  if player:GetAttribute("Area")~="Cafe" then return end
  if action=="Profile" or action=="OtherJournal" or action=="TradeRequest" then
   if type(value)~="number" or value~=value or value%1~=0 then return end
   local other=Players:GetPlayerByUserId(value)
   if not other or other==player or not bags[other] or not near(player,other) then return end
   if action=="Profile" then
    local featured={} for _,id in ipairs(bags[other].profile or {}) do local m=R.find(bags[other],id) if m then table.insert(featured,{monsterId=m.monsterId,stars=m.stars}) end end
    remote:FireClient(player,"Profile",{userId=other.UserId,name=other.DisplayName,username=other.Name,monsters=featured})
   elseif action=="OtherJournal" then remote:FireClient(player,"OtherJournal",Progress.snapshot(other,true))
   elseif not sessions[player] and not sessions[other] and not Store.busy(other) then
    local t={users={player,other},offers={[player]={ids={},coins=0},[other]={ids={},coins=0}},ready={},final={},revision=1,expires=clock+30}
    sessions[player]=t sessions[other]=t update(t)
    remote:FireClient(other,"TradeInvitation",{userId=player.UserId,name=player.DisplayName})
   end return
  end
  local t=sessions[player] if not t or t.committing then return end
  if clock>t.expires then close(t) return end
  local other=t.users[1]==player and t.users[2] or t.users[1]
  if action=="TradeDecline" then close(t) return end
  if action=="TradeAccept" and t.users[2]==player and near(player,other) then t.accepted=true t.expires=clock+180 update(t) return end
  if not t.accepted or not near(player,other) or Store.busy(other) then return end
  if action=="TradeOffer" then
   local offer=R.offer(bag,value)
   if offer then t.offers[player]={ids=offer.ids,coins=offer.coins} t.ready={} t.final={} t.revision+=1 t.expires=clock+180 update(t) end
  elseif action=="TradeReady" and value==t.revision then t.ready[player]=true update(t)
  elseif action=="TradeConfirm" and value==t.revision and t.ready[player] and t.ready[other] then
   t.final[player]=true update(t)
   if not t.final[other] then return end
   local a,b=t.users[1],t.users[2]
   local after,message=R.exchange(bags[a],bags[b],t.offers[a],t.offers[b])
   if not after then remote:FireClient(player,"SocialMessage",message) t.ready={} t.final={} update(t) return end
   t.committing=true
   if beforeTrade then beforeTrade(a) beforeTrade(b) end
   local ok=Store.trade(a,b,after)
   t.committing=false close(t)
   if ok then
    for _,p in ipairs({a,b}) do
     for _,m in ipairs(bags[p].monsters) do if Catalog[m.monsterId] then Progress.discover(p,m.monsterId,m.stars) end end
     sendBag(p) remote:FireClient(p,"SocialMessage","거래가 완료되었습니다.")
    end
   end
  end
 end)
 Players.PlayerRemoving:Connect(function(p) local t=sessions[p] if t and not t.committing then close(t) end end)
 task.spawn(function() while task.wait(2) do for _,t in pairs(sessions) do if not t.committing and (os.clock()>t.expires or not near(t.users[1],t.users[2])) then close(t) end end end end)
end
return S
]========],after=[========[local S={}
local Players=game:GetService("Players")
local P=game.ReplicatedStorage.RodeoFantasy
local R=require(P.SocialRules)
local Store=require(script.Parent.InventoryStore)
local Progress=require(script.Parent.ProgressService)
local Catalog=require(P.MonsterCatalog)
local sessions={}
function S.trading(player) local t=sessions[player] return t and t.accepted end
local function close(t)
 if t.committing then return end
 for _,p in ipairs(t.users) do sessions[p]=nil P.CaptureRemote:FireClient(p,"TradeClosed") end
end
function S.start(bags,canAct,sendBag,beforeTrade)
 local remote=P.CaptureRemote
 local function near(a,b)
  local x=a.Character and a.Character:FindFirstChild("HumanoidRootPart")
  local y=b.Character and b.Character:FindFirstChild("HumanoidRootPart")
  return x and y and (x.Position-y.Position).Magnitude<=16
 end
 local function packet(t,p)
  local q=t.users[1]==p and t.users[2] or t.users[1]
  local theirs=table.clone(t.offers[q]) theirs.monsters={}
  for _,id in ipairs(theirs.ids) do local m=R.find(bags[q],id) if m then table.insert(theirs.monsters,{monsterId=m.monsterId,stars=m.stars}) end end
  return {other=q.UserId,name=q.DisplayName,accepted=t.accepted,mine=t.offers[p],theirs=theirs,ready=t.ready[p],otherReady=t.ready[q],final=t.final[p],revision=t.revision}
 end
 local function update(t) for _,p in ipairs(t.users) do remote:FireClient(p,"Trade",packet(t,p)) end end
 local stamps={}
 remote.OnServerEvent:Connect(function(player,action,value)
  if type(action)~="string" or not canAct(player) or Store.busy(player) then return end
  local allowed={Breed=true,ProfileSave=true,Profile=true,OtherJournal=true,TradeRequest=true,TradeAccept=true,TradeDecline=true,TradeOffer=true,TradeReady=true,TradeConfirm=true}
  if not allowed[action] then return end
  local clock=os.clock() local key=tostring(player.UserId)..action
  if clock-(stamps[key] or 0)<.25 then return end stamps[key]=clock
  local bag=bags[player] if not bag then return end
  if action=="Breed" then
   local _,message=R.pair(bag,value) remote:FireClient(player,"SocialMessage",message) return
  end
  if action=="ProfileSave" then
   local ids=R.profile(bag,value) if ids and not S.trading(player) then bag.profile=ids remote:FireClient(player,"SocialMessage","Profile saved.") end return
  end
  if player:GetAttribute("Area")~="Cafe" then return end
  if action=="Profile" or action=="OtherJournal" or action=="TradeRequest" then
   if type(value)~="number" or value~=value or value%1~=0 then return end
   local other=Players:GetPlayerByUserId(value)
   if not other or other==player or not bags[other] or not near(player,other) then return end
   if action=="Profile" then
    local featured={} for _,id in ipairs(bags[other].profile or {}) do local m=R.find(bags[other],id) if m then table.insert(featured,{monsterId=m.monsterId,stars=m.stars}) end end
    remote:FireClient(player,"Profile",{userId=other.UserId,name=other.DisplayName,username=other.Name,monsters=featured})
   elseif action=="OtherJournal" then remote:FireClient(player,"OtherJournal",Progress.snapshot(other,true))
   elseif not sessions[player] and not sessions[other] and not Store.busy(other) then
    local t={users={player,other},offers={[player]={ids={},coins=0},[other]={ids={},coins=0}},ready={},final={},revision=1,expires=clock+30}
    sessions[player]=t sessions[other]=t update(t)
    remote:FireClient(other,"TradeInvitation",{userId=player.UserId,name=player.DisplayName})
   end return
  end
  local t=sessions[player] if not t or t.committing then return end
  if clock>t.expires then close(t) return end
  local other=t.users[1]==player and t.users[2] or t.users[1]
  if action=="TradeDecline" then close(t) return end
  if action=="TradeAccept" and t.users[2]==player and near(player,other) then t.accepted=true t.expires=clock+180 update(t) return end
  if not t.accepted or not near(player,other) or Store.busy(other) then return end
  if action=="TradeOffer" then
   local offer=R.offer(bag,value)
   if offer then t.offers[player]={ids=offer.ids,coins=offer.coins} t.ready={} t.final={} t.revision+=1 t.expires=clock+180 update(t) end
  elseif action=="TradeReady" and value==t.revision then t.ready[player]=true update(t)
  elseif action=="TradeConfirm" and value==t.revision and t.ready[player] and t.ready[other] then
   t.final[player]=true update(t)
   if not t.final[other] then return end
   local a,b=t.users[1],t.users[2]
   local after,message=R.exchange(bags[a],bags[b],t.offers[a],t.offers[b])
   if not after then remote:FireClient(player,"SocialMessage",message) t.ready={} t.final={} update(t) return end
   t.committing=true
   if beforeTrade then beforeTrade(a) beforeTrade(b) end
   local ok=Store.trade(a,b,after)
   t.committing=false close(t)
   if ok then
    for _,p in ipairs({a,b}) do
     for _,m in ipairs(bags[p].monsters) do if Catalog[m.monsterId] then Progress.discover(p,m.monsterId,m.stars) end end
     sendBag(p) remote:FireClient(p,"SocialMessage","Trade complete.")
    end
   end
  end
 end)
 Players.PlayerRemoving:Connect(function(p) local t=sessions[p] if t and not t.committing then close(t) end end)
 task.spawn(function() while task.wait(2) do for _,t in pairs(sessions) do if not t.committing and (os.clock()>t.expires or not near(t.users[1],t.users[2])) then close(t) end end end end)
end
return S
]========]},
{name="PlanetCatalog",parent=package,before=[========[-- Only released/confirmed destinations are listed here.
local P={Order={"GreenStar"},GreenStar={Name="Green Star",Image="rbxassetid://78730064656056",LengthMeters=1000}}
return P
]========],after=[========[-- Confirmed planet names/artwork; only Green Star currently has a hunt course.
local P={Order={"GreenStar","Zephyrus","Phyto","Celestia"},
 GreenStar={Name="Green Star",Image="rbxassetid://138744590770196",LengthMeters=1000,Available=true},
 Zephyrus={Name="Zephyrus",Image="rbxassetid://109972305275318",Available=false},
 Phyto={Name="Phyto",Image="rbxassetid://110070555355468",Available=false},
 Celestia={Name="Celestia",Image="rbxassetid://93669217728731",Available=false}}
return P
]========]},
{name="SocialRules",parent=package,before=[========[-- Pure ownership rules used by both servers. No client-authored monster data.
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
 if type(ids)~="table" or #ids~=2 or ids[1]==ids[2] then return false,"암컷과 수컷을 한 마리씩 선택하세요." end
 local a,b=find(bag,ids[1]),find(bag,ids[2])
 if not R.available(a) or not R.available(b) then return false,"선택한 몬스터가 다른 작업 중입니다." end
 if not ((a.sex=="Male" and b.sex=="Female") or (a.sex=="Female" and b.sex=="Male")) then return false,"암컷과 수컷이 필요합니다." end
 local teams=0 for _ in pairs(bag.breedingTeams or {}) do teams+=1 end
 if teams>=4 then return false,"교배는 최대 4팀까지 가능합니다." end
 return true,"시간·결과 설정 준비 중 · 교배는 아직 시작되지 않습니다."
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
 if not x or not y then return nil,"보유 수량 또는 몬스터 상태가 바뀌었습니다." end
 if (x.coins==0 and #x.ids==0) or (y.coins==0 and #y.ids==0) then return nil,"그냥 주기는 불가능합니다. 양쪽 모두 교환할 것을 넣으세요." end
 if #x.ids+#y.ids==0 then return nil,"몬스터가 포함된 거래만 가능합니다." end
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
]========],after=[========[-- Pure ownership rules used by both servers. No client-authored monster data.
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
]========]},
}
local function normalize(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 c.node=assert(c.parent:FindFirstChild(c.name),c.name.." missing")
 assert(normalize(c.node.Source)==normalize(c.before) or normalize(c.node.Source)==normalize(c.after),"Source changed: "..c.name)
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before English refresh")
local backup=Instance.new("Folder") backup.Name="EnglishRefreshBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
package:SetAttribute("ShopButtonImage","rbxassetid://114640852127407")
package:SetAttribute("IndexButtonImage","rbxassetid://110488541037597")
package:SetAttribute("RouletteButtonImage","rbxassetid://71863210551741")
package:SetAttribute("BondButtonImage","rbxassetid://104399312241349")
package:SetAttribute("GreenStarImage","rbxassetid://138744590770196")
package:SetAttribute("ZephyrusImage","rbxassetid://109972305275318")
package:SetAttribute("PhytoImage","rbxassetid://110070555355468")
package:SetAttribute("CelestiaImage","rbxassetid://93669217728731")
package:SetAttribute("DefaultUILanguage","en-us")
game:GetService("ChangeHistoryService"):SetWaypoint("English refresh installed")
print("ENGLISH_REFRESH_INSTALLED",#changes)
end
