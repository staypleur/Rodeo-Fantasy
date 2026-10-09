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
local Portrait=require(script.Parent.MonsterPortrait)
local function make(class,properties,parent)
 local node=Instance.new(class)
 if node:IsA("TextLabel") or node:IsA("TextButton") then node.Font=Enum.Font.Garamond node.TextColor3=Color3.fromRGB(63,57,42) end
 for key,value in pairs(properties) do node[key]=value end
 node.Parent=parent return node
end
local function T(text) return L.text(text,player.LocaleId) end
local function hint(entry)
 local species=C[entry.monsterId]
 if entry.stars>1 then return L.evolutionHint(entry.stars,player.LocaleId) end
 if species.Acquisition=="Breeding" then return T(species.RecipeHint or "Breeding details not announced yet") end
 return L.huntHint(species.UnlockMeters,species.TameSeconds,player.LocaleId)
end
function J.new(gui,remote)
 local self={area="Lobby",page=1,region="All",seen={},data={},entries=Q.entries(C)}
 local button=make("TextButton",{Name="OpenJournal",Text=T("Field journal").." [T]",Size=UDim2.fromOffset(175,44),Position=UDim2.new(1,-310,1,-60),BackgroundColor3=Color3.fromRGB(79,101,76),TextColor3=Color3.fromRGB(255,239,189),TextSize=20},gui)
 make("UICorner",{CornerRadius=UDim.new(0,10)},button)
 local holdBar=make("Frame",{Name="JournalHold",Size=UDim2.new(0,0,0,3),Position=UDim2.new(0,0,1,-3),BackgroundColor3=Color3.fromRGB(231,187,93),BorderSizePixel=0},button)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.91,.84),BackgroundColor3=Color3.fromRGB(101,77,62),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(980,680)},book)
 make("UICorner",{CornerRadius=UDim.new(0,12)},book)
 make("UIStroke",{Color=Color3.fromRGB(179,145,109),Thickness=3},book)
 for _,x in ipairs({.02,.51}) do
  local paper=make("Frame",{Name="Parchment",Position=UDim2.fromScale(x,.025),Size=UDim2.fromScale(.47,.95),BackgroundColor3=Color3.fromRGB(248,236,211),BorderSizePixel=0,ZIndex=41},book)
  make("UICorner",{CornerRadius=UDim.new(0,8)},paper)
 end
 make("Frame",{Name="BookSpine",Position=UDim2.fromScale(.495,.025),Size=UDim2.fromScale(.01,.95),BackgroundColor3=Color3.fromRGB(150,122,80),BorderSizePixel=0,ZIndex=42},book)
 local close=make("TextButton",{Name="CloseJournal",Text="×",Position=UDim2.new(1,-57,0,18),Size=UDim2.fromOffset(30,32),BackgroundTransparency=1,TextSize=30,ZIndex=45},book)
 local summary=make("TextLabel",{Name="JournalCount",BackgroundTransparency=1,Position=UDim2.fromOffset(32,20),Size=UDim2.new(.5,-55,0,28),TextSize=18,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=43},book)
 local regions=make("ScrollingFrame",{Name="JournalRegions",Position=UDim2.fromOffset(32,54),Size=UDim2.new(.46,-32,0,31),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=0,ZIndex=43},book)
 make("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,12)},regions)
 local pages=make("Frame",{Name="JournalEntries",BackgroundTransparency=1,Position=UDim2.fromOffset(32,98),Size=UDim2.new(1,-64,1,-210),ZIndex=43},book)
 local empty=make("TextLabel",{Name="JournalEmpty",Text=T("No entries here yet"),Visible=false,BackgroundTransparency=1,Position=pages.Position,Size=pages.Size,TextSize=23,ZIndex=44},book)
 local bubble=make("Frame",{Name="AcquisitionBubble",Visible=false,Size=UDim2.fromOffset(280,58),BackgroundColor3=Color3.fromRGB(255,249,230),BorderSizePixel=0,ZIndex=70},book)
 make("UICorner",{CornerRadius=UDim.new(0,9)},bubble)
 make("UIStroke",{Color=Color3.fromRGB(123,144,117),Thickness=2},bubble)
 make("Frame",{Name="BubbleTail",Rotation=45,Position=UDim2.new(.5,-5,0,-5),Size=UDim2.fromOffset(10,10),BackgroundColor3=Color3.fromRGB(255,249,230),BorderSizePixel=0,ZIndex=70},bubble)
 local bubbleText=make("TextLabel",{Name="AcquisitionText",BackgroundTransparency=1,Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextSize=14,TextScaled=true,TextWrapped=true,ZIndex=71},bubble)
 for i=1,8 do
  local stitch=make("Frame",{Name="DiaryStitch",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.08+i*.1),Size=UDim2.fromOffset(22,4),BackgroundColor3=Color3.fromRGB(121,94,73),BorderSizePixel=0,ZIndex=42},book)
  make("UICorner",{CornerRadius=UDim.new(0,2)},stitch)
 end
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",BackgroundTransparency=1,Position=UDim2.new(.3,0,1,-45),Size=UDim2.fromOffset(45,30),TextSize=30,ZIndex=44},book)
 local pageNumber=make("TextLabel",{Name="JournalPage",Text="1 / 1",BackgroundColor3=Color3.fromRGB(248,236,211),BorderSizePixel=0,Position=UDim2.new(.4,0,1,-44),Size=UDim2.new(.2,0,0,30),TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(52,66,54),ZIndex=44},book)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",BackgroundTransparency=1,Position=UDim2.new(.65,0,1,-45),Size=UDim2.fromOffset(45,30),TextSize=30,ZIndex=44},book)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=14},bubbleText)
 local animation=0 local lockedHumanoid local savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if humanoid and humanoid~=lockedHumanoid then
   lockedHumanoid=humanoid savedWalk=humanoid.WalkSpeed savedJump=humanoid.JumpPower savedRotate=humanoid.AutoRotate savedHeight=humanoid.JumpHeight
   humanoid.WalkSpeed=0 humanoid.JumpPower=0 humanoid.JumpHeight=0 humanoid.AutoRotate=false
  end
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid:Move(Vector3.zero) end
 end
 local function unlock()
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.WalkSpeed=savedWalk lockedHumanoid.JumpPower=savedJump lockedHumanoid.AutoRotate=savedRotate lockedHumanoid.JumpHeight=savedHeight end
  lockedHumanoid=nil CAS:UnbindAction("JournalPages")
 end
 local function flip()
  animation+=1 local token=animation
  for i=1,3 do task.delay((i-1)*.08,function()
   if token~=animation or not book.Visible then return end
   local leaf=make("Frame",{Name="TurningPage",AnchorPoint=Vector2.new(0,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.47,.92),BackgroundColor3=Color3.fromRGB(249-i*3,239-i*3,209-i*3),BorderSizePixel=0,ZIndex=48+i},book)
   make("UIStroke",{Color=Color3.fromRGB(204,187,149),Thickness=1},leaf)
   local tween=Tween:Create(leaf,TweenInfo.new(.24,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromScale(0,.92)})
   tween:Play() tween.Completed:Connect(function() leaf:Destroy() end)
  end) end
 end
 function self.close()
  book.Visible=false bubble.Visible=false animation+=1 unlock()
  for _,node in ipairs(book:GetChildren()) do if node.Name=="TurningPage" then node:Destroy() end end
 end
 function self.render()
  bubble.Visible=false
  for _,node in ipairs(pages:GetChildren()) do if node.Name=="JournalEntry" then node:Destroy() end end
  local items=Q.filter(self.entries,C,self.region,"")
  local max=math.max(1,math.ceil(#items/8)) self.page=math.clamp(self.page,1,max)
  pageNumber.Text=self.page.." / "..max empty.Visible=#items==0
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text=T("Discovered").." · "..discovered.." / "..#self.entries
  for _,tab in ipairs(regions:GetChildren()) do if tab:IsA("TextButton") then tab.BackgroundTransparency=tab.Name=="Region_"..self.region and .1 or .65 end end
  for i=(self.page-1)*8+1,math.min(self.page*8,#items) do
   local entry=items[i] local known=self.seen[entry.key]==true
   local card=make("TextButton",{Name="JournalEntry",Text="",LayoutOrder=i,BackgroundTransparency=1,Position=UDim2.fromScale((math.floor((i-1)%8/4)*.53)+(((i-1)%4)%2)*.235,math.floor(((i-1)%4)/2)*.5),Size=UDim2.fromScale(.235,.5),ZIndex=44},pages)
   local image=make("ViewportFrame",{Name="JournalPortrait",Size=UDim2.new(1,0,1,-42),BackgroundTransparency=1,Ambient=Color3.fromRGB(205,205,185),LightColor=Color3.new(1,1,1),ZIndex=45},card)
   Portrait.fill(image,entry.monsterId,entry.stars,not known,1.65)
   make("TextLabel",{Name="SpeciesName",Text=known and T(entry.monsterId) or "???",Position=UDim2.new(0,0,1,-42),Size=UDim2.new(1,0,0,22),TextSize=18,BackgroundTransparency=1,ZIndex=45},card)
   make("TextLabel",{Text=entry.stars.."★",Position=UDim2.new(0,0,1,-20),Size=UDim2.new(1,0,0,20),TextSize=15,BackgroundTransparency=1,TextColor3=Color3.fromRGB(144,113,48),ZIndex=45},card)
   local function showHint()
    bubbleText.Text=hint(entry)
    local center=card.AbsolutePosition+card.AbsoluteSize*.5-book.AbsolutePosition
    local width=math.min(280,math.max(120,book.AbsoluteSize.X-24))
    bubble.Size=UDim2.fromOffset(width,58)
    local x=math.clamp(center.X-width/2,12,math.max(12,book.AbsoluteSize.X-width-12))
    -- Dedicated footer band is outside every portrait and species label.
    bubble.Position=UDim2.fromOffset(x,book.AbsoluteSize.Y-108) bubble.Visible=true
   end
   card.MouseEnter:Connect(showHint)
   card.MouseLeave:Connect(function() bubble.Visible=false end)
   card.Activated:Connect(showHint) -- touch users can also read acquisition notes.
  end
 end
 function self.open()
  if self.area~="Lobby" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze()
  CAS:BindActionAtPriority("JournalPages",function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then self.turn(-1)
    elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then self.turn(1) end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
  book.Size=UDim2.fromScale(.08,.84) self.render()
  Tween:Create(book,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromScale(.91,.84)}):Play()
  flip() remote:FireServer("Journal")
 end
 function self.snapshot(data)
  self.data=data self.seen=data.seen or self.seen
  if book.Visible then self.render() end
 end
 function self.state(data)
  self.area=data.area button.Visible=self.area=="Lobby"
  if self.area~="Lobby" then self.close() end
  if book.Visible and data.count~=self.lastCount then remote:FireServer("Journal") end
  self.lastCount=data.count
 end
 for _,region in ipairs(Q.regions(C)) do
  local tab=make("TextButton",{Name="Region_"..region,Text=T(region),Size=UDim2.fromOffset(116,29),TextSize=18,BackgroundColor3=Color3.fromRGB(187,163,106),BackgroundTransparency=.65,ZIndex=44},regions)
  make("UICorner",{CornerRadius=UDim.new(0,6)},tab)
  tab.Activated:Connect(function() self.region=region self.page=1 self.render() flip() end)
 end
 function self.turn(direction)
  local old=self.page self.page=math.max(1,self.page+direction) self.render()
  if old~=self.page then
   pages.Position=UDim2.fromOffset(32+direction*18,98)
   Tween:Create(pages,TweenInfo.new(.22,Enum.EasingStyle.Quad),{Position=UDim2.fromOffset(32,98)}):Play() flip()
  end
 end
 previous.Activated:Connect(function() self.turn(-1) end)
 nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(self.open)
 local heldAt
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and self.area=="Lobby" and input.KeyCode==Enum.KeyCode.T then heldAt=os.clock() end
 end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.T then heldAt=nil holdBar.Size=UDim2.new(0,0,0,3) end end)
 Run.RenderStepped:Connect(function()
  if book.Visible then freeze() end
  if self.area~="Lobby" or UIS:GetFocusedTextBox() then heldAt=nil end
  if heldAt then
   local progress=math.clamp(os.clock()-heldAt,0,1) holdBar.Size=UDim2.new(progress,0,0,3)
   if progress>=1 then heldAt=nil holdBar.Size=UDim2.new(0,0,0,3) self.open() end
  end
 end)
 return self
end
return J
