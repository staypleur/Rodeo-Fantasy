"""Run the actual lobby speed helper with respawn and missing-character cases."""
from pathlib import Path
import re,subprocess
R=Path(__file__).resolve().parents[1]
source=(R/'src/server/LobbyWorld.luau').read_text(encoding='utf-8')
helper=source.split('function Lobby.prepareCharacter(character)',1)[1].split('for index=1,8 do',1)[0]
speed=re.search(r'Config.LobbyWalkSpeed=(\d+)',(R/'src/shared/Config.luau').read_text(encoding='utf-8')).group(1)
code='local Lobby={}\nlocal game={ReplicatedStorage={RodeoFantasy={Config={}}}}\nlocal require=function(_) return {LobbyWalkSpeed='+speed+'} end\nfunction Lobby.prepareCharacter(character)'+helper+'''
local h={WalkSpeed=16}
local waitCalls=0
local character={FindFirstChildOfClass=function(_,class) assert(class=='Humanoid') return h end,
WaitForChild=function() error('existing humanoid must not wait') end}
Lobby.prepareCharacter(character) assert(h.WalkSpeed==24)
h.WalkSpeed=16 Lobby.prepareCharacter(character) assert(h.WalkSpeed==24,'respawn setup')
Lobby.prepareCharacter(nil)
Lobby.prepareCharacter({FindFirstChildOfClass=function() return nil end,
WaitForChild=function(_,name,timeout) assert(name=='Humanoid' and timeout==10) waitCalls+=1 return h end})
assert(waitCalls==1 and h.WalkSpeed==24)
Lobby.prepareCharacter({FindFirstChildOfClass=function() return nil end,WaitForChild=function() return nil end})
print('LOBBY_SPEED_PASS: 24 on existing/new humanoid, safe missing character/humanoid')
'''
harness=R/'.tools/lobby_speed_harness.luau';harness.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(harness.relative_to(R))],cwd=R,check=True)
