-- Repair only the two hunt templates reported to run backwards.
assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local templates={assert(game:GetService("ServerStorage"):FindFirstChild("RodeoMonsterTemplate")),assert(package:FindFirstChild("MeshyMossratHuntTemplate"))}
for _,model in ipairs(templates) do
 assert(model:GetAttribute("NativeMeshyMossrat") and model.PrimaryPart and model:FindFirstChild("Body"),"Expected installed native Mossrat hunt template")
end
local backup=Instance.new("Folder") backup.Name="MossratHuntFacingBackup" backup.Parent=game:GetService("ServerStorage")
for _,model in ipairs(templates) do
 if not model:GetAttribute("HuntFacingRepair20261010") then
  model:Clone().Parent=backup
  local root=model.PrimaryPart
  for _,part in ipairs(model:GetChildren()) do
   if part:IsA("MeshPart") then
    local rest=root.CFrame:ToObjectSpace(part.CFrame)
    rest=CFrame.new(rest.Position)*CFrame.Angles(0,math.pi,0)*rest.Rotation
    part.CFrame=root.CFrame*rest
    part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position)
   end
  end
  model:SetAttribute("HuntFacingRepair20261010",true)
 end
end
print("MOSSRAT_HUNT_FACING_REPAIR_APPLIED")
