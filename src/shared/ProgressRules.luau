local R={}
-- Idempotent cumulative session checkpoint; union discoveries across servers.
function R.merge(old,session,catches,seen,time)
 old=old or {} local sessions={} local discovered={}
 for id,v in pairs(old.sessions or {}) do
  if id==session or time-(v.time or time)<86400*30 then sessions[id]=v end
 end
 for id,v in pairs(old.seen or {}) do if v then discovered[id]=true end end
 for id,v in pairs(seen) do if v then discovered[id]=true end end
 local previous=sessions[session] and sessions[session].count or 0
 local count=math.max(previous,catches)
 sessions[session]={count=count,time=time}
 return {captures=(old.captures or 0)+count-previous,seen=discovered,sessions=sessions}
end
return R
