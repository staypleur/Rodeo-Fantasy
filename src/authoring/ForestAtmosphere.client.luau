-- Review-only local presentation. No server physics or Terrain edits.
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local map=workspace:WaitForChild("HuntStudBlockReview")
local water,leaves={},{}
for _,p in ipairs(map:GetChildren()) do
 if p:IsA("BasePart") then
  if p.Name=="Waterfall" or p.Name=="WaterFoam" or p.Name=="WaterStream" then
   table.insert(water,{part=p,color=p.Color,phase=p.Position.Z*.03+p.Position.Y*.08})
  elseif p.Name=="CanopyUpper" or p.Name=="CanopyMiddle" then
   -- Generated resting positions remain grid aligned; only visual canopy plates
   -- sway in Play. No trunks, ground, water collision, or gameplay is moved.
   table.insert(leaves,{part=p,rest=p.CFrame,phase=p.Position.Z*.013})
  end
 end
end
local oldLight={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient}
Lighting.ClockTime=15.2
Lighting.Brightness=2
Lighting.Ambient=Color3.fromRGB(108,116,92)
Lighting.OutdoorAmbient=Color3.fromRGB(135,143,112)
local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
local createdAtmosphere=atmosphere==nil
atmosphere=atmosphere or Instance.new("Atmosphere")
local oldAtmosphere={Density=atmosphere.Density,Haze=atmosphere.Haze,Glare=atmosphere.Glare,Color=atmosphere.Color,Decay=atmosphere.Decay}
if createdAtmosphere then atmosphere.Name="ForestReviewAtmosphere" end
atmosphere.Density=.22 atmosphere.Haze=1.1 atmosphere.Glare=.15
atmosphere.Color=Color3.fromRGB(238,226,185)
atmosphere.Decay=Color3.fromRGB(145,165,126) atmosphere.Parent=Lighting
local tint=Instance.new("ColorCorrectionEffect")
tint.Name="ForestReviewColor" tint.Contrast=.04 tint.Saturation=.08
tint.TintColor=Color3.fromRGB(255,250,231) tint.Parent=Lighting
local elapsed=0
local connection
connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.1 then return end
 elapsed=0
 if not map.Parent then
  connection:Disconnect() tint:Destroy()
  if createdAtmosphere then atmosphere:Destroy() else for key,value in pairs(oldAtmosphere) do atmosphere[key]=value end end
  for key,value in pairs(oldLight) do Lighting[key]=value end
  return
 end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local time=workspace:GetServerTimeNow()
 local eye=camera.CFrame.Position
 for _,entry in ipairs(leaves) do
  local p=entry.part
  if p.Parent then
   if (entry.rest.Position-eye).Magnitude<260 then
    p.CFrame=entry.rest*CFrame.Angles(0,0,math.sin(time*.7+entry.phase)*.012)
    entry.active=true
   elseif entry.active then p.CFrame=entry.rest entry.active=false end
  end
 end
 for _,entry in ipairs(water) do
  if entry.part.Parent and (entry.part.Position-eye).Magnitude<260 then
   local wave=(math.sin(time*2.3+entry.phase)+1)*.5
   entry.part.Color=entry.color:Lerp(Color3.fromRGB(208,239,230),wave*.16)
  end
 end
end)
