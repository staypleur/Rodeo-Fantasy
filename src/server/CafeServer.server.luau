-- Cafe uses the same fenced inventory and companion rules as the lobby.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local Config=require(P.Config)
local Bag=require(P.BagRules)
local Rules=require(P.SocialRules)
local Catalog=require(P.MonsterCatalog)
local Store=require(script.Parent.InventoryStore)
local Progress=require(script.Parent.ProgressService)
local Social=require(script.Parent.SocialService)
local Travel=require(script.Parent.PlaceTravel)
local World=require(script.Parent.CafeWorld)
local map=World.build()
local remote=P.CaptureRemote
local bags,limits={},{}
local function active(p) return bags[p]~=nil and not p:GetAttribute("Travelling") end
local function canAct(p)
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 return active(p) and not Store.busy(p) and not Social.trading(p) and h and h.Health>0
end
local pets=require(script.Parent.LobbyCompanions).new({map=map,streamingMode=Enum.ModelStreamingMode.Atomic,
 bag=function(p) return bags[p] end,inLobby=active,canAct=canAct,canSummon=canAct})
local function accrue(b)
 return Bag.accrue(b,workspace:GetServerTimeNow(),Config.BagIncome.IncomeSeconds,Config.BagIncome.IncomeAmount)
end
local function send(p,gains)
 local b=bags[p] if not b or not p.Parent then return end
 remote:FireClient(p,"State",{area="Cafe",phase="Idle",count=#b.monsters,pending=b.pending,balance=b.balance,gems=b.gems or 0,
 income=gains,summonedId=p:GetAttribute("SummonedId"),profile=b.profile,progress=Progress.snapshot(p)})
end
local function sendBag(p)
 local b=bags[p] if not b then return end local items={}
 for _,m in ipairs(b.monsters) do
  table.insert(items,{id=m.id,monsterId=m.monsterId,stars=m.stars,sex=m.sex,breedingTeam=m.breedingTeam,
   incomeSeconds=m.incomeSeconds or Config.BagIncome.IncomeSeconds,incomeAmount=Bag.income(m,Config.BagIncome.IncomeAmount)})
 end
 remote:FireClient(p,"Bag",items)
end
Social.start(bags,canAct,sendBag,pets.clear)
remote.OnServerEvent:Connect(function(p,action,value)
 if type(action)~="string" or not active(p) or Store.busy(p) then return end
 local allowed={Sync=true,Bag=true,Summon=true,BondPet=true,RidePet=true,RideInput=true,GoLobby=true,Journal=true,Evolve=true,Manage=true,PlaceEgg=true,RemoveEgg=true}
 if not allowed[action] then return end
 local stamps=limits[p] or {} limits[p]=stamps
 local interval=action=="RideInput" and .05 or .25
 if os.clock()-(stamps[action] or -1)<interval then return end stamps[action]=os.clock()
 if action=="Sync" then send(p,accrue(bags[p])) sendBag(p)
 elseif action=="Bag" then sendBag(p)
 elseif action=="Journal" then remote:FireClient(p,"Journal",Progress.snapshot(p,true))
 elseif action=="GoLobby" and canAct(p) then accrue(bags[p]) Travel.go(p,false)
 elseif action=="Summon" then pets.summon(p,value) send(p)
 elseif action=="BondPet" then pets.bond(p,value)
 elseif action=="RidePet" then pets.ride(p,value)
 elseif action=="RideInput" then pets.input(p,value)
 elseif action=="Evolve" and canAct(p) then
  local gains=accrue(bags[p]);local evolved,reason=Bag.evolve(bags[p],value,workspace:GetServerTimeNow())
  if evolved then pets.clear(p) Progress.discover(p,evolved.monsterId,evolved.stars) end
  remote:FireClient(p,"EvolutionResult",{ok=evolved~=nil,reason=reason}) sendBag(p) send(p,gains)
 elseif action=="Manage" and canAct(p) and type(value)=="number" and value%1==0 and value>=1 and value<=4 then
  remote:FireClient(p,"Eggs",{pen=value,eggs=bags[p].eggs or {}})
 elseif (action=="PlaceEgg" or action=="RemoveEgg") and canAct(p) and type(value)=="table" then
  if Rules.egg(bags[p],value.id,value.pen,action=="RemoveEgg") then remote:FireClient(p,"Eggs",{pen=value.pen,eggs=bags[p].eggs}) end
 end
end)
local function added(p)
 if #Players:GetPlayers()>require(P.SocialConfig).CafeCapacity then p:Kick("Cafe is full.") return end
 local b,message=Store.open(p) if not b then p:Kick(message) return end
 bags[p]=b;p:SetAttribute("Area","Cafe");Progress.join(p,b)
 local function character(c)
  pets.clear(p);local r=c:WaitForChild("HumanoidRootPart",10)
  if r then c:PivotTo(World.Spawn) end
  local h=c:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed=Config.CafeWalkSpeed end
 end
 p.CharacterAdded:Connect(character)
 p.CharacterRemoving:Connect(function() pets.clear(p) end)
 if p.Character then task.spawn(character,p.Character) end
 send(p) sendBag(p)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(p)
 if bags[p] and not p:GetAttribute("Travelling") and not Store.busy(p) then accrue(bags[p]) end
 pets.clear(p);Progress.leave(p);Store.close(p);bags[p]=nil;limits[p]=nil
end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(added,p) end
-- Income is based on server time, independent of input, movement or open UI.
task.spawn(function()
 while task.wait(.5) do
  for p,b in pairs(bags) do if active(p) and not Store.busy(p) then send(p,accrue(b)) end end
 end
end)
Progress.start()
