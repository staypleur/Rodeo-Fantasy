-- Exercise the real restoration callback with a controlled scheduler, without waiting in CLI.
local callbacks={}
local env=setmetatable({task={delay=function(seconds,fn) table.insert(callbacks,{seconds=seconds,fn=fn}) end}},{__index=getfenv()})
local run=assert(loadstring(game.ServerScriptService.HuntWorld.Source)) setfenv(run,env)
local W=run() local p=game.ReplicatedStorage.RodeoFantasy
W.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,require(p.Config),require(p.HuntRules))
local m=W.spawn(Vector3.new(0,2,-10),'RockElephant')
local rock=Instance.new('Part') rock.Position=m.PrimaryPart.Position rock.Size=Vector3.new(4,4,4)
rock:SetAttribute('Scale',1) rock.Parent=workspace.RodeoPrototype.Obstacles
local detail=Instance.new('Part') detail.Transparency=.35 detail.Parent=rock
assert(not W.hit(m.PrimaryPart.Position,m.PrimaryPart.Position,false,m))
assert(rock:GetAttribute('Broken') and detail.Transparency==1 and not rock.CanQuery)
assert(#callbacks==1 and callbacks[1].seconds==5,'respawn must be scheduled exactly five seconds later')
callbacks[1].fn()
assert(not rock:GetAttribute('Broken') and rock.CanQuery and math.abs(detail.Transparency-.35)<.001)
assert(not W.hit(m.PrimaryPart.Position,m.PrimaryPart.Position,false,m)) assert(#callbacks==2)
rock:Destroy() callbacks[2].fn() m:Destroy()
print('OBSTACLE_RESTORE_PASS: native destruction, exact five-second schedule, appearance restoration, repeated destruction and unloaded chunk safety')
