-- Run once in Studio EDIT mode after importing the two supplied GLBs.
local M={}
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local C=require(RS.RodeoFantasy.MonsterCatalog)
local function prepare(source,old,name)
 assert(source and (source:IsA("Model") or source:IsA("MeshPart")),"Missing imported model: "..name)
 local meshes={}
 local descendants=source:IsA("MeshPart") and {source} or source:GetDescendants()
 for _,part in ipairs(descendants) do
  if part:IsA("MeshPart") then
   assert(part.MeshId~="","Mesh must be uploaded by Studio importer")
   table.insert(meshes,part)
  end
 end
 assert(#meshes>0,"Imported model has no MeshParts")
 local box,size
 if source:IsA("MeshPart") then box,size=source.CFrame,source.Size else box,size=source:GetBoundingBox() end
 local scale=2.5/size.Y
 local frame=CFrame.new(box.Position-Vector3.new(0,size.Y/2,0))
 local model=old:Clone()
 model.Name=name
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 local root=model.PrimaryPart
 assert(root,"Existing template has no root")
 for i,original in ipairs(meshes) do
  local part=original:Clone()
  local relative=frame:ToObjectSpace(original.CFrame)
  local rest=CFrame.new(relative.Position*scale-Vector3.new(0,C.MeadowMouse.RootHeight,0))*relative.Rotation
  part.Name=i==1 and "Body" or "BodyDetail"..i
  part.Size*=scale part.CFrame=root.CFrame*rest
  part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
  part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position)
  -- Preserve imported SurfaceAppearance and material textures unchanged.
  part.Parent=model
 end
 model:SetAttribute("NativeMeshyMossrat",true)
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("MeshDecorated",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",1)
 model:SetAttribute("MeshyBackHeight",1.18)
 return model
end
function M.install(hunt,detail)
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play before installing and saving")
 local package=RS.RodeoFantasy
 -- Prepare every replacement before touching any existing template.
 local replacements={
  {SS,"RodeoMonsterTemplate",prepare(hunt,SS.RodeoMonsterTemplate,"RodeoMonsterTemplate")},
  {package,"VisualTemplate",prepare(detail,package.VisualTemplate,"VisualTemplate")},
  {package,"MeshyMossratHuntTemplate",prepare(hunt,package.VisualTemplate,"MeshyMossratHuntTemplate")},
 }
 for _,entry in ipairs(replacements) do
  local old=entry[1]:FindFirstChild(entry[2])
  if old then old:Destroy() end
  entry[3].Parent=entry[1]
 end
 print("모스랫 1성 설치 완료: 사냥터 경량 / 가방·도감 상세. Ctrl+S로 저장하세요.")
end
return M
