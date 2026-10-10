-- Idempotent session checkpoints prevent double counting after an uncertain save reply.
local Rules={}
function Rules.merge(old,sessionId,produced,bestDistance,timestamp)
 old=type(old)=="table" and old or {}
 local sessions={}
 for id,entry in pairs(old.sessions or {}) do
  if entry.time>timestamp-30*86400 then sessions[id]={amount=entry.amount,time=entry.time} end
 end
 local previous=sessions[sessionId] and sessions[sessionId].amount or 0
 local increment=math.max(0,math.floor(produced)-previous)
 sessions[sessionId]={amount=math.max(previous,math.floor(produced)),time=timestamp}
 return {income=(old.income or 0)+increment,distance=math.max(old.distance or 0,math.floor(bestDistance)),sessions=sessions}
end
function Rules.mergePlanets(old,sessionId,produced,bestDistance,distances,timestamp)
 local result=Rules.merge(old,sessionId,produced,bestDistance,timestamp)
 result.planetDistances={}
 for id,value in pairs(type(old)=="table" and old.planetDistances or {}) do result.planetDistances[id]=value end
 -- All legacy runs used Green Star; retain them in that category.
 if type(old)=="table" and not old.planetDistances then result.planetDistances.GreenStar=math.max(result.planetDistances.GreenStar or 0,old.distance or 0) end
 for id,value in pairs(distances) do result.planetDistances[id]=math.max(result.planetDistances[id] or 0,math.floor(value)) end
 return result
end
return Rules
