-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local rules=require(package.LobbyRideRules)
 local presentation=require(script.Parent.RideAnimator)
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent.HudIcons).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoLobby")
  local folder=map and map:FindFirstChild("LobbyCompanions")
  local pet=folder and folder:FindFirstChild("Companion_"..player.UserId)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if pet and root and pet.PrimaryPart and pet:GetAttribute("OwnerUserId")==player.UserId
   and (root.Position-pet.PrimaryPart.Position).Magnitude<=10 then return pet end
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  current=nearby() local mounted=player:GetAttribute("LobbyRiding")==true
  button.Visible=current~=nil and rules.canBond(current:GetAttribute("Stars")) and not mounted
  ride.Visible=mounted or current~=nil and rules.canRide(current:GetAttribute("Stars"))
  button.Position=UDim2.new(.5,0,1,-76) ride.Position=button.Position ring.Enabled=mounted
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current and rules.canBond(pet:GetAttribute("Stars")) then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 ride.Activated:Connect(function()
  local pet=nearby()
  if player:GetAttribute("LobbyRiding") or pet and rules.canRide(pet:GetAttribute("Stars")) then package.CaptureRemote:FireServer("RidePet",pet and pet:GetAttribute("BagItemId")) end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0 local lastInput
 local cameraTarget local cameraHeading local cameraPet
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then
    oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView}
    -- Clear any first-person fade left by the default camera on mounting.
    for _,node in ipairs(player.Character:GetDescendants()) do
     if node:IsA("BasePart") then node.LocalTransparencyModifier=0 end
    end
   end
   camera.CameraType=Enum.CameraType.Scriptable
   local pet=current and current.Parent and current local part=pet and pet.PrimaryPart
   -- Match rider and camera to the pet's interpolated visual frame, not its
   -- server root, which intentionally arrives at a lower network frequency.
   local frame=pet and presentation.frame(pet) or (part and part.CFrame or root.CFrame)
   local height=pet and pet:FindFirstChild("Body") and pet.Body.Size.Y or 4
   if pet and part and root.Anchored then
    local rootHeight=pet:GetAttribute("RootHeight") or 2
    local upright=(pet:GetAttribute("Stars") or 1)>=6
    local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
    root.CFrame=frame*CFrame.new(offset)
   end
   local travel=pet and presentation.travelFrame(pet) or (part and part.CFrame or root.CFrame)
   local forward=Vector3.new(travel.LookVector.X,0,travel.LookVector.Z)
   if forward.Magnitude<.001 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
   local rootHeight=pet and pet:GetAttribute("RootHeight") or 2
   local upright=pet and (pet:GetAttribute("Stars") or 1)>=6
   local offset=upright and Vector3.new(0,height*.62-rootHeight,1.35) or Vector3.new(0,height*.62-rootHeight+1.25,.15)
   local target=(travel*CFrame.new(offset)).Position+Vector3.new(0,1,0)
   local heading=CFrame.lookAt(Vector3.zero,forward)
   if cameraPet~=pet or not cameraTarget or (target-cameraTarget).Magnitude>30 then
    cameraTarget=target cameraHeading=heading cameraPet=pet
   else
    cameraTarget=cameraTarget:Lerp(target,1-math.exp(-14*dt))
    cameraHeading=cameraHeading:Lerp(heading,1-math.exp(-8*dt))
   end
   camera.CFrame=CFrame.lookAt(cameraTarget-cameraHeading.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),cameraTarget)
   camera.Focus=CFrame.new(cameraTarget)
   inputTime+=dt
   local direction=hum.MoveDirection
   if inputTime>=.08 and (not lastInput or (direction-lastInput).Magnitude>.02 or inputTime>=.25) then
    inputTime=0 lastInput=direction package.CaptureRemote:FireServer("RideInput",direction)
   end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
   inputTime=0 lastInput=nil cameraTarget=nil cameraHeading=nil cameraPet=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
