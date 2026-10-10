"""Validate the clean project, runtime scripts, geometry and retained ownership rules."""
from pathlib import Path
import xml.etree.ElementTree as E
import subprocess,json,sys
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'tools'))
from place_identity import assert_unique_ids
root=E.parse(R/'dist/RodeoFantasy-New.rbxlx').getroot();assert_unique_ids(root)
def name(n):return n.findtext("Properties/string[@name='Name']")
def child(n,k):return next(c for c in n.findall('Item') if name(c)==k)
ws=next(n for n in root.findall('Item') if n.get('class')=='Workspace')
lobby=child(ws,'RodeoLobby');forest=child(ws,'GreenStar')
doors=child(lobby,'SpaceLobbyDoors')
assert doors.get('class')=='Script'
assert doors.findtext("Properties/ProtectedString[@name='Source']")== (R/'src/server/SpaceLobbyDoors.server.luau').read_text(encoding='utf-8')
assert not any(name(n)=='RodeoCafe' for n in ws.iter('Item'))
assert len(forest.findall('Item'))==2179
plots=child(lobby,'Plots');assert len(plots.findall('Item'))==8
for i in range(1,9):
 p=child(plots,f'Plot_{i}');pens=child(p,'Pens');assert len(pens.findall('Item'))==4
 for k in ('OwnerBoard','ManagePoint','DoorLeft','DoorRight','DoorSensor'):child(p,k)
 for j in range(1,5):child(child(pens,f'Pen_{j}'),'PenGrass')
for part in list(lobby.iter('Item'))+list(forest.iter('Item')):
 if part.get('class') not in ('Part','SpawnLocation'):continue
 props=part.find('Properties');assert props.findtext("token[@name='Material']")=='256'
 for face in ('TopSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'):assert props.findtext(f"token[@name='{face}']")=='3'
 assert props.findtext("token[@name='BottomSurface']")=='4'
 # Floor plates exactly meet their neighbors, no coplanar imitation studs.
 assert not (name(part) or '').lower().startswith('stud_')
for mesh in (n for n in root.iter('Item') if n.get('class')=='MeshPart'):
 assert mesh.findtext("Properties/Content[@name='MeshId']/url",'').startswith('rbxassetid://'),'Uploaded models require real asset IDs'
child(lobby,'LargerLobbyV1')
roof=child(lobby,'Roof')
ceilings=[n for n in roof.findall('Item') if name(n)=='Ceiling']
assert len(ceilings)==201
assert child(child(lobby,'Airport'),'Departure').findtext("Properties/CoordinateFrame[@name='CFrame']/Z")=='-44'
rs=next(n for n in root.findall('Item') if n.get('class')=='ReplicatedStorage')
visual=child(child(rs,'RodeoFantasy'),'VisualTemplate')
assert visual.findtext("Properties/Ref[@name='PrimaryPart']") in {n.get('referent') for n in visual.findall('Item')}
assert not any(name(n) in ('FacetedMouse','SkyWhaleRuntime','MeshyAirshipData','CafeLayout','OperatorPrompt') for n in root.iter('Item'))
for n in root.iter('Item'):
 if n.get('class') in ('Script','LocalScript','ModuleScript'):
  p=R/'.tools/new_compile.luau';p.write_text(n.findtext("Properties/ProtectedString[@name='Source']") or '',encoding='utf-8')
  subprocess.run([str(R/'.tools/luau/luau-compile.exe'),str(p.relative_to(R))],cwd=R,check=True,stdout=subprocess.DEVNULL)
  if name(n) in ('CafeServer','CafeClient'):assert n.findtext("Properties/bool[@name='Disabled']")=='true'
subprocess.run([str(R/'.tools/luau/luau-compile.exe'),'dist/InstallModels.commandbar.lua'],cwd=R,check=True,stdout=subprocess.DEVNULL)
# Run the installer's actual preflight against the generated place hierarchy.
def lua_tree(n,depth=0):
 children=[c for c in n.findall('Item') if c.get('class') not in ('Part','SpawnLocation','Terrain')]
 return '{name='+json.dumps(name(n) or '')+',children={'+(','.join(lua_tree(c,depth+1) for c in children) if depth<3 else '')+'}}'
services='{name="game",children={'+','.join(lua_tree(n) for n in root.findall('Item'))+'}}'
preflight=(R/'dist/InstallModels.commandbar.lua').read_text(encoding='utf-8').split('local hasMossrat=')[0]
mock='''
local function attach(n)
 function n:FindFirstChild(k) for _,c in ipairs(self.children) do if c.name==k then return c end end end
 for _,c in ipairs(n.children) do attach(c) end
 return n
end
game=attach('''+services+''')
function game:GetService(k) if k=="RunService" then return {IsRunning=function() return false end} end return assert(self:FindFirstChild(k),k) end
workspace=game:GetService("Workspace")
local function check()
'''+preflight+'''
end
check()
local clients=game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
for i,c in ipairs(clients.children) do if c.name=="UserMossratRigAnimator" then table.remove(clients.children,i) break end end
local ok,err=pcall(check) assert(not ok and string.find(err,"StarterPlayerScripts",1,true))
print("MODEL_INSTALL_PREFLIGHT_PASS: actual place hierarchy accepted, missing animator rejected")
'''
(R/'.tools/model_install_preflight.luau').write_text(mock,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/model_install_preflight.luau'],cwd=R,check=True)
# Numeric route and border functions: full width stays constant at all meters.
course=(R/'src/shared/CourseGeometry.luau').read_text(encoding='utf-8')
rules=(R/'src/shared/DepartureSelectionRules.luau').read_text(encoding='utf-8')
bag_rules=(R/'src/shared/BagRules.luau').read_text(encoding='utf-8')
h='local C=(function()\n'+course+'\nend)()\nlocal R=(function()\n'+rules+'\nend)()\nlocal B=(function()\n'+bag_rules+'\nend)()\n'+'''
for meters=0,1000,5 do
 local z=-meters*4.8 assert(C.width(z)==96 and C.median(z)==0)
 assert(C.contains(0,z,2) and C.contains(93,z,2) and not C.contains(95,z,2))
end
local bag={monsters={{id=1,monsterId="MeadowMouse",stars=1}}}
local ready=function() return true end local catalog={MeadowMouse={}}
assert(R.validate(bag,"GreenStar",1,catalog,ready)==bag.monsters[1])
local m,e=R.validate(bag,"GreenStar",2,catalog,ready) assert(m==nil and e=="NotOwned")
bag.monsters[1].tradeLock=true m,e=R.validate(bag,"GreenStar",1,catalog,ready) assert(m==nil and e=="MonsterBusy")
local fresh=B.new()
for i=1,3 do B.grant(fresh,"MeadowMouse",10,3,1) end
assert(#fresh.monsters==3 and fresh.monsters[1].id~=fresh.monsters[2].id)
local result=B.evolve(fresh,{1,1,2},10) assert(result==nil and #fresh.monsters==3,"Duplicate ids cannot consume inventory")
result=B.evolve(fresh,{1,2,3},10) assert(result and result.stars==2 and #fresh.monsters==1)
B.accrue(fresh,16,3,1) assert(fresh.pending==4 and B.collect(fresh)==4 and fresh.balance==4)
print("NEW_PROJECT_RULES_PASS: constant 192 width, borders, ownership, locks, bag grants/evolution/income")
'''
p=R/'.tools/test_new_project.luau';p.write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
print('NEW_PROJECT_PASS: unique XML, new lobby/2179-part forest, 8 rooms/32 sockets, Plastic/Studs, no legacy models/cafe map, all embedded scripts compile; Studio/device verification pending')
