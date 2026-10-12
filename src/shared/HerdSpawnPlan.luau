-- Interleave branch candidates before advancing to the next lane. No model allocation here.
local Plan={}
function Plan.candidates(ranges,lanes,startRight)
 local result={}
 for _,lane in ipairs(lanes) do
  for index=1,#ranges do
   local range=ranges[startRight and (#ranges-index+1) or index]
   if range[2]>range[1] then
    table.insert(result,(range[1]+range[2])/2+lane*(range[2]-range[1])/2)
   end
  end
 end
 return result
end
return Plan
