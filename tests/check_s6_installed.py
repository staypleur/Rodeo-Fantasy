"""Verify the saved Studio review contains the rig and exact live code."""
from pathlib import Path
import sys
import xml.etree.ElementTree as E

r = Path(__file__).resolve().parents[1]
root = E.parse(sys.argv[1]).getroot()
def name(n):
    return n.findtext("Properties/string[@name='Name']")
def child(n, key):
    return next(v for v in n.findall('Item') if name(v) == key)
def service(key):
    return next(v for v in root.findall('Item') if v.get('class') == key)

package = child(service('ReplicatedStorage'), 'RodeoFantasy')
client = child(service('StarterPlayer'), 'StarterPlayerScripts')
for folder, parent, keys in [
    ('client', client, ['BagUI', 'PetPromptUI', 'NativeMossrat', 'UserMossratRigAnimator']),
    ('server', service('ServerScriptService'), ['LobbyCompanions']),
    ('shared', package, ['UserMossratRigDataS6']),
]:
    for key in keys:
        saved = child(parent, key).findtext("Properties/ProtectedString[@name='Source']")
        assert saved.replace('\r\n', '\n') == (r / f'src/{folder}/{key}.luau').read_text(encoding='utf8'), key
for parent, key in [
    (package, 'VisualTemplate_S6'),
    (package, 'MeshyMossratHuntTemplate_S6'),
    (service('ServerStorage'), 'RodeoMonsterTemplate_S6'),
]:
    model = child(parent, key)
    assert len([n for n in model.iter('Item') if n.get('class') == 'Bone']) == 34, key
    assert child(model, 'Body').get('class') == 'MeshPart', key
print('S6_SAVED_PASS: six live modules match; three templates retain 34 bones')
