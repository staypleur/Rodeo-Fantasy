-- Collection and capture XP persist separately from session-only bag contents.
local S={}
local Rules=require(game.ReplicatedStorage.RodeoFantasy.ProgressRules)
local Catalog=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local Run=game:GetService("RunService")
local enabled=Run:IsRunning() and game.GameId>0
local store
if enabled then
 local ok,value=pcall(function() return game:GetService("DataStoreService"):GetDataStore("RodeoExplorer"..(Run:IsStudio() and "_Test_v1" or "_v1")) end)
 enabled=ok store=value
end
local entries={}
local function nameplate(player,level)
 local character=player.Character
 local head=character and character:FindFirstChild("Head")
 if not head then return end
 local gui=head:FindFirstChild("ExplorerNameplate")
 if not gui then
  gui=Instance.new("BillboardGui") gui.Name="ExplorerNameplate" gui.Adornee=head
  gui.Size=UDim2.fromOffset(160,44) gui.Parent=head
  local humanoid=character:FindFirstChildOfClass("Humanoid") if humanoid then humanoid.NameDisplayDistance=0 end
 end
 -- Camera-relative lift plus a fixed screen gap stays above hats at overhead angles.
 gui.StudsOffset=Vector3.new(0,1.5,0) gui.StudsOffsetWorldSpace=Vector3.zero
 gui.SizeOffset=Vector2.new(0,2)
 gui.MaxDistance=120 gui.AlwaysOnTop=true
 require(script.Parent.LevelPlaque).update(gui,level,player.Name or player.DisplayName or "Player")
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
   e.loaded=true e.status="Progress loaded"
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
 e.count+=1 e.dirty=true S.discover(player,id,stars)
end
function S.snapshot(player,includeSeen)
 local e=entries[player]
 local xp=e and e.saved+e.count-e.ack or 0
 local level,fraction,current,required=Rules.bar(xp)
 nameplate(player,level)
 return {xp=xp,level=level,fraction=fraction,current=current,required=required,status=e and e.status or "Loading progress",seen=includeSeen and e and table.clone(e.seen) or nil}
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
  e.dirty=e.count~=count
  for key in pairs(e.seen) do if not data.seen[key] then e.dirty=true end end
 else e.status="Progress temporarily unavailable" warn("Rodeo explorer progress save failed; session checkpoint retained.") end
 e.busy=false
 return ok
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
