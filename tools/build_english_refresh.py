"""Apply changed scripts and uploaded artwork without rebuilding the Studio scene."""
from pathlib import Path
import subprocess,json
ROOT=Path(__file__).resolve().parents[1]
def long(value):return '[========['+value+']========]'
paths=subprocess.check_output(['git','diff','--name-only','20c50c1','--','src'],cwd=ROOT,text=True).splitlines()
code='''do
assert(not game:GetService("RunService"):IsRunning(),"Stop Play before applying")
local package=game.ReplicatedStorage.RodeoFantasy
local changes={
'''
for path in paths:
 p=Path(path);name=p.name.replace('.server.luau','').replace('.client.luau','').replace('.luau','')
 parent='game.ServerScriptService' if '/server/' in path else 'game.StarterPlayer.StarterPlayerScripts' if '/client/' in path else 'package'
 old=subprocess.check_output(['git','show','20c50c1:'+path],cwd=ROOT).decode('utf8')
 code+='{name="'+name+'",parent='+parent+',before='+long(old)+',after='+long((ROOT/path).read_text(encoding='utf8'))+'},\n'
code+='''}
local function normalize(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 c.node=assert(c.parent:FindFirstChild(c.name),c.name.." missing")
 assert(normalize(c.node.Source)==normalize(c.before) or normalize(c.node.Source)==normalize(c.after),"Source changed: "..c.name)
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before English refresh")
local backup=Instance.new("Folder") backup.Name="EnglishRefreshBackup_"..game:GetService("HttpService"):GenerateGUID(false) backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do c.node:Clone().Parent=backup c.node.Source=c.after end
'''
assets=json.loads((ROOT/'assets/ui/english-refresh/manifest.json').read_text())
for key,name in {'ShopButtonImage':'ShopSquare','IndexButtonImage':'IndexSquare','RouletteButtonImage':'RouletteSquare','BondButtonImage':'BondIcon','GreenStarImage':'GreenStar','ZephyrusImage':'Zephyrus','PhytoImage':'Phyto','CelestiaImage':'Celestia'}.items():
 code+=f'package:SetAttribute("{key}","rbxassetid://{assets[name]["image"]}")\n'
code+='''package:SetAttribute("DefaultUILanguage","en-us")
game:GetService("ChangeHistoryService"):SetWaypoint("English refresh installed")
print("ENGLISH_REFRESH_INSTALLED",#changes)
end
'''
(ROOT/'dist/EnglishRefresh.commandbar.lua').write_text(code,encoding='utf8')
print('Installer built:',len(paths),'scripts')
