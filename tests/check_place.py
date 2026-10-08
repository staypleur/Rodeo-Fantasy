"""Check source embedding and references in the distributable Studio file."""
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
place = ET.parse(root / "dist/RodeoFantasy-Capture.rbxlx").getroot()
assert place.attrib["version"] == "4"
referents = [item.attrib["referent"] for item in place.iter("Item")]
assert len(referents) == len(set(referents))
for ref in place.iter("Ref"):
    assert ref.text in referents
scripts = {
    item.find("Properties/string[@name='Name']").text: item.find("Properties/ProtectedString[@name='Source']").text
    for item in place.iter("Item") if item.attrib["class"] in ("Script", "LocalScript", "ModuleScript")
}
expected = {
    "LevelTheme": "src/shared/LevelTheme.luau",
    "LevelPlaque": "src/server/LevelPlaque.luau",
    "HuntIsolation": "src/client/HuntIsolation.luau",
    "IncomeEffects": "src/client/IncomeEffects.luau",
    "ProgressRules": "src/shared/ProgressRules.luau",
    "CollectionQuery": "src/shared/CollectionQuery.luau",
    "ProgressService": "src/server/ProgressService.luau",
    "JournalUI": "src/client/JournalUI.luau",
    "CreatureMesh": "src/client/CreatureMesh.luau",
    "MonsterPortrait": "src/client/MonsterPortrait.luau",
    "RecordService": "src/server/RecordService.luau",
    "RecordRules": "src/shared/RecordRules.luau",
    "MonsterCatalog": "src/shared/MonsterCatalog.luau",
    "Localization": "src/shared/Localization.luau",
    "BagUI": "src/client/BagUI.luau",
    "LocalizationController": "src/client/LocalizationController.luau",
    "Config": "src/shared/Config.luau",
    "HuntRules": "src/shared/HuntRules.luau",
    "HerdMotion": "src/shared/HerdMotion.luau",
    "CourseGeometry": "src/shared/CourseGeometry.luau",
    "HerdVisibility": "src/shared/HerdVisibility.luau",
    "BagRules": "src/shared/BagRules.luau",
    "CaptureServer": "src/server/CaptureServer.server.luau",
    "HuntWorld": "src/server/HuntWorld.luau",
    "LobbyWorld": "src/server/LobbyWorld.luau",
    "CaptureClient": "src/client/CaptureClient.client.luau",
    "RideAnimator": "src/client/RideAnimator.luau",
    "RiderPresentation": "src/client/RiderPresentation.luau",
    "TamingGauge": "src/client/TamingGauge.luau",
    "DistanceMarkers": "src/client/DistanceMarkers.luau",
    "AudioPresentation": "src/client/AudioPresentation.luau",
    "DashPresentation": "src/client/DashPresentation.luau",
    "CatchPresentation": "src/client/CatchPresentation.luau",
    "CrashEffect": "src/client/CrashEffect.luau",
}
assert set(scripts) == set(expected)
for name, source in expected.items():
    assert scripts[name] == (root / source).read_text(encoding="utf-8"), name
assert place.find("Item[@class='ServerScriptService']/Item[@class='Script']") is not None
assert place.find("Item[@class='StarterPlayer']/Item[@class='StarterPlayerScripts']/Item[@class='LocalScript']") is not None
print(f"PASS: XML structure, unique references, script placement and all {len(expected)} embedded sources")

for species in ("MeadowMouse","GrassBoar","TreeWolf","RockElephant","Weedcrow"):
 for stage in (1,3,6,9):
  model=ET.parse(root/f"dist/{species}_S{stage}.rbxmx").getroot().find("Item[@class='Model']")
  assert model.find("Properties/string[@name='Name']").text==f"{species}_S{stage}"
  refs={n.attrib['referent'] for n in model.iter('Item')}
  assert all(n.text in refs for n in model.iter('Ref'))
  names=[n.findtext("Properties/string[@name='Name']") for n in model.findall('Item')]
  assert len(names)==len(set(names)), (species,stage,'duplicate pose names')
  assert len(names)>30
  assert not any(n.attrib['class'] in ('Script','LocalScript','ModuleScript','MeshPart') for n in model.iter('Item'))
print('PASS: all 20 approved A models have unique pose names and self-contained references')

assert place.find("Item[@class='StarterPlayer']/Properties/bool[@name='LoadCharacterAppearance']").text == "true"
assert not any(node.find("Properties/string[@name='Name']").text == "StarterCharacter" for node in place.iter("Item"))
print("PASS: player appearance enabled with no replacement StarterCharacter")

lobby=next(n for n in place.iter("Item") if n.find("Properties/string[@name='Name']").text=="RodeoLobby")
plots=next(n for n in lobby if n.tag=="Item" and n.find("Properties/string[@name='Name']").text=="Plots")
assert len(plots.findall("Item"))==8
for plot in plots.findall("Item"):
    pens=next(n for n in plot.findall("Item") if n.find("Properties/string[@name='Name']").text=="Pens")
    assert len(pens.findall("Item"))==4
print("PASS: lobby contains eight private plots and 32 editable native pens")

# SAT tests all pairs of rotated plot pads: separated interiors prevent z-fighting.
import math
pads=[]
for plot in plots.findall("Item"):
    pad=next(n for n in plot.findall("Item") if n.findtext("Properties/string[@name='Name']")=="GardenPad")
    cf=pad.find("Properties/CoordinateFrame[@name='CFrame']")
    size=pad.find("Properties/Vector3[@name='size']")
    x,z=float(cf.findtext('X')),float(cf.findtext('Z'))
    sx,sz=float(size.findtext('X'))/2,float(size.findtext('Z'))/2
    pads.append([(x+dx*float(cf.findtext('R00'))+dz*float(cf.findtext('R02')),z+dx*float(cf.findtext('R20'))+dz*float(cf.findtext('R22'))) for dx,dz in [(-sx,-sz),(sx,-sz),(sx,sz),(-sx,sz)]])
def overlaps(a,b):
    for poly in (a,b):
        for i,p in enumerate(poly):
            q=poly[(i+1)%4]; axis=(p[1]-q[1],q[0]-p[0])
            va=[x*axis[0]+z*axis[1] for x,z in a]; vb=[x*axis[0]+z*axis[1] for x,z in b]
            if max(va)<=min(vb) or max(vb)<=min(va): return False
    return True
for i in range(8):
    for j in range(i+1,8): assert not overlaps(pads[i],pads[j]), f"overlapping plots {i+1}/{j+1}"
assert not any(n.findtext("Properties/string[@name='Name']") in ('Welcome','DepartureSign') for n in lobby.iter('Item'))
print("PASS: all 28 plot pairs separated; removed welcome/hunt signs")

all_nodes=list(lobby.iter("Item"))
def named(name): return [n for n in all_nodes if n.findtext("Properties/string[@name='Name']")==name]
assert not named("FountainPool") and not named("FountainColumn") and not named("BoardingPlatform") and not named("BoardingStep")
assert len(named("BoardingLadder"))==1 and named("BoardingLadder")[0].get("class")=="TrussPart"
assert named("BoardingLadder")[0].findtext("Properties/float[@name='Transparency']")=="1"
assert len(named("LadderRail"))==2 and len(named("LadderRung"))==14
spawn=named("LobbySpawn")[0].find("Properties/CoordinateFrame[@name='CFrame']")
assert float(spawn.findtext("X"))==6000 and float(spawn.findtext("Z"))==0
assert len(named("BasketFloor"))==1 and not named("Cabin")
assert named("WalrusBody")[0].findtext("Properties/token[@name='shape']")=="0"
assert len(named("SkyGarden_1"))==1 and len(named("SkyGarden_8"))==1
assert len(named("SkyCanopy"))==24 and len(named("IslandWaterfall"))==48
assert all(n.findtext("Properties/float[@name='Transparency']")=="1" for n in named("GardenWall"))
def footprint(node):
 p=node.find("Properties");cf=p.find("CoordinateFrame[@name='CFrame']");size=p.find("Vector3[@name='size']")
 x,z=float(cf.findtext('X')),float(cf.findtext('Z'));sx,sz=float(size.findtext('X'))/2,float(size.findtext('Z'))/2
 return [(x+dx*float(cf.findtext('R00'))+dz*float(cf.findtext('R02')),z+dx*float(cf.findtext('R20'))+dz*float(cf.findtext('R22'))) for dx,dz in [(-sx,-sz),(sx,-sz),(sx,sz),(-sx,sz)]]
paths=[footprint(n) for n in named("GardenPath")]
furnishings=[n for n in all_nodes if n.findtext("Properties/string[@name='Name']",'').startswith('GardenCorner_') or n.findtext("Properties/string[@name='Name']") in ('Shops','Leaderboards')]
checked=0
for model in furnishings:
 for node in model.iter('Item'):
  if node.get('class')!='Part': continue
  poly=footprint(node)
  for path in paths: assert not overlaps(poly,path), node.findtext("Properties/string[@name='Name']")+" blocks a ranch path"
  checked+=1
print(f"PASS: center spawn, one ladder, smooth final airship/open basket, floating isles and waterfalls, invisible safety bounds, {checked} furnishings clear all eight paths")

assert not named("BrickStud"), "reference architecture uses masonry rather than plastic studs"
assert len(named("RanchTower"))==32 and len(named("TowerRoofCourse"))==256
assert len(named("EntryArchVoussoir"))==72
assert named("PlanetureFloorLogo") and len(named("GardenWater"))>20
assert named("PlazaBrick")
print("PASS: eight masonry courtyard ranches, four pens each, teal layered roofs, radial water garden and floor logo")
