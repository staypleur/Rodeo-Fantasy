-- Approved natural-cluster Green Star course. Geometry uses metres at 4.8 studs/m.
local Course={LengthStuds=9600,LayoutScale=4.8,LengthMeters=2000,Forks={{430,550},{830,990},{1250,1390},{1670,1840}}}
function Course.width(z)
 local d=math.max(0,-z/Course.LayoutScale)
 return 29.5+5.5*math.cos(d/90) -- total 48..70 studs, never wider than the previous map
end
function Course.fork(z)
 local d=-z/Course.LayoutScale
 for index,fork in ipairs(Course.Forks) do
  if d>=fork[1] and d<=fork[2] then return index,(index%2==1 and "Mountain" or "Canyon"),math.clamp((d-fork[1])/(fork[2]-fork[1]),0,1) end
 end
 return nil
end
function Course.median(z)
 local _,_,t=Course.fork(z)
 return t and 9*math.sin(math.pi*t)^.65 or 0
end
function Course.hazard(x,z,padding,flying)
 padding=padding or 0
 if math.abs(x)+padding>=Course.width(z) then return "Wall" end
 local _,kind=Course.fork(z)
 local middle=Course.median(z)
 if not flying and kind and middle>.05 and math.abs(x)<middle+padding then return kind=="Canyon" and "CanyonFall" or "Wall" end
 return nil
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
