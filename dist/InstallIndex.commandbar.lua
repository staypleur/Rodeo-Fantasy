-- Existing uploaded models and lobby geometry are retained.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local changes={{name="JournalUI",after=[========[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
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
  summary.Text="잠금 해제: "..discovered.."/"..#self.entries
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
]========],allowed={[========[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
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
  summary.Text="잠금 해제: "..discovered.."/"..#self.entries
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
]========],[========[local J={}
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
]========],[========[local J={}
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
]========],[========[local J={}
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
]========],[========[local J={}
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
]========],[========[local J={}
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
]========],[========[local J={}
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
]========]}},{name="MonsterPortrait",after=[========[local P={}
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
]========],allowed={[========[local P={}
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
]========],[========[local P={}
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
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 local direction=Vector3.new(1,.55,-1.5).Unit
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
]========],[========[local P={}
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
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 local direction=Vector3.new(1,.55,-1.5).Unit
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
]========],[========[local P={}
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
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 local direction=Vector3.new(1,.55,-1.5).Unit
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
]========],[========[local P={}
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
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 local direction=Vector3.new(1,.55,-1.5).Unit
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
]========],[========[local P={}
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
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 local direction=Vector3.new(1,.55,-1.5).Unit
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
]========],[========[local P={}
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
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 local direction=Vector3.new(1,.55,-1.5).Unit
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
]========]}},{name="CreatureMesh",after=[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.posePortrait(model) Native.posePortrait(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========],allowed={[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.posePortrait(model) Native.posePortrait(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========],[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========],[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========],[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========],[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========],[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========],[========[-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
]========]}},{name="NativeMossrat",after=[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.posePortrait(model)
 if not M.isTarget(model) then return end
 rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
 rigAnimator.poseFront(model)
end
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],allowed={[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.posePortrait(model)
 if not M.isTarget(model) then return end
 rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
 rigAnimator.poseFront(model)
end
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if body and body:FindFirstChild("LeftFrontUpper",true) and body:FindFirstChild("Head",true) then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 -- Correct the installed S1 mesh facing opposite the forward (-Z) run direction.
 -- Fixed revision keeps this idempotent; never rotate the authoritative root.
 if source:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  yaw+=180
  facingRevision..="-ForwardV2"
 end
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========],[========[-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local rigAnimator
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("MossratUserRigRevision",source:GetAttribute("MossratUserRigRevision"))
 model:SetAttribute("MossratRigTranslationScale",(source:GetAttribute("MossratRigTranslationScale") or 2.5/.9)*scale)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 if model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  rigAnimator=rigAnimator or require(script.Parent:WaitForChild("UserMossratRigAnimator"))
  rigAnimator.animate(model,moving)
  return
 end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
]========]}},{name="UserMossratRigAnimator",after=[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],allowed={[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
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
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========]}},{name="HudIcons",after=[========[-- Small native shapes: no external images are required for the menu symbols.
local I={}
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
 local function refresh()
  local id=package:GetAttribute(key)
  local ready=type(id)=="string" and id:match("^rbxassetid://%d+$")~=nil
  image.Image=ready and id or "" image.Visible=ready
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
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
]========],allowed={[========[-- Small native shapes: no external images are required for the menu symbols.
local I={}
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
 local function refresh()
  local id=package:GetAttribute(key)
  local ready=type(id)=="string" and id:match("^rbxassetid://%d+$")~=nil
  image.Image=ready and id or "" image.Visible=ready
  button.BackgroundTransparency=ready and 1 or background
  for n,visible in pairs(originals) do n.Visible=not ready and visible end
  for n,enabled in pairs(strokes) do n.Enabled=not ready and enabled end
 end
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
]========],[========[-- Small native shapes: no external images are required for the menu symbols.
local I={}
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
]========]}},{name="LobbyMenus",after=[========[-- Lobby entries only; products, odds and rewards remain undecided.
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
  for _,button in ipairs(buttons) do button.Visible=lobby end
  if not lobby then api.close() end
 end
 return api
end
return M
]========],allowed={[========[-- Lobby entries only; products, odds and rewards remain undecided.
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
  for _,button in ipairs(buttons) do button.Visible=lobby end
  if not lobby then api.close() end
 end
 return api
end
return M
]========],[========[-- Lobby entries only; products, odds and rewards remain undecided.
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
  make("TextLabel",{Text="도감",BackgroundTransparency=1,Position=UDim2.fromOffset(54,0),Size=UDim2.new(1,-58,1,0),Font=Enum.Font.GothamBlack,TextSize=24,TextColor3=Color3.new(1,1,1),TextStrokeColor3=Color3.new(0,0,0),TextStrokeTransparency=0},journalButton)
 end
 for i,kind in ipairs({"Egg","Paw"}) do
  local button=make("TextButton",{Name="Open"..kind,Text="",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,.42,i==1 and -26 or 38),Size=UDim2.fromOffset(56,56),BorderSizePixel=0,BackgroundColor3=i==1 and Color3.fromRGB(255,83,80) or Color3.fromRGB(255,160,54),Visible=false},gui)
  make("UICorner",{CornerRadius=UDim.new(0,5)},button) make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},button)
  local icon=Icons.draw(button,kind,42) icon.Position=UDim2.fromOffset(7,7)
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
  for _,button in ipairs(buttons) do button.Visible=lobby end
  if not lobby then api.close() end
 end
 return api
end
return M
]========],[========[-- Lobby entries only; products, odds and rewards remain undecided.
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
]========]}}}
local function norm(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 c.node=assert(clients:FindFirstChild(c.name),"코드 없음: "..c.name)
 assert(c.node:IsA("ModuleScript"),"종류 불일치: "..c.name)
 local valid=false for _,s in ipairs(c.allowed) do if norm(s)==norm(c.node.Source) then valid=true break end end
 assert(valid,"다른 코드가 있어 중단: "..c.name) c.before=c.node.Source
end
local backup=Instance.new("Folder") backup.Name="IndexUpdateBackup_"..game:GetService("HttpService"):GenerateGUID(false)
for _,c in ipairs(changes) do c.node:Clone().Parent=backup end
game:GetService("ChangeHistoryService"):SetWaypoint("Before index update")
local ok,err=pcall(function()
 backup.Parent=game:GetService("ServerStorage")
 for _,c in ipairs(changes) do c.node.Source=c.after end
end)
if not ok then
 for _,c in ipairs(changes) do c.node.Source=c.before end
 backup:Destroy() error("인덱스 설치 복구 완료: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Index updated")
print("INDEX_UPDATE_INSTALLED — Ctrl+S 저장 후 Play. 왼쪽 인덱스 버튼 또는 T를 누르세요.")
