"""Startup dependency, upload-preservation and ownership regression checks."""
from pathlib import Path
import subprocess,re,xml.etree.ElementTree as E,json
R=Path(__file__).resolve().parents[1]
root=E.parse(R/'dist/RodeoFantasy-New.rbxlx').getroot()
def name(n):return n.findtext("Properties/string[@name='Name']")
player=next(n for n in root.findall('Item') if n.get('class')=='StarterPlayer')
clients=next(n for n in player.findall('Item') if name(n)=='StarterPlayerScripts')
client_names={name(n) for n in clients.findall('Item')}
for n in clients.findall('Item'):
 source=n.findtext("Properties/ProtectedString[@name='Source']") or ''
 for dependency in re.findall(r'script.Parent:WaitForChild\("([^"]+)"\)',source):
  assert dependency in client_names,(name(n),dependency)
ride=(R/'src/client/RideAnimator.luau').read_text(encoding='utf-8')
assert 'WaitForChild("MountRoot")' not in ride
source=(R/'src/server/CaptureServer.server.luau').read_text(encoding='utf-8')
assert source.index('local startingMounts={}')<source.index('local function start(')
assert 'nextWorld.spawn(Vector3.new(0,2,-8),picked.monsterId,picked.stars)' in source
paths=[str(p.relative_to(R)) for d in ('shared','server','client') for p in (R/'src'/d).glob('*.luau')]
result=subprocess.run([str(R/'.tools/luau/luau-analyze.exe'),*paths],cwd=R,capture_output=True,text=True)
allowed=set('game workspace script task warn CFrame Vector3 Vector2 Color3 UDim UDim2 Enum Instance ColorSequence NumberSequence ColorSequenceKeypoint NumberSequenceKeypoint NumberRange RaycastParams OverlapParams TweenInfo typeof tick time shared settings UserSettings utf8 Random Rect BrickColor Axes Faces Region3 DateTime buffer Font'.split())
unknown=set(re.findall(r"Unknown global '([^']+)'",result.stdout+result.stderr))-allowed
assert not unknown,unknown
subprocess.run([str(R/'.tools/luau/luau-compile.exe'),'dist/UpdateCurrentProject.commandbar.lua'],cwd=R,check=True,stdout=subprocess.DEVNULL)
# Exercise real summon validation: other areas/rooms, invalid/locked IDs, missing models.
rules=(R/'src/shared/SocialRules.luau').read_text(encoding='utf-8')
companions=(R/'src/server/LobbyCompanions.luau').read_text(encoding='utf-8')
h='''
local signals={}
local remote={FireClient=function(_,p,kind,message) table.insert(signals,message) end}
local bag={monsters={{id=1,monsterId="MeadowMouse",stars=1},{id=2,monsterId="MeadowMouse",stars=1,tradeLock=true}}}
local map={WaitForChild=function() end}
local catalog={visual=function() return "VisualTemplate" end}
local pureRules=(function()
'''+rules+'''
end)()
local package={MonsterCatalog=catalog,SocialRules=pureRules,CaptureRemote=remote,FindFirstChild=function() return nil end}
game={ReplicatedStorage={RodeoFantasy=package},GetService=function() return {Heartbeat={Connect=function() end}} end}
workspace={WaitForChild=function() return map end}
Instance={new=function() return {} end}
RaycastParams={new=function() return {} end}
Enum={RaycastFilterType={Include=1}}
require=function(v) return v end
local Module=(function()
'''+companions+'''
end)()
local player={Character={FindFirstChild=function() return {} end},SetAttribute=function() end}
local active,ownedRoom=false,false
local api=Module.new({bag=function() return bag end,canAct=function() return active end,canSummon=function() return ownedRoom end})
api.summon(player,1) assert(#signals==0)
active=true api.summon(player,1) assert(#signals==1 and string.find(signals[1],"부화실"))
ownedRoom=true
for _,id in ipairs({-1,0,1.5,2,"1",{}}) do api.summon(player,id) end
assert(#signals==1,"Invalid and locked IDs cannot summon")
api.summon(player,1) assert(#signals==2,"Missing approved model reports readiness")
print("LOBBY_SUMMON_GUARDS_PASS: active area, owned room, IDs, locks, missing model")
'''
(R/'.tools/test_lobby_guards.luau').write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_lobby_guards.luau'],cwd=R,check=True)
print('LOBBY_UPDATE_PASS: client dependencies, scoped selection, selected mount, no unexpected globals, update compilation')
