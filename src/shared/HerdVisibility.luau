-- Same road-centred camera as the client. Numeric projection is testable offline.
local View={}
function View.capacity(width) return width<30 and 4 or 6 end
-- Let animals already on screen run out naturally when the road narrows.
function View.transitionLimit(candidates,z,aspect,t,target,previous,preferred)
 local count=0
 for _,candidate in ipairs(candidates) do
  if ((previous and previous[candidate.key]) or (preferred and preferred[candidate.key])) and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) then count+=1 end
 end
 return math.max(target,count)
end
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
function View.select(candidates,z,aspect,t,limit,previous,preferred,split)
 local visible={}
 local selected={} local count=0
 -- A rider has just left this already-visible animal. Keep it ahead of the
 -- ordinary shortlist until it runs out of view; still obey the herd cap.
 for _,candidate in ipairs(candidates) do
  if preferred and preferred[candidate.key] and count<(limit or 6) and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) then
   selected[candidate.key]=true count+=1
  end
 end
 local function entry(candidate)
  -- Fork balancing must never reveal a hidden runner inside the camera.
  -- Reserve new runners at the outer entry band, then retain them as they enter.
  return not previous or candidate.emerging or candidate.atDen or not View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1)
 end
 for _,candidate in ipairs(candidates) do
  if not selected[candidate.key] and previous and previous[candidate.key] and count<(limit or 6) and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) then
   selected[candidate.key]=true count+=1
  end
  if entry(candidate) and View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1.15) then
   candidate.score=(candidate.z-z+15)^2+candidate.x*candidate.x*.2+(View.visible(candidate.x,candidate.y,candidate.z-z,aspect,t,1) and 0 or 1000000)
   table.insert(visible,candidate)
  end
 end
 table.sort(visible,function(a,b) if a.score==b.score then return a.serial<b.serial end return a.score<b.score end)
 -- Fill from eligible offscreen entries on the less populated side first.
 -- Retained visible runners are never replaced to force a numerical balance.
 while count<(limit or 6) do
  local left,right=0,0
  for _,candidate in ipairs(candidates) do
   if selected[candidate.key] then if candidate.x<0 then left+=1 else right+=1 end end
  end
  local preferred=left<right and -1 or right<left and 1 or nil
  local best
  for _,candidate in ipairs(visible) do
   if not selected[candidate.key] then
    if not best then best=candidate end
    if preferred and candidate.x*preferred>0 then best=candidate break end
   end
  end
  if not best then break end
  selected[best.key]=true count+=1
 end

 return selected
end
return View
