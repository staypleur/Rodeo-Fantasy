-- Same road-centred camera as the client. Numeric projection is testable offline.
local View={}
function View.visible(x,y,relativeZ,aspect,t,margin)
 local fx,fy,fz=-t.CameraSideStuds,-t.CameraHeightStuds,-(t.CameraBehindStuds+t.CameraLookAheadStuds)
 local length=math.sqrt(fx*fx+fy*fy+fz*fz)
 fx,fy,fz=fx/length,fy/length,fz/length
 local horizontal=math.sqrt(fx*fx+fz*fz)
 local rx,rz=-fz/horizontal,fx/horizontal
 local ux,uy,uz=-rz*fy,rz*fx-rx*fz,rx*fy
 local dx,dy,dz=x-t.CameraSideStuds,y-t.CameraGroundFocusStuds-t.CameraHeightStuds,relativeZ-t.CameraBehindStuds
 local depth=dx*fx+dy*fy+dz*fz
 if depth<=0 then return false end
 local half=depth*math.tan(math.rad(t.CameraFieldOfView)/2)*(margin or .82)
 return math.abs(dx*rx+dz*rz)<half*aspect and math.abs(dx*ux+dy*uy+dz*uz)<half
end
-- Shared deterministic shortlist: only displayed wild animals can be caught/collided with.
function View.select(candidates,z,aspect,t,limit,previous)
 local visible={}
 local selected={} local count=0
 local function entry(candidate)
  return not previous or candidate.emerging or candidate.atDen or not View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1)
 end
 for _,candidate in ipairs(candidates) do
  if previous and previous[candidate.key] and count<(limit or 6) and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) then
   selected[candidate.key]=true count+=1
  end
  if entry(candidate) and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1.15) then
   candidate.score=(candidate.z-z+15)^2+candidate.x*candidate.x*.2+(View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) and 0 or 1000000)
   table.insert(visible,candidate)
  end
 end
 table.sort(visible,function(a,b) if a.score==b.score then return a.serial<b.serial end return a.score<b.score end)
 -- Prefer ready runners, then fill the visible herd with animals leaving caves.
 for _,candidate in ipairs(visible) do
  if not selected[candidate.key] and not candidate.emerging and count<4 and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) then selected[candidate.key]=true count+=1 end
 end
 for _,candidate in ipairs(visible) do
  if not selected[candidate.key] and candidate.emerging and count<math.min(limit or 6,6) and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) then selected[candidate.key]=true count+=1 end
 end
 for _,candidate in ipairs(visible) do
  if not selected[candidate.key] and count<(limit or 6) then selected[candidate.key]=true count+=1 end
 end
 -- Faster/flying herds can leave the inner window together. Fill the minimum
 -- from animals already inside the full camera, without replacing stable IDs.
 if count<4 then
  for _,candidate in ipairs(candidates) do
   if not selected[candidate.key] and entry(candidate) and not candidate.emerging and count<4 and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,.98) then
    selected[candidate.key]=true count+=1
   end
  end
 end
 return selected
end
return View
