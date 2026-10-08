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
return Rules
