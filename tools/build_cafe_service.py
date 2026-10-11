"""Build cafe service and a lobby publication copy without authoring backups.

The owner-approved current Studio save supplies uploaded monster/model assets.
Never overwrite that save or dist/RodeoFantasy-New.rbxlx.
"""
from pathlib import Path
import copy
import sys
import xml.etree.ElementTree as E
from build_project import node, prop, script

R = Path(__file__).resolve().parents[1]
CHANGED = {'LobbyMenus', 'BagUI', 'JournalUI', 'PetPromptUI', 'HudIcons',
           'LobbyCompanions', 'SocialConfig', 'PlaceTravel', 'CafeWorld',
           'CafeServer', 'CafeClient', 'CaptureServer', 'CaptureClient', 'RideAnimator',
           'HuntSteerSender', 'ProgressService'}

def install_activity_modules(root):
    package = next(v for v in service(root, 'ReplicatedStorage').findall('Item') if name(v) == 'RodeoFantasy')
    server = service(root, 'ServerScriptService')
    client = service(root, 'StarterPlayer').find("Item[@class='StarterPlayerScripts']")
    for parent, keys in [(package, ('GomokuRules', 'PianoNotes')),
                         (server, ('CafeActivities', 'CafeMapLayout')),
                         (client, ('CafeActivityUI', 'HuntSteerSender'))]:
        for key in keys:
            existing = next((v for v in parent.findall('Item') if name(v) == key), None)
            if existing is None:
                existing = script(parent, 'ModuleScript', key, source_for(key).read_text(encoding='utf-8'))
                # Distinct from source-file referents before final remapping.
                existing.set('referent', 'CafeActivity_' + key)
            else:
                prop(existing, 'ProtectedString', 'Source', source_for(key).read_text(encoding='utf-8'))

def name(v):
    return v.findtext("Properties/string[@name='Name']")

def service(root, kind):
    return next(v for v in root.findall('Item') if v.get('class') == kind)

def source_for(key):
    return next((p for p in (R/'src').glob('*/*.luau')
                 if p.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau') == key), None)

def refresh(root, all_modules=False):
    for v in root.iter('Item'):
        if v.get('class') not in ('Script', 'LocalScript', 'ModuleScript'):
            continue
        key = name(v)
        p = source_for(key)
        if p and (key in CHANGED or all_modules and v.get('class') == 'ModuleScript'):
            prop(v, 'ProtectedString', 'Source', p.read_text(encoding='utf-8'))

def clean_authoring(root):
    storage = service(root, 'ServerStorage')
    for v in list(storage.findall('Item')):
        if not (name(v) or '').startswith('RodeoMonsterTemplate') and name(v) != 'CafePianoVisual':
            storage.remove(v)

def finalize(root, out):
    refs = {v.get('referent'): f'CafeService{i}' for i,v in enumerate(root.iter('Item'))}
    assert len(refs) == len(list(root.iter('Item'))), 'Duplicate source referents'
    for v in root.iter('Item'):
        v.set('referent', refs[v.get('referent')])
    for ref in root.iter('Ref'):
        ref.text = refs.get(ref.text, 'null')
    used = {p.text for p in root.findall('.//Properties/SharedString')}
    # CSG geometry stores its data through NetAssetRef, too.
    used.update(p.text for p in root.iter('NetAssetRef'))
    shared = root.find('SharedStrings')
    if shared is not None:
        for v in list(shared):
            if v.get('md5') not in used:
                shared.remove(v)
    E.ElementTree(root).write(out, encoding='utf-8', xml_declaration=True)
    print(out.name, len(list(root.iter('Item'))), 'items')

def build(current, cafe_review=None):
    original = E.parse(current).getroot()
    lobby = copy.deepcopy(original)
    clean_authoring(lobby)
    refresh(lobby)
    install_activity_modules(lobby)
    prop(service(lobby, 'Players'), 'int', 'MaxPlayers', 8)
    out = R/'dist/ReviewModels/RodeoPlaneture-Lobby.rbxlx'
    finalize(lobby, out)

    # This review contains the approved 1.15 island spacing. The old refined
    # map uses 1.4 and would put the new activity stations outside its cafes.
    cafe_path = cafe_review or R/'dist/ReviewModels/CafePiano-Source.rbxlx'
    cafe = E.parse(cafe_path).getroot()
    # Remap the independent source document before combining XML trees.
    for v in original.iter('Item'):
        v.set('referent', 'Original_' + v.get('referent'))
    for ref in original.iter('Ref'):
        if ref.text not in ('null', 'nil', None):
            ref.text = 'Original_' + ref.text
    shared = cafe.find('SharedStrings')
    if shared is None:
        shared = E.SubElement(cafe, 'SharedStrings')
    keys = {v.get('md5') for v in shared}
    for v in original.findall('SharedStrings/SharedString'):
        if v.get('md5') not in keys:
            shared.append(copy.deepcopy(v))
            keys.add(v.get('md5'))
    for kind in ('ReplicatedStorage', 'ServerStorage', 'ServerScriptService', 'StarterPlayer'):
        old = next((v for v in cafe.findall('Item') if v.get('class') == kind), None)
        if old is not None:
            cafe.remove(old)
        cafe.append(copy.deepcopy(service(original, kind)))
    clean_authoring(cafe)
    package = next(v for v in service(cafe, 'ReplicatedStorage').findall('Item') if name(v) == 'RodeoFantasy')
    for v in list(package.findall('Item')):
        if v.get('class') == 'Model' and not (name(v) or '').startswith('VisualTemplate'):
            package.remove(v)
    refresh(cafe, all_modules=True)
    install_activity_modules(cafe)
    storage = service(cafe, 'ServerStorage')
    if not any(name(v) == 'CafePianoVisual' for v in storage.findall('Item')):
        piano = copy.deepcopy(E.parse(R/'assets/maps/CafePianoVisual.rbxmx').getroot().find('Item'))
        storage.append(piano)
    server = service(cafe, 'ServerScriptService')
    for v in server.findall('Item'):
        if v.get('class') == 'Script':
            prop(v, 'bool', 'Disabled', str(name(v) != 'CafeServer').lower())
    client = service(cafe, 'StarterPlayer').find("Item[@class='StarterPlayerScripts']")
    for v in client.findall('Item'):
        if v.get('class') == 'LocalScript':
            prop(v, 'bool', 'Disabled', str(name(v) != 'CafeClient').lower())
    review = E.parse(cafe_path).getroot()
    rotation = next(v for v in review.iter('Item') if name(v) == 'CafePlanetRotation')
    rotation = copy.deepcopy(rotation)
    rotation.set('referent', 'CafeServiceRotation')
    client.append(rotation)
    prop(service(cafe, 'Players'), 'int', 'MaxPlayers', 20)
    finalize(cafe, R/'dist/ReviewModels/RodeoPlaneture-Cafe.rbxlx')

if __name__ == '__main__':
    build(Path(sys.argv[1]), Path(sys.argv[2]) if len(sys.argv)>2 else None)
