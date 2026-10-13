"""Guarded update of the shared planet catalog and its two existing views."""
from pathlib import Path
import subprocess
R = Path(__file__).resolve().parents[1]
FILES = [('PlanetCatalog','src/shared/PlanetCatalog.luau','package','ModuleScript'),
         ('JournalUI','src/client/JournalUI.luau','client','ModuleScript'),
         ('RocketDeparture','src/client/RocketDeparture.client.luau','client','LocalScript')]
def q(s):
    e='='
    while ']'+e+']' in s: e+='='
    return '['+e+'['+s+']'+e+']'
def build():
    rows=[]
    for name,path,parent,kind in FILES:
        before=subprocess.check_output(['git','show','79eeb21:'+path],cwd=R).decode('utf8')
        after=(R/path).read_text(encoding='utf8')
        previous=subprocess.check_output(['git','show','0633d02:'+path],cwd=R).decode('utf8')
        rows.append('{node='+parent+':FindFirstChild('+q(name)+'),kind='+q(kind)+',before='+q(before)+',previous='+q(previous)+',after='+q(after)+'}')
    code='''assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
assert(game.GameId==10770388358,"Wrong experience")
local package=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local client=game.StarterPlayer.StarterPlayerScripts
local changes={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,c in ipairs(changes) do
 assert(c.node and c.node:IsA(c.kind),"Missing or unexpected script")
 assert(norm(c.node.Source)==norm(c.before) or norm(c.node.Source)==norm(c.previous) or norm(c.node.Source)==norm(c.after),"Other changes: "..c.node.Name)
 assert(loadstring(c.after),"Invalid source: "..c.node.Name)
 c.original=c.node.Source
end
game.ChangeHistoryService:SetWaypoint("Before planet artwork")
local backup=Instance.new("Folder") backup.Name="PlanetUpdateBackup_"..game.HttpService:GenerateGUID(false)
backup.Archivable=false backup.Parent=game.ServerStorage
for _,c in ipairs(changes) do c.node:Clone().Parent=backup end
local ok,err=pcall(function() for _,c in ipairs(changes) do c.node.Source=c.after end end)
if not ok then for _,c in ipairs(changes) do c.node.Source=c.original end error(err) end
game.ChangeHistoryService:SetWaypoint("Planet artwork installed")
print("PLANET_UPDATE_INSTALLED",game.PlaceId,19)
'''
    (R/'dist/PlanetUpdate.commandbar.lua').write_text(code,encoding='utf8')
if __name__=='__main__': build()
