-- Numeric route planning for unmounted animals; authority remains on the server.
local Motion={}

function Motion.new(x,seed)
 return {home=x,elapsed=0,phase=seed*2.399963,amplitude=2.5+seed%3*0.6,vx=0}
end

function Motion.step(state,x,z,dt,rocks,tuning,halfX,halfZ,rules)
 dt=math.max(0,math.min(dt,0.1))
 state.elapsed+=dt
 local limit=tuning.RoadHalfWidth-halfX-1
 local speed=tuning.HerdStudsPerSecond
 local horizon=speed*1.5+halfZ
 local intervals={{-limit,limit}}
 -- Select a corridor that stays clear for the animal's full footprint.
 for _,rock in ipairs(rocks) do
  local depth=rock.sz/2+halfZ+0.9
  if rock.z-depth<=z and rock.z+depth>=z-horizon then
   local low,high=rock.x-rock.sx/2-halfX-0.9,rock.x+rock.sx/2+halfX+0.9
   local remaining={}
   for _,range in ipairs(intervals) do
    if high<range[1] or low>range[2] then table.insert(remaining,range)
    else
     if low>range[1] then table.insert(remaining,{range[1],low}) end
     if high<range[2] then table.insert(remaining,{high,range[2]}) end
    end
   end
   intervals=remaining
  end
 end
 local preferred=math.clamp(state.home+math.sin(state.elapsed*0.72+state.phase)*state.amplitude+math.sin(state.elapsed*1.13+state.phase*0.7)*0.65,-limit,limit)
 local target,best=x,math.huge
 for _,range in ipairs(intervals) do
  local candidate=math.clamp(preferred,range[1],range[2])
  local score=math.abs(candidate-preferred)+math.abs(candidate-x)*0.25
  if score<best then target,best=candidate,score end
 end
 local wanted=math.clamp((target-x)*3,-14,14)
 state.vx+=math.clamp(wanted-state.vx,-45*dt,45*dt)
 local nextX,nextZ=math.clamp(x+state.vx*dt,-limit,limit),z-speed*dt
 local function blocked(nx,nz)
  for _,rock in ipairs(rocks) do
   if rules.sweptBox(x,0,z,nx,0,nz,rock.x,0,rock.z,rock.sx+halfX*2,2,rock.sz+halfZ*2,0.35) then return true end
  end
  return false
 end
 -- A close or newly spawned rock must never be tunneled through between ticks.
 if blocked(nextX,nextZ) then
  if not blocked(nextX,z) then nextZ=z
  else nextX,nextZ=x,z state.vx=0 end
 end
 return nextX,nextZ,(nextX-x)/math.max(dt,0.000001)
end

return Motion
