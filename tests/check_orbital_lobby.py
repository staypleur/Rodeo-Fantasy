"""Actual map interface, personal-room entrance and old-egg inventory regressions."""
from pathlib import Path
import xml.etree.ElementTree as E,subprocess,sys
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'tools'))
from place_identity import assert_unique_ids
root=E.parse(R/'dist/RodeoFantasy-New.rbxlx').getroot();assert_unique_ids(root)
name=lambda n:n.findtext("Properties/string[@name='Name']")
child=lambda n,k:next(c for c in n.findall('Item') if name(c)==k)
ws=next(n for n in root.findall('Item') if n.get('class')=='Workspace');lobby=child(ws,'RodeoLobby')
child(child(lobby,'Airport'),'Rocket');child(lobby,'OrbitalLobbyV2')
assert not any(n.get('class')=='MeshPart' for n in lobby.iter('Item'))
def box(n):
 p=n.find('Properties');cf=p.find("CoordinateFrame[@name='CFrame']");s=p.find("Vector3[@name='size']")
 center=[float(cf.findtext(k)) for k in 'XYZ'];size=[float(s.findtext(k)) for k in 'XYZ']
 half=[sum(abs(float(cf.findtext(f'R{i}{j}')))*size[j]/2 for j in range(3)) for i in range(3)]
 return center,half
for room in child(lobby,'Plots').findall('Item'):
 assert len(child(room,'Pens').findall('Item'))==1
 assert len(child(room,'BabyCapsules').findall('Item'))==4
 sensor,_=box(child(room,'DoorSensor'));manage,_=box(child(room,'ManagePoint'))
 # A player can cross the door opening to the management area at torso height.
 solids=[p for p in room.iter('Item') if p.get('class')=='Part' and name(p) not in ('DoorLeft','DoorRight') and p.findtext("Properties/bool[@name='CanCollide']")=='true']
 for t in [i/20 for i in range(21)]:
  point=[sensor[0]*(1-t)+manage[0]*t,9,sensor[2]*(1-t)+manage[2]*t]
  for p in solids:
   c,h=box(p)
   assert not all(abs(point[i]-c[i])<h[i]-.1 for i in range(3)),(name(room),name(p),'blocks entry')
# No exact duplicate coplanar guide lights, which would cause flicker.
guides=[]
for part in lobby.iter('Item'):
 if part.get('class')=='Part' and name(part)=='GuideLight':guides.append(tuple(box(part)[0]))
assert len(guides)==len(set(guides))
lights=[n for n in lobby.iter('Item') if n.get('class')=='PointLight'];assert len(lights)==4
assert all(n.findtext("Properties/bool[@name='Shadows']")=='false' for n in lights)
# All uploaded MeshPart/Bone/SurfaceAppearance properties stay identical to the pre-update file.
baseline=subprocess.run(['git','show','ee4ffcf:dist/RodeoFantasy-New.rbxlx'],cwd=R,capture_output=True,check=True)
before=E.fromstring(baseline.stdout)
def meshes(r):
 result=[]
 for n in r.iter('Item'):
  if n.get('class') not in ('MeshPart','Bone','SurfaceAppearance'):continue
  props=E.fromstring(E.tostring(n.find('Properties')))
  for ref in props.iter('Ref'):ref.text='PRESERVED_LOCAL_REF'
  result.append((n.get('class'),E.tostring(props)))
 return sorted(result)
assert meshes(before)==meshes(root),'Uploaded model/material properties changed'
rules=(R/'src/shared/LobbyIncubatorRules.luau').read_text(encoding='utf-8')
world=(R/'src/server/LobbyWorld.luau').read_text(encoding='utf-8')
h='local R=(function()\n'+rules+'\nend)()\n'+'''
local eggs={{id=11,assignedPen=1},{id=12,assignedPen=2},{id=13,assignedPen=3},{id=14,assignedPen=4},{id=15}}
local bag={eggs=eggs,balance=71,monsters={{id=99}}}
assert(R.migrate(bag)==3 and #bag.eggs==5 and bag.eggs==eggs)
assert(eggs[1].assignedPen==1 and eggs[2].assignedPen==nil and eggs[3].assignedPen==nil and eggs[4].assignedPen==nil)
assert(bag.balance==71 and bag.monsters[1].id==99 and R.migrate(bag)==0)
eggs[2].assignedPen=1 assert(R.migrate(bag)==1 and eggs[2].assignedPen==nil)
assert(R.migrate({})==0)
local plots={}
for i=1,8 do
 local pen={SetAttribute=function() end,FindFirstChild=function() return nil end}
 plots["Plot_"..i]={Pens={Pen_1=pen,GetChildren=function() return {pen} end},OwnerBoard={GetChildren=function() return {} end},SetAttribute=function() end}
end
local map={Airport={Departure={}},WaitForChild=function() return plots end}
workspace={WaitForChild=function() return map end}
CFrame={new=function() return {} end}
local L=(function()
'''+world+'''
end)()
local p={Name="Test",UserId=10,SetAttribute=function() end}
assert(L.getPen(p,1)==nil)
assert(L.assign(p)==1 and L.getPen(p,1)==plots.Plot_1.Pens.Pen_1)
for _,v in ipairs({0,2,3,4,-1,1.5,"1",{}}) do assert(L.getPen(p,v)==nil) end
assert(L.getPen(p,0/0)==nil)
L.release(p) assert(L.getPen(p,1)==nil)
print("ORBITAL_INVENTORY_PASS: all eggs retained, old slots returned, migration idempotent, one owned slot only")
'''
p=R/'.tools/test_orbital_inventory.luau';p.write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
subprocess.run([str(R/'.tools/luau/luau-compile.exe'),'dist/InstallOrbitalLobby.commandbar.lua'],cwd=R,check=True,stdout=subprocess.DEVNULL)
print('ORBITAL_LOBBY_PASS: 8x(1+4), entry paths, guide duplicates, four shadowless lights, uploaded geometry/bones/materials unchanged; Studio/device validation pending')
