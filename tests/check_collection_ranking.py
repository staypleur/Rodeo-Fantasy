"""Run actual collection persistence/index code with deterministic DataStore stubs."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def module(name):return '(function()\n'+(R/f'src/shared/{name}.luau').read_text(encoding='utf-8')+'\nend)()'
s='local Rules='+module('ProgressRules')+'\nlocal Catalog='+module('MonsterCatalog')+'\n'
s+=r"""
assert(Rules.discovered({['MeadowMouse:1']=true,['MeadowMouse:2']=true,['unknown:1']=true,['GrassBoar:3']=false},Catalog)==1)
local stored={seen={['MeadowMouse:1']=true},captures=200,sessions={}} local score=0 local failIndex=false
local profile={GetAsync=function() return stored end,UpdateAsync=function(_,key,fn) stored=fn(stored) return stored end}
local ordered={UpdateAsync=function(_,key,fn) if failIndex then error('temporary index outage') end score=fn(score) return score end}
local DSS={GetDataStore=function(_,name) assert(name=='RodeoExplorer_Test_v1') return profile end,GetOrderedDataStore=function(_,name) assert(name=='RodeoCollection_Test_v1') return ordered end}
local game={GameId=1,ReplicatedStorage={RodeoFantasy={ProgressRules='Rules',MonsterCatalog='Catalog'}}}
function game:GetService(name) return ({RunService={IsRunning=function() return true end,IsStudio=function() return true end},HttpService={GenerateGUID=function() return 'session' end},DataStoreService=DSS})[name] end
local task={spawn=function(fn) fn() end} local warn=function() end
local require=function(name) return name=='Rules' and Rules or Catalog end
local S=(function()
"""
s+=(R/'src/server/ProgressService.luau').read_text(encoding='utf-8')
s+=r"""
end)()
local p={UserId=123}
S.join(p) assert(S.save(p) and score==1,'existing discoveries migrate to collection index')
S.caught(p,'MeadowMouse',1) assert(not S.save(p) and score==1,'duplicate catches must not increase score')
S.discover(p,'MeadowMouse',3)
stored.seen['Weedcrow:6']=true -- another server's discovery arrives before this save
failIndex=true assert(not S.save(p) and score==1)
failIndex=false assert(S.save(p) and score==3,'index failure must keep dirty checkpoint for retry')
assert(stored.captures==200,'historic capture data must not be rewritten as collection score')
score=4 S.discover(p,'GrassBoar',1) S.save(p) assert(score==4,'concurrent index cannot decrease')
S.leave(p)
print('COLLECTION_RANKING_PASS: unique valid stages, loaded-record migration, duplicate catches, concurrent discovery union, index outage/retry and separate score history')
"""
s+='local RecordRules='+module('RecordRules')+'\n'
s+=r"""
local recordProfile={UpdateAsync=function(_,key,fn) return fn(nil) end}
local distanceWrites=0
local dist={UpdateAsync=function(_,key,fn) distanceWrites+=1 return fn(0) end,GetSortedAsync=function() return {GetCurrentPage=function() return {{key='123',value=123}} end} end}
ordered.GetSortedAsync=function() return {GetCurrentPage=function() return {{key='123',value=score}} end} end
DSS.GetDataStore=function(_,name) assert(name=='RodeoRecords_Test_v1') return recordProfile end
DSS.GetOrderedDataStore=function(_,name)
 if name=='RodeoDistance_Test_v1' then return dist end
 assert(name=='RodeoCollection_Test_v1','production index must not be used') return ordered
end
local oldService=game.GetService
game.GetService=function(self,name) if name=='Players' then return {GetNameFromUserIdAsync=function() return 'TestPlayer' end} end return oldService(self,name) end
function game:BindToClose() end
local function board(name) return {Name=name,Ranking={Heading={},Entries={}},GetAttribute=function() return false end,SetAttribute=function() end} end
local boards={Distance=board('Distance'),Income=board('Income')}
local workspace={RodeoLobby={Leaderboards=boards}}
game.ReplicatedStorage.RodeoFantasy.RecordRules='RecordRules'
local require=function(name) return name=='RecordRules' and RecordRules or Catalog end
local task={spawn=function(fn,...) local c=coroutine.create(fn) assert(coroutine.resume(c,...)) end,wait=function() coroutine.yield() end}
local Records=(function()
"""
s+=(R/'src/server/RecordService.luau').read_text(encoding='utf-8')
s+=r"""
end)()
Records.sample(p,1000000,123) assert(Records.save(123) and distanceWrites==1)
Records.start()
assert(boards.Income.Ranking.Heading.Text=='Collection discoveries')
assert(boards.Income.Ranking.Entries.Text=='1. TestPlayer   4 / 20')
assert(boards.Distance.Ranking.Entries.Text=='1. TestPlayer   123 m')
print('RANK_BOARD_PASS: collection index/title/discovery total, distance retained, production index unused')
"""
path=R/'.tools/collection_ranking.luau';path.write_text(s,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
