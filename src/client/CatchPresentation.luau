-- Cosmetic throw and landing impulse; capture still belongs to the server.
local Effects={}
local phase,throw,ring,burst,highlight
local debris={}
local broken=setmetatable({},{__mode="k"})
local function anchor(name)
 local p=Instance.new("Part") p.Name=name p.Anchored=true p.Transparency=1
 p.CanCollide,p.CanTouch,p.CanQuery=false,false,false p.Size=Vector3.one p.Parent=workspace
 return p
end
local function circle(parent,count,color,width)
 local points={}
 for i=1,count do local a=Instance.new("Attachment") a.Parent=parent points[i]=a end
 for i=1,count do
  local beam=Instance.new("Beam") beam.Attachment0=points[i] beam.Attachment1=points[i%count+1]
  beam.Width0,beam.Width1,beam.FaceCamera=width,width,true beam.Color=ColorSequence.new(color) beam.Parent=parent
 end
 return points
end
local function clear()
 for _,value in ipairs({throw or false,ring or false,highlight or false}) do if value then value:Destroy() end end
 if burst then burst.part:Destroy() end
 throw,ring,burst,highlight=nil,nil,nil,nil
end
function Effects.update(state,character,frame,clock)
 if state.phase=="Idle" or state.phase=="GameOver" or state.phase=="CourseEnd" then clear() phase=state.phase return 0 end
 if state.phase=="Lassoing" and state.monster and state.monster.PrimaryPart and frame then
  if not throw then
   throw=anchor("LocalThrownLasso") circle(throw,24,Color3.fromRGB(255,222,100),0.12)
   local a,b=Instance.new("Attachment"),Instance.new("Attachment") a.Name="Hand" b.Name="Loop" a.Parent=throw b.Parent=throw
   local line=Instance.new("Beam") line.CurveSize0=2 line.CurveSize1=-1 line.Attachment0,line.Attachment1=a,b line.Width0,line.Width1,line.FaceCamera=0.1,0.1,true
   line.Color=ColorSequence.new(Color3.fromRGB(255,222,100)) line.Parent=throw
  end
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local serverRope=root and root:FindFirstChild("CaptureRope")
  if serverRope then serverRope.Enabled=false end
  local hand=character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
  local origin=hand and hand.Position or frame.Position+Vector3.new(1,1,0)
  local target=state.monster.PrimaryPart.Position+Vector3.new(0,1,0)
  local p=math.clamp((clock-state.started)/(state.landingSeconds or 0.28),0,1)
  local center=origin:Lerp(target,math.min(1,p*1.8))+Vector3.new(0,math.sin(math.pi*p)*2,0)
  throw.CFrame=CFrame.new(center)
  local index=0
  for _,a in ipairs(throw:GetChildren()) do
   if a:IsA("Attachment") and a.Name~="Hand" and a.Name~="Loop" then
    local angle=index/24*math.pi*2 index+=1
    a.Position=Vector3.new(math.cos(angle)*(1.3+p*0.8),math.sin(angle)*0.35,math.sin(angle)*(1+p*0.6))
   end
  end
  throw.Hand.Position=throw.CFrame:PointToObjectSpace(origin) throw.Loop.Position=Vector3.zero
  if not highlight then highlight=Instance.new("Highlight") highlight.Name="LocalCatchGlow" highlight.Parent=workspace end
  highlight.Adornee=state.monster highlight.FillColor=Color3.fromRGB(255,229,113) highlight.OutlineColor=Color3.fromRGB(255,248,213)
  highlight.FillTransparency=0.35+p*0.5 highlight.OutlineTransparency=0.15+p*0.7
 elseif throw then throw:Destroy() throw=nil end
 if state.phase=="Riding" and phase=="Lassoing" and frame then
  if burst then burst.part:Destroy() end
  if ring then ring:Destroy() end
  ring=anchor("LocalLandingRing") ring.Position=Vector3.new(frame.X,0.15,frame.Z)
  burst={part=ring,started=clock,points=circle(ring,40,Color3.fromRGB(247,229,181),0.6)}
 end
 if burst then
  local age=(clock-burst.started)/0.55
  if age>=1 then burst.part:Destroy() burst=nil ring=nil if highlight then highlight:Destroy() highlight=nil end
  else
   local radius=2+age*11
   for i,a in ipairs(burst.points) do local angle=(i-1)/40*math.pi*2 a.Position=Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius) end
   for _,beam in ipairs(burst.part:GetChildren()) do if beam:IsA("Beam") then beam.Transparency=NumberSequence.new(0.25+age*0.75) beam.Width0=0.8*(1-age)+0.1 beam.Width1=beam.Width0 end end
   if highlight then highlight.FillTransparency=0.85+age*0.15 highlight.OutlineTransparency=0.85+age*0.15 end
  end
 end
 phase=state.phase
 return state.phase=="Lassoing" and math.sin(math.pi*math.clamp((clock-state.started)/(state.landingSeconds or 0.28),0,1))*2.5 or 0
end
function Effects.crates(obstacles,position,clock,dt)
 if obstacles and position then
  for _,box in ipairs(obstacles:GetChildren()) do
   if not box:GetAttribute("Broken") then broken[box]=nil end
   if box:GetAttribute("Broken") and not broken[box] then
    broken[box]=true
    if clock-(box:GetAttribute("BrokenAt") or 0)<0.8 and (box.Position-position).Magnitude<160 then
     for i=1,12 do
      local shard=anchor("LocalCrateShard") shard.Transparency=0 shard.Material=Enum.Material.Wood
      local stone=box:GetAttribute("Style")=="MossyRock"
      shard.Material=stone and Enum.Material.Slate or Enum.Material.Wood
      shard.Color=stone and Color3.fromRGB(177,157,123) or Color3.fromRGB(203,148,87)
      shard.Size=stone and Vector3.one*.7 or Vector3.new(1.8,0.35,0.55)
      local angle=i/12*math.pi*2
      shard.CFrame=CFrame.new(box.Position+Vector3.new(math.cos(angle),i%3-1,math.sin(angle)))
      table.insert(debris,{part=shard,origin=shard.CFrame,started=clock,velocity=Vector3.new(math.cos(angle)*12,6+i%4,math.sin(angle)*12)})
     end
    end
   end
  end
 end
 for i=#debris,1,-1 do
  local entry=debris[i] local age=clock-entry.started
  if age>=0.8 then entry.part:Destroy() table.remove(debris,i)
  else entry.part.CFrame=CFrame.new(entry.origin.Position+entry.velocity*age+Vector3.new(0,-16*age*age,0))*CFrame.Angles(age*5,age*3,0) entry.part.Transparency=math.clamp((age-0.5)/0.3,0,1) end
 end
end
return Effects
