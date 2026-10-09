-- Saved meshes only. No EditableMesh/Image allocation at runtime.
local M={}
local frames=setmetatable({},{__mode="k"})
function M.sample(clock,group)
 local angle=0
 if group=="LeftFin" then angle=math.sin(clock*.65)*.055
 elseif group=="RightFin" then angle=-math.sin(clock*.65)*.055
 elseif group=="Tail" then angle=math.sin(clock*.65+.7)*.075 end
 return math.sin(clock*.5)*.45,math.sin(clock*.4)*.008,angle
end
function M.step(ship,clock)
 local parts=frames[ship]
 if not parts then
  parts={} frames[ship]=parts
  local function remember(part)
   if part:IsA("MeshPart") then
    parts[#parts+1]={part=part,rest=part:GetAttribute("WhaleRest") or part.CFrame,
     group=part:GetAttribute("WhaleMotionGroup"),hinge=part:GetAttribute("WhaleHinge")}
   end
  end
  for _,part in ipairs(ship:GetDescendants()) do remember(part) end
  ship.DescendantAdded:Connect(remember)
 end
 local anchor=CFrame.new(6000,55,-5)
 local bob,roll=M.sample(clock,nil)
 local sway=anchor*CFrame.new(0,bob,0)*CFrame.Angles(0,0,roll)*anchor:Inverse()
 for _,entry in ipairs(parts) do
  if entry.part.Parent then
   local rest=entry.rest
   if entry.hinge then
    local _,_,angle=M.sample(clock,entry.group)
    local turn=entry.group=="Tail" and CFrame.Angles(angle,0,0) or CFrame.Angles(0,0,angle)
    rest=entry.hinge*turn*entry.hinge:Inverse()*rest
   end
   entry.part.CFrame=sway*rest
  end
 end
end
return M
