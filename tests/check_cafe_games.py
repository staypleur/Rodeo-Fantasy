from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
test='''
local G=require("../src/shared/GomokuRules")
local S=require("../src/client/HuntSteerSender")
for _,direction in ipairs({{1,0},{0,1},{1,1},{1,-1}}) do
 local b=G.new()
 for n=0,3 do
  assert(G.move(b,1,4+n*direction[1],8+n*direction[2]))
  assert(not G.move(b,1,15,15)) -- wrong turn
  assert(G.move(b,2,1+n,1))
 end
 assert(G.move(b,1,4+4*direction[1],8+4*direction[2]))
 assert(b.winner==1 and not G.move(b,2,15,15))
end
local b=G.new()
assert(not G.move(b,1,0,1) and not G.move(b,1,1.5,2) and not G.move(b,1,0/0,1))
assert(G.move(b,1,1,1) and not G.move(b,2,1,1))
-- Six is legal in free gomoku (fill the gap last).
b=G.new() b.cells={[1]=1,[2]=1,[3]=1,[5]=1,[6]=1} b.moves=5
assert(G.move(b,1,4,1) and b.winner==1)
local sent={}
local input=S.new(function(v) table.insert(sent,v) end)
assert(input(1,0,true)) -- no initial polling wait
assert(input(0,.008,true)) -- quick release sent immediately
assert(not input(0,.02,false))
assert(input(0,.06,false)) -- repair a server-throttled edge
assert(not input(0,.07,false))
assert(input(0,.27,false)) -- keepalive below the .5s server timeout
assert(sent[1]==1 and sent[2]==0 and sent[3]==0)
print("CAFE_RULES_INPUT_PASS: 4 directions, overline, invalid/duplicate/post-win moves, immediate release and bounded retries")
'''
path=root/'.tools/cafe_games_test.luau'
test=test.replace('local G=require("../src/shared/GomokuRules")','local G=(function()\n'+(root/'src/shared/GomokuRules.luau').read_text(encoding='utf-8')+'\nend)()')
test=test.replace('local S=require("../src/client/HuntSteerSender")','local S=(function()\n'+(root/'src/client/HuntSteerSender.luau').read_text(encoding='utf-8')+'\nend)()')
path.write_text(test,encoding='utf-8')
subprocess.run([str(root/'.tools/luau/luau.exe'),'.tools/cafe_games_test.luau'],cwd=root,check=True)
