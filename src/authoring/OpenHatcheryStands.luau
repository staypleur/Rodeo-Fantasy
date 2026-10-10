-- Four low, open egg stands per player room. Existing room materials supply colors.
local M={}
function M.build(room)
 local base=assert(room:FindFirstChild("RoomBase"),"RoomBase 없음")
 local oldPen=room.Pens:FindFirstChild("Pen_1")
 local oldGrass=oldPen and oldPen:FindFirstChild("PenGrass")
 local board=room:FindFirstChild("OwnerBoard")
 local text=board and board:FindFirstChildWhichIsA("TextLabel",true)
 local accent=text and text.TextColor3 or Color3.fromRGB(69,167,172)
 if oldPen then
  for _,n in ipairs(oldPen:GetDescendants()) do
   if n:IsA("BasePart") and n.Material==Enum.Material.Neon then accent=n.Color break end
  end
 end
 local floor=base.Position.Y+base.Size.Y/2
 local origin=CFrame.new(base.Position.X,floor,base.Position.Z)*base.CFrame.Rotation
 local pens=Instance.new("Folder") pens.Name="Pens"
 local function part(parent,name,size,frame,color,material)
  local p=Instance.new("Part") p.Name=name p.Shape=Enum.PartType.Cylinder
  p.Size=size p.CFrame=frame*CFrame.Angles(0,0,math.pi/2)
  p.Color=color p.Material=material p.Anchored=true
  p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=parent
  return p
 end
 for index,pos in ipairs({{-12,-10},{12,-10},{-12,12},{12,12}}) do
  local pen=Instance.new("Model") pen.Name="Pen_"..index pen:SetAttribute("Capacity",1) pen.Parent=pens
  local frame=origin*CFrame.new(pos[1],0,pos[2])
  part(pen,"StandBase",Vector3.new(1,15,15),frame*CFrame.new(0,.5,0),Color3.fromRGB(42,55,73),Enum.Material.SmoothPlastic)
  part(pen,"StandGlow",Vector3.new(.18,14,14),frame*CFrame.new(0,1.08,0),accent,Enum.Material.Neon)
  -- PenGrass remains horizontal for the existing egg placement code.
  local socket=Instance.new("Part") socket.Name="PenGrass" socket.Size=Vector3.new(11,1.2,11)
  socket.CFrame=frame*CFrame.new(0,.7,0) socket.Color=oldGrass and oldGrass.Color or Color3.fromRGB(30,42,61)
  socket.Material=Enum.Material.SmoothPlastic socket.Anchored=true socket.Transparency=1
  socket.CanCollide=false socket.CanTouch=false socket.CanQuery=false socket.Parent=pen
  part(pen,"EggSeat",Vector3.new(.2,11,11),frame*CFrame.new(0,1.2,0),socket.Color,Enum.Material.SmoothPlastic)
  local number=Instance.new("Part") number.Name="StandNumber" number.Size=Vector3.new(4,.1,2)
  number.CFrame=frame*CFrame.new(0,1.34,-5) number.Transparency=1 number.Anchored=true number.CanCollide=false number.CanTouch=false number.CanQuery=false number.Parent=pen
  local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Top gui.CanvasSize=Vector2.new(200,100) gui.Parent=number
  local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1 label.Text=tostring(index)
  label.Font=Enum.Font.GothamBold label.TextScaled=true label.TextColor3=Color3.new(1,1,1) label.Parent=gui
 end
 return pens
end
return M
