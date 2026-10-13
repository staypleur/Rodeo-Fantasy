"""Package the exact artwork overlay without overwriting the user's place file."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def q(s):
    e='='
    while ']'+e+']' in s: e+='='
    return '['+e+'['+s+']'+e+']'
before=subprocess.check_output(['git','show','3aed47d:src/client/SocialUI.luau'],cwd=R).decode('utf8')
rows=[]
for name in ['BreedingUI','SocialUI']:
    source=(R/f'src/client/{name}.luau').read_text(encoding='utf8')
    rows.append('{name='+q(name)+',source='+q(source)+'}')
code='''-- Replace this with the uploaded IMAGE asset ID, then run in Studio Command Bar.
local IMAGE_ID = ""
assert(IMAGE_ID:match("^%d+$") and tonumber(IMAGE_ID)>0,"Set IMAGE_ID first")
assert(not game:GetService("RunService"):IsRunning(),"Stop Play first")
assert(game.GameId==10770388358,"Wrong experience")
local client=game.StarterPlayer.StarterPlayerScripts
local package=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local updates={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
local social=client:FindFirstChild("SocialUI")
assert(social and social:IsA("ModuleScript"),"Missing SocialUI")
assert(norm(social.Source)==norm('''+q(before)+''') or norm(social.Source)==norm(updates[2].source),"SocialUI has other changes: review before installing")
for _,u in ipairs(updates) do
 assert(loadstring(u.source),"Invalid source: "..u.name)
 local old=client:FindFirstChild(u.name)
 assert(not old or old:IsA("ModuleScript"),"Unexpected class: "..u.name)
end
game.ChangeHistoryService:SetWaypoint("Before breeding UI")
local backup=Instance.new("Folder") backup.Name="BreedingUIBackup_"..game.HttpService:GenerateGUID(false)
backup.Archivable=false backup.Parent=game.ServerStorage
for _,u in ipairs(updates) do
 local n=client:FindFirstChild(u.name)
 if n then n:Clone().Parent=backup else n=Instance.new("ModuleScript") n.Name=u.name n.Parent=client end
 n.Source=u.source
end
package:SetAttribute("BreedingBackgroundImage","rbxassetid://"..IMAGE_ID)
game.ChangeHistoryService:SetWaypoint("Breeding UI installed")
print("BREEDING_UI_INSTALLED",game.PlaceId)
'''
out=R/'dist/BreedingUI.commandbar.lua'
out.write_text(code,encoding='utf8')
print(out)
