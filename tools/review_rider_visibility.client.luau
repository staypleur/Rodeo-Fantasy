-- Play-only diagnostic; removed when Studio stops. No saved inventory changes.
local p=game.Players.LocalPlayer
assert(p:GetAttribute("LobbyRiding"),"Mount first")
local rs=game.RunService
local camera=workspace.CurrentCamera
local started=os.clock()
local samples,hidden,wrongCamera,switches=0,0,0,0
local changed=camera:GetPropertyChangedSignal("CameraType"):Connect(function() switches+=1 end)
rs:BindToRenderStep("VisibilityReviewInput",202,function()
 local t=os.clock()-started
 p.Character.Humanoid:Move(t<2 and Vector3.zero or Vector3.new(t%4<2 and 1 or -1,0,0),false)
end)
rs:BindToRenderStep("VisibilityReviewSample",204,function()
 samples+=1
 if camera.CameraType~=Enum.CameraType.Scriptable then wrongCamera+=1 end
 for _,part in ipairs(p.Character:GetDescendants()) do
  if part:IsA("BasePart") and part.Transparency<1 and part.LocalTransparencyModifier>.01 then hidden+=1 break end
 end
 if os.clock()-started>=12 then
  changed:Disconnect()
  rs:UnbindFromRenderStep("VisibilityReviewInput") rs:UnbindFromRenderStep("VisibilityReviewSample")
  p.Character.Humanoid:Move(Vector3.zero,false)
  print("RIDER_VISIBILITY_REVIEW",samples,"frames",hidden,"hidden frames",wrongCamera,"wrong camera frames",switches,"camera switches")
 end
end)
