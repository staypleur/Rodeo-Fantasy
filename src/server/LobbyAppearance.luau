-- Lobby roof and owner labels; personal rooms deliberately remain open above.
local M={}
local function part(parent,name,size,cf,color,material)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material
 p.Anchored=true p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Reflectance=0 p.Parent=parent return p
end
function M.ensure(lobby)
 local roof=lobby:FindFirstChild("Roof")
 if not roof then roof=Instance.new("Model") roof.Name="Roof" roof.Parent=lobby end
 if not roof:FindFirstChild("FullGlassCeiling") then
  local glass=part(roof,"FullGlassCeiling",Vector3.new(512,2,512),CFrame.new(6000,102,0),Color3.fromRGB(173,212,232),Enum.Material.Glass)
  glass.Transparency=.9 glass.CastShadow=false
 end
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  if not room:FindFirstChild("OwnerBoard") then
   local base=room.RoomBase
   local origin=CFrame.new(base.Position.X,base.Position.Y+base.Size.Y/2,base.Position.Z)*base.CFrame.Rotation
   local board=part(room,"OwnerBoard",Vector3.new(28,5,1),origin*CFrame.new(0,34,-39),Color3.fromRGB(18,30,49),Enum.Material.SmoothPlastic)
   board.CanCollide=false
   local gui=Instance.new("SurfaceGui") gui.Name="OwnerName" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(840,150) gui.Parent=board
   local label=Instance.new("TextLabel") label.Name="Text" label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
   label.Text="" label.TextSize=68 label.Font=Enum.Font.GothamBold label.TextColor3=Color3.fromRGB(163,227,255) label.Parent=gui
  end
 end
 local planet=lobby:FindFirstChild("CeilingPlanet")
 if planet and not lobby:FindFirstChild("PlanetAura") then
  local aura=Instance.new("Model") aura.Name="PlanetAura" aura.Parent=lobby
  local box=planet:GetBoundingBox()
  for i,size in ipairs({250,272,294}) do
   local glow=part(aura,"VioletHalo"..i,Vector3.one*size,CFrame.new(box.Position),Color3.fromRGB(151,58,255),Enum.Material.Neon)
   glow.Shape=Enum.PartType.Ball glow.Transparency=({.9,.96,.98})[i]
   glow.CanCollide=false glow.CanQuery=false glow.CastShadow=false
  end
 end
end
return M
