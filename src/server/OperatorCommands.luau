-- Owner-only chat commands. No client privilege flag or operator button.
local M={}
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
local package=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local Catalog=require(package:WaitForChild("MonsterCatalog"))
local Names=require(package:WaitForChild("Localization")).entries
local Rules=require(package:WaitForChild("MonsterCommandRules"))
-- Verified in Studio: puller3313, UserId 3116679300.
local ownerId=3116679300
function M.register(context)
 local function run(player,text)
  if not ownerId or player.UserId~=ownerId then return end
  local request=Rules.parse(text,Catalog,Names)
  if not request then return end
  if request.help or request.invalid then context.message(player,Rules.help(Catalog,Names)) return end
  context.grant(player,request.id,request.stars,request.count)
 end
 if TextChatService.ChatVersion==Enum.ChatVersion.TextChatService then
  for _,alias in ipairs({"/monster","/operator"}) do
   local command=Instance.new("TextChatCommand") command.Name=alias=="/monster" and "RodeoOwnerMonster" or "RodeoOwnerHelp"
   command.PrimaryAlias=alias command.Parent=TextChatService
   command.Triggered:Connect(function(source,text)
    local player=source and Players:GetPlayerByUserId(source.UserId)
    if player then run(player,text) end
   end)
  end
 else
  local function added(player) player.Chatted:Connect(function(text) run(player,text) end) end
  Players.PlayerAdded:Connect(added)
  for _,player in ipairs(Players:GetPlayers()) do added(player) end
 end
end
return M
