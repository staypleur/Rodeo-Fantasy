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

standalone = ET.parse(root / "dist/Lumidon.rbxmx").getroot()
model = standalone.find("Item[@class='Model']")
assert model is not None and model.find("Properties/string[@name='Name']").text == "Lumidon"
model_refs = {node.attrib["referent"] for node in model.iter("Item")}
for ref in model.iter("Ref"):
    assert ref.text in model_refs, "standalone model must not depend on the place"
assert not any(node.attrib["class"] in ("Script", "LocalScript", "ModuleScript", "MeshPart") for node in model.iter("Item"))
assert len(list(model.iter("Item"))) > 30
print("PASS: standalone model has complete local references and no scripts or uploaded meshes")

assert place.find("Item[@class='StarterPlayer']/Properties/bool[@name='LoadCharacterAppearance']").text == "true"
assert not any(node.find("Properties/string[@name='Name']").text == "StarterCharacter" for node in place.iter("Item"))
print("PASS: player appearance enabled with no replacement StarterCharacter")

lobby=next(n for n in place.iter("Item") if n.find("Properties/string[@name='Name']").text=="RodeoLobby")
plots=next(n for n in lobby if n.tag=="Item" and n.find("Properties/string[@name='Name']").text=="Plots")
assert len(plots.findall("Item"))==8
for plot in plots.findall("Item"):
    pens=next(n for n in plot.findall("Item") if n.find("Properties/string[@name='Name']").text=="Pens")
    assert len(pens.findall("Item"))==8
print("PASS: lobby contains eight private plots and 64 editable native pens")
