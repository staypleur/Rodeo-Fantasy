do
assert(not game:GetService("RunService"):IsRunning(),"Play 중지")
local package=game.ReplicatedStorage.RodeoFantasy
local changes={
{name="CaptureServer",parent=game.ServerScriptService,kind="Script",before=[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canSummon(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0)
 local wildIds={}
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 model:SetAttribute("StartingOwnedMount",true)
 model:SetAttribute("Tamed_"..player.UserId,true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}})
  elseif not states[player] then remote:FireClient(player,"SocialMessage","알 배치는 내 부화실 안에서 이용해주세요.") end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if (not state or state.phase=="GameOver" or state.phase=="CourseEnd") and not player:GetAttribute("ReturningLobby") then
   player:SetAttribute("ReturningLobby",true)
   restoreAvatar(state)
   states[player]=nil
   if worldRoots[player] then worldRoots[player]:Destroy() end
   worlds[player],worldRoots[player]=nil,nil
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not humanoid or humanoid.Health<=0 or (state and (state.phase=="GameOver" or state.phase=="CourseEnd")) then
    local ok,err=pcall(function() player:LoadCharacterAsync() end)
    if not ok then states[player]=state player:SetAttribute("ReturningLobby",nil) warn("LOBBY_RESPAWN_FAILED: "..tostring(err)) send(player,"다시 로비로 돌아가기를 눌러 주세요.") return end
    character=player.Character
   end
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then root.Anchored=false root.AssemblyLinearVelocity=Vector3.zero character:PivotTo(Lobby.Spawn) end
   humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.PlatformStand=false humanoid.AutoRotate=true end
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(character)
   player:SetAttribute("ReturningLobby",nil)
   send(player,"로비로 돌아왔습니다.") sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or clock
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if not state.tamed and clock-state.started>=Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
    state.angerAt=state.angerAt or clock
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 for index=1,4 do Lobby.display(player,index,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========],after=[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local PhysicsService=game:GetService("PhysicsService")
local package=RS:WaitForChild("RodeoFantasy")
local Config=require(package.Config)
local Catalog=require(package.MonsterCatalog)
local Rules=require(package.HuntRules)
local BagRules=require(package.BagRules)
local World=require(script.Parent.HuntWorld)
local Lobby=require(script.Parent.LobbyWorld)
local Records=require(script.Parent.RecordService)
local Progress=require(script.Parent.ProgressService)
local Course=require(package.CourseGeometry)
local Store=require(script.Parent.InventoryStore)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local SocialRules=require(package.SocialRules)
local remote=package.CaptureRemote
local tuning=Config.Prototype
-- ROCKET_DEPARTURE_V1
local rocketLaunchPermit={}
local startingMounts={}
local function rocketModelReady(id,stars)
 local name=Catalog.template(id,stars)
 local model=game:GetService("ServerStorage"):FindFirstChild(name)
 return model and model:IsA("Model") and model.PrimaryPart~=nil and model:GetAttribute("UserApprovedHuntModel")==true
end
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
local companions=require(script.Parent.LobbyCompanions).new({
 bag=function(p) return bags[p] end,
 inLobby=function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,
 canAct=function(p) return bags[p] and not states[p] and not Store.busy(p) and not Social.trading(p) and not p:GetAttribute("Travelling") end,
 canSummon=function(p) return Lobby.canSummon(p) end,
})
local runs=Instance.new("Folder") runs.Name="PrivateHunts" runs.Parent=game:GetService("Workspace")
local lastSync,lastCleanup,lastHerd=0,0,0
local huntGroups={}
for index=1,8 do
 local name="RodeoHunt"..index
 pcall(function() PhysicsService:RegisterCollisionGroup(name) end)
 PhysicsService:CollisionGroupSetCollidable(name,name,true)
 PhysicsService:CollisionGroupSetCollidable(name,"Default",true)
 huntGroups[index]=name
end
for a=1,8 do for b=1,8 do if a~=b then PhysicsService:CollisionGroupSetCollidable(huntGroups[a],huntGroups[b],false) end end end
local function setCharacterGroup(player,groupName)
 local character=player.Character
 if not character then return end
 for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup=groupName end end
end
local function isolateRoot(folder,groupName)
 local function assign(instance) if instance:IsA("BasePart") then instance.CollisionGroup=groupName end end
 for _,instance in ipairs(folder:GetDescendants()) do assign(instance) end
 folder.DescendantAdded:Connect(assign)
end

for _,name in ipairs({"PreviewMonster","PreviewGround"}) do local preview=workspace.RodeoPrototype:FindFirstChild(name) if preview then preview:Destroy() end end
local function now() return workspace:GetServerTimeNow() end
local function baseSpeed(state)
 return state and state.monster and state.monster:GetAttribute("RideSpeed") or tuning.ForwardStudsPerSecond
end
local function send(player,message)
 local state,bag=states[player],bags[player]
 if not bag or Store.busy(player) or player:GetAttribute("Travelling") then return end
 local gains=BagRules.accrue(bag,now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
 Records.sample(player,bag.totalProduced or 0,state and state.distance or 0,"GreenStar")
 local wildIds={}
 if state and worlds[player] then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{summonedId=player:GetAttribute("SummonedId"),huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
end
local function sendBag(player)
 local bag=bags[player]
 if not bag or states[player] then return end
 local items={}
 for _,item in ipairs(bag.monsters) do
  table.insert(items,{id=item.id,breedingTeam=item.breedingTeam,assignedPen=item.assignedPen,monsterId=item.monsterId,stars=item.stars,sex=item.sex,incomeSeconds=item.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=BagRules.income(item,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(player,"Bag",items)
end
local function clearRope(state)
 for _,item in ipairs(state.rope or {}) do item:Destroy() end
 state.rope=nil
end
local function attachRope(state)
 local from,to=Instance.new("Attachment"),Instance.new("Attachment")
 from.Parent,to.Parent=state.root,state.monster.PrimaryPart
 local rope=Instance.new("Beam")
 rope.Name="CaptureRope"
 rope.Attachment0,rope.Attachment1=from,to
 rope.Width0,rope.Width1,rope.FaceCamera=0.1,0.1,true
 rope.Color,rope.Parent=ColorSequence.new(Color3.fromRGB(230,181,72)),state.root
 state.rope={from,to,rope}
end
local function freeMount(state)
 if state.monster and state.monster.Parent then
  state.monster:SetAttribute("Occupied",false)
  state.monster:SetAttribute("Running",true)
  state.monster:SetAttribute("Steering",0)
  state.monster:SetAttribute("Angry",false)
  state.monster:SetAttribute("DashUntil",nil)
  state.monster:SetAttribute("AngerWarning",false)
  state.monster:SetAttribute("AngerStarted",nil)
  local p=state.monster.PrimaryPart.Position
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
 end
 state.previousMonster,state.monster=state.monster,nil
 clearRope(state)
end
local function restoreAvatar(state)
 if not state then return end
 for part,alpha in pairs(state.hiddenParts or {}) do
  if part.Parent then part.Transparency=alpha part:SetAttribute("CrashAlpha",nil) end
 end
 for gui,enabled in pairs(state.hiddenLabels or {}) do if gui.Parent then gui.Enabled=enabled gui:SetAttribute("CrashEnabled",nil) end end
 state.hiddenParts=nil state.hiddenLabels=nil
end
local function finish(player,reason,crashKind)
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 state.crash=crashKind~=nil
 state.endReason=crashKind
 local brokenMount=(crashKind=="Wall" or crashKind=="Obstacle") and state.monster
 if brokenMount and brokenMount.Parent then state.monsterCrashFrame=brokenMount.PrimaryPart.CFrame state.monsterCrashId=brokenMount:GetAttribute("MonsterId") end
 freeMount(state)
 if brokenMount and brokenMount.Parent then brokenMount:Destroy() end
 state.phase="GameOver"
 if state.crash and state.root.Parent then
  state.hiddenParts={} state.hiddenLabels={}
  for _,part in ipairs(state.root.Parent:GetDescendants()) do
   if part:IsA("BasePart") then state.hiddenParts[part]=part.Transparency part:SetAttribute("CrashAlpha",part.Transparency) part.Transparency=1
   elseif part:IsA("BillboardGui") then state.hiddenLabels[part]=part.Enabled part:SetAttribute("CrashEnabled",part.Enabled) part.Enabled=false end
  end
 end
 if state.root.Parent then
  state.root.Anchored=state.wasAnchored
  state.root.AssemblyLinearVelocity=Vector3.zero
  state.humanoid.AutoRotate,state.humanoid.PlatformStand=state.autoRotate,state.platformStand
 end
 send(player,reason)
end
local function huntTemplate()
 local storage=game:GetService("ServerStorage")
 local existing=storage:FindFirstChild("RodeoMonsterTemplate")
 if existing then return existing end
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터 모스랫 템플릿이 없습니다. 모델 복구 코드를 적용하세요.")
 approved.Archivable=true
 local restored=assert(approved:Clone(),"모스랫 템플릿 복제 실패")
 restored.Name="RodeoMonsterTemplate" restored.Parent=storage
 warn("HUNT_TEMPLATE_RESTORED: approved Mossrat hunt model")
 return restored
end
local function start(player)
 local previous=states[player]
 if previous and previous.phase~="GameOver" and previous.phase~="CourseEnd" then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if not previous and not rocketLaunchPermit[player] then return end
 local picked,reason=require(package.DepartureSelectionRules).validate(bags[player],"GreenStar",startingMounts[player],Catalog,rocketModelReady)
 if not picked or workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")~=true then
  send(player,"새 사냥터와 선택한 몬스터를 연결할 준비 중입니다.") return
 end
 if not previous and not Lobby.canDepart(player) then send(player,"Approach the airship to start.") return end
 local rootFolder=Instance.new("Folder") rootFolder.Name=tostring(player.UserId) rootFolder:SetAttribute("OwnerUserId",player.UserId)
 local slot=player:GetAttribute("LobbySlot")
 local collisionGroup=huntGroups[slot]
 local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=rootFolder
 rootFolder.Parent=runs
 if collisionGroup then isolateRoot(rootFolder,collisionGroup) end
 local nextWorld=World.new()
 local ok,model=pcall(function()
  nextWorld.init(rootFolder,huntTemplate(),Config,Rules)
  nextWorld.ensure(0) nextWorld.replenish(0,views[player] or 1,nil,true,40)
  return nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)
 end)
 if not ok then
  rootFolder:Destroy()
  warn("HUNT_START_FAILED: "..tostring(model))
  send(player,"사냥터를 준비하지 못했습니다. 다시 시도해 주세요.")
  return
 end
 if previous then
  restoreAvatar(previous)
  freeMount(previous)
  if previous.phase=="CourseEnd" and previous.root==root then
   root.Anchored=previous.wasAnchored
   humanoid.AutoRotate,humanoid.PlatformStand=previous.autoRotate,previous.platformStand
  end
 end
 if worldRoots[player] then worldRoots[player]:Destroy() end
 if collisionGroup then setCharacterGroup(player,collisionGroup) end
 worlds[player]=nextWorld worldRoots[player]=rootFolder
 model:SetAttribute("Occupied",true)
 model:SetAttribute("Angry",false) model:SetAttribute("InitialLanding",true)
 model:SetAttribute("StartingOwnedMount",true)
 model:SetAttribute("Tamed_"..player.UserId,true)
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=true}
 companions.clear(player)
 root.Anchored,humanoid.AutoRotate,humanoid.PlatformStand=true,false,true
 root.CFrame=model:GetPivot()*CFrame.new(0,model:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,8)
 states[player].origin=root.CFrame
 attachRope(states[player])
 send(player)
end
local function launch(player,state)
 freeMount(state)
 worlds[player].releaseMount(state.previousMonster,player)
 state.phase,state.started="Airborne",now()
 state.launchY=state.root.Position.Y
 state.steer,state.dashUntil=0,nil
 state.tamed,state.angerAt=false,nil
 send(player)
end
local function lasso(player,state)
 local World=worlds[player]
 local model=World.nearest(state.root.Position,state.previousMonster,World.visibleSet(state.root.Position.Z,views[player],player))
 if not model then return end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded={state.root.Parent,worldRoots[player].Monsters}
 for other,folder in pairs(worldRoots) do if other~=player then table.insert(excluded,folder) end end
 params.FilterDescendantsInstances=excluded
 if workspace:Raycast(state.root.Position,model.PrimaryPart.Position-state.root.Position,params) then return end
 model:SetAttribute("Occupied",true)
 state.monster,state.phase,state.started=model,"Lassoing",now()
 state.origin=state.root.CFrame
 state.landingSeconds=tuning.JumpSeconds
 state.pendingDash=true
 attachRope(state)
 send(player)
end
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag,companions.clear)
local departure=require(script.Parent.RocketDepartureService).new({
 catalog=Catalog,now=now,token=function() return game:GetService("HttpService"):GenerateGUID(false) end,
 bag=function(p) return bags[p] end,
 canOpen=function(p)
  local humanoid=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return bags[p] and not states[p] and humanoid and humanoid.Health>0 and not Store.busy(p) and not Social.trading(p)
   and not p:GetAttribute("Travelling") and Lobby.canDepart(p)
 end,
 modelReady=rocketModelReady,
 courseReady=function() return workspace.RodeoLobby:GetAttribute("GreenStarRuntimeReady")==true end,
 send=function(p,action,value) remote:FireClient(p,action,value) end,
 launch=function(p,id)
  local before,old=states[p],startingMounts[p]
  startingMounts[p]=id rocketLaunchPermit[p]=true
  local ok,err=pcall(start,p)
  rocketLaunchPermit[p]=nil
  local launched=ok and states[p]~=before and states[p]~=nil
  if not launched then startingMounts[p]=old if not ok then warn("ROCKET_LAUNCH_FAILED: "..tostring(err)) end end
  return launched
 end,
})
Lobby.connect(function(p) departure.open(p) end)
remote.OnServerEvent:Connect(function(p,action,value)
 if action=="LaunchSelection" then departure.submit(p,value)
 elseif action=="CancelDeparture" then departure.cancel(p) end
end)
Players.PlayerRemoving:Connect(function(p) departure.remove(p) rocketLaunchPermit[p]=nil startingMounts[p]=nil companions.clear(p) end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" and action~="Summon" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="Summon" then
  if not states[player] then companions.summon(player,value) send(player) end
  return
 end
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}})
  elseif not states[player] then remote:FireClient(player,"SocialMessage","알 배치는 내 부화실 안에서 이용해주세요.") end
  return
 end
 if action=="Place" or action=="Remove" then return end -- Monster pens were replaced by egg incubators.
 if action=="PlaceEgg" or action=="RemoveEgg" then
  if states[player] or type(value)~="table" or not Lobby.canUsePen(player,value.pen) then return end
  if SocialRules.egg(bags[player],value.id,value.pen,action=="RemoveEgg") then
   Lobby.display(player,value.pen,bags[player].eggs)
   remote:FireClient(player,"Eggs",{pen=value.pen,eggs=bags[player].eggs})
  end return
 end
 if action=="Evolve" then
  if states[player] or Social.trading(player) or type(value)~="table" then return end
  -- Credit every completed income tick before consuming source monsters.
  local gains=BagRules.accrue(bags[player],now(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
  local evolved,affected=BagRules.evolve(bags[player],value,now())
  if not evolved then
   remote:FireClient(player,"EvolutionResult",{ok=false,reason=affected})
   sendBag(player)
   return
  end
  companions.clear(player)
  for pen in pairs(affected) do Lobby.display(player,pen,bags[player].monsters) end
  remote:FireClient(player,"EvolutionResult",{ok=true,monsterId=evolved.monsterId,stars=evolved.stars})
  send(player)
  if #gains>0 then remote:FireClient(player,"BagIncome",gains) end
  sendBag(player)
  return
 end
 if action=="Journal" then if not states[player] then remote:FireClient(player,"Journal",Progress.snapshot(player,true)) end return end
 if action=="Bag" then sendBag(player) return end
 if action=="Sync" then send(player) sendBag(player) return end
 if action=="Start" then start(player) return end
 if action=="ReturnLobby" then
  local state=states[player]
  if (not state or state.phase=="GameOver" or state.phase=="CourseEnd") and not player:GetAttribute("ReturningLobby") then
   player:SetAttribute("ReturningLobby",true)
   restoreAvatar(state)
   states[player]=nil
   if worldRoots[player] then worldRoots[player]:Destroy() end
   worlds[player],worldRoots[player]=nil,nil
   local character=player.Character
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not humanoid or humanoid.Health<=0 or (state and (state.phase=="GameOver" or state.phase=="CourseEnd")) then
    local ok,err=pcall(function() player:LoadCharacterAsync() end)
    if not ok then states[player]=state player:SetAttribute("ReturningLobby",nil) warn("LOBBY_RESPAWN_FAILED: "..tostring(err)) send(player,"다시 로비로 돌아가기를 눌러 주세요.") return end
    character=player.Character
   end
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then root.Anchored=false root.AssemblyLinearVelocity=Vector3.zero character:PivotTo(Lobby.Spawn) end
   humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then humanoid.PlatformStand=false humanoid.AutoRotate=true end
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(character)
   player:SetAttribute("ReturningLobby",nil)
   send(player,"로비로 돌아왔습니다.") sendBag(player)
  end
  return
 end
 local state=states[player]
 if not state or state.phase=="GameOver" then return end
 if action=="Steer" and state.phase=="Riding" and type(value)=="number" and value==value and value>=-1 and value<=1 then
  state.steer,state.steerAt=value,now()
 elseif action=="Jump" and value==nil then
  if state.phase=="Riding" then launch(player,state)
  elseif state.phase=="Airborne" then lasso(player,state) end
 end
end)
RunService.Heartbeat:Connect(function(delta)
 local clock,dt=now(),math.min(delta,0.1)
 for _,world in pairs(worlds) do world.step(dt) end
 local nearZ={0}
 local watchers={}
 for player,state in pairs(states) do
  local World=worlds[player]
  if (state.phase=="GameOver" or state.phase=="CourseEnd") then
   if state.root.Parent then table.insert(nearZ,state.root.Position.Z) end
   continue
  end
  if not state.root.Parent or player.Character~=state.root.Parent or state.humanoid.Health<=0 then finish(player,"Hunt ended") continue end
  local steer=state.phase=="Riding" and clock-state.steerAt<0.5 and state.steer or 0
  local buckHeight,buckDrift=0,0
  if state.phase=="Riding" and Config.Hunt.AngerEnabled and clock-state.started>=Config.Hunt.AngerSeconds then
   state.angerAt=state.angerAt or state.started+Config.Hunt.AngerSeconds
   local elapsed=clock-state.angerAt-tuning.AngerWarningSeconds
   if elapsed>=0 then
    buckHeight,buckDrift=Rules.buck(elapsed,tuning.BuckCycleSeconds,tuning.BuckHeightStuds,Catalog[state.monster:GetAttribute("MonsterId")].TripleHop)
    steer*=tuning.AngrySteerMultiplier
   end
  end
  local old=state.phase=="Riding" and state.monster and state.monster.PrimaryPart.Position or state.root.Position
  local speed=state.phase=="Airborne" and tuning.AirStudsPerSecond or Rules.rideSpeed(clock,state.phase=="Riding" and state.dashUntil,baseSpeed(state),tuning.SwitchDashMultiplier)
  local position=Vector3.new(math.clamp(old.X+(steer*tuning.SidewaysStudsPerSecond+buckDrift*tuning.BuckSidewaysStudsPerSecond)*dt,-tuning.RoadHalfWidth,tuning.RoadHalfWidth),old.Y,old.Z-speed*dt)
  if state.distance+speed*dt*tuning.MetersPerStud>=Course.LengthMeters then
   state.distance=Course.LengthMeters
   state.phase="CourseEnd" state.dashUntil=nil
   if state.monster then state.monster:SetAttribute("Running",false) state.monster:SetAttribute("DashUntil",nil) state.monster:SetAttribute("Angry",false) state.monster:SetAttribute("AngerWarning",false) end
   if state.monster then
    local p=state.monster.PrimaryPart.Position
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z)
    state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   end
   clearRope(state)
   send(player,"Next region coming soon")
   continue
  end
  state.distance+=speed*dt*tuning.MetersPerStud
  World.ensure(position.Z)
  table.insert(nearZ,position.Z)
  if state.phase=="Airborne" then
   position=Vector3.new(position.X,state.launchY+Rules.jumpHeight(clock-state.started,tuning.FlightSeconds,tuning.JumpArcStuds),position.Z)
   state.root.CFrame=CFrame.new(position)
   if World.hit(old,position) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if state.phase=="Airborne" and clock-state.started>=tuning.FlightSeconds then finish(player,"You missed the next monster.","Fall") end
  elseif state.phase=="Lassoing" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   local p=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,(state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z),p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
   local saddle=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local landingSeconds=state.landingSeconds or tuning.JumpSeconds
   local landingProgress=math.clamp((clock-state.started)/landingSeconds,0,1)
   state.root.CFrame=state.origin:Lerp(saddle,landingProgress)*CFrame.new(0,math.sin(math.pi*landingProgress)*tuning.JumpArcStuds*0.5,0)
   if World.hit(p,state.monster.PrimaryPart.Position,state.monster:GetAttribute("Flying")) then finish(player,"You hit an obstacle.","Obstacle") continue end
   if clock-state.started>=landingSeconds then
    clearRope(state)
    state.initialLanding=nil state.monster:SetAttribute("InitialLanding",nil)
    state.phase,state.started,state.tamed="Riding",clock,state.monster:GetAttribute("Tamed_"..player.UserId)==true
    state.dashUntil=state.pendingDash and clock+tuning.SwitchDashSeconds or nil
    state.pendingDash=nil
    state.monster:SetAttribute("DashUntil",state.dashUntil)
    state.monster:SetAttribute("RunStarted",clock)
    state.monster:SetAttribute("Angry",false)
    state.monster:SetAttribute("AngerWarning",false)
    state.monster:SetAttribute("AngerStarted",nil)
    send(player)
    -- Space presses during landing are not queued as a new jump.
   end
  elseif state.phase=="Riding" then
   if not state.monster or not state.monster.Parent then finish(player,"You lost your mount.") continue end
   position=Vector3.new(position.X,((state.monster:GetAttribute("RootHeight") or 2)+World.groundHeight(state.monster.PrimaryPart.Position.X,state.monster.PrimaryPart.Position.Z))+buckHeight,position.Z)
   local before=state.monster.PrimaryPart.Position
   state.monster.PrimaryPart.CFrame=CFrame.new(position)
   state.monster:SetAttribute("Steering",steer)
   state.root.CFrame=state.monster:GetPivot()*CFrame.new(0,state.monster:GetAttribute("SaddleHeight") or tuning.RideHeightStuds,tuning.RideForwardStuds)
   local dashing=state.dashUntil~=nil and clock<state.dashUntil
   if World.crateHit(before,position,state.monster,state.monster:GetAttribute("SizeClass") or Config.Monster.SizeClass,dashing) then finish(player,"This monster cannot break crates.","Obstacle") continue end
   local contact=World.mountedHit(before,position,state.monster,World.visibleSet(position.Z,views[player],player),dashing)
   if contact then finish(player,contact=="Wall" and "You hit a wall." or "You hit another monster.",contact) continue end
   if World.hit(before,position,state.monster:GetAttribute("Flying"),state.monster,dashing) then finish(player,"You hit an obstacle.","Obstacle") continue end
   local tameReady,warningReady=Rules.mountTimeline(clock-state.started,Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds,Config.Hunt.AngerSeconds,tuning.AngerWarningSeconds)
   if not state.tamed and tameReady then
    local id=state.monster:GetAttribute("MonsterId") or Config.Monster.Id
    local species=Catalog[id]
    state.tamed=true BagRules.grant(bags[player],id,clock,species.IncomeSeconds,species.IncomeAmount) Progress.caught(player,id,1) send(player,"Monster tamed! Added to your bag.")
    state.monster:SetAttribute("Tamed_"..player.UserId,true)
   end
   if Config.Hunt.AngerEnabled and warningReady then
    state.angerAt=state.angerAt or state.started+Config.Hunt.AngerSeconds
    state.monster:SetAttribute("AngerWarning",true)
    state.monster:SetAttribute("AngerStarted",state.angerAt+tuning.AngerWarningSeconds)
    state.monster:SetAttribute("Angry",clock-state.angerAt>=tuning.AngerWarningSeconds)
    -- Anger persists until the rider chooses to jump or a real collision ends the run.
   end
  end
  table.insert(watchers,{z=state.root.Position.Z,aspect=views[player] or 1})
 end
 if clock-lastHerd>=0.25 then lastHerd=clock for player,state in pairs(states) do if state.phase~="GameOver" and state.phase~="CourseEnd" then worlds[player].maintain({{z=state.root.Position.Z,aspect=views[player] or 1}}) end end end
 if clock-lastSync>=0.25 then lastSync=clock for _,player in ipairs(Players:GetPlayers()) do send(player) end end
 if clock-lastCleanup>=3 then lastCleanup=clock for player,world in pairs(worlds) do world.cleanup({states[player] and states[player].root.Position.Z or 0}) end end
end)
local function added(player)
 if not Lobby.assign(player) then player:Kick("This server holds up to 8 players.") return end
 player.CharacterAdded:Connect(function(character) task.defer(function() if not states[player] then setCharacterGroup(player,"Default") Lobby.prepareCharacter(character) end end) end)
 if player.Character then setCharacterGroup(player,"Default") task.spawn(Lobby.prepareCharacter,player.Character) end
 player.CanLoadCharacterAppearance=true
 if player.UserId>0 then player.CharacterAppearanceId=player.UserId end
 local bag,message=Store.open(player)
 if not bag then Lobby.release(player) player:Kick(message) return end
 bags[player]=bag player:SetAttribute("Area","Lobby") Progress.join(player)
 require(game.ReplicatedStorage.RodeoFantasy.LobbyIncubatorRules).migrate(bag)
 for index=1,4 do Lobby.display(player,index,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function()
  companions.clear(player) finish(player,"Hunt ended") states[player]=nil
  if worldRoots[player] then worldRoots[player]:Destroy() end
  worlds[player],worldRoots[player]=nil,nil
 end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end
]========]},
{name="LobbyCompanions",parent=game.ServerScriptService,kind="ModuleScript",before=[========[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
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
 function api.clear(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","내 부화실 안에서 소환해주세요.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  if not source or source:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","이 몬스터의 모델을 준비 중입니다.") return
  end
  local position=r.Position+r.CFrame.RightVector*4-r.CFrame.LookVector*4
  local y=ground(position) if not y then return end
  local model=source:Clone() model:ScaleTo(model:GetScale()*Catalog.scale(item.stars)/Catalog.Scales[Catalog.stage(item.stars)])
  local height=Catalog[item.monsterId].RootHeight*Catalog.scale(item.stars)
  local frame=CFrame.new(position.X,y+height,position.Z)
  model:PivotTo(frame*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
  model.Name="Companion_"..p.UserId
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
   elseif part:IsA("BillboardGui") then part:Destroy() end
  end
  for key,value in pairs({MonsterId=item.monsterId,Stars=item.stars,OwnerUserId=p.UserId,BagItemId=id,Running=false,RootHeight=height,RunStarted=workspace:GetServerTimeNow()}) do model:SetAttribute(key,value) end
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false}
  p:SetAttribute("SummonedId",id)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="교감"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  prompt.Style=Enum.ProximityPromptStyle.Custom
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<1.5 then return end
   last=os.clock() P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=workspace:GetServerTimeNow()})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then api.clear(p) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    delta=delta.Unit*math.min(delta.Magnitude-6,32*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
    else
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
]========],after=[========[-- One owned companion per lobby player. No mounting and no invented bond rewards.
local M={}
local P=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(P.MonsterCatalog)
local Rules=require(P.SocialRules)
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
 function api.clear(p)
  local pet=pets[p] if pet then pet.model:Destroy() end
  pets[p]=nil p:SetAttribute("SummonedId",nil)
 end
 function api.summon(p,id)
  if not context.canAct(p) then return end
  if pets[p] and pets[p].id==id then api.clear(p) return end
  if not context.canSummon(p) then P.CaptureRemote:FireClient(p,"SocialMessage","내 부화실 안에서 소환해주세요.") return end
  local item=Rules.find(context.bag(p),id)
  local r=root(p) if not r or not Rules.available(item) then return end
  local source=P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))
  if not source or source:GetAttribute("MossratUserRigRevision")~="ApprovedS1-v1" then
   P.CaptureRemote:FireClient(p,"SocialMessage","이 몬스터의 모델을 준비 중입니다.") return
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
  api.clear(p) model.Parent=folder pets[p]={model=model,id=id,height=height,following=false}
  p:SetAttribute("SummonedId",id)
  local prompt=Instance.new("ProximityPrompt") prompt.Name="PetOwnCompanion" prompt.ActionText="교감"
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false prompt.Parent=model.PrimaryPart
  prompt.Style=Enum.ProximityPromptStyle.Custom
  local last=-math.huge
  prompt.Triggered:Connect(function(who)
   local rr=root(who)
   if who~=p or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),id)) or not rr or (rr.Position-model.PrimaryPart.Position).Magnitude>12 or os.clock()-last<3.5 then return end
   last=os.clock()
   local at=workspace:GetServerTimeNow()
   model:SetAttribute("PetBondStarted",at) model:SetAttribute("PetBondUntil",at+3)
   P.CaptureRemote:FireAllClients("LobbyPet",{model=model,at=at})
  end)
 end
 local elapsed=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  elapsed+=dt if elapsed<.1 then return end local step=math.min(elapsed,.2) elapsed=0
  for p,pet in pairs(pets) do
   local r=root(p)
   -- Saving/trading locks and character replacement are transient. Only clear
   -- on leaving the lobby or actually losing ownership; never on Store.busy.
   if not p.Parent or not context.inLobby(p) or not Rules.find(context.bag(p),pet.id) then api.clear(p) continue end
   if not r or not context.canAct(p) or not Rules.available(Rules.find(context.bag(p),pet.id)) then pet.model:SetAttribute("Running",false) continue end
   if (pet.model:GetAttribute("PetBondUntil") or 0)>workspace:GetServerTimeNow() then pet.model:SetAttribute("Running",false) continue end
   local old=pet.model.PrimaryPart.CFrame
   local toOwner=Vector3.new(r.Position.X-old.X,0,r.Position.Z-old.Z)
   -- A start/stop band keeps a resting pet still when its owner turns nearby.
   if toOwner.Magnitude>11 then pet.following=true
   elseif toOwner.Magnitude<=6 then pet.following=false end
   local target=r.Position
   local delta=Vector3.new(target.X-old.X,0,target.Z-old.Z)
   local moving=pet.following and delta.Magnitude>6
   if moving then
    delta=delta.Unit*math.min(delta.Magnitude-6,32*step)
    local position=old.Position+delta
    local y=ground(Vector3.new(position.X,r.Position.Y,position.Z))
    -- Lift the cast over the lobby's short steps, while still checking walls.
    local castHeight=y and math.max(old.Y,y+pet.height) or old.Y
    local hit=workspace:Blockcast(CFrame.new(old.X,castHeight,old.Z),Vector3.new(1.5,1.5,1.5),delta,params)
    if y and not hit and math.abs(y+pet.height-old.Y)<=6 then
     position=Vector3.new(position.X,y+pet.height,position.Z)
     local frame=CFrame.lookAt(position,position+delta)
     pet.model:PivotTo(frame*pet.model.PrimaryPart.CFrame:Inverse()*pet.model:GetPivot())
    else
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
]========]},
{name="LobbyWorld",parent=game.ServerScriptService,kind="ModuleScript",before=[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
require(script.Parent.LobbyAppearance).ensure(map)
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,14,-72)
local departureRadius=38
local function centerDeparture()
 local rocket=map.Airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then
  local box=rocket:GetBoundingBox()
  Lobby.Departure.Position=Vector3.new(box.Position.X,Lobby.Departure.Position.Y,box.Position.Z)
 end
 Lobby.Departure.Transparency=1
 Lobby.Departure.CanCollide=false
end
centerDeparture()
function Lobby.prepareCharacter(character)
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",10)
 if root then
  root.Anchored=true
  character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  local owner=game:GetService("Players"):GetPlayerFromCharacter(character)
  if owner and workspace.StreamingEnabled then pcall(function() owner:RequestStreamAroundAsync(Lobby.Spawn.Position,3) end) end
 end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed humanoid.PlatformStand=false humanoid.AutoRotate=true end
 if root then
  task.delay(.35,function()
   if character.Parent and root.Parent then
    character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
    root.Anchored=false
    if humanoid and humanoid.Health>0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
   end
  end)
 end
 local head=character:FindFirstChild("Head") or character:WaitForChild("Head",10)
 if head and not character:FindFirstChild("AstronautHelmet") then
  local helmet=Instance.new("Accessory") helmet.Name="AstronautHelmet"
  local bubble=Instance.new("Part") bubble.Name="Handle" bubble.Shape=Enum.PartType.Ball
  bubble.Size=Vector3.one*math.max(2.8,head.Size.Magnitude*1.5)
  bubble.Material=Enum.Material.Glass bubble.Color=Color3.fromRGB(196,232,245) bubble.Transparency=.78
  bubble.CanCollide=false bubble.CanTouch=false bubble.CanQuery=false bubble.Massless=true bubble.CastShadow=false
  bubble.CFrame=head.CFrame bubble.Parent=helmet
  local weld=Instance.new("WeldConstraint") weld.Part0=head weld.Part1=bubble weld.Parent=bubble
  helmet.Parent=character
 end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
end
local function label(index,name)
 local board=plots["Plot_"..index]:FindFirstChild("OwnerBoard")
 if not board then return end
 for _,gui in ipairs(board:GetChildren()) do
  if gui:IsA("SurfaceGui") then gui.Text.Text=name end
 end
end
for index=1,8 do label(index,"") end
function Lobby.assign(player)
 if owned[player] then return owned[player] end
 for index=1,8 do
  if not occupants[index] then
   occupants[index]=player owned[player]=index
   plots["Plot_"..index]:SetAttribute("OwnerUserId",player.UserId)
   player:SetAttribute("LobbySlot",index)
   label(index,player.Name)
   return index
  end
 end
 return nil
end
function Lobby.release(player)
 local index=owned[player]
 if not index then return end
 occupants[index]=nil owned[player]=nil
 player:SetAttribute("LobbySlot",nil)
 plots["Plot_"..index]:SetAttribute("OwnerUserId",nil)
 for _,pen in ipairs(plots["Plot_"..index].Pens:GetChildren()) do
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=departureRadius
end
function Lobby.getPen(player,index)
 if type(index)~="number" or index%1~=0 or index<1 or index>4 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canSummon(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and math.abs(root.Position.X-6000)<=256 and math.abs(root.Position.Z)<=256
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=departureRadius prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========],after=[========[local Lobby={}
local map=workspace:WaitForChild("RodeoLobby")
require(script.Parent.LobbyAppearance).ensure(map)
local plots=map:WaitForChild("Plots")
local owned,occupants={},{}
Lobby.Departure=map.Airport.Departure
Lobby.Spawn=CFrame.new(6000,14,-72)
local departureRadius=38
local function centerDeparture()
 local rocket=map.Airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then
  local box=rocket:GetBoundingBox()
  Lobby.Departure.Position=Vector3.new(box.Position.X,Lobby.Departure.Position.Y,box.Position.Z)
 end
 Lobby.Departure.Transparency=1
 Lobby.Departure.CanCollide=false
end
centerDeparture()
function Lobby.prepareCharacter(character)
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",10)
 if root then
  root.Anchored=true
  character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  local owner=game:GetService("Players"):GetPlayerFromCharacter(character)
  if owner and workspace.StreamingEnabled then pcall(function() owner:RequestStreamAroundAsync(Lobby.Spawn.Position,3) end) end
 end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
 if humanoid then humanoid.WalkSpeed=require(game.ReplicatedStorage.RodeoFantasy.Config).LobbyWalkSpeed humanoid.PlatformStand=false humanoid.AutoRotate=true end
 if root then
  task.delay(.35,function()
   if character.Parent and root.Parent then
    character:PivotTo(Lobby.Spawn) root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
    root.Anchored=false
    if humanoid and humanoid.Health>0 then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
   end
  end)
 end
 local helmet=character:FindFirstChild("AstronautHelmet")
 if helmet then helmet:Destroy() end
end
for index=1,8 do
 local plot=plots["Plot_"..index]
 plot:SetAttribute("Slot",index)
 for _,pen in ipairs(plot.Pens:GetChildren()) do pen:SetAttribute("Capacity",1) end
end
local function label(index,name)
 local board=plots["Plot_"..index]:FindFirstChild("OwnerBoard")
 if not board then return end
 for _,gui in ipairs(board:GetChildren()) do
  if gui:IsA("SurfaceGui") then gui.Text.Text=name end
 end
end
for index=1,8 do label(index,"") end
function Lobby.assign(player)
 if owned[player] then return owned[player] end
 for index=1,8 do
  if not occupants[index] then
   occupants[index]=player owned[player]=index
   plots["Plot_"..index]:SetAttribute("OwnerUserId",player.UserId)
   player:SetAttribute("LobbySlot",index)
   label(index,player.Name)
   return index
  end
 end
 return nil
end
function Lobby.release(player)
 local index=owned[player]
 if not index then return end
 occupants[index]=nil owned[player]=nil
 player:SetAttribute("LobbySlot",nil)
 plots["Plot_"..index]:SetAttribute("OwnerUserId",nil)
 for _,pen in ipairs(plots["Plot_"..index].Pens:GetChildren()) do
  for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do
   local display=pen:FindFirstChild(name) if display then display:Destroy() end
  end
 end
 label(index,"")
end
function Lobby.canDepart(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and (root.Position-Lobby.Departure.Position).Magnitude<=departureRadius
end
function Lobby.getPen(player,index)
 if type(index)~="number" or index%1~=0 or index<1 or index>4 or not owned[player] then return nil end
 return plots["Plot_"..owned[player]].Pens["Pen_"..index]
end
function Lobby.canManage(player)
 local index=owned[player]
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return index and root and (root.Position-plots["Plot_"..index].ManagePoint.Position).Magnitude<=36
end
function Lobby.canSummon(player)
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 return owned[player]~=nil and root and math.abs(root.Position.X-6000)<=256 and math.abs(root.Position.Z)<=256
end
function Lobby.canUsePen(player,index)
 return Lobby.getPen(player,index) and Lobby.canManage(player)
end
function Lobby.display(player,index,items)
 local pen=Lobby.getPen(player,index) if not pen then return end
 for _,name in ipairs({"DisplayMonsters","DisplayEggs"}) do local old=pen:FindFirstChild(name) if old then old:Destroy() end end
 local folder=Instance.new("Folder") folder.Name="DisplayEggs" folder.Parent=pen
 for _,egg in ipairs(items) do
  if egg.assignedPen==index then
   local shell=Instance.new("Part") shell.Name="IncubatingEgg" shell.Shape=Enum.PartType.Ball shell.Size=Vector3.new(2.6,3.4,2.6)
   shell.CFrame=pen.PenGrass.CFrame*CFrame.new(0,pen.PenGrass.Size.Y/2+1.7,0) shell.Color=Color3.fromRGB(246,234,196) shell.Material=Enum.Material.SmoothPlastic shell.Anchored=true shell.Parent=folder
   break
  end
 end
end
function Lobby.connectPens(callback)
 for plotIndex=1,8 do
  local plot=plots["Plot_"..plotIndex]
  local prompt=Instance.new("ProximityPrompt")
  prompt.Name="ManageRanch" prompt.ActionText="알 관리" prompt.ObjectText=""
  prompt.HoldDuration=1 prompt.MaxActivationDistance=10 prompt.RequiresLineOfSight=false
  prompt.KeyboardKeyCode=Enum.KeyCode.E prompt.Parent=plot.ManagePoint
  prompt.Triggered:Connect(function(player)
   if owned[player]==plotIndex and Lobby.canManage(player) then callback(player) end
  end)
 end
end
function Lobby.connect(callback)
 local prompt=Instance.new("ProximityPrompt")
 prompt.Name="FlyToHunt" prompt.ActionText="행성 선택" prompt.ObjectText="로켓"
 prompt.HoldDuration=1 prompt.MaxActivationDistance=departureRadius prompt.RequiresLineOfSight=false
 prompt.KeyboardKeyCode=Enum.KeyCode.E
 prompt.Parent=Lobby.Departure
 prompt.Triggered:Connect(function(player) if Lobby.canDepart(player) then callback(player) end end)
end
return Lobby
]========]},
{name="LobbyAppearance",parent=game.ServerScriptService,kind="ModuleScript",before=[========[-- Lobby roof and owner labels; personal rooms deliberately remain open above.
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
  local glass=part(roof,"FullGlassCeiling",Vector3.new(512,2,512),CFrame.new(6000,102,0),Color3.fromRGB(173,212,232),Enum.Material.Glass)
  glass.Transparency=.9 glass.CastShadow=false
 end
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
 if planet and not lobby:FindFirstChild("PlanetAura") then
  local aura=Instance.new("Model") aura.Name="PlanetAura" aura.Parent=lobby
  local box=planet:GetBoundingBox()
  for i,size in ipairs({250,272,294}) do
   local glow=part(aura,"VioletHalo"..i,Vector3.one*size,CFrame.new(box.Position),Color3.fromRGB(151,58,255),Enum.Material.Neon)
   glow.Shape=Enum.PartType.Ball glow.Transparency=({.9,.96,.98})[i]
   glow.CanCollide=false glow.CanQuery=false glow.CastShadow=false
  end
 end
end
return M
]========],after=[========[-- Lobby roof and owner labels; personal rooms deliberately remain open above.
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
]========]},
{name="RecordService",parent=game.ServerScriptService,kind="ModuleScript",before=[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters)
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>entry.distance
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.merge(old,entry.id,produced,best,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   distance:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.distance) end)
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=require(script.Parent.LobbyRankings).ensure(workspace.RodeoLobby)
 boards.Income.Ranking.Heading.Text="도감 수집"
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========],after=[========[-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Planets=require(game.ReplicatedStorage.RodeoFantasy.PlanetCatalog)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,collection
local planetStores={}
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  -- Reuse the old index for Green Star; existing records remain visible.
  for _,id in ipairs(Planets.Order) do planetStores[id]=id=="GreenStar" and distance or DSS:GetOrderedDataStore("RodeoDistance_"..id..suffix) end
  collection=DSS:GetOrderedDataStore("RodeoCollection"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,_,meters,planet)
 planet=planet or "GreenStar"
 if not Planets[planet] or type(meters)~="number" or meters~=meters or meters==math.huge or meters<0 then return end
 local produced=0 -- Production no longer grants a leaderboard score.
 if not enabled or player.UserId<=0 then return end
 local entry=entries[player.UserId]
 if not entry then
  entry={id=Http:GenerateGUID(false),produced=0,distance=0,distances={},dirty=true}
  entries[player.UserId]=entry
 end
 entry.dirty=entry.dirty or produced>entry.produced or meters>(entry.distances[planet] or 0)
 entry.distances[planet]=math.max(entry.distances[planet] or 0,meters)
 entry.produced=math.max(entry.produced,produced)
 entry.distance=math.max(entry.distance,meters)
end
function Service.save(userId)
 local entry=entries[userId]
 if not entry or entry.busy or not entry.dirty then return false end
 entry.busy=true
 local produced,best=entry.produced,entry.distance
 local snapshot=table.clone(entry.distances)
 local ok,result=pcall(function()
  return profile:UpdateAsync(tostring(userId),function(old)
   return Rules.mergePlanets(old,entry.id,produced,best,snapshot,os.time())
  end)
 end)
 if ok then
  -- Ordered indexes are monotonic; concurrent servers cannot lower a saved rank.
  local indexes=pcall(function()
   for id,store in pairs(planetStores) do
    local value=result.planetDistances[id]
    if value then store:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,value) end) end
   end
  end)
  entry.dirty=not indexes or entry.produced~=produced or entry.distance~=best
  for id,value in pairs(entry.distances) do if value~=(snapshot[id] or 0) then entry.dirty=true end end
  if indexes and entry.left and not entry.dirty then entries[userId]=nil end
 else
  warn("Rodeo records save failed; checkpoint retained for retry.")
 end
 entry.busy=false
 return ok and not entry.dirty
end
function Service.leave(player)
 local entry=entries[player.UserId]
 if entry then entry.left=true Service.save(player.UserId) end
end
local function refresh(board,store)
 local label=board.Ranking.Entries
 if not enabled then label.Text="Publish to enable rankings" return end
 local ok,pages=pcall(function() return store:GetSortedAsync(false,10,1) end)
 if not ok then
  if not board:GetAttribute("HasRecords") then label.Text="Records temporarily unavailable" end
  return -- retain the last successful board during an outage
 end
 local lines={}
 for rank,row in ipairs(pages:GetCurrentPage()) do
  local id=tonumber(row.key)
  if not names[id] then
   local found,name=pcall(function() return Players:GetNameFromUserIdAsync(id) end)
   names[id]=found and name or nil
  end
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or " / "..#Catalog.Order*4)
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=require(script.Parent.LobbyRankings).ensure(workspace.RodeoLobby)
 boards.Income.Ranking.Heading.Text="도감 수집"
 boards.Distance.Ranking.Heading.Text="Green Star · Distance Top 10"
 task.spawn(function()
  while true do
   -- Each confirmed planet has its own ordered index. Only Green Star is live.
   refresh(boards.Distance,planetStores.GreenStar) refresh(boards.Income,collection)
   task.wait(60)
  end
 end)
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for id in pairs(entries) do task.spawn(Service.save,id) end
  end
 end)
 game:BindToClose(function()
  local remaining=0
  for id in pairs(entries) do
   remaining+=1
   task.spawn(function()
    local deadline=os.clock()+23
    repeat
     Service.save(id)
     if not entries[id] or not entries[id].dirty then break end
     task.wait(1)
    until os.clock()>deadline
    remaining-=1
   end)
  end
  local deadline=os.clock()+25
  while remaining>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return Service
]========]},
{name="PetPromptUI",parent=game.StarterPlayer.StarterPlayerScripts,kind="ModuleScript",before=[========[-- A screen button avoids placing a large prompt over the companion model.
local M={}
function M.new(gui,player)
 local UIS=game:GetService("UserInputService")
 local service=game:GetService("ProximityPromptService")
 local current,held,connections=nil,nil,{}
 local button=Instance.new("TextButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,0,1,-100) button.Size=UDim2.fromOffset(150,48)
 button.BackgroundColor3=Color3.fromRGB(34,45,64) button.TextColor3=Color3.new(1,1,1) button.Font=Enum.Font.GothamBold
 button.TextSize=18 button.ZIndex=10 button.Parent=gui
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=button
 local bar=Instance.new("Frame") bar.Name="HoldProgress" bar.Size=UDim2.new(0,0,0,4) bar.Position=UDim2.new(0,0,1,-4)
 bar.BackgroundColor3=Color3.fromRGB(184,121,255) bar.BorderSizePixel=0 bar.ZIndex=11 bar.Parent=button
 local tween
 local function reset()
  if tween then tween:Cancel() tween=nil end bar.Size=UDim2.new(0,0,0,4)
 end
 local function hide()
  if held and current then current:InputHoldEnd() end held=nil current=nil button.Visible=false reset()
  for _,c in ipairs(connections) do c:Disconnect() end table.clear(connections)
 end
 service.PromptShown:Connect(function(prompt)
  if prompt.Name~="PetOwnCompanion" then return end
  local model=prompt:FindFirstAncestorOfClass("Model")
  if not model or model:GetAttribute("OwnerUserId")~=player.UserId then prompt.Enabled=false return end
  hide() current=prompt button.Visible=true button.Text=UIS.TouchEnabled and "교감 · 꾹 누르기" or "교감 · E 꾹"
  table.insert(connections,prompt.PromptButtonHoldBegan:Connect(function()
   reset() tween=game:GetService("TweenService"):Create(bar,TweenInfo.new(prompt.HoldDuration,Enum.EasingStyle.Linear),{Size=UDim2.new(1,0,0,4)}) tween:Play()
  end))
  table.insert(connections,prompt.PromptButtonHoldEnded:Connect(reset))
  table.insert(connections,prompt.Triggered:Connect(reset))
 end)
 service.PromptHidden:Connect(function(prompt) if current==prompt then hide() end end)
 button.InputBegan:Connect(function(input)
  if current and not held and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then held=input current:InputHoldBegin() end
 end)
 UIS.InputEnded:Connect(function(input) if input==held then if current then current:InputHoldEnd() end held=nil end end)
 UIS.WindowFocusReleased:Connect(function() if held and current then current:InputHoldEnd() end held=nil reset() end)
 gui.Destroying:Connect(hide)
end
return M
]========],after=[========[-- A screen button avoids placing a large prompt over the companion model.
local M={}
function M.new(gui,player)
 local UIS=game:GetService("UserInputService")
 local service=game:GetService("ProximityPromptService")
 local current,held,connections=nil,nil,{}
 local button=Instance.new("TextButton") button.Name="PetInteract" button.Visible=false
 button.AnchorPoint=Vector2.new(.5,1) button.Position=UDim2.new(.5,0,1,-100) button.Size=UDim2.fromOffset(150,48)
 button.BackgroundColor3=Color3.fromRGB(34,45,64) button.TextColor3=Color3.new(1,1,1) button.Font=Enum.Font.GothamBold
 button.TextSize=18 button.ZIndex=10 button.Parent=gui
 local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=button
 local bar=Instance.new("Frame") bar.Name="HoldProgress" bar.Size=UDim2.new(0,0,0,4) bar.Position=UDim2.new(0,0,1,-4)
 bar.BackgroundColor3=Color3.fromRGB(184,121,255) bar.BorderSizePixel=0 bar.ZIndex=11 bar.Parent=button
 local tween
 local function reset()
  if tween then tween:Cancel() tween=nil end bar.Size=UDim2.new(0,0,0,4)
 end
 local function hide()
  if held and current then current:InputHoldEnd() end held=nil current=nil button.Visible=false reset()
  for _,c in ipairs(connections) do c:Disconnect() end table.clear(connections)
 end
 service.PromptShown:Connect(function(prompt)
  if prompt.Name~="PetOwnCompanion" then return end
  local model=prompt:FindFirstAncestorOfClass("Model")
  if not model or model:GetAttribute("OwnerUserId")~=player.UserId then prompt.Enabled=false return end
  hide() current=prompt button.Visible=true button.Text=UIS.TouchEnabled and "교감" or "교감 E"
  table.insert(connections,prompt.PromptButtonHoldBegan:Connect(function()
   reset() tween=game:GetService("TweenService"):Create(bar,TweenInfo.new(prompt.HoldDuration,Enum.EasingStyle.Linear),{Size=UDim2.new(1,0,0,4)}) tween:Play()
  end))
  table.insert(connections,prompt.PromptButtonHoldEnded:Connect(reset))
  table.insert(connections,prompt.Triggered:Connect(reset))
 end)
 service.PromptHidden:Connect(function(prompt) if current==prompt then hide() end end)
 button.InputBegan:Connect(function(input)
  if current and not held and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1) then held=input current:InputHoldBegin() end
 end)
 UIS.InputEnded:Connect(function(input) if input==held then if current then current:InputHoldEnd() end held=nil end end)
 UIS.WindowFocusReleased:Connect(function() if held and current then current:InputHoldEnd() end held=nil reset() end)
 gui.Destroying:Connect(hide)
end
return M
]========]},
{name="UserMossratRigAnimator",parent=game.StarterPlayer.StarterPlayerScripts,kind="ModuleScript",before=[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,bones={},last=0,started=os.clock()}
  for _,b in ipairs(body:GetDescendants()) do if b:IsA("Bone") then c.bones[b.Name]=b end end
  cache[model]=c
 end
 local now=os.clock()
 if c.mode and now-c.last<1/30 then return end c.last=now
 local mode=moving and "Walk" or "Idle"
 if c.mode~=mode then c.mode=mode c.started=now c.blendStarted=now c.previous={}
  for name,b in pairs(c.bones) do c.previous[name]=b.Transform end
 end
 local clip=data.clips[mode]
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
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if legSide and legLimb and moving then
    local opposite=(legSide=="Left")~=(legLimb=="Front")
    local beat=math.sin((now-c.started)*math.pi*6+(opposite and math.pi or 0))
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========],after=[========[-- Plays the exact approved glTF samples through Bone.Transform; never blinks.
local A={}
local data=require(game.ReplicatedStorage.RodeoFantasy:WaitForChild("UserMossratRigData"))
local cache=setmetatable({},{__mode="k"})
local torsoCenterX={Pelvis=-.04,Spine=.02,Chest=.035,Neck=.025,Head=.015}
-- Portraits do not run the walking animation loop. Apply the same neutral
-- torso/head correction immediately so their first frame matches the game.
function A.poseFront(model)
 local body=model:FindFirstChild("Body") if not body then return end
 local scale=model:GetAttribute("MossratRigTranslationScale") or 2.5/data.height
 for _,b in ipairs(body:GetDescendants()) do
  if b:IsA("Bone") then
   local x=torsoCenterX[b.Name]
   b.Transform=CFrame.new((x or 0)*scale,0,0)
   if b.Name=="Head" then b.Transform=b.Transform*CFrame.Angles(0,math.rad(-8.2),0) end
  end
 end
end
local function rotation(v)
 local x,y,z,w=v[1],v[2],v[3],v[4]
 local n=math.sqrt(x*x+y*y+z*z+w*w) x,y,z,w=x/n,y/n,z/n,w/n
 return CFrame.new(0,0,0,1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y))
end
function A.animate(model,moving)
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
   local centerX=torsoCenterX[name]
   if name=="Head" or name=="Neck" then frame=CFrame.identity end
   if centerX then frame=CFrame.new(centerX*scale,0,0)*frame end
   if name=="Head" then frame=frame*CFrame.Angles(0,math.rad(-8.2),0) end
   -- Explicit four-leg stride also covers imported rigs whose revision attribute is absent.
   local legSide=name:sub(1,4)=="Left" and "Left" or name:sub(1,5)=="Right" and "Right" or nil
   local legLimb=name:find("Front",1,true) and "Front" or name:find("Rear",1,true) and "Rear" or nil
   if bonding then
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
    if name:find("Upper",1,true) then frame=CFrame.Angles(beat*.65,0,0)
    elseif name:find("Lower",1,true) then frame=CFrame.Angles(math.max(0,-beat)*.65,0,0)
    elseif name:find("Paw",1,true) then frame=CFrame.Angles(-beat*.25,0,0) end
   end
   b.Transform=(c.previous[name] or CFrame.identity):Lerp(frame,blend)
  end
 end
end
return A
]========]},
{name="HuntEffects",parent=game.StarterPlayer.StarterPlayerScripts,kind="ModuleScript",before=[========[-- Local effects with a fixed object budget, independent of herd size.
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
 local gui=Instance.new("BillboardGui") gui.Name="LocalPetHeart" gui.Size=UDim2.fromOffset(60,60)
 gui.StudsOffset=Vector3.new(0,4,0) gui.AlwaysOnTop=false gui.Parent=model.PrimaryPart
 local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
 label.Text="♥" label.TextColor3=Color3.fromRGB(255,162,193) label.TextSize=40 label.Parent=gui
 game:GetService("Debris"):AddItem(gui,1.2)
end
return M
]========],after=[========[-- Local effects with a fixed object budget, independent of herd size.
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
]========]},
{name="JournalUI",parent=game.StarterPlayer.StarterPlayerScripts,kind="ModuleScript",before=[========[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Buttons=require(script.Parent:WaitForChild("BagUI"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(kind,props,parent)
 local n=Instance.new(kind)
 if n:IsA("TextLabel") or n:IsA("TextButton") then
  n.Font=Enum.Font.GothamBlack n.TextColor3=Color3.new(1,1,1)
  n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0
 end
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
local function label(parent,name,value,x,y,w,h,max)
 local n=make("TextLabel",{Name=name,Text=value,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundTransparency=1,TextScaled=true,TextWrapped=true,ZIndex=45},parent)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=max},n) return n
end
local function panel(parent,name,x,y,w,h,color)
 local n=make("Frame",{Name=name,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color,BorderSizePixel=0,ZIndex=42},parent)
 make("UIStroke",{Color=Color3.fromRGB(10,14,20),Thickness=2},n) return n
end
local function gradient(parent,a,b)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new(a,b)},parent)
end
local function T(v) return L.text(v,player.LocaleId) end
function J.new(gui,remote)
 local self={area="Lobby",page=1,seen={},data={},entries=Q.entries(C),perSpread=8,selected=1}
 local button=Buttons.iconButton(gui,"Journal","T",92)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.91,.82),BackgroundColor3=Color3.fromRGB(54,58,72),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1000,620)},book)
 make("UIStroke",{Color=Color3.fromRGB(8,12,19),Thickness=3},book)
 gradient(book,Color3.fromRGB(71,77,96),Color3.fromRGB(37,39,52))
 -- Smooth plate seams, rather than studs, carry the reference's dark framing.
 for i=1,15 do
  make("Frame",{Name="FrameSeam",Position=UDim2.fromScale(i/16,0),Size=UDim2.fromScale(.002,1),BackgroundColor3=Color3.fromRGB(100,108,129),BackgroundTransparency=.8,BorderSizePixel=0,ZIndex=40},book)
 end
 local header=panel(book,"IndexHeader",.008,.012,.984,.12,Color3.fromRGB(22,204,247))
 gradient(header,Color3.fromRGB(117,241,255),Color3.fromRGB(0,167,228))
 label(header,"Title","펫 인덱스",.02,.05,.7,.85,30).TextXAlignment=Enum.TextXAlignment.Left
 local close=make("TextButton",{Name="CloseJournal",Text="X",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(255,56,60),TextSize=30,BorderSizePixel=0,ZIndex=47},header)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},close)
 gradient(close,Color3.fromRGB(255,131,129),Color3.fromRGB(241,24,34))
 local region=panel(book,"PlanetLandscape",.02,.16,.14,.68,Color3.fromRGB(37,93,29))
 gradient(region,Color3.fromRGB(127,186,62),Color3.fromRGB(24,73,39))
 label(region,"PlanetName","Green Star",.04,.04,.92,.2,23)
 label(region,"Biome","초원",.08,.66,.84,.18,22)
 local planet=make("Frame",{Name="GreenStarPlanet",Position=UDim2.fromScale(.13,.30),Size=UDim2.fromScale(.74,.28),BackgroundColor3=Color3.fromRGB(98,209,45),BorderSizePixel=0,ZIndex=43},region)
 make("UICorner",{CornerRadius=UDim.new(1,0)},planet)
 make("UIAspectRatioConstraint",{AspectRatio=1},planet)
 gradient(planet,Color3.fromRGB(166,237,66),Color3.fromRGB(19,100,55))
 make("UIStroke",{Color=Color3.fromRGB(158,255,157),Thickness=2},planet)
 local pages=panel(book,"JournalEntries",.18,.16,.50,.53,Color3.fromRGB(23,27,35))
 local progress=panel(book,"CollectionProgress",.18,.72,.50,.12,Color3.fromRGB(14,18,25))
 local progressFill=make("Frame",{Name="ProgressFill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(26,220,84),BorderSizePixel=0,ZIndex=43},progress)
 gradient(progressFill,Color3.fromRGB(103,255,68),Color3.fromRGB(8,138,55))
 local progressText=label(progress,"ProgressCount","",0,0,1,1,32)
 local detail=panel(book,"SelectedMonster",.70,.16,.28,.42,Color3.fromRGB(14,99,181))
 gradient(detail,Color3.fromRGB(30,148,235),Color3.fromRGB(8,31,60))
 local info=panel(book,"MonsterInformation",.70,.61,.28,.23,Color3.fromRGB(21,68,40))
 gradient(info,Color3.fromRGB(35,110,57),Color3.fromRGB(13,37,24))
 local bottom=panel(book,"UnlockSummary",.02,.88,.96,.095,Color3.fromRGB(17,20,29))
 local summary=label(bottom,"JournalCount","",.1,0,.68,1,24)
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(2,0),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-2,0,0),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local pageNumber=label(bottom,"JournalPage","",.79,0,.12,1,15)
 local planetTab=make("TextButton",{Name="Planet_GreenStar",Text="행성\nGreen Star",Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.18),BackgroundColor3=Color3.fromRGB(59,206,73),BorderSizePixel=0,TextScaled=true,ZIndex=46},book)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},planetTab)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=21},planetTab)
 gradient(planetTab,Color3.fromRGB(167,250,95),Color3.fromRGB(14,127,67))
 local compact=false
 local lockedHumanoid,savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h and h~=lockedHumanoid then
   lockedHumanoid=h savedWalk=h.WalkSpeed savedJump=h.JumpPower savedRotate=h.AutoRotate savedHeight=h.JumpHeight
   h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0 h.AutoRotate=false
  end
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid:Move(Vector3.zero) end
 end
 local function unlock()
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.WalkSpeed=savedWalk lockedHumanoid.JumpPower=savedJump lockedHumanoid.JumpHeight=savedHeight lockedHumanoid.AutoRotate=savedRotate end
  lockedHumanoid=nil CAS:UnbindAction("JournalPages")
 end
 function self.close() book.Visible=false unlock() end
 local function selectedDetail()
  for _,n in ipairs(detail:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  for _,n in ipairs(info:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local entry=self.entries[self.selected] if not entry then return end
  local species=C[entry.monsterId] local revealed=self.seen[entry.key]==true
  local viewport=make("ViewportFrame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,Ambient=Color3.fromRGB(210,215,211),LightColor=Color3.new(1,1,1),ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income((species.IncomeAmount or 1)*2^(entry.stars-1),species.IncomeSeconds or 3,player.LocaleId) or "???",.04,.87,.92,.12,20)
  income.TextColor3=Color3.fromRGB(97,255,61)
  label(info,"Acquisition",revealed and (entry.stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,player.LocaleId) or L.evolutionHint(entry.stars,player.LocaleId)) or "수집하면 정보가 공개됩니다",.05,.05,.9,.58,16)
  label(info,"Caught",T("Caught").." "..(self.data.caught and self.data.caught[entry.key] or 0),.05,.67,.9,.26,17)
 end
 function self.render()
  for _,n in ipairs(pages:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) self.page=math.clamp(self.page,1,max)
  self.selected=math.clamp(self.selected,1,math.max(1,#self.entries))
  pageNumber.Text=self.page.." / "..max
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text="잠금 해제: "..discovered.."/"..#self.entries
  progressText.Text=discovered.."/"..#self.entries progressFill.Size=UDim2.fromScale(#self.entries>0 and discovered/#self.entries or 0,1)
  previous.Visible=max>1 nextPage.Visible=max>1
  local colors={Color3.fromRGB(83,181,78),Color3.fromRGB(26,139,232),Color3.fromRGB(203,73,229),Color3.fromRGB(242,190,32)}
  local columns=(compact or #self.entries<=4) and 2 or 4
  for slot=1,self.perSpread do
   local index=(self.page-1)*self.perSpread+slot local entry=self.entries[index] if not entry then break end
   local revealed=self.seen[entry.key]==true
   local rows=math.max(2,math.ceil(math.min(self.perSpread,#self.entries)/columns))
   local card=make("TextButton",{Name="JournalEntry",Text="",Position=UDim2.fromScale(((slot-1)%columns)/columns+.01,math.floor((slot-1)/columns)/rows+.015),Size=UDim2.fromScale(1/columns-.02,1/rows-.03),BackgroundColor3=colors[((slot-1)%4)+1],BorderSizePixel=0,ZIndex=44},pages)
   make("UIStroke",{Color=index==self.selected and Color3.fromRGB(232,250,255) or Color3.new(0,0,0),Thickness=index==self.selected and 3 or 2},card)
   gradient(card,Color3.fromRGB(218,230,235),Color3.fromRGB(50,86,108))
   local viewport=make("ViewportFrame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,Ambient=Color3.fromRGB(205,213,200),LightColor=Color3.new(1,1,1),ZIndex=45},card)
   Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
   label(card,"EntryName",revealed and T(entry.monsterId) or "???",.02,.01,.96,.19,17)
   label(card,"Stars",entry.stars.."★",0,.82,1,.18,16)
   card.Activated:Connect(function() self.selected=index self.render() end)
  end
  selectedDetail()
 end
 function self.turn(direction)
  if not book.Visible then return end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) local page=math.clamp(self.page+direction,1,max)
  if self.page==page then return end self.page=page self.render() Audio.ui("PageTurn")
 end
 function self.open()
  if self.area=="Hunt" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze() self.render() Audio.ui("BookOpen")
  if not self.other then remote:FireServer("Journal") end
  CAS:BindActionAtPriority("JournalPages",function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then self.turn(-1)
    elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then self.turn(1) end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
 end
 function self.viewOther(data) self.other=true self.close() self.snapshot(data) self.open() end
 function self.snapshot(data) self.data=data self.seen=data.seen or self.seen if book.Visible then self.render() end end
 function self.state(data)
  self.area=data.area button.Visible=self.area~="Hunt"
  if self.area=="Hunt" then self.close() end
  if book.Visible and not self.other and data.count~=self.lastCount then remote:FireServer("Journal") end self.lastCount=data.count
 end
 local function resize()
  local camera=workspace.CurrentCamera
  compact=camera and camera.ViewportSize.X<860 or false
  if compact then
   book.Position=UDim2.fromScale(.5,.5) book.Size=UDim2.fromScale(.92,.86)
   region.Visible=false planetTab.Position=UDim2.fromScale(.70,.15) planetTab.Size=UDim2.fromScale(.28,.12)
   pages.Position=UDim2.fromScale(.02,.16) pages.Size=UDim2.fromScale(.65,.52)
   progress.Position=UDim2.fromScale(.02,.71) progress.Size=UDim2.fromScale(.65,.10)
   detail.Position=UDim2.fromScale(.70,.30) detail.Size=UDim2.fromScale(.28,.51)
   info.Visible=false
  else
   book.Position=UDim2.fromScale(.44,.5) book.Size=UDim2.fromScale(.76,.82)
   region.Visible=true planetTab.Position=UDim2.fromScale(1.025,.17) planetTab.Size=UDim2.fromScale(.18,.18)
   pages.Position=UDim2.fromScale(.18,.16) pages.Size=UDim2.fromScale(.50,.53)
   progress.Position=UDim2.fromScale(.18,.72) progress.Size=UDim2.fromScale(.50,.12)
   detail.Position=UDim2.fromScale(.70,.16) detail.Size=UDim2.fromScale(.28,.42) info.Visible=true
  end
  if book.Visible then self.render() end
 end
 -- Decide from screen width, not a size this callback itself changes.
 local function screenLayout()
  resize()
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(screenLayout) end
 task.defer(screenLayout)
 planetTab.Activated:Connect(function() self.page=1 self.render() end)
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]========],after=[========[-- Reference-style index; collection keys and income rules remain unchanged.
local J={}
local player=game:GetService("Players").LocalPlayer
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local Q=require(package.CollectionQuery)
local L=require(package.Localization)
local Planets=require(package.PlanetCatalog)
local Portrait=require(script.Parent:WaitForChild("MonsterPortrait"))
local Buttons=require(script.Parent:WaitForChild("BagUI"))
local Audio=require(script.Parent:WaitForChild("AudioPresentation"))
local function make(kind,props,parent)
 local n=Instance.new(kind)
 if n:IsA("TextLabel") or n:IsA("TextButton") then
  n.Font=Enum.Font.GothamBlack n.TextColor3=Color3.new(1,1,1)
  n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0
 end
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
local function label(parent,name,value,x,y,w,h,max)
 local n=make("TextLabel",{Name=name,Text=value,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundTransparency=1,TextScaled=true,TextWrapped=true,ZIndex=45},parent)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=max},n) return n
end
local function panel(parent,name,x,y,w,h,color)
 local n=make("Frame",{Name=name,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=color,BorderSizePixel=0,ZIndex=42},parent)
 make("UIStroke",{Color=Color3.fromRGB(10,14,20),Thickness=2},n) return n
end
local function gradient(parent,a,b)
 make("UIGradient",{Rotation=90,Color=ColorSequence.new(a,b)},parent)
end
local function T(v) return L.text(v,player.LocaleId) end
function J.new(gui,remote)
 local self={area="Lobby",page=1,seen={},data={},entries=Q.entries(C),perSpread=8,selected=1}
 local button=Buttons.iconButton(gui,"Journal","T",92)
 local book=make("Frame",{Name="FieldJournal",Visible=false,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.91,.82),BackgroundColor3=Color3.fromRGB(54,58,72),BorderSizePixel=0,ZIndex=40},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(1000,620)},book)
 make("UIStroke",{Color=Color3.fromRGB(8,12,19),Thickness=3},book)
 gradient(book,Color3.fromRGB(71,77,96),Color3.fromRGB(37,39,52))
 -- Smooth plate seams, rather than studs, carry the reference's dark framing.
 for i=1,15 do
  make("Frame",{Name="FrameSeam",Position=UDim2.fromScale(i/16,0),Size=UDim2.fromScale(.002,1),BackgroundColor3=Color3.fromRGB(100,108,129),BackgroundTransparency=.8,BorderSizePixel=0,ZIndex=40},book)
 end
 local header=panel(book,"IndexHeader",.008,.012,.984,.12,Color3.fromRGB(22,204,247))
 gradient(header,Color3.fromRGB(117,241,255),Color3.fromRGB(0,167,228))
 label(header,"Title","펫 인덱스",.02,.05,.7,.85,30).TextXAlignment=Enum.TextXAlignment.Left
 local close=make("TextButton",{Name="CloseJournal",Text="X",AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-6,.5,0),Size=UDim2.fromOffset(44,44),BackgroundColor3=Color3.fromRGB(255,56,60),TextSize=30,BorderSizePixel=0,ZIndex=47},header)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},close)
 gradient(close,Color3.fromRGB(255,131,129),Color3.fromRGB(241,24,34))
 local region=panel(book,"PlanetLandscape",.02,.16,.14,.68,Color3.fromRGB(37,93,29))
 gradient(region,Color3.fromRGB(127,186,62),Color3.fromRGB(24,73,39))
 label(region,"PlanetName","Green Star",.04,.04,.92,.2,23)
 label(region,"Biome","초원",.08,.66,.84,.18,22)
 local planet=make("Frame",{Name="GreenStarPlanet",Position=UDim2.fromScale(.13,.30),Size=UDim2.fromScale(.74,.28),BackgroundColor3=Color3.fromRGB(98,209,45),BorderSizePixel=0,ZIndex=43},region)
 make("UICorner",{CornerRadius=UDim.new(1,0)},planet)
 make("UIAspectRatioConstraint",{AspectRatio=1},planet)
 gradient(planet,Color3.fromRGB(166,237,66),Color3.fromRGB(19,100,55))
 make("UIStroke",{Color=Color3.fromRGB(158,255,157),Thickness=2},planet)
 local art=make("ImageLabel",{Name="GreenStarArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.01,.23),Size=UDim2.fromScale(.98,.42),ScaleType=Enum.ScaleType.Fit,ZIndex=44},region)
 task.spawn(function() while art.Parent and not art.IsLoaded do task.wait(.25) end if art.Parent then planet.Visible=false end end)
 local pages=panel(book,"JournalEntries",.18,.16,.50,.53,Color3.fromRGB(23,27,35))
 local progress=panel(book,"CollectionProgress",.18,.72,.50,.12,Color3.fromRGB(14,18,25))
 local progressFill=make("Frame",{Name="ProgressFill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(26,220,84),BorderSizePixel=0,ZIndex=43},progress)
 gradient(progressFill,Color3.fromRGB(103,255,68),Color3.fromRGB(8,138,55))
 local progressText=label(progress,"ProgressCount","",0,0,1,1,32)
 local detail=panel(book,"SelectedMonster",.70,.16,.28,.42,Color3.fromRGB(14,99,181))
 gradient(detail,Color3.fromRGB(30,148,235),Color3.fromRGB(8,31,60))
 local info=panel(book,"MonsterInformation",.70,.61,.28,.23,Color3.fromRGB(21,68,40))
 gradient(info,Color3.fromRGB(35,110,57),Color3.fromRGB(13,37,24))
 local bottom=panel(book,"UnlockSummary",.02,.88,.96,.095,Color3.fromRGB(17,20,29))
 local summary=label(bottom,"JournalCount","",.1,0,.68,1,24)
 local previous=make("TextButton",{Name="JournalPrevious",Text="‹",Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(2,0),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local nextPage=make("TextButton",{Name="JournalNext",Text="›",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-2,0,0),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1,TextSize=30,ZIndex=46},bottom)
 local pageNumber=label(bottom,"JournalPage","",.79,0,.12,1,15)
 local planetTab=make("TextButton",{Name="Planet_GreenStar",Text="행성\nGreen Star",Position=UDim2.fromScale(1.025,.17),Size=UDim2.fromScale(.18,.18),BackgroundColor3=Color3.fromRGB(59,206,73),BorderSizePixel=0,TextScaled=true,ZIndex=46},book)
 make("UIStroke",{Color=Color3.new(0,0,0),Thickness=2},planetTab)
 make("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=21},planetTab)
 gradient(planetTab,Color3.fromRGB(167,250,95),Color3.fromRGB(14,127,67))
 planetTab.Text=""
 local tabLabel=label(planetTab,"PlanetTabLabel","행성\nGreen Star",.36,.04,.62,.92,21) tabLabel.ZIndex=47
 make("ImageLabel",{Name="GreenStarTabArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.015,.08),Size=UDim2.fromScale(.34,.84),ScaleType=Enum.ScaleType.Fit,ZIndex=47},planetTab)
 local compact=false
 local lockedHumanoid,savedWalk,savedJump,savedRotate,savedHeight
 local function freeze()
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if h and h~=lockedHumanoid then
   lockedHumanoid=h savedWalk=h.WalkSpeed savedJump=h.JumpPower savedRotate=h.AutoRotate savedHeight=h.JumpHeight
   h.WalkSpeed=0 h.JumpPower=0 h.JumpHeight=0 h.AutoRotate=false
  end
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid:Move(Vector3.zero) end
 end
 local function unlock()
  if lockedHumanoid and lockedHumanoid.Parent then lockedHumanoid.WalkSpeed=savedWalk lockedHumanoid.JumpPower=savedJump lockedHumanoid.JumpHeight=savedHeight lockedHumanoid.AutoRotate=savedRotate end
  lockedHumanoid=nil CAS:UnbindAction("JournalPages")
 end
 function self.close() book.Visible=false unlock() end
 local function selectedDetail()
  for _,n in ipairs(detail:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  for _,n in ipairs(info:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local entry=self.entries[self.selected] if not entry then return end
  local species=C[entry.monsterId] local revealed=self.seen[entry.key]==true
  local viewport=make("ViewportFrame",{Name="SelectedPortrait",Position=UDim2.fromScale(.1,.02),Size=UDim2.fromScale(.8,.60),BackgroundTransparency=1,Ambient=Color3.fromRGB(210,215,211),LightColor=Color3.new(1,1,1),ZIndex=44},detail)
  Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
  label(detail,"SelectedName",revealed and T(entry.monsterId) or "???",.04,.63,.92,.16,22)
  label(detail,"SelectedStars",entry.stars.."★",.04,.79,.92,.08,17)
  local income=label(detail,"SelectedIncome",revealed and L.income((species.IncomeAmount or 1)*2^(entry.stars-1),species.IncomeSeconds or 3,player.LocaleId) or "???",.04,.87,.92,.12,20)
  income.TextColor3=Color3.fromRGB(97,255,61)
  label(info,"Acquisition",revealed and (entry.stars==1 and L.huntHint(species.UnlockMeters,species.TameSeconds,player.LocaleId) or L.evolutionHint(entry.stars,player.LocaleId)) or "수집하면 정보가 공개됩니다",.05,.05,.9,.58,16)
  label(info,"Caught",T("Caught").." "..(self.data.caught and self.data.caught[entry.key] or 0),.05,.67,.9,.26,17)
 end
 function self.render()
  for _,n in ipairs(pages:GetChildren()) do if n:IsA("GuiObject") then n:Destroy() end end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) self.page=math.clamp(self.page,1,max)
  self.selected=math.clamp(self.selected,1,math.max(1,#self.entries))
  pageNumber.Text=self.page.." / "..max
  local discovered=0 for _,entry in ipairs(self.entries) do if self.seen[entry.key] then discovered+=1 end end
  summary.Text=T("Unlocked")..": "..discovered.."/"..#self.entries
  progressText.Text=discovered.."/"..#self.entries progressFill.Size=UDim2.fromScale(#self.entries>0 and discovered/#self.entries or 0,1)
  previous.Visible=max>1 nextPage.Visible=max>1
  local colors={Color3.fromRGB(83,181,78),Color3.fromRGB(26,139,232),Color3.fromRGB(203,73,229),Color3.fromRGB(242,190,32)}
  local columns=(compact or #self.entries<=4) and 2 or 4
  for slot=1,self.perSpread do
   local index=(self.page-1)*self.perSpread+slot local entry=self.entries[index] if not entry then break end
   local revealed=self.seen[entry.key]==true
   local rows=math.max(2,math.ceil(math.min(self.perSpread,#self.entries)/columns))
   local card=make("TextButton",{Name="JournalEntry",Text="",Position=UDim2.fromScale(((slot-1)%columns)/columns+.01,math.floor((slot-1)/columns)/rows+.015),Size=UDim2.fromScale(1/columns-.02,1/rows-.03),BackgroundColor3=colors[((slot-1)%4)+1],BorderSizePixel=0,ZIndex=44},pages)
   make("UIStroke",{Color=index==self.selected and Color3.fromRGB(232,250,255) or Color3.new(0,0,0),Thickness=index==self.selected and 3 or 2},card)
   gradient(card,Color3.fromRGB(218,230,235),Color3.fromRGB(50,86,108))
   local viewport=make("ViewportFrame",{Name="JournalPortrait",Position=UDim2.fromScale(.04,.17),Size=UDim2.fromScale(.92,.65),BackgroundTransparency=1,Ambient=Color3.fromRGB(205,213,200),LightColor=Color3.new(1,1,1),ZIndex=45},card)
   Portrait.fill(viewport,entry.monsterId,entry.stars,not revealed,1)
   label(card,"EntryName",revealed and T(entry.monsterId) or "???",.02,.01,.96,.19,17)
   label(card,"Stars",entry.stars.."★",0,.82,1,.18,16)
   card.Activated:Connect(function() self.selected=index self.render() end)
  end
  selectedDetail()
 end
 function self.turn(direction)
  if not book.Visible then return end
  local max=math.max(1,math.ceil(#self.entries/self.perSpread)) local page=math.clamp(self.page+direction,1,max)
  if self.page==page then return end self.page=page self.render() Audio.ui("PageTurn")
 end
 function self.open()
  if self.area=="Hunt" then return end
  if book.Visible then self.close() return end
  if self.onOpen then self.onOpen() end
  book.Visible=true freeze() self.render() Audio.ui("BookOpen")
  if not self.other then remote:FireServer("Journal") end
  CAS:BindActionAtPriority("JournalPages",function(_,state,input)
   if state==Enum.UserInputState.Begin then
    if input.KeyCode==Enum.KeyCode.A or input.KeyCode==Enum.KeyCode.Left then self.turn(-1)
    elseif input.KeyCode==Enum.KeyCode.D or input.KeyCode==Enum.KeyCode.Right then self.turn(1) end
   end
   return Enum.ContextActionResult.Sink
  end,false,3000,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
 end
 function self.viewOther(data) self.other=true self.close() self.snapshot(data) self.open() end
 function self.snapshot(data) self.data=data self.seen=data.seen or self.seen if book.Visible then self.render() end end
 function self.state(data)
  self.area=data.area button.Visible=self.area~="Hunt"
  if self.area=="Hunt" then self.close() end
  if book.Visible and not self.other and data.count~=self.lastCount then remote:FireServer("Journal") end self.lastCount=data.count
 end
 local function resize()
  local camera=workspace.CurrentCamera
  compact=camera and camera.ViewportSize.X<860 or false
  if compact then
   book.Position=UDim2.fromScale(.5,.5) book.Size=UDim2.fromScale(.92,.86)
   region.Visible=false planetTab.Position=UDim2.fromScale(.70,.15) planetTab.Size=UDim2.fromScale(.28,.12)
   pages.Position=UDim2.fromScale(.02,.16) pages.Size=UDim2.fromScale(.65,.52)
   progress.Position=UDim2.fromScale(.02,.71) progress.Size=UDim2.fromScale(.65,.10)
   detail.Position=UDim2.fromScale(.70,.30) detail.Size=UDim2.fromScale(.28,.51)
   info.Visible=false
  else
   book.Position=UDim2.fromScale(.44,.5) book.Size=UDim2.fromScale(.76,.82)
   region.Visible=true planetTab.Position=UDim2.fromScale(1.025,.17) planetTab.Size=UDim2.fromScale(.18,.18)
   pages.Position=UDim2.fromScale(.18,.16) pages.Size=UDim2.fromScale(.50,.53)
   progress.Position=UDim2.fromScale(.18,.72) progress.Size=UDim2.fromScale(.50,.12)
   detail.Position=UDim2.fromScale(.70,.16) detail.Size=UDim2.fromScale(.28,.42) info.Visible=true
  end
  if book.Visible then self.render() end
 end
 -- Decide from screen width, not a size this callback itself changes.
 local function screenLayout()
  resize()
 end
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(screenLayout) end
 task.defer(screenLayout)
 planetTab.Activated:Connect(function() self.page=1 self.render() end)
 previous.Activated:Connect(function() self.turn(-1) end) nextPage.Activated:Connect(function() self.turn(1) end)
 close.Activated:Connect(self.close) button.Activated:Connect(function() self.other=false self.open() end)
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.T and self.area=="Lobby" then self.other=false self.open() end
 end)
 Run.RenderStepped:Connect(function() if book.Visible then freeze() end end)
 return self
end
return J
]========]},
{name="RocketDeparture",parent=game.StarterPlayer.StarterPlayerScripts,kind="LocalScript",before=[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local remote=package:WaitForChild("CaptureRemote")
local Catalog=require(package:WaitForChild("MonsterCatalog"))
local L=require(package:WaitForChild("Localization"))
local function make(class,props,parent)
 local p=Instance.new(class) for key,value in pairs(props) do p[key]=value end p.Parent=parent return p
end
local gui=make("ScreenGui",{Name="RocketDepartureUI",ResetOnSpawn=false,DisplayOrder=40,Enabled=false},player:WaitForChild("PlayerGui"))
local overlay=make("TextButton",{Size=UDim2.fromScale(1,1),Text="",AutoButtonColor=false,Modal=true,BackgroundColor3=Color3.fromRGB(5,14,24),BackgroundTransparency=.15},gui)
local panel=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.94,.9),BackgroundColor3=Color3.fromRGB(17,38,54)},overlay)
make("UISizeConstraint",{MaxSize=Vector2.new(700,600)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local title=make("TextLabel",{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-80,0,40),Text="행성 선택",TextXAlignment=Enum.TextXAlignment.Left,TextSize=24,TextColor3=Color3.fromRGB(220,249,243),Font=Enum.Font.GothamBold,BackgroundTransparency=1},panel)
local close=make("TextButton",{Position=UDim2.new(1,-60,0,8),Size=UDim2.fromOffset(48,48),Text="×",TextSize=30,BackgroundColor3=Color3.fromRGB(35,65,78),TextColor3=Color3.new(1,1,1)},panel)
local hint=make("TextLabel",{Position=UDim2.fromOffset(16,58),Size=UDim2.new(1,-32,0,48),Text="",TextSize=16,TextWrapped=true,BackgroundTransparency=1,TextColor3=Color3.fromRGB(199,222,221)},panel)
local list=make("ScrollingFrame",{Position=UDim2.fromOffset(16,112),Size=UDim2.new(1,-32,1,-232),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=8,BackgroundTransparency=1,BorderSizePixel=0},panel)
local layout=make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},list)
local status=make("TextLabel",{Position=UDim2.new(0,16,1,-112),Size=UDim2.new(1,-32,0,48),Text="",TextWrapped=true,TextSize=16,BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,213,146)},panel)
local nextButton=make("TextButton",{Position=UDim2.new(0,16,1,-60),Size=UDim2.new(1,-32,0,48),Text="다음",TextSize=20,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(10,31,41),BackgroundColor3=Color3.fromRGB(92,216,182)},panel)
local function fit()
 local compact=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<430
 hint.Position=UDim2.fromOffset(16,58)
 hint.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 list.Position=UDim2.fromOffset(16,compact and 96 or 112)
 list.Size=UDim2.new(1,-32,1,compact and -188 or -232)
 status.Position=UDim2.new(0,16,1,compact and -88 or -112)
 status.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 nextButton.Position=UDim2.new(0,16,1,compact and -52 or -60)
 nextButton.Size=UDim2.new(1,-32,0,compact and 44 or 48)
end
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local messages={MenuExpired="선택 시간이 지났어요. 로켓에서 E를 다시 길게 눌러 주세요.",ApproachRocket="로켓 가까이에서 다시 시도해 주세요.",ModelPending="새 몬스터 모델을 연결할 준비 중이에요.",CoursePending="Green Star 사냥터 연결을 준비 중이에요.",MonsterBusy="교배 또는 거래 중인 몬스터는 탈 수 없어요.",NotOwned="가방이 변경됐어요. 로켓에서 다시 선택해 주세요.",LaunchFailed="사냥터 준비에 실패했어요. 다시 시도해 주세요."}
local menu,step,selected,busy=nil,1,nil,false
local rows={}
local function clear()
 for _,row in ipairs(rows) do row:Destroy() end rows={}
end
local function button(text,order,callback)
 local b=make("TextButton",{Size=UDim2.new(1,-8,0,60),Text=text,TextSize=18,TextWrapped=true,Font=Enum.Font.GothamMedium,TextColor3=Color3.fromRGB(229,242,238),BackgroundColor3=Color3.fromRGB(35,69,82),LayoutOrder=order},list)
 make("UICorner",{CornerRadius=UDim.new(0,8)},b)
 b.Activated:Connect(callback) table.insert(rows,b) return b
end
local function hide(cancel)
 if cancel and menu then remote:FireServer("CancelDeparture") end
 gui.Enabled=false menu=nil busy=false clear()
end
local function chooseMonster()
 step=2 selected=nil clear() list.CanvasPosition=Vector2.zero
 title.Text="출발할 몬스터 선택" hint.Text="Green Star · 숲 1,000m\n내 가방의 몬스터를 타고 시작해요."
 nextButton.Text="탑승하고 출발" status.Text="몬스터 한 마리를 선택해 주세요."
 if #menu.items==0 then status.Text="보유 몬스터가 없어요. 무료 1성 모스랫은 새 모델 연결 후 지급됩니다." end
 for index,item in ipairs(menu.items) do
  local id=item.monsterId
  local name=id=="MeadowMouse" and "모스랫" or Catalog[id] and L.text(Catalog[id].Template:gsub("Template$",""),player.LocaleId) or tostring(id)
  local b
  b=button(name.." · "..tostring(item.stars).."성"..(item.ready and "" or " · 준비 중"),index,function()
   if busy then return end
   if not item.ready then status.Text=messages[item.reason] or "현재 선택할 수 없어요." return end
   selected=item.id status.Text=name.."을(를) 타고 출발해요."
   for _,row in ipairs(rows) do row.BackgroundColor3=Color3.fromRGB(35,69,82) end
   b.BackgroundColor3=Color3.fromRGB(47,125,112)
  end)
 end
end
close.Activated:Connect(function() hide(true) end)
nextButton.Activated:Connect(function()
 if not menu or busy then return end
 if step==1 then
  if not selected then status.Text="Green Star를 선택해 주세요." return end
  chooseMonster()
 elseif selected then
  busy=true status.Text="사냥터를 준비하고 있어요…"
  local launchMenu=menu
  remote:FireServer("LaunchSelection",{token=menu.token,planet="GreenStar",itemId=selected})
  task.delay(8,function()
   if gui.Enabled and menu==launchMenu and busy then busy=false status.Text="응답을 기다리고 있어요. 다시 시도하거나 창을 닫아 주세요." end
  end)
 end
end)
UIS.InputBegan:Connect(function(input,processed)
 if not processed and gui.Enabled and input.KeyCode==Enum.KeyCode.Escape then hide(true) end
end)
player.CharacterRemoving:Connect(function() hide(true) end)
remote.OnClientEvent:Connect(function(action,data)
 if action=="DepartureMenu" then
  menu=data step=1 selected=nil busy=false gui.Enabled=true clear() list.CanvasPosition=Vector2.zero
  title.Text="행성 선택" hint.Text="로켓으로 떠날 행성을 선택해 주세요."
  nextButton.Text="다음 · 몬스터 선택" status.Text=""
  local b
  b=button("Green Star\n숲 · 1,000m",1,function() selected="GreenStar" b.BackgroundColor3=Color3.fromRGB(47,125,112) status.Text="Green Star를 선택했어요." end)
 elseif action=="DepartureResult" and gui.Enabled then
  busy=false
  if data.ok then hide(false) else status.Text=messages[data.reason] or "출발할 수 없어요. 다시 선택해 주세요." end
 elseif action=="State" and data.area=="Hunt" then hide(false) end
end)
]========],after=[========[local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local package=RS:WaitForChild("RodeoFantasy")
local remote=package:WaitForChild("CaptureRemote")
local Catalog=require(package:WaitForChild("MonsterCatalog"))
local L=require(package:WaitForChild("Localization"))
local Planets=require(package:WaitForChild("PlanetCatalog"))
local function make(class,props,parent)
 local p=Instance.new(class) for key,value in pairs(props) do p[key]=value end p.Parent=parent return p
end
local gui=make("ScreenGui",{Name="RocketDepartureUI",ResetOnSpawn=false,DisplayOrder=40,Enabled=false},player:WaitForChild("PlayerGui"))
require(script.Parent:WaitForChild("LocalizationController")).watch(gui)
local overlay=make("TextButton",{Size=UDim2.fromScale(1,1),Text="",AutoButtonColor=false,Modal=true,BackgroundColor3=Color3.fromRGB(5,14,24),BackgroundTransparency=.15},gui)
local panel=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.94,.9),BackgroundColor3=Color3.fromRGB(17,38,54)},overlay)
make("UISizeConstraint",{MaxSize=Vector2.new(700,600)},panel)
make("UICorner",{CornerRadius=UDim.new(0,14)},panel)
local title=make("TextLabel",{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-80,0,40),Text="행성 선택",TextXAlignment=Enum.TextXAlignment.Left,TextSize=24,TextColor3=Color3.fromRGB(220,249,243),Font=Enum.Font.GothamBold,BackgroundTransparency=1},panel)
local close=make("TextButton",{Position=UDim2.new(1,-60,0,8),Size=UDim2.fromOffset(48,48),Text="×",TextSize=30,BackgroundColor3=Color3.fromRGB(35,65,78),TextColor3=Color3.new(1,1,1)},panel)
local hint=make("TextLabel",{Position=UDim2.fromOffset(16,58),Size=UDim2.new(1,-32,0,48),Text="",TextSize=16,TextWrapped=true,BackgroundTransparency=1,TextColor3=Color3.fromRGB(199,222,221)},panel)
local list=make("ScrollingFrame",{Position=UDim2.fromOffset(16,112),Size=UDim2.new(1,-32,1,-232),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=8,BackgroundTransparency=1,BorderSizePixel=0},panel)
local layout=make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},list)
local status=make("TextLabel",{Position=UDim2.new(0,16,1,-112),Size=UDim2.new(1,-32,0,48),Text="",TextWrapped=true,TextSize=16,BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,213,146)},panel)
local nextButton=make("TextButton",{Position=UDim2.new(0,16,1,-60),Size=UDim2.new(1,-32,0,48),Text="다음",TextSize=20,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(10,31,41),BackgroundColor3=Color3.fromRGB(92,216,182)},panel)
local function fit()
 local compact=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y<430
 hint.Position=UDim2.fromOffset(16,58)
 hint.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 list.Position=UDim2.fromOffset(16,compact and 96 or 112)
 list.Size=UDim2.new(1,-32,1,compact and -188 or -232)
 status.Position=UDim2.new(0,16,1,compact and -88 or -112)
 status.Size=UDim2.new(1,-32,0,compact and 32 or 48)
 nextButton.Position=UDim2.new(0,16,1,compact and -52 or -60)
 nextButton.Size=UDim2.new(1,-32,0,compact and 44 or 48)
end
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local messages={MenuExpired="선택 시간이 지났어요. 로켓에서 E를 다시 길게 눌러 주세요.",ApproachRocket="로켓 가까이에서 다시 시도해 주세요.",ModelPending="새 몬스터 모델을 연결할 준비 중이에요.",CoursePending="Green Star 사냥터 연결을 준비 중이에요.",MonsterBusy="교배 또는 거래 중인 몬스터는 탈 수 없어요.",NotOwned="가방이 변경됐어요. 로켓에서 다시 선택해 주세요.",LaunchFailed="사냥터 준비에 실패했어요. 다시 시도해 주세요."}
local menu,step,selected,busy=nil,1,nil,false
local rows={}
local function clear()
 for _,row in ipairs(rows) do row:Destroy() end rows={}
end
local function button(text,order,callback)
 local b=make("TextButton",{Size=UDim2.new(1,-8,0,60),Text=text,TextSize=18,TextWrapped=true,Font=Enum.Font.GothamMedium,TextColor3=Color3.fromRGB(229,242,238),BackgroundColor3=Color3.fromRGB(35,69,82),LayoutOrder=order},list)
 make("UICorner",{CornerRadius=UDim.new(0,8)},b)
 b.Activated:Connect(callback) table.insert(rows,b) return b
end
local function hide(cancel)
 if cancel and menu then remote:FireServer("CancelDeparture") end
 gui.Enabled=false menu=nil busy=false clear()
end
local function chooseMonster()
 step=2 selected=nil clear() list.CanvasPosition=Vector2.zero
 title.Text="출발할 몬스터 선택" hint.Text="Green Star · 숲 1,000m\n내 가방의 몬스터를 타고 시작해요."
 nextButton.Text="탑승하고 출발" status.Text="몬스터 한 마리를 선택해 주세요."
 if #menu.items==0 then status.Text="보유 몬스터가 없어요. 무료 1성 모스랫은 새 모델 연결 후 지급됩니다." end
 for index,item in ipairs(menu.items) do
  local id=item.monsterId
  local name=L.text(id,player.LocaleId)
  local b
  b=button(name.." · "..tostring(item.stars).."성"..(item.ready and "" or " · 준비 중"),index,function()
   if busy then return end
   if not item.ready then status.Text=messages[item.reason] or "현재 선택할 수 없어요." return end
   selected=item.id status.Text=name.."을(를) 타고 출발해요."
   for _,row in ipairs(rows) do row.BackgroundColor3=Color3.fromRGB(35,69,82) end
   b.BackgroundColor3=Color3.fromRGB(47,125,112)
  end)
 end
end
close.Activated:Connect(function() hide(true) end)
nextButton.Activated:Connect(function()
 if not menu or busy then return end
 if step==1 then
  if not selected then status.Text="Green Star를 선택해 주세요." return end
  chooseMonster()
 elseif selected then
  busy=true status.Text="사냥터를 준비하고 있어요…"
  local launchMenu=menu
  remote:FireServer("LaunchSelection",{token=menu.token,planet="GreenStar",itemId=selected})
  task.delay(8,function()
   if gui.Enabled and menu==launchMenu and busy then busy=false status.Text="응답을 기다리고 있어요. 다시 시도하거나 창을 닫아 주세요." end
  end)
 end
end)
UIS.InputBegan:Connect(function(input,processed)
 if not processed and gui.Enabled and input.KeyCode==Enum.KeyCode.Escape then hide(true) end
end)
player.CharacterRemoving:Connect(function() hide(true) end)
remote.OnClientEvent:Connect(function(action,data)
 if action=="DepartureMenu" then
  menu=data step=1 selected=nil busy=false gui.Enabled=true clear() list.CanvasPosition=Vector2.zero
  title.Text="행성 선택" hint.Text="로켓으로 떠날 행성을 선택해 주세요."
  nextButton.Text="다음 · 몬스터 선택" status.Text=""
  local b
  b=button("Green Star\n숲 · 1,000m",1,function() selected="GreenStar" b.BackgroundColor3=Color3.fromRGB(47,125,112) status.Text="Green Star를 선택했어요." end)
  b.Size=UDim2.new(1,-8,0,160) b.Text=""
  make("ImageLabel",{Name="GreenStarArtwork",Image=Planets.GreenStar.Image,BackgroundTransparency=1,Position=UDim2.fromScale(.02,.04),Size=UDim2.fromScale(.40,.92),ScaleType=Enum.ScaleType.Fit},b)
  make("TextLabel",{Name="PlanetLabel",Text=L.text("Green Star\n숲 · 1,000m",player.LocaleId),BackgroundTransparency=1,Position=UDim2.fromScale(.44,.1),Size=UDim2.fromScale(.54,.8),TextScaled=true,TextWrapped=true,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1)},b)
 elseif action=="DepartureResult" and gui.Enabled then
  busy=false
  if data.ok then hide(false) else status.Text=messages[data.reason] or "출발할 수 없어요. 다시 선택해 주세요." end
 elseif action=="State" and data.area=="Hunt" then hide(false) end
end)
]========]},
{name="LocalizationController",parent=game.StarterPlayer.StarterPlayerScripts,kind="ModuleScript",before=[========[local C={}
local service=game:GetService("LocalizationService")
local player=game:GetService("Players").LocalPlayer
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local records=setmetatable({},{__mode="k"})
local translator,cache,inflight=nil,{},{}
function C.locale() return player.LocaleId end
function C.text(source)
 local localText=L.text(source,C.locale())
 if localText~=source or string.sub(C.locale(),1,2)=="en" then return localText end
 if cache[source] then return cache[source] end
 if translator and not inflight[source] then
  inflight[source]=true
  task.spawn(function()
   local ok,value=pcall(function() return translator:Translate(workspace,source) end)
   cache[source]=ok and value or source inflight[source]=nil
   for node,record in pairs(records) do if record.source==source and node.Parent then record.apply() end end
  end)
 end
 return source
end
local function bind(node,property)
 local record={source=node[property],busy=false}
 records[node]=record
 function record.apply()
  if record.busy then return end
  record.busy=true
  local rankingRows=node.Name=="Entries" and node.Parent and node.Parent.Name=="Ranking"
  record.applied=(rankingRows and not L.entries[record.source]) and record.source or C.text(record.source)
  node[property]=record.applied record.busy=false
 end
 node:GetPropertyChangedSignal(property):Connect(function()
  if record.busy or node[property]==record.applied then return end
  record.source=node[property] record.apply()
 end)
 record.apply()
end
function C.watch(root)
 local function add(node)
  if node.Name=="LobbyStats" or node.Name=="BagMoney" or node.Name=="Income" or (node.Parent and node.Parent.Parent and node.Parent.Parent.Name=="OwnerBoard") then return end
  if node:IsA("TextLabel") or node:IsA("TextButton") then bind(node,"Text")
  elseif node:IsA("ProximityPrompt") then
   -- Prompt has two independently localized fields.
   node.ActionText=C.text(node.ActionText) node.ObjectText=C.text(node.ObjectText)
  end
 end
 for _,node in ipairs(root:GetDescendants()) do add(node) end
 root.DescendantAdded:Connect(add)
end
local function load()
 translator=nil cache={} inflight={}
 task.spawn(function()
  local ok,value=pcall(function() return service:GetTranslatorForPlayerAsync(player) end)
  if ok then translator=value end
  for _,record in pairs(records) do record.apply() end
 end)
 for _,record in pairs(records) do record.apply() end
end
player:GetPropertyChangedSignal("LocaleId"):Connect(load)
load()
return C
]========],after=[========[local C={}
local service=game:GetService("LocalizationService")
local player=game:GetService("Players").LocalPlayer
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local records=setmetatable({},{__mode="k"})
local translator,cache,inflight=nil,{},{}
function C.locale() return player.LocaleId end
function C.text(source)
 local localText=L.text(source,C.locale())
 if localText~=source or string.sub(C.locale(),1,2)=="en" then return localText end
 if cache[source] then return cache[source] end
 if translator and not inflight[source] then
  inflight[source]=true
  task.spawn(function()
   local ok,value=pcall(function() return translator:Translate(workspace,source) end)
   cache[source]=ok and value or source inflight[source]=nil
   for node,record in pairs(records) do if record.source==source and node.Parent then record.apply() end end
  end)
 end
 return source
end
local function bind(node,property)
 local record={source=node[property],busy=false}
 records[node]=record
 function record.apply()
  if record.busy then return end
  record.busy=true
  local rankingRows=node.Name=="Entries" and node.Parent and (node.Parent.Name=="Ranking" or node.Parent.Name=="RankingBack")
  record.applied=(rankingRows and not L.entries[record.source]) and record.source or C.text(record.source)
  node[property]=record.applied record.busy=false
 end
 node:GetPropertyChangedSignal(property):Connect(function()
  if record.busy or node[property]==record.applied then return end
  record.source=node[property] record.apply()
 end)
 record.apply()
end
function C.watch(root)
 local function add(node)
  if node.Name=="LobbyStats" or node.Name=="BagMoney" or node.Name=="Income" or (node.Parent and node.Parent.Parent and node.Parent.Parent.Name=="OwnerBoard") then return end
  if node:IsA("TextLabel") or node:IsA("TextButton") then bind(node,"Text")
  elseif node:IsA("ProximityPrompt") then
   -- Prompt has two independently localized fields.
   node.ActionText=C.text(node.ActionText) node.ObjectText=C.text(node.ObjectText)
  end
 end
 for _,node in ipairs(root:GetDescendants()) do add(node) end
 root.DescendantAdded:Connect(add)
end
local function load()
 translator=nil cache={} inflight={}
 task.spawn(function()
  local ok,value=pcall(function() return service:GetTranslatorForPlayerAsync(player) end)
  if ok then translator=value end
  for _,record in pairs(records) do record.apply() end
 end)
 for _,record in pairs(records) do record.apply() end
end
player:GetPropertyChangedSignal("LocaleId"):Connect(load)
load()
return C
]========]},
{name="Config",parent=package,kind="ModuleScript",before=[========[-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=40 -- Adjustable presentation tuning for the larger lobby.

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 Wind="rbxassetid://2306939610", -- Creator Store wind; availability requires Studio verification.
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 35, -- Restored original meadow/canyon width.
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
]========],after=[========[-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=40 -- Adjustable presentation tuning for the larger lobby.

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 Wind="rbxassetid://2306939610", -- Creator Store wind; availability requires Studio verification.
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	-- Both clocks begin at the same Riding.started; never after taming finishes.
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 35, -- Restored original meadow/canyon width.
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
]========]},
{name="HuntRules",parent=package,kind="ModuleScript",before=[========[-- Pure rules for continuous riding, airborne lassoing and swept collisions.
local Rules = {}

function Rules.rideSpeed(clock,dashUntil,base,multiplier)
 return base*(dashUntil and clock<dashUntil and multiplier or 1)
end

function Rules.jumpHeight(elapsed, duration, height)
	return math.sin(math.clamp(elapsed / duration, 0, 1) * math.pi) * height
end

-- One ground-to-ground hop. Shared only for synchronized presentation and server motion.
function Rules.buck(elapsed,cycle,height,triple)
 if triple then
  local burst=cycle*2
  local t=math.max(elapsed,0)%burst
  if t>=cycle*1.35 then return 0,0,0 end
  cycle=cycle*.45
  elapsed=t
 end
 local phase=(math.max(elapsed,0)%cycle)/cycle
 local direction=math.floor(math.max(elapsed,0)/cycle)%2==0 and 1 or -1
 return math.sin(math.pi*phase)*height, math.sin(math.pi*phase)*direction, math.sin(math.pi*phase*2)*0.28
end

function Rules.canKnock(size,target,dashing)
 return (size=="Large" and (target=="Small" or target=="Medium"))
  or (size=="Medium" and target=="Small" and dashing==true)
end

function Rules.canBreakObstacle(size,target,dashing)
 return size=="Large" and target=="Small" and dashing==true
end

-- Wooden loot containers are distinct from rocks/trees and need no dash.
function Rules.canBreakCrate(size)
 return size=="Medium" or size=="Large"
end

function Rules.progress(elapsed, duration)
	return math.clamp(elapsed / duration, 0, 1)
end

function Rules.inRange(dx, dz, range)
	return dx == dx and dz == dz and dx * dx + dz * dz <= range * range
end

function Rules.sweptBox(ax, ay, az, bx, by, bz, cx, cy, cz, sx, sy, sz, radius)
	local enter, leave = 0, 1
	local origins, deltas = {ax, ay, az}, {bx-ax, by-ay, bz-az}
	local centers, halves = {cx, cy, cz}, {sx/2+radius, sy/2+radius, sz/2+radius}
	for axis = 1, 3 do
		local low, high = centers[axis]-halves[axis], centers[axis]+halves[axis]
		if math.abs(deltas[axis]) < 0.000001 then
			if origins[axis] < low or origins[axis] > high then return false end
		else
			local first, last = (low-origins[axis])/deltas[axis], (high-origins[axis])/deltas[axis]
			if first > last then first, last = last, first end
			enter, leave = math.max(enter, first), math.min(leave, last)
			if enter > leave then return false end
		end
	end
	return true
end

return Rules
]========],after=[========[-- Pure rules for continuous riding, airborne lassoing and swept collisions.
local Rules = {}

-- Shared elapsed time from landing, independent of whether taming has completed.
function Rules.mountTimeline(elapsed,tameSeconds,warningSeconds,warningDuration)
 return elapsed>=tameSeconds,elapsed>=warningSeconds,elapsed>=warningSeconds+warningDuration
end

function Rules.rideSpeed(clock,dashUntil,base,multiplier)
 return base*(dashUntil and clock<dashUntil and multiplier or 1)
end

function Rules.jumpHeight(elapsed, duration, height)
	return math.sin(math.clamp(elapsed / duration, 0, 1) * math.pi) * height
end

-- One ground-to-ground hop. Shared only for synchronized presentation and server motion.
function Rules.buck(elapsed,cycle,height,triple)
 if triple then
  local burst=cycle*2
  local t=math.max(elapsed,0)%burst
  if t>=cycle*1.35 then return 0,0,0 end
  cycle=cycle*.45
  elapsed=t
 end
 local phase=(math.max(elapsed,0)%cycle)/cycle
 local direction=math.floor(math.max(elapsed,0)/cycle)%2==0 and 1 or -1
 return math.sin(math.pi*phase)*height, math.sin(math.pi*phase)*direction, math.sin(math.pi*phase*2)*0.28
end

function Rules.canKnock(size,target,dashing)
 return (size=="Large" and (target=="Small" or target=="Medium"))
  or (size=="Medium" and target=="Small" and dashing==true)
end

function Rules.canBreakObstacle(size,target,dashing)
 return size=="Large" and target=="Small" and dashing==true
end

-- Wooden loot containers are distinct from rocks/trees and need no dash.
function Rules.canBreakCrate(size)
 return size=="Medium" or size=="Large"
end

function Rules.progress(elapsed, duration)
	return math.clamp(elapsed / duration, 0, 1)
end

function Rules.inRange(dx, dz, range)
	return dx == dx and dz == dz and dx * dx + dz * dz <= range * range
end

function Rules.sweptBox(ax, ay, az, bx, by, bz, cx, cy, cz, sx, sy, sz, radius)
	local enter, leave = 0, 1
	local origins, deltas = {ax, ay, az}, {bx-ax, by-ay, bz-az}
	local centers, halves = {cx, cy, cz}, {sx/2+radius, sy/2+radius, sz/2+radius}
	for axis = 1, 3 do
		local low, high = centers[axis]-halves[axis], centers[axis]+halves[axis]
		if math.abs(deltas[axis]) < 0.000001 then
			if origins[axis] < low or origins[axis] > high then return false end
		else
			local first, last = (low-origins[axis])/deltas[axis], (high-origins[axis])/deltas[axis]
			if first > last then first, last = last, first end
			enter, leave = math.max(enter, first), math.min(leave, last)
			if enter > leave then return false end
		end
	end
	return true
end

return Rules
]========]},
{name="Localization",parent=package,kind="ModuleScript",before=[========[local L={}
L.entries={
 ["Ocean"]={ko="바다",ja="海"},
 ["Swamp"]={ko="늪지",ja="沼地"},
 ["Forest"]={ko="숲",ja="森"},
 ["Total caught"]={ko="총 포획",ja="総捕獲"},
 ["Caught"]={ko="포획 수",ja="捕獲数"},
 ["Found at"]={ko="발견 위치",ja="発見場所"},
 ["Taming (1 star)"]={ko="1성 길들이기",ja="1つ星の捕獲"},
 ["Seconds"]={ko="초",ja="秒"},
 ["Region not released yet"]={ko="아직 공개되지 않은 지역이에요",ja="まだ公開されていない地域です"},
 ["Male"]={ko="수컷",ja="オス"},
 ["Female"]={ko="암컷",ja="メス"},
 ["Unknown sex"]={ko="미확인",ja="不明"},
 ["Collection discoveries"]={ko="도감 수집 랭킹",ja="図鑑収集ランキング"},
 ["Settings"]={ko="설정",ja="設定"},
 ["Sound settings"]={ko="소리 설정",ja="サウンド設定"},
 ["Background music"]={ko="배경 음악",ja="背景音楽"},
 ["Sound effects"]={ko="효과음",ja="効果音"},
 ["Hunting continues while settings are open"]={ko="설정을 열어도 사냥은 계속 진행돼요",ja="設定中も狩りは続きます"},
 ["MeadowMouse"]={ko="모스랫",en="모스랫",ja="모스랫"},
 ["GrassBoar"]={ko="브램블보어",en="브램블보어",ja="브램블보어"},
 ["TreeWolf"]={ko="바인팽",en="바인팽",ja="바인팽"},
 ["RockElephant"]={ko="엘레바인",en="엘레바인",ja="엘레바인"},
 ["Farthest run"]={ko="최장 거리 랭킹",ja="最長距離ランキング"},
 ["Total produced"]={ko="누적 생산액 랭킹",ja="累計生産ランキング"},
 ["Loading records..."]={ko="기록 불러오는 중…",ja="記録を読み込み中…"},
 ["No records yet"]={ko="아직 기록이 없어요",ja="まだ記録がありません"},
 ["Publish to enable rankings"]={ko="게시 후 랭킹을 사용할 수 있어요",ja="公開後にランキングが使えます"},
 ["Records temporarily unavailable"]={ko="기록을 잠시 불러올 수 없어요",ja="記録を一時的に読み込めません"},
 ["Farthest run"]={ko="최장 거리 랭킹",ja="最長距離ランキング"},
 ["Total produced"]={ko="누적 생산액 랭킹",ja="累計生産ランキング"},
 ["No records yet"]={ko="아직 기록이 없어요",ja="まだ記録がありません"},
 ["Publish to enable rankings"]={ko="게시 후 랭킹을 사용할 수 있어요",ja="公開後にランキングが使えます"},
 ["Records temporarily unavailable"]={ko="기록을 잠시 불러올 수 없어요",ja="記録を一時的に読み込めません"},
 ["Manage ranch"]={ko="목장 관리",ja="牧場を管理"},
 ["Choose ranch"]={ko="관리할 목장 선택",ja="管理する牧場を選ぶ"},
 ["Weedcrow"]={ko="쏜크로",en="쏜크로",ja="쏜크로"},
 ["Monster tamed! Added to your bag."]={ko="길들이기 성공! 가방에 추가됐어요.",ja="仲間にしました！バッグに追加。"},
 ["Place monsters"]={ko="몬스터 배치",ja="モンスターを配置"},
 ["Ranch"]={ko="목장",ja="牧場"},
 ["Place"]={ko="배치",ja="配置"},
 ["Return to bag"]={ko="가방으로 돌려놓기",ja="バッグに戻す"},
 ["Placed"]={ko="배치됨",ja="配置済み"},
 ["Full"]={ko="가득 참",ja="満員"},
 ["This server holds up to 8 players."]={ko="이 서버는 8명까지 입장할 수 있어요.",ja="このサーバーは8人までです。"},
 ["Start hunt"]={ko="사냥 시작",ja="狩りを始める"},
 ["Hunt again"]={ko="다시 사냥하기",ja="もう一度狩る"},
 ["Return to lobby"]={ko="로비로 돌아가기",ja="ロビーに戻る"},
 ["Jump / Lasso"]={ko="점프 / 줄",ja="ジャンプ / ロープ"},
 ["Hunt ended"]={ko="사냥 종료",ja="狩り終了"},
 ["Next region coming soon"]={ko="다음 지역 준비 중",ja="次のエリアは準備中"},
 ["You hit an obstacle."]={ko="장애물에 부딪혔어요.",ja="障害物にぶつかりました。"},
 ["You missed the next monster."]={ko="다음 몬스터를 잡지 못했어요.",ja="次のモンスターをつかめませんでした。"},
 ["You lost your mount."]={ko="몬스터를 놓쳤어요.",ja="乗っていたモンスターを失いました。"},
 ["This monster cannot break crates."]={ko="상자를 부술 수 없는 몬스터예요.",ja="このモンスターは木箱を壊せません。"},
 ["You hit a wall."]={ko="벽에 부딪혔어요.",ja="壁にぶつかりました。"},
 ["You hit another monster."]={ko="다른 몬스터에 부딪혔어요.",ja="別のモンスターにぶつかりました。"},
 ["Welcome back to the lobby."]={ko="로비로 돌아왔어요.",ja="ロビーに戻りました。"},
 ["Approach the airship to start."]={ko="비행장에서 사냥터로 출발하세요.",ja="飛行船に近づくと出発します。"},
 ["Lumidon tamed! Added to your bag."]={ko="루미돈 길들이기 성공! 가방에 추가됐어요.",ja="ルミドンを仲間にしました！バッグに追加。"},
 ["Lumidon"]={ko="루미돈",ja="ルミドン"},
 ["Angry! Press Space to jump!"]={ko="화났어요! 스페이스바로 점프하세요!",ja="怒っています！スペースでジャンプ！"},
 ["Tamed · Keep riding"]={ko="길들이기 성공 · 계속 타고 달리세요",ja="仲間になった · そのまま走ろう"},
 ["Taming Lumidon ♥"]={ko="루미돈 길들이는 중 ♥",ja="ルミドンを仲間にしています ♥"},
 ["A/D to steer · Space to jump / again to lasso"]={ko="A·D로 좌우 이동 · 스페이스바로 점프 / 공중에서 다시 누르면 줄",ja="A/Dで左右 · スペースでジャンプ / 空中でもう一度ロープ"},
 ["Press Space to catch the next monster!"]={ko="스페이스바로 다음 몬스터를 잡으세요!",ja="スペースで次のモンスターをつかもう！"},
 ["Lasso a monster inside the yellow ring"]={ko="노란 원 안에 몬스터가 들어오면 줄이 연결됩니다",ja="黄色い輪の中のモンスターにロープを投げよう"},
 ["Flying to your next mount…"]={ko="날아가서 탑승하는 중…",ja="次のモンスターに飛び乗っています…"},
 ["Keep riding after landing"]={ko="탑승 후 계속 타고 달릴 수 있어요",ja="着地後も乗り続けられます"},
 ["1,000m · Next region coming soon"]={ko="1,000m · 다음 지역 준비 중",ja="1,000m · 次のエリアは準備中"},
 ["Meadow complete · Start again or return"]={ko="초원 시험 구간이 끝났어요 · 사냥 시작으로 다시 달릴 수 있어요",ja="草原クリア · 再挑戦またはロビーへ"},
 ["Try again · Your bag income is kept"]={ko="다시 사냥하기로 재도전 · 가방 수익은 유지",ja="再挑戦 · バッグの収入は残ります"},
 ["Bag"]={ko="가방",ja="バッグ"},
 ["Close"]={ko="닫기",ja="閉じる"},
 ["No monsters caught yet"]={ko="아직 포획한 몬스터가 없어요",ja="まだモンスターがいません"},
 ["Uncollected coins"]={ko="모인 돈",ja="未受取コイン"},
 ["Shop · Coming soon"]={ko="상점 · 준비 중",ja="ショップ · 準備中"},
 ["Hunting grounds"]={ko="사냥터",ja="狩りエリア"},
 ["Airship"]={ko="비행선",ja="飛行船"},
 ["Fly to hunt"]={ko="사냥터로 출발",ja="狩りに出発"},
 ["All"]={ko="전체",ja="すべて"},
 ["Meadow"]={ko="초원",ja="草原"},
 ["Breeding"]={ko="배합",ja="交配"},
 ["Search monsters"]={ko="몬스터 검색",ja="モンスターを検索"},
 ["No matching monsters"]={ko="검색 결과가 없어요",ja="該当するモンスターがいません"},
 ["Field journal"]={ko="몬스터 도감",ja="モンスター図鑑"},
 ["Explorer's field journal"]={ko="탐험가의 몬스터 도감",ja="探検家のモンスター図鑑"},
 ["Discovered"]={ko="발견",ja="発見"},
 ["Hover an entry for field notes"]={ko="몬스터에 커서를 올리면 획득 방법을 볼 수 있어요",ja="モンスターにカーソルを合わせると入手方法を表示"},
 ["No entries here yet"]={ko="아직 등록된 몬스터가 없는 분류예요",ja="この分類にはまだ項目がありません"},
 ["Breeding details not announced yet"]={ko="배합 방법은 아직 공개되지 않았어요",ja="交配方法はまだ公開されていません"},
 ["Evolve"]={ko="진화",ja="進化",en="Evolve"},
 ["Cancel"]={ko="취소",ja="キャンセル",en="Cancel"},
 ["Select"]={ko="선택",ja="選択",en="Select"},
 ["Selected"]={ko="선택됨",ja="選択済み",en="Selected"},
 ["Select three matching monsters"]={ko="같은 종류·같은 별 3마리를 선택하세요",ja="同種・同じ星の3匹を選んでください",en="Select three matching monsters"},
 ["Evolution failed"]={ko="진화할 수 없어요. 가방을 새로 확인해 주세요.",ja="進化できません。バッグを確認してください。",en="Evolution failed. Refresh your bag and try again."},
 ["Already at max stars"]={ko="10성이 된 몬스터는 더 진화할 수 없어요.",ja="10星のモンスターは進化できません。",en="A 10-star monster cannot evolve further."},
 ["Loading progress"]={ko="기록을 불러오는 중",ja="記録を読み込み中"},
 ["Progress saved"]={ko="기록 저장됨",ja="記録を保存済み"},
 ["Progress loaded"]={ko="기록 불러옴",ja="記録を読み込み済み"},
 ["Session progress"]={ko="이번 접속의 기록",ja="今回の記録"},
 ["Progress temporarily unavailable"]={ko="기록 저장 연결을 기다리는 중",ja="記録の接続待ち"},
}
function L.text(source,locale)
 local lang=string.lower(string.sub(locale or "en",1,2))
 local row=L.entries[source]
 return row and (row[lang] or row.en) or source
end
function L.stats(count,money,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "가방: %d마리 · 모인 돈: %d" or lang=="ja" and "バッグ: %d匹 · 未受取コイン: %d" or "Bag: %d · Uncollected coins: %d"
 return string.format(pattern,count,money)
end
function L.income(amount,seconds,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "%s초마다 %s코인" or lang=="ja" and "%s秒ごとに%sコイン" or (amount==1 and "%s coin every %ss" or "%s coins every %ss")
 if lang=="ko" or lang=="ja" then return string.format(pattern,tostring(seconds),tostring(amount)) end
 return string.format(pattern,tostring(amount),tostring(seconds))
end
function L.levelLabel(level,current,required,locale)
 local lang=string.sub(locale or "en",1,2)
 local name=lang=="ko" and "레벨" or lang=="ja" and "レベル" or "Lv."
 return name.." "..level..(required==0 and " · MAX" or " · "..current.."/"..required.." XP")
end
function L.huntHint(meters,seconds,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "초원 %dm부터 등장. 점프 후 다시 Space로 줄을 던지고 %d초 동안 타세요." or lang=="ja" and "草原%dmから出現。ジャンプ後Spaceで投げ縄を使い、%d秒乗り続けよう。" or "Found in the meadow from %dm. Jump, press Space again to lasso, then ride for %ds."
 return string.format(pattern,meters,seconds)
end
function L.evolutionHint(stars,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "가방에서 같은 종류·같은 별 3마리를 선택해 %d성으로 진화시키세요." or lang=="ja" and "バッグで同種・同じ星の3匹を選び、%d星に進化させよう。" or "Select three of the same species and star in your bag to evolve to %d stars."
 return string.format(pattern,stars)
end
return L
]========],after=[========[local L={}
L.entries={
 ["교감 E"]={en="Bond E",ko="교감 E"},
 ["교감"]={en="Bond",ko="교감"},
 ["펫 인덱스"]={en="Pet Index",ko="펫 인덱스"},
 ["초원"]={en="Meadow",ko="초원"},
 ["행성\nGreen Star"]={en="Planet\nGreen Star",ko="행성\nGreen Star"},
 ["수집하면 정보가 공개됩니다"]={en="Collect to reveal details",ko="수집하면 정보가 공개됩니다"},
 ["Unlocked"]={ko="잠금 해제"},
 ["행성 선택"]={en="Select Planet",ko="행성 선택"},
 ["출발할 몬스터 선택"]={en="Choose Your Mount",ko="출발할 몬스터 선택"},
 ["로켓으로 떠날 행성을 선택해 주세요."]={en="Choose a planet to visit.",ko="로켓으로 떠날 행성을 선택해 주세요."},
 ["다음"]={en="Next",ko="다음"},
 ["다음 · 몬스터 선택"]={en="Next · Choose Mount",ko="다음 · 몬스터 선택"},
 ["탑승하고 출발"]={en="Mount and Depart",ko="탑승하고 출발"},
 ["몬스터 한 마리를 선택해 주세요."]={en="Select one of your monsters.",ko="몬스터 한 마리를 선택해 주세요."},
 ["Green Star를 선택해 주세요."]={en="Please select Green Star.",ko="Green Star를 선택해 주세요."},
 ["Green Star를 선택했어요."]={en="Green Star selected.",ko="Green Star를 선택했어요."},
 ["Green Star\n숲 · 1,000m"]={en="Green Star\nForest · 1,000m",ko="Green Star\n숲 · 1,000m"},
 ["Green Star · 숲 1,000m\n내 가방의 몬스터를 타고 시작해요."]={en="Green Star · Forest 1,000m\nStart riding a monster from your bag.",ko="Green Star · 숲 1,000m\n내 가방의 몬스터를 타고 시작해요."},
 ["사냥터를 준비하고 있어요…"]={en="Preparing the hunt…",ko="사냥터를 준비하고 있어요…"},
 ["Green Star · Distance Top 10"]={ko="Green Star · 거리 랭킹 TOP 10"},
 ["도감 수집"]={en="Collection",ko="도감 수집"},
 ["Ocean"]={ko="바다",ja="海"},
 ["Swamp"]={ko="늪지",ja="沼地"},
 ["Forest"]={ko="숲",ja="森"},
 ["Total caught"]={ko="총 포획",ja="総捕獲"},
 ["Caught"]={ko="포획 수",ja="捕獲数"},
 ["Found at"]={ko="발견 위치",ja="発見場所"},
 ["Taming (1 star)"]={ko="1성 길들이기",ja="1つ星の捕獲"},
 ["Seconds"]={ko="초",ja="秒"},
 ["Region not released yet"]={ko="아직 공개되지 않은 지역이에요",ja="まだ公開されていない地域です"},
 ["Male"]={ko="수컷",ja="オス"},
 ["Female"]={ko="암컷",ja="メス"},
 ["Unknown sex"]={ko="미확인",ja="不明"},
 ["Collection discoveries"]={ko="도감 수집 랭킹",ja="図鑑収集ランキング"},
 ["Settings"]={ko="설정",ja="設定"},
 ["Sound settings"]={ko="소리 설정",ja="サウンド設定"},
 ["Background music"]={ko="배경 음악",ja="背景音楽"},
 ["Sound effects"]={ko="효과음",ja="効果音"},
 ["Hunting continues while settings are open"]={ko="설정을 열어도 사냥은 계속 진행돼요",ja="設定中も狩りは続きます"},
 ["MeadowMouse"]={ko="모스랫",en="Mossrat",ja="모스랫"},
 ["GrassBoar"]={ko="브램블보어",en="브램블보어",ja="브램블보어"},
 ["TreeWolf"]={ko="바인팽",en="바인팽",ja="바인팽"},
 ["RockElephant"]={ko="엘레바인",en="엘레바인",ja="엘레바인"},
 ["Farthest run"]={ko="최장 거리 랭킹",ja="最長距離ランキング"},
 ["Total produced"]={ko="누적 생산액 랭킹",ja="累計生産ランキング"},
 ["Loading records..."]={ko="기록 불러오는 중…",ja="記録を読み込み中…"},
 ["No records yet"]={ko="아직 기록이 없어요",ja="まだ記録がありません"},
 ["Publish to enable rankings"]={ko="게시 후 랭킹을 사용할 수 있어요",ja="公開後にランキングが使えます"},
 ["Records temporarily unavailable"]={ko="기록을 잠시 불러올 수 없어요",ja="記録を一時的に読み込めません"},
 ["Farthest run"]={ko="최장 거리 랭킹",ja="最長距離ランキング"},
 ["Total produced"]={ko="누적 생산액 랭킹",ja="累計生産ランキング"},
 ["No records yet"]={ko="아직 기록이 없어요",ja="まだ記録がありません"},
 ["Publish to enable rankings"]={ko="게시 후 랭킹을 사용할 수 있어요",ja="公開後にランキングが使えます"},
 ["Records temporarily unavailable"]={ko="기록을 잠시 불러올 수 없어요",ja="記録を一時的に読み込めません"},
 ["Manage ranch"]={ko="목장 관리",ja="牧場を管理"},
 ["Choose ranch"]={ko="관리할 목장 선택",ja="管理する牧場を選ぶ"},
 ["Weedcrow"]={ko="쏜크로",en="쏜크로",ja="쏜크로"},
 ["Monster tamed! Added to your bag."]={ko="길들이기 성공! 가방에 추가됐어요.",ja="仲間にしました！バッグに追加。"},
 ["Place monsters"]={ko="몬스터 배치",ja="モンスターを配置"},
 ["Ranch"]={ko="목장",ja="牧場"},
 ["Place"]={ko="배치",ja="配置"},
 ["Return to bag"]={ko="가방으로 돌려놓기",ja="バッグに戻す"},
 ["Placed"]={ko="배치됨",ja="配置済み"},
 ["Full"]={ko="가득 참",ja="満員"},
 ["This server holds up to 8 players."]={ko="이 서버는 8명까지 입장할 수 있어요.",ja="このサーバーは8人までです。"},
 ["Start hunt"]={ko="사냥 시작",ja="狩りを始める"},
 ["Hunt again"]={ko="다시 사냥하기",ja="もう一度狩る"},
 ["Return to lobby"]={ko="로비로 돌아가기",ja="ロビーに戻る"},
 ["Jump / Lasso"]={ko="점프 / 줄",ja="ジャンプ / ロープ"},
 ["Hunt ended"]={ko="사냥 종료",ja="狩り終了"},
 ["Next region coming soon"]={ko="다음 지역 준비 중",ja="次のエリアは準備中"},
 ["You hit an obstacle."]={ko="장애물에 부딪혔어요.",ja="障害物にぶつかりました。"},
 ["You missed the next monster."]={ko="다음 몬스터를 잡지 못했어요.",ja="次のモンスターをつかめませんでした。"},
 ["You lost your mount."]={ko="몬스터를 놓쳤어요.",ja="乗っていたモンスターを失いました。"},
 ["This monster cannot break crates."]={ko="상자를 부술 수 없는 몬스터예요.",ja="このモンスターは木箱を壊せません。"},
 ["You hit a wall."]={ko="벽에 부딪혔어요.",ja="壁にぶつかりました。"},
 ["You hit another monster."]={ko="다른 몬스터에 부딪혔어요.",ja="別のモンスターにぶつかりました。"},
 ["Welcome back to the lobby."]={ko="로비로 돌아왔어요.",ja="ロビーに戻りました。"},
 ["Approach the airship to start."]={ko="비행장에서 사냥터로 출발하세요.",ja="飛行船に近づくと出発します。"},
 ["Lumidon tamed! Added to your bag."]={ko="루미돈 길들이기 성공! 가방에 추가됐어요.",ja="ルミドンを仲間にしました！バッグに追加。"},
 ["Lumidon"]={ko="루미돈",ja="ルミドン"},
 ["Angry! Press Space to jump!"]={ko="화났어요! 스페이스바로 점프하세요!",ja="怒っています！スペースでジャンプ！"},
 ["Tamed · Keep riding"]={ko="길들이기 성공 · 계속 타고 달리세요",ja="仲間になった · そのまま走ろう"},
 ["Taming Lumidon ♥"]={ko="루미돈 길들이는 중 ♥",ja="ルミドンを仲間にしています ♥"},
 ["A/D to steer · Space to jump / again to lasso"]={ko="A·D로 좌우 이동 · 스페이스바로 점프 / 공중에서 다시 누르면 줄",ja="A/Dで左右 · スペースでジャンプ / 空中でもう一度ロープ"},
 ["Press Space to catch the next monster!"]={ko="스페이스바로 다음 몬스터를 잡으세요!",ja="スペースで次のモンスターをつかもう！"},
 ["Lasso a monster inside the yellow ring"]={ko="노란 원 안에 몬스터가 들어오면 줄이 연결됩니다",ja="黄色い輪の中のモンスターにロープを投げよう"},
 ["Flying to your next mount…"]={ko="날아가서 탑승하는 중…",ja="次のモンスターに飛び乗っています…"},
 ["Keep riding after landing"]={ko="탑승 후 계속 타고 달릴 수 있어요",ja="着地後も乗り続けられます"},
 ["1,000m · Next region coming soon"]={ko="1,000m · 다음 지역 준비 중",ja="1,000m · 次のエリアは準備中"},
 ["Meadow complete · Start again or return"]={ko="초원 시험 구간이 끝났어요 · 사냥 시작으로 다시 달릴 수 있어요",ja="草原クリア · 再挑戦またはロビーへ"},
 ["Try again · Your bag income is kept"]={ko="다시 사냥하기로 재도전 · 가방 수익은 유지",ja="再挑戦 · バッグの収入は残ります"},
 ["Bag"]={ko="가방",ja="バッグ"},
 ["Close"]={ko="닫기",ja="閉じる"},
 ["No monsters caught yet"]={ko="아직 포획한 몬스터가 없어요",ja="まだモンスターがいません"},
 ["Uncollected coins"]={ko="모인 돈",ja="未受取コイン"},
 ["Shop · Coming soon"]={ko="상점 · 준비 중",ja="ショップ · 準備中"},
 ["Hunting grounds"]={ko="사냥터",ja="狩りエリア"},
 ["Airship"]={ko="비행선",ja="飛行船"},
 ["Fly to hunt"]={ko="사냥터로 출발",ja="狩りに出発"},
 ["All"]={ko="전체",ja="すべて"},
 ["Meadow"]={ko="초원",ja="草原"},
 ["Breeding"]={ko="배합",ja="交配"},
 ["Search monsters"]={ko="몬스터 검색",ja="モンスターを検索"},
 ["No matching monsters"]={ko="검색 결과가 없어요",ja="該当するモンスターがいません"},
 ["Field journal"]={ko="몬스터 도감",ja="モンスター図鑑"},
 ["Explorer's field journal"]={ko="탐험가의 몬스터 도감",ja="探検家のモンスター図鑑"},
 ["Discovered"]={ko="발견",ja="発見"},
 ["Hover an entry for field notes"]={ko="몬스터에 커서를 올리면 획득 방법을 볼 수 있어요",ja="モンスターにカーソルを合わせると入手方法を表示"},
 ["No entries here yet"]={ko="아직 등록된 몬스터가 없는 분류예요",ja="この分類にはまだ項目がありません"},
 ["Breeding details not announced yet"]={ko="배합 방법은 아직 공개되지 않았어요",ja="交配方法はまだ公開されていません"},
 ["Evolve"]={ko="진화",ja="進化",en="Evolve"},
 ["Cancel"]={ko="취소",ja="キャンセル",en="Cancel"},
 ["Select"]={ko="선택",ja="選択",en="Select"},
 ["Selected"]={ko="선택됨",ja="選択済み",en="Selected"},
 ["Select three matching monsters"]={ko="같은 종류·같은 별 3마리를 선택하세요",ja="同種・同じ星の3匹を選んでください",en="Select three matching monsters"},
 ["Evolution failed"]={ko="진화할 수 없어요. 가방을 새로 확인해 주세요.",ja="進化できません。バッグを確認してください。",en="Evolution failed. Refresh your bag and try again."},
 ["Already at max stars"]={ko="10성이 된 몬스터는 더 진화할 수 없어요.",ja="10星のモンスターは進化できません。",en="A 10-star monster cannot evolve further."},
 ["Loading progress"]={ko="기록을 불러오는 중",ja="記録を読み込み中"},
 ["Progress saved"]={ko="기록 저장됨",ja="記録を保存済み"},
 ["Progress loaded"]={ko="기록 불러옴",ja="記録を読み込み済み"},
 ["Session progress"]={ko="이번 접속의 기록",ja="今回の記録"},
 ["Progress temporarily unavailable"]={ko="기록 저장 연결을 기다리는 중",ja="記録の接続待ち"},
}
function L.text(source,locale)
 local lang=string.lower(string.sub(locale or "en",1,2))
 local row=L.entries[source]
 return row and (row[lang] or row.en) or source
end
function L.stats(count,money,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "가방: %d마리 · 모인 돈: %d" or lang=="ja" and "バッグ: %d匹 · 未受取コイン: %d" or "Bag: %d · Uncollected coins: %d"
 return string.format(pattern,count,money)
end
function L.income(amount,seconds,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "%s초마다 %s코인" or lang=="ja" and "%s秒ごとに%sコイン" or (amount==1 and "%s coin every %ss" or "%s coins every %ss")
 if lang=="ko" or lang=="ja" then return string.format(pattern,tostring(seconds),tostring(amount)) end
 return string.format(pattern,tostring(amount),tostring(seconds))
end
function L.levelLabel(level,current,required,locale)
 local lang=string.sub(locale or "en",1,2)
 local name=lang=="ko" and "레벨" or lang=="ja" and "レベル" or "Lv."
 return name.." "..level..(required==0 and " · MAX" or " · "..current.."/"..required.." XP")
end
function L.huntHint(meters,seconds,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "초원 %dm부터 등장. 점프 후 다시 Space로 줄을 던지고 %d초 동안 타세요." or lang=="ja" and "草原%dmから出現。ジャンプ後Spaceで投げ縄を使い、%d秒乗り続けよう。" or "Found in the meadow from %dm. Jump, press Space again to lasso, then ride for %ds."
 return string.format(pattern,meters,seconds)
end
function L.evolutionHint(stars,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "가방에서 같은 종류·같은 별 3마리를 선택해 %d성으로 진화시키세요." or lang=="ja" and "バッグで同種・同じ星の3匹を選び、%d星に進化させよう。" or "Select three of the same species and star in your bag to evolve to %d stars."
 return string.format(pattern,stars)
end
return L
]========]},
{name="RecordRules",parent=package,kind="ModuleScript",before=[========[-- Idempotent session checkpoints prevent double counting after an uncertain save reply.
local Rules={}
function Rules.merge(old,sessionId,produced,bestDistance,timestamp)
 old=type(old)=="table" and old or {}
 local sessions={}
 for id,entry in pairs(old.sessions or {}) do
  if entry.time>timestamp-30*86400 then sessions[id]={amount=entry.amount,time=entry.time} end
 end
 local previous=sessions[sessionId] and sessions[sessionId].amount or 0
 local increment=math.max(0,math.floor(produced)-previous)
 sessions[sessionId]={amount=math.max(previous,math.floor(produced)),time=timestamp}
 return {income=(old.income or 0)+increment,distance=math.max(old.distance or 0,math.floor(bestDistance)),sessions=sessions}
end
return Rules
]========],after=[========[-- Idempotent session checkpoints prevent double counting after an uncertain save reply.
local Rules={}
function Rules.merge(old,sessionId,produced,bestDistance,timestamp)
 old=type(old)=="table" and old or {}
 local sessions={}
 for id,entry in pairs(old.sessions or {}) do
  if entry.time>timestamp-30*86400 then sessions[id]={amount=entry.amount,time=entry.time} end
 end
 local previous=sessions[sessionId] and sessions[sessionId].amount or 0
 local increment=math.max(0,math.floor(produced)-previous)
 sessions[sessionId]={amount=math.max(previous,math.floor(produced)),time=timestamp}
 return {income=(old.income or 0)+increment,distance=math.max(old.distance or 0,math.floor(bestDistance)),sessions=sessions}
end
function Rules.mergePlanets(old,sessionId,produced,bestDistance,distances,timestamp)
 local result=Rules.merge(old,sessionId,produced,bestDistance,timestamp)
 result.planetDistances={}
 for id,value in pairs(type(old)=="table" and old.planetDistances or {}) do result.planetDistances[id]=value end
 -- All legacy runs used Green Star; retain them in that category.
 if type(old)=="table" and not old.planetDistances then result.planetDistances.GreenStar=math.max(result.planetDistances.GreenStar or 0,old.distance or 0) end
 for id,value in pairs(distances) do result.planetDistances[id]=math.max(result.planetDistances[id] or 0,math.floor(value)) end
 return result
end
return Rules
]========]},
{name="PlanetCatalog",parent=package,kind="ModuleScript",before=[========[]========],after=[========[-- Only released/confirmed destinations are listed here.
local P={Order={"GreenStar"},GreenStar={Name="Green Star",Image="rbxassetid://78730064656056",LengthMeters=1000}}
return P
]========]},
}
local function normal(s) return s:gsub("\r\n","\n") end
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name)
 if c.node then assert(normal(c.node.Source)==normal(c.before) or normal(c.node.Source)==normal(c.after),"코드 불일치: "..c.name)
 else assert(c.before=="","코드 없음: "..c.name) end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before companion polish")
local backup=Instance.new("Folder") backup.Name="CompanionPolishBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do
 if c.node then c.node:Clone().Parent=backup else c.node=Instance.new(c.kind) c.node.Name=c.name c.node.Parent=c.parent end
 c.node.Source=c.after
end
-- The prior effect is retained in the reversible backup.
local aura=workspace.RodeoLobby:FindFirstChild("PlanetAura") if aura then aura.Parent=backup end
local appearance=(function()
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

end)()
appearance.ensure(workspace.RodeoLobby)
package:SetAttribute("GreenStarImage","rbxassetid://78730064656056")
workspace.RodeoLobby.Leaderboards.Distance.Ranking.Heading.Text="Green Star · Distance Top 10"
workspace.RodeoLobby.Leaderboards.Distance.RankingBack.Heading.Text="Green Star · Distance Top 10"
for _,p in ipairs(game.Players:GetPlayers()) do local h=p.Character and p.Character:FindFirstChild("AstronautHelmet") if h then h.Parent=backup end end
game:GetService("ChangeHistoryService"):SetWaypoint("Companion polish installed")
print("COMPANION_POLISH_INSTALLED")
end
