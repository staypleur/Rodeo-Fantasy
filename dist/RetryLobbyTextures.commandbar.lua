-- Retry imported or installed lobby textures; preserve every original asset ID.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local rows,ids,seen,surfaces={},{},{},{}
local targets={IncubatorImport=true,DoorImport=true,ConsoleImport=true,PlanetImport=true,
 UserIncubator=true,UserDoorFrame=true,UserDoorConsole=true,CeilingPlanet=true}
local modelCount,surfaceCount,temporaryCount=0,0,0
-- Installed modules are nested inside RodeoLobby; import originals may already
-- be archived in ServerStorage. Only live Workspace objects need reloading.
for _,model in ipairs(workspace:GetDescendants()) do
 if targets[model.Name] then
  modelCount+=1
  for _,n in ipairs(model:GetDescendants()) do
   if n:IsA("SurfaceAppearance") and not surfaces[n] then
    surfaces[n]=true surfaceCount+=1
    local maps={}
    for _,key in ipairs({"ColorMap","NormalMap","MetalnessMap","RoughnessMap"}) do
     local id=n[key]
     if type(id)=="string" and (id:match("^rbxassetid://%d+$") or id:match("^https?://")) then
      maps[key]=id
      if not seen[id] then seen[id]=true table.insert(ids,id) end
     elseif type(id)=="string" and id:match("^rbxtemp://") then temporaryCount+=1 end
    end
    if next(maps) then table.insert(rows,{node=n,maps=maps}) end
   end
  end
 end
end
print("LOBBY_TEXTURE_TARGETS — 모델",modelCount,"재질",surfaceCount,"업로드 맵",#ids,"임시 맵",temporaryCount)
if modelCount==0 then
 error("재시도 대상 없음: Workspace의 …Import 또는 RodeoLobby의 UserIncubator/UserDoorFrame/UserDoorConsole/CeilingPlanet을 찾지 못했습니다.")
end
assert(#rows>0,"대상 모델은 찾았지만 재요청할 업로드 맵이 없습니다. 위 재질·임시 맵 수를 확인하세요.")
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
