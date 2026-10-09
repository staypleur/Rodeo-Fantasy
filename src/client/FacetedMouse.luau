-- Approved A1 meshes, reused across hunt, portraits and ranches.
local M={}
local Asset=game:GetService("AssetService")
local C=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local data=require(script.Parent.FacetedMouseData)
local cache,resources={},{}
local preparing,ready,failed=false,false,false
local pending=setmetatable({},{__mode="k"})
function M.isTarget(model)
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1
end
function M.prepare()
 while preparing do task.wait() end
 if ready or failed then return ready end
 preparing=true
 local ok,err=pcall(function()
  local image=assert(Asset:CreateEditableImage({Size=Vector2.new(data.ImageSize,data.ImageSize)}),"No image budget")
  resources[#resources+1]=image
  local pixels=buffer.create(data.ImageSize*data.ImageSize*4) local offset=0
  local encoded=data.ImageRLE:gsub("%s","")
  for i=1,#encoded,10 do
   local count=tonumber(encoded:sub(i,i+3),16)
   local r=tonumber(encoded:sub(i+4,i+5),16) local g=tonumber(encoded:sub(i+6,i+7),16) local b=tonumber(encoded:sub(i+8,i+9),16)
   local color=r+g*256+b*65536+255*16777216
   for _=1,count do buffer.writeu32(pixels,offset,color) offset+=4 end
  end
  assert(offset==buffer.len(pixels),"Incomplete approved texture")
  image:WritePixelsBuffer(Vector2.zero,Vector2.new(data.ImageSize,data.ImageSize),pixels)
  local surface=Asset:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(image)}) resources[#resources+1]=surface
  for _,entry in ipairs(data.Parts) do
   local mesh=assert(Asset:CreateEditableMesh(),"No mesh budget") resources[#resources+1]=mesh
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
   local part=Asset:CreateMeshPartAsync(Content.fromObject(mesh),{CollisionFidelity=Enum.CollisionFidelity.Box})
   part.Name=entry.Name part.Color=Color3.new(1,1,1) part.Anchored=true
   part.CanCollide,part.CanTouch,part.CanQuery=false,false,false
   part.DoubleSided=true part.RenderFidelity=Enum.RenderFidelity.Precise
   surface:Clone().Parent=part
   cache[#cache+1]={part=part,center=Vector3.new(unpack(entry.Center))}
  end
 end)
 ready=ok failed=not ok preparing=false
 M.failed=failed
 if not ok then
  for _,entry in ipairs(cache) do entry.part:Destroy() end cache={}
  for _,resource in ipairs(resources) do resource:Destroy() end resources={}
  warn("Approved mouse failed to load. Enable Mesh / Image APIs in Game Settings > Security or import the approved GLB. Existing visual retained. "..tostring(err))
 end
 return ready
end
function M.apply(model)
 if not M.isTarget(model) or model:GetAttribute("FacetedMouseRevision")==data.Revision or pending[model] then return false end
 pending[model]=true
 if not M.prepare() or not model.Parent or not model.PrimaryPart then pending[model]=nil return false end
 local root=model.PrimaryPart local scale=C.scale(model:GetAttribute("Stars") or 1)
 local silhouette=model:GetAttribute("PortraitSilhouette")==true local staged={}
 for _,entry in ipairs(cache) do
  local part=entry.part:Clone() part.Size*=scale
  part.CFrame=root.CFrame*CFrame.new((entry.center+Vector3.new(0,-data.GroundY-C.MeadowMouse.RootHeight,0))*scale)
  if silhouette then
   for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
   part.TextureID="" part.Color=Color3.new(0,0,0)
  end
  staged[#staged+1]=part
 end
 model:SetAttribute("ImportedA",true)
 for _,old in ipairs(model:GetChildren()) do if old:IsA("BasePart") and old~=root then old:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("MeshDecorated",true) model:SetAttribute("FacetedMouseRevision",data.Revision)
 pending[model]=nil return true
end
return M
