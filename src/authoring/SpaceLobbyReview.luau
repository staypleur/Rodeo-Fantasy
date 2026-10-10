-- Standalone design review. Does not replace RodeoLobby or player inventories.
local Layout=require(script.Parent.SpaceLobbyLayout)
local Review={}
function Review.create(parent,backup,origin)
 origin=origin or Vector3.new(0,8,0)
 local model=Instance.new("Model") model.Name="SpaceLobbyReview"
 model:SetAttribute("SpaceLobbyReview",true)
 model:SetAttribute("LobbyCapacity",8) model:SetAttribute("CafeCapacity",20)
 model:SetAttribute("CompanionsPerPlayer",1) model:SetAttribute("LobbyRiding",false)
 local groups={}
 local ok,err=pcall(function()
  for _,b in ipairs(Layout.build()) do
   local group=groups[b.group]
   if not group then group=Instance.new("Model") group.Name=b.group group.Parent=model groups[b.group]=group end
   local p=Instance.new("Part") p.Name=b.name p.Shape=Enum.PartType.Block
   p.Size=Vector3.new(table.unpack(b.size))
   p.CFrame=CFrame.new(origin+Vector3.new(table.unpack(b.pos)))*CFrame.Angles(0,math.rad(b.yaw),0)
   p.Color=Color3.fromRGB(table.unpack(b.color)) p.Material=Enum.Material.Plastic
   p.TopSurface=Enum.SurfaceType.Studs p.BottomSurface=Enum.SurfaceType.Inlet
   for _,face in ipairs({"FrontSurface","BackSurface","LeftSurface","RightSurface"}) do p[face]=Enum.SurfaceType.Studs end
   p.Anchored=true p.CanCollide=b.collide p.CanTouch=false p.Parent=group
   if b.name=="DoorSensor" then p.Transparency=1 end
   if b.text then
    local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Front gui.PixelsPerStud=25 gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.Parent=p
    local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
    label.Text=b.text label.TextScaled=true label.Font=Enum.Font.GothamBold label.TextColor3=Color3.fromRGB(28,44,60) label.Parent=gui
   end
  end
 end)
 if not ok then model:Destroy() error(err,0) end
 -- Only earlier review models are archived; real lobby/airship are preserved.
 for _,old in ipairs(parent:GetChildren()) do
  if old.Name==model.Name and old:GetAttribute("SpaceLobbyReview")==true then old.Parent=backup end
 end
 model.Parent=parent
 return model
end
return Review
