local M={}
function M.run(map)
 if map:FindFirstChild("LargerLobbyV1") then return end
 for _,part in ipairs(map:GetDescendants()) do
  if part:IsA("BasePart") and not part:FindFirstAncestor("Rocket") and not part:FindFirstAncestor("LobbyCompanions") then
   local cf=part.CFrame local p=cf.Position
   local function snap(n) return math.floor(n/4+.5)*4 end
   part.Size=Vector3.new(math.max(4,snap(part.Size.X*1.2)),part.Size.Y,math.max(4,snap(part.Size.Z*1.2)))
   part.CFrame=CFrame.new(6000+snap((p.X-6000)*1.2),p.Y,snap(p.Z*1.2))*cf.Rotation
  end
 end
 local roof=map:FindFirstChild("Roof")
 for _,part in ipairs(roof:GetChildren()) do if part.Name=="Ceiling" then part:Destroy() end end
 for x=-7,7 do for z=-7,7 do
  if math.abs(x)+math.abs(z)<=11 then
   local part=Instance.new("Part") part.Name="Ceiling" part.Anchored=true
   part.Size=Vector3.new(40,8,40) part.Position=Vector3.new(6000+x*40,92,z*40)
   part.Material=Enum.Material.Plastic part.Color=Color3.fromRGB(30,42,61)
   part.TopSurface=Enum.SurfaceType.Studs part.BottomSurface=Enum.SurfaceType.Inlet
   for _,face in ipairs({"FrontSurface","BackSurface","LeftSurface","RightSurface"}) do part[face]=Enum.SurfaceType.Studs end
   part.CanTouch=false part.Parent=roof
  end
 end end
 map.Airport.Departure.CFrame=CFrame.new(6000,4,-44)
 for _,plot in ipairs(map.Plots:GetChildren()) do
  local board=plot.OwnerBoard
  for _,gui in ipairs(board:GetChildren()) do if gui:IsA("SurfaceGui") then gui.Text.Text="빈 부화실" end end
 end
 local marker=Instance.new("BoolValue") marker.Name="LargerLobbyV1" marker.Value=true marker.Parent=map
end
return M
