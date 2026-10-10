-- Isolate the incubator color map; original materials remain in ServerStorage.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local rows,seen={},{}
for _,model in ipairs(workspace:GetDescendants()) do
 if model.Name=="UserIncubator" or model.Name=="IncubatorImport" then
  for _,node in ipairs(model:GetDescendants()) do
   if node:IsA("SurfaceAppearance") and node.Parent:IsA("MeshPart") and not seen[node] then
    seen[node]=true
    local id=node.ColorMap
    assert(id:match("^rbxassetid://%d+$"),"부화기 ColorMap 업로드 ID 없음: "..node:GetFullName())
    table.insert(rows,{old=node,part=node.Parent,color=node.Parent.Color,id=id})
   end
  end
 end
end
assert(#rows>0,"Workspace에서 부화기 재질을 찾지 못했습니다.")
local backup=Instance.new("Folder")
backup.Name="IncubatorColorCheckBackup_"..game:GetService("HttpService"):GenerateGUID(false)
for index,r in ipairs(rows) do
 local saved=Instance.new("Folder") saved.Name=tostring(index) saved.Parent=backup
 local target=Instance.new("ObjectValue") target.Name="Target" target.Value=r.part target.Parent=saved
 local color=Instance.new("Color3Value") color.Name="OriginalColor" color.Value=r.color color.Parent=saved
 r.saved=saved
 r.new=Instance.new("SurfaceAppearance") r.new.Name="SurfaceAppearance"
 r.new.AlphaMode=r.old.AlphaMode r.new.Color=r.old.Color
 r.new.ColorMap=r.id
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before incubator color check")
local ok,err=pcall(function()
 backup.Parent=game:GetService("ServerStorage")
 for _,r in ipairs(rows) do
  r.old.Parent=r.saved
  r.part.Color=Color3.new(1,1,1)
  r.new.Parent=r.part
 end
end)
if not ok then
 for _,r in ipairs(rows) do r.new:Destroy() r.old.Parent=r.part r.part.Color=r.color end
 backup:Destroy() error("부화기 재질 복구 완료: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Incubator color check requested")
print("INCUBATOR_COLOR_CHECK_REQUESTED — 대상",#rows,". 화면에서 색상 확인 필요. 원래 재질 백업:",backup.Name)
-- This requests material generation; the print message does not prove loading success.
