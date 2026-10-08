-- Local wind geometry, active only during the existing switch dash.
local Dash={}
local anchor,points,beams
local function clear()
 if anchor then anchor:Destroy() anchor=nil end
end
function Dash.update(phase,frame,clock,untilTime,duration)
 if phase~="Riding" or not frame or not untilTime or clock>=untilTime then clear() return end
 if not anchor then
  anchor=Instance.new("Part") anchor.Name="LocalDashWind"
  anchor.Anchored=true anchor.Transparency=1 anchor.Size=Vector3.one
  anchor.CanCollide,anchor.CanTouch,anchor.CanQuery=false,false,false
  anchor.Parent=workspace points={} beams={}
  for i=1,80 do local a=Instance.new("Attachment") a.Parent=anchor points[i]=a end
  for i=1,72 do
   local beam=Instance.new("Beam") beam.FaceCamera=true
   if i<=64 then
    local group=math.floor((i-1)/32)*32
    beam.Attachment0=points[i] beam.Attachment1=points[group+i%32+1]
   else beam.Attachment0=points[65+(i-65)*2] beam.Attachment1=points[66+(i-65)*2] end
   beam.Width0,beam.Width1=0.16,0.08
   beam.Color=ColorSequence.new(Color3.fromRGB(255,249,222))
   beam.LightEmission=0.2 beam.Parent=anchor beams[i]=beam
  end
 end
 anchor.CFrame=frame*CFrame.new(0,-1,0)
 local progress=math.clamp(1-(untilTime-clock)/duration,0,1)
 for group=0,1 do
  local radius=3.2+progress*3+group*0.9
  for i=1,32 do
   local angle=(i-1)/32*math.pi*2
   points[group*32+i].Position=Vector3.new(math.cos(angle)*radius,math.sin(angle)*radius,1+progress*7+group*3)
  end
 end
 for i=0,7 do
  local angle=i/8*math.pi*2+0.2
  local radius=3.7+math.sin(clock*20+i)*0.3
  local start=Vector3.new(math.cos(angle)*radius,math.sin(angle)*radius,-3)
  points[65+i*2].Position=start
  points[66+i*2].Position=start+Vector3.new(0,0,5+progress*6)
 end
 for _,beam in ipairs(beams) do beam.Transparency=NumberSequence.new(0.45+progress*0.55) end
end
return Dash
