-- Applies the requested smooth surfaces to the installed lobby only.
local lobby=workspace:WaitForChild("RodeoLobby")
local roof=lobby:FindFirstChild("Roof") or Instance.new("Model")
roof.Name="Roof" roof.Parent=lobby
if not roof:FindFirstChild("FullOpaqueCeiling") then
 local cap=Instance.new("Part") cap.Name="FullOpaqueCeiling"
 cap.Size=Vector3.new(512,8,512) cap.Position=Vector3.new(6000,102,0)
 cap.Anchored=true cap.CanTouch=false cap.Material=Enum.Material.SmoothPlastic
 cap.Color=Color3.fromRGB(25,35,57) cap.Parent=roof
end
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("Part") then
  part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth
  part.FrontSurface=Enum.SurfaceType.Smooth part.BackSurface=Enum.SurfaceType.Smooth
  part.LeftSurface=Enum.SurfaceType.Smooth part.RightSurface=Enum.SurfaceType.Smooth
  if part.Material==Enum.Material.Plastic then part.Material=Enum.Material.SmoothPlastic end
 end
end
