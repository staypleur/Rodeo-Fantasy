local View=require("../src/shared/HerdVisibility")
local t=require("../src/shared/Config").Prototype
local course=require("../src/shared/CourseGeometry")
for _,aspect in ipairs({0.4,0.5625,1,16/9,4}) do
 for _,z in ipairs({0,-1100,-2500,-3300,-4200}) do
  local count=0
  for offset=20,100,16 do
   for _,range in ipairs(course.ranges(z-offset,3)) do
    for i=1,6 do
     local x=range[1]+(range[2]-range[1])*i/7
     if View.visible(x,2,-offset,aspect,t) then count+=1 end
    end
   end
  end
  assert(count>=6,"camera window needs safe candidates for narrow and wide screens")
 end
end
assert(not View.visible(6000,2,0,1,t),"lobby creatures must never count as hunt herd")
assert(not View.visible(0,2,-500,1,t),"off-screen herd must not meet quota")
print("PASS: camera-sized herd windows across 5 screen ratios and all course stages")
