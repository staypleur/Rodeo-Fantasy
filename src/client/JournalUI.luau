local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Buttons=require(script.Parent:WaitForChild("BagUI"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(class,props,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.GothamMedium node.TextColor3=Color3.fromRGB(68,52,33) end
 for key,value in pairs(props) do node[key]=value end
 node.Parent=parent return node
end
local function T(value) return L.text(value,player.LocaleId) end
local function gradient(parent,a,b)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new(a,b)},parent)
end
local function text(parent,name,value,x,y,w,h,size)
 local n=make("TextLabel",{Name=name,Text=value,BackgroundTransparency=1,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),TextScaled=true,TextWrapped=true,ZIndex=45},parent)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=size},n) return n
end
function J.new(gui,remote)
 local self={area="Lobby",page=1,region="All",seen={},data={},entries=Q.entries(C),perSpread=2}
 local button=Buttons.iconButton(gui,"Journal","T",92)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.96,.86),BackgroundColor3=Color3.fromRGB(87,54,34),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1200,780)},book)
 make("UICorner",{CornerRadius=UDim.new(0,12)},book)
 make("UIStroke",{Color=Color3.fromRGB(189,143,80),Thickness=3},book)
 gradient(book,Color3.fromRGB(129,82,47),Color3.fromRGB(59,39,29))
 local paper=make("Frame",{Name="Parchment",Position=UDim2.fromScale(.135,.065),Size=UDim2.fromScale(.73,.87),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=41},book)
 gradient(paper,Color3.fromRGB(248,237,209),Color3.fromRGB(213,191,147))
 make("UIStroke",{Color=Color3.fromRGB(182,154,107),Thickness=2},paper)
 local spine=make("Frame",{Name="BookSpine",Position=UDim2.fromScale(.498,.065),Size=UDim2.fromScale(.004,.87),BackgroundColor3=Color3.fromRGB(150,111,68),BorderSizePixel=0,ZIndex=42},book)
 local summary=text(book,"JournalCount","",.14,.005,.68,.05,18)
 summary.TextColor3=Color3.fromRGB(250,230,187)
 for _,x in ipairs({.145,.50}) do
  local line=make("Frame",{Name="PageHeaderRule",Position=UDim2.fromScale(x,.069),Size=UDim2.fromScale(.355,.004),BackgroundColor3=Color3.fromRGB(187,145,73),BorderSizePixel=0,ZIndex=42},book)
 end
 for _,x in ipairs({.137,.847}) do
  for _,y in ipairs({.069,.91}) do
   make("Frame",{Name="PaperCorner",Position=UDim2.fromScale(x,y),Size=UDim2.fromOffset(16,16),Rotation=45,BackgroundColor3=Color3.fromRGB(181,145,92),BackgroundTransparency=.4,BorderSizePixel=0,ZIndex=42},book)
  end
 end
 local regions=make("ScrollingFrame",{Name="JournalRegions",Position=UDim2.fromScale(.005,.18),Size=UDim2.fromScale(.125,.64),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollBarThickness=2,ZIndex=45},book)
 make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},regions)
 local pages=make("Frame",{Name="JournalEntries",BackgroundTransparency=1,Position=UDim2.fromScale(.15,.085),Size=UDim2.fromScale(.70,.83),ZIndex=43},book)
 local close=make("TextButton",{Name="CloseJournal",Text="×",Position=UDim2.fromScale(.91,.005),Size=UDim2.fromScale(.075,.065),BackgroundTransparency=1,TextColor3=Color3.fromRGB(246,226,184),TextSize=30,ZIndex=46},book)
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",Position=UDim2.fromScale(.145,.94),Size=UDim2.fromScale(.12,.06),BackgroundColor3=Color3.fromRGB(217,186,125),BorderSizePixel=0,TextSize=32,ZIndex=46},book)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",Position=UDim2.fromScale(.735,.94),Size=UDim2.fromScale(.12,.06),BackgroundColor3=Color3.fromRGB(217,186,125),BorderSizePixel=0,TextSize=32,ZIndex=46},book)
 local pageNumber=text(book,"JournalPage","",.32,.942,.36,.052,18) pageNumber.TextColor3=Color3.fromRGB(250,230,187)
 local lockedHumanoid,savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local character=player.Character local h=character and character:FindFirstChildOfClass("Humanoid")
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
 local generation=0 local turning=false
 local function flip(direction)
  generation+=1 local token=generation turning=true Audio.ui("PageTurn")
  local leaf=make("Frame",{Name="TurningPage",AnchorPoint=Vector2.new(direction<0 and 1 or 0,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.355,.87),BackgroundColor3=Color3.fromRGB(242,225,185),BorderSizePixel=0,ZIndex=55},book)
  gradient(leaf,Color3.fromRGB(250,237,207),Color3.fromRGB(201,166,109))
  Tween:Create(leaf,TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromScale(0,.87)}):Play()
  task.delay(.26,function() leaf:Destroy() if generation==token then turning=false end end)
 end
 function self.close()
  book.Visible=false generation+=1 turning=false unlock()
  for _,n in ipairs(book:GetChildren()) do if n.Name=="TurningPage" then n:Destroy() end end
 end
 local function speciesList()
  local ids={} for _,id in ipairs(C.Order) do if self.region=="All" or C[id].Region==self.region then table.insert(ids,id) end end return ids
 end
 function self.render()
  for _,n in ipairs(pages:GetChildren()) do n:Destroy() end
  local ids=speciesList() local max=math.max(1,math.ceil(#ids/self.perSpread)) self.page=math.clamp(self.page,1,max)
  pageNumber.Text=self.page.." / "..max
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text=T("Discovered").." "..discovered.." / "..#self.entries.."   ·   "..T("Total caught").." "..(self.data.captures or 0)
  for _,tab in ipairs(regions:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundTransparency=tab.Name=="Region_"..self.region and 0 or .28 end end
  previous.AutoButtonColor=self.page>1 nextPage.AutoButtonColor=self.page<max
  if #ids==0 then text(pages,"JournalEmpty",T("Region not released yet"),0,.2,1,.5,20) return end
  for slot=1,self.perSpread do
   local id=ids[(self.page-1)*self.perSpread+slot] if not id then continue end
   local species=C[id] local known=false local caught=0
   for _,stars in ipairs({1,3,6,9}) do local key=id..":"..stars known=known or self.seen[key]==true caught+=(self.data.caught and self.data.caught[key] or 0) end
   local page=make("Frame",{Name="SpeciesPage",BackgroundTransparency=1,Position=UDim2.fromScale((slot-1)/self.perSpread+.01,0),Size=UDim2.fromScale(1/self.perSpread-.02,1),ZIndex=44},pages)
   text(page,"SpeciesTitle",known and T(id) or "???",0,0,1,.07,24)
   local caughtLabel=text(page,"SpeciesCaught",T("Caught").." "..caught,0,.075,1,.055,15) caughtLabel.TextColor3=Color3.fromRGB(82,109,67)
   local info=make("Frame",{Name="SpeciesInformation",Position=UDim2.fromScale(0,.75),Size=UDim2.fromScale(1,.25),BackgroundColor3=Color3.fromRGB(246,228,187),BorderSizePixel=0,ZIndex=44},page)
   text(info,"FoundAt",T("Found at").." · "..T(species.Region).." "..(species.UnlockMeters or 0).."m",.03,.03,.94,.22,15)
   text(info,"TamingTime",T("Taming (1 star)").." · "..species.TameSeconds..T("Seconds"),.03,.27,.94,.22,15)
   local income=text(info,"Production","",.03,.51,.94,.22,15)
   local acquisition=text(info,"Acquisition","",.03,.75,.94,.23,13)
   local function select(stars)
    income.Text=stars.."★ · "..L.income((species.IncomeAmount or 1)*2^(stars-1),species.IncomeSeconds or 3,player.LocaleId)
    acquisition.Text=stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,player.LocaleId) or L.evolutionHint(stars,player.LocaleId)
   end
   select(1)
   for index,stars in ipairs({1,3,6,9}) do
    local revealed=self.seen[id..":"..stars]==true
    local card=make("TextButton",{Name="JournalEntry",Text="",Position=UDim2.fromScale(((index-1)%2)*.51,.14+math.floor((index-1)/2)*.30),Size=UDim2.fromScale(.49,.285),BackgroundColor3=Color3.fromRGB(216,204,170),BackgroundTransparency=.22,BorderSizePixel=0,ZIndex=44},page)
    make("UIStroke",{Color=Color3.fromRGB(169,147,102),Thickness=1},card)
    local viewport=make("ViewportFrame",{Name="JournalPortrait",Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,.8),BackgroundTransparency=1,Ambient=Color3.fromRGB(205,205,185),LightColor=Color3.new(1,1,1),ZIndex=45},card)
    Portrait.fill(viewport,id,stars,not revealed,1.65)
    if not revealed then local q=text(card,"UndiscoveredQuestion","?",.2,.12,.6,.55,52) q.TextColor3=Color3.fromRGB(244,209,121) q.ZIndex=46 q.TextStrokeTransparency=.2 end
    text(card,"Stars",stars.."★",0,.8,1,.2,17)
    card.MouseEnter:Connect(function() select(stars) end)
    card.Activated:Connect(function() select(stars) end)
   end
  end
 end
 function self.turn(direction)
  if not book.Visible or turning then return end
  local max=math.max(1,math.ceil(#speciesList()/self.perSpread)) local next=math.clamp(self.page+direction,1,max)
  if next==self.page then return end
  self.page=next self.render() flip(direction)
 end
 function self.open()
  if self.area=="Hunt" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze() self.render() Audio.ui("BookOpen") if not self.other then remote:FireServer("Journal") end
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
 for index,region in ipairs({"All","Meadow","Forest","Swamp","Ocean"}) do
  local colors={Color3.fromRGB(172,145,85),Color3.fromRGB(112,153,85),Color3.fromRGB(70,123,88),Color3.fromRGB(122,120,76),Color3.fromRGB(75,137,164)}
  local tab=make("TextButton",{Name="Region_"..region,LayoutOrder=index,Text=T(region),Size=UDim2.new(1,-3,0,42),TextScaled=true,BackgroundColor3=colors[index],TextColor3=Color3.fromRGB(255,242,214),BorderSizePixel=0,ZIndex=46},regions)
  make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=16},tab)
  tab.Activated:Connect(function()
   if turning or self.region==region then return end
   self.region=region self.page=1 self.render() flip(1)
  end)
 end
 -- Mutation/breeding tabs wait for confirmed content and recipe rules.
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 local function resize()
  local n=book.AbsoluteSize.X<700 and 1 or 2
  if n~=self.perSpread then
   local first=(self.page-1)*self.perSpread self.perSpread=n self.page=math.floor(first/n)+1
   spine.Visible=n==2 if book.Visible then self.render() end
  end
 end
 book:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize) resize()
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
