local installer=(function()
-- Hunt-only swap: social templates and source assets stay intact.
local M={}
function M.run(source)
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
 local P=game.ReplicatedStorage.RodeoFantasy
 local old=assert(P:FindFirstChild("MeshyMossratHuntTemplate"))
 local social=assert(P:FindFirstChild("VisualTemplate"))
 assert(old.PrimaryPart and social.PrimaryPart)
 assert(source and source:IsA("Model") and source:IsDescendantOf(workspace),"Select the imported hunt model")
 local meshes={} local count=0
 for _,n in ipairs(source:GetDescendants()) do
  assert(not n:IsA("LuaSourceContainer"),"Unexpected source script")
  if n:IsA("MeshPart") then table.insert(meshes,n) end
  if n:IsA("Bone") then count+=1 end
 end
 assert(#meshes==1 and count==34,"Expected one mesh and 34 bones")
 local mesh=meshes[1]
 assert(mesh.MeshId~="" and mesh.MeshId~=social.Body.MeshId,"Import the new hunt mesh first")
 local model=old:Clone()
 local part=mesh:Clone() part.Name="Body"
 local scale=2.5/mesh.Size.Y
 local box,size=source:GetBoundingBox()
 local base=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0))
 local relative=base:ToObjectSpace(mesh.CFrame)
 local height=require(P.MonsterCatalog).MeadowMouse.RootHeight
 local rest=CFrame.Angles(0,math.pi,0)*CFrame.new(relative.Position*scale-Vector3.new(0,height,0))*relative.Rotation
 part.Size*=scale part.CFrame=model.PrimaryPart.CFrame*rest
 for _,n in ipairs(part:GetDescendants()) do
  if n:IsA("Bone") then n.CFrame=CFrame.new(n.CFrame.Position*scale)*n.CFrame.Rotation n.Transform=CFrame.identity end
 end
 for _,n in ipairs(model:GetChildren()) do if n:IsA("BasePart") and n~=model.PrimaryPart then n:Destroy() end end
 part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
 part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position) part.Parent=model
 model:SetAttribute("MossratUserRigRevision","ApprovedS1-v1")
 model:SetAttribute("MeshyFacingRevision","ApprovedS1-Hunt2951-v1")
 model:SetAttribute("MossratRigTranslationScale",2.5/.9)
 model:SetAttribute("SourceTriangles",2951)
 model:SetAttribute("ModelUsage","Hunt")
 model:SetAttribute("UserModelSourceSha256","4ebded703de65ada8c905d942881ac73e40136037a5fcef6162a92a9ea92c412")
 local backup=Instance.new("Folder") backup.Name="MossratHuntLODBackup_"..game:GetService("HttpService"):GenerateGUID(false)
 game:GetService("ChangeHistoryService"):SetWaypoint("Before hunt LOD")
 backup.Parent=game.ServerStorage old.Parent=backup model.Parent=P source.Parent=backup
 game:GetService("ChangeHistoryService"):SetWaypoint("Hunt LOD installed")
 print("HUNT_LOD_INSTALLED",part.MeshId,"HUNT_TRIANGLES",2951,"SOCIAL_UNCHANGED",social.Body.MeshId)
end
return M

end)() installer.run(workspace:FindFirstChild("MossratS1Rigged"))
