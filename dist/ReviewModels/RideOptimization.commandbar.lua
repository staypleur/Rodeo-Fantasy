assert(not game:GetService("RunService"):IsRunning(),"Stop Play")
local changes={}
do local n=assert(game.ServerScriptService:FindFirstChild("LobbyCompanions")) local before=[=[-- One owned companion per lobby player; riding remains server authoritative.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
local RideRules=require(P.LobbyRideRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.dismount(p)
  local pet=pets[p] local ride=pet and pet.ride
  if not ride then return end
  pet.ride=nil pet.input=Vector3.zero
  p:SetAttribute("LobbyRiding",nil) pet.model:SetAttribute("RiderUserId",nil)
  local r,h=ride.root,ride.humanoid
  if r.Parent and h.Parent then
   local frame=pet.model.PrimaryPart.CFrame
   for _,offset in ipairs({Vector3.new(5,0,0),Vector3.new(-5,0,0),Vector3.new(0,0,6)}) do
    local pos=frame:PointToWorldSpace(offset) local y=ground(pos)
    if y and not workspace:Blockcast(CFrame.new(frame.Position),Vector3.new(2,2,2),pos-frame.Position,params) then
     r.CFrame=CFrame.new(pos.X,y+h.HipHeight+r.Size.Y/2,pos.Z)*frame.Rotation break
    end
   end
   r.Anchored=ride.anchored h.AutoRotate=ride.autoRotate h.PlatformStand=ride.platformStand h.Sit=ride.sit
   r.AssemblyLinearVelocity=Vector3.zero
  end
 end
 function api.ride(p,id)
  local pet=pets[p] local r=root(p)
  if pet and pet.ride then api.dismount(p) return true end
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if not pet or pet.id~=id or not r or not h or h.Health<=0 or not context.canAct(p) or not context.inLobby(p)
   or not Rules.available(Rules.find(context.bag(p),id)) or (r.Position-pet.model.PrimaryPart.Position).Magnitude>10
   or (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then return false end
  pet.ride={root=r,humanoid=h,anchored=r.Anchored,autoRotate=h.AutoRotate,platformStand=h.PlatformStand,sit=h.Sit}
  pet.input=Vector3.zero pet.inputAt=os.clock()
  r.Anchored=true h.AutoRotate=false h.PlatformStand=true h.Sit=true
  pet.model:SetAttribute("RiderUserId",p.UserId) p:SetAttribute("LobbyRiding",true)
  return true
 end
 function api.input(p,value)
  local pet=pets[p] if not pet or not pet.ride then return end
  local direction=RideRules.direction(value) if not direction then return end
  pet.input=direction pet.inputAt=os.clock()
 end
 function api.bond(p,id)
  local pet=pets[p] local rr=root(p)
  if not pet or pet.ride or pet.id~=id or not context.canAct(p) or not context.inLobby(p)
   or not Rules.available(Rules.find(context.bag(p),id)) or not rr
   or (rr.Position-pet.model.PrimaryPart.Position).Magnitude>10 or os.clock()-(pet.lastBond or -math.huge)<3.5 then return false end
  pet.lastBond=os.clock()
  local at=workspace:GetServerTimeNow()
  pet.model:SetAttribute("PetBondStarted",at) pet.model:SetAttribute("PetBondUntil",at+3)
  P.CaptureRemote:FireAllClients("LobbyPet",{model=pet.model,at=at})
  return true
 end
 function api.clear(p)
  api.dismount(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","Summon your companion in the lobby.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  local revision=source and source:GetAttribute("MossratUserRigRevision")
  if revision~="ApprovedS1-v1" and revision~="UserS3-v1" and revision~="UserS6-v1" and revision~="UserS9-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false,blocked=0}
  p:SetAttribute("SummonedId",id)

 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if pet.ride then
    local ride=pet.ride
    if r~=ride.root or not ride.humanoid.Parent or ride.humanoid.Health<=0 then api.dismount(p) continue end
    local direction=context.canAct(p) and Rules.available(Rules.find(context.bag(p),pet.id)) and os.clock()-pet.inputAt<.5 and pet.input or Vector3.zero
    local old=pet.model.PrimaryPart.CFrame local delta=direction*RideRules.speed(pet.model:GetAttribute("Stars"))*step
    local position=old.Position+delta local y=ground(position)
    local frame=old local moving=delta.Magnitude>.01
    if moving then
     local hit=workspace:Blockcast(CFrame.new(old.X,old.Y+1,old.Z),Vector3.new(2.5,2.5,2.5),delta,params)
     if y and not hit and math.abs(y+pet.height-old.Y)<=3 then
      position=Vector3.new(position.X,y+pet.height,position.Z) frame=CFrame.lookAt(position,position+direction)
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     else moving=false end
    end
    local stage=Catalog.stage(pet.model:GetAttribute("Stars"))
    local body=pet.model:FindFirstChild("Body") local tall=body and body.Size.Y or pet.height*2
    local offset=stage>=6 and Vector3.new(0,tall*.62-pet.height,1.35) or Vector3.new(0,tall*.62-pet.height+1.25,.15)
    r.CFrame=frame*CFrame.new(offset) r.AssemblyLinearVelocity=Vector3.zero
    pet.model:SetAttribute("Running",moving) pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
    continue
   end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A pet stranded behind a wall must not be left outside the visible lobby.
   -- Recover only onto a collidable surface near its owner, never into the sky.
   if toOwner.Magnitude>70 or pet.blocked>=1.5 then
    for _,offset in ipairs({Vector3.new(4,0,4),Vector3.new(-4,0,4),Vector3.new(4,0,-4),Vector3.new(-4,0,-4)}) do
     local position=r.Position+offset
     local y=ground(position)
     if y and math.abs(y-r.Position.Y)<10 then
      local frame=CFrame.new(position.X,y+pet.height,position.Z)*old.Rotation
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
      pet.following=false pet.blocked=0 old=frame
      toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
      break
     end
    end
   end
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    -- Match the owner's pace; the lobby player walks at 40 studs/sec.
    local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
    local speed=humanoid and humanoid.WalkSpeed or 40
    delta=delta.Unit*math.min(delta.Magnitude-6,speed*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     pet.blocked=0
    else
     pet.blocked+=step
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]=] local after=[=[-- One owned companion per lobby player; riding remains server authoritative.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
local RideRules=require(P.LobbyRideRules)
function M.new(context)
 local pets={}
 local map=workspace:WaitForChild("RodeoLobby")
 local folder=Instance.new("Folder") folder.Name="LobbyCompanions" folder.Parent=map
 local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={map} params.RespectCanCollide=true
 local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
 local function ground(position)
  local hit=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-64,0),params)
  return hit and hit.Position.Y
 end
 local api={}
 function api.dismount(p)
  local pet=pets[p] local ride=pet and pet.ride
  if not ride then return end
  pet.ride=nil pet.input=Vector3.zero
  p:SetAttribute("LobbyRiding",nil) pet.model:SetAttribute("RiderUserId",nil)
  local r,h=ride.root,ride.humanoid
  if r.Parent and h.Parent then
   local frame=pet.model.PrimaryPart.CFrame
   for _,offset in ipairs({Vector3.new(5,0,0),Vector3.new(-5,0,0),Vector3.new(0,0,6)}) do
    local pos=frame:PointToWorldSpace(offset) local y=ground(pos)
    if y and not workspace:Blockcast(CFrame.new(frame.Position),Vector3.new(2,2,2),pos-frame.Position,params) then
     r.CFrame=CFrame.new(pos.X,y+h.HipHeight+r.Size.Y/2,pos.Z)*frame.Rotation break
    end
   end
   r.Anchored=ride.anchored h.AutoRotate=ride.autoRotate h.PlatformStand=ride.platformStand h.Sit=ride.sit
   r.AssemblyLinearVelocity=Vector3.zero
  end
 end
 function api.ride(p,id)
  local pet=pets[p] local r=root(p)
  if pet and pet.ride then api.dismount(p) return true end
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if not pet or pet.id~=id or not r or not h or h.Health<=0 or not context.canAct(p) or not context.inLobby(p)
   or not Rules.available(Rules.find(context.bag(p),id)) or (r.Position-pet.model.PrimaryPart.Position).Magnitude>10
   or (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then return false end
  pet.ride={root=r,humanoid=h,anchored=r.Anchored,autoRotate=h.AutoRotate,platformStand=h.PlatformStand,sit=h.Sit}
  pet.input=Vector3.zero pet.inputAt=os.clock()
  r.Anchored=true h.AutoRotate=false h.PlatformStand=false h.Sit=true
  h:ChangeState(Enum.HumanoidStateType.Seated)
  pet.model:SetAttribute("RiderUserId",p.UserId) p:SetAttribute("LobbyRiding",true)
  return true
 end
 function api.input(p,value)
  local pet=pets[p] if not pet or not pet.ride then return end
  local direction=RideRules.direction(value) if not direction then return end
  pet.input=direction pet.inputAt=os.clock()
 end
 function api.bond(p,id)
  local pet=pets[p] local rr=root(p)
  if not pet or pet.ride or pet.id~=id or not context.canAct(p) or not context.inLobby(p)
   or not Rules.available(Rules.find(context.bag(p),id)) or not rr
   or (rr.Position-pet.model.PrimaryPart.Position).Magnitude>10 or os.clock()-(pet.lastBond or -math.huge)<3.5 then return false end
  pet.lastBond=os.clock()
  local at=workspace:GetServerTimeNow()
  pet.model:SetAttribute("PetBondStarted",at) pet.model:SetAttribute("PetBondUntil",at+3)
  P.CaptureRemote:FireAllClients("LobbyPet",{model=pet.model,at=at})
  return true
 end
 function api.clear(p)
  api.dismount(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","Summon your companion in the lobby.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  local revision=source and source:GetAttribute("MossratUserRigRevision")
  if revision~="ApprovedS1-v1" and revision~="UserS3-v1" and revision~="UserS6-v1" and revision~="UserS9-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","This monster model is coming soon.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  model.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false,blocked=0}
  p:SetAttribute("SummonedId",id)

 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if pet.ride then
    local ride=pet.ride
    if r~=ride.root or not ride.humanoid.Parent or ride.humanoid.Health<=0 then api.dismount(p) continue end
    local direction=context.canAct(p) and Rules.available(Rules.find(context.bag(p),pet.id)) and os.clock()-pet.inputAt<.5 and pet.input or Vector3.zero
    local old=pet.model.PrimaryPart.CFrame local delta=direction*RideRules.speed(pet.model:GetAttribute("Stars"))*step
    local position=old.Position+delta
    local frame=old local moving=delta.Magnitude>.01
    if moving then
     local y=ground(position)
     local hit=workspace:Blockcast(CFrame.new(old.X,old.Y+1,old.Z),Vector3.new(2.5,2.5,2.5),delta,params)
     if y and not hit and math.abs(y+pet.height-old.Y)<=3 then
      position=Vector3.new(position.X,y+pet.height,position.Z) frame=CFrame.lookAt(position,position+direction)
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     else moving=false end
    end
    local stage=Catalog.stage(pet.model:GetAttribute("Stars"))
    local body=pet.model:FindFirstChild("Body") local tall=body and body.Size.Y or pet.height*2
    local offset=stage>=6 and Vector3.new(0,tall*.62-pet.height,1.35) or Vector3.new(0,tall*.62-pet.height+1.25,.15)
    local riderFrame=frame*CFrame.new(offset)
    if r.CFrame~=riderFrame then r.CFrame=riderFrame end
    if r.AssemblyLinearVelocity~=Vector3.zero then r.AssemblyLinearVelocity=Vector3.zero end
    pet.model:SetAttribute("Running",moving) pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
    continue
   end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A pet stranded behind a wall must not be left outside the visible lobby.
   -- Recover only onto a collidable surface near its owner, never into the sky.
   if toOwner.Magnitude>70 or pet.blocked>=1.5 then
    for _,offset in ipairs({Vector3.new(4,0,4),Vector3.new(-4,0,4),Vector3.new(4,0,-4),Vector3.new(-4,0,-4)}) do
     local position=r.Position+offset
     local y=ground(position)
     if y and math.abs(y-r.Position.Y)<10 then
      local frame=CFrame.new(position.X,y+pet.height,position.Z)*old.Rotation
      pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
      pet.following=false pet.blocked=0 old=frame
      toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
      break
     end
    end
   end
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    -- Match the owner's pace; the lobby player walks at 40 studs/sec.
    local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
    local speed=humanoid and humanoid.WalkSpeed or 40
    delta=delta.Unit*math.min(delta.Magnitude-6,speed*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
     pet.blocked=0
    else
     pet.blocked+=step
     moving=false
    end
   end
   pet.model:SetAttribute("Running",moving)
   pet.model:SetAttribute("HerdVelocity",moving and delta/step or Vector3.zero)
  end
 end)
 return api
end
return M
]=] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Source changed: LobbyCompanions") table.insert(changes,{n,after}) end
do local n=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("PetPromptUI")) local before=[=[-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent.HudIcons).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoLobby")
  local folder=map and map:FindFirstChild("LobbyCompanions")
  local pet=folder and folder:FindFirstChild("Companion_"..player.UserId)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if pet and root and pet.PrimaryPart and pet:GetAttribute("OwnerUserId")==player.UserId
   and (root.Position-pet.PrimaryPart.Position).Magnitude<=10 then return pet end
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  current=nearby() local mounted=player:GetAttribute("LobbyRiding")==true
  button.Visible=current~=nil and not mounted ride.Visible=current~=nil or mounted ring.Enabled=mounted
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 ride.Activated:Connect(function()
  local pet=nearby()
  if pet or player:GetAttribute("LobbyRiding") then package.CaptureRemote:FireServer("RidePet",pet and pet:GetAttribute("BagItemId")) end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView} end
   camera.CameraType=Enum.CameraType.Scriptable
   local pet=nearby() local part=pet and pet.PrimaryPart
   local frame=part and part.CFrame or root.CFrame
   local height=pet and pet:FindFirstChild("Body") and pet.Body.Size.Y or 4
   local target=root.Position+Vector3.new(0,1,0)
   camera.CFrame=CFrame.lookAt(target-frame.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),target)
   inputTime+=dt
   if inputTime>=.08 then inputTime=0 package.CaptureRemote:FireServer("RideInput",hum.MoveDirection) end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]=] local after=[=[-- Only this bounded image button can request bonding; no world-touch prompt.
local M={}
function M.new(gui,player)
 local package=game.ReplicatedStorage.RodeoFantasy
 local button=Instance.new("ImageButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,-38,1,-76) button.Size=UDim2.fromOffset(64,64)
 button.BackgroundTransparency=1 button.ScaleType=Enum.ScaleType.Fit
 button.Image=require(script.Parent.HudIcons).imageId(package,"BondButtonImage")
 button.ZIndex=10 button.Parent=gui
 local ride=button:Clone() ride.Name="PetRide" ride.Position=UDim2.new(.5,38,1,-76)
 ride.Image=require(script.Parent.HudIcons).imageId(package,"RideButtonImage") ride.Parent=gui
 local ring=Instance.new("UIStroke") ring.Color=Color3.fromRGB(255,217,88) ring.Thickness=3 ring.Enabled=false ring.Parent=ride
 local current local elapsed=0
 local function nearby()
  local map=workspace:FindFirstChild("RodeoLobby")
  local folder=map and map:FindFirstChild("LobbyCompanions")
  local pet=folder and folder:FindFirstChild("Companion_"..player.UserId)
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if pet and root and pet.PrimaryPart and pet:GetAttribute("OwnerUserId")==player.UserId
   and (root.Position-pet.PrimaryPart.Position).Magnitude<=10 then return pet end
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end elapsed=0
  current=nearby() local mounted=player:GetAttribute("LobbyRiding")==true
  button.Visible=current~=nil and not mounted ride.Visible=current~=nil or mounted ring.Enabled=mounted
 end)
 button.Activated:Connect(function()
  local pet=nearby()
  if pet and pet==current then package.CaptureRemote:FireServer("BondPet",pet:GetAttribute("BagItemId")) end
 end)
 ride.Activated:Connect(function()
  local pet=nearby()
  if pet or player:GetAttribute("LobbyRiding") then package.CaptureRemote:FireServer("RidePet",pet and pet:GetAttribute("BagItemId")) end
 end)
 local rs=game:GetService("RunService") local oldCamera local inputTime=0 local lastInput
 local stepName="LobbyRideCamera_"..player.UserId
 rs:BindToRenderStep(stepName,Enum.RenderPriority.Camera.Value+3,function(dt)
  local camera=workspace.CurrentCamera local mounted=player:GetAttribute("LobbyRiding")==true
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if mounted and root and hum then
   if not oldCamera then oldCamera={type=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView} end
   camera.CameraType=Enum.CameraType.Scriptable
   local pet=current and current.Parent and current local part=pet and pet.PrimaryPart
   local frame=part and part.CFrame or root.CFrame
   local height=pet and pet:FindFirstChild("Body") and pet.Body.Size.Y or 4
   local target=root.Position+Vector3.new(0,1,0)
   camera.CFrame=CFrame.lookAt(target-frame.LookVector*math.max(12,height*2)+Vector3.new(0,math.max(4,height*.6),0),target)
   inputTime+=dt
   local direction=hum.MoveDirection
   if inputTime>=.08 and (not lastInput or (direction-lastInput).Magnitude>.02 or inputTime>=.25) then
    inputTime=0 lastInput=direction package.CaptureRemote:FireServer("RideInput",direction)
   end
  elseif oldCamera then
   camera.CameraType=oldCamera.type camera.CameraSubject=hum or oldCamera.subject camera.FieldOfView=oldCamera.fov oldCamera=nil
   inputTime=0 lastInput=nil
  end
 end)
 gui.Destroying:Connect(function() connection:Disconnect() rs:UnbindFromRenderStep(stepName) current=nil end)
end
return M
]=] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Source changed: PetPromptUI") table.insert(changes,{n,after}) end
do local n=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("HuntEffects")) local before=[=[-- Local effects with a fixed object budget, independent of herd size.
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
 local rs=game:GetService("RunService") local debris=game:GetService("Debris")
 local body=model:FindFirstChild("Body") local height=body and body.Size.Y or 3
 local center=body or model.PrimaryPart
 local container=Instance.new("Folder") container.Name="LocalBondAura" container.Parent=center
 local glow=Instance.new("Attachment") glow.Name="PinkBondGlow" glow.Parent=center
 local mist=Instance.new("ParticleEmitter") mist.Texture="rbxasset://textures/particles/smoke_main.dds"
 mist.Color=ColorSequence.new(Color3.fromRGB(255,105,191),Color3.fromRGB(255,199,230))
 mist.LightEmission=.6 mist.Rate=8 mist.Speed=NumberRange.new(.1,.3) mist.SpreadAngle=Vector2.new(180,180)
 mist.Lifetime=NumberRange.new(.7,1.2) mist.Size=NumberSequence.new(height*.95)
 mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.87),NumberSequenceKeypoint.new(1,1)})
 mist.Parent=glow
 local hearts={}
 for i=1,10 do
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
  hearts[i]={gui=gui,shapes=shapes,angle=i*math.pi*2/10}
 end
 local started=os.clock() local connection
 connection=rs.RenderStepped:Connect(function()
  local t=os.clock()-started
  if t>=3 or not center.Parent then connection:Disconnect() container:Destroy() glow:Destroy() return end
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
]=] local after=[=[-- Local effects with a fixed object budget, independent of herd size.
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
]=] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Source changed: HuntEffects") table.insert(changes,{n,after}) end
do local n=assert(game.StarterPlayer.StarterPlayerScripts:FindFirstChild("UserMossratRigAnimator")) local before=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local dataS3=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS3"))
local dataS6=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS6"))
local dataS9=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS9"))
local function rigData(model)
 local revision=model:GetAttribute("MossratUserRigRevision")
 return revision=="UserS9-v1" and dataS9 or revision=="UserS6-v1" and dataS6 or revision=="UserS3-v1" and dataS3 or data
end
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local s3=rigData(model)~=data
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=not s3 and torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" and not s3 then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local data=rigData(model)
 local s9=data==dataS9
 local s6=data==dataS6 or s9
 local s3=data==dataS3 or s6
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=bondUntil>workspace:GetServerTimeNow()
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses={}
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v={}
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=not s3 and torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" and not s3 then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding and not s3 then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=workspace:GetServerTimeNow()-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-workspace:GetServerTimeNow())/.35,0,1))
    local pose=CFrame.identity
    if name=="Pelvis" then pose=CFrame.new(0,-.08*scale,0)*CFrame.Angles(math.rad(-32),0,0)
    elseif name=="Spine" then pose=CFrame.Angles(math.rad(-18),0,0)
    elseif name=="Chest" then pose=CFrame.Angles(math.rad(8),0,0)
    elseif name=="Neck" then pose=CFrame.Angles(math.rad(22),0,0)
    elseif name=="Head" then pose=CFrame.Angles(math.rad(20),math.sin(t*4)*.12,math.sin(t*4)*.20)
    elseif legLimb=="Rear" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(50),0,0)
    elseif legLimb=="Rear" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(-55),0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(-50),0,0)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(40),0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*(s6 and (legLimb=="Front" and .22 or .45) or .65),0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*(s6 and .28 or .65),0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   local tailIndex=tonumber(name:match("^Tail(%d+)$"))
   if tailIndex then
    frame=frame*CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035)
   end
   if bonding and data==dataS3 then
    local t=workspace:GetServerTimeNow()-(model:GetAttribute("PetBondStarted") or 0)
    local progress=math.clamp((t-.35)/1.7,0,1)
    if name=="Root" then
     local height=data.height*scale local lift=math.sin(progress*math.pi)*height*.65
     frame=CFrame.new(0,height*.5+lift,0)*CFrame.Angles(-math.pi*2*progress,0,0)*CFrame.new(0,-height*.5,0)
    elseif legLimb and progress>0 and progress<1 then
     frame=CFrame.Angles(math.sin(progress*math.pi)*(legLimb=="Front" and -.6 or .6),0,0)
    end
   elseif bonding and s9 then
    local t=workspace:GetServerTimeNow()-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.5,0,1),math.clamp((bondUntil-workspace:GetServerTimeNow())/.5,0,1))
    local pose=CFrame.identity
    if name=="Chest" then pose=CFrame.Angles(-.28,0,0)
    elseif name=="Head" then pose=CFrame.Angles(-.40,0,math.sin(t*8)*.025)
    elseif name=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(.15,0,(legSide=="Left" and 1 or -1)*.6)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-.5,0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif bonding and s6 then
    local t=workspace:GetServerTimeNow()-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.4,0,1),math.clamp((bondUntil-workspace:GetServerTimeNow())/.4,0,1))
    local sign=legSide=="Left" and 1 or -1
    local pose=CFrame.identity
    if legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(-.25,0,sign*1.35)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-1.5,0,0)
    elseif name=="Chest" then pose=CFrame.Angles(-.12,math.sin(t*2)*.12,0)
    elseif name=="Head" then pose=CFrame.Angles(-.1,math.sin(t*2)*.12,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]=] local after=[=[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local dataS3=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS3"))
local dataS6=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS6"))
local dataS9=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigDataS9"))
local function rigData(model)
 local revision=model:GetAttribute("MossratUserRigRevision")
 return revision=="UserS9-v1" and dataS9 or revision=="UserS6-v1" and dataS6 or revision=="UserS3-v1" and dataS3 or data
end
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local s3=rigData(model)~=data
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=not s3 and torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" and not s3 then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local data=rigData(model)
 local s9=data==dataS9
 local s6=data==dataS6 or s9
 local s3=data==dataS3 or s6
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},poses={},sample={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 local interval=moving and 1/30 or 1/15
 local camera=workspace.CurrentCamera
 if model:GetAttribute("OwnerUserId") and camera then
  local distance=(body.Position-camera.CFrame.Position).Magnitude
  if distance>150 then return end
  if distance>70 then interval=1/10 end
 end
 if c.mode and now-c.last<interval then return end c.last=now
 local serverNow=workspace:GetServerTimeNow()
 local bondUntil=model:GetAttribute("PetBondUntil") or 0
 local bonding=bondUntil>serverNow
 local mode=bonding and "Bond" or moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={} table.clear(c.poses)
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode=="Bond" and "Idle" or mode]
 local sample=((now-c.started)%clip.duration)*clip.fps
 local index=math.floor(sample)+1 local alpha=sample-math.floor(sample)
 local poses=c.poses
 local scale=(model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height)
 for _,ch in ipairs(clip.channels) do
  local a,b=ch.values[index],ch.values[index+1] local v=c.sample
  for i=1,#a do v[i]=a[i]*(1-alpha)+b[i]*alpha end
  local p=poses[ch.bone] or {} poses[ch.bone]=p
  if ch.path=="rotation" then p.rotation=rotation(v) else p.translation=Vector3.new(v[1],v[2],v[3])*scale end
 end
 local blend=math.clamp((now-c.blendStarted)/.18,0,1)
 for _,name in ipairs(data.bones) do
  local b=c.bones[name]
  if b then
   local p=poses[name] or {}
   local frame=CFrame.new(p.translation or Vector3.zero)*(p.rotation or CFrame.identity)
   -- Keep the face forward; retain body, legs, ears and tail motion.
   -- Center the original offset torso chain without changing the uploaded mesh/UVs.
   local centerX=not s3 and torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" and not s3 then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding and not s3 then
    -- Settle onto the rear paws, raise the front paws and gently tilt the face.
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.3,0,1),math.clamp((bondUntil-serverNow)/.35,0,1))
    local pose=CFrame.identity
    if name=="Pelvis" then pose=CFrame.new(0,-.08*scale,0)*CFrame.Angles(math.rad(-32),0,0)
    elseif name=="Spine" then pose=CFrame.Angles(math.rad(-18),0,0)
    elseif name=="Chest" then pose=CFrame.Angles(math.rad(8),0,0)
    elseif name=="Neck" then pose=CFrame.Angles(math.rad(22),0,0)
    elseif name=="Head" then pose=CFrame.Angles(math.rad(20),math.sin(t*4)*.12,math.sin(t*4)*.20)
    elseif legLimb=="Rear" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(50),0,0)
    elseif legLimb=="Rear" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(-55),0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(math.rad(-50),0,0)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(math.rad(40),0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*(s6 and (legLimb=="Front" and .22 or .45) or .65),0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*(s6 and .28 or .65),0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   local tailIndex=tonumber(name:match("^Tail(%d+)$"))
   if tailIndex then
    frame=frame*CFrame.Angles(0,math.sin(now*1.6-tailIndex*.45)*.12,math.sin(now*1.3-tailIndex*.3)*.035)
   end
   if bonding and data==dataS3 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local progress=math.clamp((t-.35)/1.7,0,1)
    if name=="Root" then
     local height=data.height*scale local lift=math.sin(progress*math.pi)*height*.65
     frame=CFrame.new(0,height*.5+lift,0)*CFrame.Angles(-math.pi*2*progress,0,0)*CFrame.new(0,-height*.5,0)
    elseif legLimb and progress>0 and progress<1 then
     frame=CFrame.Angles(math.sin(progress*math.pi)*(legLimb=="Front" and -.6 or .6),0,0)
    end
   elseif bonding and s9 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.5,0,1),math.clamp((bondUntil-serverNow)/.5,0,1))
    local pose=CFrame.identity
    if name=="Chest" then pose=CFrame.Angles(-.28,0,0)
    elseif name=="Head" then pose=CFrame.Angles(-.40,0,math.sin(t*8)*.025)
    elseif name=="Jaw" then pose=CFrame.Angles(.5,0,0)
    elseif legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(.15,0,(legSide=="Left" and 1 or -1)*.6)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-.5,0,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   elseif bonding and s6 then
    local t=serverNow-(model:GetAttribute("PetBondStarted") or 0)
    local ease=math.min(math.clamp(t/.4,0,1),math.clamp((bondUntil-serverNow)/.4,0,1))
    local sign=legSide=="Left" and 1 or -1
    local pose=CFrame.identity
    if legLimb=="Front" and name:find("Upper",1,true) then pose=CFrame.Angles(-.25,0,sign*1.35)
    elseif legLimb=="Front" and name:find("Lower",1,true) then pose=CFrame.Angles(-1.5,0,0)
    elseif name=="Chest" then pose=CFrame.Angles(-.12,math.sin(t*2)*.12,0)
    elseif name=="Head" then pose=CFrame.Angles(-.1,math.sin(t*2)*.12,0) end
    frame=frame*CFrame.identity:Lerp(pose,ease)
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]=] assert(n.Source:gsub("\r\n","\n")==before or n.Source:gsub("\r\n","\n")==after,"Source changed: UserMossratRigAnimator") table.insert(changes,{n,after}) end
local b=Instance.new("Folder") b.Name="RideOptimizationBackup_"..game:GetService("HttpService"):GenerateGUID(false) b.Parent=game.ServerStorage
game:GetService("ChangeHistoryService"):SetWaypoint("Before ride optimization")
for _,c in ipairs(changes) do c[1]:Clone().Parent=b c[1].Source=c[2] end
game:GetService("ChangeHistoryService"):SetWaypoint("Ride optimization") print("RIDE_OPTIMIZATION_INSTALLED",#changes)