-- Preserve one egg in each of the four open hatchery stands.
local R={}
function R.migrate(bag)
 local occupied={}
 local returned=0
 for _,egg in ipairs(bag.eggs or {}) do
  local slot=egg.assignedPen
  if type(slot)=="number" and slot%1==0 and slot>=1 and slot<=4 and not occupied[slot] then occupied[slot]=true
  elseif slot~=nil then egg.assignedPen=nil returned+=1 end
 end
 return returned
end
return R
