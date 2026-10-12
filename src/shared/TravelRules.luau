-- Cumulative distance checkpoints; a repeated save cannot credit the same run twice.
local R={UnlockMeters=10000}
function R.merge(old,session,meters,timestamp)
 old=type(old)=="table" and old or {}
 local totals=table.clone(old.planetMeters or {})
 local receipts={}
 for id,v in pairs(old.sessions or {}) do
  if id==session or timestamp-(v.time or 0)<30*86400 then receipts[id]=v end
 end
 local previous=receipts[session] and receipts[session].meters or {}
 local checkpoint=table.clone(previous)
 for id,value in pairs(meters) do
  assert(type(value)=="number" and value==value and value>=0 and value<math.huge,"Invalid distance")
  local nextValue=math.max(previous[id] or 0,math.floor(value))
  totals[id]=(totals[id] or 0)+nextValue-(previous[id] or 0)
  checkpoint[id]=nextValue
 end
 receipts[session]={time=timestamp,meters=checkpoint}
 local total=0 for _,v in pairs(totals) do total+=v end
 return {planetMeters=totals,totalMeters=total,sessions=receipts}
end
function R.unlocks(order,meters)
 local result={}
 for i,id in ipairs(order) do result[id]=i==1 or (meters[order[i-1]] or 0)>=R.UnlockMeters end
 return result
end
return R
