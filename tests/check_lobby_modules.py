from pathlib import Path
import json,struct,hashlib,subprocess,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
meta=json.loads((R/'assets/models/LobbyModules/metadata.json').read_text())
for key,entry in meta.items():
 p=R/'assets/models/LobbyModules'/key;b=(p/(key+'.glb')).read_bytes()
 assert hashlib.sha256(b).hexdigest()==entry['sha256']
 chunks={};offset=12
 while offset<len(b):
  n,k=struct.unpack_from('<II',b,offset);chunks[k]=b[offset+8:offset+8+n];offset+=8+n
 g=json.loads(chunks[0x4e4f534a]);ex=json.loads((p/(key+'.gltf')).read_text())
 assert g['meshes']==ex['meshes'] and g['accessors']==ex['accessors'] and g['nodes']==ex['nodes']
 assert (p/(key+'.bin')).read_bytes()==chunks[0x004e4942]
 for i,img in enumerate(g['images']):
  view=g['bufferViews'][img['bufferView']];start=view.get('byteOffset',0)
  assert (p/ex['images'][i]['uri']).read_bytes()==chunks[0x004e4942][start:start+view['byteLength']]
for p in ['dist/InstallLobbyModules.commandbar.lua','src/client/HudIcons.luau','src/client/HudStats.luau','src/client/BagUI.luau']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),p],cwd=R,check=True,stdout=subprocess.DEVNULL)
r=E.parse(R/'dist/RodeoFantasy-New.rbxlx');name=lambda x:x.findtext("Properties/string[@name='Name']")
l=next(n for n in r.findall('.//Item') if name(n)=='RodeoLobby')
floor=next(n for n in l.findall('.//Item') if name(n)=='LobbyCollisionFloor')
assert floor.findtext("Properties/bool[@name='CanCollide']")=='true'
assert floor.findtext("Properties/float[@name='Transparency']")=='1'
assert not any(name(n) in ('PlanetLayer','PlanetRing','DepartureSign','FullOpaqueCeiling','Ceiling') for n in l.findall('.//Item'))
for n in l.findall('.//Item'):
 if name(n)=='WindowSpace':assert n.findtext("Properties/float[@name='Transparency']")=='0'
stats=(R/'src/client/HudStats.luau').read_text()
assert '(data.balance or 0)+(data.pending or 0)' in stats
print('LOBBY_MODULES_PASS: 4 original hashes, exact mesh/UV/image recovery, glass roof/solid walls/collision floor, compiled installer; Studio upload/placement unverified')
