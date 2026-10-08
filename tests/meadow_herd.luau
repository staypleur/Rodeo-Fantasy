local Motion=require("../src/shared/HerdMotion")
local Rules=require("../src/shared/HuntRules")
local Course=require("../src/shared/CourseGeometry")
local tuning=require("../src/shared/Config").Prototype
local checks=0
for layout=1,12 do
 local rocks={}
 for d=80,4780,32 do
  local scale=(d+layout)%3==0 and 2 or 1
  local ranges=Course.ranges(-d,scale*2+3)
  local range=ranges[(math.floor(d/32)+layout)%#ranges+1]
  local fraction=(math.sin(d*0.71+layout)*0.5+0.5)
  table.insert(rocks,{x=range[1]+(range[2]-range[1])*fraction,z=-d,sx=4*scale,sz=4*scale})
 end
 for _,initialX in ipairs({-18,-6,6,18}) do
  local x,z=initialX,0
  local motion=Motion.new(x,layout*7+initialX)
  local still=0
  for tick=1,1250 do
   local nx,nz=Motion.step(motion,x,z,0.1,rocks,tuning,1.25,2.3,Rules,Course)
   assert(Course.contains(nx,nz,1.25),"herd must stay in meadow branches")
   still=math.abs(nz-z)<0.001 and still+0.1 or 0
   assert(still<3,"animal stuck at "..nx..","..nz.." layout "..layout)
   for _,rock in ipairs(rocks) do
    assert(not Rules.sweptBox(x,0,z,nx,0,nz,rock.x,0,rock.z,rock.sx+2.5,2,rock.sz+4.6,0.2),"herd crosses large/small obstacle")
    checks+=1
   end
   x,z=nx,nz
  end
  assert(z<-4800,"herd must traverse entire meadow")
 end
end
print("PASS: "..checks.." meadow footprint checks across 12 varied layouts, forks and obstacle sizes")
