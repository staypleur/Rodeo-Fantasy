local S={}
local Players=game:GetService("Players")
local P=game.ReplicatedStorage.RodeoFantasy
local R=require(P.SocialRules)
local Store=require(script.Parent.InventoryStore)
local Progress=require(script.Parent.ProgressService)
local Catalog=require(P.MonsterCatalog)
local sessions={}
function S.trading(player) local t=sessions[player] return t and t.accepted end
local function close(t)
 if t.committing then return end
 for _,p in ipairs(t.users) do sessions[p]=nil P.CaptureRemote:FireClient(p,"TradeClosed") end
end
function S.start(bags,canAct,sendBag,beforeTrade)
 local remote=P.CaptureRemote
 local function near(a,b)
  local x=a.Character and a.Character:FindFirstChild("HumanoidRootPart")
  local y=b.Character and b.Character:FindFirstChild("HumanoidRootPart")
  return x and y and (x.Position-y.Position).Magnitude<=16
 end
 local function packet(t,p)
  local q=t.users[1]==p and t.users[2] or t.users[1]
  local theirs=table.clone(t.offers[q]) theirs.monsters={}
  for _,id in ipairs(theirs.ids) do local m=R.find(bags[q],id) if m then table.insert(theirs.monsters,{monsterId=m.monsterId,stars=m.stars}) end end
  return {other=q.UserId,name=q.DisplayName,accepted=t.accepted,mine=t.offers[p],theirs=theirs,ready=t.ready[p],otherReady=t.ready[q],final=t.final[p],revision=t.revision}
 end
 local function update(t) for _,p in ipairs(t.users) do remote:FireClient(p,"Trade",packet(t,p)) end end
 local stamps={}
 remote.OnServerEvent:Connect(function(player,action,value)
  if type(action)~="string" or not canAct(player) or Store.busy(player) then return end
  local allowed={Breed=true,ProfileSave=true,Profile=true,OtherJournal=true,TradeRequest=true,TradeAccept=true,TradeDecline=true,TradeOffer=true,TradeReady=true,TradeConfirm=true}
  if not allowed[action] then return end
  local clock=os.clock() local key=tostring(player.UserId)..action
  if clock-(stamps[key] or 0)<.25 then return end stamps[key]=clock
  local bag=bags[player] if not bag then return end
  if action=="Breed" then
   local _,message=R.pair(bag,value) remote:FireClient(player,"SocialMessage",message) return
  end
  if action=="ProfileSave" then
   local ids=R.profile(bag,value) if ids and not S.trading(player) then bag.profile=ids remote:FireClient(player,"SocialMessage","Profile saved.") end return
  end
  if player:GetAttribute("Area")~="Cafe" then return end
  if action=="Profile" or action=="OtherJournal" or action=="TradeRequest" then
   if type(value)~="number" or value~=value or value%1~=0 then return end
   local other=Players:GetPlayerByUserId(value)
   if not other or other==player or not bags[other] or not near(player,other) then return end
   if action=="Profile" then
    local featured={} for _,id in ipairs(bags[other].profile or {}) do local m=R.find(bags[other],id) if m then table.insert(featured,{monsterId=m.monsterId,stars=m.stars}) end end
    remote:FireClient(player,"Profile",{userId=other.UserId,name=other.DisplayName,username=other.Name,monsters=featured})
   elseif action=="OtherJournal" then remote:FireClient(player,"OtherJournal",Progress.snapshot(other,true))
   elseif not sessions[player] and not sessions[other] and not Store.busy(other) then
    local t={users={player,other},offers={[player]={ids={},coins=0},[other]={ids={},coins=0}},ready={},final={},revision=1,expires=clock+30}
    sessions[player]=t sessions[other]=t update(t)
    remote:FireClient(other,"TradeInvitation",{userId=player.UserId,name=player.DisplayName})
   end return
  end
  local t=sessions[player] if not t or t.committing then return end
  if clock>t.expires then close(t) return end
  local other=t.users[1]==player and t.users[2] or t.users[1]
  if action=="TradeDecline" then close(t) return end
  if action=="TradeAccept" and t.users[2]==player and near(player,other) then t.accepted=true t.expires=clock+180 update(t) return end
  if not t.accepted or not near(player,other) or Store.busy(other) then return end
  if action=="TradeOffer" then
   local offer=R.offer(bag,value)
   if offer then t.offers[player]={ids=offer.ids,coins=offer.coins} t.ready={} t.final={} t.revision+=1 t.expires=clock+180 update(t) end
  elseif action=="TradeReady" and value==t.revision then t.ready[player]=true update(t)
  elseif action=="TradeConfirm" and value==t.revision and t.ready[player] and t.ready[other] then
   t.final[player]=true update(t)
   if not t.final[other] then return end
   local a,b=t.users[1],t.users[2]
   local after,message=R.exchange(bags[a],bags[b],t.offers[a],t.offers[b])
   if not after then remote:FireClient(player,"SocialMessage",message) t.ready={} t.final={} update(t) return end
   t.committing=true
   if beforeTrade then beforeTrade(a) beforeTrade(b) end
   local ok=Store.trade(a,b,after)
   t.committing=false close(t)
   if ok then
    for _,p in ipairs({a,b}) do
     for _,m in ipairs(bags[p].monsters) do if Catalog[m.monsterId] then Progress.discover(p,m.monsterId,m.stars) end end
     sendBag(p) remote:FireClient(p,"SocialMessage","Trade complete.")
    end
   end
  end
 end)
 Players.PlayerRemoving:Connect(function(p) local t=sessions[p] if t and not t.committing then close(t) end end)
 task.spawn(function() while task.wait(2) do for _,t in pairs(sessions) do if not t.committing and (os.clock()>t.expires or not near(t.users[1],t.users[2])) then close(t) end end end end)
end
return S
