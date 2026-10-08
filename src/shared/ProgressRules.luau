local R={MaxLevel=1000,MaxXP=5000}
function R.threshold(level)
 local n=math.clamp(math.floor(level),1,R.MaxLevel)-1
 return math.floor(n+4001*(n/999)^2)
end
function R.level(xp)
 local low,high=1,R.MaxLevel
 while low<high do
  local mid=math.ceil((low+high)/2)
  if R.threshold(mid)<=xp then low=mid else high=mid-1 end
 end
 return low
end
function R.bar(xp)
 local level=R.level(xp)
 if level==R.MaxLevel then return level,1,0,0 end
 local first,last=R.threshold(level),R.threshold(level+1)
 return level,math.clamp((xp-first)/(last-first),0,1),xp-first,last-first
end
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
