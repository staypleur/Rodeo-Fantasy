"""Build an EDIT-mode patch that preserves the user's installed model assets."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
entries=[('client','NativeMossrat','src/client/NativeMossrat.luau'),('client','RideAnimator','src/client/RideAnimator.luau'),('client','CreatureMesh','src/client/CreatureMesh.luau'),('client','CaptureClient','src/client/CaptureClient.client.luau'),('server','InventoryStore','src/server/InventoryStore.luau'),('package','MeshyAirshipInstaller','src/authoring/MeshyAirshipInstaller.luau'),('package','MeshyMossratInstaller','src/authoring/MeshyMossratInstaller.luau')]
code=['assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")','local client=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")','local server=game:GetService("ServerScriptService")','local package=game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy")','local updates={}']
for parent,name,file in entries:
 source=(R/file).read_text(encoding='utf-8');assert ']====]' not in source
 code.append('updates[#updates+1]={node=assert('+parent+':FindFirstChild("'+name+'",true),"Missing '+name+'"),source=[====['+source+']====]}')
code.append('for _,entry in ipairs(updates) do entry.node.Source=entry.source end')
source=(R/'src/authoring/MeshyLobbyRepair.luau').read_text(encoding='utf-8')
code.extend(['local fresh=Instance.new("ModuleScript") fresh.Name="MeshyLobbyRepairOnce" fresh.Parent=package','fresh.Source=[====['+source+']====]','local ok,err=pcall(function() local repair=require(fresh) repair.apply() repair.retryTextures() end)','fresh:Destroy()','assert(ok,err)'])
(R/'dist/ApplyLobbyModelRepair.commandbar.lua').write_text(chr(10).join(code),encoding='utf-8')
print('LOBBY_REPAIR_PATCH_BUILT')
