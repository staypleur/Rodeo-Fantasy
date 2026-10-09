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

local items={}
for i=1,12 do table.insert(items,{key=i,x=0,y=2,z=-35-i*.7,serial=i}) end
local first=View.select(items,0,1,t,6)
local newcomer={key=99,x=0,y=2,z=-30,serial=99}
table.insert(items,newcomer)
local stable=View.select(items,0,1,t,6,first)
for key in pairs(first) do assert(stable[key],"nearer arrivals must not flicker existing runners") end
assert(not stable[99],"full visible set stays stable until an animal leaves")
for _,candidate in ipairs(items) do if first[candidate.key] then candidate.z=-600 end end
local replaced=View.select(items,0,1,t,6,stable)
assert(not replaced[99],"hidden central runners must not suddenly appear when a slot opens")
local edge
for dz=-20,-200,-1 do
 if View.visible(0,2,dz,1,t,1.15) and not View.visible(0,2,dz,1,t,1) then edge={key=100,x=0,y=2,z=dz,serial=100} break end
end
assert(edge) table.insert(items,edge)
local arrivals=View.select(items,0,1,t,6,stable)
assert(arrivals[100],"new runners enter from the camera boundary")
print("PASS: stable herd identities and replacement after leaving the camera")

-- Leaving an occupied mount must not hide an animal already seen by the rider.
for _,aspect in ipairs({.4,1,16/9,4}) do
 local herd={}
 for i=1,7 do table.insert(herd,{key=i,x=0,y=2,z=-30-i,serial=i}) end
 local prior={} for i=1,6 do prior[i]=true end
 local released=View.select(herd,0,aspect,t,6,prior,{[7]=true})
 assert(released[7],'former mount takes a visible slot, even when six wild animals were shown')
 local count=0 for _ in pairs(released) do count+=1 end assert(count==6)
 for frame=1,15 do
  for _,item in ipairs(herd) do item.z-=.3 end
  released=View.select(herd,0,aspect,t,6,released,{[7]=true})
  assert(released[7],'released animal keeps running visibly without shortlist flicker')
 end
 herd[7].z=-600
 local gone=View.select(herd,0,aspect,t,6,released,{[7]=true})
 assert(not gone[7],'offscreen former mount is no longer pinned')
end
print('PASS: released mount stays visible while running, cap six, offscreen release on four ratios')
