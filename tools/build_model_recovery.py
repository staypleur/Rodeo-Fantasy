"""Bundle a single edit-mode installer without embedding user configuration."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
entries=[('client','NativeMossrat','src/client/NativeMossrat.luau'),
 ('client','RideAnimator','src/client/RideAnimator.luau'),
 ('client','CreatureMesh','src/client/CreatureMesh.luau'),
 ('client','CaptureClient','src/client/CaptureClient.client.luau'),
 ('server','InventoryStore','src/server/InventoryStore.luau'),
 ('package','MeshyAirshipInstaller','src/authoring/MeshyAirshipInstaller.luau'),
 ('package','MeshyMossratInstaller','src/authoring/MeshyMossratInstaller.luau')]
code=['assert(not game:GetService("RunService"):IsRunning(),"■ 정지 후 실행하세요.")',
 'local client=game:GetService("StarterPlayer").StarterPlayerScripts',
 'local server=game:GetService("ServerScriptService")',
 'local package=game:GetService("ReplicatedStorage").RodeoFantasy', 'local updates={}']
for parent,name,file in entries:
 source=(R/file).read_text(encoding='utf-8');assert ']====]' not in source
 code.append('updates[#updates+1]={node=assert('+parent+':FindFirstChild("'+name+'",true),"Missing '+name+'"),source=[====['+source+']====]}')
code.append('for _,entry in ipairs(updates) do entry.node.Source=entry.source end')
source=(R/'src/authoring/ModelRecoveryInstaller.luau').read_text(encoding='utf-8')
code.extend(['local fresh=Instance.new("ModuleScript") fresh.Name="ModelRecoveryOnce" fresh.Parent=package',
 'fresh.Source=[====['+source+']====]',
 'local ok,err=pcall(function() require(fresh).install() end)',
 'fresh:Destroy()', 'assert(ok,err)'])
(R/'dist/ModelRecovery/ApplyModels.commandbar.lua').write_text('\n'.join(code),encoding='utf-8')
print('MODEL_RECOVERY_INSTALLER_BUILT')
