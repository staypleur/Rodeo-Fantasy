-- Shared by lobby and cafe. Fenced sessions and recoverable two-player trades.
local S={}
local DS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.BagRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local localOnly=Run:IsStudio() and (game.GameId==0 or game.PlaceId==0)
local suffix=Run:IsStudio() and "_Studio_v1" or "_v1"
local store,transactions
-- Unpublished Studio sessions cannot even acquire DataStore handles.
if not localOnly then
 store=DS:GetDataStore("RodeoInventory"..suffix)
 transactions=DS:GetDataStore("RodeoTrades"..suffix)
end
local entries={}
local function freshBag()
 local bag=Rules.new()
 local model=game:GetService("ServerStorage"):FindFirstChild("RodeoMonsterTemplate")
 if model and model:GetAttribute("MossratUserRigRevision")=="ApprovedS1-v1" then
  local species=Catalog.MeadowMouse
  Rules.grant(bag,"MeadowMouse",workspace:GetServerTimeNow(),species.IncomeSeconds,species.IncomeAmount)
  bag.profile.starterMossratGranted=true
 end
 return bag
end
local function copy(value)
 if type(value)~="table" then return value end
 local out={} for k,v in pairs(value) do out[k]=copy(v) end return out
end
local function normalize(data)
 data=data or Rules.new()
 data.eggs=data.eggs or {} data.profile=data.profile or {} data.breedingTeams=data.breedingTeams or {}
 data.balance=data.balance or 0 data.pending=data.pending or 0 data.serial=data.serial or 0
 -- No unapproved offline income; begin the next interval on this server.
 for _,m in ipairs(data.monsters) do m.lastIncome=workspace:GetServerTimeNow() m.assignedPen=nil m.tradeLock=nil end
 return data
end
function S.open(player)
 local token=Http:GenerateGUID(false)
 if localOnly then local data=freshBag() entries[player]={token=token,data=data} player:SetAttribute("StarterMossratGranted",data.profile.starterMossratGranted==true) return data end
 local ok,result=pcall(function()
  return store:UpdateAsync(tostring(player.UserId),function(old)
   old=old or {data=freshBag()}
   if old.lock and old.lock.expires>os.time() then return nil end
   old.lock={token=token,expires=os.time()+120} return old
  end)
 end)
 if not ok or not result or not result.lock or result.lock.token~=token then return nil,"가방을 안전하게 불러오지 못했습니다. 잠시 후 다시 접속해주세요." end
 if result.pendingTrade then
  local pending=result.pendingTrade
  local found,tx=pcall(function() return transactions:GetAsync(pending.id) end)
  if not found then return nil,"거래 기록 확인 중입니다. 잠시 후 다시 접속해주세요." end
  if tx and tx.committed then result.data=pending.after end
  local resolved,saved=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=token then return nil end
    old.data=result.data old.pendingTrade=nil return old
   end)
  end)
  if not resolved or not saved then return nil,"거래 복구 중입니다. 잠시 후 다시 접속해주세요." end
 end
 local data=normalize(result.data)
 player:SetAttribute("StarterMossratGranted",data.profile.starterMossratGranted==true)
 entries[player]={token=token,data=data} return data
end
function S.busy(player) local e=entries[player] return not e or e.busy or e.closed end
function S.save(player,release)
 local e=entries[player] if not e or e.busy or e.closed then return false end
 e.busy=true
 local snapshot=copy(e.data)
 local ok,result=true,true
 if not localOnly then
  ok,result=pcall(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
    old.data=snapshot old.lock=not release and {token=e.token,expires=os.time()+120} or nil return old
   end)
  end)
 end
 e.busy=false
 if ok and result then if release then e.closed=true end return true end
 e.closed=true player:Kick("가방 저장 연결이 끊겨 안전하게 종료합니다. 다시 접속해주세요.") return false
end
function S.trade(a,b,after)
 local ea,eb=entries[a],entries[b]
 if S.busy(a) or S.busy(b) then return false end
 ea.busy=true eb.busy=true
 local id=Http:GenerateGUID(false)
 local ok=true
 if not localOnly then
  ok=pcall(function()
   -- Both before/after images persist before a single durable commit decision.
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or old.pendingTrade then return nil end
     old.data=copy(e.data) old.pendingTrade={id=id,after=copy(after[i])}
     old.lock.expires=os.time()+120 return old
    end)
    assert(written and written.pendingTrade and written.pendingTrade.id==id,"Trade checkpoint rejected")
   end
   transactions:UpdateAsync(id,function(old) return old or {committed=true,users={a.UserId,b.UserId},at=os.time()} end)
   for i,p in ipairs({a,b}) do
    local e=entries[p]
    local written=store:UpdateAsync(tostring(p.UserId),function(old)
     if not old or not old.lock or old.lock.token~=e.token or not old.pendingTrade or old.pendingTrade.id~=id then return nil end
     old.data=copy(after[i]) old.pendingTrade=nil return old
    end)
    assert(written and not written.pendingTrade,"Trade settlement pending")
   end
  end)
 end
 if ok then
  for i,e in ipairs({ea,eb}) do table.clear(e.data) for k,v in pairs(after[i]) do e.data[k]=v end end
 else
  -- Never overwrite uncertain durable transaction state with stale RAM.
  ea.closed=true eb.closed=true
  a:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.") b:Kick("거래 기록을 안전하게 확인하기 위해 재접속해주세요.")
 end
 ea.busy=false eb.busy=false return ok
end
function S.close(player)
 local e=entries[player] if not e then return end
 local deadline=os.clock()+25
 while e.busy and os.clock()<deadline do task.wait(.1) end
 if not e.closed then S.save(player,true) end
 entries[player]=nil
end
task.spawn(function()
 while task.wait(30) do for player,e in pairs(entries) do if not e.closed and not e.busy then S.save(player) end end end
end)
game:BindToClose(function()
 local remaining=0
 for p in pairs(entries) do remaining+=1 task.spawn(function() S.close(p) remaining-=1 end) end
 local deadline=os.clock()+27 while remaining>0 and os.clock()<deadline do task.wait(.1) end
end)
return S
