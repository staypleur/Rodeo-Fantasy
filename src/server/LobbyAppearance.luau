-- Lobby roof and owner labels; personal rooms deliberately remain open above.
local M={}
local function part(parent,name,size,cf,color,material)
 local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color p.Material=material
 p.Anchored=true p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Reflectance=0 p.Parent=parent return p
end
function M.ensure(lobby)
 local roof=lobby:FindFirstChild("Roof")
 if not roof then roof=Instance.new("Model") roof.Name="Roof" roof.Parent=lobby end
 if not roof:FindFirstChild("FullGlassCeiling") then
  local glass=part(roof,"FullGlassCeiling",Vector3.new(512,2,512),CFrame.new(6000,102,0),Color3.fromRGB(173,212,232),Enum.Material.SmoothPlastic)
  glass.Transparency=.94 glass.CastShadow=false
 end
 -- Glass suppresses transparent objects behind it. Preserve the optical glass panel
 -- using the transparent solid renderer, so exterior auras remain visible.
 roof.FullGlassCeiling.Material=Enum.Material.SmoothPlastic
 roof.FullGlassCeiling.Transparency=.94
 for _,room in ipairs(lobby.Plots:GetChildren()) do
  if not room:FindFirstChild("OwnerBoard") then
   local base=room.RoomBase
   local origin=CFrame.new(base.Position.X,base.Position.Y+base.Size.Y/2,base.Position.Z)*base.CFrame.Rotation
   local board=part(room,"OwnerBoard",Vector3.new(28,5,1),origin*CFrame.new(0,34,-39),Color3.fromRGB(18,30,49),Enum.Material.SmoothPlastic)
   board.CanCollide=false
   local gui=Instance.new("SurfaceGui") gui.Name="OwnerName" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(840,150) gui.Parent=board
   local label=Instance.new("TextLabel") label.Name="Text" label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
   label.Text="" label.TextSize=68 label.Font=Enum.Font.GothamBold label.TextColor3=Color3.fromRGB(163,227,255) label.Parent=gui
  end
 end
 local planet=lobby:FindFirstChild("CeilingPlanet")
 if planet and (not lobby:FindFirstChild("PlanetAura") or lobby.PlanetAura:GetAttribute("Revision")~=3) then
  if lobby:FindFirstChild("PlanetAura") then lobby.PlanetAura:Destroy() end
  local aura=Instance.new("Model") aura.Name="PlanetAura" aura.Parent=lobby
  aura:SetAttribute("Revision",3)
  local box=planet:GetBoundingBox()
  for i,size in ipairs({380,410,440}) do
   local glow=part(aura,"VioletHalo"..i,Vector3.one*size,CFrame.new(box.Position),Color3.fromRGB(151,58,255),Enum.Material.Neon)
   glow.Shape=Enum.PartType.Ball glow.Transparency=({.98,.992,.996})[i]
   glow.CanCollide=false glow.CanQuery=false glow.CastShadow=false
  end
  local outline=Instance.new("Highlight") outline.Name="PlanetVioletRim" outline.Adornee=planet
  outline.FillTransparency=1 outline.OutlineColor=Color3.fromRGB(205,118,255) outline.OutlineTransparency=.22
  outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Parent=aura
  local anchor=part(aura,"AuraParticles",Vector3.one,CFrame.new(box.Position),Color3.new(),Enum.Material.SmoothPlastic)
  anchor.Transparency=1 anchor.CanCollide=false anchor.CanQuery=false
  local emitter=Instance.new("ParticleEmitter") emitter.Name="VioletSparkles" emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
  emitter.Shape=Enum.ParticleEmitterShape.Sphere emitter.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
  anchor.Size=Vector3.one*390
  emitter.Color=ColorSequence.new(Color3.fromRGB(198,92,255)) emitter.LightEmission=1 emitter.Rate=12
  emitter.Lifetime=NumberRange.new(3,4) emitter.Speed=NumberRange.new(0)
  emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.3,8),NumberSequenceKeypoint.new(1,0)})
  local center=Instance.new("Attachment") center.Name="CoronaCenter" center.Parent=anchor
 local corona=Instance.new("ParticleEmitter") corona.Name="VioletCorona" corona.Parent=center
 corona.Texture="rbxasset://textures/particles/flare_main.dds" corona.Color=ColorSequence.new(Color3.fromRGB(169,65,255))
 corona.LightEmission=1 corona.Rate=.5 corona.Lifetime=NumberRange.new(4) corona.Speed=NumberRange.new(0)
 corona.Size=NumberSequence.new(440) corona.Transparency=NumberSequence.new(.93)
 emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.2),NumberSequenceKeypoint.new(1,1)}) emitter.Parent=anchor
 end
end
return M
