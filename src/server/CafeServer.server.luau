local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local P=game.ReplicatedStorage.RodeoFantasy
local C=require(P.MonsterCatalog)
local Bag=require(P.BagRules)
local Rules=require(P.SocialRules)
local Store=require(script.Parent.InventoryStore)
local Progress=require(script.Parent.ProgressService)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local World=require(script.Parent.CafeWorld)
local map=World.build()
local remote=P.CaptureRemote
local pets=Instance.new("Folder") pets.Name="CafePets" pets.Parent=workspace
local bags,mounts,companions,limits={},{},{},{}
local function active(p) return bags[p] and not p:GetAttribute("Travelling") end
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function sendBag(p)
 local b=bags[p] if not b then return end local items={}
 for _,m in ipairs(b.monsters) do table.insert(items,{id=m.id,monsterId=m.monsterId,stars=m.stars,sex=m.sex,breedingTeam=m.breedingTeam,incomeSeconds=m.incomeSeconds,incomeAmount=Bag.income(m)}) end
 remote:FireClient(p,"Bag",items)
end
local function dismount(p)
 local m=mounts[p] if not m then return end
 if m.root.Parent then m.root.Anchored=m.anchored m.humanoid.PlatformStand=m.platform m.humanoid.AutoRotate=m.rotate m.root.CFrame=m.root.CFrame*CFrame.new(5,0,0) end
 mounts[p]=nil p:SetAttribute("CafeMounted",false)
 local c=companions[p] if c then c.model:SetAttribute("Running",false) c.model:SetAttribute("HerdVelocity",Vector3.zero) end
end
local function clear(p)
 dismount(p) local c=companions[p] if c then c.model:Destroy() end companions[p]=nil p:SetAttribute("SummonedId",nil)
end
local function summon(p,id)
 if Social.trading(p) then return end
 local m=Rules.find(bags[p],id) local r=root(p)
 if not Rules.available(m) or not r or (companions[p] and companions[p].id==id) then return end
 local template=P:FindFirstChild(C.visual(m.monsterId,m.stars)) if not template then return end
 local model=template:Clone() model:ScaleTo(C.scale(m.stars)/C.Scales[C.stage(m.stars)])
 local _,size=model:GetBoundingBox()
 local pos=r.Position+r.CFrame.LookVector*(math.max(size.X,size.Z)*.5+5)
 if size.Y>18 and pos.Z< -107 then model:Destroy() remote:FireClient(p,"SocialMessage","큰 몬스터는 앞쪽 운동장에서 소환해주세요.") return end
 if math.abs(pos.X)>285 or pos.Z>285 or pos.Z< -209 then model:Destroy() return end
 local params=OverlapParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={map}
 local box=CFrame.new(pos.X,size.Y*.5+1,pos.Z)
 for _,hit in ipairs(workspace:GetPartBoundsInBox(box,Vector3.new(size.X,math.max(1,size.Y-2),size.Z),params)) do
  if hit.CanCollide and hit.Size.Y>2 and hit.Name~="Roof" then model:Destroy() remote:FireClient(p,"SocialMessage","주변 공간이 좁아요. 조금 넓은 곳에서 소환해주세요.") return end
 end
 clear(p)
 model.Name="Companion_"..p.UserId model:SetAttribute("MonsterId",m.monsterId) model:SetAttribute("Stars",m.stars)
 model:SetAttribute("OwnerUserId",p.UserId) model:SetAttribute("BagItemId",m.id) model:SetAttribute("Running",false) model:SetAttribute("RunStarted",workspace:GetServerTimeNow())
 local height=C[m.monsterId].RootHeight*C.scale(m.stars)
 model:PivotTo(CFrame.new(pos.X,height,pos.Z)*model.PrimaryPart.CFrame:Inverse()*model:GetPivot())
 for _,n in ipairs(model:GetDescendants()) do if n:IsA("BasePart") then n.Anchored=true n.CanCollide=false n.CanTouch=false elseif n:IsA("BillboardGui") then n:Destroy() end end
 model.Parent=pets companions[p]={model=model,id=id,height=height,size=size}
 p:SetAttribute("SummonedId",id)
 local mountPoint=Instance.new("Attachment") mountPoint.Name="MountPoint" mountPoint.Position=Vector3.new(size.X/2+1,-height+3,0) mountPoint.Parent=model.PrimaryPart
 local prompt=Instance.new("ProximityPrompt") prompt.Name="RideOwnMonster" prompt.ActionText="타기" prompt.KeyboardKeyCode=Enum.KeyCode.Q prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=mountPoint
 prompt.Triggered:Connect(function(who)
  local rr=root(who) local h=who.Character and who.Character:FindFirstChildOfClass("Humanoid")
  if who~=p or not active(p) or Store.busy(p) or Social.trading(p) or not Rules.available(Rules.find(bags[p],id)) or not rr or not h or h.Health<=0 or (rr.Position-mountPoint.WorldPosition).Magnitude>16 then return end
  if mounts[p] then dismount(p) return end
  mounts[p]={root=rr,humanoid=h,anchored=rr.Anchored,platform=h.PlatformStand,rotate=h.AutoRotate,move=Vector3.zero,at=os.clock()}
  rr.Anchored=true h.PlatformStand=true h.AutoRotate=false p:SetAttribute("CafeMounted",true)
 end)
end
Social.start(bags,active,sendBag,clear)
remote.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" or not active(p) or Store.busy(p) then return end
 local stamps=limits[p] or {} limits[p]=stamps
 if os.clock()-(stamps[action] or -1)<(action=="CafeMove" and .04 or .25) then return end stamps[action]=os.clock()
 if action=="Sync" or action=="Bag" then sendBag(p)
 elseif action=="Summon" then summon(p,value)
 elseif action=="Dismount" then dismount(p)
 elseif action=="CafeMove" and mounts[p] and typeof(value)=="Vector3" and value.X==value.X and value.Z==value.Z and value.Magnitude<=1.1 then mounts[p].move=Vector3.new(value.X,0,value.Z) mounts[p].at=os.clock()
 elseif action=="Journal" then remote:FireClient(p,"Journal",Progress.snapshot(p,true))
 elseif action=="Evolve" and not Social.trading(p) then
  Bag.accrue(bags[p],workspace:GetServerTimeNow(),3,1)
  local evolved,reason=Bag.evolve(bags[p],value,workspace:GetServerTimeNow())
  if evolved then clear(p) end remote:FireClient(p,"EvolutionResult",{ok=evolved~=nil,reason=reason}) sendBag(p)
 end
end)
local portal=map.LobbyReturn
local back=Instance.new("ProximityPrompt") back.ActionText="로비로 이동" back.HoldDuration=1 back.MaxActivationDistance=12 back.RequiresLineOfSight=false back.Parent=portal
back.Triggered:Connect(function(p) if root(p) and (root(p).Position-portal.Position).Magnitude<=16 and not Social.trading(p) then clear(p) Travel.go(p,false) end end)
local function added(p)
 if #Players:GetPlayers()>20 then p:Kick("카페 정원은 20명입니다.") return end
 local bag,message=Store.open(p) if not bag then p:Kick(message) return end
 bags[p]=bag p:SetAttribute("Area","Cafe") Progress.join(p)
 local function character(c)
  clear(p) local r=c:WaitForChild("HumanoidRootPart",10) if r then c:PivotTo(World.Spawn) end
  local h=c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=24 end
  if r then
   local prompt=Instance.new("ProximityPrompt") prompt.Name="ViewCafeProfile" prompt.ActionText="프로필 보기" prompt.ObjectText=p.DisplayName prompt.HoldDuration=1 prompt.MaxActivationDistance=12 prompt.RequiresLineOfSight=false prompt.Parent=r
  end
 end
 p.CharacterAdded:Connect(character) p.CharacterRemoving:Connect(function() clear(p) end)
 if p.Character then task.spawn(character,p.Character) end
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(p) clear(p) Progress.leave(p) Store.close(p) bags[p]=nil limits[p]=nil end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 local clock=workspace:GetServerTimeNow()
 for p,m in pairs(mounts) do
  local c=companions[p]
  if not c or not m.root.Parent or m.humanoid.Health<=0 then dismount(p) continue end
  local move=os.clock()-m.at<.4 and m.move or Vector3.zero
  local old=c.model.PrimaryPart.Position local delta=move*24*math.min(dt,.1)
  local nextPos=old+delta
  local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={map} params.RespectCanCollide=true
  local size=Vector3.new(math.max(1,c.size.X*.8),math.max(1,c.size.Y-2),math.max(1,c.size.Z*.8))
  if math.abs(nextPos.X)>285 or nextPos.Z>285 or nextPos.Z< -208 or (delta.Magnitude>0 and workspace:Blockcast(CFrame.new(old.X,c.size.Y/2+1.1,old.Z),size,delta,params)) then move=Vector3.zero nextPos=old end
  if move.Magnitude>.01 then c.model.PrimaryPart.CFrame=CFrame.lookAt(nextPos,nextPos+move) end
  c.model:SetAttribute("Running",move.Magnitude>.01) c.model:SetAttribute("HerdVelocity",move*24)
  m.root.CFrame=c.model.PrimaryPart.CFrame*CFrame.new(0,C.saddleHeight(Rules.find(bags[p],c.id).monsterId,Rules.find(bags[p],c.id).stars),0)
 end
 elapsed+=dt if elapsed<.25 then return end elapsed=0
 for p,b in pairs(bags) do
  if Store.busy(p) or p:GetAttribute("Travelling") then continue end
  local gains=Bag.accrue(b,clock,3,1)
  remote:FireClient(p,"State",{area="Cafe",phase="Idle",count=#b.monsters,pending=b.pending,balance=b.balance,income=gains,summonedId=p:GetAttribute("SummonedId"),profile=b.profile})
 end
end)
Progress.start()
