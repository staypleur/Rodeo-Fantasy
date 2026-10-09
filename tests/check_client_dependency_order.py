"""Load the real animator while sibling modules arrive late, in separate steps."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
code=r'''
local template={WaitForChild=function() return {} end}
local package={MonsterCatalog={}}
function package:WaitForChild(name)
 if name=='VisualTemplate' then return template end
 if name=='Config' then return {Prototype={}} end
 return {}
end
local game={GetService=function() return {WaitForChild=function() return package end} end}
local siblings={} local parent={}
function parent:WaitForChild(name)
 while not siblings[name] do coroutine.yield(name) end
 return siblings[name]
end
setmetatable(parent,{__index=function(_,name) error('Sibling not ready: '..name) end})
local script={Parent=parent} local require=function(module) return module end
local loader=coroutine.create(function()
'''+(R/'src/client/RideAnimator.luau').read_text(encoding='utf-8')+r'''
end)
local ok,waiting=coroutine.resume(loader)
assert(ok and waiting=='CreatureMesh' and coroutine.status(loader)=='suspended')
siblings.CreatureMesh={}
ok,waiting=coroutine.resume(loader)
assert(ok and waiting=='CrashEffect' and coroutine.status(loader)=='suspended')
siblings.CrashEffect={}
local loaded
ok,loaded=coroutine.resume(loader)
assert(ok and type(loaded.update)=='function' and coroutine.status(loader)=='dead')
print('CLIENT_DEPENDENCY_ORDER_PASS: actual RideAnimator waits for late CreatureMesh, then late CrashEffect, then loads successfully')
'''
p=R/'.tools/client_dependency_order.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
