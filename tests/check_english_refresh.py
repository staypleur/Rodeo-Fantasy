from pathlib import Path
import subprocess,json,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
paths=subprocess.check_output(['git','diff','--name-only','20c50c1','--','src'],cwd=R,text=True).splitlines()
for path in paths:subprocess.run([str(R/'.tools/luau/luau-compile.exe'),path],cwd=R,check=True,stdout=subprocess.DEVNULL)
# Exercise the real permission functions with owner roots far from their room.
world=(R/'src/server/LobbyWorld.luau').read_text(encoding='utf8')
functions=world[world.index('function Lobby.getPen'):world.index('function Lobby.display')]
social=(R/'src/shared/SocialRules.luau').read_text(encoding='utf8')
planets=(R/'src/shared/PlanetCatalog.luau').read_text(encoding='utf8')
h='local Planets=(function()\n'+planets+'\nend)()\nlocal Rules=(function()\n'+social+'\nend)()\n'+'''
assert(#Planets.Order==4 and Planets.GreenStar.Available)
for _,id in ipairs({"Zephyrus","Phyto","Celestia"}) do assert(not Planets[id].Available and Planets[id].Image~="") end
local Lobby={}
local owner={Character={FindFirstChild=function() return {Position={X=6000,Z=-120}} end}}
local outsider={Character=owner.Character}
local owned={[owner]=1}
local plots={Plot_1={Pens={Pen_1={},Pen_2={},Pen_3={},Pen_4={}}}}
'''+functions+'''
for i=1,4 do assert(Lobby.canUsePen(owner,i));assert(not Lobby.canUsePen(outsider,i)) end
for _,i in ipairs({0,5,1.5,0/0,"1"}) do assert(not Lobby.canUsePen(owner,i)) end
owner.Character={FindFirstChild=function() return {Position={X=0,Z=0}} end}
assert(not Lobby.canUsePen(owner,1))
local bag={monsters={},eggs={{id=7},{id=8}}}
assert(Rules.egg(bag,7,4,false));assert(not Rules.egg(bag,8,4,false));assert(not Rules.egg(bag,999,4,true))
print("ENGLISH_REFRESH_RULES_PASS: four planets; unreleased hunts blocked; remote owned eggs; invalid slots and outside lobby blocked")
'''
(R/'.tools/test_english_refresh.luau').write_text(h,encoding='utf8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_english_refresh.luau'],cwd=R,check=True)
root=E.parse(R/'dist/RodeoFantasy-New.rbxlx').getroot()
name=lambda n:n.findtext("Properties/string[@name='Name']")
child=lambda n,key:next(v for v in n.findall('Item') if name(v)==key)
service=lambda key:next(v for v in root.findall('Item') if v.get('class')==key)
package=child(service('ReplicatedStorage'),'RodeoFantasy');client=child(service('StarterPlayer'),'StarterPlayerScripts')
for path in paths:
 key=Path(path).name.replace('.server.luau','').replace('.client.luau','').replace('.luau','')
 parent=service('ServerScriptService') if '/server/' in path else client if '/client/' in path else package
 assert child(parent,key).findtext("Properties/ProtectedString[@name='Source']").replace('\r\n','\n')==(R/path).read_text(encoding='utf8'),key
print('ENGLISH_REFRESH_SAVED_PASS:',len(paths),'live scripts match and compile')
