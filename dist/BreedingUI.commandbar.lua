-- Replace this with the uploaded IMAGE asset ID, then run in Studio Command Bar.
local IMAGE_ID = "112011601018432"
assert(IMAGE_ID:match("^%d+$") and tonumber(IMAGE_ID)>0,"Set IMAGE_ID first")
assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
assert(game.GameId==10770388358,"Wrong experience")
local client=game.StarterPlayer.StarterPlayerScripts
local package=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local updates={{name=[=[BreedingUI]=],source=[=[-- Artwork coordinates are measured on the unchanged 1448 x 1086 source PNG.
local M={}
local UIS=game:GetService("UserInputService")
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local L=require(P:WaitForChild("Localization"))
local W,H=1448,1086
M.Regions={Close={1225,143,118,110},Female={375,295,196,176},Male={879,295,196,176},
 FemaleReset={546,452,60,60},MaleReset={1050,452,60,60},Breed={484,530,475,98},Guide={992,541,242,84}}
M.Slots={}
for _,y in ipairs({673,843}) do
 for _,x in ipairs({155,390,632,875,1115}) do table.insert(M.Slots,{x,y,181,122}) end
end
local function make(class,props,parent)
 local n=Instance.new(class) for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
function M.new(gui,remote,getItems,notice)
 local self={} local selected={} local page=1 local items={} local lastSend=-math.huge
 local ko=game.Players.LocalPlayer.LocaleId:sub(1,2)=="ko"
 local function text(a,b) return ko and a or b end
 local root=make("Frame",{Name="BreedingOverlay",Visible=false,BackgroundTransparency=1,
  AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(W,H),ZIndex=70},gui)
 local scale=make("UIScale",{},root)
 local art=make("ImageLabel",{Name="Background",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
  ScaleType=Enum.ScaleType.Stretch,Image="",ZIndex=70},root)
 local missing=make("TextLabel",{Name="MissingArtwork",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(13,18,44),
  BackgroundTransparency=.1,Text=text("번식실 배경 이미지 연결이 필요합니다.","Breeding background image is not configured."),
  TextColor3=Color3.new(1,1,1),TextSize=30,ZIndex=71},art)
 local function updateLoadStatus()
  missing.Visible=art.Image=="" or not art.IsLoaded
 end
 local function refreshArt()
  local id=P:GetAttribute("BreedingBackgroundImage")
  local imageId=type(id)=="string" and id or ""
  if art.Image~=imageId then art.Image=imageId end
  updateLoadStatus()
  if imageId~="" and not art.IsLoaded then
   task.spawn(function()
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({imageId}) end)
    if root.Parent and art.Image==imageId then updateLoadStatus() end
   end)
  end
 end
 local connections={}
 table.insert(connections,P:GetAttributeChangedSignal("BreedingBackgroundImage"):Connect(refreshArt))
 table.insert(connections,art:GetPropertyChangedSignal("IsLoaded"):Connect(updateLoadStatus))
 local function layout()
  local size=gui.AbsoluteSize
  scale.Scale=math.max(.01,math.min((size.X-24)/W,(size.Y-24)/H,1))
 end
 table.insert(connections,gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
 local function hit(name,rect,z)
  return make("ImageButton",{Name=name,Image="",ImageTransparency=1,BackgroundTransparency=1,
   AutoButtonColor=false,Position=UDim2.fromOffset(rect[1],rect[2]),Size=UDim2.fromOffset(rect[3],rect[4]),ZIndex=z or 75},root)
 end
 local buttons={} for name,rect in pairs(M.Regions) do buttons[name]=hit(name,rect) end
 local function label(parent,value)
  return make("TextLabel",{Text=value,BackgroundTransparency=1,Position=UDim2.new(0,0,1,-30),Size=UDim2.new(1,0,0,28),
   TextScaled=true,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=.25,ZIndex=78},parent)
 end
 local portraits={}
 local function draw(button,m)
  if portraits[button] then portraits[button]:Destroy() portraits[button]=nil end
  if not m then return end
  local box=make("Frame",{Name="Monster",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=76},button)
  portraits[button]=box
  local visual=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,-28),ZIndex=76},box)
  Portrait.fill(visual,m.monsterId,m.stars,false)
  label(box,(m.sex=="Female" and "♀ " or m.sex=="Male" and "♂ " or "")..L.text(m.monsterId,ko and "ko" or "en-us").." "..tostring(m.stars).."★")
 end
 local slots={} local render
 local function available(m) return m and not m.breedingTeam and not m.tradeLock end
 for i,rect in ipairs(M.Slots) do
  local b=hit("MonsterSlot"..i,rect) slots[i]=b
  b.Activated:Connect(function()
   local m=items[(page-1)*10+i]
   if not available(m) then notice(text("사용 중인 몬스터는 선택할 수 없습니다.","This monster is unavailable.")) return end
   if m.sex~="Female" and m.sex~="Male" then notice(text("성별이 정해진 몬스터를 선택하세요.","Choose a monster with a known sex.")) return end
   selected[m.sex]=selected[m.sex]==m.id and nil or m.id render()
  end)
 end
 -- Side rails give touch paging a larger target without covering the ten slots.
 local previous=hit("PreviousPage",{34,753,96,150}) label(previous,"‹")
 local nextPage=hit("NextPage",{1318,753,96,150}) label(nextPage,"›")
 local pageLabel=label(hit("PageNumber",{630,634,188,24}),"")
 render=function()
  items=table.clone(getItems() or {})
  table.sort(items,function(a,b) if a.stars~=b.stars then return a.stars>b.stars end return a.id<b.id end)
  local found={} for _,m in ipairs(items) do if available(m) and selected[m.sex]==m.id then found[m.sex]=m end end
  for _,sex in ipairs({"Female","Male"}) do if not found[sex] then selected[sex]=nil end draw(buttons[sex],found[sex]) end
  local pages=math.max(1,math.ceil(#items/10)) page=math.clamp(page,1,pages)
  pageLabel.Text=tostring(page).." / "..tostring(pages)
  previous.Visible=page>1 nextPage.Visible=page<pages
  for i,b in ipairs(slots) do
   local m=items[(page-1)*10+i] draw(b,m)
   b.Active=m~=nil b.Selectable=m~=nil
   local stroke=b:FindFirstChild("Selected") or make("UIStroke",{Name="Selected",Color=Color3.new(1,1,1),Thickness=3},b)
   stroke.Enabled=m~=nil and (selected.Female==m.id or selected.Male==m.id)
  end
 end
 previous.Activated:Connect(function() page-=1 render() end)
 nextPage.Activated:Connect(function() page+=1 render() end)
 function self.close() root.Visible=false end
 buttons.Close.Activated:Connect(self.close)
 for _,sex in ipairs({"Female","Male"}) do
  local function clear() selected[sex]=nil render() end
  buttons[sex].Activated:Connect(clear) buttons[sex.."Reset"].Activated:Connect(clear)
 end
 buttons.Breed.Activated:Connect(function()
  render() -- Recheck current ownership/locks before sending IDs; server is authoritative.
  if not selected.Female or not selected.Male then notice(text("암컷과 수컷을 한 마리씩 선택하세요.","Select one female and one male.")) return end
  if os.clock()-lastSend<1 then return end lastSend=os.clock()
  remote:FireServer("Breed",{selected.Female,selected.Male})
 end)
 buttons.Guide.Activated:Connect(function()
  notice(text("암컷·수컷을 선택하고 Breed를 누르세요. 현재는 짝 확인만 가능합니다. 교배서는 상자 드롭·행성 완주로 해금할 예정이며 조합과 확률은 준비 중입니다.",
   "Select a female and male, then Breed to check the pair. Breeding is not active yet. Recipe unlocks are planned for crates and course completion; combinations and rates are pending."))
 end)
 table.insert(connections,UIS.InputBegan:Connect(function(input,processed)
  if not root.Visible or processed or UIS:GetFocusedTextBox() then return end
  if input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB then self.close() end
 end))
 table.insert(connections,remote.OnClientEvent:Connect(function(kind)
  if kind=="Bag" and root.Visible then task.defer(function() if root.Parent then render() end end) end
 end))
 function self.open() selected={} page=1 root.Visible=true refreshArt() layout() render() remote:FireServer("Bag") end
 function self.destroy() for _,c in ipairs(connections) do c:Disconnect() end root:Destroy() end
 refreshArt() layout()
 return self
end
return M
]=]},{name=[=[SocialUI]=],source=[=[local S={}
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local BreedingUI=require(script.Parent:WaitForChild("BreedingUI"))
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
 local breeding=BreedingUI.new(gui,remote,function() return bag.items end,self.message)
 local controls=make("Frame",{Position=UDim2.fromOffset(18,63),Size=UDim2.new(1,-36,0,40),BackgroundTransparency=1,ZIndex=62},window)
 local footer=make("Frame",{Position=UDim2.new(0,18,1,-56),Size=UDim2.new(1,-36,0,42),BackgroundTransparency=1,ZIndex=62},window)
 local mode,selected,other,trade=nil,{},nil,nil
 local function clear(parent) for _,n in ipairs(parent:GetChildren()) do if not n:IsA("UIGridLayout") then n:Destroy() end end end
 local function open(name)
  breeding.close()
  if self.onOpen then self.onOpen() end
  bag.close() journal.close() window.Visible=true title.Text=name clear(content) clear(controls) clear(footer)
 end
 function self.close() window.Visible=false breeding.close() end
 local function ids() local out={} for id in pairs(selected) do table.insert(out,id) end table.sort(out) return out end
 local function card(m,fn)
  local frame=make("Frame",{BackgroundColor3=selected[m.id] and Color3.fromRGB(183,208,155) or Color3.fromRGB(251,243,224),Size=UDim2.fromOffset(170,205),ZIndex=62},content)
  make("UICorner",{CornerRadius=UDim.new(0,12)},frame)
  local v=make("Frame",{Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ZIndex=63},frame)
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
 function self.breed()
  if self.onOpen then self.onOpen() end
  bag.close() journal.close() window.Visible=false mode="Breed" breeding.open()
 end
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
]=]}}
local function norm(s) return s:gsub("\r\n","\n") end
local social=client:FindFirstChild("SocialUI")
assert(social and social:IsA("ModuleScript"),"Missing SocialUI")
assert(norm(social.Source)==norm([=[local S={}
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
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
  local v=make("Frame",{Size=UDim2.new(1,0,0,140),BackgroundTransparency=1,ZIndex=63},frame)
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
]=]) or norm(social.Source)==norm(updates[2].source),"SocialUI has other changes: review before installing")
for _,u in ipairs(updates) do
 assert(loadstring(u.source),"Invalid source: "..u.name)
 local old=client:FindFirstChild(u.name)
 assert(not old or old:IsA("ModuleScript"),"Unexpected class: "..u.name)
end
game.ChangeHistoryService:SetWaypoint("Before breeding UI")
local backup=Instance.new("Folder") backup.Name="BreedingUIBackup_"..game.HttpService:GenerateGUID(false)
backup.Archivable=false backup.Parent=game.ServerStorage
for _,u in ipairs(updates) do
 local n=client:FindFirstChild(u.name)
 if n then n:Clone().Parent=backup else n=Instance.new("ModuleScript") n.Name=u.name n.Parent=client end
 n.Source=u.source
end
package:SetAttribute("BreedingBackgroundImage","rbxassetid://"..IMAGE_ID)
game.ChangeHistoryService:SetWaypoint("Breeding UI installed")
print("BREEDING_UI_INSTALLED",game.PlaceId)
