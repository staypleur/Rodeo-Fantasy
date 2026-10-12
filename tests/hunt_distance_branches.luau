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
local found=false for _,c in ipairs(candidates) do if selected[c.key] and c.x>0 then found=true end end assert(found)
print("HUNT_DISTANCE_BRANCH_PASS 1001..2000m, interleaved budget, both visible sides, retained IDs")
