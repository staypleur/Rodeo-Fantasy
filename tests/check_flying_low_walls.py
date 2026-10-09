"""Execute actual course bounds and riding collision across the low fork ridge."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
module=lambda p:'(function()\n'+(R/p).read_text(encoding='utf-8')+'\nend)()'
source=(R/'src/server/HuntWorld.luau').read_text(encoding='utf-8')
mounted=source.split('function World.mountedHit',1)[1].split('local function breakObstacle',1)[0]
hit=source.split('function World.hit',1)[1].split('function World.crateHit',1)[0]
code='local Course='+module('src/shared/CourseGeometry.luau')+'\nlocal Rules='+module('src/shared/HuntRules.luau')+r'''
local vec={}
local function V(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end
vec.__div=function(a,b) return V(a.X/b,a.Y/b,a.Z/b) end
vec.__sub=function(a,b) return V(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vec.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vec.__index={Lerp=function(a,b,t) return V(a.X+(b.X-a.X)*t,a.Y+(b.Y-a.Y)*t,a.Z+(b.Z-a.Z)*t) end}
local animals={} local previousPositions={} local World={}
local obstacles={items={},GetChildren=function(self) return self.items end}
local breakObstacle=function() error('test must not break anything') end
function World.mountedHit'''+mounted+'\nfunction World.hit'+hit+r'''
local mount={PrimaryPart={Size=V(2,2,2)},flying=false,GetAttribute=function(self,name) if name=='Flying' then return self.flying end end}
local from,to=V(0,16,-3000),V(0,16,-3008)
assert(Course.median(from.Z)>0)
assert(World.mountedHit(from,to,mount)== 'Wall','ground creatures still collide with the fork median')
mount.flying=true assert(World.mountedHit(from,to,mount)==nil,'flying creature must cross the low fork median')
assert(World.mountedHit(V(40,16,-3000),V(40,16,-3008),mount)=='Wall','outer course boundary remains enforced')
local high={Position=V(0,16,-3004),Size=V(8,40,8),GetAttribute=function(_,name) return name=='WallClass' and 'High' or nil end}
obstacles.items={high} assert(World.hit(from,to,true),'a high wall still blocks flying creatures')
local low={Position=V(0,1.5,-3004),Size=V(8,3,8),GetAttribute=function(_,name) return name=='WallClass' and 'Low' or nil end}
obstacles.items={low} assert(not World.hit(from,to,true),'low wall is flyable')
print('FLYING_LOW_WALL_PASS: mounted flight crosses low median, ground stays blocked, outer bounds enforced, high wall future fixture blocks flight')
'''
p=R/'.tools/check_flying_low_walls.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
