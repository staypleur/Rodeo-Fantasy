-- REVIEW ONLY: not required by any game script. Own textures must be uploaded
-- after design approval; no external character textures or invented asset IDs.
local M={}
local profiles={
 [6]={Orbits=2,LeafRate=2,SparkRate=4,GlowRate=1,Lifetime=1.8,Radius=.30,Height=.42,Speed=.55,LeafSize=.055,GlowSize=.16},
 [9]={Orbits=4,LeafRate=3,SparkRate=9,GlowRate=2,Lifetime=2.2,Radius=.38,Height=.58,Speed=.75,LeafSize=.06,GlowSize=.22},
}
local colors={Leaf=Color3.fromRGB(155,222,77),Glow=Color3.fromRGB(123,230,128),Spark=Color3.fromRGB(255,220,128)}
function M.profile(stars) return stars>=9 and profiles[9] or stars>=6 and profiles[6] or nil end
function M.attach(model,textures,mobile)
 local stars=model:GetAttribute("Stars") or 1
 if model:GetAttribute("MonsterId")~="MeadowMouse" then return nil,"Only Mossrat" end
 local profile=M.profile(stars)
 if not profile then return nil,"No aura below six stars" end
 local body=model:FindFirstChild("Body",true)
 if not body or not body:IsA("BasePart") then return nil,"Body not ready" end
 for _,kind in ipairs({"Leaf","Glow","Spark"}) do
  if not textures or type(textures[kind])~="string" or textures[kind]=="" then return nil,"Approved texture required: "..kind end
 end
 local old=model:FindFirstChild("MossratAuraReview") if old then old:Destroy() end
 local marker=Instance.new("Folder") marker.Name="MossratAuraReview" marker.Parent=model
 -- Body/legs reference excludes the tall plant crown and trailing mane.
 local height=math.max(body.Size.Y*2,stars>=9 and 12.5 or 5.7)
 local attachments,emitters={},{}
 local state={time=0,dead=false}
 local function emitter(parent,kind,rate,ratio)
  local item=Instance.new("ParticleEmitter") item.Name=kind item.Texture=textures[kind]
  item.Color=ColorSequence.new(colors[kind]) item.LightEmission=.8 item.LightInfluence=.2
  item.Rate=rate*(mobile and .45 or 1) item.Lifetime=NumberRange.new(profile.Lifetime*.7,profile.Lifetime)
  item.Speed=NumberRange.new(height*.04,height*.09) item.EmissionDirection=Enum.NormalId.Top
  item.SpreadAngle=Vector2.new(30,30) item.LockedToPart=false item.VelocityInheritance=.25
  item.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,height*ratio*.4),NumberSequenceKeypoint.new(.3,height*ratio),NumberSequenceKeypoint.new(1,0)})
  item.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,kind=="Glow" and .80 or .22),NumberSequenceKeypoint.new(1,1)})
  item.Rotation=NumberRange.new(0,360) item.RotSpeed=NumberRange.new(-35,35)
  item.Parent=parent table.insert(emitters,item) return item
 end
 for index=1,profile.Orbits do
  local point=Instance.new("Attachment") point.Name="MossratAuraPoint" point.Parent=body
  table.insert(attachments,point)
  emitter(point,"Leaf",profile.LeafRate,profile.LeafSize)
  emitter(point,"Glow",profile.GlowRate,profile.GlowSize)
  emitter(point,"Spark",profile.SparkRate/profile.Orbits,.018)
 end
 function state:setEnabled(enabled)
  for _,item in ipairs(emitters) do item.Enabled=enabled end
 end
 function state:step(dt,visible)
  if self.dead then return end
  if not model.Parent or not body.Parent then self:destroy() return end
  self:setEnabled(visible)
  if not visible then return end
  self.time+=math.min(dt,.1)
  for index,point in ipairs(attachments) do
   local angle=self.time*profile.Speed+2*math.pi*(index-1)/profile.Orbits
   -- Keep the orbit behind the forward face; never spawn on the eyes/head.
   point.Position=Vector3.new(math.cos(angle)*height*profile.Radius,
    -body.Size.Y*.3+math.sin(angle*1.2)*height*.10,
    math.sin(angle)*math.max(body.Size.Z*.5,height*.2)+body.Size.Z*.15)
  end
 end
 function state:destroy()
  if self.dead then return end self.dead=true
  for _,point in ipairs(attachments) do point:Destroy() end marker:Destroy()
 end
 -- No private RenderStepped loop: the approved integration should select the
 -- nearest 2 mobile / 4 desktop auras within 90 studs and call step centrally.
 marker.Destroying:Connect(function()
  if not state.dead then
   state.dead=true
   for _,point in ipairs(attachments) do point:Destroy() end
  end
 end)
 state:step(0,true)
 return state
end
return M
