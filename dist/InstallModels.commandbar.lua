-- Install into RodeoFantasy-New only, in Edit mode. Inputs: MossratImport / RocketImport.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local map=assert(workspace:FindFirstChild("RodeoLobby"),"새 로비 없음")
assert(map:FindFirstChild("SpaceLobbyDoors") and workspace:FindFirstChild("GreenStar"),"RodeoFantasy-New 맵을 먼저 여세요.")
local hasMossrat=workspace:FindFirstChild("MossratImport")~=nil
local hasRocket=workspace:FindFirstChild("RocketImport")~=nil
assert(hasMossrat or hasRocket,"가져온 전체 Model 이름을 MossratImport 또는 RocketImport로 바꾸세요.")
if hasMossrat then local M=(function()
-- Reviewed user rig installation. Existing objects survive in ServerStorage backups.
local M={}
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local function normalized(s) return s:gsub("\r\n","\n") end
function M.run(updates,modules)
 assert(not game:GetService("RunService"):IsRunning(),"Play를 먼저 중지하세요.")
 local package=assert(RS:FindFirstChild("RodeoFantasy"),"RodeoFantasy 없음")
 local source=workspace:FindFirstChild("MossratImport")
 local prepared,changes,additions={},{},{}
 for _,u in ipairs(updates) do
  local parent=u.name=="NativeMossrat" and game.StarterPlayer.StarterPlayerScripts or game.ServerScriptService
  local node=assert(parent:FindFirstChild(u.name,true),u.name.." 없음")
  local current=normalized(node.Source)
  assert(current==u.before or current==u.after,u.name.." 코드 버전이 달라 설치를 중단합니다. 기존 코드 보존.")
  if current~=u.after then table.insert(changes,{node=node,before=node.Source,after=u.after}) end
 end
 for _,m in ipairs(modules) do
  local old=m.parent:FindFirstChild(m.name)
  if old then assert(old:IsA("ModuleScript") and normalized(old.Source)==m.source,"이미 있는 모듈 버전 불일치: "..m.name)
  else
   local node=Instance.new("ModuleScript") node.Name=m.name node.Source=m.source
   table.insert(additions,{node=node,parent=m.parent})
  end
 end
 local targets={{SS,"RodeoMonsterTemplate"},{package,"VisualTemplate"},{package,"MeshyMossratHuntTemplate"}}
 local current=true
 for _,t in ipairs(targets) do local old=t[1]:FindFirstChild(t[2]) if not old or old:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then current=false end end
 if current and #changes==0 and #additions==0 then print("MOSSRAT_RIG_ALREADY_CURRENT") return end
 assert(source and source:IsA("Model"),"가져온 리그 Model 이름을 Workspace.MossratImport로 바꿔 주세요.")
 local meshes,bones={},{}
 for _,p in ipairs(source:GetDescendants()) do
  assert(not p:IsA("LuaSourceContainer"),"입력 모델의 스크립트는 허용하지 않습니다.")
  if p:IsA("MeshPart") then assert(p.MeshId~="","Studio에서 메시 업로드 필요") table.insert(meshes,p) end
  if p:IsA("Bone") then assert(not bones[p.Name],"중복 관절 이름: "..p.Name) bones[p.Name]=p end
 end
 assert(#meshes==1,"승인 모델은 MeshPart 한 개여야 합니다.")
 local expected={["Root"]="",["Pelvis"]="Root",["Spine"]="Pelvis",["Chest"]="Spine",["Neck"]="Chest",["Head"]="Neck",["Jaw"]="Head",["EyeLeft"]="Head",["EyeRight"]="Head",["EarLeft"]="Head",["EarTipLeft"]="EarLeft",["EarRight"]="Head",["EarTipRight"]="EarRight",["Sprout"]="Head",["SproutTip"]="Sprout",["WhiskerLeft"]="Head",["WhiskerRight"]="Head",["LeftFrontUpper"]="Chest",["LeftFrontLower"]="LeftFrontUpper",["LeftFrontPaw"]="LeftFrontLower",["LeftRearUpper"]="Pelvis",["LeftRearLower"]="LeftRearUpper",["LeftRearPaw"]="LeftRearLower",["RightFrontUpper"]="Chest",["RightFrontLower"]="RightFrontUpper",["RightFrontPaw"]="RightFrontLower",["RightRearUpper"]="Pelvis",["RightRearLower"]="RightRearUpper",["RightRearPaw"]="RightRearLower",["Tail1"]="Pelvis",["Tail2"]="Tail1",["Tail3"]="Tail2",["Tail4"]="Tail3",["Tail5"]="Tail4"}
 for name,parent in pairs(expected) do
  local b=assert(bones[name],"리깅 관절 없음: "..name)
  assert(b:IsDescendantOf(meshes[1]),"관절이 메시 밖에 있습니다: "..name)
  assert(parent=="" and b.Parent==meshes[1] or parent~="" and b.Parent==bones[parent],"관절 계층 불일치: "..name)
 end
 local count=0 for _ in pairs(bones) do count+=1 end assert(count==34,"34관절 모델을 가져오세요.")
 local box,size=source:GetBoundingBox()
 assert(size.Y>0 and size.Y<math.huge,"유효하지 않은 모델 높이")
 local scale=2.5/size.Y
 local base=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0))
 local catalog=require(package.MonsterCatalog)
 for _,t in ipairs(targets) do
  local old=t[1]:FindFirstChild(t[2])
  local prototype=old or package:FindFirstChild("VisualTemplate")
  assert(prototype and prototype:IsA("Model") and prototype.PrimaryPart,"기존 템플릿 Root 없음: "..t[2])
  local model=prototype:Clone() model.Name=t[2]
  for _,child in ipairs(model:GetChildren()) do if child:IsA("BasePart") and child~=model.PrimaryPart then child:Destroy() end end
  local part=meshes[1]:Clone() part.Name="Body"
  local relative=base:ToObjectSpace(meshes[1].CFrame)
  local rest=CFrame.Angles(0,math.pi,0)*CFrame.new(relative.Position*scale-Vector3.new(0,catalog.MeadowMouse.RootHeight,0))*relative.Rotation
  part.Size*=scale part.CFrame=model.PrimaryPart.CFrame*rest
  for _,b in ipairs(part:GetDescendants()) do if b:IsA("Bone") then b.CFrame=CFrame.new(b.CFrame.Position*scale)*b.CFrame.Rotation b.Transform=CFrame.identity end end
  part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
  part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position) part.Parent=model
  for _,name in ipairs({"NativeMeshyMossrat","NativeMeshyReady","MeshDecorated","ImportedA","MeshyFacingCorrected","UserApprovedHuntModel"}) do model:SetAttribute(name,true) end
  model:SetAttribute("NativeMeshyStars",1) model:SetAttribute("MeshyVisualYawDegrees",0)
  model:SetAttribute("MeshyFacingRevision","ApprovedS1-v1") model:SetAttribute("MossratUserRigRevision","ApprovedS1-v1")
  model:SetAttribute("MossratRigTranslationScale",2.5/.9)
  model:SetAttribute("MeshyBackHeight",1.18)
  model:SetAttribute("UserModelSourceSha256","488598762339c44959cef95e1803a3ead9bff32fd864b54afadb241380474bec")
  table.insert(prepared,{parent=t[1],old=old,node=model})
 end
 local backup=Instance.new("Folder") backup.Name="MossratRigBackup_"..game:GetService("HttpService"):GenerateGUID(false)
 for _,c in ipairs(changes) do local clone=c.node:Clone() clone.Parent=backup end
 game:GetService("ChangeHistoryService"):SetWaypoint("Before approved Mossrat rig")
 local ok,err=pcall(function()
  backup.Parent=SS
  for _,p in ipairs(prepared) do if p.old then p.old.Parent=backup end p.node.Parent=p.parent end
  for _,a in ipairs(additions) do a.node.Parent=a.parent end
  for _,c in ipairs(changes) do c.node.Source=c.after end
  source.Parent=backup
 end)
 if not ok then
  for _,c in ipairs(changes) do c.node.Source=c.before end
  for _,a in ipairs(additions) do a.node:Destroy() end
  for _,p in ipairs(prepared) do p.node:Destroy() if p.old then p.old.Parent=p.parent end end
  source.Parent=workspace backup:Destroy() error("설치 복구 완료: "..tostring(err))
 end
 game:GetService("ChangeHistoryService"):SetWaypoint("Approved Mossrat rig installed")
 print("MOSSRAT_RIG_INSTALLED — Ctrl+S로 저장. 새 숲 준비 여부는 별도입니다.")
end
return M

end)() M.run({},{}) end
if hasRocket then
 local source=workspace.RocketImport
 assert(source:IsA("Model"),"RocketImport는 전체 Model이어야 합니다.")
 local count=0
 for _,n in ipairs(source:GetDescendants()) do
  assert(not n:IsA("LuaSourceContainer"),"입력 로켓에 스크립트를 넣지 마세요.")
  if n:IsA("MeshPart") then assert(n.MeshId~="","로켓 메시 업로드 필요") count+=1 end
 end
 assert(count>0,"로켓 MeshPart 없음")
 local airport=map.Airport local old=airport:FindFirstChild("Rocket")
 local copy=assert(source:Clone(),"로켓 복제 실패") copy.Name="Rocket"
 copy:PivotTo(copy:GetPivot()*CFrame.Angles(0,math.pi,0))
 local box,size=copy:GetBoundingBox() assert(size.Y>0,"로켓 높이 오류")
 copy:ScaleTo(copy:GetScale()*(18/.28)/size.Y)
 box,size=copy:GetBoundingBox()
 copy:PivotTo(CFrame.new(Vector3.new(6000,8+size.Y/2,0)-box.Position)*copy:GetPivot())
 for _,p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end end
 copy:SetAttribute("UserRocketDepartureV1",true)
 copy:SetAttribute("UserRocketSourceSha256","458fe773d5b29cf4b90979d8990334dad62344c3ed917b729cad7a387e1f91a8")
 local backup=Instance.new("Folder") backup.Name="RocketImportBackup_"..game:GetService("HttpService"):GenerateGUID(false)
 backup.Parent=game:GetService("ServerStorage")
 local ok,err=pcall(function() if old then old.Parent=backup end copy.Parent=airport source.Parent=backup end)
 if not ok then copy:Destroy() if old then old.Parent=airport end source.Parent=workspace backup:Destroy() error(err) end
 local pending=airport:FindFirstChild("RocketModelPending") if pending then pending.Parent=backup end
 print("NEW_ROCKET_INSTALLED")
end
print("NEW_PROJECT_MODELS_INSTALLED — Ctrl+S로 저장하고 Play로 확인하세요.")
