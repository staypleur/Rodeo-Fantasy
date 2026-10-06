"""Build the self-contained Studio place using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
document = ET.Element("roblox", version="4")
counter = 0


def prop(properties, kind, name, value):
    element = ET.SubElement(properties, kind, name=name)
    if isinstance(value, dict):
        for key, component in value.items():
            ET.SubElement(element, key).text = str(component)
    else:
        element.text = str(value).lower() if isinstance(value, bool) else str(value)
    return element


def item(parent, kind, name):
    global counter
    counter += 1
    node = ET.SubElement(parent, "Item", {"class": kind, "referent": f"RBX{counter}"})
    properties = ET.SubElement(node, "Properties")
    prop(properties, "string", "Name", name)
    return node, properties


def vector(x, y, z):
    return dict(X=x, Y=y, Z=z)


def frame(x, y, z):
    return dict(X=x, Y=y, Z=z, R00=1, R01=0, R02=0, R10=0, R11=1, R12=0, R20=0, R21=0, R22=1)


def part(parent, name, position, size, color, kind="Part"):
    node, properties = item(parent, kind, name)
    prop(properties, "bool", "Anchored", True)
    prop(properties, "Vector3", "size", vector(*size))
    prop(properties, "CoordinateFrame", "CFrame", frame(*position))
    prop(properties, "Color3", "Color", dict(R=color[0] / 255, G=color[1] / 255, B=color[2] / 255))
    prop(properties, "token", "TopSurface", 0)
    prop(properties, "token", "BottomSurface", 0)
    return node, properties


def script(parent, kind, name, path):
    node, properties = item(parent, kind, name)
    prop(properties, "ProtectedString", "Source", (ROOT / path).read_text(encoding="utf-8"))
    if kind != "ModuleScript":
        prop(properties, "bool", "Disabled", False)
    return node


def monster(parent, name, position):
    node, properties = item(parent, "Model", name)
    body, body_props = part(node, "Body", position, (3, 3, 4), (165, 165, 165))
    prop(body_props, "bool", "CanCollide", False)
    prop(properties, "Ref", "PrimaryPart", body.attrib["referent"])
    billboard, bill_props = item(body, "BillboardGui", "Nameplate")
    prop(bill_props, "UDim2", "Size", dict(XS=0, XO=240, YS=0, YO=65))
    prop(bill_props, "Vector3", "StudsOffset", vector(0, 4, 0))
    prop(bill_props, "bool", "AlwaysOnTop", True)
    label, label_props = item(billboard, "TextLabel", "Label")
    prop(label_props, "UDim2", "Size", dict(XS=1, XO=0, YS=1, YO=0))
    prop(label_props, "float", "BackgroundTransparency", 1)
    prop(label_props, "string", "Text", "앰버랫\n외형 미정")
    prop(label_props, "float", "TextSize", 18)
    prop(label_props, "Color3", "TextColor3", dict(R=1, G=1, B=1))
    prop(label_props, "float", "TextStrokeTransparency", 0.3)
    return node


workspace, workspace_props = item(document, "Workspace", "Workspace")
prop(workspace_props, "bool", "StreamingEnabled", False)
world, _ = item(workspace, "Folder", "RodeoPrototype")
item(world, "Folder", "Monsters")
floor, floor_props = part(world, "PreviewGround", (0, -1, 0), (100, 2, 256), (195, 166, 119))
prop(floor_props, "token", "Material", 1296)  # Sand
spawn, spawn_props = part(world, "Spawn", (0, 0.1, 0), (5, 0.2, 5), (195, 166, 119), "SpawnLocation")
prop(spawn_props, "bool", "Neutral", True)
prop(spawn_props, "bool", "CanCollide", False)
prop(spawn_props, "float", "Transparency", 1)
prop(spawn_props, "int", "Duration", 0)
monster(world, "PreviewMonster", (0, 2, -8))

replicated, _ = item(document, "ReplicatedStorage", "ReplicatedStorage")
package, _ = item(replicated, "Folder", "RodeoFantasy")
script(package, "ModuleScript", "Config", "src/shared/Config.luau")
script(package, "ModuleScript", "CaptureRules", "src/shared/CaptureRules.luau")
item(package, "RemoteEvent", "CaptureRemote")
server_storage, _ = item(document, "ServerStorage", "ServerStorage")
monster(server_storage, "RodeoMonsterTemplate", (0, 0, 0))
server_scripts, _ = item(document, "ServerScriptService", "ServerScriptService")
script(server_scripts, "Script", "CaptureServer", "src/server/CaptureServer.server.luau")
starter, starter_props = item(document, "StarterPlayer", "StarterPlayer")
prop(starter_props, "float", "CameraMaxZoomDistance", 40)
prop(starter_props, "float", "CameraMinZoomDistance", 8)
starter_scripts, _ = item(starter, "StarterPlayerScripts", "StarterPlayerScripts")
script(starter_scripts, "LocalScript", "CaptureClient", "src/client/CaptureClient.client.luau")
lighting, lighting_props = item(document, "Lighting", "Lighting")
prop(lighting_props, "float", "ClockTime", 14)
prop(lighting_props, "float", "Brightness", 2)
prop(lighting_props, "Color3", "Ambient", dict(R=0.5, G=0.5, B=0.5))

ET.indent(document, space="  ")
output = ROOT / "dist" / "RodeoFantasy-Capture.rbxlx"
output.parent.mkdir(exist_ok=True)
ET.ElementTree(document).write(output, encoding="utf-8", xml_declaration=True)
print(f"Built {output.name} ({output.stat().st_size:,} bytes)")
