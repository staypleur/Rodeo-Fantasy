-- Approved lineage, lazily reused across hunt, portraits and ranches.
local M={}
local Asset=game:GetService("AssetService")
local C=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local data=require(script.Parent:WaitForChild("FacetedMouseData"))
local stages,textures,imagePreparing={},{},{}
local pending=setmetatable({},{__mode="k"})
local retryAfter=setmetatable({},{__mode="k"})
function M.isTarget(model)
 return model:GetAttribute("MonsterId")=="MeadowMouse"
end
function M.prepare(stage)
 stage=stage or 1
 local state=stages[stage]
 if not state then state={cache={},resources={}} stages[stage]=state end
 while state.preparing do task.wait() end
 if state.ready or state.failed then return state.ready end
 state.preparing=true
 local definition=data.Stages[stage]
 local cache,resources=state.cache,state.resources
 local builder
 local ok,err=pcall(function()
  while imagePreparing[definition.ImageKey] do task.wait() end
  local texture=textures[definition.ImageKey]
  if not texture then
  imagePreparing[definition.ImageKey]=true
  local image
  local imageOK,imageError=pcall(function()
  image=assert(Asset:CreateEditableImage({Size=Vector2.new(data.ImageSize,data.ImageSize)}),"No image budget")
  -- Shared texture outlives stage caches and every replay/portrait clone.
  local pixels=buffer.create(data.ImageSize*data.ImageSize*4) local offset=0
  local encoded=data.Images[definition.ImageKey]:gsub("%s","")
  for i=1,#encoded,10 do
   local count=tonumber(encoded:sub(i,i+3),16)
   local r=tonumber(encoded:sub(i+4,i+5),16) local g=tonumber(encoded:sub(i+6,i+7),16) local b=tonumber(encoded:sub(i+8,i+9),16)
   local color=r+g*256+b*65536+255*16777216
   for _=1,count do buffer.writeu32(pixels,offset,color) offset+=4 end
  end
  assert(offset==buffer.len(pixels),"Incomplete approved texture")
  image:WritePixelsBuffer(Vector2.zero,Vector2.new(data.ImageSize,data.ImageSize),pixels)
  end)
  imagePreparing[definition.ImageKey]=nil
  if not imageOK then if image then image:Destroy() end error(imageError) end
  texture=image textures[definition.ImageKey]=image
  end
  state.texture=texture
  for _,entry in ipairs(definition.Parts) do
   local mesh=assert(Asset:CreateEditableMesh(),"No mesh budget for "..entry.Name)
   builder=mesh
   for i=1,#entry.Vertices,3 do
    local ids,uvs={},{} local v=entry.Vertices[i]
    local normal=mesh:AddNormal(Vector3.new(v[4],v[5],v[6]))
    for j=i,i+2 do
     local point=entry.Vertices[j]
     ids[#ids+1]=mesh:AddVertex(Vector3.new(point[1],point[2],point[3]))
     uvs[#uvs+1]=mesh:AddUV(Vector2.new(point[7],point[8]))
    end
    local face=mesh:AddTriangle(ids[1],ids[2],ids[3]) mesh:SetFaceNormals(face,{normal,normal,normal}) mesh:SetFaceUVs(face,uvs)
   end
   -- Empty meshes reserve dynamic topology capacity. Keep only compact fixed-size
   -- copies, freeing the single temporary builder before constructing the next part.
   local fixed=assert(Asset:CreateEditableMeshAsync(Content.fromObject(mesh),{FixedSize=true}),"No fixed mesh budget for "..entry.Name)
   resources[#resources+1]=fixed
   mesh:Destroy() builder=nil
   local part=Asset:CreateMeshPartAsync(Content.fromObject(fixed),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
   resources[#resources+1]=part
   part.Name=entry.Name part.Color=Color3.new(1,1,1) part.Anchored=true
   part.CanCollide,part.CanTouch,part.CanQuery=false,false,false
   part.DoubleSided=true
   cache[#cache+1]={part=part,center=Vector3.new(unpack(entry.Center)),pivot=Vector3.new(unpack(entry.Pivot))}
  end
 end)
 state.ready=ok state.failed=not ok state.preparing=false
 if not ok then
  if builder then builder:Destroy() builder=nil end
  state.cache={}
  for _,resource in ipairs(resources) do resource:Destroy() end resources={}
  warn("Approved mouse failed to load; existing visual retained. Actual error: "..tostring(err))
 end
 return state.ready
end
function M.apply(model)
 if not M.isTarget(model) then return false end
 local stars=model:GetAttribute("Stars") or 1
 local stage=C.stage(stars) local definition=data.Stages[stage]
 if model:GetAttribute("FacetedMouseRevision")==definition.Revision or pending[model] then return false end
 if retryAfter[model] and os.clock()<retryAfter[model] then return false end
 pending[model]=true
 if not M.prepare(stage) or not model.Parent or not model.PrimaryPart then pending[model]=nil return false end
 local state=stages[stage]
 local root=model.PrimaryPart local scale=C.scale(stars)/C.Scales[stage]
 local rootHeight=C.MeadowMouse.RootHeight*C.scale(stars)
 local silhouette=model:GetAttribute("PortraitSilhouette")==true local staged={}
 local ok,err=pcall(function() for _,entry in ipairs(state.cache) do
  local part=entry.part:Clone() part.Size*=scale
  staged[#staged+1]=part
  local rest=CFrame.new((entry.center+Vector3.new(0,-definition.GroundY,0))*scale-Vector3.new(0,rootHeight,0))
  part:SetAttribute("ApprovedRest",rest)
  part:SetAttribute("ApprovedPivot",(entry.pivot+Vector3.new(0,-definition.GroundY,0))*scale-Vector3.new(0,rootHeight,0))
  part.CFrame=root.CFrame*rest
  if silhouette then
   for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
   part.TextureID="" part.Color=Color3.new(0,0,0)
  else
   -- This model needs a base-color map only. Avoid per-part PBR texture-pack
   -- creation across every replay; bind the same retained image to MeshPart.
   for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
   part.TextureContent=Content.fromObject(state.texture)
  end
 end end)
 if not ok or not model.Parent then
  for _,part in ipairs(staged) do part:Destroy() end
  pending[model]=nil
  retryAfter[model]=os.clock()+5
  if not ok then warn("Approved mouse texture binding failed; existing visual retained: "..tostring(err)) end
  return false
 end
 if not model:GetAttribute("ApprovedVisualGuard") then
  model:SetAttribute("ApprovedVisualGuard",true)
  -- Server template parts can arrive after the client replacement (streaming /
  -- late replication). They must not reappear above the approved local model.
  model.DescendantAdded:Connect(function(part)
   if part:IsA("BasePart") and part~=root and not part:GetAttribute("ApprovedRest") then
    task.defer(function()
     if part.Parent and part:IsDescendantOf(model) and not part:GetAttribute("ApprovedRest") then part:Destroy() end
    end)
   end
  end)
 end
 model:SetAttribute("ImportedA",true)
 for _,old in ipairs(model:GetDescendants()) do if old:IsA("BasePart") and old~=root then old:Destroy() end end
 for _,part in ipairs(staged) do part.CFrame=root.CFrame*part:GetAttribute("ApprovedRest") part.Parent=model end
 model:SetAttribute("MeshDecorated",true) model:SetAttribute("FacetedMouseRevision",definition.Revision)
 retryAfter[model]=nil
 pending[model]=nil return true
end
return M
