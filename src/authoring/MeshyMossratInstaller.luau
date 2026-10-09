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
 assert(hunt,"사냥터용 가져온 모델을 찾지 못했습니다. 탐색기에서 가져온 모스랫을 선택한 뒤 installSelected()를 사용하세요.")
 detail=detail or hunt
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
 print("모스랫 1성 설치 완료: "..(hunt==detail and "선택한 모델을 공용으로 사용" or "사냥터/상세 모델 분리")..". Ctrl+S로 저장하세요.")
end
function M.installSelected()
 local selected=game:GetService("Selection"):Get()
 assert(#selected>=1 and #selected<=2,"탐색기에서 가져온 모스랫 Model 또는 MeshPart 1~2개를 선택하세요.")
 local hunt,detail
 for _,source in ipairs(selected) do
  assert(source:IsA("Model") or source:IsA("MeshPart"),"가져온 모델 전체 또는 MeshPart를 선택하세요. 텍스처/폴더는 설치할 수 없습니다.")
  assert(source:IsDescendantOf(workspace),"Workspace에 가져온 모스랫을 선택하세요.")
  local name=source.Name:lower()
  if name:find("hunt",1,true) then hunt=source end
  if name:find("detail",1,true) then detail=source end
 end
 if #selected==1 then hunt,detail=selected[1],selected[1]
 else assert(hunt and detail and hunt~=detail,"두 모델 선택 시 이름에 각각 Hunt와 Detail이 있어야 합니다. 한 모델만 선택하면 이름과 관계없이 공용으로 설치합니다.") end
 return M.install(hunt,detail)
end
return M
