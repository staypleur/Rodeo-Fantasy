-- Global records only. Bag contents and spendable balance are still session-only.
local Service={}
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Rules=require(game.ReplicatedStorage.RodeoFantasy.RecordRules)
local enabled=RunService:IsRunning() and game.GameId>0
local suffix=RunService:IsStudio() and "_Test_v1" or "_v1"
local profile,distance,income
if enabled then
 local ok=pcall(function()
  profile=DSS:GetDataStore("RodeoRecords"..suffix)
  distance=DSS:GetOrderedDataStore("RodeoDistance"..suffix)
  income=DSS:GetOrderedDataStore("RodeoProduction"..suffix)
 end)
 enabled=ok
end
local entries,names={},{}
function Service.sample(player,produced,meters)
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
   income:UpdateAsync(tostring(userId),function(old) return math.max(old or 0,result.income) end)
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
  local value=tostring(row.value)..(board.Name=="Distance" and " m" or "")
  table.insert(lines,string.format("%d. %s   %s",rank,names[id] or "Player",value))
 end
 label.Text=#lines>0 and table.concat(lines,"\n") or "No records yet"
 board:SetAttribute("HasRecords",true)
end
function Service.start()
 local boards=workspace.RodeoLobby.Leaderboards
 task.spawn(function()
  while true do
   refresh(boards.Distance,distance) refresh(boards.Income,income)
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
