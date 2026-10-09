-- LEGACY ONLY: raw Meshy +Z installed without rotation. Not for prepared -Z GLBs.
-- For new installs use MeshyMossratInstaller.installSelected() instead.
assert(not game:GetService("RunService"):IsRunning(),"먼저 재생을 정지하세요")
local package=game.ReplicatedStorage.RodeoFantasy
local models={}
for _,entry in ipairs({{game.ServerStorage,"RodeoMonsterTemplate"},{package,"VisualTemplate"},{package,"MeshyMossratHuntTemplate"}}) do
 local model=assert(entry[1]:FindFirstChild(entry[2]),"설치된 템플릿이 없습니다: "..entry[2])
 assert(model.PrimaryPart and model:GetAttribute("NativeMeshyMossrat"),"먼저 새 모스랫을 설치하세요")
 table.insert(models,model)
end
for _,model in ipairs(models) do
 if not model:GetAttribute("MeshyFacingCorrected") then
  local root=model.PrimaryPart
  for _,part in ipairs(model:GetChildren()) do
   if part:IsA("MeshPart") then
    local rest=CFrame.Angles(0,math.pi,0)*root.CFrame:ToObjectSpace(part.CFrame)
    part.CFrame=root.CFrame*rest
    part:SetAttribute("ApprovedRest",rest)
    part:SetAttribute("ApprovedPivot",rest.Position)
   end
  end
  model:SetAttribute("MeshyFacingCorrected",true)
 end
end
print("모스랫 방향 수정 완료. Ctrl+S 후 Play로 확인하세요.")
