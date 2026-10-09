local R={}
function R.discovered(seen,catalog)
 local count=0
 for _,id in ipairs(catalog.Order) do
  for _,stars in ipairs({1,3,6,9}) do if seen[id..":"..stars]==true then count+=1 end end
 end
 return count
end
-- Idempotent cumulative session checkpoint; union discoveries across servers.
function R.merge(old,session,catches,seen,time,caught)
 old=old or {} local sessions={} local discovered={} local totals={}
 for key,value in pairs(old.caught or {}) do totals[key]=value end
 for id,v in pairs(old.sessions or {}) do
  if id==session or time-(v.time or time)<86400*30 then sessions[id]=v end
 end
 for id,v in pairs(old.seen or {}) do if v then discovered[id]=true end end
 for id,v in pairs(seen) do if v then discovered[id]=true end end
 local previous=sessions[session] and sessions[session].count or 0
 local count=math.max(previous,catches)
 local checkpoint={}
 local oldCounts=sessions[session] and sessions[session].caught or {}
 for key,value in pairs(oldCounts) do checkpoint[key]=value end
 for key,value in pairs(caught or {}) do
  local previousValue=oldCounts[key] or 0
  local nextValue=math.max(previousValue,value)
  totals[key]=(totals[key] or 0)+nextValue-previousValue checkpoint[key]=nextValue
 end
 sessions[session]={count=count,time=time,caught=checkpoint}
 return {captures=(old.captures or 0)+count-previous,seen=discovered,sessions=sessions,caught=totals}
end
return R
