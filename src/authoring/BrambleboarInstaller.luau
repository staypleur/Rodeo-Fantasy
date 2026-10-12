-- Prepare outside gameplay first. Production installation requires reviewed assets.
local M={}
local specs={
 {label="S1_A",stage=1,height=2.5,widthRatio=.7026052176952362/.9,tri=10357,revision="NeutralQuadruped-v1",back=1.28},
 {label="S1_B",stage=1,height=2.5,widthRatio=.7037814557552338/.9,tri=3115,revision="NeutralQuadruped-v1",back=1.28},
 {label="S3",stage=3,height=5.56,widthRatio=1.4179283380508423/2,tri=10355,revision="NeutralQuadruped-v1",back=2.64},
 {label="S6",stage=6,height=8.33,widthRatio=2.5135960578918457/3,tri=10238,revision="ProvidedBiped-v1",back=5.41},
 {label="S9",stage=9,height=15.28,widthRatio=5.52315616607666/5.5,tri=9803,revision="ProvidedBiped-v1",back=9.93},
}
function M.prepare()
 assert(not game.RunService:IsRunning(),"Stop Play before preparing models")
 local P=game.ReplicatedStorage.RodeoFantasy local C=require(P.MonsterCatalog)
 assert(not game.ServerStorage:FindFirstChild("BrambleboarPrepared"),"Prepared models already exist")
 local imports={}
 local originalFolder=game.ServerStorage:FindFirstChild("BrambleboarImportedOriginals")
 for _,model in ipairs((originalFolder or workspace):GetChildren()) do
  if model:IsA("Model") and model.Name:find("Brambleboar") then
   local mesh=nil local count=0
   for _,node in ipairs(model:GetDescendants()) do
    assert(not node:IsA("LuaSourceContainer"),"Imported scripts are not allowed")
    if node:IsA("MeshPart") then assert(not mesh,"Expected one mesh") mesh=node end
    if node:IsA("Bone") then count+=1 end
   end
   if mesh then assert(count==18,"Expected 18 fitted bones") table.insert(imports,{model=model,mesh=mesh}) end
  end
 end
 assert(#imports==5,"Expected five Brambleboar imports, found "..#imports)
 local prepared=Instance.new("Folder") prepared.Name="BrambleboarPrepared"
 for _,s in ipairs(specs) do
  local chosen,error=nil,math.huge
  for _,entry in ipairs(imports) do
   if not entry.used then
    local e=math.abs(entry.mesh.Size.X/entry.mesh.Size.Y-s.widthRatio)
    if e<error then chosen,error=entry,e end
   end
  end
  assert(chosen and error<.0004,"Cannot identify supplied model "..s.label) chosen.used=true
  local model=Instance.new("Model") model.Name=s.label
  local root=Instance.new("Part") root.Name="Root" root.Transparency=1
  root.Size=Vector3.new(2.8,3.1,4.4)*C.Scales[s.stage]
  root.Anchored=true root.CanCollide=false root.CanQuery=false root.CanTouch=false root.Parent=model model.PrimaryPart=root
  local mesh=chosen.mesh:Clone() local scale=s.height/mesh.Size.Y
  local relative=CFrame.new(chosen.mesh.Position-Vector3.new(0,chosen.mesh.Size.Y/2,0)):ToObjectSpace(chosen.mesh.CFrame)
  local height=C.GrassBoar.RootHeight*C.Scales[s.stage]
  -- Roblox's importer converts glTF forward to -Z. Preserve its rotation.
  local rest=CFrame.new(0,s.height/2-height,0)*relative.Rotation
  mesh.Name="Body" mesh.Size*=scale mesh.CFrame=root.CFrame*rest
  for _,b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then b.CFrame=CFrame.new(b.CFrame.Position*scale)*b.CFrame.Rotation b.Transform=CFrame.identity end end
  mesh.Anchored=true mesh.CanCollide=false mesh.CanTouch=false mesh.CanQuery=false
  mesh:SetAttribute("ApprovedRest",rest) mesh:SetAttribute("ApprovedPivot",rest.Position) mesh.Parent=model
  assert(mesh:FindFirstChildOfClass("SurfaceAppearance"),"Missing color surface")
  for key,value in pairs({MonsterId="GrassBoar",Stars=s.stage,NativeMeshyMossrat=true,NativeMeshyReady=false,ImportedA=true,MeshDecorated=true,FaceCourseForward=true,RootHeight=height,
   MeshyFacingRevision="Brambleboar-Forward-v1",MossratUserRigRevision=s.revision,MossratRigTranslationScale=scale,SourceTriangles=s.tri,MeshyBackHeight=s.back,
   ModelUsage=s.label=="S1_B" and "Hunt" or "Social"}) do model:SetAttribute(key,value) end
  model.Parent=prepared
 end
 prepared.Parent=game.ServerStorage
 local originals=originalFolder or Instance.new("Folder") originals.Name="BrambleboarImportedOriginals" originals.Parent=game.ServerStorage
 for _,entry in ipairs(imports) do entry.model.Parent=originals end
 print("BRAMBLE_PREPARED",#specs,"models; gameplay unchanged")
 return prepared
end
function M.install()
 assert(not game.RunService:IsRunning(),"Stop Play before installing")
 local P=game.ReplicatedStorage.RodeoFantasy local SS=game.ServerStorage
 local prepared=assert(SS:FindFirstChild("BrambleboarPrepared"),"Review models first")
 for _,s in ipairs(specs) do assert(prepared:FindFirstChild(s.label),s.label) end
 local backup=Instance.new("Folder") backup.Name="BrambleboarBackup_"..game.HttpService:GenerateGUID(false) backup.Parent=SS
 game.ChangeHistoryService:SetWaypoint("Before Brambleboar models")
 for _,s in ipairs(specs) do
  local suffix=s.stage==1 and "" or "_S"..s.stage
  local targets=s.label=="S1_B" and {{P,"MeshyBrambleboarHuntTemplate"}} or {{P,"GrassBoarVisualTemplate"..suffix},{SS,"GrassBoarTemplate"..suffix}}
  for _,target in ipairs(targets) do
   local old=target[1]:FindFirstChild(target[2]) if old then old.Parent=backup end
   local model=prepared[s.label]:Clone() model.Name=target[2] model.Parent=target[1]
  end
 end
 game.ChangeHistoryService:SetWaypoint("Brambleboar installed")
 print("BRAMBLE_INSTALLED","one-star hunt LOD; detailed social stages")
end
return M
