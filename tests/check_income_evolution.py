"""Three-to-one evolution must preserve total production at every tier."""
from pathlib import Path
import subprocess, tempfile

root=Path(__file__).resolve().parents[1]
source=(root/'src/shared/BagRules.luau').read_text(encoding='utf8')
test='local R=(function()\n'+source+'\nend)()\n'+'''
for star=1,9 do
 local bag=R.new()
 for i=1,3 do R.grant(bag,"MeadowMouse",0,3,2) bag.monsters[i].stars=star end
 local before=0 for _,m in ipairs(bag.monsters) do before+=R.income(m) end
 local evolved=R.evolve(bag,{1,2,3},0)
 assert(evolved and #bag.monsters==1 and R.income(evolved)==before)
 R.accrue(bag,6,3,1)
 assert(bag.pending==before*2)
 R.accrue(bag,6,3,1) assert(bag.pending==before*2,"Duplicate income")
end
assert(R.income({stars=1})==1 and R.income({stars=3})==9)
assert(R.income({stars=6})==243 and R.income({stars=9})==6561)
print("INCOME_EVOLUTION_PASS: tiers 1-10, conserved production, no duplicate ticks")
'''
scratch=root/'.tools/test-temp';scratch.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(dir=scratch) as folder:
 path=Path(folder)/'test.luau';path.write_text(test,encoding='utf8')
 subprocess.run([str(root/'.tools/luau/luau.exe'),str(path.relative_to(root))],cwd=root,check=True)
