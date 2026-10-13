from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def module(p):return '(function()\n'+(R/p).read_text(encoding='utf8')+'\nend)()'
s='local Bag='+module('src/shared/BagRules.luau')+'\nlocal Social='+module('src/shared/SocialRules.luau')+'\nlocal Ride='+module('src/shared/LobbyRideRules.luau')+'\n'
s+='''local b=Bag.new()
for i=1,30 do assert(Bag.grant(b,"GrassBoar",0,1,2)) end
assert(not Bag.grant(b,"GrassBoar",0,1,2) and #b.monsters==30 and b.serial==30)
assert(Bag.income({incomeAmount=2,stars=1})==2)
assert(Bag.income({incomeAmount=2,stars=2})==6)
assert(Bag.income({incomeAmount=2,stars=3})==18)
assert(Bag.offline(b,10)==180 and b.pending==180)
assert(not Bag.discard(b,0/0))
b.monsters[1].tradeLock=true assert(not Bag.discard(b,1)) b.monsters[1].tradeLock=nil
assert(Bag.discard(b,1) and #b.monsters==29 and not Bag.discard(b,1))
assert(Bag.grant(b,"GrassBoar",0,1,2).id==31)
local small=Bag.new() Bag.grant(small,"GrassBoar",0,1,2)
for i=1,10 do Bag.offline(small,1) end
assert(math.abs(small.pending+small.offlineRemainder-6)<.00001)
assert(math.abs(Ride.speed(3)/Ride.speed(1)-1.2)<.00001)
assert(math.abs(Ride.speed(6)/Ride.speed(1)-1.3)<.00001)
assert(math.abs(Ride.speed(9)/Ride.speed(1)-1.5)<.00001)
local other=Bag.new() Bag.grant(other,"GrassBoar",0,1,2) Bag.grant(other,"GrassBoar",0,1,2)
b.balance=10
assert(not Social.exchange(b,other,{ids={},coins=1},{ids={1},coins=0}))
print("PASS income, offline fraction, capacity, discard, trade capacity, ride tiers")
'''
s+='local Course='+module('src/shared/CourseGeometry.luau')+'\nlocal Layout='+module('src/server/GreenStarCourseLayout.luau')+'\nlocal SpawnPlan='+module('src/shared/HerdSpawnPlan.luau')+'\n'
cat=(R/'src/shared/MonsterCatalog.luau').read_text(encoding='utf8').replace('require(script.Parent.CourseGeometry)','Course')
s+='local Catalog=(function()\n'+cat+'\nend)()\nlocal tuning={MetersPerStud=1/4.8}\n'
w=(R/'src/server/HuntWorld.luau').read_text(encoding='utf8');s+=w[w.index('local planned=nil'):w.index('function World.replenish')]
s+='''prepareHerds()
local counts={}
for _,entry in ipairs(planned) do
 counts[entry.meters]=(counts[entry.meters] or 0)+1
 assert(Course.contains(entry.x,entry.z,5))
 assert(entry.meters>=Catalog[entry.id].UnlockMeters)
 for _,chunk in pairs(Layout) do for _,o in ipairs(chunk.obstacles) do
 assert(math.abs(o.x-entry.x)>=2*o.scale+5 or math.abs(o.z-entry.z)>=2*o.scale+8)
 end end
end
for m=0,1900,100 do assert(counts[m] and counts[m]>=3 and counts[m]<=5,"segment "..m.." count "..tostring(counts[m])) end
print("PASS 20 preplanned segments, obstacle clearance, species boundaries",#planned)
'''
p=R/'.tools/gameplay_revision_test.luau';p.write_text(s,encoding='utf8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/gameplay_revision_test.luau'],cwd=R,check=True)
for p in (R/'src').rglob('*.luau'):
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),str(p.relative_to(R))],cwd=R,stdout=subprocess.DEVNULL,check=True)
print('PASS all source Luau compilation')
