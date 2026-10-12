local Course=(function() -- COURSE_SOURCE
end)()
local Plan=(function() -- PLAN_SOURCE
end)()
local View=(function() -- VIEW_SOURCE
end)()
local Config=(function() -- CONFIG_SOURCE
end)()
for _,meters in ipairs({999,1000,1001,1500,1999,2000,2010}) do
 local displayDistance=meters
 displayDistance=math.min(displayDistance,Course.LengthMeters)
 assert(displayDistance==math.min(meters,2000))
end
for _,right in ipairs({false,true}) do
 local positions=Plan.candidates({{-30,-14},{14,30}},{-.72,-.24,.24,.72},right)
 for i=1,7,2 do assert(positions[i]*positions[i+1]<0) end
 local left,rightCount=0,0
 for i=1,6 do if positions[i]<0 then left+=1 else rightCount+=1 end end
 assert(left==3 and rightCount==3)
end
local t=Config.Prototype
local candidates={}
for i=1,8 do table.insert(candidates,{key=i,x=i<=6 and -20 or 20,y=2,z=-30,serial=i}) end
assert(View.visible(-20,2,-30,2.15,t,1) and View.visible(20,2,-30,2.15,t,1))
local selected=View.select(candidates,0,2.15,t,4,nil,nil,true)
local l,r,n=0,0,0
for _,c in ipairs(candidates) do if selected[c.key] then n+=1 if c.x<0 then l+=1 else r+=1 end end end
assert(n<=4 and l>0 and r>0)
local previous={[1]=true,[2]=true}
selected=View.select(candidates,0,2.15,t,4,previous,nil,true)
assert(selected[1] and selected[2],"Retained animals must not pop out")
for _,c in ipairs(candidates) do
 assert(not selected[c.key] or previous[c.key],"Fork must not reveal an unseen runner in front of the player")
end
-- Both roads can acquire runners before they enter the visible camera.
for _,aspect in ipairs({.6,1,2.15}) do
 local entries={}
 for _,x in ipairs({-20,20}) do
  local found
  for depth=0,220 do
   if not View.visible(x,2,-depth,aspect,t,1) and View.visible(x,2,-depth,aspect,t,1.15) then
    found={key=x,x=x,y=2,z=-depth,serial=x+30} break
   end
  end
  assert(found,"Missing offscreen entry band") table.insert(entries,found)
 end
 local entering=View.select(entries,0,aspect,t,4,{},nil,true)
 assert(entering[-20] and entering[20],"Both fork roads must preload outside the camera")
 for _,c in ipairs(entries) do c.z=-30 end
 local kept=View.select(entries,0,aspect,t,4,entering,nil,true)
 for _,c in ipairs(entries) do if View.visible(c.x,c.y,c.z,aspect,t,1) then assert(kept[c.key]) end end
end
print("HUNT_DISTANCE_BRANCH_PASS 1001..2000m, interleaved budget, both visible sides, retained IDs")
