-- Original, asset-free circular taming indicator following the rendered mount.
local Gauge={}
local anchor,billboard,heart
local segments={}
local function create()
 anchor=Instance.new("Part")
 anchor.Name="LocalTamingGaugeAnchor" anchor.Anchored=true anchor.Transparency=1
 anchor.CanCollide,anchor.CanTouch,anchor.CanQuery=false,false,false
 anchor.Size=Vector3.one anchor.Parent=workspace
 billboard=Instance.new("BillboardGui")
 billboard.Name="MountedTamingGauge" billboard.Size=UDim2.fromOffset(82,82)
 billboard.AlwaysOnTop=true billboard.Adornee=anchor billboard.Parent=anchor
 local disk=Instance.new("Frame") disk.Size=UDim2.fromScale(1,1)
 disk.BackgroundColor3=Color3.fromRGB(66,61,48) disk.BackgroundTransparency=0.15 disk.BorderSizePixel=0 disk.Parent=billboard
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(1,0) corner.Parent=disk
 for i=1,64 do
  local angle=(i-0.5)/64*math.pi*2-math.pi/2
  local segment=Instance.new("Frame")
  segment.Name="Arc"..i segment.AnchorPoint=Vector2.new(0.5,0.5)
  segment.Position=UDim2.fromScale(0.5+math.cos(angle)*0.44,0.5+math.sin(angle)*0.44)
  segment.Size=UDim2.fromOffset(7,4.3) segment.Rotation=math.deg(angle)
  segment.BorderSizePixel=0 segment.BackgroundColor3=Color3.fromRGB(106,99,78) segment.Parent=disk
  segments[i]=segment
 end
 heart=Instance.new("TextLabel") heart.Name="Heart" heart.Size=UDim2.fromScale(1,1)
 heart.BackgroundTransparency=1 heart.Text="♥" heart.Font=Enum.Font.GothamBlack
 heart.TextSize=44 heart.TextColor3=Color3.fromRGB(255,139,209) heart.Parent=disk
end
function Gauge.update(frame,progress,tamed,angry)
 if not frame then if billboard then billboard.Enabled=false end return end
 if not anchor then create() end
 billboard.Enabled=true anchor.CFrame=frame*CFrame.new(3.5,5,0)
 local completed=math.floor(math.clamp(progress,0,1)*64+0.0001)
 for i,segment in ipairs(segments) do
  segment.BackgroundColor3=i<=completed and Color3.fromRGB(255,137,207) or Color3.fromRGB(106,99,78)
 end
 heart.Text=angry and "!" or "♥"
 heart.TextColor3=angry and Color3.fromRGB(255,167,96) or Color3.fromRGB(255,139,209)
 heart.TextTransparency=tamed and 0 or 0.1
end
return Gauge
