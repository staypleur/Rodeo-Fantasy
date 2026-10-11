"""Patch only reviewed runtime scripts, portraits, and overlapping dock cores."""
from pathlib import Path
import xml.etree.ElementTree as E
import sys
root=Path(__file__).resolve().parents[1]
doc=E.parse(sys.argv[1]).getroot()
def name(n):return n.findtext("Properties/string[@name='Name']")
def child(n,key):return next(n for n in n.findall('Item') if name(n)==key)
def service(key):return next(n for n in doc.findall('Item') if n.get('class')==key)
def quote(s):
 eq='='
 while ']'+eq+']' in s:eq+='='
 return '['+eq+'['+s+']'+eq+']'
parents={'client':child(service('StarterPlayer'),'StarterPlayerScripts'),'shared':child(service('ReplicatedStorage'),'RodeoFantasy'),'server':service('ServerScriptService')}
paths=['client/BagUI','client/BipedAnimator','client/PetPromptUI','client/RocketDeparture.client','client/UserMossratRigAnimator','server/LobbyCompanions','shared/BagRules','shared/LobbyRideRules','client/MonsterPortrait','client/QuadrupedAnimator']
paths.append('client/JournalUI')
rows=[]
for path in paths:
 kind,file=path.split('/');key=file.replace('.client','');old=child(parents[kind],key)
 before=old.findtext("Properties/ProtectedString[@name='Source']").replace('\r\n','\n')
 after=(root/'src'/f'{path}.luau').read_text(encoding='utf8')
 rows.append('{node='+{'client':'C','shared':'P','server':'S'}[kind]+':FindFirstChild('+quote(key)+'),before='+quote(before)+',after='+quote(after)+'}')
code='''assert(not game.RunService:IsRunning(),"Stop Play first")
local P=game.ReplicatedStorage.RodeoFantasy local C=game.StarterPlayer.StarterPlayerScripts local S=game.ServerScriptService
local updates={'''+','.join(rows)+'''}
for _,u in ipairs(updates) do assert(u.node and (u.node.Source:gsub("\\r\\n","\\n")==u.before or u.node.Source:gsub("\\r\\n","\\n")==u.after),"Source changed") end
local backup=Instance.new("Folder") backup.Name="PetRulesBackup_"..game.HttpService:GenerateGUID(false) backup.Parent=game.ServerStorage
game.ChangeHistoryService:SetWaypoint("Before pet rules update")
for _,u in ipairs(updates) do u.node:Clone().Parent=backup u.node.Source=u.after end
local fix=(function()
'''+(root/'src/authoring/DockSurfaceFix.luau').read_text(encoding='utf8')+'''\nend)()
local airport=workspace.RodeoLobby.Airport
for _,n in ipairs(airport:GetChildren()) do if n.Name=="DockLayer" then n:Clone().Parent=backup end end
local fixed=fix.apply(airport)
'''
ids=root/'assets/ui/MossratPortraits/updated_ids.json'
if ids.exists():
 import json
 for star,image in json.loads(ids.read_text()).items():code+=f'P:SetAttribute("MossratPortraitS{star}","rbxassetid://{image}")\n'
code+='game.ChangeHistoryService:SetWaypoint("Pet rules updated")\nprint("PET_RULES_INSTALLED",#updates,"scripts",fixed,"dock cores")\n'
out=root/'dist/ReviewModels/PetRules.commandbar.lua';out.write_text(code,encoding='utf8');print(out,len(code))
