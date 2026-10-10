"""Review geometry/entry structure and real server selection rules; no device claims."""
from pathlib import Path
import json, subprocess
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'assets/courses/SpaceLobby/layout.json').read_text())
blocks=data['blocks']
assert len(blocks)<1000
for slot in range(1,9):
 room=[b for b in blocks if b['group']==f'Room_{slot}']
 assert sum(b['name'].startswith('EggSocket_') for b in room)==4
 assert sum(b['name'].startswith('Incubator_') for b in room)==4
 for name in ('DoorLeft','DoorRight','DoorSensor','DoorHeader','Ceiling','DoorStep'):
  assert sum(b['name']==name for b in room)==1
for group in ('Shop_1','Shop_2','DistanceRanking','JournalRanking','Roulette','BattlePass'):
 assert sum(b['group']==group and b['name']=='StationBoard' for b in blocks)==1
assert not any('Monster' in b['name'] or b['name']=='Egg' for b in blocks)
for b in blocks:
 assert b['pos'][0]%4==0 and b['pos'][2]%4==0 and b['pos'][1]%2==0
 assert all(v>0 and v%4==0 for v in b['size'])
assert sum(b['name']=='HullWall' for b in blocks)==8
source=(ROOT/'src/shared/DepartureSelectionRules.luau').read_text(encoding='utf-8')
harness='local R=(function()\n'+source+'\nend)()\n'+'''
local owned={id=3,monsterId="MeadowMouse",stars=1}
local bag={monsters={owned}}
local catalog={MeadowMouse={}}
local ready=function() return true end
assert(R.validate(bag,"GreenStar",3,catalog,ready)==owned)
local function reject(planet,id,reason)
 local item,errorCode=R.validate(bag,planet,id,catalog,ready)
 assert(item==nil and errorCode==reason)
end
reject("FakePlanet",3,"UnknownDestination")
reject("GreenStar",4,"NotOwned")
reject("GreenStar","3","InvalidMonster")
reject("GreenStar",0/0,"InvalidMonster")
reject("GreenStar",3.5,"InvalidMonster")
owned.tradeLock=true reject("GreenStar",3,"MonsterBusy") owned.tradeLock=nil
owned.breedingTeam=1 reject("GreenStar",3,"MonsterBusy") owned.breedingTeam=nil
local found,reason=R.validate(bag,"GreenStar",3,catalog,function() return false end)
assert(found==nil and reason=="ModelPending")
catalog.MeadowMouse=nil reject("GreenStar",3,"UnknownSpecies")
print("SPACE_LOBBY_RULES_PASS: ownership, numeric inventory IDs, locks, planet whitelist, model readiness")
'''
path=ROOT/'.tools/test_space_lobby_rules.luau';path.write_text(harness,encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path.relative_to(ROOT))],cwd=ROOT,check=True)
for file in ('src/authoring/SpaceLobbyLayout.luau','src/authoring/SpaceLobbyReview.luau','src/authoring/SpaceLobbyDoors.server.luau','src/shared/SpaceLobbyConfig.luau','src/shared/DepartureSelectionRules.luau','dist/ReviewModels/CreateSpaceLobby.commandbar.lua'):
 subprocess.run([str(ROOT/'.tools/luau/luau-compile.exe'),file],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
print('SPACE_LOBBY_REVIEW_PASS: 8 rooms/32 sockets, 6 stations, structural grids, compiled generator/doors/bundle; Studio execution pending')
