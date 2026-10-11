from pathlib import Path
import sys,json,subprocess
sys.path.insert(0,'tools')
from mossrat_rig_common import load
from build_mossrat_s3_connection import long
r=Path.cwd()
s=(r/'src/authoring/UserMossratS3Installer.luau').read_text(encoding='utf8').replace('S3','S6').replace('Scales[3]','Scales[6]').replace('Stars",3','Stars",6').replace('3.5','4.75').replace('1.26','1.71').replace('db41ce805303eacff7e6565e58aef96b7dc25708b332350904789e2136acbda0','3e9b36121a303c42f79eb77db6a444db02eb384c4d365a56c469cbb63535f7ee')
(r/'src/authoring/UserMossratS6Installer.luau').write_text(s,encoding='utf8')
g,b=load(r/'assets/models/MossratS6UserRig/MossratS6Rigged.glb')
parents={c:i for i,n in enumerate(g['nodes']) for c in n.get('children',[])}
h='{'+','.join('['+json.dumps(g['nodes'][j]['name'])+']='+json.dumps(g['nodes'][parents[j]]['name'] if j in parents else '') for j in g['skins'][0]['joints'])+'}'
s=s.replace('__BONE_HIERARCHY__',h)
code='do\nlocal package=game.ReplicatedStorage.RodeoFantasy\nlocal updates={\n'
for name,parent,path in [('BagUI','game.StarterPlayer.StarterPlayerScripts','src/client/BagUI.luau'),('PetPromptUI','game.StarterPlayer.StarterPlayerScripts','src/client/PetPromptUI.luau'),('NativeMossrat','game.StarterPlayer.StarterPlayerScripts','src/client/NativeMossrat.luau'),('UserMossratRigAnimator','game.StarterPlayer.StarterPlayerScripts','src/client/UserMossratRigAnimator.luau'),('LobbyCompanions','game.ServerScriptService','src/server/LobbyCompanions.luau')]:
 before=subprocess.check_output(['git','show','672dc63:'+path]).decode().replace('\r\n','\n')
 code+='{name='+json.dumps(name)+',parent='+parent+',before='+long(before)+',after='+long((r/path).read_text(encoding='utf8'))+'},\n'
code+='}\nlocal modules={{parent=package,name="UserMossratRigDataS6",source='+long((r/'src/shared/UserMossratRigDataS6.luau').read_text(encoding='utf8'))+'}}\nlocal install=(function()\n'+s+'\nend)()\ninstall.run(updates,modules)\nend\n'
(r/'dist/ReviewModels/InstallMossratS6.commandbar.lua').write_text(code,encoding='utf8')
t=(r/'tools/check_mossrat_s3_rig.py').read_text().replace('S3','S6')
(r/'tools/check_mossrat_s6_rig.py').write_text(t)
