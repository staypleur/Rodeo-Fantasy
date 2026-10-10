-- Edit mode only. Import the user's GLB as Workspace.RocketImport first.
assert(not game:GetService("RunService"):IsRunning(),"Play를 정지한 뒤 실행하세요.")
local storage=game:GetService("ServerStorage")
local server=game:GetService("ServerScriptService")
local scripts=game:GetService("StarterPlayer").StarterPlayerScripts
local package=game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
local lobby=workspace:FindFirstChild("RodeoLobby")
assert(package and lobby,"기존 Rodeo Fantasy 장소에서 실행하세요.")
local airport=assert(lobby:FindFirstChild("Airport"),"Airport 없음")
local installed=airport:FindFirstChild("Rocket")
if installed and installed:GetAttribute("UserRocketDepartureV1") then print("ROCKET_DEPARTURE_ALREADY_INSTALLED") return end
assert(not installed,"기존 Rocket을 덮어쓰지 않습니다.")
local imported=assert(workspace:FindFirstChild("RocketImport"),"가져온 로켓 Model 이름을 RocketImport로 바꿔 주세요.")
assert(imported:IsA("Model"),"RocketImport는 Model이어야 합니다.")
local meshes=0
for _,node in ipairs(imported:GetDescendants()) do
 assert(not node:IsA("LuaSourceContainer"),"로켓 입력에는 실행 스크립트를 넣지 마세요.")
 if node:IsA("MeshPart") then meshes+=1 end
end
assert(meshes>0,"가져온 로켓에 MeshPart가 없습니다.")
local airship=assert(airport:FindFirstChild("Airship"),"Airship 호환 노드 없음")
local point=assert(airport:FindFirstChild("Departure"),"Departure 없음")
local updates={}
local function prepare(node,old,new)
 assert(node and node:IsA("LuaSourceContainer"),"연결할 스크립트를 찾지 못했습니다.")
 local entry
 for _,u in ipairs(updates) do if u.node==node then entry=u break end end
 if not entry then entry={node=node,before=node.Source,after=node.Source:gsub("\r\n","\n")} table.insert(updates,entry) end
 assert(not string.find(entry.after,new,1,true),"이미 일부 연결된 코드입니다. 중복 적용을 중단합니다.")
 local first,last=string.find(entry.after,old,1,true)
 assert(first and not string.find(entry.after,old,last+1,true),"코드 버전이 달라 자동 연결을 중단합니다. 기존 코드는 보존됩니다.")
 entry.after=entry.after:sub(1,first-1)..new..entry.after:sub(last+1)
end
local captureServer=server:FindFirstChild("CaptureServer",true)
local captureClient=scripts:FindFirstChild("CaptureClient",true)
local lobbyWorld=server:FindFirstChild("LobbyWorld",true)
assert(captureServer and captureClient and lobbyWorld,"CaptureServer/CaptureClient/LobbyWorld를 찾을 수 없습니다.")
prepare(captureServer,[====[local tuning=Config.Prototype]====],[====[local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end]====])
prepare(captureServer,[====[if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not Lobby.canDepart(player)]====],[====[if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player)]====])
prepare(captureServer,[====[Lobby.connect(function(p) if not Store.busy(p) and not p:GetAttribute("Travelling") then start(p) end end)]====],[====[local departure=require(script.Parent.RocketDepartureService).new({
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
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil end)]====])
prepare(captureClient,[====[require(script.Parent:WaitForChild("SkyWhaleRuntime")).install(airship)]====],[====[if not airship:GetAttribute("RocketDepartureActive") then require(script.Parent:WaitForChild("SkyWhaleRuntime")).install(airship) end]====])
prepare(captureClient,[====[local function animateShip(clock)]====],[====[local function animateShip(clock)
 if airship:GetAttribute("RocketDepartureActive") then return end]====])
prepare(lobbyWorld,[====[prompt.ActionText="Fly to hunt" prompt.ObjectText="Airship"]====],[====[prompt.ActionText="행성 선택" prompt.ObjectText="로켓"]====])
local additions={}
local function add(parent,class,name,source)
 assert(not parent:FindFirstChild(name),"이미 있는 연결 모듈: "..name)
 local node=Instance.new(class) node.Name=name node.Source=source
 table.insert(additions,{node=node,parent=parent})
end
if package:FindFirstChild("DepartureSelectionRules") then assert(package.DepartureSelectionRules.Source:gsub("\r\n","\n")==[====[-- Server-side validation for the upcoming planet -> owned mount flow.
-- Returns the owned item, never accepts client monster stats or wild models.
local Rules={}
function Rules.validate(bag,destinationId,itemId,catalog,availableModels)
 if destinationId~="GreenStar" then return nil,"UnknownDestination" end
 if type(itemId)~="number" or itemId~=itemId or itemId%1~=0 then return nil,"InvalidMonster" end
 if type(bag)~="table" or type(bag.monsters)~="table" then return nil,"InventoryUnavailable" end
 for _,item in ipairs(bag.monsters) do
  if item.id==itemId then
   if item.breedingTeam or item.tradeLock then return nil,"MonsterBusy" end
   if not catalog[item.monsterId] then return nil,"UnknownSpecies" end
   if not availableModels(item.monsterId,item.stars or 1) then return nil,"ModelPending" end
   return item
  end
 end
 return nil,"NotOwned"
end
return Rules
]====],"선택 규칙 버전이 다릅니다.") else add(package,"ModuleScript","DepartureSelectionRules",[====[-- Server-side validation for the upcoming planet -> owned mount flow.
-- Returns the owned item, never accepts client monster stats or wild models.
local Rules={}
function Rules.validate(bag,destinationId,itemId,catalog,availableModels)
 if destinationId~="GreenStar" then return nil,"UnknownDestination" end
 if type(itemId)~="number" or itemId~=itemId or itemId%1~=0 then return nil,"InvalidMonster" end
 if type(bag)~="table" or type(bag.monsters)~="table" then return nil,"InventoryUnavailable" end
 for _,item in ipairs(bag.monsters) do
  if item.id==itemId then
   if item.breedingTeam or item.tradeLock then return nil,"MonsterBusy" end
   if not catalog[item.monsterId] then return nil,"UnknownSpecies" end
   if not availableModels(item.monsterId,item.stars or 1) then return nil,"ModelPending" end
   return item
  end
 end
 return nil,"NotOwned"
end
return Rules
]====]) end
add(captureServer.Parent,"ModuleScript","RocketDepartureService",[====[-- Server-authoritative selection, independent of model import and UI layout.
local Service={}
local Rules=require(game:GetService("ReplicatedStorage").RodeoFantasy.DepartureSelectionRules)
function Service.new(ctx)
 local pending,lastSubmit={},{}
 local api={}
 local function result(player,ok,reason)
  ctx.send(player,"DepartureResult",{ok=ok,reason=reason})
 end
 function api.open(player)
  if not ctx.canOpen(player) then return false end
  local bag=ctx.bag(player)
  if not bag then return false end
  local token=ctx.token()
  pending[player]={token=token,expires=ctx.now()+60}
  local items={}
  for _,item in ipairs(bag.monsters or {}) do
   local owned,reason=Rules.validate(bag,"GreenStar",item.id,ctx.catalog,ctx.modelReady)
   table.insert(items,{id=item.id,monsterId=item.monsterId,stars=item.stars or 1,
    ready=owned~=nil,reason=reason})
  end
  ctx.send(player,"DepartureMenu",{token=token,items=items,planet="GreenStar",name="Green Star",lengthMeters=1000})
  return true
 end
 function api.submit(player,value)
  if type(value)~="table" then return false end
  if ctx.now()-(lastSubmit[player] or -math.huge)<.5 then return false end
  lastSubmit[player]=ctx.now()
  local menu=pending[player]
  if not menu or value.token~=menu.token or ctx.now()>menu.expires then
   result(player,false,"MenuExpired") return false
  end
  if not ctx.canOpen(player) then result(player,false,"ApproachRocket") return false end
  local item,reason=Rules.validate(ctx.bag(player),value.planet,value.itemId,ctx.catalog,ctx.modelReady)
  if not item then result(player,false,reason) return false end
  if not ctx.courseReady() then result(player,false,"CoursePending") return false end
  -- Revalidate the live bag immediately before launch, and consume the menu
  -- only after a successful hunt creation. A failed launch can be retried.
  local ok=ctx.launch(player,item.id)==true
  if ok then pending[player]=nil end
  result(player,ok,ok and nil or "LaunchFailed")
  return ok
 end
 function api.cancel(player) pending[player]=nil end
 function api.remove(player) pending[player],lastSubmit[player]=nil,nil end
 return api
end
return Service
]====])
add(captureClient.Parent,"LocalScript","RocketDeparture",[====[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local remote=package:WaitForChild("CaptureRemote")
local Catalog=require(package:WaitForChild("MonsterCatalog"))
local L=require(package:WaitForChild("Localization"))
local function make(class,props,parent)
 local p=Instance.new(class) for key,value in pairs(props) do p[key]=value end p.Parent=parent return p
end
local gui=make("ScreenGui",{Name="RocketDepartureUI",ResetOnSpawn=false,DisplayOrder=40,Enabled=false},player:WaitForChild("PlayerGui"))
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
  local name=id=="MeadowMouse" and "모스랫" or Catalog[id] and L.text(Catalog[id].Template:gsub("Template$",""),player.LocaleId) or tostring(id)
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
 elseif action=="DepartureResult" and gui.Enabled then
  busy=false
  if data.ok then hide(false) else status.Text=messages[data.reason] or "출발할 수 없어요. 다시 선택해 주세요." end
 elseif action=="State" and data.area=="Hunt" then hide(false) end
end)
]====])
local rocket=assert(imported:Clone(),"로켓 복제 실패")
rocket.Name="Rocket" rocket:SetAttribute("UserRocketDepartureV1",true)
local _,size=rocket:GetBoundingBox()
assert(size.Y>0 and size.Y<math.huge,"로켓 높이를 계산할 수 없습니다.")
rocket:ScaleTo(rocket:GetScale()*(18/.28)/size.Y)
local box,scaled=rocket:GetBoundingBox()
local center=Vector3.new(point.Position.X,2+scaled.Y/2,0)
rocket:PivotTo(CFrame.new(center-box.Position)*rocket:GetPivot())
for _,p in ipairs(rocket:GetDescendants()) do
 if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false end
end
local pad=Instance.new("Part") pad.Name="RocketStudPad" pad.Size=Vector3.new(64,4,64)
pad.Position=Vector3.new(center.X,0,0) pad.Anchored=true pad.Material=Enum.Material.Plastic
pad.Color=Color3.fromRGB(27,63,78) pad.TopSurface=Enum.SurfaceType.Studs pad.BottomSurface=Enum.SurfaceType.Inlet
for _,face in ipairs({"FrontSurface","BackSurface","LeftSurface","RightSurface"}) do pad[face]=Enum.SurfaceType.Studs end
pad.CanTouch=false
local backup=Instance.new("Folder") backup.Name="RocketDepartureBackup_"..tostring(os.time())
local airportCopy=assert(airport:Clone(),"기존 출발 구역 백업 실패") airportCopy.Parent=backup
for _,u in ipairs(updates) do local saved=u.node:Clone() saved.Name=u.node.Name.."BeforeRocket" saved.Parent=backup end
local removed=Instance.new("Folder") removed.Name="OriginalDepartureContents" removed.Parent=backup
local shipContents=Instance.new("Folder") shipContents.Name="AirshipContents" shipContents.Parent=removed
local airportContents=Instance.new("Folder") airportContents.Name="AirportContents" airportContents.Parent=removed
local moved={}
for _,p in ipairs(airship:GetChildren()) do table.insert(moved,{node=p,parent=airship,to=shipContents}) end
for _,p in ipairs(airport:GetChildren()) do
 if p~=airship and p~=point then table.insert(moved,{node=p,parent=airport,to=airportContents}) end
end
local oldPoint,oldFlag=point.CFrame,airship:GetAttribute("RocketDepartureActive")
local originalParent=imported.Parent
game:GetService("ChangeHistoryService"):SetWaypoint("Before user rocket departure")
local ok,err=pcall(function()
 backup.Parent=storage
 for _,u in ipairs(updates) do u.node.Source=u.after end
 for _,a in ipairs(additions) do a.node.Parent=a.parent end
 -- Keep just the compatibility Model and prompt point in Workspace.
 -- Archived meshes do not replicate with the replacement rocket.
 for _,p in ipairs(moved) do p.node.Parent=p.to end
 airship:SetAttribute("RocketDepartureActive",true)
 point.CFrame=CFrame.new(center.X,4,-20)
 rocket.Parent=airport pad.Parent=airport imported.Parent=backup
 -- Do not mark the old course or old monsters as approved new content.
end)
if not ok then
 for _,u in ipairs(updates) do u.node.Source=u.before end
 for _,a in ipairs(additions) do a.node:Destroy() end
 for _,p in ipairs(moved) do p.node.Parent=p.parent end
 point.CFrame=oldPoint airship:SetAttribute("RocketDepartureActive",oldFlag)
 imported.Parent=originalParent rocket:Destroy() pad:Destroy() backup:Destroy()
 error(err,0)
end
game:GetService("ChangeHistoryService"):SetWaypoint("After user rocket departure")
game:GetService("Selection"):Set({rocket})
print("ROCKET_DEPARTURE_PREPARED: 로켓 E 1초 → Green Star → 보유 몬스터. 새 몬스터·숲 런타임 연결 전에는 출발 준비 중으로 표시합니다.")
