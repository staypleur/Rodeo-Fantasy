assert(not game:GetService("RunService"):IsRunning(),"■ 정지 후 실행하세요.")
local server=game:GetService("ServerScriptService")
local storage=game:GetService("ServerStorage")
local package=game:GetService("ReplicatedStorage").RodeoFantasy
local updates={}
updates[#updates+1]={node=assert(server:FindFirstChild("CaptureServer"),"Missing CaptureServer"),source=[====[local Players=game:GetService("Players")
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
local states,bags,limits,views={},{},{},{}
local worlds,worldRoots={},{}
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
 if state then for model in pairs(worlds[player].visibleSet(state.root.Position.Z,views[player],player)) do table.insert(wildIds,model:GetAttribute("SpawnSerial")) end end
 remote:FireClient(player,"State",{huntRoot=worldRoots[player],initialLanding=state and state.initialLanding,income=not state and gains or nil,progress=Progress.snapshot(player),wildIds=wildIds,phase=state and state.phase or "Idle",area=state and "Hunt" or "Lobby",started=state and state.started or now(),distance=state and state.distance or 0,tameSeconds=state and state.monster and Catalog[state.monster:GetAttribute("MonsterId")].TameSeconds or 5,monster=state and state.monster,previousMonster=state and state.previousMonster,tamed=state and state.tamed or false,angerAt=state and state.angerAt,count=#bag.monsters,pending=bag.pending,balance=bag.balance,message=message,endReason=state and state.endReason,crash=state and state.crash,monsterCrashFrame=state and state.monsterCrashFrame,monsterCrashId=state and state.monsterCrashId,sampleTime=now(),position=state and state.root.Position,origin=state and state.origin,launchY=state and state.launchY,landingSeconds=state and state.landingSeconds,steer=state and state.steer or 0,dashUntil=state and state.dashUntil,baseSpeed=baseSpeed(state)})
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
require(script.Parent:WaitForChild("OperatorCommands")).register(Catalog,remote,function(player,id,stars,count)
 local bag=bags[player]
 if not bag or states[player] or Store.busy(player) or Social.trading(player) then return false end
 local species=Catalog[id]
 for _=1,count do
  BagRules.grant(bag,id,now(),species.IncomeSeconds,species.IncomeAmount)
  bag.monsters[#bag.monsters].stars=stars
 end
 send(player,"운영자 명령어로 몬스터를 가방에 추가했습니다.")
 sendBag(player)
 return true
end)
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
  state.monster.PrimaryPart.CFrame=CFrame.new(p.X,state.monster:GetAttribute("RootHeight") or 2,p.Z)
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
  return nextWorld.spawn(Vector3.new(0,2,-8))
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
 states[player]={phase="Lassoing",started=now(),landingSeconds=tuning.IntroSeconds,initialLanding=true,monster=model,root=root,humanoid=humanoid,wasAnchored=root.Anchored,autoRotate=humanoid.AutoRotate,platformStand=humanoid.PlatformStand,steer=0,steerAt=now(),distance=0,tamed=false}
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
Social.start(bags,function(p) return bags[p] and not states[p] and not p:GetAttribute("Travelling") end,sendBag)
Lobby.connect(function(p) if not Store.busy(p) and not p:GetAttribute("Travelling") then start(p) end end)
Lobby.connectPens(function(player)
 if not states[player] then sendBag(player) remote:FireClient(player,"RanchMenu") end
end)
remote.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or not bags[player] or Store.busy(player) or player:GetAttribute("Travelling") then return end
 if action~="Sync" and action~="Start" and action~="Jump" and action~="Steer" and action~="View" and action~="ReturnLobby" and action~="Bag" and action~="Manage" and action~="Place" and action~="Remove" and action~="Evolve" and action~="Journal" and action~="PlaceEgg" and action~="RemoveEgg" then return end
 local stamps=limits[player]
 if not stamps then stamps={} limits[player]=stamps end
 -- Ignore key-repeat bursts; capture transitions are always server-authoritative.
 local interval=action=="Jump" and 0.08 or action=="Steer" and 0.04 or 0.25
 if now()-(stamps[action] or -math.huge)<interval then return end
 stamps[action]=now()
 if action=="View" then
  if type(value)=="number" and value==value and value>=0.4 and value<=4 then views[player]=value end
  return
 end
 if action=="Manage" then
  if not states[player] and Lobby.canUsePen(player,value) then remote:FireClient(player,"Eggs",{pen=value,eggs=bags[player].eggs or {}}) end
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
  if state and (state.phase=="GameOver" or state.phase=="CourseEnd") then
   finish(player,"Welcome back to the lobby.")
   restoreAvatar(state)
   state.root.CFrame=Lobby.Spawn
   setCharacterGroup(player,"Default")
   Lobby.prepareCharacter(player.Character)
   states[player]=nil send(player) sendBag(player)
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
    state.monster.PrimaryPart.CFrame=CFrame.new(p.X,state.monster:GetAttribute("RootHeight") or 2,p.Z)
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
   state.monster.PrimaryPart.CFrame=CFrame.new(p.X,state.monster:GetAttribute("RootHeight") or 2,p.Z-(state.initialLanding and 0 or baseSpeed(state)*dt))
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
   position=Vector3.new(position.X,(state.monster:GetAttribute("RootHeight") or 2)+buckHeight,position.Z)
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
 for pen=1,4 do Lobby.display(player,pen,bag.eggs or {}) end
 player.CharacterRemoving:Connect(function() finish(player,"Hunt ended") states[player]=nil end)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) send(player) if worlds[player] then worlds[player].resetVisibility(player) end Records.leave(player) Progress.leave(player) Store.close(player) Lobby.release(player) finish(player,"Hunt ended") states[player],bags[player],limits[player],views[player]=nil,nil,nil,nil if worldRoots[player] then worldRoots[player]:Destroy() end worlds[player],worldRoots[player]=nil,nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end

if RunService:IsRunning() then Records.start() Progress.start() end

local bench
local garden=workspace.RodeoLobby:FindFirstChild("PlazaGarden",true)
local desired=Vector3.new(6057.28,0,23.73)
if garden then
 for _,part in ipairs(garden:GetChildren()) do
  if part:IsA("BasePart") and part.Name=="BenchSeat" and (not bench or (part.Position-desired).Magnitude<(bench.Position-desired).Magnitude) then bench=part end
 end
end
local position=bench and bench.Position or Vector3.new(6057.28,1,23.73)
if bench then
 for _,part in ipairs(garden:GetChildren()) do
  if part:IsA("BasePart") and part.Name:match("^Bench") and (part.Position-position).Magnitude<6 then part:Destroy() end
 end
end
local sign=Instance.new("Part") sign.Name="CafeTravel" sign.Size=Vector3.new(8,6,1) sign.CFrame=CFrame.lookAt(position+Vector3.new(0,3,0),Vector3.new(6000,position.Y+3,0)) sign.Color=Color3.fromRGB(64,96,72) sign.Anchored=true sign.Parent=workspace.RodeoLobby
local gui=Instance.new("SurfaceGui") gui.Parent=sign
local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text="MONSTER CAFE" text.TextScaled=true text.TextColor3=Color3.fromRGB(249,230,189) text.Parent=gui
local prompt=Instance.new("ProximityPrompt") prompt.ActionText="카페로 이동" prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=sign
prompt.Triggered:Connect(function(p)
 local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if r and not states[p] and (r.Position-sign.Position).Magnitude<=16 then Travel.go(p,true) end
end)
]====]}
updates[#updates+1]={node=assert(server:FindFirstChild("HuntWorld"),"Missing HuntWorld"),source=[====[local function createWorld()
local World = {}
local chunks, animals, previousPositions = {}, {}, {}
local root, monsters, obstacles, template, tuning
local Rules
local monsterId,rideSpeed
local Motion=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("HerdMotion"))
local Course=require(game:GetService("ReplicatedStorage").RodeoFantasy.CourseGeometry)
local Visibility=require(game.ReplicatedStorage.RodeoFantasy.HerdVisibility)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local spawnSerial=0
local crateRows={}

local function part(parent, name, position, size, color)
	local item = Instance.new("Part")
	item.Name, item.Anchored = name, true
	item.Size, item.Position, item.Color = size, position, color
	item.Material = Enum.Material.Sand
	item.Parent = parent
	return item
end

local function decoration(parent,name,position,size,color)
 local node=part(parent,name,position,size,color)
 node.Material=Enum.Material.SmoothPlastic
 node.CanCollide,node.CanTouch,node.CanQuery=false,false,false
 node.TopSurface,node.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
 return node
end

local function createCrate(x,z,index)
 local box=part(obstacles,"BreakableCrate",Vector3.new(x,2,z),Vector3.new(4,4,4),Color3.fromRGB(133,88,54))
 box.Transparency=1 box.CanCollide=false box:SetAttribute("Chunk",index) box:SetAttribute("BreakableCrate",true)
 decoration(box,"WoodCore",box.Position,Vector3.new(3.6,3.6,3.6),Color3.fromRGB(143,97,59))
 for _,side in ipairs({-1,1}) do
  for _,height in ipairs({0.25,3.75}) do
   decoration(box,"Frame",Vector3.new(x,height,z+side*1.94),Vector3.new(4,0.5,0.25),Color3.fromRGB(218,163,94))
  end
  for _,edge in ipairs({-1,1}) do
   decoration(box,"Corner",Vector3.new(x+edge*1.75,2,z+side*1.94),Vector3.new(0.5,4,0.25),Color3.fromRGB(218,163,94))
  end
  local brace=decoration(box,"DiagonalBrace",Vector3.new(x,2,z+side*2),Vector3.new(4.4,0.45,0.2),Color3.fromRGB(195,137,77))
  brace.CFrame*=CFrame.Angles(0,0,math.pi/4)
 end
 return box
end

local function dressObstacle(rock,style,scale)
 rock.Transparency=1 rock:SetAttribute("Style",style) rock:SetAttribute("Scale",scale)
 local base=Vector3.new(rock.Position.X,0,rock.Position.Z)
 local function detail(name,pos,size,color)
  return decoration(rock,name,base+pos*scale,size*scale,color)
 end
 if style=="Tree" then
  detail("TreeTrunk",Vector3.new(0,2.2,0),Vector3.new(1.25,4.4,1.25),Color3.fromRGB(146,101,70))
  detail("TreeRoots",Vector3.new(0,0.25,0),Vector3.new(2.4,0.5,2.4),Color3.fromRGB(165,117,77))
  detail("LeafCrown",Vector3.new(0,4.3,0),Vector3.new(3.8,2.1,3.8),Color3.fromRGB(112,165,85))
  detail("LeafTop",Vector3.new(-0.2,5.65,0.1),Vector3.new(2.8,0.7,2.8),Color3.fromRGB(153,195,105))
  detail("LeafHighlight",Vector3.new(0.7,5.25,-0.7),Vector3.new(1.8,0.25,1.5),Color3.fromRGB(174,210,119))
 else
  local stone=detail("Boulder",Vector3.new(0,1.15,0),Vector3.new(3.8,2.3,3.8),Color3.fromRGB(177,157,123))
  stone.CFrame*=CFrame.Angles(0,0,0.06)
  detail("StoneCap",Vector3.new(-0.3,2.5,0.15),Vector3.new(2.7,0.7,2.6),Color3.fromRGB(199,181,143))
  detail("Moss",Vector3.new(-0.6,2.91,0.1),Vector3.new(1.6,0.12,1.5),Color3.fromRGB(124,166,87))
  detail("StoneChip",Vector3.new(1.45,0.4,1.35),Vector3.new(0.9,0.8,0.9),Color3.fromRGB(163,146,113))
 end
end

function World.init(world, modelTemplate, config, rules)
	root, monsters, template, tuning, Rules = world, world.Monsters, modelTemplate, config.Prototype, rules
	monsterId = config.Monster.Id
 rideSpeed = config.Monster.RunSpeed or tuning.ForwardStudsPerSecond
	obstacles = Instance.new("Folder")
	obstacles.Name, obstacles.Parent = "Obstacles", root
	local preview = root:FindFirstChild("PreviewMonster")
	if preview then preview:Destroy() end
	local floor = root:FindFirstChild("PreviewGround")
	if floor then floor:Destroy() end
end

function World.spawn(position,speciesId,stars)
 stars=stars or 1
 local species=Catalog[speciesId or monsterId]
 local id=speciesId or monsterId
 local stage=Catalog.stage(stars)
 local source=if id==monsterId and stage==1 then template else game.ServerStorage:FindFirstChild(Catalog.template(id,stars))
 assert(source and source:IsA("Model") and source.PrimaryPart,"Missing hunt model: "..Catalog.template(id,stars))
	local model = source:Clone()
 model:ScaleTo(Catalog.scale(stars)/Catalog.Scales[stage])
 -- Wild herds replicate only their authoritative root. Clients build the approved visual
 -- for displayed creatures, instead of replicating hundreds of hidden body parts per runner.
 for _,node in ipairs(model:GetChildren()) do if node~=model.PrimaryPart then node:Destroy() end end
 model:SetAttribute("VisualDeferred",true)
 local plate=model.PrimaryPart:FindFirstChild("Nameplate") if plate then plate:Destroy() end
 model.Name = id
	model:SetAttribute("MonsterId", id)
 model:SetAttribute("Stars",stars)
 model:SetAttribute("SaddleHeight",Catalog.saddleHeight(id,stars))
	model:SetAttribute("Occupied", false)
	model:SetAttribute("Running", true)
 model:SetAttribute("RideSpeed",species.RunSpeed)
 model:SetAttribute("HerdSpeed",species.HerdSpeed)
 model:SetAttribute("SizeClass",species.SizeClass)
 model:SetAttribute("Flying",species.Flying)
 local height=species.RootHeight*Catalog.scale(stars)
 model:SetAttribute("RootHeight",height)
 position=Vector3.new(position.X,height,position.Z)
	model:SetAttribute("RunStarted", workspace:GetServerTimeNow() - (math.abs(position.X*0.17+position.Z*0.023)%1))
	model:SetAttribute("Steering", 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = monsters
	spawnSerial+=1 model:SetAttribute("SpawnSerial",spawnSerial)
	animals[model] = Motion.new(position.X,spawnSerial)
	return model
end

function World.ensure(z)
	local center = math.floor(z / tuning.GroundChunkStuds + 0.5)
	for index = center - 2, center + 1 do
		if chunks[index] or index*tuning.GroundChunkStuds < -Course.LengthStuds-128 or index*tuning.GroundChunkStuds>128 then continue end
		local chunk = Instance.new("Folder")
		chunk.Name, chunk.Parent = "Road_" .. index, root
		chunks[index] = chunk
		local start = index * tuning.GroundChunkStuds
		local meadow=part(chunk, "Meadow", Vector3.new(0,-1,start), Vector3.new(80,2,tuning.GroundChunkStuds), Color3.fromRGB(178,211,117))
  meadow.Material=Enum.Material.SmoothPlastic
		local random = Random.new(9101 + math.abs(index) * 137)
		for offset = -112,112,32 do
			local rowZ = start + offset
   if rowZ < -Course.LengthStuds-160 or rowZ>128 then continue end
   local edge=Course.width(rowZ)
   local median=Course.median(rowZ)
   if median>0 then
    decoration(chunk,"ForkRidge",Vector3.new(0,1.5,rowZ),Vector3.new(median*2,3,32),Color3.fromRGB(203,143,91))
    decoration(chunk,"ForkGrass",Vector3.new(0,3.1,rowZ),Vector3.new(median*2,0.2,32),Color3.fromRGB(133,179,96))
   end
   for _, side in ipairs({-1,1}) do
    local height=18+random:NextInteger(0,3) -- wall top remains above flying creatures
    decoration(chunk,"CanyonBase",Vector3.new(side*(edge+5),2,rowZ),Vector3.new(10,4,32),Color3.fromRGB(220,151,97))
    decoration(chunk,"CanyonStratum",Vector3.new(side*(edge+7),4.5,rowZ),Vector3.new(10,1,32),Color3.fromRGB(249,191,128))
    decoration(chunk,"CanyonUpper",Vector3.new(side*(edge+9),5+height/2,rowZ),Vector3.new(12,height,32),Color3.fromRGB(201,126,80))
    decoration(chunk,"GrassCap",Vector3.new(side*(edge+9),5+height+0.25,rowZ),Vector3.new(12,0.5,32),Color3.fromRGB(122,170,92))
    decoration(chunk,"GrassEdge",Vector3.new(side*(edge-3),0.08,rowZ),Vector3.new(6,0.16,32),Color3.fromRGB(143,190,96))
    for i=1,3 do
     local z=rowZ+random:NextNumber(-14,14)
     local x=side*random:NextNumber(edge-3,edge-1)
     decoration(chunk,"GrassTuft",Vector3.new(x,0.45,z),Vector3.new(0.5,0.9,0.5),Color3.fromRGB(109,161,77))
    end
    if random:NextNumber()<0.4 then
     local treeZ=rowZ+random:NextNumber(-8,8)
     decoration(chunk,"TreeTrunk",Vector3.new(side*(edge+13),5+height+2,treeZ),Vector3.new(1.4,4,1.4),Color3.fromRGB(152,99,67))
     decoration(chunk,"TreeCrown",Vector3.new(side*(edge+13),5+height+5,treeZ),Vector3.new(6,4,6),Color3.fromRGB(115,163,90))
     decoration(chunk,"TreeTop",Vector3.new(side*(edge+13),5+height+7,treeZ),Vector3.new(4,2,4),Color3.fromRGB(146,190,107))
    end
   end
   for i=1,3 do
    decoration(chunk,"MeadowPatch",Vector3.new(random:NextNumber(-29,29),0.025,rowZ+random:NextNumber(-14,14)),Vector3.new(random:NextNumber(2,5),0.05,random:NextNumber(3,8)),Color3.fromRGB(187,218,128))
   end
			-- Leave the run launch area clear; all other rows contain moving herds.
			if rowZ < -20 or rowZ > 30 then
				local lanes={}
    local ranges=Course.ranges(rowZ,4)
    for _,range in ipairs(ranges) do
     for i=1,4/#ranges do table.insert(lanes,range[1]+(range[2]-range[1])*i/(4/#ranges+1)) end
    end
    for _, x in ipairs(lanes) do
					-- Herd spawning is coordinated across all runners below, not tied to chunk creation.
				end
				if random:NextNumber() < tuning.RockSpawnChance then
					local kind=(math.abs(index)*8+math.floor((offset+112)/32))%4
     local style=kind>=2 and "Tree" or "MossyRock"
     local scale=kind%2==1 and 2 or 1
     local bounds=Course.ranges(rowZ-12,2*scale+2)
     local range=bounds[random:NextInteger(1,#bounds)]
     local x=random:NextNumber(range[1],range[2])
     local height=(style=="Tree" and 6 or 3)*scale
     local rock=part(obstacles,"Rock",Vector3.new(x,height/2,rowZ-12),Vector3.new(4*scale,height,4*scale),Color3.fromRGB(167,130,99))
     rock:SetAttribute("Chunk",index)
     rock.CanCollide=false -- server swept collision is authoritative
     dressObstacle(rock,style,scale)
				end

    -- Independent seeded rolls keep existing herd/rock density unchanged.
    if rowZ < -96 then
     local crateRandom=Random.new(33017+math.abs(math.floor(rowZ))*31)
     if crateRandom:NextNumber()<tuning.CrateSpawnChance then
      local clear=true
      for existing in pairs(crateRows) do if math.abs(existing-rowZ)<192 then clear=false break end end
      if clear then
       local ranges=Course.ranges(rowZ,5)
       local range=ranges[crateRandom:NextInteger(1,#ranges)]
       local x=crateRandom:NextNumber(range[1],range[2])
       -- Crates need their own clear footprint beside trees/rocks.
       for _,other in ipairs(obstacles:GetChildren()) do
        if math.abs(other.Position.Z-rowZ)<other.Size.Z/2+4 and math.abs(other.Position.X-x)<other.Size.X/2+4 then clear=false break end
       end
       if clear then createCrate(x,rowZ,index) crateRows[rowZ]=index end
      end
     end
    end
			end
		end
	end
end

function World.step(dt)
 if not obstacles then return end
 local buckets={}
 for _,rock in ipairs(obstacles:GetChildren()) do
  if rock:IsA("BasePart") and not rock:GetAttribute("Broken") then
   local key=math.floor(rock.Position.Z/64)
   buckets[key]=buckets[key] or {}
   table.insert(buckets[key],{x=rock.Position.X,z=rock.Position.Z,sx=rock.Size.X,sz=rock.Size.Z})
  end
 end
	for model,motion in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		previousPositions[model] = model.PrimaryPart.Position
		if not model:GetAttribute("Occupied") then
			-- Only the authoritative root moves. Clients own all visual body poses.
   local p,half=model.PrimaryPart.Position,model.PrimaryPart.Size/2
   local movement=table.clone(tuning)
   movement.HerdStudsPerSecond=model:GetAttribute("HerdSpeed") or tuning.HerdStudsPerSecond
   local nearby={}
   for key=math.floor((p.Z-110)/64),math.floor((p.Z+12)/64) do
    for _,rock in ipairs(buckets[key] or {}) do if not model:GetAttribute("Flying") then table.insert(nearby,rock) end end
   end
   if motion.wasOccupied then motion.home,motion.vx,motion.wasOccupied=p.X,0,false end
   local x,z,vx
   if motion.entry then
    motion.entry.age+=dt
    local a=math.min(motion.entry.age/1.25,1)
    x=motion.entry.from+(motion.entry.to-motion.entry.from)*a
    z=p.Z-(motion.entry.waiting and 0 or dt*movement.HerdStudsPerSecond*0.3)
    vx=(motion.entry.to-motion.entry.from)/1.25
    if a>=1 then motion.home=motion.entry.home motion.entry=nil model:SetAttribute("Emerging",nil) end
   else x,z,vx=Motion.step(motion,p.X,p.Z,dt,nearby,movement,half.X,half.Z,Rules,Course) end
   model.PrimaryPart.CFrame=CFrame.new(x,p.Y,z)*CFrame.Angles(0,-math.atan2(vx,movement.HerdStudsPerSecond),0)
   model:SetAttribute("Steering",vx/tuning.SidewaysStudsPerSecond)
		 model:SetAttribute("HerdVelocity",Vector3.new(vx,0,(z-p.Z)/math.max(dt,0.000001)))
		else motion.wasOccupied=true
		end
	end
end

local displayed=setmetatable({},{__mode="k"})
local released=setmetatable({},{__mode="k"})
function World.resetVisibility(viewer) displayed[viewer]=nil released[viewer]=nil end
function World.releaseMount(model,viewer)
 if not model or not model.Parent or not animals[model] or not viewer then return end
 released[viewer]=released[viewer] or {}
 released[viewer][model]=true
end
function World.atDen() return false end
function World.visibleSet(z,aspect,viewer)
 local candidates={}
 local riding=false
 for model in pairs(animals) do
  if model.Parent and model:GetAttribute("Occupied") then riding=true end
  if model.Parent and not model:GetAttribute("Occupied") then
   local p=model.PrimaryPart.Position
   table.insert(candidates,{key=model,x=p.X,y=p.Y,z=p.Z,serial=model:GetAttribute("SpawnSerial") or 0})
  end
 end
 local preferred=viewer and released[viewer]
 if preferred then
  for model in pairs(preferred) do
   local p=model.Parent and model.PrimaryPart and model.PrimaryPart.Position
   if not p or model:GetAttribute("Occupied") or not Visibility.visible(p.X,p.Y,p.Z-z,aspect or 1,tuning,1) then preferred[model]=nil end
  end
 end
 -- Reserve the occupied runner's slot before launch, so releasing it cannot
 -- evict a different wild runner that is still in the middle of the screen.
 local target=Visibility.capacity(Course.width(z))-(riding and 1 or 0)
 local previous=viewer and displayed[viewer]
 local limit=Visibility.transitionLimit(candidates,z,aspect or 1,tuning,target,previous,preferred)
 local result=Visibility.select(candidates,z,aspect or 1,tuning,limit,previous,preferred)
 if viewer then displayed[viewer]=result end
 return result
end
function World.nearest(position, excluded, selected)
	local best, bestDistance = nil, tuning.LassoRangeStuds * tuning.LassoRangeStuds
	for model in pairs(animals) do
		if not model.Parent or model==excluded or model:GetAttribute("Occupied") or model:GetAttribute("Emerging") or (selected and not selected[model]) then continue end
		local delta = model.PrimaryPart.Position-position
		local distance = delta.X*delta.X+delta.Z*delta.Z
		if distance <= bestDistance then best, bestDistance = model, distance end
	end
	return best
end

-- Private run: preload the opening scene; later births are strictly beyond the camera.
function World.replenish(z,aspect,watchers,prime,budget)
 aspect=aspect or 1
 local created=0
 local lanes={-0.72,-0.24,0.24,0.72}
 for offset=prime and -12 or 0,220,8 do
  if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
  local targetZ=z-offset
  if -targetZ*tuning.MetersPerStud>=Catalog.MeadowEndMeters then continue end
  local id=Catalog.pick(math.max(0,-z*tuning.MetersPerStud),spawnSerial)
  if not id then break end
  for _,range in ipairs(Course.ranges(targetZ,5)) do
   local narrow=Course.width(targetZ)<30
   if narrow and (offset-(prime and -12 or 0))%16~=0 then continue end
   for laneIndex,lane in ipairs(narrow and {-0.5,0.5} or lanes) do
    local x=(range[1]+range[2])/2+lane*(range[2]-range[1])/2
    local onScreen=Visibility.visible(x,Catalog[id].RootHeight,targetZ-z,aspect,tuning,1.2)
    if onScreen and not prime then continue end
    local safe=true
    for other in pairs(animals) do
     if other.Parent then local p=other.PrimaryPart.Position if math.abs(p.X-x)<8 and math.abs(p.Z-targetZ)<18 then safe=false break end end
    end
    for _,rock in ipairs(obstacles:GetChildren()) do
     if not Catalog[id].Flying and not rock:GetAttribute("Broken") and math.abs(rock.Position.X-x)<rock.Size.X/2+5 and math.abs(rock.Position.Z-targetZ)<rock.Size.Z/2+10 then safe=false break end
    end
    if safe then
     local model=World.spawn(Vector3.new(x,2,targetZ),id)
     model:SetAttribute("BornOutsideView",not onScreen)
     model:SetAttribute("OpeningScene",prime==true)
     created+=1
    end
    if created>=math.min(budget or 24,Course.width(z)<30 and 16 or 24) then break end
   end
  end
 end
 return created
end
function World.maintain(watchers)
 for _,watch in ipairs(watchers) do World.replenish(watch.z,watch.aspect,nil,false,12) end
end

-- Contact while riding: include moving herds and the visible inner canyon face.
function World.mountedHit(from,to,mount,selected,dashing)
 local half=mount.PrimaryPart.Size/2
 local flying=mount:GetAttribute("Flying")==true
 for i=0,4 do
  local p=from:Lerp(to,i/4)
  if not Course.contains(p.X,p.Z-half.Z,half.X,flying) or not Course.contains(p.X,p.Z+half.Z,half.X,flying) then return "Wall" end
 end
 for other in pairs(animals) do
  if other==mount or not other.Parent or other:GetAttribute("Flying")~=mount:GetAttribute("Flying") or (selected and not other:GetAttribute("Occupied") and not selected[other]) then continue end
  local old=previousPositions[other] or other.PrimaryPart.Position
  local current=other.PrimaryPart.Position
  local a,b=from-old,to-current
  local size=other.PrimaryPart.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(a.X,a.Y,a.Z,b.X,b.Y,b.Z,0,0,0,size.X,size.Y,size.Z,0) then
   if not other:GetAttribute("Occupied") and Rules.canKnock(mount:GetAttribute("SizeClass"),other:GetAttribute("SizeClass"),dashing) then
    animals[other]=nil previousPositions[other]=nil
    local direction=other.PrimaryPart.Position.X>=mount.PrimaryPart.Position.X and 1 or -1
    other:SetAttribute("Running",false)
    other:SetAttribute("KnockedAt",workspace:GetServerTimeNow())
    other:SetAttribute("KnockDirection",direction)
    other:SetAttribute("KnockedAway",true)
    -- Clients scatter the actual visual parts immediately. Retain the root briefly
    -- so a replicated hit is observable even after selection removes the victim.
    game:GetService("Debris"):AddItem(other,2)
   else return "Monster" end
  end
 end
 return nil
end

local function breakObstacle(rock,respawn)
 local appearance={}
 for _,piece in ipairs(rock:GetDescendants()) do
  if piece:IsA("BasePart") then appearance[piece]=piece.Transparency piece.Transparency=1 piece.CanQuery=false end
 end
 rock:SetAttribute("Broken",true) rock:SetAttribute("BrokenAt",workspace:GetServerTimeNow()) rock.CanQuery=false
 if respawn then task.delay(5,function()
  if not rock.Parent then return end
  for piece,transparency in pairs(appearance) do if piece.Parent then piece.Transparency=transparency end end
  rock:SetAttribute("Broken",false) rock.CanQuery=true
 end) end
end
function World.hit(from, to, flying,mount,dashing)
	for _, rock in ipairs(obstacles:GetChildren()) do
  if mount and rock:GetAttribute("BreakableCrate") then continue end -- dedicated crateHit rule
		if rock:GetAttribute("Broken") or (flying and rock:GetAttribute("WallClass")~="High" and rock:GetAttribute("ObstacleSize")~="Large") then continue end
		local p,s = rock.Position,rock.Size
		if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,1) then
   local obstacleSize=rock:GetAttribute("ObstacleSize") or (rock:GetAttribute("Scale")==1 and "Small" or nil)
   if mount and Rules.canBreakObstacle(mount:GetAttribute("SizeClass"),obstacleSize,dashing) then breakObstacle(rock,true)
   else return true end
  end
	end
	return false
end

function World.crateHit(from,to,mount,sizeClass,dashing)
 if mount:GetAttribute("Flying") then return false end
 for _,box in ipairs(obstacles:GetChildren()) do
  if not box:GetAttribute("BreakableCrate") or box:GetAttribute("Broken") then continue end
  local p,s=box.Position,box.Size+mount.PrimaryPart.Size
  if Rules.sweptBox(from.X,from.Y,from.Z,to.X,to.Y,to.Z,p.X,p.Y,p.Z,s.X,s.Y,s.Z,0) then
   if not Rules.canBreakCrate(sizeClass) then return true end
   box.CanQuery=false box.CanTouch=false
   box:SetAttribute("Broken",true) box:SetAttribute("BrokenAt",workspace:GetServerTimeNow())
   for _,piece in ipairs(box:GetDescendants()) do if piece:IsA("BasePart") then piece.Transparency=1 piece.CanQuery=false end end
   -- Loot is deliberately pending the user's item design.
  end
 end
 return false
end

-- Preserve each active runner's vicinity, and avoid unlimited course/animal growth.
function World.cleanup(nearZ)
	for index, chunk in pairs(chunks) do
		local keep = false
		for _, z in ipairs(nearZ) do if math.abs(index*tuning.GroundChunkStuds-z) < tuning.GroundChunkStuds*4 then keep = true break end end
		if not keep then
			chunk:Destroy()
			chunks[index] = nil
			for _, rock in ipairs(obstacles:GetChildren()) do if rock:GetAttribute("Chunk") == index then rock:Destroy() end end
			for z,owner in pairs(crateRows) do if owner==index then crateRows[z]=nil end end
		end
	end
	for model in pairs(animals) do
		if not model.Parent then animals[model] = nil previousPositions[model]=nil continue end
		local keep = model:GetAttribute("Occupied")
		for _, z in ipairs(nearZ) do if math.abs(model.PrimaryPart.Position.Z-z) < 420 then keep = true break end end
		if not keep then model:Destroy() animals[model] = nil previousPositions[model]=nil end
	end
end

return World
end
local default=createWorld()
default.new=createWorld
return default
]====]}
local template=storage:FindFirstChild("RodeoMonsterTemplate")
if not template then
 local approved=package:FindFirstChild("MeshyMossratHuntTemplate")
 assert(approved and approved:IsA("Model") and approved.PrimaryPart and approved:GetAttribute("NativeMeshyMossrat"),"사냥터용 모스랫 설치본을 찾지 못했습니다.")
 approved.Archivable=true
 for _,node in ipairs(approved:GetDescendants()) do node.Archivable=true end
 template=assert(approved:Clone()) template.Name="RodeoMonsterTemplate" template.Parent=storage
end
assert(template:IsA("Model") and template.PrimaryPart,"사냥터 템플릿에 루트가 없습니다.")
template.Archivable=true
for _,node in ipairs(template:GetDescendants()) do node.Archivable=true end
for _,entry in ipairs(updates) do entry.node.Source=entry.source end
print("HUNT_DEPARTURE_REPAIRED: Ctrl+S로 저장 후 Play에서 중앙 발판 E 출발을 확인하세요.")