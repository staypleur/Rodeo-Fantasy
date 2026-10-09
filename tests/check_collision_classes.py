"""Run real world collision functions against the user-confirmed size/dash matrix."""
from pathlib import Path
import subprocess,tempfile
R=Path(__file__).resolve().parents[1]
rules=(R/'src/shared/HuntRules.luau').read_text(encoding='utf-8')
world=(R/'src/server/HuntWorld.luau').read_text(encoding='utf-8')
for start,end,replacement in [('local Motion=require','\n','local Motion={}'),('local Course=require','\n','local Course={contains=function() return true end}'),('local Visibility=require','\n','local Visibility={}'),('local Catalog=require','\n','local Catalog={}')]:
 i=world.index(start);j=world.index(end,i);world=world[:i]+replacement+world[j:]
world=world.replace('return World\nend','function World.testSetup(a,o) animals=a previousPositions={} obstacles=o Rules=ActualRules end\nreturn World\nend')
code='local ActualRules=(function()\n'+rules+'\nend)()\n'+'''
local vm={} vm.__index=vm
local function V(x,y,z) return setmetatable({X=x,Y=y,Z=z},vm) end
vm.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub=function(a,b) return V(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__div=function(a,b) return V(a.X/b,a.Y/b,a.Z/b) end
function vm:Lerp(b,t) return V(self.X+(b.X-self.X)*t,self.Y+(b.Y-self.Y)*t,self.Z+(b.Z-self.Z)*t) end
local callbacks={}
local task={delay=function(seconds,fn) callbacks[#callbacks+1]={seconds,fn} end}
local workspace={GetServerTimeNow=function() return 10 end}
local game={GetService=function() return {AddItem=function() end} end}
local W=(function()
'''+world+'''
end)()
local function node(attrs)
 local n={attrs=attrs or {},Parent=true,Position=V(0,0,0),Size=V(2,2,2),CanQuery=true,CanTouch=true}
 n.PrimaryPart={Position=n.Position,Size=n.Size}
 function n:GetAttribute(k) return self.attrs[k] end
 function n:SetAttribute(k,v) self.attrs[k]=v end
 function n:GetDescendants() return {} end
 return n
end
local classes={'Small','Medium','Large'}
local from,to=V(0,0,1),V(0,0,-1)
local count=0
for _,size in ipairs(classes) do for _,target in ipairs(classes) do for _,dash in ipairs({false,true}) do
 local mount=node({SizeClass=size,Flying=false})
 for _,occupied in ipairs({false,true}) do
  local other=node({SizeClass=target,Flying=false,Occupied=occupied})
  W.testSetup({[mount]=true,[other]=true},{GetChildren=function() return {} end})
  local expected=not occupied and ((size=='Medium' and target=='Small' and dash) or (size=='Large' and target~='Large'))
  local hit=W.mountedHit(from,to,mount,nil,dash)
  assert((hit==nil)==expected,'wrong monster collision')
  assert((other:GetAttribute('KnockedAway')==true)==expected,'wrong breakup trigger')
  count+=1
 end
 for _,crate in ipairs({false,true}) do
  local rock=node({ObstacleSize=target,Scale=target=='Small' and 1 or 2,BreakableCrate=crate})
  W.testSetup({}, {GetChildren=function() return {rock} end})
  local expected=size=='Large' and target=='Small' and dash
  local hit
  if crate then hit=W.crateHit(from,to,mount,size,dash)
  else hit=W.hit(from,to,false,mount,dash) end
  assert(hit==not expected,'wrong obstacle collision')
  assert((rock:GetAttribute('Broken')==true)==expected,'wrong obstacle breakup')
  count+=1
 end
end end end
assert(#callbacks==1 and callbacks[1][1]==5,'small tree/rock must keep five-second restoration')
callbacks[1][2]()
print('COLLISION_CLASSES_PASS: '..count..' actual mounted/obstacle cases; occupied targets protected; breakup only on allowed hits; five-second restoration')
'''
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau',dir=R/'.tools',encoding='utf-8',delete=False) as f:
 f.write(code);p=Path(f.name)
try:subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
finally:p.unlink()
