-- Studio Play client diagnostic only; changes disappear when Play stops.
local p=game.Players.LocalPlayer assert(p)
local package=game.ReplicatedStorage.RodeoFantasy
local animator=require(p.PlayerScripts.NativeMossrat)
local models={}
for i,stage in ipairs({1,3,6,9}) do
 local m=package:FindFirstChild("VisualTemplate"..(stage==1 and "" or "_S"..stage)):Clone()
 m.Name="SharedMotionReview"..stage m:SetAttribute("Stars",stage)
 m:SetAttribute("MonsterId","MeadowMouse")
 m:SetAttribute("NativeMeshyReady",false)
 m.Parent=workspace
 m:PivotTo(CFrame.new(5983+(i-1)*11,10,75))
 assert(animator.apply(m),"Native template failed")
 models[#models+1]=m
end
local started=os.clock() local samples={0,0,0,0} local previous={}
game:GetService("RunService"):BindToRenderStep("SharedMotionReview",1000,function()
 local t=os.clock()-started
 for i,m in ipairs(models) do
  m:SetAttribute("HerdVelocity",Vector3.new(0,0,t%12<6 and 12 or 30))
  animator.animate(m,t,true,false)
  local leg=m.Body:FindFirstChild(i==3 and "mixamorig:LeftLeg" or "LeftRearLower",true)
  if leg and previous[i]~=leg.Transform then samples[i]+=1 previous[i]=leg.Transform end
 end
 workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
 workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(6000,16,37),Vector3.new(6000,12,75))
end)
task.delay(8,function() print("SHARED_MOTION_RUNTIME",table.unpack(samples)) end)
