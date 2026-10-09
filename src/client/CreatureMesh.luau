-- Shared original geometry: faceted young bodies, pointed leaves, smooth final forms.
-- Mesh content is reused across all visible creatures; authoritative roots stay untouched.
local M={}
local Asset=game:GetService("AssetService")
local FacetedMouse=require(script.Parent:WaitForChild("FacetedMouse"))
local NativeMossrat=require(script.Parent:WaitForChild("NativeMossrat"))
local cache,contents,pending={},{},{}
local builder
local function build(kind)
 local mesh=assert(Asset:CreateEditableMesh(),"Editable mesh budget unavailable")
 builder=mesh
 local function vertex(x,y,z) return mesh:AddVertex(Vector3.new(x,y,z)) end
 local function triangle(a,b,c)
  local face=mesh:AddTriangle(a,b,c)
  local normal=(mesh:GetPosition(b)-mesh:GetPosition(a)):Cross(mesh:GetPosition(c)-mesh:GetPosition(a))
  if normal.Magnitude>.00001 then
   if kind=="Smooth" then
    local normals={} for _,id in ipairs({a,b,c}) do normals[#normals+1]=mesh:AddNormal(mesh:GetPosition(id).Unit) end
    mesh:SetFaceNormals(face,normals)
   else local n=mesh:AddNormal(normal.Unit) mesh:SetFaceNormals(face,{n,n,n}) end
  end
 end
 if kind=="Leaf" then
  local rows={}
  for j=0,8 do
   local t=j/8 local width=.5*math.sin(math.pi*t)^.8+.005
   local y=.38*math.sin(math.pi*t) local z=t-.5
   rows[j+1]={vertex(-width,y-.15,z),vertex(0,y,z),vertex(width,y-.15,z),vertex(0,y-.3,z)}
  end
  for j=1,8 do
   for k=1,4 do local n=k%4+1
    triangle(rows[j][k],rows[j+1][k],rows[j+1][n]) triangle(rows[j][k],rows[j+1][n],rows[j][n])
   end
  end
 elseif kind=="Clover" then
  local upper,lower={},{}
  for j=1,24 do
   local a=2*math.pi*(j-1)/24
   local x=math.sin(a)^3*.5 local z=-(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/32
   upper[j]=vertex(x,.5,z) lower[j]=vertex(x,-.5,z)
  end
  local top,bottom=vertex(0,.5,0),vertex(0,-.5,0)
  for j=1,24 do local n=j%24+1 triangle(top,upper[j],upper[n]) triangle(bottom,lower[n],lower[j]) triangle(upper[j],lower[j],lower[n]) triangle(upper[j],lower[n],upper[n]) end
 else
  local sides=kind=="Smooth" and 24 or 10
  local rings=kind=="Smooth" and 14 or 6
  local top=vertex(0,.5,0) local bottom=vertex(0,-.5,0) local rows={}
  for r=1,rings-1 do
   local latitude=math.pi*r/rings rows[r]={}
   for i=1,sides do
    local a=2*math.pi*(i-1)/sides
    rows[r][i]=vertex(math.sin(latitude)*math.cos(a)*.5,math.cos(latitude)*.5,math.sin(latitude)*math.sin(a)*.5)
   end
  end
  for i=1,sides do
   local j=i%sides+1 triangle(top,rows[1][j],rows[1][i])
   triangle(bottom,rows[#rows][i],rows[#rows][j])
   for r=1,#rows-1 do
    triangle(rows[r][i],rows[r][j],rows[r+1][j]) triangle(rows[r][i],rows[r+1][j],rows[r+1][i])
   end
  end
 end
 local fixed=assert(Asset:CreateEditableMeshAsync(Content.fromObject(mesh),{FixedSize=true}),"Fixed mesh budget unavailable")
 contents[kind]=fixed
 mesh:Destroy() builder=nil
 local part=Asset:CreateMeshPartAsync(Content.fromObject(fixed),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
 cache[kind]=part
 part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
 part.DoubleSided=true
 return part
end
function M.prepare()
 if M.failed then return false end
 while pending.prepare do task.wait() end
 if M.ready then return true end
 pending.prepare=true
 local ok,err=pcall(function() for _,kind in ipairs({"Faceted","Smooth","Leaf","Clover"}) do if not cache[kind] then build(kind) end end end)
 if not ok then
  if builder then builder:Destroy() builder=nil end
  for _,part in pairs(cache) do part:Destroy() end cache={}
  for _,mesh in pairs(contents) do mesh:Destroy() end contents={}
  warn("Creature mesh unavailable; native models retained: "..tostring(err))
 end
 M.ready=ok M.failed=not ok pending.prepare=false return ok
end
function M.animate(model,phase,moving,angry)
 NativeMossrat.animate(model,phase,moving,angry)
end
function M.materialize(model)
 if NativeMossrat.isTarget(model) then NativeMossrat.apply(model) return end
 if not FacetedMouse.failed and FacetedMouse.isTarget(model) and not model:GetAttribute("FacetedMouseRevision") then task.spawn(FacetedMouse.apply,model) end
 if model:FindFirstChild("Body") or not model.PrimaryPart then return end
 local package=game.ReplicatedStorage.RodeoFantasy
 local C=require(package.MonsterCatalog)
 local id=model:GetAttribute("MonsterId") or "MeadowMouse"
 local template=package[C.visual(id,model:GetAttribute("Stars") or 1)]
 for _,original in ipairs(template:GetChildren()) do
  if original:IsA("BasePart") and original~=template.PrimaryPart then
   local part=original:Clone()
   part.CFrame=model.PrimaryPart.CFrame*template.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   part.Parent=model
  end
 end
end
function M.decorate(model)
 if NativeMossrat.isTarget(model) then NativeMossrat.apply(model) return end
 if FacetedMouse.isTarget(model) then FacetedMouse.apply(model) return end
 if model:GetAttribute("MeshDecorated") or pending[model] then return end
 pending[model]=true
 if not M.ready then M.prepare() end
 if not M.ready then pending[model]=nil return end
 for _,old in ipairs(model:GetChildren()) do
  if not old:IsA("Part") or old==model.PrimaryPart or old.Transparency>=1 then continue end
  local leaf=(old.Name:find("Leaf") or old.Name:find("Sprout") or old.Name:find("Clover") or old.Name:find("Grass")) and not old.Name:find("Vein")
  local kind=old.Name:find("Clover") and "Clover" or leaf and "Leaf" or old.Shape==Enum.PartType.Ball and ((model:GetAttribute("Stars") or 1)>=9 and "Smooth" or "Faceted") or nil
  if not kind then continue end
  local template=cache[kind] if not template then continue end
  local part=template:Clone()
  part.Name=old.Name part.Size=old.Size part.CFrame=old.CFrame part.Color=old.Color
  part.Transparency=old.Transparency part.LocalTransparencyModifier=old.LocalTransparencyModifier
  part.Material=old.Material part.CastShadow=old.CastShadow
  for _,child in ipairs(old:GetChildren()) do child.Parent=part end
  part.Parent=model old:Destroy()
 end
 model:SetAttribute("MeshDecorated",true) pending[model]=nil
end
return M
