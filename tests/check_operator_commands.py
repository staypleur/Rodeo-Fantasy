"""Exercise real owner/password gates, parser and final bag grant callback."""
from pathlib import Path
import hashlib,subprocess
R=Path(__file__).resolve().parents[1]
wrap=lambda path:'(function()\n'+(R/path).read_text(encoding='utf-8')+'\nend)()'
capture=(R/'src/server/CaptureServer.server.luau').read_text(encoding='utf-8')
callback=capture.split('register(Catalog,remote,function(player,id,stars,count)\n',1)[1].split('\nend)\nlocal function clearRope',1)[0]
assert 'Progress.' not in callback
code='local hash='+wrap('src/server/OperatorSha256.luau')+'\nlocal Auth='+wrap('src/server/OperatorAuth.luau')+'\nlocal Catalog='+wrap('src/shared/MonsterCatalog.luau')+'\nlocal BagRules='+wrap('src/shared/BagRules.luau')+'\n'
for value in ('','abc','a'*1000,'테스트 salt пароль'):
 import json
 code+='assert(hash('+json.dumps(value,ensure_ascii=False)+')=="'+hashlib.sha256(value.encode()).hexdigest()+'")\n'
code+=r'''
local owner={UserId=42} local outsider={UserId=99}
local clock=100 local serial=0 local notices={} local executed=0
local settings={Salt='test-only-salt-123456',PasswordHash=hash('test-only-salt-123456'..'dummy-test-password')}
local auth=Auth.new(42,settings,hash,function() return clock end,function() serial+=1 return 'nonce-'..serial end,
 function(player,kind,data) assert(player==owner) notices[#notices+1]={kind=kind,data=data} end,
 function(player,operation) assert(player==owner and operation.stars==9) executed+=1 return true end)
local operation={stars=9,description='test'}
assert(not auth.request(outsider,operation) and #notices==0)
assert(auth.request(owner,operation) and executed==0)
local nonce=notices[#notices].data.token
assert(not auth.verify(outsider,{token=nonce,password='dummy-test-password'}))
assert(not auth.verify(owner,{token='forged',password='dummy-test-password'}))
assert(not auth.verify(owner,{token=nonce,password='wrong'}))
clock+=1 assert(auth.verify(owner,{token=nonce,password='dummy-test-password',stars=1}))
assert(executed==1 and not auth.verify(owner,{token=nonce,password='dummy-test-password'}),'challenge is consumed before execution')
clock+=1 assert(auth.request(owner,operation)) nonce=notices[#notices].data.token
clock+=46 assert(not auth.verify(owner,{token=nonce,password='dummy-test-password'}),'expired challenge')
clock+=1 assert(auth.request(owner,operation)) nonce=notices[#notices].data.token
auth.cancel(owner,nonce) assert(not auth.verify(owner,{token=nonce,password='dummy-test-password'}))
clock+=1 assert(auth.request(owner,operation)) nonce=notices[#notices].data.token
for _=1,5 do clock+=1 assert(not auth.verify(owner,{token=nonce,password='wrong'})) end
assert(not auth.request(owner,operation),'five failures lock the account for 60 seconds')
clock+=61 assert(auth.request(owner,operation)) auth.remove(owner)
local disabled=Auth.new(42,{Salt='',PasswordHash=''},hash,function() return clock end,function() error('must not issue challenge') end,function() end,function() error('must not execute') end)
assert(not disabled.request(owner,operation))
local modules={OperatorSettings=settings,OperatorSha256=hash,OperatorAuth=Auth}
local script={Parent={WaitForChild=function(_,name) return name end}}
local require=function(name) return modules[name] end
'''
code+='local Command='+wrap('src/server/OperatorCommands.luau')+r'''
local id,stars,count=Command.parse('/monster 모스랫 9 3',Catalog)
assert(id=='MeadowMouse' and stars==9 and count==3)
for _,id in ipairs(Catalog.Order) do assert(Command.parse('/monster '..id..' 6',Catalog)==id) end
for _,bad in ipairs({'/monster unknown 9','/monster 모스랫 0','/monster 모스랫 10','/monster 모스랫 1.5','/monster 모스랫 nan','/monster 모스랫 9 -1','/monster 모스랫 9 11','/monster 모스랫 9 2 extra','/monster 모스랫','/other 모스랫 9'}) do assert(Command.parse(bad,Catalog)==nil,bad) end
local bags={[owner]=BagRules.new()} local states={} local sync=0 local bagSync=0
local now=function() return 100 end
local send=function(player) assert(player==owner) sync+=1 end
local sendBag=function(player) assert(player==owner) bagSync+=1 end
local grant=function(player,id,stars,count)
'''+callback+r'''
end
assert(grant(owner,'MeadowMouse',9,3))
for i,item in ipairs(bags[owner].monsters) do assert(item.id==i and item.stars==9 and item.lastIncome==100 and item.incomeSeconds==3 and BagRules.income(item)==256 and item.sex) end
assert(sync==1 and bagSync==1 and bags[owner].pending==0)
states[owner]={} assert(not grant(owner,'MeadowMouse',9,3) and #bags[owner].monsters==3)
states[owner]=nil
settings.OwnerUsername='puller3313'
local commandHandler local chatCallbacks={} local latest local receiver
owner.Chatted={Connect=function(_,f) chatCallbacks[42]=f end}
outsider.Chatted={Connect=function(_,f) chatCallbacks[99]=f end}
Enum={ChatVersion={LegacyChatService=0}}
game={GetService=function(_,name)
 if name=='TextChatService' then return {ChatVersion=0} end
 if name=='Players' then return {GetUserIdFromNameAsync=function(_,name) assert(name=='puller3313') return 42 end,
  PlayerRemoving={Connect=function() end},PlayerAdded={Connect=function() end},GetPlayers=function() return {owner,outsider} end} end
 if name=='HttpService' then return {GenerateGUID=function() return 'server-nonce' end} end
 error(name)
end}
local remote={OnServerEvent={Connect=function(_,f) receiver=f end},FireClient=function(_,p,kind,data) assert(p==owner) latest={kind=kind,data=data} end}
Command.register(Catalog,remote,grant)
chatCallbacks[99]('/monster 모스랫 9 3') assert(not latest)
chatCallbacks[42]('/monster 모스랫 9 3') assert(latest.kind=='OperatorPrompt' and #bags[owner].monsters==3)
receiver(outsider,'OperatorVerify',{token='server-nonce',password='dummy-test-password'}) assert(#bags[owner].monsters==3)
receiver(owner,'OperatorVerify',{token='server-nonce',password='dummy-test-password'}) assert(#bags[owner].monsters==6 and latest.data.ok)
print('OPERATOR_COMMANDS_PASS: SHA-256 vectors, owner restriction, per-command password, forged/replayed/expired/cancelled tokens, lockout, blank config disabled, parser and real grant')
'''
p=R/'.tools/check_operator_commands.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
