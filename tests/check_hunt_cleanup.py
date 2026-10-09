"""Execute the real world cleanup with deterministic state and engine stubs."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
source=(R/'src/server/HuntWorld.luau').read_text(encoding='utf-8')
source=source.replace('return World\nend', '''
function World.testState(c,a,p,o,t,r)
 chunks,animals,previousPositions,obstacles,tuning,crateRows=c,a,p,o,t,r
end
return World
end''')
prefix='''
local node={} node.RodeoFantasy=node
function node:WaitForChild() return node end
local game={ReplicatedStorage=node,GetService=function() return node end}
local require=function() return {} end
local world=(function()
'''
suffix='''
end)()
local function item(chunk,z,occupied)
 local o={Parent=true,PrimaryPart={Position={Z=z}},attrs={Chunk=chunk,Occupied=occupied}}
 function o:GetAttribute(k) return self.attrs[k] end
 function o:Destroy() self.Parent=nil self.destroyed=true end
 return o
end
local chunks={} local animals={} local positions={} local rows={}
local rocks={} local obstacles={GetChildren=function() return rocks end}
world.testState(chunks,animals,positions,obstacles,{GroundChunkStuds=100},rows)
world.cleanup({0}) -- no cave tables, no chunks, no animals
chunks[0]=item(0,0) chunks[10]=item(10,1000)
local near=item(0,100) local far=item(10,1000) local mounted=item(10,1000,true) local gone=item(0,0)
gone.Parent=nil
for _,o in ipairs({near,far,mounted,gone}) do animals[o]=true positions[o]=10 end
rocks[1]=item(0,0) rocks[2]=item(10,1000) rows[0]=0 rows[1000]=10
world.cleanup({0})
assert(chunks[0] and not chunks[10] and rocks[2].destroyed and not rocks[1].destroyed)
assert(rows[0]==0 and rows[1000]==nil)
assert(animals[near] and animals[mounted] and not animals[far] and not animals[gone])
assert(not positions[far] and not positions[gone] and far.destroyed and not mounted.destroyed)
world.cleanup({0}) -- repeated cleanup must remain safe
world.cleanup({}) -- leaving the run removes unoccupied world objects
assert(next(chunks)==nil and near.destroyed and animals[mounted])
local another=world.new()
another.cleanup({0}) -- independent uninitialized world, no stale cave state
print('HUNT_CLEANUP_PASS: empty/repeated/private world cleanup, distant chunks/obstacles/crate rows, animal history and mounted preservation')
'''
path=R/'.tools/hunt_cleanup.luau'
path.write_text(prefix+source+suffix,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
