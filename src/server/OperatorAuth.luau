-- Every operation gets its own owner-only, expiring password challenge.
local M={}
local function equal(a,c)
 if #a~=#c then return false end
 local diff=0 for i=1,#a do diff=bit32.bor(diff,bit32.bxor(a:byte(i),c:byte(i))) end
 return diff==0
end
function M.new(ownerId,settings,hash,clock,token,notify,execute)
 local pending,attempts,requested={},{},{}
 local self={}
 function self.request(player,operation)
  if not ownerId or player.UserId~=ownerId then return false end
  local now=clock() local rate=attempts[player]
  if rate and now<(rate.lockedUntil or 0) then notify(player,'OperatorResult',{ok=false,message='확인을 여러 번 실패했습니다. 60초 후 다시 시도하세요.'}) return false end
  if now-(requested[player] or -math.huge)<1 then return false end
  requested[player]=now
  if #settings.PasswordHash~=64 or #settings.Salt<16 then notify(player,'OperatorResult',{ok=false,message='먼저 컴퓨터에서 운영자 비밀번호 설정 도구를 실행하세요.'}) return false end
  local nonce=token()
  pending[player]={token=nonce,expires=now+45,operation=operation}
  notify(player,'OperatorPrompt',{token=nonce,description=operation.description})
  return true
 end
 function self.cancel(player,nonce)
  if pending[player] and pending[player].token==nonce then pending[player]=nil end
 end
 function self.verify(player,value)
  if player.UserId~=ownerId or type(value)~='table' or type(value.token)~='string' or type(value.password)~='string' or #value.password>256 then return false end
  local entry=pending[player] local now=clock()
  if not entry or entry.token~=value.token then return false end
  if entry.expires<now then pending[player]=nil notify(player,'OperatorResult',{ok=false,message='확인 시간이 지났습니다. 명령어를 다시 입력하세요.'}) return false end
  local rate=attempts[player] or {failures=0,last=-math.huge} attempts[player]=rate
  if now<(rate.lockedUntil or 0) then return false end
  if now-rate.last<1 then notify(player,'OperatorResult',{ok=false,retry=true,message='1초 후 다시 확인하세요.'}) return false end
  rate.last=now
  if not equal(hash(settings.Salt..value.password),settings.PasswordHash) then
   rate.failures+=1
   if rate.failures>=5 then rate.failures=0 rate.lockedUntil=now+60 pending[player]=nil end
   notify(player,'OperatorResult',{ok=false,retry=pending[player]~=nil,message=pending[player] and '비밀번호가 맞지 않습니다.' or '60초 후 명령어를 다시 입력하세요.'})
   return false
  end
  pending[player]=nil attempts[player]=nil -- consume before executing; no replay or cached login
  local ok,result=pcall(execute,player,entry.operation)
  notify(player,'OperatorResult',{ok=ok and result~=false,message=ok and result~=false and '운영자 명령어를 실행했습니다.' or '실행할 수 없습니다. 로비에서 다시 시도하세요.'})
  return ok and result~=false
 end
 function self.remove(player) pending[player]=nil attempts[player]=nil requested[player]=nil end
 return self
end
return M
