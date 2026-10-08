-- Same road-centred camera as the client. Numeric projection is testable offline.
local View={}
function View.visible(x,y,relativeZ,aspect,t)
 local fx,fy,fz=-t.CameraSideStuds,-t.CameraHeightStuds,-(t.CameraBehindStuds+t.CameraLookAheadStuds)
 local length=math.sqrt(fx*fx+fy*fy+fz*fz)
 fx,fy,fz=fx/length,fy/length,fz/length
 local horizontal=math.sqrt(fx*fx+fz*fz)
 local rx,rz=-fz/horizontal,fx/horizontal
 local ux,uy,uz=-rz*fy,rz*fx-rx*fz,rx*fy
 local dx,dy,dz=x-t.CameraSideStuds,y-t.CameraGroundFocusStuds-t.CameraHeightStuds,relativeZ-t.CameraBehindStuds
 local depth=dx*fx+dy*fy+dz*fz
 if depth<=0 then return false end
 local half=depth*math.tan(math.rad(t.CameraFieldOfView)/2)*0.82
 return math.abs(dx*rx+dz*rz)<half*aspect and math.abs(dx*ux+dy*uy+dz*uz)<half
end
return View
