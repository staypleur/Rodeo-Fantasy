"""Execute actual launch, freeMount, world movement and visibility selection."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def module(path):return '(function()\n'+(R/path).read_text(encoding='utf-8')+'\nend)()'
code='local ActualView='+module('src/shared/HerdVisibility.luau')+'\n'
code+='local ActualMotion='+module('src/shared/HerdMotion.luau')+'\n'
code+='local ActualRules='+module('src/shared/HuntRules.luau')+'\n'
code+='local ActualCourse='+module('src/shared/CourseGeometry.luau')+'\n'
code+='local ActualConfig='+module('src/shared/Config.luau')+'\n'
visibilityTest=(R/'tests/herd_visibility.luau').read_text(encoding='utf-8')
visibilityTest=visibilityTest.replace('require("../src/shared/HerdVisibility")','ActualView').replace('require("../src/shared/Config")','ActualConfig').replace('require("../src/shared/CourseGeometry")','ActualCourse')
code+=visibilityTest+'\n'
code+='''
local vm={}
vm.__div=function(v,n) return setmetatable({X=v.X/n,Y=v.Y/n,Z=v.Z/n},vm) end
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vm) end}
local cm={} cm.__mul=function(a,b) return a end
local CFrame={new=function(x,y,z) return setmetatable({Position=Vector3.new(x,y,z)},cm) end,
Angles=function() return {} end}
local node={} node.RodeoFantasy=node
function node:WaitForChild() return node end
local game={ReplicatedStorage=node,GetService=function() return node end}
local require=function() return {} end
local world=(function()
'''
world=(R/'src/server/HuntWorld.luau').read_text(encoding='utf-8')
world=world.replace('return World\nend','''
function World.testState(a)
 animals=a obstacles={GetChildren=function() return {} end} tuning=ActualConfig.Prototype
 Rules=ActualRules Course=ActualCourse Motion=ActualMotion Visibility=ActualView
end
return World
end''')
code+=world+'\nend)()\n'
server=(R/'src/server/CaptureServer.server.luau').read_text(encoding='utf-8')
code+='local clearRope=function(state) state.rope=nil end\n'
code+=server[server.index('local function freeMount('):server.index('local function restoreAvatar(')]
code+='''
local worlds={} local now=function() return 0 end local send=function() end
'''
code+=server[server.index('local function launch('):server.index('local function lasso(')]
code+='''
local function animal(id,z,occupied)
 local attrs={SpawnSerial=id,RootHeight=2,HerdSpeed=44,Occupied=occupied,Flying=false}
 local cf=CFrame.new(0,2,z)
 local root=setmetatable({Size=Vector3.new(2,2,3)}, {
 __index=function(_,key) if key=='Position' then return cf.Position elseif key=='CFrame' then return cf end end,
 __newindex=function(_,key,value) assert(key=='CFrame') cf=value end})
 return {Parent=true,PrimaryPart=root,GetAttribute=function(_,k) return attrs[k] end,
 SetAttribute=function(_,k,v) attrs[k]=v end}
end
local viewer={} worlds[viewer]=world
local animals={} local mounted=animal(7,-30,true)
animals[mounted]=ActualMotion.new(0,7)
for i=1,6 do local m=animal(i,-30-i,false) animals[m]=ActualMotion.new(0,i) end
world.testState(animals)
local before=world.visibleSet(0,1,viewer) assert(not before[mounted])
local beforeCount=0 for _ in pairs(before) do beforeCount+=1 end
assert(beforeCount==5,'riding reserves one of the six total visible slots')
local otherViewer={} assert(not world.visibleSet(0,1,otherViewer)[mounted])
world.step(.05) assert(mounted.PrimaryPart.Position.Z==-30,'occupied mount is moved by riding, not herd')
local state={monster=mounted,root={Position=Vector3.new(0,5,0)},rope={},tamed=true}
launch(viewer,state)
assert(state.phase=='Airborne' and state.monster==nil and state.previousMonster==mounted)
assert(mounted.Parent and mounted:GetAttribute('Running') and not mounted:GetAttribute('Occupied'))
assert(state.rope==nil and not state.tamed)
local previousZ=mounted.PrimaryPart.Position.Z
for i=1,4 do
 world.step(.05)
 assert(mounted.PrimaryPart.Position.Z<previousZ,'former mount continues moving forward')
 previousZ=mounted.PrimaryPart.Position.Z
 local shown=world.visibleSet(0,1,viewer)
 for runner in pairs(before) do assert(shown[runner],'launch cannot evict a wild runner still on screen') end
 assert(shown[mounted],'former mount must remain visible after launch')
 local count=0 for _ in pairs(shown) do count+=1 end assert(count<=6)
end
assert(not world.visibleSet(0,1,otherViewer)[mounted],'visibility hold is private to the rider')
mounted.PrimaryPart.CFrame=CFrame.new(0,2,-600)
assert(not world.visibleSet(0,1,viewer)[mounted],'former mount is released after leaving view')
world.resetVisibility(viewer)
print('MOUNT_RELEASE_PASS: actual launch/freeMount, continuing herd motion, visible release, cap six, viewer isolation, offscreen unpin')
'''
path=R/'.tools/mount_release.luau';path.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
