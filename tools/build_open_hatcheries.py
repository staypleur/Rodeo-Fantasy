"""Narrow edit-mode installer; never rebuilds the user's saved place."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def long(s):
    assert ']========]' not in s
    return '[========['+s+']========]'
rows=[]
for path,parent,name in [('src/server/LobbyWorld.luau','server','LobbyWorld'),('src/client/BagUI.luau','clients','BagUI'),('src/shared/LobbyIncubatorRules.luau','shared','LobbyIncubatorRules'),('src/server/CaptureServer.server.luau','server','CaptureServer')]:
    before=subprocess.check_output(['git','show','d1a33f1:'+path],cwd=R).decode('utf-8')
    after=(R/path).read_text(encoding='utf-8')
    rows.append('{parent='+parent+',name="'+name+'",before='+long(before)+',after='+long(after)+'}')
code='''do
-- Remove supplied room machinery; preserve room shells, planet, rocket and inventory.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"RodeoLobby 없음")
local shared=game.ReplicatedStorage.RodeoFantasy
local server=game:GetService("ServerScriptService")
local clients=game.StarterPlayer.StarterPlayerScripts
local function normal(s) return s:gsub("\\r\\n","\\n") end
local changes={'''+','.join(rows)+'''}
for _,c in ipairs(changes) do
 c.node=assert(c.parent:FindFirstChild(c.name),c.name.." 없음")
 assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"별도 변경된 코드: "..c.name)
 c.original=c.node.Source
end
local builder=(function()
'''+(R/'src/authoring/OpenHatcheryStands.luau').read_text(encoding='utf-8')+'''
end)()
local prepared={}
for i=1,8 do
 local room=assert(lobby.Plots:FindFirstChild("Plot_"..i),"부화실 없음")
 assert(room.Pens and room.RoomBase,"부화실 기준점 없음")
 table.insert(prepared,{room=room,pens=builder.build(room)})
end
local backup=Instance.new("Folder") backup.Name="OpenHatcheryBackup_"..game:GetService("HttpService"):GenerateGUID(false)
local moved={}
local targets={BabyCapsules=true,UserIncubator=true,UserDoorFrame=true,UserDoorConsole=true,DoorLeft=true,DoorRight=true,DoorSensor=true,SpaceLobbyDoors=true,ControlPedestal=true,IncubatorConsole=true,ConsoleBar=true,EggStatus=true}
local function archive(n)
 table.insert(moved,{node=n,parent=n.Parent}) n.Parent=backup
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before four open hatcheries")
local ok,err=pcall(function()
 backup.Parent=game.ServerStorage
 for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
 for _,row in ipairs(prepared) do
  local old=row.room.Pens
  -- Retain any edit-mode egg displays without duplicating inventory.
  for _,pen in ipairs(old:GetChildren()) do
   local target=row.pens:FindFirstChild(pen.Name)
   local display=pen:FindFirstChild("DisplayEggs")
   if target and display and pen:FindFirstChild("PenGrass") then
    local copy=display:Clone()
    local shift=target.PenGrass.CFrame*pen.PenGrass.CFrame:Inverse()
    for _,p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.CFrame=shift*p.CFrame end end
    copy.Parent=target
   end
  end
  archive(old) row.pens.Parent=row.room
  for _,n in ipairs(row.room:GetChildren()) do if targets[n.Name] then archive(n) end end
 end
 local doors=lobby:FindFirstChild("SpaceLobbyDoors") if doors then archive(doors) end
 for _,name in ipairs({"IncubatorImport","DoorImport","ConsoleImport","IncubatorTextureDiagnostic"}) do
  local n=workspace:FindFirstChild(name) if n then archive(n) end
 end
 lobby:SetAttribute("OpenHatcheriesInstalled",true)
end)
if not ok then
 for _,row in ipairs(prepared) do row.pens:Destroy() end
 for i=#moved,1,-1 do moved[i].node.Parent=moved[i].parent end
 for _,c in ipairs(changes) do c.node.Source=c.original end
 backup:Destroy() error("설치 복구: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Four open hatcheries installed")
local count=0
for _,row in ipairs(prepared) do assert(#row.pens:GetChildren()==4) count+=4 end
print("OPEN_HATCHERIES_INSTALLED — 8개 방 / 열린 알 받침 32개 / 캡슐·문·콘솔 제거. 원본은 ServerStorage 백업. Ctrl+S 저장.")
game:GetService("Selection"):Set({prepared[1].room})
local base=prepared[1].room.RoomBase
local center=base.Position+Vector3.new(0,3,0)
workspace.CurrentCamera.CFrame=CFrame.lookAt(center+base.CFrame:VectorToWorldSpace(Vector3.new(0,24,-42)),center)
workspace.CurrentCamera.Focus=CFrame.new(center)
end
'''
(R/'dist/InstallOpenHatcheries.commandbar.lua').write_text(code,encoding='utf-8')
print('OPEN_HATCHERIES_INSTALLER_BUILT')
