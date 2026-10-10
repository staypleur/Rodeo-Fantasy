-- Reviewed user rig installation. Existing objects survive in ServerStorage backups.
local M={}
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local function normalized(s) return s:gsub("\r\n","\n") end
function M.run(updates,modules)
 assert(not game:GetService("RunService"):IsRunning(),"Play를 먼저 중지하세요.")
 local package=assert(RS:FindFirstChild("RodeoFantasy"),"RodeoFantasy 없음")
 local source
 for _,candidate in ipairs(workspace:GetChildren()) do
  if candidate:IsA("Model") and candidate.Name:match("^MossratS3Rigged") then
   local count=0 for _,b in ipairs(candidate:GetDescendants()) do if b:IsA("Bone") then count+=1 end end
   if count==34 then source=candidate break end
  end
 end
 local prepared,changes,additions={},{},{}
 for _,u in ipairs(updates) do
  local parent=u.parent
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
 local targets={{SS,"RodeoMonsterTemplate_S3"},{package,"VisualTemplate_S3"},{package,"MeshyMossratHuntTemplate_S3"}}
 local current=true
 for _,t in ipairs(targets) do local old=t[1]:FindFirstChild(t[2]) if not old or old:GetAttribute("MossratUserRigRevision")~="UserS3-v1" then current=false end end
 if current and #changes==0 and #additions==0 then print("MOSSRAT_S3_RIG_ALREADY_CURRENT") return end
 assert(source and source:IsA("Model"),"가져온 리그 Model 이름을 Workspace.MossratS3Rigged로 바꿔 주세요.")
 local meshes,bones={},{}
 for _,p in ipairs(source:GetDescendants()) do
  assert(not p:IsA("LuaSourceContainer"),"입력 모델의 스크립트는 허용하지 않습니다.")
  if p:IsA("MeshPart") then assert(p.MeshId~="","Studio에서 메시 업로드 필요") table.insert(meshes,p) end
  if p:IsA("Bone") then assert(not bones[p.Name],"중복 관절 이름: "..p.Name) bones[p.Name]=p end
 end
 assert(#meshes==1,"승인 모델은 MeshPart 한 개여야 합니다.")
 local expected=__BONE_HIERARCHY__
 for name,parent in pairs(expected) do
  local b=assert(bones[name],"리깅 관절 없음: "..name)
  assert(b:IsDescendantOf(meshes[1]),"관절이 메시 밖에 있습니다: "..name)
  assert(parent=="" and b.Parent==meshes[1] or parent~="" and b.Parent==bones[parent],"관절 계층 불일치: "..name)
 end
 local count=0 for _ in pairs(bones) do count+=1 end assert(count==34,"34관절 모델을 가져오세요.")
 local box,size=source:GetBoundingBox()
 assert(size.Y>0 and size.Y<math.huge,"유효하지 않은 모델 높이")
 local scale=3.5/size.Y
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
  local rest=CFrame.Angles(0,math.pi,0)*CFrame.new(relative.Position*scale-Vector3.new(0,catalog.MeadowMouse.RootHeight*catalog.Scales[3],0))*relative.Rotation
  part.Size*=scale part.CFrame=model.PrimaryPart.CFrame*rest
  for _,b in ipairs(part:GetDescendants()) do if b:IsA("Bone") then b.CFrame=CFrame.new(b.CFrame.Position*scale)*b.CFrame.Rotation b.Transform=CFrame.identity end end
  part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
  part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position) part.Parent=model
  for _,name in ipairs({"NativeMeshyMossrat","NativeMeshyReady","MeshDecorated","ImportedA","MeshyFacingCorrected","UserApprovedHuntModel"}) do model:SetAttribute(name,true) end
  model:SetAttribute("FaceCourseForward",true)
  model:SetAttribute("NativeMeshyStars",3) model:SetAttribute("MeshyVisualYawDegrees",0)
  model:SetAttribute("MeshyFacingRevision","UserS3-v1") model:SetAttribute("MossratUserRigRevision","UserS3-v1")
  model:SetAttribute("MossratRigTranslationScale",3.5/1.26)
  model:SetAttribute("MeshyBackHeight",1.50)
  model:SetAttribute("UserModelSourceSha256","db41ce805303eacff7e6565e58aef96b7dc25708b332350904789e2136acbda0")
  table.insert(prepared,{parent=t[1],old=old,node=model})
 end
 local backup=Instance.new("Folder") backup.Name="MossratS3RigBackup_"..game:GetService("HttpService"):GenerateGUID(false)
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
 print("MOSSRAT_S3_RIG_INSTALLED — Ctrl+S로 저장. 새 숲 준비 여부는 별도입니다.")
end
return M
