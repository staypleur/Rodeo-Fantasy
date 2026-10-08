-- Local course markings projected from the server's run distance, not global map Z.
local Markers={}
local gates={}
local function create(distance)
 local model=Instance.new("Model") model.Name="LocalDistanceMarker" model:SetAttribute("Meters",distance)
 local function part(name,size,pos,color)
  local p=Instance.new("Part") p.Name=name p.Size=size p.Position=pos p.Color=color
  p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false p.Parent=model return p
 end
 for i=0,19 do
  part("FinishStripe",Vector3.new(3.5,0.04,1.5),Vector3.new(-33.25+i*3.5,0.04,0),i%2==0 and Color3.fromRGB(255,242,203) or Color3.fromRGB(238,134,97))
 end
 for _,side in ipairs({-1,1}) do
  part("Post",Vector3.new(0.6,6,0.6),Vector3.new(side*33,3,0),Color3.fromRGB(112,85,62))
  local board=part("DistanceSign",Vector3.new(7,3,0.4),Vector3.new(side*30,6,0),Color3.fromRGB(63,104,79))
  local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Back gui.CanvasSize=Vector2.new(560,240) gui.Parent=board
  local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
  label.Text=tostring(distance).."m" label.TextColor3=Color3.fromRGB(255,242,203) label.Font=Enum.Font.GothamBold label.TextScaled=true label.Parent=gui
 end
 model.WorldPivot=CFrame.identity model.Parent=workspace return model
end
function Markers.update(active,distance,frame,metersPerStud)
 if not active or not frame then
  for _,gate in pairs(gates) do gate.model:Destroy() end gates={} return
 end
 local nextDistance=1000 -- only the first meadow is implemented
 for value,gate in pairs(gates) do
  if value<nextDistance-1000 or value>nextDistance then gate.model:Destroy() gates[value]=nil end
 end
 -- Keep one forthcoming marker; refresh its projection as flying changes travel speed.
 local gate=gates[nextDistance]
 if not gate then gate={model=create(nextDistance)} gates[nextDistance]=gate end
 gate.model:PivotTo(CFrame.new(0,0,frame.Z-(nextDistance-distance)/metersPerStud))
end
return Markers
