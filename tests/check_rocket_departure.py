"""Exercise the real selection service and compile exact integration patches."""
from pathlib import Path
import sys, subprocess
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from build_rocket_departure import patch,SERVER_PATCHES,CLIENT_PATCHES,LOBBY_PATCHES
def run(path):
 subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path.relative_to(ROOT))],cwd=ROOT,check=True)
def compile_file(path):
 subprocess.run([str(ROOT/'.tools/luau/luau-compile.exe'),str(path.relative_to(ROOT))],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
for file,patches in [('src/server/CaptureServer.server.luau',SERVER_PATCHES),('src/client/CaptureClient.client.luau',CLIENT_PATCHES),('src/server/LobbyWorld.luau',LOBBY_PATCHES)]:
 original=(ROOT/file).read_text(encoding='utf-8')
 patched=patch(original,patches)
 # Preserve unrelated changes, reject repeated/unknown source versions.
 assert patch('-- unrelated user changes\n'+original+'\n-- user footer',patches)=='-- unrelated user changes\n'+patched+'\n-- user footer'
 try: patch(patched,patches)
 except ValueError: pass
 else: raise AssertionError('Repeated patches must fail preflight')
 path=ROOT/'.tools'/('rocket_'+Path(file).name)
 path.write_text(patched,encoding='utf-8'); compile_file(path)
rules=(ROOT/'src/shared/DepartureSelectionRules.luau').read_text(encoding='utf-8')
service=(ROOT/'src/server/RocketDepartureService.luau').read_text(encoding='utf-8').replace('local Rules=require(game:GetService("ReplicatedStorage").RodeoFantasy.DepartureSelectionRules)','local Rules=(function()\n'+rules+'\nend)()')
harness='local Service=(function()\n'+service+'\nend)()\n'+'''
local time,serial,launches=0,0,0
local near,modelReady,courseReady,launchWorks=true,true,true,true
local bag={monsters={{id=1,monsterId="MeadowMouse",stars=1},{id=2,monsterId="MeadowMouse",stars=3}}}
local events={}
local api=Service.new({
 now=function() return time end,token=function() serial+=1 return "token"..serial end,
 canOpen=function() return near end,bag=function() return bag end,catalog={MeadowMouse={}},
 modelReady=function() return modelReady end,courseReady=function() return courseReady end,
 send=function(p,a,v) table.insert(events,{p=p,a=a,v=v}) end,
 launch=function(p,id) launches+=1 return launchWorks end,
})
local function open(p) assert(api.open(p or "A")) return events[#events].v.token end
local token=open()
local function submit(value,p) time+=1 return api.submit(p or "A",value) end
local function request(t,id,planet) return {token=t,itemId=id,planet=planet or "GreenStar"} end
assert(not submit(request(token,1),"B") and launches==0,"Another player's menu")
assert(not submit(request(token,"1")) and launches==0,"String item ID")
assert(not submit(request(token,0/0)) and launches==0,"NaN ID")
assert(not submit(request(token,3)) and launches==0,"Unowned mount")
assert(not submit(request(token,1,"OtherPlanet")) and launches==0,"Unapproved planet")
near=false assert(not submit(request(token,1)) and launches==0) assert(not api.open("B")) near=true
bag.monsters[1].tradeLock=true assert(not submit(request(token,1)) and launches==0) bag.monsters[1].tradeLock=nil
bag.monsters[1].breedingTeam=1 assert(not submit(request(token,1)) and launches==0) bag.monsters[1].breedingTeam=nil
modelReady=false assert(not submit(request(token,1)) and launches==0) modelReady=true
courseReady=false assert(not submit(request(token,1)) and launches==0) courseReady=true
bag.monsters[1].id=9 assert(not submit(request(token,1)) and launches==0) bag.monsters[1].id=1
launchWorks=false assert(not submit(request(token,1)) and launches==1) launchWorks=true
assert(submit(request(token,1)) and launches==2,"Retry after failure")
assert(not submit(request(token,1)) and launches==2,"Replay after success")
token=open() api.cancel("A") assert(not submit(request(token,1)) and launches==2)
token=open() time+=61 assert(not submit(request(token,1)) and launches==2,"Expired menu")
token=open() api.remove("A") assert(not submit(request(token,1)) and launches==2)
bag.monsters={} token=open() assert(#events[#events].v.items==0 and not submit(request(token,1)))
-- Flooded malformed requests receive at most one response per rate window.
time+=1 local before=#events api.submit("A",request("bad",1)) api.submit("A",request("bad",1)) assert(#events==before+1)
print("ROCKET_DEPARTURE_PASS: ownership/proximity/locks/readiness/expiry/replay/rate limit/failed launch retry; patched code compiled")
'''
path=ROOT/'.tools/test_rocket_departure.luau';path.write_text(harness,encoding='utf-8');run(path)
for file in ['src/client/RocketDeparture.client.luau','src/server/RocketDepartureService.luau','src/authoring/ForestAtmosphere.client.luau','dist/ReviewModels/InstallUserRocket.commandbar.lua']:
 compile_file(ROOT/file)
