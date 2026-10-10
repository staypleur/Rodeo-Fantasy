from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
expected={'ShopButtonImage':'84295507284264','IndexButtonImage':'135277525783308','EggButtonImage':'87551432940862','PawButtonImage':'8596625063532','MossratFaceImage':'98296663869747'}
h='local I=(function()\n'+(R/'src/client/HudIcons.luau').read_text(encoding='utf-8')+'\nend)()\n'
h+='local attrs={} local p={GetAttribute=function(_,k) return attrs[k] end,SetAttribute=function(_,k,v) attrs[k]=v end}\n'
for key,id in expected.items():
 h+=f'assert(I.imageId(p,"{key}")=="rbxassetid://{id}")\n'
h+='''attrs.MossratFaceImage="rbxassetid://0"
assert(I.imageId(p,"MossratFaceImage")==I.ImageIds.MossratFaceImage)
attrs.MossratFaceImage="rbxassetid://123"
assert(I.imageId(p,"MossratFaceImage")=="rbxassetid://123")
local game={ReplicatedStorage={FindFirstChild=function() return p end},GetService=function(_,k) return ({RunService={IsRunning=function() return false end},ChangeHistoryService={SetWaypoint=function() end}})[k] end}
'''
h+=(R/'dist/ApplyHudImages.commandbar.lua').read_text(encoding='utf-8')
for key,id in expected.items():h+=f'assert(attrs["{key}"]=="rbxassetid://{id}")\n'
h+='print("HUD_IMAGE_IDS_PASS: all five configured, zero placeholder ignored, custom override retained")\n'
(R/'.tools/test_hud_images.luau').write_text(h,encoding='utf-8')
for path in ['src/client/HudIcons.luau','src/client/HudStats.luau','dist/ApplyHudImages.commandbar.lua','dist/InstallIndex.commandbar.lua','dist/FixCurrentLobbyHunt.commandbar.lua']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),path],cwd=R,check=True,stdout=subprocess.DEVNULL)
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_hud_images.luau'],cwd=R,check=True)
