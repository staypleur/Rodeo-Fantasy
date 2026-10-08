local course=require("../src/shared/CourseGeometry")
assert(course.LengthMeters==1000 and course.LengthStuds==1600)
assert(course.width(0)==35 and course.width(-500)==24 and course.width(-1550)==35)
assert(#course.ranges(-500,2)==1 and #course.ranges(-1000,2)==2 and #course.ranges(-1500,2)==1)
assert(not course.contains(0,-1000,1.25) and course.contains(20,-1000,1.25))
assert(not course.contains(24,-500,1.25))
for d=0,1600,4 do
 for _,range in ipairs(course.planningRanges(-d,68,2.25)) do
  for _,x in ipairs({range[1]+0.001,range[2]-0.001}) do
   assert(course.contains(x,-d,1.6),"forecast route must also be safe now")
  end
 end
end
print("PASS: finite meadow, narrowing, branch, merge and forecast corridor checks")
