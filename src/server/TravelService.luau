-- Server distance only. Sparse snapshots and idempotent saves, no frame-level requests.
local S={}
local Run=game:GetService("RunService")
local P=game.ReplicatedStorage.RodeoFantasy
local Rules=require(P.TravelRules)
local Planets=require(P.PlanetCatalog)
local enabled=Run:IsRunning() and game.GameId>0
local suffix=Run:IsStudio() and "_Test_v1" or "_v1"
local profile,index
if enabled then
 local ok=pcall(function()
  local ds=game:GetService("DataStoreService")
  profile=ds:GetDataStore("RodeoTravel"..suffix)
  index=ds:GetOrderedDataStore("RodeoTotalDistance"..suffix)
 end)
 enabled=ok
end
local entries={}
function S.join(player)
 local e={session=game.HttpService:GenerateGUID(false),meters={},saved={},ack={},dirty=false,loading=enabled,loaded=not enabled}
 entries[player]=e
 if enabled then task.spawn(function()
  local ok,data=pcall(function() return profile:GetAsync(tostring(player.UserId)) end)
  if entries[player]~=e then return end
  e.loading=false
  if ok then e.saved=type(data)=="table" and data.planetMeters or {} e.saved=e.saved or {} e.loaded=true end
 end) end
end
function S.sample(player,planet,run,meters)
 local e=entries[player]
 if not e or not run or not Planets[planet] or type(meters)~="number" or meters~=meters or meters<0 or meters==math.huge then return end
 if e.run~=run then e.run=run e.last=0 end
 local delta=math.max(0,meters-e.last)
 e.last=math.max(e.last,meters)
 if delta>0 then e.meters[planet]=(e.meters[planet] or 0)+delta e.dirty=true end
end
function S.snapshot(player)
 local e=entries[player] local meters={}
 if e then
  for id,v in pairs(e.saved) do meters[id]=v end
  for id,v in pairs(e.meters) do meters[id]=(meters[id] or 0)+v-(e.ack[id] or 0) end
 end
 return {loaded=e and e.loaded or false,planetMeters=meters,unlocked=Rules.unlocks(Planets.Order,meters),requiredMeters=Rules.UnlockMeters}
end
function S.canEnter(player,id)
 if id==Planets.Order[1] then return true end
 local progress=S.snapshot(player)
 return progress.loaded and progress.unlocked[id]==true
end
function S.save(player)
 local e=entries[player]
 if not enabled or not e or e.loading or e.busy or not e.dirty then return false end
 e.busy=true
 local checkpoint=table.clone(e.meters)
 local ok,data=pcall(function()
  return profile:UpdateAsync(tostring(player.UserId),function(old) return Rules.merge(old,e.session,checkpoint,os.time()) end)
 end)
 if ok then
  e.saved=data.planetMeters e.ack=checkpoint e.loaded=true
  local indexed=pcall(function() index:UpdateAsync(tostring(player.UserId),function(old) return math.max(old or 0,data.totalMeters) end) end)
  e.dirty=not indexed
  for id,v in pairs(e.meters) do if v~=(checkpoint[id] or 0) then e.dirty=true end end
 else warn("Cumulative distance save failed; checkpoint retained.") end
 e.busy=false
 return ok and not e.dirty
end
function S.leave(player)
 local e=entries[player] if not e then return end
 e.left=true S.save(player)
 if not enabled or not e.dirty then entries[player]=nil end
end
function S.flush(player)
 local e=entries[player]
 if not e or not e.dirty then return true end
 return S.save(player)
end
function S.start()
 if not enabled then return end
 task.spawn(function()
  while task.wait(60) do for player,e in pairs(entries) do task.spawn(function()
   S.save(player) if e.left and not e.dirty then entries[player]=nil end
  end) end end
 end)
 game:BindToClose(function()
  local waiting=0
  for player in pairs(entries) do waiting+=1 task.spawn(function() S.save(player) waiting-=1 end) end
  local deadline=os.clock()+25 while waiting>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return S
