-- Empty Studio place only; design review, no game installation.
local Review=(function()
-- Standalone design review. Does not replace RodeoLobby or player inventories.
local Layout=(function()
-- Design-review layout. Contents/prices/rewards and hatching times are not invented.
local L={Capacity=8,IncubatorsPerPlayer=4,Radius=208}
function L.build()
 local blocks={}
 local navy={30,42,61} local hull={69,82,100} local cream={218,224,224}
 local teal={69,167,172} local dark={43,59,77} local gold={208,172,96}
 local function put(name,x,y,z,sx,sy,sz,color,yaw,group,text,collide)
  table.insert(blocks,{name=name,pos={x,y,z},size={sx,sy,sz},color=color,yaw=yaw or 0,group=group or "Hall",text=text,collide=collide~=false})
 end
 -- Joined tiles form a broad octagonal deck; no separate imitation Stud parts.
 for x=-6,6 do for z=-6,6 do
  if math.abs(x)+math.abs(z)<=9 then
   put("Deck",x*32,-4,z*32,32,8,32,(x+z)%2==0 and navy or dark)
  end
 end end
 local function radial(angle,r)
  return math.floor(math.sin(math.rad(angle))*r/4+.5)*4,math.floor(math.cos(math.rad(angle))*r/4+.5)*4
 end
 for slot=1,8 do
  local angle=(slot-1)*45
  local cx,cz=radial(angle,160)
  local group="Room_"..slot
  local function room(name,x,y,z,sx,sy,sz,color,text,collide)
   local a=math.rad(angle)
   local wx=cx+x*math.cos(a)+z*math.sin(a)
   local wz=cz-x*math.sin(a)+z*math.cos(a)
   -- Room rotations are multiples of 45 degrees; origin coordinates remain grid4.
   wx=math.floor(wx/4+.5)*4 wz=math.floor(wz/4+.5)*4
   put(name,wx,y,wz,sx,sy,sz,color,angle,group,text,collide)
  end
  room("RoomDeck",0,2,0,56,4,64,cream)
  room("BackWall",0,24,32,48,40,8,hull)
  room("SideWall",-28,24,0,8,40,56,hull)
  room("SideWall",28,24,0,8,40,56,hull)
  room("DoorFrame",-24,24,-32,16,40,8,cream)
  room("DoorFrame",24,24,-32,16,40,8,cream)
  room("DoorHeader",0,40,-32,32,8,8,teal,"INCUBATOR "..slot)
  room("DoorStep",0,0,-36,32,4,8,cream)
  room("DoorTrim",-16,18,-36,4,28,4,gold)
  room("DoorTrim",16,18,-36,4,28,4,gold)
  room("DoorLeft",-8,18,-32,16,28,4,teal)
  room("DoorRight",8,18,-32,16,28,4,teal)
  room("DoorSensor",0,8,-32,4,4,4,teal,nil,false)
  room("Ceiling",0,48,0,64,8,72,navy)
  room("ServicePanel",0,28,28,24,16,4,navy,"EGG BAY")
  room("ServiceStripe",0,28,24,16,4,4,teal)
  for index=1,4 do
   local x=index%2==1 and -12 or 12 local z=index<=2 and -8 or 16
   room("Incubator_"..index,x,6,z,16,4,16,navy)
   room("EggSocket_"..index,x,10,z,12,4,12,teal)
   room("IncubatorTrim",x,12,z+8,16,8,4,cream)
  end
  -- The enclosing rocket hull and overhead ribs keep the lobby indoors.
  local hx,hz=radial(angle,212)
  put("HullWall",hx,44,hz,176,88,8,hull,angle,"Hull")
  put("HullStripe",hx,64,hz,176,8,12,teal,angle,"Hull")
  put("HullTopTrim",hx,84,hz,176,8,16,cream,angle,"Hull")
  local rx,rz=radial(angle,120)
  put("OverheadRib",rx,76,rz,8,8,176,cream,angle,"Roof")
  local px,pz=radial(angle,100)
  put("WalkwayMarker",px,2,pz,16,4,16,teal,angle)
 end
 -- Segmented canopy is hidden only in the cutaway illustration.
 for x=-5,5 do for z=-5,5 do
  if math.abs(x)+math.abs(z)<=8 then put("Ceiling",x*32,92,z*32,32,8,32,navy,0,"Roof") end
 end end
 put("DockBase",0,2,0,64,4,64,hull,0,"Dock")
 put("DockTop",0,6,0,48,4,48,teal,0,"Dock")
 put("Departure",40,6,0,8,12,16,gold,90,"Dock","Green Star")
 -- User will provide the rocket model. Reserve the docking area only.
 put("RocketModelPending",0,12,0,32,8,8,cream,0,"Dock","ROCKET MODEL PENDING",false)
 -- Six stations fit between the inner ring and the eight doors.
 local stations={
  {name="Shop_1",angle=22.5,text="SHOP 01",color=teal},
  {name="Shop_2",angle=337.5,text="SHOP 02",color=teal},
  {name="DistanceRanking",angle=112.5,text="DISTANCE",color=gold},
  {name="JournalRanking",angle=247.5,text="COLLECTION",color=gold},
  {name="Roulette",angle=157.5,text="ROULETTE",color={194,112,91}},
  {name="BattlePass",angle=202.5,text="BATTLE PASS",color={128,137,188}},
 }
 for _,s in ipairs(stations) do
  local x,z=radial(s.angle,88)
  put("StationBase",x,4,z,24,8,16,hull,s.angle,s.name)
  put("StationCounter",x,10,z,32,4,20,s.color,s.angle,s.name)
  put("StationBoard",x,24,z+4,24,24,4,cream,s.angle,s.name,s.text)
  if s.name=="Shop_1" or s.name=="Shop_2" then
   local a=math.rad(s.angle)
   for _,side in ipairs({-1,1}) do
    local px=math.floor((x+side*16*math.cos(a))/4+.5)*4
    local pz=math.floor((z-side*16*math.sin(a))/4+.5)*4
    put("ShopPillar",px,24,pz,4,36,4,hull,s.angle,s.name)
   end
   put("ShopCanopy",x,44,z,40,4,24,s.color,s.angle,s.name)
   put("ShopCanopyTop",x,48,z,32,4,16,cream,s.angle,s.name)
  end
 end
 return blocks
end
return L

end)()
local Review={}
function Review.create(parent,backup,origin)
 origin=origin or Vector3.new(0,8,0)
 local model=Instance.new("Model") model.Name="SpaceLobbyReview"
 model:SetAttribute("SpaceLobbyReview",true)
 model:SetAttribute("LobbyCapacity",8) model:SetAttribute("CafeCapacity",20)
 model:SetAttribute("CompanionsPerPlayer",1) model:SetAttribute("LobbyRiding",false)
 local groups={}
 local ok,err=pcall(function()
  for _,b in ipairs(Layout.build()) do
   local group=groups[b.group]
   if not group then group=Instance.new("Model") group.Name=b.group group.Parent=model groups[b.group]=group end
   local p=Instance.new("Part") p.Name=b.name p.Shape=Enum.PartType.Block
   p.Size=Vector3.new(table.unpack(b.size))
   p.CFrame=CFrame.new(origin+Vector3.new(table.unpack(b.pos)))*CFrame.Angles(0,math.rad(b.yaw),0)
   p.Color=Color3.fromRGB(table.unpack(b.color)) p.Material=Enum.Material.Plastic
   p.TopSurface=Enum.SurfaceType.Studs p.BottomSurface=Enum.SurfaceType.Inlet
   for _,face in ipairs({"FrontSurface","BackSurface","LeftSurface","RightSurface"}) do p[face]=Enum.SurfaceType.Studs end
   p.Anchored=true p.CanCollide=b.collide p.CanTouch=false p.Parent=group
   if b.name=="DoorSensor" then p.Transparency=1 end
   if b.text then
    local gui=Instance.new("SurfaceGui") gui.Face=Enum.NormalId.Front gui.PixelsPerStud=25 gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud gui.Parent=p
    local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
    label.Text=b.text label.TextScaled=true label.Font=Enum.Font.GothamBold label.TextColor3=Color3.fromRGB(28,44,60) label.Parent=gui
   end
  end
 end)
 if not ok then model:Destroy() error(err,0) end
 -- Only earlier review models are archived; real lobby/airship are preserved.
 for _,old in ipairs(parent:GetChildren()) do
  if old.Name==model.Name and old:GetAttribute("SpaceLobbyReview")==true then old.Parent=backup end
 end
 model.Parent=parent
 return model
end
return Review

end)()
game:GetService("ChangeHistoryService"):SetWaypoint("Before spaceship lobby review")
local model=Review.create(workspace,game:GetService("ServerStorage"),Vector3.new(0,8,0))
local doors=Instance.new("Script") doors.Name="ReviewAutomaticDoors" doors.Source=[==[-- Review doors only. Egg inventory permissions remain server-owned game logic.
local model=script.Parent
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local doors={}
for slot=1,8 do
 local room=model:FindFirstChild("Room_"..slot)
 local left,right,sensor=room.DoorLeft,room.DoorRight,room.DoorSensor
 table.insert(doors,{left=left,right=right,sensor=sensor,lc=left.CFrame,rc=right.CFrame,open=false,tweens={}})
end
local elapsed=0
local connection
connection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.2 then return end elapsed=0
 local roots={}
 for _,player in ipairs(Players:GetPlayers()) do
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if root and h and h.Health>0 then table.insert(roots,root.Position) end
 end
 for _,door in ipairs(doors) do
  local near=false
  for _,pos in ipairs(roots) do
   if (pos-door.sensor.Position).Magnitude<=(door.open and 20 or 16) then near=true break end
  end
  if near~=door.open then
   door.open=near
   for _,t in ipairs(door.tweens) do t:Cancel() end door.tweens={}
   -- Decorative review leaves do not collide during movement or closure.
   door.left.CanCollide=false door.right.CanCollide=false
   for _,item in ipairs({{door.left,door.lc, -16},{door.right,door.rc,16}}) do
    local t=Tween:Create(item[1],TweenInfo.new(.35),{CFrame=item[2]*CFrame.new(near and item[3] or 0,0,0)})
    table.insert(door.tweens,t) t:Play()
   end
  end
 end
end)
model.Destroying:Connect(function()
 connection:Disconnect()
 for _,d in ipairs(doors) do for _,t in ipairs(d.tweens) do t:Cancel() end end
end)
]==] doors.Parent=model
local spawn=Instance.new("SpawnLocation") spawn.Name="ReviewSpawn" spawn.Size=Vector3.new(8,1,8) spawn.CFrame=CFrame.new(0,9,-52) spawn.Anchored=true spawn.CanCollide=false spawn.Transparency=1 spawn.Neutral=true spawn.Duration=0 spawn.Parent=model
game:GetService("Selection"):Set({model.Dock.DockTop})
game:GetService("ChangeHistoryService"):SetWaypoint("After spaceship lobby review")
print("SPACE_LOBBY_REVIEW_CREATED", "8 rooms / 32 egg slots; rocket model pending; game inventory not connected")
