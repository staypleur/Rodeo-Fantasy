-- Artwork coordinates are measured on the unchanged 1448 x 1086 source PNG.
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
