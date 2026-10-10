from pathlib import Path
import subprocess,xml.etree.ElementTree as E,math
R=Path(__file__).resolve().parents[1]
root=E.parse(R/'dist/RodeoFantasy-New.rbxlx')
def name(n):return n.findtext("Properties/string[@name='Name']")
lobby=next(n for n in root.findall('.//Item') if name(n)=='RodeoLobby')
cap=next(n for n in lobby.findall('.//Item') if name(n)=='FullOpaqueCeiling')
size=cap.find("Properties/Vector3[@name='size']")
assert float(size.find('X').text)>=512 and float(size.find('Z').text)>=512
assert cap.findtext("Properties/float[@name='Transparency']")=='0'
for p in lobby.findall('.//Item'):
 if p.get('class')=='Part':
  for face in ('TopSurface','BottomSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'):assert p.findtext(f"Properties/token[@name='{face}']")=='0'
for room in [n for n in lobby.findall('.//Item') if (name(n) or '').startswith('Plot_')]:
 def point(key):
  p=next(n for n in room.findall('Item') if name(n)==key).find("Properties/CoordinateFrame[@name='CFrame']")
  return [float(p.find(k).text) for k in ('X','Z')]
 base,sensor=point('RoomBase'),point('DoorSensor')
 v=[sensor[i]-base[i] for i in range(2)];target=[6000-base[0],-base[1]]
 cosine=sum(v[i]*target[i] for i in range(2))/(math.hypot(*v)*math.hypot(*target))
 assert cosine>.999999,(name(room),cosine)
 for b in room.findall('.//Item'):
  if b.get('class')=='TextLabel' and b.findtext("Properties/string[@name='Text']")=='YOUR HATCHERY':raise AssertionError('Old owner text')
for p in ['src/server/CaptureServer.server.luau','src/server/LobbyWorld.luau','src/server/LobbyPresentation.server.luau','src/client/NativeMossrat.luau','src/client/UserMossratRigAnimator.luau','dist/FixCurrentLobbyHunt.commandbar.lua']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),p],cwd=R,check=True,stdout=subprocess.DEVNULL)
server=(R/'src/server/CaptureServer.server.luau').read_text(encoding='utf-8')
branch=server.split(' if action=="ReturnLobby" then\n',1)[1].split('\n local state=states[player]\n if not state',1)[0]
branch=branch.rsplit('\n end',1)[0]
h='''
local states,worldRoots,worlds={},{},{}
local moved,sends,respawns=0,0,0
local Lobby={Spawn="LOBBY",prepareCharacter=function() end}
local function restoreAvatar() end
local function setCharacterGroup() end
local function send() sends+=1 end
local function sendBag() end
local function warn() end
local Vector3={zero=0}
local function character(health)
 local root={Anchored=true}
 local human={Health=health,PlatformStand=true,AutoRotate=false}
 return {FindFirstChildOfClass=function() return human end,FindFirstChild=function() return root end,PivotTo=function(_,point) assert(point=="LOBBY") moved+=1 end},root
end
local player={attrs={}}
function player:GetAttribute(n) return self.attrs[n] end
function player:SetAttribute(n,v) self.attrs[n]=v end
function player:LoadCharacterAsync() respawns+=1 self.Character=character(100) end
local function returnLobby()
'''+branch+'''
end
player.Character=character(100)
states[player]={phase="Riding"} returnLobby() assert(moved==0)
states[player]={phase="GameOver",root={CFrame="STALE"}}
returnLobby() assert(moved==1 and states[player]==nil and respawns==0)
player.Character=character(0) states[player]={phase="GameOver",root={CFrame="DEAD"}}
returnLobby() assert(moved==2 and respawns==1 and states[player]==nil)
-- CharacterRemoving may have already cleared the state; still return the current avatar.
player.Character=character(100) returnLobby() assert(moved==3)
player:SetAttribute("ReturningLobby",true) returnLobby() assert(moved==3)
print("RETURN_LOBBY_FLOW_PASS: living, dead/respawn, cleared state, active and reentrant guards")
'''
(R/'.tools/test_current_return.luau').write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_current_return.luau'],cwd=R,check=True)
anim=(R/'src/client/UserMossratRigAnimator.luau').read_text(encoding='utf-8');data=(R/'src/shared/UserMossratRigData.luau').read_text(encoding='utf-8')
h='''
local clock=0
local os={clock=function() return clock end}
local mt={}
local function frame(x,y,z,rx,ry,rz) return setmetatable({x=x or 0,y=y or 0,z=z or 0,rx=rx or 0,ry=ry or 0,rz=rz or 0},mt) end
mt.__index={Lerp=function(a,b,t) return frame(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t,a.z+(b.z-a.z)*t,a.rx+(b.rx-a.rx)*t,a.ry+(b.ry-a.ry)*t,a.rz+(b.rz-a.rz)*t) end}
mt.__mul=function(a,b) return frame(a.x+b.x,a.y+b.y,a.z+b.z,a.rx+b.rx,a.ry+b.ry,a.rz+b.rz) end
local CFrame={new=function(x,y,z) if type(x)=="table" then return frame(x.x,x.y,x.z) end return frame(x,y,z) end,Angles=function(x,y,z) return frame(0,0,0,x,y,z) end}
CFrame.identity=frame()
local vmt={__mul=function(v,k) return {x=v.x*k,y=v.y*k,z=v.z*k} end}
local Vector3={new=function(x,y,z) return setmetatable({x=x,y=y,z=z},vmt) end,zero={x=0,y=0,z=0}}
local data=(function()
'''+data+'''
end)()
local require=function(v) return v end
local game={ReplicatedStorage={RodeoFantasy={WaitForChild=function() return data end}}}
local A=(function()
'''+anim+'''
end)()
local bones,list={},{}
for _,n in ipairs(data.bones) do local b={Name=n,Transform=CFrame.identity,IsA=function(_,k) return k=="Bone" end} bones[n]=b table.insert(list,b) end
local body={GetDescendants=function() return list end}
local model={FindFirstChild=function(_,n) return n=="Body" and body end,GetAttribute=function() return nil end}
A.animate(model,true) clock=.26 A.animate(model,true)
assert(math.abs(bones.LeftFrontUpper.Transform.rx)>.2,"Foreleg must move")
assert(math.abs(bones.LeftFrontUpper.Transform.rx+bones.RightFrontUpper.Transform.rx)<1e-6,"Opposite forelegs alternate")
assert(math.abs(bones.LeftFrontUpper.Transform.rx-bones.RightRearUpper.Transform.rx)<1e-6,"Diagonal pair shares beat")
assert(math.abs(bones.Head.Transform.ry-math.rad(-8.2))<1e-6,"Fixed head alignment")
clock=.5 A.animate(model,false) clock=.8 A.animate(model,false)
assert(math.abs(bones.LeftFrontUpper.Transform.rx)<.1,"Return to rest")
print("RIG_GAIT_PASS: alternating legs, diagonal pairs, fixed head and rest transition")
'''
(R/'.tools/test_current_gait.luau').write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_current_gait.luau'],cwd=R,check=True)
assert 'model:SetAttribute("Tamed_"..player.UserId,true)' in server
assert 'label(index,player.DisplayName or player.Name)' in (R/'src/server/LobbyWorld.luau').read_text(encoding='utf-8')
print('CURRENT_FIXES_PASS: smooth surfaces, inward doors, compiled sources and behavioral mocks; no Studio/device validation')
