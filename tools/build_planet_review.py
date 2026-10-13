"""Isolated UI review using production modules; no production server or saves."""
from pathlib import Path
import xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
root=E.Element('roblox',version='4')
counter=0
def node(parent,kind,name,source=None):
 global counter
 counter+=1
 n=E.SubElement(parent,'Item',{'class':kind,'referent':f'RBXPlanet{counter}'});p=E.SubElement(n,'Properties')
 E.SubElement(p,'string',name='Name').text=name
 if source is not None:E.SubElement(p,'ProtectedString',name='Source').text=source
 return n
node(root,'Workspace','Workspace')
rs=node(root,'ReplicatedStorage','ReplicatedStorage');package=node(rs,'Folder','RodeoFantasy')
for p in (R/'src/shared').glob('*.luau'):node(package,'ModuleScript',p.stem,p.read_text(encoding='utf8'))
node(package,'RemoteEvent','CaptureRemote')
sp=node(root,'StarterPlayer','StarterPlayer');client=node(sp,'StarterPlayerScripts','StarterPlayerScripts')
for p in (R/'src/client').glob('*.luau'):
 if not p.name.endswith('.client.luau'):node(client,'ModuleScript',p.stem,p.read_text(encoding='utf8'))
node(client,'LocalScript','RocketDeparture',(R/'src/client/RocketDeparture.client.luau').read_text(encoding='utf8'))
node(client,'LocalScript','PlanetReview','''local player=game.Players.LocalPlayer
local P=game.ReplicatedStorage.RodeoFantasy
local planets=require(P.PlanetCatalog)
local gui=Instance.new("ScreenGui") gui.Name="PlanetReview" gui.ResetOnSpawn=false gui.DisplayOrder=100 gui.Parent=player:WaitForChild("PlayerGui")
local ui=require(script.Parent:WaitForChild("JournalUI")).new(gui,{FireServer=function() end})
local toggle=Instance.new("TextButton") toggle.Text="Review: Index / Planets" toggle.Size=UDim2.fromOffset(210,32) toggle.Position=UDim2.new(.5,-105,0,0) toggle.ZIndex=200 toggle.Parent=gui
local function departure() ui.close() P.CaptureRemote:FireServer("Review") end
toggle.Activated:Connect(function()
 local d=player.PlayerGui:FindFirstChild("RocketDepartureUI")
 if d and d.Enabled then d.Enabled=false ui.open() else departure() end
end)
task.wait(2) departure()
local images={} for _,id in ipairs(planets.Order) do table.insert(images,planets[id].Image) end
game.ContentProvider:PreloadAsync(images,function(id,status) print("PLANET_IMAGE",id,status.Name) end)
print("PLANET_REVIEW_READY",#planets.Order)
''')
ss=node(root,'ServerScriptService','ServerScriptService')
node(ss,'Script','ReviewServer','''local P=game.ReplicatedStorage.RodeoFantasy
local floor=Instance.new("SpawnLocation") floor.Anchored=true floor.Size=Vector3.new(100,1,100) floor.Parent=workspace
P.CaptureRemote.OnServerEvent:Connect(function(player,action)
 if action=="Review" then P.CaptureRemote:FireClient(player,"DepartureMenu",{travel={loaded=true,planetMeters={},unlocked={GreenStar=true}},monsters={}}) end
end)''')
E.indent(root);E.ElementTree(root).write(R/'dist/Planet-UI-Review.rbxlx',encoding='utf8',xml_declaration=True)
