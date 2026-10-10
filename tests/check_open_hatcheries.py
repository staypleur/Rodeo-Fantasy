"""Four owned egg slots and live-place geometry checks; no invented hatch rewards."""
from pathlib import Path
import subprocess,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
rules=(R/'src/shared/LobbyIncubatorRules.luau').read_text(encoding='utf-8')
social=(R/'src/shared/SocialRules.luau').read_text(encoding='utf-8')
world=(R/'src/server/LobbyWorld.luau').read_text(encoding='utf-8')
getpen=world[world.index('function Lobby.getPen'):world.index('function Lobby.canManage')]
h='local R=(function()\n'+rules+'\nend)()\nlocal S=(function()\n'+social+'\nend)()\n'+'''
local eggs={{id=1,assignedPen=1},{id=2,assignedPen=2},{id=3,assignedPen=3},{id=4,assignedPen=4},{id=5,assignedPen=2},{id=6,assignedPen=9},{id=7}}
local bag={eggs=eggs,balance=71,monsters={{id=99}}}
assert(R.migrate(bag)==2 and #eggs==7 and bag.eggs==eggs)
for i=1,4 do assert(eggs[i].assignedPen==i) end
assert(not eggs[5].assignedPen and not eggs[6].assignedPen)
assert(R.migrate(bag)==0 and bag.balance==71 and bag.monsters[1].id==99)
assert(not S.egg(bag,7,2,false))
assert(S.egg(bag,2,2,true) and S.egg(bag,7,2,false))
assert(not S.egg(bag,999,1,true) and not S.egg(bag,7,3,true))
for _,v in ipairs({0,5,1.5,0/0,"1"}) do assert(not S.egg(bag,7,v,false)) end
local Lobby={}
local owner,other={},{}
local owned={[owner]=1}
local plots={Plot_1={Pens={Pen_1={},Pen_2={},Pen_3={},Pen_4={}}}}
'''+getpen+'''
for i=1,4 do assert(Lobby.getPen(owner,i)==plots.Plot_1.Pens["Pen_"..i]) assert(Lobby.getPen(other,i)==nil) end
for _,v in ipairs({0,5,1.5,0/0,"1",{}}) do assert(Lobby.getPen(owner,v)==nil) end
assert(Lobby.getPen(owner,nil)==nil)
print("OPEN_HATCHERY_RULES_PASS: 4 occupied slots retained, duplicate/invalid slots returned without data loss, ownership/range checks")
'''
p=R/'.tools/test_open_hatcheries.luau';p.write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],check=True,cwd=R)
for file in ['src/authoring/OpenHatcheryStands.luau','src/server/SpaceLobbyDoors.server.luau','src/server/LobbyPresentation.server.luau','src/server/LobbyRankings.luau','src/server/CaptureServer.server.luau','src/client/BagUI.luau','dist/InstallOpenHatcheries.commandbar.lua','dist/CleanupLobby.commandbar.lua']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),file],cwd=R,check=True,stdout=subprocess.DEVNULL)
tree=E.parse(R/'dist/RodeoFantasy-New.rbxlx')
name=lambda n:n.findtext("Properties/string[@name='Name']")
child=lambda n,k:next(x for x in n.findall('Item') if name(x)==k)
ws=next(n for n in tree.getroot().findall('Item') if n.get('class')=='Workspace')
lobby=child(ws,'RodeoLobby')
removed={'UserIncubator','UserDoorFrame','UserDoorConsole','DoorLeft','DoorRight','DoorSensor','BabyCapsules','RoomRoof','Planter','Stem','LeafPlate','Amenities','ShipShell','SpaceLobbyDoors'}
assert not removed.intersection(name(n) for n in lobby.iter('Item'))
def vec(n,kind,key): return [float(n.findtext(f'Properties/{kind}[@name="{key}"]/{a}')) for a in 'XYZ']
for i in range(1,9):
 room=child(child(lobby,'Plots'),f'Plot_{i}');pens=child(room,'Pens')
 assert len(pens.findall('Item'))==4
 for j in range(1,5):
  pen=child(pens,f'Pen_{j}');child(pen,'PenGrass')
  for n in pen.findall('Item'):
   if n.get('class')=='Part': assert n.findtext("Properties/bool[@name='CanCollide']")=='false'
 walls=child(room,'SolidRoomWalls');assert len(walls.findall('Item'))==5
 # Exact room-local butt-joint extents; side inner face +/-38 meets front/rear ends.
 assert vec(child(walls,'RearWall'),'Vector3','size')==[76,32,2]
child(child(lobby,'Roof'),'FullGlassCeiling')
child(lobby,'BlackSpaceSphere')
child(lobby,'PlanetAura')
for room in child(lobby,'Plots').findall('Item'): child(room,'OwnerBoard')
floor=child(lobby,'LobbyCollisionFloor')
assert floor.findtext("Properties/float[@name='Transparency']")=='0'
assert floor.findtext("Properties/bool[@name='CanCollide']")=='true'
assert vec(floor,'Vector3','size')==[512,4,512]
for key in ['Distance','Income']:
 board=child(child(lobby,'Leaderboards'),key)
 assert vec(board,'Vector3','size')==[26,30,1.5]
 assert abs(vec(board,'CoordinateFrame','CFrame')[2]-24)<.001
 assert abs(float(board.findtext("Properties/CoordinateFrame[@name='CFrame']/R00")))<.001
 assert child(board,'RankingBack').findtext("Properties/token[@name='Face']")=='2'
 assert child(board,'Ranking').findtext("Properties/token[@name='Face']")=='5'
# Live module source must match the four updated inventory/UI modules and rankings.
for key,path in [('LobbyWorld','src/server/LobbyWorld.luau'),('BagUI','src/client/BagUI.luau'),('LobbyIncubatorRules','src/shared/LobbyIncubatorRules.luau'),('CaptureServer','src/server/CaptureServer.server.luau'),('LobbyRankings','src/server/LobbyRankings.luau'),('LobbyPresentation','src/server/LobbyPresentation.server.luau')]:
 node=next(n for n in tree.findall('.//Item') if name(n)==key)
 assert node.findtext("Properties/ProtectedString[@name='Source']").replace('\r\n','\n')==(R/path).read_text(encoding='utf-8')
print('OPEN_LOBBY_SAVED_PASS: 8x4 open stands, no door/capsule/room roof/tree; glass lobby roof and owner signs restored, opaque collision backing, upright rankings, saved source matches; live egg/reconnect and mobile checks pending')
