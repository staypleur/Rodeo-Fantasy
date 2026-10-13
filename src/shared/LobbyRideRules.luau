-- Lobby riding uses owned pets and server-limited movement.
local R={}
function R.canRide(stars) return (tonumber(stars) or 1)>=3 end
function R.canBond(stars) return not R.canRide(stars) end
-- Signed yaw handles even a 180-degree reversal without a zero-vector lerp.
function R.turn(forward,target,dt)
 if target.Magnitude<.001 then return forward end
 target=target.Unit
 local angle=math.atan2(forward:Cross(target).Y,forward:Dot(target))
 local step=math.clamp(angle,-math.pi*1.5*dt,math.pi*1.5*dt)
 return CFrame.Angles(0,step,0):VectorToWorldSpace(forward)
end
function R.speed(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 return 26*(stars>=9 and 1.5 or stars>=6 and 1.3 or stars>=3 and 1.2 or 1)
end
function R.direction(value)
 if typeof(value)~="Vector3" or value.X~=value.X or value.Y~=value.Y or value.Z~=value.Z then return nil end
 if math.abs(value.X)>1000 or math.abs(value.Z)>1000 or math.abs(value.Y)>1000 then return nil end
 local flat=Vector3.new(value.X,0,value.Z)
 return flat.Magnitude>1 and flat.Unit or flat
end
return R
