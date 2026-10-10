-- Retry only imported lobby textures; preserve every original asset ID.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local rows,ids,seen={},{},{}
for _,name in ipairs({"IncubatorImport","DoorImport","ConsoleImport","PlanetImport"}) do
 local model=workspace:FindFirstChild(name)
 if model then
  for _,n in ipairs(model:GetDescendants()) do
   if n:IsA("SurfaceAppearance") then
    local maps={}
    for _,key in ipairs({"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}) do
     local id=n[key]
     if type(id)=="string" and id:match("^rbxassetid://%d+$") then
      maps[key]=id
      if not seen[id] then seen[id]=true table.insert(ids,id) end
     end
    end
    if next(maps) then table.insert(rows,{node=n,maps=maps}) end
   end
  end
 end
end
assert(#rows>0,"가져온 모델의 업로드된 텍스처가 없습니다.")
game:GetService("ChangeHistoryService"):SetWaypoint("Before imported texture retry")
local ok,err=pcall(function()
 for _,r in ipairs(rows) do for key in pairs(r.maps) do r.node[key]="" end end
 task.wait(.5)
end)
-- Restore IDs even if the reset fails. No maps or models are deleted.
for _,r in ipairs(rows) do for key,id in pairs(r.maps) do r.node[key]=id end end
if not ok then error("원래 텍스처 ID 복원: "..tostring(err)) end
game:GetService("ChangeHistoryService"):SetWaypoint("Imported texture retry requested")
local loaded,failed=0,0
local preloadOk,preloadErr=pcall(function()
 game:GetService("ContentProvider"):PreloadAsync(ids,function(id,status)
  if status==Enum.AssetFetchStatus.Success then loaded+=1
  else failed+=1 warn("TEXTURE_FETCH: "..id.." / "..tostring(status)) end
 end)
end)
if not preloadOk then warn("텍스처 로딩 요청 오류: "..tostring(preloadErr)) end
print("LOBBY_TEXTURE_RETRY_REQUESTED — 로딩 성공",loaded,"실패",failed,". 모델 색상·재질은 화면에서 확인하세요.")
