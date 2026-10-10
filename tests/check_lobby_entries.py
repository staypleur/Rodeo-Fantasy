from pathlib import Path
import subprocess,xml.etree.ElementTree as E,math
R=Path(__file__).resolve().parents[1]
for path in ['src/client/LobbyMenus.luau','src/client/CaptureClient.client.luau','src/server/LobbyRankings.luau','src/server/RecordService.luau','dist/FixCurrentLobbyHunt.commandbar.lua']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),path],cwd=R,check=True,stdout=subprocess.DEVNULL)
root=E.parse(R/'dist/RodeoFantasy-New.rbxlx')
name=lambda n:n.findtext("Properties/string[@name='Name']")
boards=next(n for n in root.findall('.//Item') if name(n)=='Leaderboards')
for board in boards.findall('Item'):
 cf=board.find("Properties/CoordinateFrame[@name='CFrame']")
 assert math.isclose(abs(float(cf.findtext('X'))-6000),54,abs_tol=1e-4) and math.isclose(float(cf.findtext('Z')),-16,abs_tol=1e-4)
 assert math.isclose(float(cf.findtext('Y')),2.04,abs_tol=1e-4) and board.findtext("Properties/bool[@name='CanCollide']")=='false'
 gui=next(n for n in board.findall('Item') if name(n)=='Ranking')
 assert {name(n) for n in gui.findall('Item')}=={'Heading','Entries'}
 assert gui.findtext("Properties/token[@name='Face']")=='1'
source=(R/'src/client/LobbyMenus.luau').read_text(encoding='utf-8')
h='''
local nodes={}
local Enum={Font={GothamBold=1,Gotham=2,GothamBlack=3},TextXAlignment={Left=1}}
local script={Parent={WaitForChild=function() return {} end}}
local workspace={}
local require=function() return {draw=function() return {} end,bindArtwork=function() end} end
local Vector2={new=function(...) return {...} end}
local UDim={new=function(...) return {...} end}
local UDim2={new=function(...) return {...} end,fromScale=function(...) return {...} end,fromOffset=function(...) return {...} end}
local Color3={new=function(...) return {...} end,fromRGB=function(...) return {...} end}
local ColorSequence={new=function(...) return {...} end}
local Instance={new=function(kind)
 local n={ClassName=kind,Activated={}}
 function n:FindFirstChild() return nil end
 function n.Activated:Connect(f) self.fire=f end
 table.insert(nodes,n) return n
end}
local UI=(function()
'''+source+'''
end)()
local eggs,pets=0,0
local bag={openRanchMenu=function() eggs+=1 end,openCompanionMenu=function() pets+=1 end}
local api=UI.new({FindFirstChild=function() return nil end},bag)
local function node(name) for _,n in ipairs(nodes) do if n.Name==name then return n end end error(name) end
local shop,roulette,panel=node("OpenShop"),node("OpenRoulette"),node("LobbyMenus")
local opens=0 api.onOpen=function() opens+=1 end
assert(not shop.Visible and not roulette.Visible)
api.state({phase="Idle"}) assert(shop.Visible and roulette.Visible)
shop.Activated.fire() assert(panel.Visible and opens==1)
node("Close").Activated.fire() assert(not panel.Visible)
roulette.Activated.fire() assert(panel.Visible and opens==2)
api.state({phase="Riding"}) assert(not panel.Visible and not shop.Visible and not roulette.Visible)
shop.Activated.fire() assert(opens==2)
api.state({phase="Idle"}) assert(shop.Visible)
node("OpenEgg").Activated.fire() node("OpenPaw").Activated.fire() assert(eggs==1 and pets==1)
print("LOBBY_ENTRIES_PASS: open/close, lobby visibility, hunt transition, hidden-button guard")
'''
(R/'.tools/test_lobby_entries.luau').write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_lobby_entries.luau'],cwd=R,check=True)
print('RANKING_PLACEMENT_PASS: both live boards beside central rocket')
