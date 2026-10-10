"""Apply only the approved room/shell/board cleanup to the live saved lobby."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def long(s): return '[========['+s+']========]'
world=(R/'src/server/LobbyWorld.luau').read_text(encoding='utf-8')
prior=world.replace('local board=plots["Plot_"..index]:FindFirstChild("OwnerBoard")\n if not board then return end','local board=plots["Plot_"..index].OwnerBoard')
ranking=(R/'src/server/LobbyRankings.luau').read_text(encoding='utf-8')
oldranking=subprocess.check_output(['git','show','d1a33f1:src/server/LobbyRankings.luau'],cwd=R).decode('utf-8')
presentation=(R/'src/server/LobbyPresentation.server.luau').read_text(encoding='utf-8')
oldpresentation=subprocess.check_output(['git','show','d1a33f1:src/server/LobbyPresentation.server.luau'],cwd=R).decode('utf-8')
code='''do
assert(not game:GetService("RunService"):IsRunning(),"Play 중지")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"로비 없음")
assert(lobby:GetAttribute("OpenHatcheriesInstalled"),"열린 부화소를 먼저 설치하세요.")
local server=game.ServerScriptService
local function normal(s) return s:gsub("\\r\\n","\\n") end
local changes={
{node=server.LobbyWorld,before='''+long(prior)+''',after='''+long(world)+'''},
{node=server.LobbyRankings,before='''+long(oldranking)+''',after='''+long(ranking)+'''},
{node=server.LobbyPresentation,before='''+long(oldpresentation)+''',after='''+long(presentation)+'''}
}
for _,c in ipairs(changes) do assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"코드가 달라 중단: "..c.node.Name) c.original=c.node.Source end
local backup=Instance.new("Folder") backup.Name="LobbyCleanupBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
local moved,added,properties={},{},{}
local function archive(n) if n then table.insert(moved,{n,n.Parent}) n.Parent=backup end end
local function set(n,key,value) table.insert(properties,{n,key,n[key]}) n[key]=value end
local function block(parent,name,size,cf,color)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Reflectance=0 p.Parent=parent table.insert(added,p) return p
end
local planet=lobby:FindFirstChild("CeilingPlanet")
local planetOld=planet and {scale=planet:GetScale(),pivot=planet:GetPivot()}
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby cleanup")
local ok,err=pcall(function()
 for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
 for _,name in ipairs({"Roof","Amenities","SpaceDiorama","ShipShell","SolidShipWalls"}) do archive(lobby:FindFirstChild(name)) end
 local shell=Instance.new("Model") shell.Name="SolidShipWalls" shell.Parent=lobby table.insert(added,shell)
 local color=Color3.fromRGB(56,69,86)
 block(shell,"WallNorth",Vector3.new(496,80,8),CFrame.new(6000,42,-252),color)
 block(shell,"WallSouth",Vector3.new(496,80,8),CFrame.new(6000,42,252),color)
 block(shell,"WallEast",Vector3.new(8,80,512),CFrame.new(6252,42,0),color)
 block(shell,"WallWest",Vector3.new(8,80,512),CFrame.new(5748,42,0),color)
 -- Opaque backing stops sky showing through the octagonal tile seams.
 local floor=assert(lobby:FindFirstChild("LobbyCollisionFloor"),"안전 바닥 없음")
 set(floor,"Transparency",0) set(floor,"Color",Color3.fromRGB(62,77,99))
 set(floor,"Material",Enum.Material.SmoothPlastic) set(floor,"Reflectance",0)
 set(floor,"Size",Vector3.new(512,4,512)) set(floor,"CFrame",CFrame.new(6000,-.15,0)) set(floor,"CanCollide",true)
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  local base=room.RoomBase local top=base.Position.Y+base.Size.Y/2
  local origin=CFrame.new(base.Position.X,top,base.Position.Z)*base.CFrame.Rotation
  local board=room:FindFirstChild("OwnerBoard") local label=board and board:FindFirstChildWhichIsA("TextLabel",true)
  local existingGlow=room.Pens.Pen_1:FindFirstChild("StandGlow")
  local accent=label and label.TextColor3 or existingGlow and existingGlow.Color or Color3.fromRGB(69,167,172)
  for _,pen in ipairs(room.Pens:GetChildren()) do local glow=pen:FindFirstChild("StandGlow") if glow then set(glow,"Color",accent) end end
  for _,n in ipairs(room:GetChildren()) do
   if ({RoomRoof=true,OwnerBoard=true,Planter=true,Stem=true,LeafPlate=true,SideWall=true,RearWall=true,FrontWall=true,SolidRoomWalls=true})[n.Name] then archive(n) end
  end
  local walls=Instance.new("Model") walls.Name="SolidRoomWalls" walls.Parent=room table.insert(added,walls)
  local c=Color3.fromRGB(180,191,198)
  -- Butt joints meet exactly, without duplicate coplanar faces. Opening width 28.
  for _,x in ipairs({-39,39}) do block(walls,"SideWall",Vector3.new(2,32,80),origin*CFrame.new(x,16,0),c) end
  block(walls,"RearWall",Vector3.new(76,32,2),origin*CFrame.new(0,16,39),c)
  for _,x in ipairs({-26,26}) do block(walls,"FrontWall",Vector3.new(24,32,2),origin*CFrame.new(x,16,-39),c) end
 end
 if planet then
  local _,size=planet:GetBoundingBox()
  planet:ScaleTo(planet:GetScale()*360/math.max(size.X,size.Y,size.Z))
  local box=planet:GetBoundingBox()
  planet:PivotTo(CFrame.new(Vector3.new(6000,330,60)-box.Position)*planet:GetPivot())
  for _,p in ipairs(planet:GetDescendants()) do if p:IsA("BasePart") then set(p,"CanCollide",false) set(p,"CanTouch",false) set(p,"CanQuery",false) end end
 end
 -- Remove decorative signs; ranking entries remain functional.
 local title=lobby.Airport:FindFirstChild("GameTitle") if title then archive(title) end
 for _,n in ipairs(lobby:GetDescendants()) do
  if n:IsA("BasePart") then
   if n.Reflectance~=0 then set(n,"Reflectance",0) end
   if n.Material~=Enum.Material.Neon and n.Material~=Enum.Material.Glass then set(n,"TopSurface",Enum.SurfaceType.Smooth) set(n,"BottomSurface",Enum.SurfaceType.Smooth) end
  end
 end
 local rankings=(function()
'''+ranking+'''
end)()
 local boards=lobby:FindFirstChild("Leaderboards")
 for _,n in ipairs(boards:GetChildren()) do
  table.insert(properties,{n,"Size",n.Size}) table.insert(properties,{n,"CFrame",n.CFrame})
  local gui=n:FindFirstChild("Ranking") if gui then table.insert(properties,{gui,"Face",gui.Face}) end
 end
 rankings.ensure(lobby)
 lobby:SetAttribute("LobbyCleanupInstalled",true)
end)
if not ok then
 for i=#properties,1,-1 do local r=properties[i] r[1][r[2]]=r[3] end
 for i=#added,1,-1 do added[i]:Destroy() end
 for i=#moved,1,-1 do moved[i][1].Parent=moved[i][2] end
 for _,c in ipairs(changes) do c.node.Source=c.original end
 if planetOld then planet:ScaleTo(planetOld.scale) planet:PivotTo(planetOld.pivot) end
 backup:Destroy() error("정리 실패·복원: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby cleanup complete")
game:GetService("Selection"):Set({})
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(6000,50,-95),Vector3.new(6000,16,0)) workspace.CurrentCamera.Focus=CFrame.new(6000,16,0)
print("LOBBY_CLEANUP_INSTALLED — 천장·나무·장식 간판 제거 / 벽 이음새·바닥 메움 / 랭킹 로켓 양옆 / 행성 최대 폭360. Ctrl+S 저장.")
end
'''
(R/'dist/CleanupLobby.commandbar.lua').write_text(code,encoding='utf-8')
print('LOBBY_CLEANUP_BUILT')
