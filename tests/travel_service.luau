local Rules=(function()
-- RULES_SOURCE
end)()
local stored,indexed={},{}
local fail=false
local profile={}
function profile:GetAsync(key) return stored[key] end
function profile:UpdateAsync(key,fn)
 if fail then error('Simulated save failure') end
 stored[key]=fn(stored[key]) return stored[key]
end
local index={UpdateAsync=function(_,key,fn) indexed[key]=fn(indexed[key]) end}
local ds={GetDataStore=function() return profile end,GetOrderedDataStore=function() return index end}
local run={IsRunning=function() return true end,IsStudio=function() return true end}
local guid=0
local planets={Order={'GreenStar','Zephyrus'},GreenStar={},Zephyrus={}}
local game={GameId=1,ReplicatedStorage={RodeoFantasy={TravelRules='rules',PlanetCatalog='planets'}},HttpService={GenerateGUID=function() guid+=1 return tostring(guid) end}}
function game:GetService(id) return id=='RunService' and run or ds end
local task={spawn=function(fn) fn() end}
local function require(id) return id=='rules' and Rules or planets end
local warn=function() end
local S=(function()
-- SERVICE_SOURCE
end)()
local player={UserId=12}
S.join(player)
local state={phase='Ride'}
S.sample(player,'GreenStar',state,80)
state.phase='Angry'
S.sample(player,'GreenStar',state,110)
S.sample(player,'GreenStar',state,100)
assert(S.snapshot(player).planetMeters.GreenStar==110,'Phase reset or backwards sample credited')
assert(S.save(player))
assert(stored['12'].totalMeters==110)
S.sample(player,'GreenStar',{},70)
assert(S.snapshot(player).planetMeters.GreenStar==180)
fail=true
assert(not S.flush(player))
assert(S.snapshot(player).planetMeters.GreenStar==180,'Failed save lost distance')
fail=false
assert(S.flush(player))
assert(stored['12'].totalMeters==180 and indexed['12']==180)
assert(S.flush(player) and stored['12'].totalMeters==180,'Repeated flush double credited')
S.leave(player) S.join(player)
assert(S.snapshot(player).planetMeters.GreenStar==180,'Reconnect lost distance')
assert(not S.canEnter(player,'Zephyrus'))
S.sample(player,'GreenStar',{},9820)
assert(S.canEnter(player,'Zephyrus'))
assert(S.flush(player) and stored['12'].totalMeters==10000)
print('TRAVEL_SERVICE_PASS: phases, retry, flush, reconnect, unlock')
