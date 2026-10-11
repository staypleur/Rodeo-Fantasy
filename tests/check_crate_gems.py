from pathlib import Path
import subprocess
r=Path.cwd()
world=(r/'src/server/HuntWorld.luau').read_text(encoding='utf8')
crate=world[world.index('function World.crateHit'):world.index('-- Preserve each active runner')]
rules=(r/'src/shared/HuntRules.luau').read_text(encoding='utf8')
bag=(r/'src/shared/BagRules.luau').read_text(encoding='utf8')
store=(r/'src/server/InventoryStore.luau').read_text(encoding='utf8')
normalize=store[store.index('local function normalize'):store.index('function S.open')]
server=(r/'src/server/CaptureServer.server.luau').read_text(encoding='utf8')
award=server[server.index('   if broken>0 then'):server.index('   if blocked then')]
test='local Rules=(function()\n'+rules+'\nend)()\nlocal BagRules=(function()\n'+bag+'\nend)()\n'+'''
local function v(x,y,z)
 return setmetatable({X=x,Y=y,Z=z},{__add=function(a,b) return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end})
end
local children={}
local obstacles={GetChildren=function() return children end}
local workspace={GetServerTimeNow=function() return 50 end}
local function box(x,z)
 local attrs={BreakableCrate=true}
 local b={Position=v(x,0,z),Size=v(4,4,4),CanQuery=true,CanTouch=true}
 function b:GetAttribute(k) return attrs[k] end
 function b:SetAttribute(k,value) attrs[k]=value end
 function b:GetDescendants() return {} end
 return b
end
local flying=false
local mount={PrimaryPart={Size=v(2,2,2)},GetAttribute=function() return flying end}
local World={}
'''+crate+'''
children={box(0,4),box(0,9),box(20,4)}
local blocked,n=World.crateHit(v(0,0,0),v(0,0,12),mount,'Medium',false)
assert(not blocked and n==2)
blocked,n=World.crateHit(v(0,0,0),v(0,0,12),mount,'Medium',false)
assert(not blocked and n==0,'Repeated collision rewarded again')
assert(not children[3]:GetAttribute('Broken'),'Off-path crate broken')
children={box(0,4)}
blocked,n=World.crateHit(v(0,0,0),v(0,0,8),mount,'Small',true)
assert(blocked and n==0 and not children[1]:GetAttribute('Broken'))
flying=true
blocked,n=World.crateHit(v(0,0,0),v(0,0,8),mount,'Large',false)
assert(not blocked and n==0)
flying=false
blocked,n=World.crateHit(v(0,0,0),v(0,0,8),mount,'Large',false)
assert(not blocked and n==1)
local Rules=BagRules
'''+normalize+'''
assert(BagRules.new().gems==0)
assert(normalize({monsters={},balance=12}).gems==0)
local restored=normalize({monsters={},balance=12,gems=17})
assert(restored.gems==17 and restored.balance==12)
local player={} local bags={[player]=restored} local sent=0
local function send(p) assert(p==player) sent+=1 end
local function reward(broken)
'''+award+'''
end
reward(1) reward(0) reward(2)
assert(restored.gems==20 and restored.balance==12 and sent==2)
print('CRATE_GEMS_PASS: swept/multiple/repeated/off-path/small/flying; new and legacy bags; retained balance')
'''
(r/'.tools/test_crate_gems.luau').write_text(test,encoding='utf8')
subprocess.run([str(r/'.tools/luau/luau.exe'),'.tools/test_crate_gems.luau'],check=True)
