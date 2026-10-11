local motion=require("../src/shared/QuadrupedMotion")
for _,running in ipairs({false,true}) do
 for _,limb in ipairs({"LeftFront","LeftRear","RightFront","RightRear"}) do
  local previousZ,previousY=motion.foot(0,limb,running)
  for i=1,1000 do
   local z,y=motion.foot(i/1000,limb,running)
   assert(y>=0 and y<=1 and math.abs(z)<=.500001)
   assert(math.abs(z-previousZ)<.02 and math.abs(y-previousY)<.02,"Discontinuous foot path")
   previousZ,previousY=z,y
   for _,bend in ipairs({-1,1}) do
    local ty,tz=-.5+y*.1,z*.2
    local a,b=motion.solve(ty,tz,.3,.3,bend)
    local fy=-math.cos(a)*.3-math.cos(b)*.3
    local fz=math.sin(a)*.3+math.sin(b)*.3
    assert(math.abs(fy-ty)<1e-6 and math.abs(fz-tz)<1e-6,"IK foot endpoint")
   end
  end
 end
end
for _,y in ipairs({0,-100,100}) do
 local a,b=motion.solve(y,0,.3,.2,1)
 assert(a==a and b==b,"Unreachable target produces NaN")
end
print("PASS: foot paths continuous; 16,000 reachable IK solutions; unreachable targets finite")
