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
local activeBonds=setmetatable({},{__mode="k"}) local activeBondCount=0
function M.pet(data)
 local model=type(data)=="table" and data.model
 if typeof(model)~="Instance" or not model:IsA("Model") or not model.PrimaryPart then return end
 local camera=workspace.CurrentCamera
 if not camera or (model.PrimaryPart.Position-camera.CFrame.Position).Magnitude>80 or activeBonds[model] or activeBondCount>=4 then return end
 activeBonds[model]=true activeBondCount+=1
 local rs=game:GetService("RunService") local debris=game:GetService("Debris")
 local body=model:FindFirstChild("Body") local height=body and body.Size.Y or 3
 local center=body or model.PrimaryPart
 local container=Instance.new("Folder") container.Name="LocalBondAura" container.Parent=center
 local glow=Instance.new("Attachment") glow.Name="PinkBondGlow" glow.Parent=center
 local mist=Instance.new("ParticleEmitter") mist.Texture="rbxasset://textures/particles/smoke_main.dds"
 mist.Color=ColorSequence.new(Color3.fromRGB(255,105,191),Color3.fromRGB(255,199,230))
 mist.LightEmission=.6 mist.Rate=UIS.TouchEnabled and 6 or 8 mist.Speed=NumberRange.new(.1,.3) mist.SpreadAngle=Vector2.new(180,180)
 mist.Lifetime=NumberRange.new(.7,1.2) mist.Size=NumberSequence.new(height*.95)
 mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.72),NumberSequenceKeypoint.new(1,1)})
 mist.Parent=glow
 local hearts={}
 local heartCount=UIS.TouchEnabled and 6 or 10
 for i=1,heartCount do
  local gui=Instance.new("BillboardGui") gui.Name="BondHeartAura" gui.Size=UDim2.fromOffset(22,22)
  gui.Adornee=center gui.AlwaysOnTop=false gui.MaxDistance=80 gui.Parent=container
  local shapes={}
  local function shape(x,y,w,h,round,angle)
   local f=Instance.new("Frame") f.BackgroundColor3=Color3.fromRGB(255,145,202) f.BorderSizePixel=0
   f.Position=UDim2.fromScale(x,y) f.Size=UDim2.fromScale(w,h) f.Rotation=angle or 0 f.Parent=gui
   if round then local c=Instance.new("UICorner") c.CornerRadius=UDim.new(.5,0) c.Parent=f end
   table.insert(shapes,f)
  end
  shape(.25,.30,.5,.5,false,45) shape(.08,.12,.5,.5,true) shape(.42,.12,.5,.5,true)
  hearts[i]={gui=gui,shapes=shapes,angle=i*math.pi*2/heartCount}
 end
 local started=os.clock() local connection local lastFrame=0
 connection=rs.RenderStepped:Connect(function()
  local t=os.clock()-started
  if t>=3 or not center.Parent then
   connection:Disconnect() container:Destroy() glow:Destroy() activeBonds[model]=nil activeBondCount-=1 return
  end
  if t-lastFrame<1/30 then return end lastFrame=t
  mist.Enabled=t<2.1
  for i,h in ipairs(hearts) do
   local angle=h.angle+t*.45 local pulse=.5+.5*math.sin(t*3+i)
   h.gui.StudsOffsetWorldSpace=Vector3.new(math.cos(angle)*height*.65,math.sin(i*2.3)*height*.33+math.sin(t*2+i)*.15,math.sin(angle)*height*.65)
   for _,f in ipairs(h.shapes) do f.BackgroundTransparency=math.max(.12+(.18*pulse),1-math.min(t/.25,(3-t)/.5,1)) end
  end
 end)
 debris:AddItem(container,3.2) debris:AddItem(glow,3.2)
end
return M
