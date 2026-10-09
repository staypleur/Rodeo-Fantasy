"""Exercise collection service without granting removed level/XP rewards."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def module(name):return '(function()\n'+(R/f'src/shared/{name}.luau').read_text(encoding='utf-8')+'\nend)()'
s='local Rules='+module('ProgressRules')+'\nlocal C='+module('MonsterCatalog')+'\n'
s+=r"""
local game={GameId=0,ReplicatedStorage={RodeoFantasy={ProgressRules='Rules',MonsterCatalog='C'}}}
function game:GetService(name)
 if name=='RunService' then return {IsRunning=function() return false end} end
 if name=='HttpService' then return {GenerateGUID=function() return 'test' end} end
 error('Unexpected service '..name)
end
local require=function(name) return name=='Rules' and Rules or C end
local Service=(function()
"""
s+=(R/'src/server/ProgressService.luau').read_text(encoding='utf-8')
s+=r"""
end)()
local player={UserId=123}
Service.join(player)
Service.caught(player,'MeadowMouse',1) Service.caught(player,'MeadowMouse',1)
Service.discover(player,'MeadowMouse',3)
local state=Service.snapshot(player,true)
assert(state.seen['MeadowMouse:1'] and state.seen['MeadowMouse:3'])
assert(state.captures==2 and state.caught['MeadowMouse:1']==2)
assert(not state.level and not state.xp and not state.fraction and not state.required)
assert(not Service.snapshot(player).seen)
Service.leave(player)
print('COLLECTION_SERVICE_PASS: discoveries retained, level/XP rewards and payload absent')
"""
path=R/'.tools/collection_service.luau';path.write_text(s,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
