-- Shared normalized foot paths and two-segment inverse kinematics.
-- One module for every compatible quadruped; dimensions come from its bind pose.
local M={}
local walk={LeftRear=0,LeftFront=.25,RightRear=.5,RightFront=.75}
local trot={LeftRear=0,RightFront=0,RightRear=.5,LeftFront=.5}
function M.foot(phase,limb,running)
 local p=(phase+(running and trot or walk)[limb])%1
 local stance=running and .52 or .72
 if p<stance then return .5-p/stance,0 end
 local t=(p-stance)/(1-stance)
 local smooth=t*t*(3-2*t)
 return -.5+smooth,math.sin(math.pi*t)^2
end
function M.solve(y,z,upper,lower,bend)
 local d=math.clamp(math.sqrt(y*y+z*z),math.abs(upper-lower)+1e-5,upper+lower-1e-5)
 local direction=math.atan2(z,-y)
 local angle=math.acos(math.clamp((upper*upper+d*d-lower*lower)/(2*upper*d),-1,1))
 local a=direction+bend*angle
 local kneeY=-math.cos(a)*upper local kneeZ=math.sin(a)*upper
 -- Use the clamped endpoint to remain finite when the requested foot is unreachable.
 local targetY=-math.cos(direction)*d local targetZ=math.sin(direction)*d
 local b=math.atan2(targetZ-kneeZ,-(targetY-kneeY))
 return a,b
end
return M
