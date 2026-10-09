-- User-authored Meshy assets: shared native MeshParts, no EditableMesh allocation.
local M={}
local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")
local C=require(package:WaitForChild("MonsterCatalog"))
local boneCache=setmetatable({},{__mode="k"})
function M.isTarget(model)
 local visual=package:FindFirstChild("VisualTemplate")
 return model:GetAttribute("MonsterId")=="MeadowMouse" and C.stage(model:GetAttribute("Stars") or 1)==1 and visual~=nil and visual:GetAttribute("NativeMeshyMossrat")==true
end
function M.apply(model)
 if not M.isTarget(model) or not model.PrimaryPart then return false end
 local stars=model:GetAttribute("Stars") or 1
 local source=model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate") or package.VisualTemplate
 if not source then return false end
 local facingRevision=source:GetAttribute("MeshyFacingRevision") or "Original"
 local yaw=source:GetAttribute("MeshyVisualYawDegrees") or 0
 if model:GetAttribute("NativeMeshyReady") and model:GetAttribute("NativeMeshyStars")==stars and model:GetAttribute("NativeMeshyFacingRevision")==facingRevision and model:FindFirstChild("Body") then return true end
 local scale=C.scale(model:GetAttribute("Stars") or 1)
 local staged={}
 for _,original in ipairs(source:GetChildren()) do
  if original:IsA("MeshPart") then
   local part=original:Clone()
   local rest=source.PrimaryPart.CFrame:ToObjectSpace(original.CFrame)
   rest=CFrame.new(rest.Position*scale)*CFrame.Angles(0,math.rad(yaw),0)*rest.Rotation
   part.Size*=scale
   if scale~=1 then
    for _,bone in ipairs(part:GetDescendants()) do
     if bone:IsA("Bone") then bone.CFrame=CFrame.new(bone.CFrame.Position*scale)*bone.CFrame.Rotation end
    end
   end
   part.CFrame=model.PrimaryPart.CFrame*rest
   part:SetAttribute("ApprovedRest",rest)
   part:SetAttribute("ApprovedPivot",rest.Position)
   if model:GetAttribute("PortraitSilhouette") then
    for _,child in ipairs(part:GetChildren()) do if child:IsA("SurfaceAppearance") then child:Destroy() end end
    part.TextureID="" part.Color=Color3.new(0,0,0)
   end
   table.insert(staged,part)
  end
 end
 if #staged==0 then return false end
 for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and part~=model.PrimaryPart then part:Destroy() end end
 for _,part in ipairs(staged) do part.Parent=model end
 model:SetAttribute("ImportedA",true)
 model:SetAttribute("NativeMeshyReady",true)
 model:SetAttribute("NativeMeshyStars",stars)
 model:SetAttribute("NativeMeshyFacingRevision",facingRevision)
 model:SetAttribute("MeshDecorated",true)
 return true
end
-- Hunt presentation faces the course while the authoritative root still avoids obstacles.
function M.huntFrame(model,frame)
 local hunt=package:FindFirstChild("MeshyMossratHuntTemplate")
 if model:GetAttribute("VisualDeferred") and M.isTarget(model) and hunt and hunt:GetAttribute("FaceCourseForward") then
  return CFrame.new(frame.Position),true
 end
 return frame,false
end
function M.animate(model,phase,moving,angry)
 if not M.isTarget(model) then return end
 local body=model:FindFirstChild("Body")
 if not body then return end
 local cached=boneCache[model]
 if not cached or cached.body~=body then
  cached={body=body,bones={}}
  for _,bone in ipairs(body:GetDescendants()) do
   if bone:IsA("Bone") and bone.Name:match("^Moss.+Leg$") then
    table.insert(cached.bones,{bone=bone,opposite=(bone.Name:find("Left")~=nil)~=(bone.Name:find("Front")~=nil)})
   end
  end
  boneCache[model]=cached
 end
 for _,entry in ipairs(cached.bones) do
  local angle=moving and math.sin(phase+(entry.opposite and math.pi or 0))*(angry and .55 or .45) or 0
  entry.bone.Transform=CFrame.Angles(angle,0,0)
 end
end
return M
