"""Verify packaged scripts, isolated entry points, editable map, native source integrity."""
from pathlib import Path
import xml.etree.ElementTree as E
import hashlib,json,struct
import sys
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'tools'))
from place_identity import assert_unique_ids
for suffix,cafe in [('Hatchery',False),('Cafe',True)]:
 root=E.parse(R/f'dist/RodeoFantasy-Social-{suffix}.rbxlx').getroot();assert_unique_ids(root)
 scripts={n.findtext("Properties/string[@name='Name']"):n for n in root.iter('Item') if n.get('class') in ('Script','LocalScript','ModuleScript')}
 for name in ('CaptureClient','CaptureServer','CafeClient','CafeServer'):
  assert scripts[name].findtext("Properties/bool[@name='Disabled']")==str(name.startswith('Cafe')!=cafe).lower()
 for name,folder in [('SocialRules','shared'),('SocialConfig','shared'),('SocialService','server'),('InventoryStore','server'),('SocialUI','client'),('NativeMossrat','client'),('SkyWhaleRuntime','client'),('MeshyAirshipInstaller','authoring'),('MeshyMossratInstaller','authoring')]:
  assert scripts[name].findtext("Properties/ProtectedString[@name='Source']")==(R/f'src/{folder}/{name}.luau').read_text(encoding='utf-8')
 ws=next(n for n in root.iter('Item') if n.get('class')=='Workspace')
 names=[n.findtext("Properties/string[@name='Name']") for n in ws.findall('Item')]
 assert ('RodeoCafe' in names)==cafe and ('RodeoLobby' in names)!=cafe
 if cafe:
  model=next(n for n in ws.findall('Item') if n.findtext("Properties/string[@name='Name']")=='RodeoCafe')
  parts=[n for n in model.findall('Item') if n.get('class') in ('Part','Seat')]
  assert len(parts)==len(json.loads((R/'assets/cafe/layout.json').read_text(encoding='utf-8')))
  assert sum(n.get('class')=='Seat' for n in parts)>=20
 print(suffix,'PACKAGE_PASS: isolated entry scripts; latest source; correct editable map; unique IDs')
base=R/'assets/meshes/meshy';raw=(base/'LobbyAirship_Source.glb').read_bytes();manifest=json.loads((base/'LobbyAirship_Source.json').read_text())
assert hashlib.sha256(raw).hexdigest()==manifest['sha256']
length=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+length]);assert sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives'])==10293
assert len(manifest['cables'])==4 and min(c[3] for c in manifest['cables'])>60
installer=(R/'src/authoring/MeshyMossratInstaller.luau').read_text(encoding='utf-8')
assert 'sourceForward=sourceForward or "-Z"' in installer and 'sourceForward=="+Z" and math.pi or 0' in installer
print('ASSET_DIRECTION_PASS: untouched lobby model; prepared mossrat -Z does not receive a second rotation')
