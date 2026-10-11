-- Edit-time migration. Preserve island geometry; translate clusters and rebuild bridges.
local M={Spacing=1.15}
local zones={Central={0,0,360},RosePalace={-1000,-1300,470},ShadowPalace={1000,-1300,470},RoseCafe={-1055,-450,270},ShadowCafe={1055,-450,270},Conservatory={-1150,180,240},ArcaneLounge={1150,180,240},RoseFountain={-650,460,180},ShadowFountain={650,460,180},RoseGiantGarden={-1450,1500,1020},ShadowGiantGarden={1450,1500,1020}}
local routes={{"Central","RoseCafe",280},{"Central","ShadowCafe",280},{"Central","RoseFountain",280},{"Central","ShadowFountain",280},{"RoseCafe","RosePalace",280},{"ShadowCafe","ShadowPalace",280},{"RoseCafe","Conservatory",220},{"ShadowCafe","ArcaneLounge",220},{"Conservatory","RoseGiantGarden",320},{"ArcaneLounge","ShadowGiantGarden",320},{"RoseFountain","RoseGiantGarden",320},{"ShadowFountain","ShadowGiantGarden",320}}
function M.apply(map)
 local previous=map:GetAttribute("IslandSpacing") or 1.4
 if previous==M.Spacing then return 0 end
 local moved=0
 for _,part in ipairs(map:GetDescendants()) do
  if not part:IsA("BasePart") or part.Name=="IslandBridge" or part.Name=="BridgeGuard" then continue end
  local position=part.Position
  local zone,score=nil,math.huge
  -- Background planets/vista islands are separate landmarks; scale their centre only.
  if part:IsDescendantOf(map.SpaceView) and part.Name~="CentralPlanet" and part.Name~="CentralPlanetOrbit" then
   local anchor
   if part.Name=="BackgroundPlanet" or part.Name=="BackgroundOrbit" then anchor=Vector3.new(position.X<0 and -1900 or 1900,0,-2250)
   else
    local candidates={{-420,-900},{430,-880},{0,-1350},{-220,1050},{240,950},{0,1950}}
    local best=math.huge
    for _,v in candidates do local d=(Vector3.new(v[1]*previous,position.Y,v[2]*previous)-position).Magnitude if d<best then best=d anchor=Vector3.new(v[1],0,v[2]) end end
   end
   part.CFrame+=anchor*(M.Spacing-previous) moved+=1
   continue
  end
  for name,v in pairs(zones) do
   local delta=Vector2.new(position.X-v[1]*previous,position.Z-v[2]*previous)
   local distance=delta.Magnitude/v[3]
   if distance<score then score,zone=distance,v end
  end
  if zone then part.CFrame+=Vector3.new(zone[1],0,zone[2])*(M.Spacing-previous) moved+=1 end
 end
 local layout=map.IslandLayout
 local bridges,guards={},{}
 for _,part in ipairs(layout:GetChildren()) do
  if part.Name=="IslandBridge" then bridges[#bridges+1]=part elseif part.Name=="BridgeGuard" then guards[#guards+1]=part end
 end
 assert(#bridges==#routes and #guards==#routes*2,"Unexpected bridge layout")
 for i,route in ipairs(routes) do
  local a,b=zones[route[1]],zones[route[2]]
  local start=Vector3.new(a[1]*M.Spacing,0,a[2]*M.Spacing)
  local finish=Vector3.new(b[1]*M.Spacing,0,b[2]*M.Spacing)
  local direction=(finish-start).Unit
  start+=direction*a[3]*.65 finish-=direction*b[3]*.65
  local span=(finish-start).Magnitude local centre=(start+finish)*.5
  local yaw=math.atan2(direction.X,direction.Z)
  bridges[i].CFrame=CFrame.new(centre+Vector3.new(0,-.1,0))*CFrame.Angles(0,yaw,0)
  bridges[i].Size=Vector3.new(route[3],1.2,span+40)
  for j,sign in ipairs({-1,1}) do
   local guard=guards[(i-1)*2+j]
   guard.CFrame=CFrame.new(centre+Vector3.new(direction.Z,0,-direction.X)*sign*(route[3]/2+2)+Vector3.new(0,7,0))*CFrame.Angles(0,yaw,0)
   guard.Size=Vector3.new(4,14,span)
  end
 end
 map:SetAttribute("IslandSpacing",M.Spacing)
 return moved
end
return M
