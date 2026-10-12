-- Approved natural-cluster Green Star course. Geometry uses metres at 4.8 studs/m.
local Course={LengthStuds=9600,LayoutScale=4.8,LengthMeters=2000,Forks={{430,550},{830,990},{1250,1390},{1670,1840}}}
function Course.width(z)
 local d=math.max(0,-z/3)
 local function ramp(a,b) return math.clamp((d-a)/(b-a),0,1) end
 return 35-11*ramp(256,400)+11*ramp(600,800)
end
function Course.median(z)
 local d=-z/Course.LayoutScale
 for _,fork in ipairs(Course.Forks) do if d>=fork[1] and d<=fork[2] then return 9 end end
 return 0
end
function Course.ranges(z,padding,flying)
 local edge=Course.width(z)-padding
 local middle=Course.median(z)
 if middle>0 and not flying then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.planningRanges(z,horizon,padding)
 local edge=math.min(Course.width(z),Course.width(z-horizon),Course.width(z-horizon/2))-padding
 local middle=math.max(Course.median(z),Course.median(z-horizon),Course.median(z-horizon/2))
 if middle>0 then return {{-edge,-middle-padding},{middle+padding,edge}} end
 return {{-edge,edge}}
end
function Course.contains(x,z,padding,flying)
 for _,range in ipairs(Course.ranges(z,padding,flying)) do
  if x>range[1] and x<range[2] then return true end
 end
 return false
end
return Course
