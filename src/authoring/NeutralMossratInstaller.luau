-- Install the supplied neutral meshes; keep originals and replaced templates in a backup.
local M={}
function M.run(updates,modules)
 assert(not game.RunService:IsRunning(),"Stop Play first")
 local P=game.ReplicatedStorage.RodeoFantasy
 local SS=game.ServerStorage
 local catalog=require(P.MonsterCatalog)
 local specs={
  {name="MossratNeutralS1V2",stage=1,height=2.5,tri=10411,sha="a54460ceb4db1d6d4b7348e8689f12510cab904d5b6e914e4053250e4e4ab4c3",targets={{P,"VisualTemplate"},{SS,"RodeoMonsterTemplate"}}},
  {name="MossratNeutralS1HuntV2",stage=1,height=2.5,tri=3122,sha="2f1eb7b32b08e9f9d6e4242b59bd4bb8cbac337df065004ffc4dab50ada0c198",targets={{P,"MeshyMossratHuntTemplate"}}},
  {name="MossratNeutralS3V2",stage=3,height=4.25,tri=10329,sha="d595a85c90d4cce5485572fc672075459ad91b8aa7f56b0d760349220877ba05",targets={{P,"VisualTemplate_S3"},{SS,"RodeoMonsterTemplate_S3"},{P,"MeshyMossratHuntTemplate_S3"}}},
 }
 local prepared={}
 for _,u in ipairs(updates) do
  u.node=assert(u.parent:FindFirstChild(u.name),u.name)
  local current=u.node.Source:gsub("\r\n","\n")
  assert(current==u.before or current==u.after,"Source changed: "..u.name)
 end
 for _,m in ipairs(modules) do assert(not m.parent:FindFirstChild(m.name),"Already exists: "..m.name) end
 for _,s in ipairs(specs) do
  s.source=assert(workspace:FindFirstChild(s.name),s.name)
  local mesh,count=nil,0
  for _,n in ipairs(s.source:GetDescendants()) do
   assert(not n:IsA("LuaSourceContainer"),"Unexpected imported script")
   if n:IsA("MeshPart") then assert(not mesh,"Multiple meshes") mesh=n end
   if n:IsA("Bone") then count+=1 end
  end
  assert(mesh and mesh.MeshId~="" and count==23,"Expected 23 effective skin bones")
  assert(mesh:FindFirstChild("Head",true) and mesh:FindFirstChildOfClass("SurfaceAppearance"),"Head/texture missing")
  for _,side in ipairs({"Left","Right"}) do for _,limb in ipairs({"Front","Rear"}) do
   local upper=assert(mesh:FindFirstChild(side..limb.."Upper",true))
   local lower=assert(upper:FindFirstChild(side..limb.."Lower"))
   assert(lower:FindFirstChild(side..limb.."Paw"),"Broken leg hierarchy")
  end end
  local box,size=s.source:GetBoundingBox()
  local relative=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0)):ToObjectSpace(mesh.CFrame)
  local scale=s.height/mesh.Size.Y
  local rootHeight=catalog.MeadowMouse.RootHeight*catalog.Scales[s.stage]
  local rest=CFrame.new(relative.Position*scale-Vector3.new(0,rootHeight,0))*relative.Rotation
  for _,target in ipairs(s.targets) do
   local old=assert(target[1]:FindFirstChild(target[2]),target[2])
   local model=old:Clone() assert(model.PrimaryPart)
   for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
   local part=mesh:Clone() part.Name="Body" part.Size*=scale
   for _,b in ipairs(part:GetDescendants()) do if b:IsA("Bone") then b.CFrame=CFrame.new(b.CFrame.Position*scale)*b.CFrame.Rotation b.Transform=CFrame.identity end end
   part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position) part.Parent=model
   for _,attr in ipairs({"NativeMeshyMossrat","MeshDecorated","ImportedA","MeshyFacingCorrected","UserApprovedHuntModel","FaceCourseForward"}) do model:SetAttribute(attr,true) end
   model:SetAttribute("NativeMeshyReady",false)
   model:SetAttribute("NativeMeshyStars",s.stage)
   model:SetAttribute("MeshyVisualYawDegrees",0)
   model:SetAttribute("MeshyFacingRevision","NeutralQuadruped-v1")
   model:SetAttribute("MossratUserRigRevision","NeutralQuadruped-v1")
   model:SetAttribute("MossratRigTranslationScale",scale)
   model:SetAttribute("SourceTriangles",s.tri)
   model:SetAttribute("ModelUsage",target[2]:find("Hunt") and "Hunt" or "Social")
   model:SetAttribute("UserModelSourceSha256",s.sha)
   table.insert(prepared,{node=model,old=old,parent=target[1]})
  end
 end
 local backup=Instance.new("Folder") backup.Name="NeutralMossratBackup_"..game.HttpService:GenerateGUID(false)
 game.ChangeHistoryService:SetWaypoint("Before neutral Mossrat installation")
 backup.Parent=SS
 for _,u in ipairs(updates) do u.node:Clone().Parent=backup end
 for _,p in ipairs(prepared) do p.old.Parent=backup p.node.Parent=p.parent end
 for _,m in ipairs(modules) do local node=Instance.new("ModuleScript") node.Name=m.name node.Source=m.source node.Parent=m.parent end
 for _,u in ipairs(updates) do u.node.Source=u.after end
 for _,n in ipairs(workspace:GetChildren()) do if n.Name:match("^MossratNeutralS") then n.Parent=backup end end
 game.ChangeHistoryService:SetWaypoint("Neutral Mossrat installed")
 for _,p in ipairs(prepared) do print("NEUTRAL_INSTALLED",p.node.Name,p.node.Body.MeshId,p.node.Body.Size.Y,p.node:GetAttribute("SourceTriangles")) end
end
return M
