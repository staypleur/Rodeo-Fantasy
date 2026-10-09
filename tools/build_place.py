"""Build the self-contained Studio place using only Python's standard library."""
from pathlib import Path
import copy
import math
import xml.etree.ElementTree as ET
from meadow_models import components, SPECIES, STAGES, SCALES, BOUNDS, BODY_SCALES
from lobby_map import build_lobby

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


def frame(x, y, z, rotation=(0, 0, 0)):
    rx, ry, rz = [math.radians(value) for value in rotation]
    cx, cy, cz, sx, sy, sz = math.cos(rx), math.cos(ry), math.cos(rz), math.sin(rx), math.sin(ry), math.sin(rz)
    return dict(X=x, Y=y, Z=z,
                R00=cy*cz+sy*sx*sz, R01=-cy*sz+sy*sx*cz, R02=sy*cx,
                R10=cx*sz, R11=cx*cz, R12=-sx,
                R20=-sy*cz+cy*sx*sz, R21=sy*sz+cy*sx*cz, R22=cy*cx)


def part(parent, name, position, size, color, kind="Part", rotation=(0, 0, 0)):
    node, properties = item(parent, kind, name)
    prop(properties, "bool", "Anchored", True)
    prop(properties, "Vector3", "size", vector(*size))
    prop(properties, "CoordinateFrame", "CFrame", frame(*position, rotation))
    prop(properties, "Color3uint8", "Color3uint8", (color[0] << 16) | (color[1] << 8) | color[2])
    prop(properties, "token", "TopSurface", 0)
    prop(properties, "token", "BottomSurface", 0)
    return node, properties


def script(parent, kind, name, path):
    node, properties = item(parent, kind, name)
    prop(properties, "ProtectedString", "Source", (ROOT / path).read_text(encoding="utf-8"))
    if kind != "ModuleScript":
        prop(properties, "bool", "Disabled", False)
    return node


def monster(parent, name, position, species="MeadowMouse", stars=1):
    visual_components = components(species,stars)
    node, properties = item(parent, "Model", name)
    root, root_props = part(node, "MountRoot", position, tuple(v*SCALES[stars]*BODY_SCALES[species] for v in BOUNDS[species]), (175, 77, 36))
    prop(root_props, "float", "Transparency", 1)
    prop(root_props, "bool", "CanCollide", False)
    prop(root_props, "bool", "CanQuery", False)
    prop(root_props, "bool", "CanTouch", False)
    prop(properties, "Ref", "PrimaryPart", root.attrib["referent"])
    for component in visual_components:
        component_position = tuple(position[i] + component["position"][i] for i in range(3))
        shape = component["shape"]
        body, body_props = part(node, component["name"], component_position,
                               component["size"], component["color"],
                               "WedgePart" if shape == "Wedge" else "Part", component["rotation"])
        prop(body_props, "bool", "CanCollide", False)
        prop(body_props, "bool", "CanTouch", False)
        prop(body_props, "token", "Material", 288 if component["neon"] else 272)
        if component.get("studs"):
            for surface in ("TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface"):
                existing = body_props.find(f"token[@name='{surface}']")
                if existing is not None:
                    existing.text = "3"
                else:
                    prop(body_props, "token", surface, 3)  # Visual studs; no automatic joints.
        if shape == "Ball":
            prop(body_props, "token", "shape", 0)
        if shape == "Sphere":
            mesh, mesh_props = item(body, "SpecialMesh", "Shape")
            prop(mesh_props, "token", "MeshType", 3)  # Enum.MeshType.Sphere
            prop(mesh_props, "Vector3", "Scale", vector(1, 1, 1))
        if component.get("glow"):
            light, light_props = item(body, "PointLight", "LanternLight")
            prop(light_props, "Color3", "Color", dict(R=1, G=0.49, B=0.13))
            prop(light_props, "float", "Brightness", 0.35)
            prop(light_props, "float", "Range", 4)
    billboard, bill_props = item(root, "BillboardGui", "Nameplate")
    prop(bill_props, "bool", "Enabled", False)
    prop(bill_props, "float", "MaxDistance", 32)
    prop(bill_props, "UDim2", "Size", dict(XS=0, XO=240, YS=0, YO=65))
    prop(bill_props, "Vector3", "StudsOffset", vector(0, 3.5, 0))
    prop(bill_props, "bool", "AlwaysOnTop", True)
    label, label_props = item(billboard, "TextLabel", "Label")
    prop(label_props, "UDim2", "Size", dict(XS=1, XO=0, YS=1, YO=0))
    prop(label_props, "float", "BackgroundTransparency", 1)
    prop(label_props, "string", "Text", species)
    prop(label_props, "float", "TextSize", 18)
    prop(label_props, "Color3", "TextColor3", dict(R=1, G=1, B=1))
    prop(label_props, "float", "TextStrokeTransparency", 0.3)
    return node


workspace, workspace_props = item(document, "Workspace", "Workspace")
prop(workspace_props, "bool", "StreamingEnabled", False)
world, _ = item(workspace, "Folder", "RodeoPrototype")
item(world, "Folder", "Monsters")
floor, floor_props = part(world, "PreviewGround", (0, -1, 0), (100, 2, 256), (178, 211, 117))
prop(floor_props, "token", "Material", 272)  # SmoothPlastic
lobby = build_lobby(workspace, item, part, prop)
spawn, spawn_props = part(lobby, "LobbySpawn", (6000, 0.3, 0), (5, 0.2, 5), (178, 211, 117), "SpawnLocation")
prop(spawn_props, "bool", "Neutral", True)
prop(spawn_props, "bool", "CanCollide", False)
prop(spawn_props, "float", "Transparency", 1)
prop(spawn_props, "int", "Duration", 0)
monster(world, "PreviewMonster", (0, 2, -8))

replicated, _ = item(document, "ReplicatedStorage", "ReplicatedStorage")
package, _ = item(replicated, "Folder", "RodeoFantasy")
script(package, "ModuleScript", "ProgressRules", "src/shared/ProgressRules.luau")
script(package, "ModuleScript", "CollectionQuery", "src/shared/CollectionQuery.luau")
script(package, "ModuleScript", "MonsterCatalog", "src/shared/MonsterCatalog.luau")
script(package, "ModuleScript", "RecordRules", "src/shared/RecordRules.luau")
script(package, "ModuleScript", "Config", "src/shared/Config.luau")
script(package, "ModuleScript", "HuntRules", "src/shared/HuntRules.luau")
script(package, "ModuleScript", "HerdMotion", "src/shared/HerdMotion.luau")
script(package, "ModuleScript", "CourseGeometry", "src/shared/CourseGeometry.luau")
script(package, "ModuleScript", "HerdVisibility", "src/shared/HerdVisibility.luau")
script(package, "ModuleScript", "Localization", "src/shared/Localization.luau")
script(package, "ModuleScript", "LevelTheme", "src/shared/LevelTheme.luau")
script(package, "ModuleScript", "BagRules", "src/shared/BagRules.luau")
item(package, "RemoteEvent", "CaptureRemote")
server_storage, _ = item(document, "ServerStorage", "ServerStorage")
model_templates={}
for species in SPECIES:
    visual="VisualTemplate" if species=="MeadowMouse" else species+"VisualTemplate"
    source="RodeoMonsterTemplate" if species=="MeadowMouse" else species+"Template"
    for stars in STAGES:
        suffix="" if stars==1 else "_S"+str(stars)
        monster(package,visual+suffix,(0,0,0),species,stars)
        model_templates[(species,stars)]=monster(server_storage,source+suffix,(0,0,0),species,stars)
server_scripts, _ = item(document, "ServerScriptService", "ServerScriptService")
script(server_scripts, "Script", "CaptureServer", "src/server/CaptureServer.server.luau")
script(server_scripts, "ModuleScript", "HuntWorld", "src/server/HuntWorld.luau")
script(server_scripts, "ModuleScript", "LobbyWorld", "src/server/LobbyWorld.luau")
script(server_scripts, "ModuleScript", "LevelPlaque", "src/server/LevelPlaque.luau")
script(server_scripts, "ModuleScript", "ProgressService", "src/server/ProgressService.luau")
script(server_scripts, "ModuleScript", "RecordService", "src/server/RecordService.luau")
starter, starter_props = item(document, "StarterPlayer", "StarterPlayer")
prop(starter_props, "bool", "LoadCharacterAppearance", True)
prop(starter_props, "float", "CameraMaxZoomDistance", 40)
prop(starter_props, "float", "CameraMinZoomDistance", 8)
starter_scripts, _ = item(starter, "StarterPlayerScripts", "StarterPlayerScripts")
script(starter_scripts, "ModuleScript", "HuntIsolation", "src/client/HuntIsolation.luau")
script(starter_scripts, "ModuleScript", "CreatureMesh", "src/client/CreatureMesh.luau")
script(starter_scripts, "ModuleScript", "FacetedMouse", "src/client/FacetedMouse.luau")
script(starter_scripts, "ModuleScript", "FacetedMouseData", "src/client/FacetedMouseData.luau")
script(starter_scripts, "ModuleScript", "IncomeEffects", "src/client/IncomeEffects.luau")
script(starter_scripts, "ModuleScript", "MonsterPortrait", "src/client/MonsterPortrait.luau")
script(starter_scripts, "ModuleScript", "JournalUI", "src/client/JournalUI.luau")
script(starter_scripts, "ModuleScript", "BagUI", "src/client/BagUI.luau")
script(starter_scripts, "ModuleScript", "LocalizationController", "src/client/LocalizationController.luau")
script(starter_scripts, "LocalScript", "CaptureClient", "src/client/CaptureClient.client.luau")
script(starter_scripts, "ModuleScript", "RideAnimator", "src/client/RideAnimator.luau")
script(starter_scripts, "ModuleScript", "RiderPresentation", "src/client/RiderPresentation.luau")
script(starter_scripts, "ModuleScript", "TamingGauge", "src/client/TamingGauge.luau")
script(starter_scripts, "ModuleScript", "CrashEffect", "src/client/CrashEffect.luau")
script(starter_scripts, "ModuleScript", "DistanceMarkers", "src/client/DistanceMarkers.luau")
script(starter_scripts, "ModuleScript", "AudioPresentation", "src/client/AudioPresentation.luau")
script(starter_scripts, "ModuleScript", "SettingsUI", "src/client/SettingsUI.luau")
script(starter_scripts, "ModuleScript", "DashPresentation", "src/client/DashPresentation.luau")
script(starter_scripts, "ModuleScript", "CatchPresentation", "src/client/CatchPresentation.luau")
lighting, lighting_props = item(document, "Lighting", "Lighting")
prop(lighting_props, "float", "ClockTime", 14)
prop(lighting_props,"float","ExposureCompensation",-.15)
prop(lighting_props,"Color3","OutdoorAmbient",dict(R=.35,G=.38,B=.42))
prop(lighting_props, "float", "Brightness", 1.5)
prop(lighting_props, "Color3", "Ambient", dict(R=0.25, G=0.27, B=0.3))

ET.indent(document, space="  ")
output = ROOT / "dist" / "RodeoFantasy-Capture.rbxlx"
output.parent.mkdir(exist_ok=True)
ET.ElementTree(document).write(output, encoding="utf-8", xml_declaration=True)
print(f"Built {output.name} ({output.stat().st_size:,} bytes)")

# Approved A models: all five species, each growth stage, self-contained local references.
for (species,stars),model in model_templates.items():
    model_document=ET.Element("roblox",version="4")
    model_copy=copy.deepcopy(model)
    model_copy.find("Properties/string[@name='Name']").text=species+"_S"+str(stars)
    model_document.append(model_copy)
    ET.indent(model_document,space="  ")
    ET.ElementTree(model_document).write(output.parent/(species+"_S"+str(stars)+".rbxmx"),encoding="utf-8",xml_declaration=True)
print("Built 20 approved A evolution models")

ship_document=ET.Element("roblox",version="4")
ship=next(n for n in lobby.iter("Item") if n.findtext("Properties/string[@name='Name']")=="Airship")
ship_copy=copy.deepcopy(ship)
ship_copy.find("Properties/string[@name='Name']").text="BlueSeaElephantAirship"
ship_document.append(ship_copy)
ET.indent(ship_document,space="  ")
ET.ElementTree(ship_document).write(output.parent/"BlueSeaElephantAirship.rbxmx",encoding="utf-8",xml_declaration=True)
