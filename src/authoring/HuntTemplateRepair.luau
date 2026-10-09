-- Restore exact approved assets from known backups, retaining backups and airship.
local M={}
function M.apply()
 assert(not game:GetService("RunService"):IsRunning(),"■ 정지 후 실행하세요.")
 local storage=game:GetService("ServerStorage")
 local package=game:GetService("ReplicatedStorage").RodeoFantasy
 local backup=storage:FindFirstChild("LobbyRepairBackup20261010")
 local detailImport=workspace:FindFirstChild("RecoveryMossratDetailTemplate")
 local entries={
  {parent=package,name="MeshyMossratHuntTemplate"},
  {parent=storage,name="RodeoMonsterTemplate"},
  {parent=package,name="VisualTemplate"},
 }
 local pending={}
 -- Validate every missing role before publishing any replacement.
 for _,entry in ipairs(entries) do
  local current=entry.parent:FindFirstChild(entry.name)
  if current then
   assert(current:IsA("Model") and current.PrimaryPart,"잘못된 기존 템플릿: "..entry.name)
  else
   local source=backup and backup:FindFirstChild(entry.name)
   if not source then
    source=if entry.name=="VisualTemplate" then detailImport else package:FindFirstChild("MeshyMossratHuntTemplate")
   end
   assert(source and source:IsA("Model") and source.PrimaryPart and source:GetAttribute("NativeMeshyMossrat"),"복구 원본 없음: "..entry.name..". 상세 복구 rbxmx 파일을 Workspace에 넣어주세요.")
   assert(source:FindFirstChild("Body") and source.Body:IsA("MeshPart"),"복구 원본에 메시 없음: "..entry.name)
   source.Archivable=true
   for _,node in ipairs(source:GetDescendants()) do node.Archivable=true end
   local copy=assert(source:Clone()) copy.Name=entry.name
   table.insert(pending,{parent=entry.parent,model=copy})
  end
 end
 for _,entry in ipairs(pending) do entry.model.Parent=entry.parent end
 -- Backup predates the explicit 180-degree runtime correction. Normalize once.
 for _,model in ipairs({package.MeshyMossratHuntTemplate,storage.RodeoMonsterTemplate}) do
  if model:GetAttribute("HuntFacingRepair20261010") then
   for _,part in ipairs(model:GetChildren()) do
    if part:IsA("MeshPart") then
     local rest=model.PrimaryPart.CFrame:ToObjectSpace(part.CFrame)
     rest=CFrame.new(rest.Position)*CFrame.Angles(0,math.pi,0)*rest.Rotation
     part.CFrame=model.PrimaryPart.CFrame*rest
     part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position)
    end
   end
   model:SetAttribute("HuntFacingRepair20261010",nil)
  end
  model:SetAttribute("MeshyVisualYawDegrees",180)
  model:SetAttribute("MeshyFacingRevision",model:GetAttribute("HeadShapeStraightened") and "HeadStraight-v1" or "HuntFacing-v2")
  model:SetAttribute("FaceCourseForward",false)
 end
 if detailImport then
  local archive=storage:FindFirstChild("HuntDepartureRecoveryInputs")
  if not archive then archive=Instance.new("Folder") archive.Name="HuntDepartureRecoveryInputs" archive.Parent=storage end
  detailImport.Parent=archive
 end
 print("HUNT_TEMPLATES_RESTORED: hunt/server/detail; original assets and airship preserved")
end
return M
