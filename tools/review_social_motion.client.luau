-- Studio Play-only fixture: local clones, no inventory or persistent data changes.
local player=game.Players.LocalPlayer
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local C=require(P.MonsterCatalog)
local A=require(player:WaitForChild("PlayerScripts"):WaitForChild("RideAnimator"))
local R=require(P.LobbyRideRules)
local map=workspace:FindFirstChild("RodeoCafe") or workspace:WaitForChild("RodeoLobby")
local folder=Instance.new("Folder") folder.Name="SocialMotionDiagnostic" folder.Parent=map
local camera=workspace.CurrentCamera
local originalType,originalFrame=camera.CameraType,camera.CFrame
task.wait(2) -- Default camera finishes character setup before this fixture owns it.
camera.CameraType=Enum.CameraType.Scriptable
local origin=Vector3.new(0,5000,0)
camera.CFrame=CFrame.lookAt(origin+Vector3.new(12,12,-26),origin)
local heading=Vector3.new(0,0,-1)
for _,sign in ipairs({1,-1}) do
 for i=1,240 do
  local target=CFrame.Angles(0,sign*i*math.pi*2/240,0).LookVector
  local nextHeading=R.turn(heading,target,1/60)
  assert(nextHeading.Magnitude>.999 and nextHeading.Magnitude<1.001)
  assert(math.acos(math.clamp(heading:Dot(nextHeading),-1,1))<=math.pi*1.5/60+.0001)
  heading=nextHeading
 end
end
assert(R.turn(Vector3.new(0,0,-1),Vector3.new(0,0,1),.1).Magnitude>.999)
for _,id in ipairs({"MeadowMouse","GrassBoar"}) do
 for _,stage in ipairs({1,3,6,9}) do
  local model=P[C.visual(id,stage)]:Clone() model.Name="Review_"..id..stage
  model:SetAttribute("MonsterId",id) model:SetAttribute("Stars",stage)
  model:SetAttribute("OwnerUserId",player.UserId) model:SetAttribute("BagItemId","LOCAL_REVIEW")
  model:SetAttribute("Running",true) model:SetAttribute("HerdVelocity",Vector3.new(6,0,0))
  model:PivotTo(CFrame.new(origin)*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Parent=folder
  local t,acc,samples,changed=0,0,0,0
  local previous,bonePrevious
  local boneChanged=false
  while t<1.5 do
   local dt=game.RunService.RenderStepped:Wait() t+=dt acc+=dt
   camera.CameraType=Enum.CameraType.Scriptable
   camera.CFrame=CFrame.lookAt(origin+Vector3.new(12,12,-26),origin)
   if acc>=.1 then
    acc%=.1
    model.PrimaryPart.CFrame=CFrame.new(origin+Vector3.new(t*6,0,0))*CFrame.Angles(0,t*2,0)
   end
   A.update(map,workspace:GetServerTimeNow(),origin,dt)
   local frame=assert(A.travelFrame(model),"Nested companion skipped")
   if previous and (frame.Position-previous.Position).Magnitude>.00001 then changed+=1 end
   previous=frame samples+=1
   local bone=model.Body:FindFirstChild("LeftRearUpper",true) or model.Body:FindFirstChild("mixamorig:LeftUpLeg",true)
   if bone and bonePrevious and bone.Transform~=bonePrevious then boneChanged=true end
   bonePrevious=bone and bone.Transform
  end
  assert(changed>samples*.6,"Presentation follows only network samples")
  assert(boneChanged,"Locomotion bone did not animate")
  model:SetAttribute("Running",false)
  if stage==1 then
   local now=workspace:GetServerTimeNow()
   model:SetAttribute("PetBondStarted",now) model:SetAttribute("PetBondUntil",now+3)
   local neck=model.Body:FindFirstChild("Neck",true)
   local before=neck.Transform
   for i=1,25 do
    local dt=game.RunService.RenderStepped:Wait()
    camera.CameraType=Enum.CameraType.Scriptable
    camera.CFrame=CFrame.lookAt(origin+Vector3.new(12,12,-26),origin)
    A.update(map,workspace:GetServerTimeNow(),origin,dt)
   end
   assert(neck.Transform~=before,"Bond neck did not animate")
  end
  print("SOCIAL_MOTION_PLAY_PASS",map.Name,id,stage,samples,changed,boneChanged)
  model:Destroy()
 end
end
folder:Destroy()
camera.CameraType=originalType camera.CFrame=originalFrame
print("SOCIAL_MOTION_ALL_PASS",game.PlaceId,"nested scope, 8 rigs, 2 bonds, clockwise/counterclockwise 360 and reversal")
