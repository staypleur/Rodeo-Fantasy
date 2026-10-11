from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
source = (root / 'src/server/ProgressService.luau').read_text(encoding='utf-8')
harness = '''
local catalog={MeadowMouse={},stage=function(stars) return stars>=9 and 9 or stars>=6 and 6 or stars>=3 and 3 or 1 end}
local game={GameId=0,ReplicatedStorage={RodeoFantasy={ProgressRules={},MonsterCatalog=catalog}}}
function game:GetService(name)
 if name=="RunService" then return {IsRunning=function() return false end} end
 if name=="HttpService" then return {GenerateGUID=function() return "test" end} end
end
local require=function(value) return value end
local Progress=(function()
''' + source + '''
end)()
local player={GetAttribute=function() return false end}
Progress.join(player,{monsters={{monsterId="MeadowMouse",stars=3}}})
local snapshot=Progress.snapshot(player,true)
assert(snapshot.seen["MeadowMouse:3"] and snapshot.captures==0)
Progress.discover(player,"MeadowMouse",6)
Progress.discover(player,"MeadowMouse",6)
snapshot=Progress.snapshot(player,true)
assert(snapshot.seen["MeadowMouse:6"] and snapshot.captures==0)
assert(next(snapshot.caught)==nil)
print("DISCOVERY_REPAIR_PASS: owned 3-star restored; evolution discovery does not inflate catches")
'''
target=root/'.tools/test_discovery_repair.luau'
target.parent.mkdir(exist_ok=True)
target.write_text(harness,encoding='utf-8')
subprocess.run([str(root/'.tools/luau/luau.exe'),'.tools/test_discovery_repair.luau'],cwd=root,check=True)
