local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Mesh=require(script.Parent.CreatureMesh)
function P.fill(viewport,id,stars,silhouette)
 local world=Instance.new("WorldModel") world.Parent=viewport
 local model=package[C.visual(id,stars)]:Clone()
 local stage=C.stage(stars)
 model:ScaleTo(C.scale(stars)/C.Scales[stage])
 model.Parent=world model:PivotTo(CFrame.new())
 for _,node in ipairs(model:GetDescendants()) do
  if node:IsA("BillboardGui") or node:IsA("Light") then node:Destroy()
  elseif silhouette and node:IsA("BasePart") then node.Color=Color3.fromRGB(22,28,23) node.Material=Enum.Material.SmoothPlastic end
 end
 model:SetAttribute("Stars",stars)
 Mesh.decorate(model)
 local frame,size=model:GetBoundingBox()
 local camera=Instance.new("Camera") camera.FieldOfView=32
 camera.CFrame=CFrame.lookAt(frame.Position+Vector3.new(1,.55,-1.5).Unit*math.max(size.X,size.Y,size.Z)*2.3,frame.Position)
 camera.Parent=viewport viewport.CurrentCamera=camera
 return model
end
return P
