local course=require("../src/shared/CourseGeometry")
assert(course.LengthMeters==1000 and course.LengthStuds==4800)
assert(course.width(0)==35 and course.width(-1500)==24 and course.width(-4650)==35)
assert(#course.ranges(-1500,2)==1 and #course.ranges(-3000,2)==2 and #course.ranges(-4500,2)==1)
assert(not course.contains(0,-3000,1.25) and course.contains(20,-3000,1.25))
assert(not course.contains(24,-1500,1.25))
for d=0,4800,4 do
 for _,range in ipairs(course.planningRanges(-d,68,2.25)) do
  for _,x in ipairs({range[1]+0.001,range[2]-0.001}) do
   assert(course.contains(x,-d,1.6),"forecast route must also be safe now")
  end
 end
end
print("PASS: finite meadow, narrowing, branch, merge and forecast corridor checks")

local config=require("../src/shared/Config")
assert(math.abs(config.Prototype.MetersPerStud*course.LengthStuds-1000)<0.00001)
assert(math.abs(config.Prototype.ForwardStudsPerSecond*config.Prototype.MetersPerStud-40/3)<0.00001)
print("PASS: unchanged ride speed, one-third meter rate and consistent 1000m geometry")
