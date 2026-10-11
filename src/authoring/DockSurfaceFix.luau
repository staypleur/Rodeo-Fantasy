-- Reversible, idempotent repair: inset the buried core faces from the trim.
local M={}
function M.apply(airport)
 local count=0
 for _,part in ipairs(airport:GetChildren()) do
  if part:IsA("BasePart") and part.Name=="DockLayer" and not part:GetAttribute("DockSurfaceV2") then
   part:SetAttribute("DockOriginalSize",part.Size)
   part.Size-=Vector3.new(.08,0,.08)
   part:SetAttribute("DockSurfaceV2",true) count+=1
  end
 end
 return count
end
return M
