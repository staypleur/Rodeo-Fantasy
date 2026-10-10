"""Preserve the user's uploaded models, colors and lobby while applying current fixes."""
from pathlib import Path
import subprocess,json
R=Path(__file__).resolve().parents[1]
def long(s):return '[========['+s+']========]'
rows=[]
for path,parent,new in [('src/server/LobbyWorld.luau','server',False),('src/server/CaptureServer.server.luau','server',False),('src/client/NativeMossrat.luau','clients',False),('src/client/UserMossratRigAnimator.luau','clients',False),('src/server/LobbyPresentation.server.luau','server',True),('src/server/LobbyRankings.luau','server',True),('src/server/RecordService.luau','server',False),('src/client/LobbyMenus.luau','clients',True),('src/client/CaptureClient.client.luau','clients',False),('src/client/HudIcons.luau','clients',True),('src/client/HudStats.luau','clients',True),('src/client/SettingsUI.luau','clients',False),('src/client/BagUI.luau','clients',False),('src/client/SocialUI.luau','clients',False)]:
 p=R/path;after=p.read_text(encoding='utf-8');allowed=[after]
 for rev in ['0c0f1db','57d4c74','78cb6bc','cbbb822','b0c9be0']:
  old=subprocess.run(['git','show',rev+':'+path],cwd=R,capture_output=True)
  if old.returncode==0:allowed.append(old.stdout.decode('utf-8'))
 kind='Script' if p.name.endswith('.server.luau') else 'LocalScript' if p.name.endswith('.client.luau') else 'ModuleScript'
 rows.append('{parent='+parent+',name='+json.dumps(p.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau'))+',kind='+json.dumps(kind)+',new='+str(new).lower()+',after='+long(after)+',allowed={'+','.join(long(s) for s in allowed)+'}}')
code='''assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"RodeoLobby 없음")
local shared=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"시스템 없음")
local server=game:GetService("ServerScriptService")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local changes={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name)
 if c.node then
  assert(c.node.ClassName==c.kind,"종류 불일치: "..c.name)
  local valid=false for _,s in ipairs(c.allowed) do if norm(s)==norm(c.node.Source) then valid=true break end end
  assert(valid,"다른 코드가 있어 중단: "..c.name) c.before=c.node.Source
 else assert(c.new,"코드 없음: "..c.name) end
end
local backup=Instance.new("Folder") backup.Name="LobbyHuntFixBackup_"..game:GetService("HttpService"):GenerateGUID(false)
backup.Parent=game:GetService("ServerStorage")
lobby:Clone().Parent=backup
local parts,pivots,texts,removed,made,rankingFaces={},{},{},{},{},{}
local leftovers={InstalledMossratPreview=true,InstalledRocketPreview=true,MossratImport=true,MossratMeshOnly=true,MossratS1Rigged=true,Mossrat=true,RocketImport=true,Rocket=true}
for _,n in ipairs(workspace:GetChildren()) do
 if leftovers[n.Name] and n:IsA("Model") and n:FindFirstChildWhichIsA("MeshPart",true) then table.insert(removed,{n,n.Parent}) end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before lobby and hunt fixes")
local ok,err=pcall(function()
 for _,c in ipairs(changes) do
  if c.node then c.node:Clone().Parent=backup else c.node=Instance.new(c.kind) c.node.Name=c.name c.node.Parent=c.parent table.insert(made,c.node) end
  c.node.Source=c.after
 end
 for _,p in ipairs(lobby:GetDescendants()) do
  if p:IsA("Part") then
   table.insert(parts,{p,p.Material,p.TopSurface,p.BottomSurface,p.FrontSurface,p.BackSurface,p.LeftSurface,p.RightSurface,p.Transparency,p.CanCollide,p.Color})
   p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.FrontSurface=Enum.SurfaceType.Smooth p.BackSurface=Enum.SurfaceType.Smooth p.LeftSurface=Enum.SurfaceType.Smooth p.RightSurface=Enum.SurfaceType.Smooth
   if p.Material==Enum.Material.Plastic then p.Material=Enum.Material.SmoothPlastic end
  end
 end
 local oldBoards=lobby:FindFirstChild("Leaderboards")
 if oldBoards then
  for _,b in ipairs(oldBoards:GetChildren()) do if b:IsA("BasePart") or b:IsA("Model") then table.insert(pivots,{b,b:GetPivot(),b:IsA("BasePart") and b.Size,b:IsA("BasePart") and b.CanCollide,b:IsA("BasePart") and b.CanTouch,b:IsA("BasePart") and b.CanQuery}) end end
 else
  oldBoards=Instance.new("Folder") oldBoards.Name="Leaderboards" oldBoards.Parent=lobby table.insert(made,oldBoards)
 end
 local oldChildren={} for _,b in ipairs(oldBoards:GetChildren()) do oldChildren[b]=true end
 for _,b in ipairs(oldBoards:GetChildren()) do local gui=b:FindFirstChild("Ranking") if gui then table.insert(rankingFaces,{gui,gui.Face}) end end
 local rankings=assert(loadstring(server.LobbyRankings.Source))()
 rankings.ensure(lobby)
 for _,b in ipairs(oldBoards:GetChildren()) do if not oldChildren[b] then table.insert(made,b) end end
 local rocket=lobby.Airport:FindFirstChild("Rocket")
 local center=Vector3.new(6000,0,0)
 if rocket and rocket:IsA("Model") then local box=rocket:GetBoundingBox() center=Vector3.new(box.X,0,box.Z) end
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  local base=room:FindFirstChild("RoomBase") local sensor=room:FindFirstChild("DoorSensor")
  if base and sensor then
   table.insert(pivots,{room,room:GetPivot()})
   local origin=base.Position
   local offset=sensor.Position-origin local towards=center-origin
   local delta=math.atan2(towards.X,towards.Z)-math.atan2(offset.X,offset.Z)
   room:PivotTo(CFrame.new(origin)*CFrame.Angles(0,delta,0)*CFrame.new(-origin)*room:GetPivot())
  end
  local board=room:FindFirstChild("OwnerBoard")
  if board then for _,t in ipairs(board:GetDescendants()) do if t:IsA("TextLabel") then table.insert(texts,{t,t.Text}) t.Text="" end end end
 end
 local sign=lobby.Airport:FindFirstChild("DepartureSign")
 if sign then table.insert(removed,{sign,sign.Parent}) end
 local diorama=lobby:FindFirstChild("SpaceDiorama")
 if diorama then for _,p in ipairs(diorama:GetDescendants()) do if p.Name=="PlanetLayer" or p.Name=="PlanetRing" then table.insert(removed,{p,p.Parent}) end end end
 if not lobby:FindFirstChild("LobbyCollisionFloor") then
  local floor=Instance.new("Part") floor.Name="LobbyCollisionFloor" floor.Size=Vector3.new(512,4,512) floor.Position=Vector3.new(6000,0,0)
  floor.Anchored=true floor.Transparency=1 floor.CanCollide=true floor.CanTouch=false floor.CollisionGroup="Default" floor.Parent=lobby table.insert(made,floor)
 end
 for _,row in ipairs(removed) do row[1].Parent=backup end
 local roof=lobby:FindFirstChild("Roof")
 if not roof then roof=Instance.new("Model") roof.Name="Roof" roof.Parent=lobby table.insert(made,roof) end
 for _,p in ipairs(roof:GetChildren()) do if p.Name=="Ceiling" or p.Name=="FullOpaqueCeiling" then table.insert(removed,{p,p.Parent}) p.Parent=backup end end
 if not roof:FindFirstChild("FullGlassCeiling") then
  local cap=Instance.new("Part") cap.Name="FullGlassCeiling" cap.Size=Vector3.new(512,2,512) cap.Position=Vector3.new(6000,102,0)
  cap.Anchored=true cap.CanTouch=false cap.Material=Enum.Material.Glass cap.Transparency=.65 cap.Color=Color3.fromRGB(173,212,232)
  cap.TopSurface=Enum.SurfaceType.Smooth cap.BottomSurface=Enum.SurfaceType.Smooth cap.Parent=roof table.insert(made,cap)
 end
 for _,p in ipairs(lobby.ShipShell:GetDescendants()) do if p:IsA("BasePart") and p.Name=="WindowSpace" then p.Material=Enum.Material.Metal p.Transparency=0 p.CanCollide=true p.Color=Color3.fromRGB(62,78,103) end end

end)
if not ok then
 for _,row in ipairs(removed) do row[1].Parent=row[2] end
 for _,row in ipairs(pivots) do row[1]:PivotTo(row[2]) if row[3] then row[1].Size=row[3] row[1].CanCollide=row[4] row[1].CanTouch=row[5] row[1].CanQuery=row[6] end end
 for _,row in ipairs(texts) do row[1].Text=row[2] end
 for _,row in ipairs(rankingFaces) do row[1].Face=row[2] end
 for _,r in ipairs(parts) do local p=r[1] p.Material=r[2] p.TopSurface=r[3] p.BottomSurface=r[4] p.FrontSurface=r[5] p.BackSurface=r[6] p.LeftSurface=r[7] p.RightSurface=r[8] p.Transparency=r[9] p.CanCollide=r[10] p.Color=r[11] end
 for _,c in ipairs(changes) do if c.before then c.node.Source=c.before end end
 for _,n in ipairs(made) do n:Destroy() end
 backup:Destroy() error("기존 상태 복원 완료: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Lobby and hunt fixes installed")
print("LOBBY_HUNT_FIXES_INSTALLED — Ctrl+S 저장 후 Play. 미리보기 정리 수:",#removed)
'''
(R/'dist/FixCurrentLobbyHunt.commandbar.lua').write_text(code,encoding='utf-8')
print('CURRENT_LOBBY_HUNT_FIXES_BUILT')
