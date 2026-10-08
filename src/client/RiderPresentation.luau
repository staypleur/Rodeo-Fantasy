-- Local presentation only; server still owns capture, movement and collisions.
local Presentation = {}
local character, animate, animateDisabled
local joints, dust = {}, {}
local constraints={}
-- Transform is evaluated by the avatar animator before physics each frame.
game:GetService("RunService").PreSimulation:Connect(function()
 for joint,rest in pairs(constraints) do
  if joint.Parent and rest.pose then joint.Transform=rest.pose end
 end
end)
local lastDust = 0
local shadow, trail, trailEnd
local rope, ropePoints, ropeTail
local previousPhase
local function restore()
 for joint,rest in pairs(joints) do if joint.Parent then joint.C0=rest end end
 if animate and animate.Parent then animate.Disabled=animateDisabled end
 for joint,rest in pairs(constraints) do if joint.Parent then joint.Transform=rest.transform end end
 constraints={}
 joints={}
 if shadow then shadow:Destroy() shadow=nil end
 if trail then trail.Parent:Destroy() trail=nil end
 if trailEnd then trailEnd:Destroy() trailEnd=nil end
 if rope then rope:Destroy() rope=nil end
 previousPhase=nil
 character,animate=nil,nil
end
function Presentation.update(model,phase,frame,dt,clock,dashUntil)
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
   if joint:IsA("Motor6D") then joints[joint]=joint.C0 joint.Transform=CFrame.identity
   elseif joint:IsA("AnimationConstraint") and joint.Attachment0 then
    constraints[joint]={frame=joint.Attachment0.CFrame,transform=joint.Transform,pose=CFrame.identity}
    joint.Transform=CFrame.identity
   end
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
  -- Parts and joints may arrive after HumanoidRootPart during character replication.
  for _,joint in ipairs(model:GetDescendants()) do
   if joint:IsA("Motor6D") and not joints[joint] then joints[joint]=joint.C0 joint.Transform=CFrame.identity
   elseif joint:IsA("AnimationConstraint") and joint.Attachment0 and not constraints[joint] then
    constraints[joint]={frame=joint.Attachment0.CFrame,transform=joint.Transform,pose=CFrame.identity}
   end
  end
  local airborne=phase=="Airborne" or phase=="Lassoing"
  root.CFrame=frame * CFrame.Angles(phase=="Lassoing" and -0.28 or airborne and -0.5 or 0,0,0)
  local function poseOffset(name)
   name=name:gsub(" ","")
   local offset=CFrame.identity
   if name:find("Shoulder") then
    local side=name:find("Left") and -1 or 1
    offset=phase=="Lassoing" and (side==1 and CFrame.Angles(1.8,0,0.35) or CFrame.Angles(0.2,0,-1.0)) or airborne and CFrame.Angles(0,0,side*math.pi/2) or (side==1 and CFrame.Angles(0.12*math.sin(clock*15),0,2.65) or CFrame.Angles(0.65,0,-0.15))
   elseif name:find("Hip") then
    local side=name:find("Left") and -1 or 1
    offset=CFrame.Angles(airborne and 0 or 1.2,0,side*(airborne and 0.65 or 0.3))
   elseif name:find("Knee") then offset=CFrame.Angles(airborne and 0 or -1.2,0,0)
   elseif name=="Waist" then offset=CFrame.Angles(airborne and 0.08 or 0.15,0,0) end
   return offset
  end
  for joint,rest in pairs(joints) do
   if not joint.Parent then joints[joint]=nil continue end
   local target=CFrame.new(rest.Position)*poseOffset(joint.Name)*rest.Rotation
   joint.C0=joint.C0:Lerp(target,1-math.exp(-18*dt))
  end
  -- Upgraded R15 avatars have AnimationConstraints rather than Motor6Ds.
  for joint,rest in pairs(constraints) do
   if not joint.Parent then constraints[joint]=nil continue end
   local target=CFrame.new(rest.frame.Position)*poseOffset(joint.Name)*rest.frame.Rotation
   rest.pose=rest.pose:Lerp(rest.frame:Inverse()*target,1-math.exp(-18*dt))
   joint.Transform=rest.pose
  end
  if phase=="Riding" then
   if not rope then
    rope=Instance.new("Part") rope.Name="LocalCowboyLasso"
    rope.Anchored,rope.CanCollide,rope.CanTouch,rope.CanQuery=true,false,false,false
    rope.Transparency=1 rope.Size=Vector3.one rope.Parent=workspace
    ropePoints={}
    for i=1,24 do local a=Instance.new("Attachment") a.Parent=rope ropePoints[i]=a end
    ropeTail=Instance.new("Attachment") ropeTail.Parent=rope
    for i=1,25 do
     local beam=Instance.new("Beam")
     beam.Attachment0=i==25 and ropeTail or ropePoints[i]
     beam.Attachment1=i==25 and ropePoints[1] or ropePoints[i%24+1]
     beam.Width0,beam.Width1,beam.FaceCamera=0.09,0.09,true
     beam.Color=ColorSequence.new(Color3.fromRGB(236,192,101)) beam.Parent=rope
    end
   end
   rope.CFrame=root.CFrame
   local hand=model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
   ropeTail.Position=hand and root.CFrame:PointToObjectSpace(hand.Position) or Vector3.new(1,2,0)
   local spin=CFrame.new(0.6,2.8,0)*CFrame.Angles(0,(clock*15)%(math.pi*2),0)*CFrame.Angles(0.25,0,0)
   for i,a in ipairs(ropePoints) do
    local angle=(i-1)/24*math.pi*2
    a.Position=spin:PointToWorldSpace(Vector3.new(math.cos(angle)*1.7,0,math.sin(angle)*1.25))
   end
  elseif rope then rope:Destroy() rope=nil end
  shadow.CFrame=CFrame.new(frame.X,0.055,frame.Z)*CFrame.Angles(0,0,math.pi/2)
  shadow.Transparency=airborne and 0.5 or 0.75
  trail.Enabled=airborne or (phase=="Riding" and dashUntil~=nil and clock<dashUntil)
  if phase=="Riding" and previousPhase and previousPhase~="Riding" then
   for i=1,22 do
    local puff=Instance.new("Part") puff.Name="LocalLandingDust"
    puff.Anchored,puff.CanCollide,puff.CanTouch,puff.CanQuery=true,false,false,false
    puff.Color=Color3.fromRGB(239,220,176) puff.Size=Vector3.one*(1.2+i%3*0.35) puff.Transparency=0.45
    local angle=i/22*math.pi*2
    puff.Position=Vector3.new(frame.X+math.cos(angle)*4,0.5,frame.Z+math.sin(angle)*4)
    puff.Parent=workspace table.insert(dust,{part=puff,started=clock,velocity=Vector3.new(math.cos(angle)*12,1.2,math.sin(angle)*12),baseSize=puff.Size.X})
   end
  end
  previousPhase=phase
  if phase=="Riding" and clock-lastDust>0.04 then
   lastDust=clock
   local puff=Instance.new("Part")
   puff.Name="LocalHoofDust" puff.Anchored=true
   puff.CanCollide,puff.CanTouch,puff.CanQuery=false,false,false
   puff.Color=Color3.fromRGB(239,220,176) puff.Material=Enum.Material.SmoothPlastic
   puff.Size=Vector3.one*(0.9+math.sin(clock*19)*0.15) puff.Transparency=0.4
   puff.Position=Vector3.new(frame.X+math.sin(clock*31)*1.5,0.35,frame.Z+2.5)
   puff.Parent=workspace
   table.insert(dust,{part=puff,started=clock,baseSize=puff.Size.X,velocity=Vector3.new(math.sin(clock*11)*0.5,0.7,2)})
   local streak=puff:Clone() streak.Name="LocalSpeedStreak"
   streak.Size=Vector3.new(0.08,0.04,3.5) streak.Transparency=0.65
   streak.Position=Vector3.new(frame.X+math.sin(clock*17)*8,0.08,frame.Z-9)
   streak.Parent=workspace table.insert(dust,{part=streak,started=clock,streak=true})
  end
 end
 for i=#dust,1,-1 do
  local entry=dust[i] local p=(clock-entry.started)/0.65
  if p>=1 then entry.part:Destroy() table.remove(dust,i)
  else
   entry.part.Transparency=0.45+p*0.55
   if not entry.streak then entry.part.Size=Vector3.one*((entry.baseSize or 0.5)+p*0.8) end
   entry.part.Position+=(entry.velocity or Vector3.new(0,entry.streak and 0 or 0.6,0))*dt
  end
 end
end
function Presentation.clear() restore() end
return Presentation
