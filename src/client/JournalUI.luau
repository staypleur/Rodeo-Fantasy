-- Reference-style index; collection keys and income rules remain unchanged.
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
