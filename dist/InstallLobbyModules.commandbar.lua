-- Import the four complete Models once; reuse their uploaded meshes/textures in all rooms.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하고 실행하세요.")
local lobby=assert(workspace:FindFirstChild("RodeoLobby"),"RodeoLobby 없음")
local sources={}
for _,key in ipairs({"Incubator","Door","Console","Planet"}) do
 local source=assert(workspace:FindFirstChild(key.."Import"),key.."Import 전체 모델을 먼저 가져오세요.")
 assert(source:IsA("Model"),key.."Import는 Model이어야 합니다.")
 local count=0
 for _,n in ipairs(source:GetDescendants()) do
  assert(not n:IsA("LuaSourceContainer"),"입력 모델에 스크립트가 있습니다: "..key)
  if n:IsA("MeshPart") then assert(n.MeshId~="","업로드된 메시가 필요합니다: "..key) count+=1 end
 end
 assert(count>0,"MeshPart 없음: "..key) sources[key]=source
end
local prepared={}
local function clone(key,parent,name,height,target)
 local copy=assert(sources[key]:Clone(),"복제 실패") copy.Name=name
 local _,size=copy:GetBoundingBox() assert(size.Y>0,"모델 높이 오류") copy:ScaleTo(copy:GetScale()*height/size.Y)
 local box=copy:GetBoundingBox() copy:PivotTo(target*box:Inverse()*copy:GetPivot())
 for _,p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end end
 table.insert(prepared,{node=copy,parent=parent}) return copy
end
local old,doors={},{ }
local markers={}
for i=1,8 do
 local room=assert(lobby.Plots:FindFirstChild("Plot_"..i),"부화실 없음")
 local pen=assert(room.Pens:FindFirstChild("Pen_1"),"부화소 없음")
 local grass=assert(pen:FindFirstChild("PenGrass"),"부화소 기준점 없음")
 table.insert(markers,{grass,grass.Transparency,grass.CanCollide})
 local floor=room.RoomBase.Position.Y+room.RoomBase.Size.Y/2
 clone("Incubator",pen,"UserIncubator",16,CFrame.new(grass.Position.X,floor+8,grass.Position.Z)*grass.CFrame.Rotation)
 for _,n in ipairs(pen:GetChildren()) do
  if n:IsA("BasePart") and n.Name~="PenGrass" or n.Name=="UserIncubator" then table.insert(old,{n,n.Parent}) end
 end
 local l,r=room.DoorLeft,room.DoorRight
 local middle=(l.Position+r.Position)/2
 local axis=l.CFrame.Rotation
 local frame=CFrame.new(middle.X,floor+10,middle.Z)*axis
 clone("Door",room,"UserDoorFrame",20,frame)
 clone("Console",room,"UserDoorConsole",5,frame*CFrame.new(18,-7.5,-4))
 for _,name in ipairs({"UserDoorFrame","UserDoorConsole"}) do local n=room:FindFirstChild(name) if n then table.insert(old,{n,n.Parent}) end end
 for _,row in ipairs({{l,-1},{r,1}}) do
  local p=row[1]
  table.insert(doors,{p,p.CFrame,p.Size,p.Color,p.Material,p.CanCollide,p.Transparency})
  row.target=CFrame.new(middle.X,floor+7.5,middle.Z)*axis*CFrame.new(row[2]*2.3,0,0)
  doors[#doors].target=row.target
 end
end
clone("Planet",lobby,"CeilingPlanet",72,CFrame.new(6070,225,35)*CFrame.Angles(0,math.rad(-20),math.rad(-10)))
local planet=lobby:FindFirstChild("CeilingPlanet") if planet then table.insert(old,{planet,planet.Parent}) end
local backup=Instance.new("Folder") backup.Name="LobbyModulesBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game:GetService("ServerStorage")
lobby:Clone().Parent=backup
game:GetService("ChangeHistoryService"):SetWaypoint("Before supplied lobby models")
local added={}
local ok,err=pcall(function()
 for _,row in ipairs(old) do row[1].Parent=backup end
 for _,row in ipairs(prepared) do row.node.Parent=row.parent end
 for _,row in ipairs(markers) do row[1].Transparency=1 row[1].CanCollide=false end
 for _,row in ipairs(doors) do
  local p=row[1] p.CFrame=row.target p.Size=Vector3.new(4.6,15,.5) p.Color=Color3.fromRGB(40,56,75) p.Material=Enum.Material.Metal p.CanCollide=false p.Transparency=0
  if not p:FindFirstChild("DoorTrim") then
   local gui=Instance.new("SurfaceGui") gui.Name="DoorTrim" gui.Face=Enum.NormalId.Front gui.Parent=p table.insert(added,gui)
   local stripe=Instance.new("Frame") stripe.Size=UDim2.new(.08,0,.85,0) stripe.Position=UDim2.fromScale(.46,.075) stripe.BackgroundColor3=Color3.fromRGB(94,226,255) stripe.BorderSizePixel=0 stripe.Parent=gui
  end
 end
 for _,source in pairs(sources) do table.insert(old,{source,source.Parent}) source.Parent=backup end
end)
if not ok then
 for _,row in ipairs(prepared) do row.node:Destroy() end
 for _,n in ipairs(added) do n:Destroy() end
 for _,row in ipairs(old) do row[1].Parent=row[2] end
 for _,row in ipairs(doors) do local p=row[1] p.CFrame=row[2] p.Size=row[3] p.Color=row[4] p.Material=row[5] p.CanCollide=row[6] p.Transparency=row[7] end
 for _,row in ipairs(markers) do row[1].Transparency=row[2] row[1].CanCollide=row[3] end
 backup:Destroy() error("설치 실패, 이전 상태 복원: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Supplied lobby models installed")
print("LOBBY_MODULES_INSTALLED — 부화기8/문틀8/콘솔8/천장행성1. Ctrl+S 저장 후 Play.")
