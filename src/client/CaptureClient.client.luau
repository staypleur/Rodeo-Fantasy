local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package:WaitForChild("Config"))
local Rules=require(package:WaitForChild("HuntRules"))
local remote=package:WaitForChild("CaptureRemote")
local animator=require(script.Parent:WaitForChild("RideAnimator"))
local rider=require(script.Parent:WaitForChild("RiderPresentation"))
local gauge=require(script.Parent:WaitForChild("TamingGauge"))
local crashEffect=require(script.Parent:WaitForChild("CrashEffect"))
local audio=require(script.Parent:WaitForChild("AudioPresentation"))
local catch=require(script.Parent:WaitForChild("CatchPresentation"))
local dash=require(script.Parent:WaitForChild("DashPresentation"))
local markers=require(script.Parent:WaitForChild("DistanceMarkers"))
local monsters=workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local menuBound=false local returnHeld=nil local suppressJumpUntilRelease=false
local flightFrame=nil
local savedType,savedSubject,savedFieldOfView=nil,nil,nil
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent
 return node
end
local gui=make("ScreenGui",{Name="RodeoCaptureUI",ResetOnSpawn=false,DisplayOrder=10},player:WaitForChild("PlayerGui"))
local function text(parent,value,pos,size,font)
 return make("TextLabel",{Text=value,Position=pos,Size=size,TextSize=font or 18,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,245,219),BackgroundTransparency=1,TextWrapped=true},parent)
end
local incomeFX=require(script.Parent:WaitForChild("IncomeEffects"))
local bagUI=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journalUI=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
bagUI.onOpen=journalUI.close journalUI.onOpen=bagUI.close
local locale=require(script.Parent:WaitForChild("LocalizationController"))
locale.watch(gui) locale.watch(workspace.RodeoLobby)
-- Only the owner sees a ranch interaction. The server separately checks ownership/distance.
for _,plot in ipairs(workspace.RodeoLobby.Plots:GetChildren()) do
 local function updatePrompts()
  for _,node in ipairs(plot:GetDescendants()) do
   if node:IsA("ProximityPrompt") and node.Name=="ManageRanch" then node.Enabled=plot:GetAttribute("OwnerUserId")==player.UserId end
  end
 end
 plot:GetAttributeChangedSignal("OwnerUserId"):Connect(updatePrompts)
 plot.DescendantAdded:Connect(function(node) if node:IsA("ProximityPrompt") then updatePrompts() end end)
 updatePrompts()
end
local airship=workspace.RodeoLobby.Airport.Airship
local shipAnchor=CFrame.new(6000,24,-5)
local shipParts={}
local function rememberShip(node)
 if node:IsA("BasePart") then shipParts[node]=shipAnchor:ToObjectSpace(node.CFrame) end
end
for _,node in ipairs(airship:GetDescendants()) do rememberShip(node) end
airship.DescendantAdded:Connect(rememberShip)
local function animateShip(clock)
 local sway=shipAnchor*CFrame.new(math.sin(clock*.7)*.35,math.sin(clock*.9)*.25,0)*CFrame.Angles(0,0,math.sin(clock*.7)*.018)
 for node,rest in pairs(shipParts) do
  if not node.Parent then shipParts[node]=nil continue end
  local pose=rest
  if node.Name=="SeaWingRoot" or node.Name=="SeaWingFeather" then
   local sign=rest.X<0 and -1 or 1
   local pivot=CFrame.new(sign*18,23,-4)
   pose=pivot*CFrame.Angles(0,0,sign*math.sin(clock*1.1)*.18)*pivot:Inverse()*rest
  end
  node.CFrame=sway*pose
 end
end
local function T(value) return locale.text(value) end
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=make("Frame",{Name="LobbyStats",Position=UDim2.fromOffset(16,66),Size=UDim2.fromOffset(240,48),BackgroundColor3=Color3.fromRGB(40,65,56),BackgroundTransparency=.1},gui)
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local function iconBlock(name,pos,size,color,parent,round)
 local frame=make("Frame",{Name=name,Position=pos,Size=size,BackgroundColor3=color,BorderSizePixel=0},parent)
 make("UICorner",{CornerRadius=UDim.new(0,round or 5)},frame) return frame
end
local bagIcon=iconBlock("BagIcon",UDim2.fromOffset(12,14),UDim2.fromOffset(24,26),Color3.fromRGB(178,126,84),bag)
iconBlock("Handle",UDim2.fromOffset(5,-7),UDim2.fromOffset(14,10),Color3.fromRGB(178,126,84),bagIcon)
iconBlock("Pocket",UDim2.fromOffset(4,12),UDim2.fromOffset(16,9),Color3.fromRGB(133,88,58),bagIcon)
local coinIcon=iconBlock("CoinIcon",UDim2.fromOffset(115,10),UDim2.fromOffset(28,28),Color3.fromRGB(249,198,83),bag,50)
make("UIStroke",{Color=Color3.fromRGB(220,159,45),Thickness=2},coinIcon)
iconBlock("CoinShine",UDim2.fromOffset(11,5),UDim2.fromOffset(5,18),Color3.fromRGB(255,228,138),coinIcon)
local bagCount=text(bag,"0",UDim2.fromOffset(43,4),UDim2.fromOffset(62,40),20) bagCount.Name="BagCount"
local moneyCount=text(bag,"0",UDim2.fromOffset(151,4),UDim2.fromOffset(80,40),20) moneyCount.Name="MoneyCount"
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"Rodeo Fantasy",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A/D to steer · Space to jump / again to lasso",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="Start hunt",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="Return to lobby",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={} local shadowPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,.08,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 local shadow=make("Attachment",{},ring) shadow.Position=a.Position-Vector3.new(0,.08,0) shadowPoints[i]=shadow
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(94,248,255)),Enabled=false},ring)
 beams[32+i]=make("Beam",{Name="RangeOutline",Attachment0=shadowPoints[i],Attachment1=shadowPoints[i%32+1],Width0=.32,Width1=.32,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(24,40,58)),Enabled=false},ring)
end
local function active() return state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd" end
local function steering()
 if state.phase~="Riding" then return 0 end
 local keyLeft=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.A)
 local keyRight=not UIS:GetFocusedTextBox() and UIS:IsKeyDown(Enum.KeyCode.D)
 if keyRight or keyLeft then return (keyRight and 1 or 0)-(keyLeft and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if state.phase~="Riding" then left,right=false,false return Enum.ContextActionResult.Sink end
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function jumpAction(_,inputState)
 if UIS:GetFocusedTextBox() or not active() then return Enum.ContextActionResult.Pass end
 if suppressJumpUntilRelease then
  if inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","Jump / Lasso")
  CAS:SetPosition("RodeoJump",UDim2.new(1,-95,1,-160))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.FieldOfView=Config.Prototype.CameraFieldOfView
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  CAS:UnbindAction("RodeoJump")
  camera.CameraType=savedType
  camera.FieldOfView=savedFieldOfView
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject,savedFieldOfView=nil,nil,nil
  held,left,right=false,false,false
 end
end
local function menuMode(enabled)
 if enabled==menuBound then return end menuBound=enabled returnHeld=nil
 if not enabled then CAS:UnbindAction("RodeoRetry") CAS:UnbindAction("RodeoReturn") return end
 CAS:BindActionAtPriority("RodeoRetry",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then suppressJumpUntilRelease=true remote:FireServer("Start")
  elseif inputState==Enum.UserInputState.End then suppressJumpUntilRelease=false end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.Space)
 CAS:BindActionAtPriority("RodeoReturn",function(_,inputState)
  if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then returnHeld=os.clock()
  elseif inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel then returnHeld=nil end
  return Enum.ContextActionResult.Sink
 end,false,Enum.ContextActionPriority.High.Value+3,Enum.KeyCode.E)
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=false
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 held,left,right=false,false,false returnHeld=nil
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="RanchMenu" then bagUI.openRanchMenu() return end
 if kind=="Pen" then bagUI.openPen(data) return end
 if kind=="Journal" then journalUI.snapshot(data) return end
 if kind=="Bag" then bagUI.snapshot(data) return end
 if kind~="State" then return end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame,data.monsterCrashId) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 bagUI.state(data) journalUI.state(data)
 if data.area=="Lobby" then
  bagUI.income(data.income)
  local slot=player:GetAttribute("LobbySlot")
  local plot=slot and workspace.RodeoLobby.Plots:FindFirstChild("Plot_"..slot)
  if plot and data.income and #data.income>0 then
   local pets={}
   for _,model in ipairs(plot.Pens:GetDescendants()) do if model:IsA("Model") and model:GetAttribute("BagItemId") then pets[model:GetAttribute("BagItemId")]=model end end
   for _,gain in ipairs(data.income) do if pets[gain.id] then incomeFX.pet(pets[gain.id],gain.amount) end end
  end
 else incomeFX.clear() end
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "Hunt again" or "Start hunt"
 cameraMode(active() or state.phase=="CourseEnd")
 menuMode(state.phase=="GameOver")
 bagCount.Text=tostring(state.count or 0) moneyCount.Text=tostring(state.pending or 0)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 if returnHeld and state.phase=="GameOver" and os.clock()-returnHeld>=1 then returnHeld=nil remote:FireServer("ReturnLobby") end
 local clock=workspace:GetServerTimeNow()
 if state.area=="Lobby" or state.area==nil then animateShip(clock) end
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local candidates={}
 for _,model in ipairs(monsters:GetChildren()) do
  if model.PrimaryPart and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0,emerging=model:GetAttribute("Emerging")})
  end
 end
 local selected={}
 local ids={}
 for _,id in ipairs(state.wildIds or {}) do ids[id]=true end
 for _,candidate in ipairs(candidates) do
  if ids[candidate.serial] then selected[candidate.key]=true end
 end
 local frames=animator.update(monsters,clock,root and root.Position,dt,selected)
 if state.area=="Lobby" then animator.update(workspace.RodeoLobby,clock,root and root.Position,dt) end
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
  elseif state.phase=="Airborne" and state.position and state.launchY then
   local elapsed=math.clamp(clock-(state.sampleTime or clock),0,0.3)
   local pos=state.position+Vector3.new(0,0,-t.AirStudsPerSecond)*elapsed
   local target=CFrame.new(math.clamp(pos.X,-t.RoadHalfWidth,t.RoadHalfWidth),state.launchY+Rules.jumpHeight(clock-state.started,t.FlightSeconds,t.JumpArcStuds),pos.Z)
   flightFrame=(flightFrame or root.CFrame):Lerp(target,1-math.exp(-22*dt))
   visualFrame=flightFrame
  end
 end
 local catchFov=catch.update(state,player.Character,visualFrame,clock)
 rider.update(player.Character,state.phase,visualFrame,dt,clock,state.dashUntil)
 dash.update(state.phase,visualFrame,clock,state.dashUntil,t.SwitchDashSeconds)
 crashEffect.update(player.Character,state.phase,clock)
 catch.crates(workspace.RodeoPrototype:FindFirstChild("Obstacles"),root and root.Position,clock,dt)
 audio.update(state,monsters,root and root.Position,clock,selected)
 local displayDistance=state.distance or 0
 if active() then
  local speed=state.phase=="Airborne" and t.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,(state.baseSpeed or t.ForwardStudsPerSecond),t.SwitchDashMultiplier)
  displayDistance+=math.clamp(clock-(state.sampleTime or clock),0,0.3)*speed*t.MetersPerStud
 end
 markers.update(active() or state.phase=="CourseEnd",displayDistance,visualFrame,t.MetersPerStud)
 displayDistance=math.min(displayDistance,1000)
 distance.Visible=state.area=="Hunt"
 bag.Visible=state.area=="Lobby" or state.phase=="Idle"
 distance.Text=string.format("%dm",math.floor(displayDistance))
 highlight.Enabled=false
 panel.Visible=state.phase=="CourseEnd"
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,state.tameSeconds or Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if (active() or state.phase=="CourseEnd") and root then
  -- Follow horizontal movement; jumping should not lift the whole view.
  local groundFocus=Vector3.new(0,t.CameraGroundFocusStuds,visualFrame.Position.Z)
  local target=CFrame.lookAt(groundFocus+Vector3.new(t.CameraSideStuds,t.CameraHeightStuds,t.CameraBehindStuds),groundFocus+Vector3.new(0,0,-t.CameraLookAheadStuds))
  -- The followed visual position is already smoothed; a second camera lag hides jumps.
  workspace.CurrentCamera.FieldOfView=t.CameraFieldOfView+catchFov
  workspace.CurrentCamera.CFrame=target
  workspace.CurrentCamera.Focus=CFrame.new(groundFocus)
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(visualFrame.Position.X,0.15,visualFrame.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") and not model:GetAttribute("Emerging") and selected[model] then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "Angry! Press Space to jump!" or state.tamed and "Tamed · Keep riding" or "Taming ♥"
  instruction.Text="A/D to steer · Space to jump / again to lasso"

 elseif state.phase=="Airborne" then
  status.Text="Press Space to catch the next monster!"
  instruction.Text="Lasso a monster inside the yellow ring"
 elseif state.phase=="Lassoing" then status.Text="Flying to your next mount…" instruction.Text="Keep riding after landing"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · Next region coming soon" instruction.Text="Meadow complete · Start again or return"
 elseif state.phase=="GameOver" then status.Text="Hunt ended" instruction.Text="Try again · Your bag income is kept"
 else status.Text="" instruction.Text="" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
