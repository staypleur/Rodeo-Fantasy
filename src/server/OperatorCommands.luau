-- Owner-only operator commands. All future commands use the same password gate.
local M={}
local aliases={['모스랫']='MeadowMouse',['브램블보어']='GrassBoar',['바인팽']='TreeWolf',['쏜크로']='Weedcrow',['엘레바인']='RockElephant'}
local names={} for name,id in pairs(aliases) do names[id]=name end
function M.parse(text,catalog)
 if type(text)~='string' or #text>160 then return nil end
 local tokens={} for token in text:gmatch('%S+') do table.insert(tokens,token) end
 if tokens[1]~='/monster' or (#tokens~=3 and #tokens~=4) then return nil end
 local id=aliases[tokens[2]] or tokens[2]
 local valid=false for _,candidate in ipairs(catalog.Order) do if candidate==id then valid=true break end end
 local stars,count=tonumber(tokens[3]),tonumber(tokens[4] or '1')
 if not valid or not stars or stars~=stars or stars%1~=0 or stars<1 or stars>9
  or not count or count~=count or count%1~=0 or count<1 or count>10 then return nil end
 return id,stars,count
end
function M.register(catalog,remote,grant)
 local chat=game:GetService('TextChatService')
 local players=game:GetService('Players')
 local settings=require(script.Parent:WaitForChild('OperatorSettings'))
 local hash=require(script.Parent:WaitForChild('OperatorSha256'))
 local Auth=require(script.Parent:WaitForChild('OperatorAuth'))
 local ok,ownerId=pcall(function() return players:GetUserIdFromNameAsync(settings.OwnerUsername) end)
 if not ok or type(ownerId)~='number' or ownerId<=0 then warn('운영자 계정 확인 실패: 운영자 명령어를 비활성화합니다.') return end
 local auth=Auth.new(ownerId,settings,hash,os.clock,function() return game:GetService('HttpService'):GenerateGUID(false) end,
  function(player,kind,data) remote:FireClient(player,kind,data) end,
  function(player,operation) return grant(player,operation.id,operation.stars,operation.count) end)
 players.PlayerRemoving:Connect(auth.remove)
 local function process(player,text)
  if player.UserId~=ownerId then
   remote:FireClient(player,'OperatorResult',{ok=false,message='이 계정은 운영자 권한이 없습니다.'}) return
  end
  local id,stars,count=M.parse(text,catalog)
  if not id then
   if type(text)=='string' and text:match('^/monster') then remote:FireClient(player,'OperatorResult',{ok=false,message='사용법: /monster 모스랫 9 (마릿수 1~10 선택). 별은 1~9입니다.'}) end
   return
  end
  auth.request(player,{id=id,stars=stars,count=count,description=string.format('%s · %d성 · %d마리 지급',names[id] or id,stars,count)})
 end
 remote.OnServerEvent:Connect(function(player,action,value)
  if action=='OperatorVerify' then auth.verify(player,value)
  elseif action=='OperatorCancel' and type(value)=='string' then auth.cancel(player,value)
  elseif action=='OperatorStatus' then remote:FireClient(player,'OperatorStatus',{allowed=player.UserId==ownerId})
  elseif action=='OperatorRequest' and type(value)=='string' and #value<=160 then process(player,value) end
 end)
 -- Saved places can use a legacy chat window even when ChatVersion differs.
 -- Both entry paths pass through the same server owner check/password challenge.
 local function connect(player)
  player.Chatted:Connect(function(text) if type(text)=='string' and text:match('^/monster') then process(player,text) end end)
 end
 players.PlayerAdded:Connect(connect)
 for _,player in ipairs(players:GetPlayers()) do connect(player) end
 if chat.ChatVersion==Enum.ChatVersion.LegacyChatService then return end
 local command=Instance.new('TextChatCommand')
 command.Name='OperatorMonsterCommand' command.PrimaryAlias='/monster'
 command.Triggered:Connect(function(source,text)
  if not source then return end
  local player=players:GetPlayerByUserId(source.UserId)
  if not player then return end
  process(player,text)
 end)
 command.Parent=chat
end
return M
