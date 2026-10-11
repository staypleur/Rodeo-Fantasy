-- Lobby riding uses owned pets and server-limited movement.
local R={}
function R.speed(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 return 26+(stars-1)*3
end
function R.direction(value)
 if typeof(value)~="Vector3" or value.X~=value.X or value.Y~=value.Y or value.Z~=value.Z then return nil end
 if math.abs(value.X)>1000 or math.abs(value.Z)>1000 or math.abs(value.Y)>1000 then return nil end
 local flat=Vector3.new(value.X,0,value.Z)
 return flat.Magnitude>1 and flat.Unit or flat
end
return R
