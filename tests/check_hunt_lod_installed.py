"""Verify saved place routes hunting to low-poly and social spaces to detailed S1."""
from pathlib import Path
import sys
import xml.etree.ElementTree as E

root = Path(__file__).resolve().parents[1]
doc = E.parse(sys.argv[1]).getroot()
def name(node):
    return node.findtext("Properties/string[@name='Name']")
def child(node, key):
    return next(n for n in node.findall('Item') if name(n) == key)
def service(key):
    return next(n for n in doc.findall('Item') if n.get('class') == key)
def mesh(model):
    return child(model, 'Body').findtext("Properties/Content[@name='MeshId']/url")

package = child(service('ReplicatedStorage'), 'RodeoFantasy')
hunt = child(package, 'MeshyMossratHuntTemplate')
social = child(package, 'VisualTemplate')
assert mesh(hunt) == 'rbxassetid://103834814949704', mesh(hunt)
assert mesh(social) == 'rbxassetid://92191779453302', mesh(social)
assert mesh(child(service('ServerStorage'), 'RodeoMonsterTemplate')) == mesh(social)
assert len([n for n in hunt.iter('Item') if n.get('class') == 'Bone']) == 23
for file, expression in [
    ('src/server/CafeServer.server.luau', 'P:FindFirstChild(C.visual(m.monsterId,m.stars))'),
    ('src/server/LobbyCompanions.luau', 'P:FindFirstChild(Catalog.visual(item.monsterId,item.stars))'),
    ('src/client/NativeMossrat.luau', 'model:GetAttribute("VisualDeferred") and package:FindFirstChild("MeshyMossratHuntTemplate"..suffix)'),
]:
    assert expression in (root / file).read_text(encoding='utf8'), file
print('HUNT_LOD_SAVED_PASS: hunt uses new mesh/23 bones; lobby/cafe and server detailed mesh retained')
