-- Install the three recovery imports together in Studio EDIT mode.
local M={}
local names={"RecoveryMossratHunt","RecoveryMossratDetail","RecoveryAirship"}
local tags={"Mossrat_S1_Hunt_HeadStraight","Mossrat_S1_Detail_HeadStraight","LobbyAirship_Recovery"}
local function imported(index)
 local named=workspace:FindFirstChild(names[index])
 local container=workspace
 local candidates={}
 for _,part in ipairs(named and named:GetDescendants() or workspace:GetDescendants()) do
  if part:IsA("MeshPart") and (named or part.Name:find(tags[index],1,true)) then table.insert(candidates,part) end
 end
 if named and named:IsA("MeshPart") then table.insert(candidates,named) end
 -- A failed ship color keeps its fresh import in Workspace. Reuse archived mouse
 -- imports on the next run, so the user does not need to import the mice again.
 if #candidates==0 and index<3 then
  for _,backup in ipairs(game:GetService("ServerStorage"):GetChildren()) do
   local imports=backup.Name=="ModelRecoveryBackup" and backup:FindFirstChild("RecoveryImports")
   if imports then
    for _,part in ipairs(imports:GetDescendants()) do
     if part:IsA("MeshPart") and part.Name:find(tags[index],1,true) then
      table.insert(candidates,part) container=imports
     end
    end
   end
  end
 end
 assert(#candidates==1,"가져온 모델 하나가 필요합니다: "..names[index]..". 새로 가져온 모델의 이름을 확인하세요.")
 local mesh=candidates[1]
 assert(mesh.MeshId~="" and mesh.Size.Y>0,"메시 가져오기를 완료하세요: "..names[index])
 local root=named or mesh
 if not named then while root.Parent~=container do root=root.Parent end end
 assert(not root:FindFirstChildWhichIsA("LuaSourceContainer",true),"가져온 모델에 스크립트가 있어 중단했습니다.")
 local appearance=mesh:FindFirstChildOfClass("SurfaceAppearance")
 assert(appearance and appearance.ColorMap~="","색 텍스처가 없는 가져오기입니다: "..names[index])
 if index<3 then
  for _,name in ipairs({"MossLeftFrontLeg","MossLeftBackLeg","MossRightFrontLeg","MossRightBackLeg"}) do
   local bone=mesh:FindFirstChild(name,true)
   assert(bone and bone:IsA("Bone"),"모스랫 Rig Type을 Custom으로 가져오세요. 누락: "..name)
  end
 end
 return mesh,root
end
local function fresh(module,callback)
 local copy=module:Clone() copy.Parent=module.Parent
 local ok,result=pcall(function() return callback(require(copy)) end)
 copy:Destroy() assert(ok,result) return result
end
local function geometry(mesh,label)
 -- PreloadAsync supports mesh geometry, but cannot validate SurfaceAppearance's
 -- processed texture pack by requesting its individual image IDs.
 local success=false
 local ok=pcall(function()
  game:GetService("ContentProvider"):PreloadAsync({mesh.MeshId},function(_,status) success=status==Enum.AssetFetchStatus.Success end)
 end)
 print("RECOVERY_MESH",label,ok and success and "Success" or "Failure")
 assert(ok and success,"새 메시 로드 실패. 기존 모델은 변경하지 않았습니다: "..label)
end
function M.install()
 assert(not game:GetService("RunService"):IsRunning(),"■ 정지 후 실행하세요.")
 local package=game.ReplicatedStorage.RodeoFantasy
 local ss=game:GetService("ServerStorage")
 local hunt,huntRoot=imported(1)
 local detail,detailRoot=imported(2)
 local shipMesh,shipRoot=imported(3)
 local shipImportParent=shipMesh.Parent
 assert(huntRoot~=detailRoot and huntRoot~=shipRoot and detailRoot~=shipRoot,"세 모델을 각각 가져오세요.")
 local airport=workspace.RodeoLobby.Airport
 local ship=assert(airport:FindFirstChild("Airship"))
 local oldHunt=assert(package:FindFirstChild("MeshyMossratHuntTemplate"))
 local oldDetail=assert(package:FindFirstChild("VisualTemplate"))
 local oldServer=assert(ss:FindFirstChild("RodeoMonsterTemplate"))
 assert(airport:FindFirstChild("Departure"),"사냥터 출발 지점이 없습니다.")
 local cables={}
 for _,part in ipairs(airport.BoardingArea:GetChildren()) do
  if part:IsA("BasePart") and part.Name=="Cable" then table.insert(cables,part) end
 end
 assert(#cables==4,"비행선 연결 줄 4개가 필요합니다.")
 geometry(hunt,"Hunt") geometry(detail,"Detail") geometry(shipMesh,"Airship")
 local backup=Instance.new("Folder") backup.Name="ModelRecoveryBackup" backup.Parent=ss
 for _,model in ipairs({oldHunt,oldDetail,oldServer,ship}) do model:Clone().Parent=backup end
 local frames={}
 for _,part in ipairs(cables) do frames[part]={frame=part.CFrame,size=part.Size} end
 local oldHuntRotation=oldHunt.PrimaryPart.CFrame:ToObjectSpace(oldHunt.Body.CFrame).Rotation
 if oldHunt:GetAttribute("HuntFacingRepair20261010") then oldHuntRotation=CFrame.Angles(0,math.pi,0)*oldHuntRotation end
 local oldDetailRotation=oldDetail.PrimaryPart.CFrame:ToObjectSpace(oldDetail.Body.CFrame).Rotation
 local oldDetailYaw=oldDetail:GetAttribute("MeshyVisualYawDegrees") or 0
 local ok,err=pcall(function()
  fresh(package.MeshyMossratInstaller,function(installer) installer.install(hunt,detail,"-Z") end)
  for _,entry in ipairs({{package.MeshyMossratHuntTemplate,oldHuntRotation,180},{ss.RodeoMonsterTemplate,oldHuntRotation,180},{package.VisualTemplate,oldDetailRotation,oldDetailYaw}}) do
   local model,rotation,yaw=unpack(entry)
   local body=model.Body
   -- Recovery files preserve the exact role-specific UVs and texture bytes.
   -- Reuse the previously displayed mouse PBR, including its processed pack.
   local old=backup:FindFirstChild(model.Name)
   local approved=old and old.Body:FindFirstChildOfClass("SurfaceAppearance")
   if approved and approved.ColorMap~="" then
    for _,child in ipairs(body:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    approved:Clone().Parent=body
    model:SetAttribute("RecoveryExistingPBRReused",true)
   end
   local rest=model.PrimaryPart.CFrame:ToObjectSpace(body.CFrame)
   rest=CFrame.new(rest.Position)*rotation
   body.CFrame=model.PrimaryPart.CFrame*rest
   body:SetAttribute("ApprovedRest",rest) body:SetAttribute("ApprovedPivot",rest.Position)
   model:SetAttribute("MeshyVisualYawDegrees",yaw)
   model:SetAttribute("MeshyFacingRevision","HeadStraight-v1")
   model:SetAttribute("HeadShapeStraightened",true)
   model:SetAttribute("HuntFacingRepair20261010",nil)
   -- Restore natural movement: the prior course-lock did not correct the head shape.
   model:SetAttribute("FaceCourseForward",false)
  end
  do
   local selection=game:GetService("Selection") local before=selection:Get()
   selection:Set({shipMesh})
   local installed,reason=pcall(function()
    fresh(package.MeshyAirshipInstaller,function(installer) return installer.installSelected("-Z") end)
   end)
   selection:Set(before)
   assert(installed,reason)
   airport.Airship:SetAttribute("RecoveryPBRPreserved",true)
   airport.Airship:SetAttribute("RecoveryTexturesChecked",nil)
  end
 end)
 if not ok then
  for _,entry in ipairs({{package,"MeshyMossratHuntTemplate"},{package,"VisualTemplate"},{ss,"RodeoMonsterTemplate"}}) do
   local current=entry[1]:FindFirstChild(entry[2]) if current then current:Destroy() end
   backup:FindFirstChild(entry[2]):Clone().Parent=entry[1]
  end
  if not ship.Parent or ship.Parent~=airport then
   local current=airport:FindFirstChild("Airship") if current then current:Destroy() end
   backup.Airship:Clone().Parent=airport
  end
  for part,data in pairs(frames) do part.CFrame=data.frame part.Size=data.size end
  shipMesh.Parent=shipImportParent
  error("설치 중단. 이전 템플릿/비행선 복구: "..tostring(err))
 end
 local imports=Instance.new("Folder") imports.Name="RecoveryImports" imports.Parent=backup
 huntRoot.Parent=imports detailRoot.Parent=imports
 shipRoot.Parent=imports
 print("MOSSRAT_HEAD_SHAPE_APPLIED: head-only geometry, four leg bones, hunt 3k/detail 10k; natural steering restored")
 print("MODEL_RECOVERY_INSTALLED: meshes installed; imported airship PBR pack preserved; four cables and Departure preserved. Ctrl+S then check colors in Play")
 return true
end
return M
