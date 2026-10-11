"""Guarded installation of the user's ninth-star rig into the open review place."""
from pathlib import Path
import json
from mossrat_rig_common import load
from build_mossrat_s3_connection import long

r = Path(__file__).resolve().parents[1]
s = (r/'src/authoring/UserMossratS6Installer.luau').read_text(encoding='utf8')
s = s.replace('S6', 'S9').replace('Scales[6]', 'Scales[9]').replace('Stars",6', 'Stars",9')
s = s.replace('4.75', '12').replace('1.71', '3.4')
s = s.replace('"MeshyBackHeight",1.50', '"MeshyBackHeight",7.44')
s = s.replace('3e9b36121a303c42f79eb77db6a444db02eb384c4d365a56c469cbb63535f7ee', '827655b15a275659105def5a41fbaa73dcd40444f669714b6a3665a90256d40d')
s = s.replace('part.Anchored=true', 'part.DoubleSided=true\n  local surface=part:FindFirstChildOfClass("SurfaceAppearance")\n  if surface then surface.ColorMap="rbxassetid://102088380784982" surface.MetalnessMap="" surface.RoughnessMap="" end\n  part.Anchored=true')
(r/'src/authoring/UserMossratS9Installer.luau').write_text(s, encoding='utf8')
g, _ = load(r/'assets/models/MossratS9UserRig/MossratS9Rigged.glb')
parents = {c:i for i,n in enumerate(g['nodes']) for c in n.get('children', [])}
h = '{'+','.join('['+json.dumps(g['nodes'][j]['name'])+']='+json.dumps(g['nodes'][parents[j]]['name'] if j in parents else '') for j in g['skins'][0]['joints'])+'}'
s = s.replace('__BONE_HIERARCHY__', h)
before = json.loads((r/'tools/baselines/mossrat_s9_before.json').read_text(encoding='utf8'))
code = 'do\nlocal package=game.ReplicatedStorage.RodeoFantasy\nlocal updates={\n'
for path, previous in before.items():
    parent = 'game.StarterPlayer.StarterPlayerScripts' if '/client/' in path else 'game.ServerScriptService'
    code += '{name='+json.dumps(Path(path).stem)+',parent='+parent+',before='+long(previous)+',after='+long((r/path).read_text(encoding='utf8'))+'},\n'
code += '}\nlocal modules={{parent=package,name="UserMossratRigDataS9",source='+long((r/'src/shared/UserMossratRigDataS9.luau').read_text(encoding='utf8'))+'}}\n'
code += 'local install=(function()\n'+s+'\nend)()\ninstall.run(updates,modules)\nend\n'
(r/'dist/ReviewModels/InstallMossratS9.commandbar.lua').write_text(code, encoding='utf8')
