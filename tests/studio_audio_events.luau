-- Command Bar in edit mode: event decisions do not need a speaker or loaded assets.
local Audio=require(game.StarterPlayer.StarterPlayerScripts.AudioPresentation)
local function has(events,key) for _,v in ipairs(events) do if v==key then return true end end return false end
local tracker=Audio.newEvents()
local mount={}
local state={area='Lobby',phase='Idle'} assert(#tracker:update(state,0,false)==0)
state={area='Hunt',phase='Riding',monster=mount,tamed=false}
assert(has(tracker:update(state,1,false),'Land'))
state.tamed=true assert(has(tracker:update(state,2,false),'Success'))
assert(not has(tracker:update(state,2.1,false),'Success'),'filled heart must not chime every frame')
assert(has(tracker:update(state,3,true),'Warning'))
assert(not has(tracker:update(state,3.1,true),'Warning'),'warning must be rate limited')
assert(has(tracker:update(state,3.6,true),'Warning'))
state.phase='Airborne' assert(has(tracker:update(state,3.7,true),'Jump'))
assert(not has(tracker:update(state,3.8,true),'Warning'),'jumping off cancels warning')
state.phase='Lassoing' assert(has(tracker:update(state,4,false),'Rope'))
state.monster={} state.phase='Riding' state.tamed=false tracker:update(state,5,false)
state.tamed=true assert(has(tracker:update(state,6,false),'Success'),'new mount can be tamed')
state.phase='GameOver' state.endReason='Monster'
assert(has(tracker:update(state,7,false),'CrashMonster'))
assert(not has(tracker:update(state,7.1,false),'CrashMonster'),'death sound must be once')
for _,case in ipairs({{'Obstacle','CrashObstacle'},{'Wall','CrashObstacle'},{'Fall','Fall'}}) do
 state.phase='Riding' tracker:update(state,8,false)
 state.phase='GameOver' state.endReason=case[1]
 assert(has(tracker:update(state,9,false),case[2]))
end
local stamp=Audio.newTimestampEvents() local obstacle={}
assert(stamp(obstacle,10,10.1)) assert(not stamp(obstacle,10,10.2),'same break does not repeat')
assert(stamp(obstacle,15,15.1),'respawned obstacle can play a fresh break')
assert(not stamp({},1,10),'late replication does not play old events')
local future={} assert(not stamp(future,20,19)) assert(stamp(future,20,20),'future timestamps wait without being consumed')
state={area='Lobby',phase='Idle'} assert(not has(tracker:update(state,20,true),'Warning'))
print('AUDIO_EVENTS_PASS: capture, warning cadence/cancellation, differentiated collision deaths, fresh knock/break stamps and respawn')
