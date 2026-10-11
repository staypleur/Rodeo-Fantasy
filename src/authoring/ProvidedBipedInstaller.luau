local M={}
function M.run(updates)
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
 local P=game.ReplicatedStorage.RodeoFantasy
 local source
 for _,m in ipairs(workspace:GetChildren()) do
  if m:IsA("Model") and m:FindFirstChild("mixamorig:Hips",true) then assert(not source,"Multiple imports") source=m end
 end
 assert(source,"Provided S6 import missing")
 local meshes={} local bones=0
 for _,n in ipairs(source:GetDescendants()) do
  assert(not n:IsA("LuaSourceContainer"),"Unexpected script")
  if n:IsA("MeshPart") then table.insert(meshes,n) end
  if n:IsA("Bone") then bones+=1 end
 end
 assert(#meshes==1 and bones==23,"Expected 1 mesh / 23 bones")
 local mesh=meshes[1] assert(mesh.MeshId~="")
 for _,u in ipairs(updates) do
  local old=u.parent:FindFirstChild(u.name)
  assert(not old and u.before==nil or old and old:IsA("ModuleScript") and (old.Source:gsub("\r\n","\n")==u.before or old.Source:gsub("\r\n","\n")==u.after),"Changed module: "..u.name)
 end
 local prepared={}
 for _,target in ipairs({{P,"VisualTemplate_S6"},{P,"MeshyMossratHuntTemplate_S6"},{game.ServerStorage,"RodeoMonsterTemplate_S6"}}) do
  local old=assert(target[1]:FindFirstChild(target[2])) local model=old:Clone()
  for _,n in ipairs(model:GetChildren()) do if n:IsA("BasePart") and n~=model.PrimaryPart then n:Destroy() end end
  local part=mesh:Clone() part.Name="Body" local scale=7/part.Size.Y
  local box,size=source:GetBoundingBox()
  local relative=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0)):ToObjectSpace(part.CFrame)
  local rootHeight=old:GetAttribute("RootHeight") or require(P.MonsterCatalog).MeadowMouse.RootHeight*1.9
  local rest=CFrame.new(relative.Position*scale-Vector3.new(0,rootHeight,0))*relative.Rotation
  part.Size*=scale part.CFrame=model.PrimaryPart.CFrame*rest
  for _,b in ipairs(part:GetDescendants()) do if b:IsA("Bone") then b.CFrame=CFrame.new(b.CFrame.Position*scale)*b.CFrame.Rotation b.Transform=CFrame.identity end end
  part.Anchored=true part.CanCollide=false part.CanQuery=false part.CanTouch=false
  part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position) part.Parent=model
  local surface=assert(part:FindFirstChildOfClass("SurfaceAppearance"),"S6 color surface missing")
  surface.ColorMap="rbxassetid://122822919155461"
  model:SetAttribute("MossratUserRigRevision","ProvidedBiped-v1")
  model:SetAttribute("MeshyFacingRevision","ProvidedBiped-Forward-v2")
  model:SetAttribute("ProvidedBipedFacingFixed",true)
  model:SetAttribute("NativeMeshyReady",false)
  table.insert(prepared,{old=old,model=model,parent=target[1]})
 end
 local backup=Instance.new("Folder") backup.Name="ProvidedBipedBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
 game:GetService("ChangeHistoryService"):SetWaypoint("Before provided biped")
 for _,u in ipairs(updates) do
  local n=u.parent:FindFirstChild(u.name)
  if n then n:Clone().Parent=backup else n=Instance.new("ModuleScript") n.Name=u.name n.Parent=u.parent end
  n.Source=u.after
 end
 for _,p in ipairs(prepared) do p.old.Parent=backup p.model.Parent=p.parent end
 source.Parent=backup
 game:GetService("ChangeHistoryService"):SetWaypoint("Provided biped installed")
 print("PROVIDED_BIPED_INSTALLED",mesh.MeshId,"23 bones; height 7; shared walking/running")
end
return M
