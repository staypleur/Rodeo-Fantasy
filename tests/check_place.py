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
    "Config": "src/shared/Config.luau",
    "CaptureRules": "src/shared/CaptureRules.luau",
    "CaptureServer": "src/server/CaptureServer.server.luau",
    "CaptureClient": "src/client/CaptureClient.client.luau",
}
assert set(scripts) == set(expected)
for name, source in expected.items():
    assert scripts[name] == (root / source).read_text(encoding="utf-8"), name
assert place.find("Item[@class='ServerScriptService']/Item[@class='Script']") is not None
assert place.find("Item[@class='StarterPlayer']/Item[@class='StarterPlayerScripts']/Item[@class='LocalScript']") is not None
print("PASS: XML structure, unique references, script placement and all 4 embedded sources")
