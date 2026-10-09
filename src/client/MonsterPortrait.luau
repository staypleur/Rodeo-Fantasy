local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Mesh=require(script.Parent:WaitForChild("CreatureMesh"))
function P.fill(viewport,id,stars,silhouette,distanceScale)
 local world=Instance.new("WorldModel") world.Parent=viewport
 local model=package[C.visual(id,stars)]:Clone()
 local stage=C.stage(stars)
 model:ScaleTo(C.scale(stars)/C.Scales[stage])
 model.Parent=world model:PivotTo(CFrame.new())
 for _,node in ipairs(model:GetDescendants()) do
  if node:IsA("BillboardGui") or node:IsA("Light") then node:Destroy()
  elseif silhouette and node:IsA("SurfaceAppearance") then node:Destroy()
  elseif silhouette and node:IsA("BasePart") then node.Color=Color3.new(0,0,0) node.Material=Enum.Material.SmoothPlastic if node:IsA("MeshPart") then node.TextureID="" end end
 end
 model:SetAttribute("Stars",stars)
 model:SetAttribute("MonsterId",id) model:SetAttribute("PortraitSilhouette",silhouette==true)
 Mesh.decorate(model)
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 local direction=Vector3.new(1,.55,-1.5).Unit
 local function fit()
  local distance=math.max(size.X,size.Y,size.Z)*2.3
  if distanceScale then
   local aspect=viewport.AbsoluteSize.Y>0 and viewport.AbsoluteSize.X/viewport.AbsoluteSize.Y or 1
   local basis=CFrame.lookAt(Vector3.zero,-direction)
   local tangent=math.tan(math.rad(camera.FieldOfView/2))
   distance=0
   for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
    local p=basis:VectorToObjectSpace(frame:VectorToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
    distance=math.max(distance,p.Z+math.abs(p.Y)/tangent,p.Z+math.abs(p.X)/(tangent*math.max(.1,aspect)))
   end end end
   distance*=1.08
  end
  camera.CFrame=CFrame.lookAt(frame.Position+direction*distance,frame.Position)
 end
 fit()
 viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
 camera.Parent=viewport viewport.CurrentCamera=camera
 return model
end
return P
