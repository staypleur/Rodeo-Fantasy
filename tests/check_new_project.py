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
assert not any(n.get('class')=='MeshPart' for n in root.iter('Item')),'Unuploaded model references must not masquerade as installed'
assert not any(name(n) in ('FacetedMouse','SkyWhaleRuntime','MeshyAirshipData','CafeLayout','OperatorPrompt') for n in root.iter('Item'))
for n in root.iter('Item'):
 if n.get('class') in ('Script','LocalScript','ModuleScript'):
  p=R/'.tools/new_compile.luau';p.write_text(n.findtext("Properties/ProtectedString[@name='Source']") or '',encoding='utf-8')
  subprocess.run([str(R/'.tools/luau/luau-compile.exe'),str(p.relative_to(R))],cwd=R,check=True,stdout=subprocess.DEVNULL)
  if name(n) in ('CafeServer','CafeClient'):assert n.findtext("Properties/bool[@name='Disabled']")=='true'
subprocess.run([str(R/'.tools/luau/luau-compile.exe'),'dist/InstallModels.commandbar.lua'],cwd=R,check=True,stdout=subprocess.DEVNULL)
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
