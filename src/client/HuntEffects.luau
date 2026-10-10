-- Local effects with a fixed object budget, independent of herd size.
local M={}
local UIS=game:GetService("UserInputService")
local config=require(game.ReplicatedStorage.RodeoFantasy.Config)
local anchor,emitter,wind,lines
local function prepare()
 if anchor then return end
 anchor=Instance.new("Part") anchor.Name="LocalHuntAtmosphere" anchor.Size=Vector3.one
 anchor.Anchored=true anchor.Transparency=1 anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Parent=workspace
 emitter=Instance.new("ParticleEmitter") emitter.Name="RunningDust"
 emitter.Texture="rbxasset://textures/particles/smoke_main.dds"
 emitter.Color=ColorSequence.new(Color3.fromRGB(204,186,138))
 emitter.Rate=UIS.TouchEnabled and 8 or 16 emitter.Lifetime=NumberRange.new(.25,.55)
 emitter.Speed=NumberRange.new(1,3) emitter.SpreadAngle=Vector2.new(30,30)
 emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,1.2)})
 emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.65),NumberSequenceKeypoint.new(1,1)})
 emitter.Enabled=false emitter.Parent=anchor
 wind=Instance.new("Sound") wind.Name="HuntWind" wind.SoundId=config.Audio.Wind wind.Looped=true wind.Volume=.08
 wind.Parent=game:GetService("SoundService")
 wind.SoundGroup=game:GetService("SoundService"):FindFirstChild("RodeoLocalEffects")
 lines={}
 for i=1,(UIS.TouchEnabled and 6 or 10) do
  local a,b=Instance.new("Attachment"),Instance.new("Attachment") a.Parent=anchor b.Parent=anchor
  local beam=Instance.new("Beam") beam.Attachment0=a beam.Attachment1=b beam.FaceCamera=true
  beam.Width0=.04 beam.Width1=.02 beam.Transparency=NumberSequence.new(.87)
  beam.Color=ColorSequence.new(Color3.fromRGB(220,245,228)) beam.Enabled=false beam.Parent=anchor
  lines[i]={a=a,b=b,beam=beam}
 end
end
function M.update(state,frame,clock)
 prepare()
 local effectsGroup=game:GetService("SoundService"):FindFirstChild("RodeoLocalEffects")
 if effectsGroup then wind.SoundGroup=effectsGroup end
 local active=state.area=="Hunt" and (state.phase=="Riding" or state.phase=="Airborne" or state.phase=="Lassoing") and frame~=nil
 emitter.Enabled=active and state.phase=="Riding" or false
 if active then
  anchor.CFrame=CFrame.new(frame.Position.X,math.max(.2,frame.Position.Y-3),frame.Position.Z)
  for i,line in ipairs(lines) do
   local offset=Vector3.new(math.sin(i*4.1)*12,2+(i%4)*3,((clock*22+i*7)%30)-15)
   line.a.Position=offset line.b.Position=offset+Vector3.new(0,.15,4)
  end
  if not wind.IsPlaying then wind:Play() end
 else
  if wind.IsPlaying then wind:Stop() end
  emitter:Clear()
 end
 for _,line in ipairs(lines) do line.beam.Enabled=active or false end
end
function M.pet(data)
 local model=type(data)=="table" and data.model
 if typeof(model)~="Instance" or not model:IsA("Model") or not model.PrimaryPart then return end
 local tween=game:GetService("TweenService")
 for i=1,8 do
  local angle=i*math.pi/4
  local gui=Instance.new("BillboardGui") gui.Name="LocalPetHeart" gui.Size=UDim2.fromOffset(38,38)
  gui.StudsOffsetWorldSpace=Vector3.new(math.cos(angle)*1.6,.4+(i%3)*.4,math.sin(angle)*1.6)
  gui.AlwaysOnTop=false gui.MaxDistance=100 gui.Parent=model.PrimaryPart
  local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
  label.Text="♥" label.TextColor3=Color3.fromRGB(255,130,190) label.TextSize=30 label.Parent=gui
  tween:Create(gui,TweenInfo.new(3),{StudsOffsetWorldSpace=gui.StudsOffsetWorldSpace+Vector3.new(0,2.2,0)}):Play()
  tween:Create(label,TweenInfo.new(3),{TextTransparency=1}):Play()
  game:GetService("Debris"):AddItem(gui,3)
 end
end
return M
