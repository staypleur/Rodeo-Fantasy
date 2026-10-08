-- First meadow only. Distances below are layout trial values in studs.
local Course={LengthStuds=4800,LayoutScale=3,LengthMeters=1000}
local function ramp(d,a,b) return math.clamp((d-a)/(b-a),0,1) end
function Course.width(z)
 local d=math.max(0,-z/3)
 return 35-11*ramp(d,256,400)+11*ramp(d,600,800)
end
function Course.median(z)
 local d=math.max(0,-z/3)
 return 9*ramp(d,800,950)*(1-ramp(d,1200,1400))
end
function Course.ranges(z,padding)
 local edge=Course.width(z)-padding
 local middle=Course.median(z)
 if middle>0 then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.planningRanges(z,horizon,padding)
 local edge=math.min(Course.width(z),Course.width(z-horizon),Course.width(z-horizon/2))-padding
 local middle=math.max(Course.median(z),Course.median(z-horizon),Course.median(z-horizon/2))
 if middle>0 then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.contains(x,z,padding)
 for _,range in ipairs(Course.ranges(z,padding)) do
  if x>range[1] and x<range[2] then return true end
 end
 return false
end
return Course
