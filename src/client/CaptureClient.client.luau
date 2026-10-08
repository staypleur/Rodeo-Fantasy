local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Rules=require(package.HuntRules)
local remote=package.CaptureRemote
local animator=require(script.Parent.RideAnimator)
local monsters=workspace.RodeoPrototype.Monsters
local state={phase="Idle",started=0,count=0,pending=0,distance=0}
local held,left,right=false,false,false
local pointerOrigin,pointerX,lastSteer=nil,nil,0
local notice,noticeUntil="",0
local savedType,savedSubject=nil,nil
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
local distance=text(gui,"0m",UDim2.fromOffset(16,16),UDim2.fromOffset(160,48),32)
local bag=text(gui,"가방: 0마리 · 모인 돈: 0원",UDim2.fromOffset(16,64),UDim2.fromOffset(360,32),16)
local panel=make("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-20),Size=UDim2.new(0.9,0,0,128),BackgroundColor3=Color3.fromRGB(36,29,25),BackgroundTransparency=0.15,BorderSizePixel=0},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(650,128)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local status=text(panel,"로데오 스트릿 · 파이리 사냥",UDim2.fromOffset(12,6),UDim2.new(1,-24,0,32),20)
local instruction=text(panel,"누르고 달리기 → 떼서 점프 → 다시 눌러 줄 던지기",UDim2.fromOffset(12,42),UDim2.new(1,-24,0,32),15)
local progress=make("Frame",{Name="TamingProgress",Position=UDim2.new(0,16,0,90),Size=UDim2.new(1,-32,0,14),BackgroundColor3=Color3.fromRGB(94,70,50),BorderSizePixel=0,Visible=false},panel)
local fill=make("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(244,127,115),BorderSizePixel=0},progress)
local startButton=make("TextButton",{Name="StartHunt",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(230,64),Text="사냥 시작",TextSize=24,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(219,103,41)},gui)
make("UICorner",{CornerRadius=UDim.new(0,16)},startButton)
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
local function active() return state.phase~="Idle" and state.phase~="GameOver" end
local function steering()
 if right or left then return (right and 1 or 0)-(left and 1 or 0) end
 if held and pointerOrigin and pointerX then
  local dx=pointerX-pointerOrigin
  return math.abs(dx)<14 and 0 or math.clamp(dx/120,-1,1)
 end
 return 0
end
local function keyAction(_,inputState,input)
 local down=inputState==Enum.UserInputState.Begin
 if inputState==Enum.UserInputState.Cancel then left,right=false,false else
  if input.KeyCode==Enum.KeyCode.A then left=down end
  if input.KeyCode==Enum.KeyCode.D then right=down end
 end
 return Enum.ContextActionResult.Sink
end
local function cameraMode(enabled)
 local camera=workspace.CurrentCamera
 if enabled and savedType==nil then
  savedType,savedSubject=camera.CameraType,camera.CameraSubject
  CAS:BindActionAtPriority("RodeoSteer",keyAction,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.W,Enum.KeyCode.S,Enum.KeyCode.Space)
  camera.CameraType=Enum.CameraType.Scriptable
 elseif not enabled and savedType~=nil then
  CAS:UnbindAction("RodeoSteer")
  camera.CameraType=savedType
  if savedSubject and savedSubject.Parent then camera.CameraSubject=savedSubject end
  savedType,savedSubject=nil,nil
  held,left,right=false,false,false
 end
end
startButton.Activated:Connect(function() remote:FireServer("Start") end)
UIS.InputBegan:Connect(function(input,processed)
 if processed or not active() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  held=true pointerOrigin,pointerX=input.Position.X,input.Position.X
  remote:FireServer("Hold",true)
 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then pointerX=input.Position.X end
end)
UIS.InputEnded:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  if held then held=false remote:FireServer("Hold",false) end
  pointerOrigin,pointerX=nil,nil
 end
end)
UIS.WindowFocusReleased:Connect(function()
 if held then remote:FireServer("Hold",false) end
 held,left,right=false,false,false
end)
remote.OnClientEvent:Connect(function(kind,data)
 if kind~="State" then return end
 state=data
 if data.message then notice,noticeUntil=data.message,os.clock()+3 end
 startButton.Visible=not active()
 startButton.Text=state.phase=="GameOver" and "다시 사냥하기" or "사냥 시작"
 cameraMode(active())
 bag.Text=string.format("가방: %d마리 · 모인 돈: %d원",state.count,state.pending)
end)
player.CharacterAdded:Connect(function() state.phase="Idle" cameraMode(false) remote:FireServer("Sync") end)
RunService.RenderStepped:Connect(function(dt)
 local clock=workspace:GetServerTimeNow()
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 animator.update(monsters,clock,root and root.Position)
 distance.Text=string.format("%dm",math.floor(state.distance or 0))
 highlight.Enabled=false
 progress.Visible=state.phase=="Riding"
 for _,beam in ipairs(beams) do beam.Enabled=state.phase=="Airborne" end
 if active() and root then
  local t=Config.Prototype
  local target=CFrame.lookAt(root.Position+Vector3.new(0,t.CameraHeightStuds,t.CameraBehindStuds),root.Position+Vector3.new(0,0,-t.CameraLookAheadStuds))
  workspace.CurrentCamera.CFrame=workspace.CurrentCamera.CFrame:Lerp(target,1-math.exp(-10*dt))
  if os.clock()-lastSteer>=0.1 then remote:FireServer("Steer",steering()) lastSteer=os.clock() end
 end
 if state.phase=="Airborne" and root then
  ring.Position=Vector3.new(root.Position.X,0.15,root.Position.Z)
  local nearest,best=nil,Config.Prototype.LassoRangeStuds^2
  for _,model in ipairs(monsters:GetChildren()) do
   if model.PrimaryPart and not model:GetAttribute("Occupied") then
    local d=model.PrimaryPart.Position-root.Position
    if d.X*d.X+d.Z*d.Z<best then nearest,best=model,d.X*d.X+d.Z*d.Z end
   end
  end
  if nearest then highlight.Adornee,highlight.Enabled=nearest,true end
 end
 if state.phase=="Riding" then
  fill.Size=UDim2.fromScale(state.tamed and 1 or Rules.progress(clock-state.started,Config.Hunt.TameSeconds),1)
  status.Text=state.angerAt and "화났어요! 손을 떼고 점프하세요!" or state.tamed and "길들이기 성공 · 다음 포켓몬으로!" or "파이리 길들이는 중 ♥"
  instruction.Text="누른 채 좌우로 움직이기 / A·D · 손을 떼면 점프"
 elseif state.phase=="Airborne" then
  status.Text="다시 눌러 다음 포켓몬을 잡으세요!"
  instruction.Text="노란 원 안에 포켓몬이 들어오면 줄이 연결됩니다"
 elseif state.phase=="Lassoing" then status.Text="줄로 연결해 탑승 중…" instruction.Text="계속 누르고 계세요"
 elseif state.phase=="GameOver" then status.Text="사냥 종료" instruction.Text="다시 사냥하기로 재도전 · 가방 수익은 유지"
 else status.Text="로데오 스트릿 · 파이리 사냥" instruction.Text="사냥 시작 → 누르고 달리기 → 떼서 점프 → 다시 눌러 줄 던지기" end
 if os.clock()<noticeUntil then status.Text=notice end
end)
remote:FireServer("Sync")
