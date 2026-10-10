-- Edit mode only. Import the complete model as Workspace.RocketImport first.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local lobby=workspace:FindFirstChild("RodeoLobby") or workspace:FindFirstChild("SmoothLobbyDesignDraft")
assert(lobby,"로비가 없습니다.")
local airport=assert(lobby:FindFirstChild("Airport"),"Airport 없음")
local departure=assert(airport:FindFirstChild("Departure"),"출발 지점 없음")
local source=assert(workspace:FindFirstChild("RocketImport"),"가져온 전체 모델 이름을 RocketImport로 바꾸세요.")
assert(source:IsA("Model"),"RocketImport는 Model이어야 합니다.")
local meshes=0
for _,p in ipairs(source:GetDescendants()) do
 assert(not p:IsA("LuaSourceContainer"),"입력 모델에 스크립트를 넣지 마세요.")
 if p:IsA("MeshPart") then assert(p.MeshId~="","메시 업로드가 필요합니다.") meshes+=1 end
end
assert(meshes>0,"MeshPart가 없습니다.")
local copy=assert(source:Clone(),"복제 실패") copy.Name="Rocket"
local old=airport:FindFirstChild("Rocket")
local oldBox,oldSize
if old and old:IsA("Model") then oldBox,oldSize=old:GetBoundingBox() end
local center=oldBox and oldBox.Position or Vector3.new(departure.Position.X,46,departure.Position.Z+34)
local height=oldSize and oldSize.Y or 68
local box,size=copy:GetBoundingBox()
assert(size.Y>0 and height>0,"모델 높이 오류")
copy:ScaleTo(copy:GetScale()*height/size.Y)
box,size=copy:GetBoundingBox()
copy:PivotTo(CFrame.new(center-box.Position)*copy:GetPivot())
for _,p in ipairs(copy:GetDescendants()) do
 if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end
end
copy:SetAttribute("SuppliedCentralRocket",true)
local backup=Instance.new("Folder") backup.Name="CentralRocketBackup_"..game:GetService("HttpService"):GenerateGUID(false)
game:GetService("ChangeHistoryService"):SetWaypoint("Before central rocket")
backup.Parent=game:GetService("ServerStorage")
local ok,err=pcall(function()
 if old then old.Parent=backup end
 copy.Parent=airport
 source.Parent=backup
end)
if not ok then copy:Destroy() if old then old.Parent=airport end source.Parent=workspace backup:Destroy() error(err) end
game:GetService("ChangeHistoryService"):SetWaypoint("Central rocket installed")
game:GetService("Selection"):Set({copy})
print("CENTRAL_ROCKET_INSTALLED — Ctrl+S 저장. Play에서 중앙 E를 확인하세요. 텍스처 표시도 확인하세요.")
