"""Prepare an import-based installer; never overwrite the user's dirty place/server."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SERVER_PATCHES=[
 ('local tuning=Config.Prototype', '''local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end'''),
 ('if not root or not humanoid or humanoid.Health<=0 then return end\n if not previous and not Lobby.canDepart(player)', '''if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player)'''),
 ('Lobby.connect(function(p) if not Store.busy(p) and not p:GetAttribute("Travelling") then start(p) end end)', '''local departure=require(script.Parent.RocketDepartureService).new({
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
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil end)'''),
]
CLIENT_PATCHES=[
 ('require(script.Parent:WaitForChild("SkyWhaleRuntime")).install(airship)',
  'if not airship:GetAttribute("RocketDepartureActive") then require(script.Parent:WaitForChild("SkyWhaleRuntime")).install(airship) end'),
 ('local function animateShip(clock)', 'local function animateShip(clock)\n if airship:GetAttribute("RocketDepartureActive") then return end'),
]
LOBBY_PATCHES=[('prompt.ActionText="Fly to hunt" prompt.ObjectText="Airship"','prompt.ActionText="행성 선택" prompt.ObjectText="로켓"')]
def patch(source,patches):
 source=source.replace('\r\n','\n')
 for old,new in patches:
  if new in source: raise ValueError('Integration patch is already present')
  if source.count(old)!=1: raise ValueError('Source does not match the reviewed integration anchor: '+old[:80])
  source=source.replace(old,new,1)
 return source
def long(value):
 assert ']====]' not in value
 return '[====['+value+']====]'
def build():
 code=['''-- Edit mode only. Import the user's GLB as Workspace.RocketImport first.
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
 if not entry then entry={node=node,before=node.Source,after=node.Source:gsub("\\r\\n","\\n")} table.insert(updates,entry) end
 assert(not string.find(entry.after,new,1,true),"이미 일부 연결된 코드입니다. 중복 적용을 중단합니다.")
 local first,last=string.find(entry.after,old,1,true)
 assert(first and not string.find(entry.after,old,last+1,true),"코드 버전이 달라 자동 연결을 중단합니다. 기존 코드는 보존됩니다.")
 entry.after=entry.after:sub(1,first-1)..new..entry.after:sub(last+1)
end
local captureServer=server:FindFirstChild("CaptureServer",true)
local captureClient=scripts:FindFirstChild("CaptureClient",true)
local lobbyWorld=server:FindFirstChild("LobbyWorld",true)
assert(captureServer and captureClient and lobbyWorld,"CaptureServer/CaptureClient/LobbyWorld를 찾을 수 없습니다.")''']
 for node,patches in [('captureServer',SERVER_PATCHES),('captureClient',CLIENT_PATCHES),('lobbyWorld',LOBBY_PATCHES)]:
  for old,new in patches: code.append(f'prepare({node},{long(old)},{long(new)})')
 code.append('local additions={}\nlocal function add(parent,class,name,source)\n assert(not parent:FindFirstChild(name),"이미 있는 연결 모듈: "..name)\n local node=Instance.new(class) node.Name=name node.Source=source\n table.insert(additions,{node=node,parent=parent})\nend')
 for parent,kind,name,path in [
  ('package','ModuleScript','DepartureSelectionRules','src/shared/DepartureSelectionRules.luau'),
  ('captureServer.Parent','ModuleScript','RocketDepartureService','src/server/RocketDepartureService.luau'),
  ('captureClient.Parent','LocalScript','RocketDeparture','src/client/RocketDeparture.client.luau')]:
  # Existing rules can be reused only when the exact reviewed implementation matches.
  source=(ROOT/path).read_text(encoding='utf-8')
  if name=='DepartureSelectionRules':
   code.append(f'if package:FindFirstChild("{name}") then assert(package.{name}.Source:gsub("\\r\\n","\\n")=={long(source)},"선택 규칙 버전이 다릅니다.") else add({parent},"{kind}","{name}",{long(source)}) end')
  else: code.append(f'add({parent},"{kind}","{name}",{long(source)})')
 code.append('''local rocket=assert(imported:Clone(),"로켓 복제 실패")
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
print("ROCKET_DEPARTURE_PREPARED: 로켓 E 1초 → Green Star → 보유 몬스터. 새 몬스터·숲 런타임 연결 전에는 출발 준비 중으로 표시합니다.")''')
 out=ROOT/'dist/ReviewModels/InstallUserRocket.commandbar.lua'
 out.write_text('\n'.join(code)+'\n',encoding='utf-8')
 print(out.name)
if __name__=='__main__': build()
