-- Collection discoveries persist separately from session-only bag contents.
local S={}
local Rules=require(game.ReplicatedStorage.RodeoFantasy.ProgressRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Run=game:GetService("RunService")
local enabled=Run:IsRunning() and game.GameId>0
local store,collection
if enabled then
 local ok,value=pcall(function()
  local ds=game:GetService("DataStoreService")
  local suffix=Run:IsStudio() and "_Test_v1" or "_v1"
  collection=ds:GetOrderedDataStore("RodeoCollection"..suffix)
  return ds:GetDataStore("RodeoExplorer"..suffix)
 end)
 enabled=ok store=value
end
local entries={}
local function hideNameplate(player)
 local character=player.Character
 if not character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid.NameDisplayDistance=0 end
 for _,node in ipairs(character:GetDescendants()) do
  if node:IsA("BillboardGui") and node.Name=="ExplorerNameplate" then node:Destroy() end
 end
end

function S.join(player)
 local e={session=game:GetService("HttpService"):GenerateGUID(false),count=0,ack=0,saved=0,seen={},dirty=false,loading=enabled,loaded=not enabled,status=enabled and "Loading progress" or "Session progress"}
 entries[player]=e
 if enabled then task.spawn(function()
  local ok,data=pcall(function() return store:GetAsync(tostring(player.UserId)) end)
  if entries[player]~=e then return end
  e.loading=false
  if ok then
   data=data or {} e.saved=data.captures or 0
   for key,v in pairs(data.seen or {}) do if v then e.seen[key]=true end end
   e.loaded=true e.dirty=true e.status="Progress loaded"
  else e.status="Progress temporarily unavailable" end
 end) end
end
function S.discover(player,id,stars)
 local e=entries[player] if not e or not Catalog[id] then return end
 local key=id..":"..Catalog.stage(stars or 1)
 if not e.seen[key] then e.seen[key]=true e.dirty=true end
end
function S.caught(player,id,stars)
 local e=entries[player] if not e then return end
 S.discover(player,id,stars)
end
function S.snapshot(player,includeSeen)
 local e=entries[player]
 hideNameplate(player)
 return {status=e and e.status or "Loading progress",seen=includeSeen and e and table.clone(e.seen) or nil}
end
function S.save(player)
 local e=entries[player]
 if not enabled or not e or e.loading or e.busy or not e.dirty then return false end
 e.busy=true
 local count,seen=e.count,table.clone(e.seen)
 local ok,data=pcall(function()
  return store:UpdateAsync(tostring(player.UserId),function(old) return Rules.merge(old,e.session,count,seen,os.time()) end)
 end)
 if ok then
  e.saved=data.captures e.ack=count e.loaded=true e.status="Progress saved"
  for key,v in pairs(data.seen) do if v then e.seen[key]=true end end
  local indexed=pcall(function()
   local discovered=Rules.discovered(data.seen,Catalog)
   collection:UpdateAsync(tostring(player.UserId),function(old) return math.max(old or 0,discovered) end)
  end)
  e.dirty=not indexed or e.count~=count
  for key in pairs(e.seen) do if not data.seen[key] then e.dirty=true end end
 else e.status="Progress temporarily unavailable" warn("Rodeo explorer progress save failed; session checkpoint retained.") end
 e.busy=false
 return ok and not e.dirty
end
function S.leave(player)
 local e=entries[player] if not e then return end
 e.left=true S.save(player)
 if not enabled or not e.dirty then entries[player]=nil end
end
function S.start()
 if not enabled then return end
 task.spawn(function()
  while true do
   task.wait(60)
   for player,e in pairs(entries) do
    task.spawn(function() S.save(player) if e.left and not e.dirty then entries[player]=nil end end)
   end
  end
 end)
 game:BindToClose(function()
  local waiting=0
  for player in pairs(entries) do waiting+=1 task.spawn(function() S.save(player) waiting-=1 end) end
  local deadline=os.clock()+25 while waiting>0 and os.clock()<deadline do task.wait(.1) end
 end)
end
return S
