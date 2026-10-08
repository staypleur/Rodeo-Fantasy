local Motion=require("../src/shared/HerdMotion")
local Rules=require("../src/shared/HuntRules")
local tuning={RoadHalfWidth=35,HerdStudsPerSecond=44}
local checks=0
local function check(v,message) assert(v,message) checks+=1 end
local function run(x,z,seed,rocks,steps,dt)
 local state=Motion.new(x,seed)
 local low,high=x,x
 for _=1,steps do
  local nx,nz=Motion.step(state,x,z,dt,rocks,tuning,1.25,2.3,Rules)
  check(nz<=z,"herd must never reverse")
  check(math.abs(nx)<=32.75,"herd must stay inside canyon")
  for _,rock in ipairs(rocks) do
   check(not Rules.sweptBox(x,0,z,nx,0,nz,rock.x,0,rock.z,rock.sx+2.5,2,rock.sz+4.6,0.2),"full body must not sweep through a rock")
  end
  low,high=math.min(low,nx),math.max(high,nx)
  x,z=nx,nz
 end
 return x,z,high-low
end
local _,z,range=run(0,0,1,{},200,0.05)
check(z<-400 and range>4,"natural herd must run forward and vary laterally")
for _,seed in ipairs({1,2,3,9,23}) do
 local _,endZ=run(0,20,seed,{{x=0,z=-45,sx=4,sz=4}},100,0.1)
 check(endZ<-100,"herd must actually pass the rock by going around it")
end
local rocks={{x=0,z=-35,sx=4,sz=4},{x=5,z=-65,sx=4,sz=4},{x=-5,z=-95,sx=4,sz=4}}
local _,endZ=run(0,20,5,rocks,150,0.1)
check(endZ<-200,"staggered rocks must not trap the herd")
local _,edgeZ=run(29,20,7,{{x=29,z=-40,sx=4,sz=4}},100,0.1)
check(edgeZ<-100,"edge rock must be bypassed within road bounds")
local state=Motion.new(0,1)
local nx,nz=Motion.step(state,0,0,0.1,{{x=0,z=-6,sx=4,sz=4}},tuning,1.25,2.3,Rules)
check(nz==0 and nx~=0,"sudden close rock must brake forward motion while steering clear")
local a,b=Motion.new(0,1),Motion.new(0,2)
local ax=Motion.step(a,0,0,0.1,{},tuning,1.25,2.3,Rules)
local bx=Motion.step(b,0,0,0.1,{},tuning,1.25,2.3,Rules)
check(ax~=bx,"individuals must not share the same sway rhythm")
print("PASS: "..checks.." herd motion checks")
