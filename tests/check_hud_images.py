from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
expected={'ShopButtonImage':'114640852127407','IndexButtonImage':'110488541037597','EggButtonImage':'87551432940862','PawButtonImage':'85966265063532','MossratFaceImage':'87383094549038','RouletteButtonImage':'71863210551741','MoneyImage':'71604722538432','BondButtonImage':'104399312241349'}
h='local game,Instance,UDim2,Enum\nlocal task={spawn=function() end}\nlocal I=(function()\n'+(R/'src/client/HudIcons.luau').read_text(encoding='utf-8')+'\nend)()\n'
h+='local attrs={} local p={GetAttribute=function(_,k) return attrs[k] end,SetAttribute=function(_,k,v) attrs[k]=v end}\n'
for key,id in expected.items():
 h+=f'assert(I.imageId(p,"{key}")=="rbxassetid://{id}")\n'
h+='''attrs.MossratFaceImage="rbxassetid://0"
assert(I.imageId(p,"MossratFaceImage")==I.ImageIds.MossratFaceImage)
attrs.MossratFaceImage="rbxassetid://123"
assert(I.imageId(p,"MossratFaceImage")=="rbxassetid://123")
game={ReplicatedStorage={RodeoFantasy=p,FindFirstChild=function() return p end},GetService=function(_,k) return ({RunService={IsRunning=function() return false end},ChangeHistoryService={SetWaypoint=function() end}})[k] end}
'''
h+='''
attrs.PawButtonImage="rbxassetid://8596625063532"
assert(I.imageId(p,"PawButtonImage")=="rbxassetid://85966265063532")
local changed
function p:GetAttributeChangedSignal() return {Connect=function(_,f) changed=f end} end
local native={Visible=true,IsA=function(_,k) return k=="GuiObject" end}
local stroke={Enabled=true,IsA=function(_,k) return k=="UIStroke" end}
local button={ZIndex=1,BackgroundTransparency=0,GetChildren=function() return {native,stroke} end}
local artwork,signals
Instance={new=function() signals={} artwork={IsLoaded=false,GetPropertyChangedSignal=function(_,k) return {Connect=function(_,f) signals[k]=f end} end}; return artwork end}
UDim2={fromScale=function() return {} end}; Enum={ScaleType={Fit=1}}
I.bindArtwork(button,"PawButtonImage")
assert(native.Visible and stroke.Enabled and artwork.Visible and artwork.ImageTransparency==.99 and button.BackgroundTransparency==0)
artwork.IsLoaded=true signals.IsLoaded()
assert(not native.Visible and not stroke.Enabled and artwork.Visible and button.BackgroundTransparency==1)
artwork.IsLoaded=false signals.IsLoaded()
assert(native.Visible and stroke.Enabled and artwork.Visible and artwork.ImageTransparency==.99)
print("HUD_ARTWORK_LOAD_PASS: pending/failure fallback, loaded image, stale paw migration")
'''
h+='print("HUD_IMAGE_IDS_PASS: all eight fallbacks configured, zero placeholder ignored, custom override retained")\n'
source=(R/'src/client/BagUI.luau').read_text(encoding='utf-8')
menu=source[source.index(' function self.openCompanionMenu()'):source.index(' function self.openRanchMenu()')]
h+='''
local self={area="Lobby",items={},mode="Evolution",pen=1}
local chooser,scroll,window,title={},{},{},{}
local remote={FireServer=function(_,kind) assert(kind=="Bag") self.snapshot(self.items) end}
function self.setEvolutionMode() self.mode=nil self.pen=nil end
function self.snapshot() title.Text=self.mode=="Companion" and "Companion · Choose one" or "Bag" end
function self.opened() end
'''+menu+'''
self.openCompanionMenu()
assert(self.mode=="Companion" and self.pen==nil and window.Visible and not chooser.Visible and scroll.Visible)
assert(title.Text=="Companion · Choose one")
self.area="Hunt" window.Visible=false self.openCompanionMenu() assert(not window.Visible)
print("COMPANION_MENU_PASS: mode survives evolution reset and server snapshot; hunt blocked")
'''
(R/'.tools/test_hud_images.luau').write_text(h,encoding='utf-8')
for path in ['src/client/HudIcons.luau','src/client/HudStats.luau','src/client/BagUI.luau','dist/ApplyHudImages.commandbar.lua','dist/InstallIndex.commandbar.lua','dist/FixCurrentLobbyHunt.commandbar.lua']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),path],cwd=R,check=True,stdout=subprocess.DEVNULL)
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_hud_images.luau'],cwd=R,check=True)
