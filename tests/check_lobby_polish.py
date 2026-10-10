"""Owner lifecycle plus the saved live modules/geometry, independent of backups."""
from pathlib import Path
import subprocess,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
source=(R/'src/server/LobbyWorld.luau').read_text(encoding='utf-8')
lifecycle=source[source.index('local function label('):source.index('function Lobby.canDepart')]
h='''local Lobby={}
local owned,occupants,plots={},{},{}
for i=1,8 do
 local text={Text="old"}
 local gui={Text=text,IsA=function(_,kind) return kind=="SurfaceGui" end}
 local board={GetChildren=function() return {gui} end}
 local pen={FindFirstChild=function() return nil end}
 plots["Plot_"..i]={OwnerBoard=board,FindFirstChild=function(_,name) return name=="OwnerBoard" and board end,SetAttribute=function() end,Pens={GetChildren=function() return {pen} end}}
end
'''+lifecycle+'''
local function player(name,id) return {Name=name,DisplayName="WRONG DISPLAY",UserId=id,SetAttribute=function() end} end
local a=player("staypleur",10)
assert(Lobby.assign(a)==1 and plots.Plot_1.OwnerBoard:GetChildren()[1].Text.Text=="staypleur")
assert(Lobby.assign(a)==1)
for i=2,8 do assert(Lobby.assign(player("owner"..i,i))==i) end
assert(Lobby.assign(player("overflow",20))==nil)
Lobby.release(a)
assert(plots.Plot_1.OwnerBoard:GetChildren()[1].Text.Text=="")
local b=player("newowner",30)
assert(Lobby.assign(b)==1 and plots.Plot_1.OwnerBoard:GetChildren()[1].Text.Text=="newowner")
print("OWNER_LIFECYCLE_PASS: username only, 8 owners, overflow refused, empty on leave, reassigned name")
'''
p=R/'.tools/test_lobby_polish.luau';p.write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
tree=E.parse(R/'dist/RodeoFantasy-New.rbxlx');root=tree.getroot()
name=lambda n:n.findtext("Properties/string[@name='Name']")
child=lambda n,key:next(v for v in n.findall('Item') if name(v)==key)
service=lambda key:next(v for v in root.findall('Item') if v.get('class')==key)
server=service('ServerScriptService');client=child(service('StarterPlayer'),'StarterPlayerScripts')
files={'LobbyWorld':'src/server/LobbyWorld.luau','LobbyRankings':'src/server/LobbyRankings.luau','LobbyAppearance':'src/server/LobbyAppearance.luau','LobbyCompanions':'src/server/LobbyCompanions.luau','LobbyPresentation':'src/server/LobbyPresentation.server.luau','CaptureClient':'src/client/CaptureClient.client.luau','PetPromptUI':'src/client/PetPromptUI.luau','HudIcons':'src/client/HudIcons.luau','HudStats':'src/client/HudStats.luau'}
for key,path in files.items():
 node=child(client if '/client/' in path else server,key)
 assert node.findtext("Properties/ProtectedString[@name='Source']").replace('\r\n','\n')==(R/path).read_text(encoding='utf-8'),key
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),path],cwd=R,check=True,stdout=subprocess.DEVNULL)
lobby=child(service('Workspace'),'RodeoLobby')
shell=child(lobby,'BlackSpaceSphere')
assert shell.get('class')=='UnionOperation'
assert shell.findtext("Properties/bool[@name='UsePartColor']")=='true'
assert shell.findtext("Properties/bool[@name='CanCollide']")=='false'
assert sum(name(n).startswith('VioletHalo') for n in child(lobby,'PlanetAura').findall('Item'))==3
roof=child(child(lobby,'Roof'),'FullGlassCeiling')
assert abs(float(roof.findtext("Properties/float[@name='Transparency']"))-.94)<.001
assert roof.findtext("Properties/token[@name='Material']")=='272' # SmoothPlastic glass render workaround

for key in ['Distance','Income']:
 board=child(child(lobby,'Leaderboards'),key)
 assert child(board,'Ranking').findtext("Properties/token[@name='Face']")=='5'
 assert child(board,'RankingBack').findtext("Properties/token[@name='Face']")=='2'
 assert abs(float(board.findtext("Properties/CoordinateFrame[@name='CFrame']/R00")))<.001
print('LOBBY_POLISH_SAVED_PASS: hollow black shell, 3 halos, glass roof, E/W double faces, 9 live sources match')
