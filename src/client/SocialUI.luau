local S={}
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
