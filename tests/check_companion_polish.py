from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
rules=(R/'src/shared/HuntRules.luau').read_text(encoding='utf8')
records=(R/'src/shared/RecordRules.luau').read_text(encoding='utf8')
locale=(R/'src/shared/Localization.luau').read_text(encoding='utf8')
catalog=(R/'src/shared/MonsterCatalog.luau').read_text(encoding='utf8')
pet=(R/'src/server/LobbyCompanions.luau').read_text(encoding='utf8')
heartbeat=pet[pet.index(' local elapsed=0'):pet.index(' return api')]
h='local Hunt=(function()\n'+rules+'\nend)()\nlocal Records=(function()\n'+records+'\nend)()\nlocal L=(function()\n'+locale+'\nend)()\nlocal C=(function()\n'+catalog+'\nend)()\n'+'''
for _,id in ipairs({"MeadowMouse","GrassBoar","TreeWolf","Weedcrow","RockElephant"}) do
 local tame=C[id].TameSeconds
 local a,b,c=Hunt.mountTimeline(tame,tame,8,2) assert(a and not b and not c)
 a,b,c=Hunt.mountTimeline(8,tame,8,2) assert(a and b and not c)
 a,b,c=Hunt.mountTimeline(10,tame,8,2) assert(a and b and c)
end
local old={distance=100,sessions={}}
local one=Records.mergePlanets(old,"a",0,100,{GreenStar=90},100000)
assert(one.planetDistances.GreenStar==100)
local two=Records.mergePlanets(one,"a",0,500,{FuturePlanet=500},100001)
assert(two.planetDistances.GreenStar==100 and two.planetDistances.FuturePlanet==500)
local three=Records.mergePlanets(two,"b",0,120,{GreenStar=120},100002)
assert(three.planetDistances.GreenStar==120 and three.planetDistances.FuturePlanet==500)
assert(L.text("교감 E","en-us")=="Bond E" and L.text("교감 E","ko-kr")=="교감 E")
assert(L.text("행성 선택","en-us")=="Select Planet")
local p={Parent=true,SetAttribute=function() end}
local destroyed=false
local model={Destroy=function() destroyed=true end,SetAttribute=function() end}
local pets={[p]={model=model,id=1}}
local hasRoot,inLobby,owned=true,true,true
local function root() return hasRoot and {} or nil end
local context={canAct=function() return false end,inLobby=function() return inLobby end,bag=function() return {} end}
local Rules={find=function() return owned and {} or nil end,available=function() return false end}
local api={clear=function(who) pets[who]=nil model:Destroy() end}
local tick
local game={GetService=function() return {Heartbeat={Connect=function(_,fn) tick=fn end}} end}
'''+heartbeat+'''
for _=1,500 do tick(.1) end assert(pets[p] and not destroyed,"transient locks cleared pet")
hasRoot=false for _=1,50 do tick(.1) end assert(pets[p] and not destroyed,"respawn cleared pet")
hasRoot=true owned=false tick(.1) assert(not pets[p] and destroyed,"ownership loss retained pet")
print("COMPANION_POLISH_RULES_PASS: shared timers; planet isolation/legacy maxima; English/Korean; transient lock and respawn retention")
'''
out=R/'.tools/test_companion_polish.luau';out.write_text(h,encoding='utf8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_companion_polish.luau'],cwd=R,check=True)

# Validate the installed live modules, excluding ServerStorage backups.
import ast,xml.etree.ElementTree as E
build=ast.parse((R/'tools/build_companion_polish.py').read_text(encoding='utf8'))
paths=next(ast.literal_eval(n.value) for n in build.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='paths' for t in n.targets))
root=E.parse(R/'dist/RodeoFantasy-New.rbxlx').getroot()
name=lambda n:n.findtext("Properties/string[@name='Name']")
child=lambda n,key:next(v for v in n.findall('Item') if name(v)==key)
service=lambda key:next(v for v in root.findall('Item') if v.get('class')==key)
package=child(service('ReplicatedStorage'),'RodeoFantasy')
client=child(service('StarterPlayer'),'StarterPlayerScripts')
for path in paths:
 key=Path(path).name.replace('.server.luau','').replace('.client.luau','').replace('.luau','')
 parent=service('ServerScriptService') if '/server/' in path else client if '/client/' in path else package
 saved=child(parent,key).findtext("Properties/ProtectedString[@name='Source']")
 assert saved.replace('\r\n','\n')==(R/path).read_text(encoding='utf8'),key
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),path],cwd=R,check=True,stdout=subprocess.DEVNULL)
print('COMPANION_POLISH_SAVED_PASS: 16 live modules match; compile passes')
