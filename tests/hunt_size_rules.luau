local Rules=require("../src/shared/HuntRules")
local sizes={"Small","Medium","Large","ExtraLarge"}
local normal={{false,false,false,false},{false,false,false,false},{true,false,false,false},{true,true,true,false}}
local dash={{false,false,false,false},{true,false,false,false},{true,true,false,false},{true,true,true,false}}
local obstacles={{false,false,false,false},{false,false,false,false},{true,false,false,false},{true,true,false,false}}
local count=0
for i,size in ipairs(sizes) do
 for j,target in ipairs(sizes) do
  assert(Rules.canKnock(size,target,false)==normal[i][j],size.." normal "..target)
  assert(Rules.canKnock(size,target,true)==dash[i][j],size.." dash "..target)
  for _,dashing in ipairs({false,true}) do
   assert(Rules.canBreakObstacle(size,target,dashing)==obstacles[i][j],size.." obstacle "..target)
   count+=1
  end
  count+=2
 end
 assert(Rules.canBreakCrate(size)==(i>1),size.." crate")
 count+=1
end
assert(not Rules.canKnock("Unknown","Small",true))
assert(not Rules.canBreakObstacle("ExtraLarge","Unknown",true))
assert(not Rules.canBreakCrate("Unknown"))
print("PASS size collision matrix: "..count.." checks plus unknown-size guards")
