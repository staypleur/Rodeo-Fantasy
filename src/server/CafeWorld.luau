-- Built from the same measured layout used for the review image.
local W={Spawn=CFrame.new(0,5,-84)}
function W.build()
 local existing=workspace:FindFirstChild("RodeoCafe")
 if existing then
  local layout=require(script.Parent.CafeLayout)
  for _,p in ipairs(existing:GetChildren()) do
   local index=p:FindFirstChild("LayoutIndex")
   if p:IsA("BasePart") and index and layout[index.Value] then
    local item=layout[index.Value] p.Material=Enum.Material[item.material or "SmoothPlastic"]
   end
  end
  return existing
 end
 local model=Instance.new("Model") model.Name="RodeoCafe"
 local layout=require(script.Parent.CafeLayout)
 for _,item in ipairs(layout) do
  local p=Instance.new(item.class or "Part") p.Name=item.name
  p.Size=Vector3.new(unpack(item.size)) p.CFrame=CFrame.new(unpack(item.pos))*CFrame.Angles(0,math.rad(item.yaw or 0),0)
  p.Color=Color3.fromRGB(unpack(item.color)) p.Anchored=true
  p.Material=Enum.Material[item.material or "SmoothPlastic"] p.Transparency=item.alpha or 0
  p.CanCollide=item.collide~=false p.CanTouch=false
  if item.shape then p.Shape=Enum.PartType[item.shape] end
  p.Parent=model
  if item.text then
   local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Front gui.PixelsPerStud=30 gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.Parent=p
   local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1) label.Text=item.text label.TextScaled=true label.Font=Enum.Font.GothamBold label.TextColor3=Color3.fromRGB(251,232,185) label.Parent=gui
  end
  if item.light then local l=Instance.new("PointLight") l.Color=Color3.fromRGB(255,221,167) l.Brightness=.8 l.Range=18 l.Shadows=false l.Parent=p end
 end
 model.Parent=workspace
 local spawn=Instance.new("SpawnLocation") spawn.Name="CafeSpawn" spawn.Size=Vector3.new(8,1,8) spawn.Position=Vector3.new(0,0,-84) spawn.Transparency=1 spawn.Anchored=true spawn.CanCollide=false spawn.Neutral=true spawn.Duration=0 spawn.Parent=model
 return model
end
return W
