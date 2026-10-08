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
local distance=text(gui,"0m",UDim2.new(0.5,-80,0,12),UDim2.fromOffset(160,48),32)
distance.Name="DistanceCounter"
distance.TextColor3=Color3.fromRGB(255,232,151)
distance.TextStrokeColor3=Color3.fromRGB(26,46,35) distance.TextStrokeTransparency=0
distance.BackgroundColor3=Color3.fromRGB(31,55,42) distance.BackgroundTransparency=0.12
make("UICorner",{CornerRadius=UDim.new(0,14)},distance)
make("UIStroke",{Color=Color3.fromRGB(113,148,95),Thickness=2},distance)
local lastAspect=nil
local bag=text(gui,"가방: 0마리 · 모인 돈: 0원",UDim2.fromOffset(16,16),UDim2.fromOffset(320,42),16)
bag.Name="LobbyStats" bag.BackgroundColor3=Color3.fromRGB(40,65,56) bag.BackgroundTransparency=0.1
make("UICorner",{CornerRadius=UDim.new(0,12)},bag)
local panel=make("Frame",{Name="HuntHelp",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,94),BackgroundColor3=Color3.fromRGB(43,67,49),BackgroundTransparency=0.22,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(510,94)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"로데오 스트릿 · 루미돈 사냥",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),18)
local instruction=text(panel,"A·D 좌우 이동 → 스페이스바 점프 → 다시 눌러 줄",UDim2.fromOffset(12,34),UDim2.new(1,-24,0,28),13)
local startButton=make("TextButton",{Name="StartHunt",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="사냥 시작",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
local returnButton=make("TextButton",{Name="ReturnLobby",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.64),Size=UDim2.fromOffset(230,48),Text="로비로 돌아가기",TextSize=18,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(78,132,114),Visible=false},gui)
make("UICorner",{CornerRadius=UDim.new(0,14)},returnButton)
returnButton.Activated:Connect(function() remote:FireServer("ReturnLobby") end)
local highlight=make("Highlight",{Enabled=false,FillTransparency=0.82,OutlineColor=Color3.fromRGB(255,222,91)},gui)
local ring=make("Part",{Name="LocalLassoRange",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Transparency=1,Size=Vector3.new(1,1,1)},workspace)
local ringPoints={}
for i=1,32 do
 local a=make("Attachment",{},ring)
 local angle=(i-1)/32*math.pi*2
 a.Position=Vector3.new(math.cos(angle)*Config.Prototype.LassoRangeStuds,0,math.sin(angle)*Config.Prototype.LassoRangeStuds)
 ringPoints[i]=a
end
local beams={}
for i=1,32 do
 beams[i]=make("Beam",{Attachment0=ringPoints[i],Attachment1=ringPoints[i%32+1],Width0=0.12,Width1=0.12,FaceCamera=true,Color=ColorSequence.new(Color3.fromRGB(255,224,83)),Enabled=false},ring)
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
 if inputState==Enum.UserInputState.Begin then remote:FireServer("Jump") end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject,savedFieldOfView=camera.CameraType,camera.CameraSubject,camera.FieldOfView
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S)
  CAS:BindActionAtPriority("RodeoJump",jumpAction,true,Enum.ContextActionPriority.High.Value+2,Enum.KeyCode.Space)
  CAS:SetTitle("RodeoJump","점프 / 줄")
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
 held,left,right=false,false,false
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind~="State" then return end
 if data.phase=="GameOver" and state.phase~="GameOver" and data.crash then crashEffect.start(player.Character,workspace:GetServerTimeNow(),data.monsterCrashFrame) end
 if data.phase~=state.phase then notice,noticeUntil="",0 end
 state=data
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=state.phase~="Idle" and not active()
 returnButton.Visible=state.phase=="GameOver" or state.phase=="CourseEnd"
 startButton.Text=state.phase=="GameOver" and "다시 사냥하기" or "사냥 시작"
 cameraMode(active() or state.phase=="CourseEnd")
 bag.Text=string.format("가방: %d마리 · 모인 돈: %d원",state.count,state.pending)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService:BindToRenderStep("RodeoCapturePresentation", Enum.RenderPriority.Camera.Value+1, function(dt)
 local clock=workspace:GetServerTimeNow()
 local size=workspace.CurrentCamera.ViewportSize
 local aspect=size.Y>0 and math.clamp(size.X/size.Y,0.4,4) or 1
 if not lastAspect or math.abs(aspect-lastAspect)>0.05 then remote:FireServer("View",aspect) lastAspect=aspect end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local frames=animator.update(monsters,clock,root and root.Position,dt)
 local t=Config.Prototype
 local visualFrame=root and root.CFrame
 if state.phase~="Airborne" then flightFrame=nil end
 if active() and root then
  local mount=state.monster and frames[state.monster]
  if (state.phase=="Riding" or state.phase=="CourseEnd") and mount then
   visualFrame=mount*CFrame.new(0,t.RideHeightStuds,t.RideForwardStuds)
  elseif state.phase=="Lassoing" and mount and state.origin then
   local p=math.clamp((clock-state.started)/(state.landingSeconds or t.JumpSeconds),0,1)
   visualFrame=state.origin:Lerp(mount*CFrame.new(0,t.RideHeightStuds,t.RideForwardStuds),p)*CFrame.new(0,math.sin(math.pi*p)*t.JumpArcStuds*0.5,0)
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
 audio.update(state,monsters,root and root.Position,clock)
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
 panel.Visible=not active()
 gauge.update(state.phase=="Riding" and state.monster and frames[state.monster] or nil,state.tamed and 1 or Rules.progress(clock-state.started,Config.Hunt.TameSeconds),state.tamed,workspace.CurrentCamera)
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
   if model.PrimaryPart and model~=state.previousMonster and not model:GetAttribute("Occupied") then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  status.Text=state.angerAt and "화났어요! 스페이스바로 점프하세요!" or state.tamed and "길들이기 성공 · 계속 타고 달리세요" or "루미돈 길들이는 중 ♥"
  instruction.Text="A·D로 좌우 이동 · 스페이스바로 점프 / 공중에서 다시 누르면 줄"

 elseif state.phase=="Airborne" then
  status.Text="스페이스바로 다음 몬스터를 잡으세요!"
  instruction.Text="노란 원 안에 몬스터가 들어오면 줄이 연결됩니다"
 elseif state.phase=="Lassoing" then status.Text="날아가서 탑승하는 중…" instruction.Text="탑승 후 계속 타고 달릴 수 있어요"
 elseif state.phase=="CourseEnd" then status.Text="1,000m · 다음 지역 준비 중" instruction.Text="초원 시험 구간이 끝났어요 · 사냥 시작으로 다시 달릴 수 있어요"
 elseif state.phase=="GameOver" then status.Text="사냥 종료" instruction.Text="다시 사냥하기로 재도전 · 가방 수익은 유지"
 else status.Text="로데오 판타지 · 파스텔 로비" instruction.Text="비행장으로 걸어가 E를 누르면 사냥터로 출발해요" end
 if os.clock()<noticeUntil and not state.angerAt then status.Text=notice end
end)
remote:FireServer("Sync")
