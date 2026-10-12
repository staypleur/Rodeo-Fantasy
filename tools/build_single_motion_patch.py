"""Build an atomic, source-guarded patch for the saved lobby/cafe snapshot."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
doc = ET.parse(sys.argv[1])
names = ['NeutralMossratAnimator', 'QuadrupedAnimator', 'BipedAnimator', 'UserMossratRigAnimator']

def quote(s):
    eq = '='
    while ']' + eq + ']' in s:
        eq += '='
    return '[' + eq + '[' + s + ']' + eq + ']'

rows = []
for name in names:
    old = next(n for n in doc.iter('Item') if n.get('class') == 'ModuleScript'
               and n.findtext("Properties/string[@name='Name']") == name)
    before = old.findtext("Properties/ProtectedString[@name='Source']")
    after = (root / 'src/client' / (name + '.luau')).read_text(encoding='utf8')
    rows.append('{name=' + quote(name) + ',before=' + quote(before) + ',after=' + quote(after) + '}')
code = '''assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
assert(game.GameId==10770388358,"Wrong experience")
local C=game.StarterPlayer.StarterPlayerScripts
local updates={''' + ','.join(rows) + '''}
for _,u in ipairs(updates) do
 local n=C:FindFirstChild(u.name)
 assert(n and n:IsA("ModuleScript"),"Missing "..u.name)
 local source=n.Source:gsub("\\r\\n","\\n")
 assert(source==u.before or source==u.after,"Changed source: "..u.name)
 assert(loadstring(u.after),"Compile failed: "..u.name)
end
local backup=Instance.new("Folder")
backup.Name="SingleMotionBackup_"..game.HttpService:GenerateGUID(false)
backup.Parent=game.ServerStorage
game.ChangeHistoryService:SetWaypoint("Before single movement loops")
for _,u in ipairs(updates) do
 local n=C[u.name] n:Clone().Parent=backup n.Source=u.after
end
game.ChangeHistoryService:SetWaypoint("Single movement loops installed")
print("SINGLE_MOTION_INSTALLED",game.PlaceId,#updates)
'''
out = root / '.tools/SingleMotion.commandbar.lua'
out.write_text(code, encoding='utf8')
print(out, len(code))
