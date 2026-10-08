-- Local presentation only; server still owns capture, movement and collisions.
local Presentation = {}
local character, animate, animateDisabled
local joints, dust = {}, {}
local lastDust = 0
local shadow, trail, trailEnd
local function restore()
 for joint,rest in pairs(joints) do if joint.Parent then joint.C0=rest end end
 if animate and animate.Parent then animate.Disabled=animateDisabled end
 joints={}
 if shadow then shadow:Destroy() shadow=nil end
 if trail then trail.Parent:Destroy() trail=nil end
 if trailEnd then trailEnd:Destroy() trailEnd=nil end
 character,animate=nil,nil
end
function Presentation.update(model,phase,frame,dt,clock)
 local active=phase~="Idle" and phase~="GameOver"
 if character and (character~=model or not active) then restore() end
 local root=model and model:FindFirstChild("HumanoidRootPart")
 if active and root and not character then
  character=model
  animate=model:FindFirstChild("Animate")
  if animate then animateDisabled=animate.Disabled animate.Disabled=true end
  local humanoid=model:FindFirstChildOfClass("Humanoid")
  local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
  if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end end
  for _,joint in ipairs(model:GetDescendants()) do
   if joint:IsA("Motor6D") then joints[joint]=joint.C0 joint.Transform=CFrame.identity end
  end
  shadow=Instance.new("Part")
  shadow.Name="LocalRiderShadow"
  shadow.Shape=Enum.PartType.Cylinder
  shadow.Size=Vector3.new(0.04,4,4)
  shadow.Color=Color3.fromRGB(71,89,54)
  shadow.Transparency=0.65
  shadow.Anchored,shadow.CanCollide,shadow.CanTouch,shadow.CanQuery=true,false,false,false
  shadow.Parent=workspace
  local a=Instance.new("Attachment") a.Name="FlightTrailAnchor" a.Position=Vector3.new(-0.7,0,0) a.Parent=root
  local b=Instance.new("Attachment") b.Name="FlightTrailEnd" b.Position=Vector3.new(0.7,0,0) b.Parent=a
  -- Both attachments must be parented to the root to use its coordinate space.
  b.Parent=root trailEnd=b
  trail=Instance.new("Trail") trail.Attachment0,trail.Attachment1=a,b
  trail.Color=ColorSequence.new(Color3.fromRGB(255,236,172))
  trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.45),NumberSequenceKeypoint.new(1,1)})
  trail.Lifetime,trail.FaceCamera,trail.Parent=0.18,true,a
 end
 if active and root and frame then
  local airborne=phase=="Airborne" or phase=="Lassoing"
  root.CFrame=frame * CFrame.Angles(airborne and -0.5 or 0,0,0)
  for joint,rest in pairs(joints) do
   if not joint.Parent then joints[joint]=nil continue end
   local name=joint.Name:gsub(" ","")
   local offset=CFrame.identity
   if name:find("Shoulder") then
    local side=name:find("Left") and -1 or 1
    offset=CFrame.Angles(airborne and -0.65 or -0.8,0,side*(airborne and 0.9 or 0.18))
   elseif name:find("Hip") then
    local side=name:find("Left") and -1 or 1
    offset=CFrame.Angles(airborne and -0.2 or -0.8,0,side*(airborne and 0.25 or 0.18))
   elseif name:find("Knee") then offset=CFrame.Angles(airborne and 0.25 or 1.1,0,0)
   elseif name=="Waist" then offset=CFrame.Angles(airborne and 0.08 or 0.15,0,0) end
   joint.C0=joint.C0:Lerp(rest*offset,1-math.exp(-18*dt))
  end
  shadow.CFrame=CFrame.new(frame.X,0.055,frame.Z)*CFrame.Angles(0,0,math.pi/2)
  shadow.Transparency=airborne and 0.5 or 0.75
  trail.Enabled=airborne
  if phase=="Riding" and clock-lastDust>0.08 then
   lastDust=clock
   local puff=Instance.new("Part")
   puff.Name="LocalHoofDust" puff.Anchored=true
   puff.CanCollide,puff.CanTouch,puff.CanQuery=false,false,false
   puff.Color=Color3.fromRGB(239,220,176) puff.Material=Enum.Material.SmoothPlastic
   puff.Size=Vector3.new(0.5,0.5,0.5) puff.Transparency=0.45
   puff.Position=Vector3.new(frame.X+math.sin(clock*31),0.3,frame.Z+2)
   puff.Parent=workspace
   table.insert(dust,{part=puff,started=clock})
  end
 end
 for i=#dust,1,-1 do
  local entry=dust[i] local p=(clock-entry.started)/0.45
  if p>=1 then entry.part:Destroy() table.remove(dust,i)
  else
   entry.part.Transparency=0.45+p*0.55
   entry.part.Size=Vector3.one*(0.5+p*0.65)
   entry.part.Position+=Vector3.new(0,dt*0.6,0)
  end
 end
end
function Presentation.clear() restore() end
return Presentation
