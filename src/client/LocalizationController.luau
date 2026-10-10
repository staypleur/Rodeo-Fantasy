local C={}
local service=game:GetService("LocalizationService")
local player=game:GetService("Players").LocalPlayer
local L=require(game.ReplicatedStorage.RodeoFantasy.Localization)
local records=setmetatable({},{__mode="k"})
local translator,cache,inflight=nil,{},{}
-- The user chose English for all current game UI, regardless of account locale.
function C.locale() return "en-us" end
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
