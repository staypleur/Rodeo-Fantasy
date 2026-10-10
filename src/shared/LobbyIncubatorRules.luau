-- Retain every egg when moving from four lobby incubators to one.
local R={}
function R.migrate(bag)
 local occupied=false
 local returned=0
 for _,egg in ipairs(bag.eggs or {}) do
  if egg.assignedPen==1 and not occupied then occupied=true
  elseif egg.assignedPen~=nil then egg.assignedPen=nil returned+=1 end
 end
 return returned
end
return R
