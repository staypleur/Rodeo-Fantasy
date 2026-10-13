assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
assert(game.GameId==10770388358,"Wrong experience")
local package=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local client=game.StarterPlayer.StarterPlayerScripts
local changes={{node=package:FindFirstChild([=[PlanetCatalog]=]),kind=[=[ModuleScript]=],before=[=[-- Confirmed planet names/artwork; only Green Star currently has a hunt course.
local Course=require(script.Parent.CourseGeometry)
local P={Order={"GreenStar","Zephyrus","Phyto","Celestia"},
 GreenStar={Name="Green Star",Image="rbxassetid://138744590770196",LengthMeters=Course.LengthMeters,Available=true},
 Zephyrus={Name="Zephyrus",Image="rbxassetid://109972305275318",Available=false},
 Phyto={Name="Phyto",Image="rbxassetid://110070555355468",Available=false},
 Celestia={Name="Celestia",Image="rbxassetid://93669217728731",Available=false}}
return P
]=],after=[=[-- User-approved order and artwork. Only Green Star has a playable hunt course.
local Course=require(script.Parent.CourseGeometry)
local P={Order={"GreenStar","Zephyrus","Floareef","Cryo","Iris","Phyto","Solaris","Mechanica","Celestia","Overgrown","Soultan","Nuclear","Stalline","Abyss","Neon","Chronos","Wasteland","Vortex","Gargantua"},
 GreenStar={Name="Green Star",Description="숲 초원 행성",Image="rbxassetid://138744590770196",Available=true,LengthMeters=Course.LengthMeters},
 Zephyrus={Name="Zephyrus",Description="사막 모래 폭풍 행성",Image="rbxassetid://109972305275318",Available=false},
 Floareef={Name="Floareef",Description="바다, 해초, 해파리, 산호 행성",Image="rbxassetid://132856159980542",Available=false},
 Cryo={Name="Cryo",Description="빙하, 얼어붙은 별, 영혼 에너지가 갇힌 행성",Image="rbxassetid://137343730723244",Available=false},
 Iris={Name="Iris",Description="무지개빛 유리, 보석 지형 행성",Image="rbxassetid://134345029159213",Available=false},
 Phyto={Name="Phyto",Description="벌레, 파리지옥, 버섯 행성",Image="rbxassetid://110070555355468",Available=false},
 Solaris={Name="Solaris",Description="하얀 마그마, 주황 태양풍, 극한 열기 행성",Image="rbxassetid://132429133902459",Available=false},
 Mechanica={Name="Mechanica",Description="거대한 기계와 파이프라인 행성",Image="rbxassetid://109682350665982",Available=false},
 Celestia={Name="Celestia",Description="보라색 안개, 부유하는 암석 행성",Image="rbxassetid://93669217728731",Available=false},
 Overgrown={Name="Overgrown",Description="이끼 낀 오래된 고대 기계, 자연 마도공학 행성",Image="rbxassetid://90442953407793",Available=false},
 Soultan={Name="Soultan",Description="서리오라, 주황·푸른 영혼 불꽃 설원 행성",Image="rbxassetid://129197246489405",Available=false},
 Nuclear={Name="Nuclear",Description="녹색 오염, 방사능, 일그러진 시공간 행성",Image="rbxassetid://70732990890234",Available=false},
 Stalline={Name="Stalline",Description="용암, 빛나는 용암 결정, 화산 행성",Image="rbxassetid://138868303166132",Available=false},
 Abyss={Name="Abyss",Description="암흑물질, 공허의 빛 행성",Image="rbxassetid://99659267680487",Available=false},
 Neon={Name="Neon",Description="네온 전선, 미래도시 구조물 행성",Image="rbxassetid://114563861855074",Available=false},
 Chronos={Name="Chronos",Description="과거의 고대문명, 황금빛, 시간오류 행성",Image="rbxassetid://88252375899235",Available=false},
 Wasteland={Name="Wasteland",Description="환각, 보라 버섯포자, 사막 황무지 행성",Image="rbxassetid://130292428150726",Available=false},
 Vortex={Name="Vortex",Description="푸른·보라 가스, 심연, 표면 없음, 플라즈마 폭풍 행성",Image="rbxassetid://113610760687152",Available=false},
 Gargantua={Name="Gargantua",Description="유황, 중금속, 강한 중력, 현무암 지형, 붉은 유황호수, 금곡 결정체 행성",Image="rbxassetid://76365437870859",Available=false},
 -- Reserved artwork: no selection position was specified for Cherry.
 Cherry={Name="Cherry",Image="rbxassetid://135408549566412",Available=false},
}
return P
]=]},{node=client:FindFirstChild([=[JournalUI]=]),kind=[=[ModuleScript]=],before=[=[-- Reference-style index; collection keys and income rules remain unchanged.
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
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and (self.area=="Lobby" or self.area=="Cafe") then self.other=false self.open() end
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
 local planetTab=make("ScrollingFrame",{Name="PlanetTabs",Active=true,BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.new(),ClipsDescendants=true,Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.68),BackgroundTransparency=1,ZIndex=46},book)
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
  planetTab.ScrollingDirection=compact and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
  local extent=compact and 140 or 86
  planetTab.CanvasSize=compact and UDim2.fromOffset(#planetButtons*extent,0) or UDim2.fromOffset(0,#planetButtons*extent)
  planetTab.CanvasPosition=Vector2.zero
  for index,tab in ipairs(planetButtons) do
   tab.Position=compact and UDim2.fromOffset((index-1)*extent+2,2) or UDim2.fromOffset(2,(index-1)*extent+2)
   tab.Size=compact and UDim2.new(0,extent-8,1,-10) or UDim2.new(1,-10,0,extent-8)
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
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and (self.area=="Lobby" or self.area=="Cafe") then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]=]},{node=client:FindFirstChild([=[RocketDeparture]=]),kind=[=[LocalScript]=],before=[=[local Players=game:GetService("Players")
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
local messages={PlanetLocked="Run 10 km on the previous planet to unlock.",MenuExpired="Selection expired. Hold E at the rocket again.",ApproachRocket="Try again near the rocket.",ModelPending="This monster model is coming soon.",CoursePending="This hunt is coming soon.",MonsterBusy="This monster is busy.",NotOwned="Your inventory changed. Please select again.",LaunchFailed="Unable to prepare the hunt. Please try again."}
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
 if menu.travel and not menu.travel.unlocked[selected] then status.Text="Run 10 km on the previous planet to unlock." return end
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
    b.BackgroundColor3=Color3.fromRGB(7,67,71) b.Outline.Thickness=5 b.Outline.Color=Color3.fromRGB(87,255,222)
    local travel=menu.travel
    if index>1 and travel and not travel.unlocked[id] then
     local meters=travel.planetMeters[Planets.Order[index-1]] or 0
     status.Text=travel.loaded and string.format("%s: %.2f / 10 km",Planets[Planets.Order[index-1]].Name,meters/1000) or "Loading distance…"
    else status.Text=planet.Available and "" or "Coming soon" end
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
local messages={PlanetLocked="Run 10 km on the previous planet to unlock.",MenuExpired="Selection expired. Hold E at the rocket again.",ApproachRocket="Try again near the rocket.",ModelPending="This monster model is coming soon.",CoursePending="This hunt is coming soon.",MonsterBusy="This monster is busy.",NotOwned="Your inventory changed. Please select again.",LaunchFailed="Unable to prepare the hunt. Please try again."}
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
 if menu.travel and not menu.travel.unlocked[selected] then status.Text="Run 10 km on the previous planet to unlock." return end
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
    b.BackgroundColor3=Color3.fromRGB(7,67,71) b.Outline.Thickness=5 b.Outline.Color=Color3.fromRGB(87,255,222)
    local travel=menu.travel
    if index>1 and travel and not travel.unlocked[id] then
     local meters=travel.planetMeters[Planets.Order[index-1]] or 0
     status.Text=travel.loaded and string.format("%s: %.2f / 10 km",Planets[Planets.Order[index-1]].Name,meters/1000) or "Loading distance…"
    else status.Text=planet.Available and "" or "Coming soon" end
   end)
   b.Name="Planet_"..id
   local accents={GreenStar=Color3.fromRGB(92,242,206),Zephyrus=Color3.fromRGB(247,201,107),Phyto=Color3.fromRGB(89,221,173),Celestia=Color3.fromRGB(180,137,252)}
   local accent=accents[id] or Color3.fromRGB(145,205,255)
   b:SetAttribute("Accent",accent)
   make("UIStroke",{Name="Outline",Color=accent,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},b)
   make("UIGradient",{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(145,180,235))},b)
   make("ImageLabel",{Name=id.."Artwork",Image=planet.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.05,.02),Size=UDim2.fromScale(.90,.80),ScaleType=Enum.ScaleType.Fit},b)
   make("TextLabel",{Name="PlanetLabel",Text=planet.Name,BackgroundTransparency=1,Position=UDim2.fromScale(.05,.82),Size=UDim2.fromScale(.90,.14),TextScaled=true,TextWrapped=true,Font=Enum.Font.GothamBold,TextColor3=accent},b)
  end
 elseif action=="DepartureResult" and gui.Enabled then
  busy=false
  if data.ok then hide(false) else status.Text=messages[data.reason] or "Unable to depart. Please select again." end
 elseif action=="State" and data.area=="Hunt" then hide(false) end
end)
]=]}}
local function norm(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 assert(c.node and c.node:IsA(c.kind),"Missing or unexpected script")
 assert(norm(c.node.Source)==norm(c.before) or norm(c.node.Source)==norm(c.after),"Other changes: "..c.node.Name)
 assert(loadstring(c.after),"Invalid source: "..c.node.Name)
 c.original=c.node.Source
end
game.ChangeHistoryService:SetWaypoint("Before planet artwork")
local backup=Instance.new("Folder") backup.Name="PlanetUpdateBackup_"..game.HttpService:GenerateGUID(false)
backup.Archivable=false backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do c.node:Clone().Parent=backup end
local ok,err=pcall(function() for _,c in ipairs(changes) do c.node.Source=c.after end end)
if not ok then for _,c in ipairs(changes) do c.node.Source=c.original end error(err) end
game.ChangeHistoryService:SetWaypoint("Planet artwork installed")
print("PLANET_UPDATE_INSTALLED",game.PlaceId,19)
