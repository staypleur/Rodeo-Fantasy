-- Play-only actual companion check. Stops automatically; never saved into the place.
local p=game.Players.LocalPlayer
local m=assert(workspace.RodeoLobby.LobbyCompanions:FindFirstChild("Companion_"..p.UserId))
local camera=workspace.CurrentCamera
local oldType,oldFrame=camera.CameraType,camera.CFrame
local started=os.clock()
local seen,first,changed={},{},{}
local frames,moving=0,0
local rs=game.RunService
rs:BindToRenderStep("NeutralReviewInput",202,function()
 local t=os.clock()-started
 p.Character.Humanoid:Move(t<2 and Vector3.zero or Vector3.new(t%8<4 and 1 or -1,0,0),false)
end)
rs:BindToRenderStep("NeutralReviewSample",210,function()
 local t=os.clock()-started
 frames+=1
 if m:GetAttribute("Running") then moving+=1 end
 for _,b in ipairs(m.Body:GetDescendants()) do
  if b:IsA("Bone") then
   first[b.Name]=first[b.Name] or b.Transform
   if (b.Transform.Position-first[b.Name].Position).Magnitude>.001 or b.Transform.LookVector:Dot(first[b.Name].LookVector)<.99999 then changed[b.Name]=true end
  end
 end
 if not p:GetAttribute("LobbyRiding") then
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(m.Body.Position+Vector3.new(7,3,-9),m.Body.Position)
 end
 if t>=12 then
  rs:UnbindFromRenderStep("NeutralReviewInput") rs:UnbindFromRenderStep("NeutralReviewSample")
  p.Character.Humanoid:Move(Vector3.zero,false)
  camera.CameraType=oldType camera.CFrame=oldFrame
  for name in pairs(changed) do seen[#seen+1]=name end table.sort(seen)
  print("NEUTRAL_RUNTIME_REVIEW",m:GetAttribute("Stars"),frames,moving,"moving frames",table.concat(seen,","),m.Body.MeshId)
 end
end)
