-- Owner-only chat commands. No client privilege flag or operator button.
local M={}
local Players=game:GetService("Players")
local TextChatService=game:GetService("TextChatService")
-- Verified in Studio: puller3313, UserId 3116679300.
local ownerId=3116679300
function M.register(context)
 local function run(player,text)
  if not ownerId or player.UserId~=ownerId then return end
  local parts=string.split(text," ")
  local command=string.lower(parts[1] or "")
  if command=="/operator" then context.message(player,"Commands: /monster Mossrat <stars 1-10> [count 1-10]") return end
  if command~="/monster" then return end
  local species=string.lower(parts[2] or "")
  local stars,count=tonumber(parts[3]),tonumber(parts[4] or "1")
  if (species~="mossrat" and species~="meadowmouse" and species~="모스랫") or not stars or stars%1~=0 or stars<1 or stars>10
   or not count or count%1~=0 or count<1 or count>10 or #parts>4 then
   context.message(player,"Usage: /monster Mossrat <stars 1-10> [count 1-10]") return
  end
  context.grant(player,"MeadowMouse",stars,count)
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
