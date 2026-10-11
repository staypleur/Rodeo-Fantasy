-- Activity controls operate on real cafe furniture; no full-screen imitation board.
local U={}
function U.new(gui,onOpen)
 local Players=game:GetService("Players") local player=Players.LocalPlayer
 local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
 local remote=P:WaitForChild("CafeActivityRemote")
 local UIS=game:GetService("UserInputService") local CAS=game:GetService("ContextActionService")
 local Audio=require(script.Parent:WaitForChild("AudioPresentation")) local notes=require(P:WaitForChild("PianoNotes"))
 local function make(class,properties,parent)
  local n=Instance.new(class) for k,v in pairs(properties) do n[k]=v end n.Parent=parent return n
 end
 local strip=make("Frame",{Name="CafeActivityControls",Visible=false,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,0),Size=UDim2.new(.9,0,0,54),BackgroundColor3=Color3.fromRGB(37,29,47)},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(650,54)},strip) make("UICorner",{CornerRadius=UDim.new(0,12)},strip)
 local title=make("TextLabel",{Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-110,1,0),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextScaled=true,Font=Enum.Font.GothamBold,Text=""},strip)
 make("UITextSizeConstraint",{MinTextSize=12,MaxTextSize=20},title)
 local exit=make("TextButton",{Position=UDim2.new(1,-48,0,5),Size=UDim2.fromOffset(44,44),Text="×",TextSize=28,BackgroundColor3=Color3.fromRGB(110,65,96),TextColor3=Color3.new(1,1,1)},strip)
 local again=make("TextButton",{Visible=false,Position=UDim2.new(1,-96,0,5),Size=UDim2.fromOffset(44,44),Text="↻",TextSize=28,BackgroundColor3=Color3.fromRGB(110,65,96),TextColor3=Color3.new(1,1,1)},strip)
 local current,kind,revision,colour,station=nil,nil,0,0,nil
 local saved,voices,cursor=nil,{},0
 local labels={} local hiddenPrompts={} local hiddenBody={}
 local bindings={Enum.KeyCode.Z,Enum.KeyCode.S,Enum.KeyCode.X,Enum.KeyCode.D,Enum.KeyCode.C,Enum.KeyCode.V,Enum.KeyCode.G,Enum.KeyCode.B,Enum.KeyCode.H,Enum.KeyCode.N,Enum.KeyCode.J,Enum.KeyCode.M,Enum.KeyCode.Q,Enum.KeyCode.Two,Enum.KeyCode.W,Enum.KeyCode.Three,Enum.KeyCode.E,Enum.KeyCode.R,Enum.KeyCode.Six,Enum.KeyCode.T,Enum.KeyCode.Seven,Enum.KeyCode.Y,Enum.KeyCode.Eight,Enum.KeyCode.U}
 local keyNames={"Z","S","X","D","C","V","G","B","H","N","J","M","Q","2","W","3","E","R","6","T","7","Y","8","U"}
 local function clearLabels() for _,label in ipairs(labels) do label:Destroy() end table.clear(labels) end
 local function restore()
  for prompt,enabled in pairs(hiddenPrompts) do if prompt.Parent then prompt.Enabled=enabled end end table.clear(hiddenPrompts)
  for part,value in pairs(hiddenBody) do if part.Parent then part.LocalTransparencyModifier=value end end table.clear(hiddenBody)
  clearLabels() CAS:UnbindAction("CafePianoKeys") strip.Visible=false current=nil kind=nil station=nil
  local camera=workspace.CurrentCamera
  if saved and camera then camera.CameraType=saved.type camera.CameraSubject=saved.subject camera.FieldOfView=saved.fov camera.CFrame=saved.frame end saved=nil
 end
 local function close() restore() remote:FireServer("Leave") end
 exit.Activated:Connect(close) again.Activated:Connect(function() remote:FireServer("Again") end)
 local function open(id,nextKind)
  local map=workspace:FindFirstChild("RodeoCafe") local folder=map and map:FindFirstChild("Activities")
  local model=folder and folder:FindFirstChild(id) if not model or not model.PrimaryPart then return false end
  if current==id and kind==nextKind then return true end
  if onOpen then onOpen() end
  clearLabels() CAS:UnbindAction("CafePianoKeys")
  current,kind,station=id,nextKind,model strip.Visible=true
  for _,prompt in ipairs(folder:GetDescendants()) do if prompt:IsA("ProximityPrompt") then
   if hiddenPrompts[prompt]==nil then hiddenPrompts[prompt]=prompt.Enabled end prompt.Enabled=false
  end end
  if player.Character then for _,part in ipairs(player.Character:GetDescendants()) do if part:IsA("BasePart") then
   if hiddenBody[part]==nil then hiddenBody[part]=part.LocalTransparencyModifier end part.LocalTransparencyModifier=1
  end end end
  local camera=workspace.CurrentCamera
  if not saved then saved={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,frame=camera.CFrame} end
  camera.CameraType=Enum.CameraType.Scriptable camera.FieldOfView=50
  local centre=model.PrimaryPart.Position
  if nextKind=="Gomoku" then
   camera.CFrame=CFrame.lookAt(centre+Vector3.new(0,20,1),centre)
  else
   camera.CFrame=CFrame.lookAt(centre+Vector3.new(0,12,7),centre+Vector3.new(0,.5,4))
   local keyboard=model:FindFirstChild("Keyboard")
   if keyboard then for _,key in ipairs(keyboard:GetChildren()) do
    local note=key:GetAttribute("Note")
    if note then
     local label=make("SurfaceGui",{Adornee=key,Face=Enum.NormalId.Top,CanvasSize=Vector2.new(120,220),AlwaysOnTop=false},gui)
     make("TextLabel",{BackgroundTransparency=1,Size=UDim2.fromScale(1,.4),Position=UDim2.fromScale(0,.58),Text=keyNames[note],TextSize=40,Font=Enum.Font.GothamBold,TextColor3=key.Name=="BlackKey" and Color3.new(1,1,1) or Color3.fromRGB(45,38,43)},label)
     labels[#labels+1]=label
    end
   end end
  end
  return true
 end
 local function play(note,id)
  local map=workspace:FindFirstChild("RodeoCafe") local folder=map and map:FindFirstChild("Activities") local model=folder and folder:FindFirstChild(id)
  if not model or not model.PrimaryPart then return end
  cursor=cursor%8+1 local sound=voices[cursor]
  if not sound or not sound.Parent then sound=Instance.new("Sound") sound.Name="CafePianoNote" sound.RollOffMinDistance=10 sound.RollOffMaxDistance=90 voices[cursor]=sound end
  sound:Stop() sound.SoundId=notes.SoundId sound.PlaybackSpeed=2^((notes.Semitones[note] or 0)/12)
  sound.Volume=.28*Audio.getVolume("Effects") sound.Parent=model.PrimaryPart sound.TimePosition=0 sound:Play()
 end
 local function press(note)
  if kind~="Piano" or not current then return end
  remote:FireServer("Note",note) play(note,current)
 end
 UIS.InputEnded:Connect(function(input,processed)
  if processed or not station or UIS:GetFocusedTextBox() then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  local camera=workspace.CurrentCamera local ray=camera:ScreenPointToRay(input.Position.X,input.Position.Y)
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={station}
  local hit=workspace:Raycast(ray.Origin,ray.Direction*80,params) if not hit then return end
  if kind=="Piano" then local note=hit.Instance:GetAttribute("Note") if note then press(note) end
  elseif kind=="Gomoku" and hit.Instance==station.PrimaryPart and colour>0 then
   local point=station.PrimaryPart.CFrame:PointToObjectSpace(hit.Position)
   local x=math.round((point.X+4)*14/8)+1 local y=math.round((point.Z+4)*14/8)+1
   if x>=1 and x<=15 and y>=1 and y<=15 then remote:FireServer("Move",x,y,revision) end
  end
 end)
 remote.OnClientEvent:Connect(function(event,data)
  if event=="Close" then restore()
  elseif event=="Piano" and open(data.id,"Piano") then
   title.Text="♫" again.Visible=false
   CAS:BindActionAtPriority("CafePianoKeys",function(_,state,input)
    if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then for n,key in ipairs(bindings) do if input.KeyCode==key then press(n) break end end end
    return Enum.ContextActionResult.Sink
   end,false,Enum.ContextActionPriority.High.Value+10,table.unpack(bindings))
  elseif event=="Board" and open(data.id,"Gomoku") then
   revision=data.revision colour=data.colour or colour again.Visible=data.winner~=nil
   local turn=data.winner~=nil and (data.winner==0 and "＝" or data.winner==1 and "⚫ ✓" or "⚪ ✓") or data.turn==1 and "⚫ →" or "⚪ →"
   title.Text=(data.players[1] or "…").."   "..turn.."   "..(data.players[2] or "…")
  elseif event=="Note" and data.performer~=player.UserId then play(data.note,data.id) end
 end)
 player.CharacterAdded:Connect(close)
 return {close=close}
end
return U
