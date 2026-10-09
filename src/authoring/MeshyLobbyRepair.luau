-- Apply in EDIT mode. Preserve uploaded mesh/PBR assets and owner configuration.
local M={}
function M.apply()
 assert(not game:GetService("RunService"):IsRunning(),"Stop Play before repairing")
 local package=game:GetService("ReplicatedStorage").RodeoFantasy
 local ss=game:GetService("ServerStorage")
 local hunt=assert(package:FindFirstChild("MeshyMossratHuntTemplate"),"Missing hunt visual template")
 local server=assert(ss:FindFirstChild("RodeoMonsterTemplate"),"Missing server monster template")
 local ship=workspace.RodeoLobby.Airport.Airship
 assert(ship:GetAttribute("NativeMeshyAirship") and ship:FindFirstChild("MeshyAirshipBody"),"Missing installed native airship")
 for _,model in ipairs({hunt,server}) do
  assert(model:GetAttribute("NativeMeshyMossrat") and model.PrimaryPart and model:FindFirstChild("Body"),"Missing installed native Mossrat")
 end
 local backup=ss:FindFirstChild("LobbyRepairBackup20261010")
 if not backup then
  backup=Instance.new("Folder") backup.Name="LobbyRepairBackup20261010" backup.Parent=ss
  for _,model in ipairs({hunt,server,ship}) do model:Clone().Parent=backup end
 end
 for _,model in ipairs({hunt,server}) do
  -- Undo the earlier direct-body patch before applying an explicit runtime yaw.
  if model:GetAttribute("HuntFacingRepair20261010") then
   for _,part in ipairs(model:GetChildren()) do
    if part:IsA("MeshPart") then
     local rest=model.PrimaryPart.CFrame:ToObjectSpace(part.CFrame)
     rest=CFrame.new(rest.Position)*CFrame.Angles(0,math.pi,0)*rest.Rotation
     part.CFrame=model.PrimaryPart.CFrame*rest
     part:SetAttribute("ApprovedRest",rest) part:SetAttribute("ApprovedPivot",rest.Position)
    end
   end
   model:SetAttribute("HuntFacingRepair20261010",nil)
  end
  model:SetAttribute("MeshyVisualYawDegrees",180)
  model:SetAttribute("MeshyFacingRevision",model:GetAttribute("HeadShapeStraightened") and "HeadStraight-v1" or "HuntFacing-v2")
  model:SetAttribute("FaceCourseForward",false)
 end
 -- Use a fresh ModuleScript instance: require caches an already-loaded installer.
 local fresh=package.MeshyAirshipInstaller:Clone() fresh.Name="AirshipRealignOnce" fresh.Parent=package
 local ok,result=pcall(function() return require(fresh).realignInstalled("-Z") end)
 fresh:Destroy()
 assert(ok,result)
 print("LOBBY_MODEL_REPAIR_APPLIED: runtime hunt facing and airship orientation; uploaded assets preserved")
 return true
end
function M.retryTextures()
 local body=workspace.RodeoLobby.Airport.Airship.MeshyAirshipBody
 local appearance=assert(body:FindFirstChildOfClass("SurfaceAppearance"),"Missing appearance")
 local count=0
 for _,key in ipairs({"ColorMap","MetalnessMap","RoughnessMap"}) do
  local id=appearance[key]:match("(%d+)$")
  if id then
   -- A different supported asset URI makes one fresh request after prior cached failures.
   local uri="https://www.roblox.com/asset/?id="..id
   task.spawn(function()
    local succeeded=false
    local ok,err=pcall(function()
     game:GetService("ContentProvider"):PreloadAsync({uri},function(_,status)
      succeeded=status==Enum.AssetFetchStatus.Success
     end)
    end)
    if ok and succeeded and appearance.Parent then appearance[key]=uri count+=1 end
    print("AIRSHIP_TEXTURE_RETRY",key,ok and succeeded and "Success" or "Failure")
    if not ok then warn(tostring(err)) end
   end)
  end
 end
end
return M
