"""Execute selection resolution and rejection before any template mutation."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
source=(R/'src/authoring/MeshyMossratInstaller.luau').read_text(encoding='utf-8')
code='''
local selected={}
local workspace={}
local services={ReplicatedStorage={RodeoFantasy={MonsterCatalog={}}},ServerStorage={},Selection={Get=function() return selected end},RunService={IsRunning=function() return false end}}
local game={GetService=function(_,name) return services[name] end}
local require=function(value) return value end
local M=(function()
'''+source+'''
end)()
assert(not pcall(M.install,nil,nil),'missing input must fail before preparing or replacing templates')
local function model(name,kind,outside)
 return {Name=name,IsA=function(_,class) return class==(kind or 'Model') end,IsDescendantOf=function(_,parent) return parent==workspace and not outside end}
end
local calls=0 local h,d
M.install=function(hunt,detail) calls+=1 h,d=hunt,detail end
assert(not pcall(M.installSelected) and calls==0,'empty selection must not install')
selected={model('output_unwrapped','MeshPart')};M.installSelected();assert(calls==1 and h==selected[1] and d==selected[1],'single imported part works regardless of name')
selected={model('renamed_Detail'),model('renamed_Hunt')};M.installSelected();assert(h==selected[2] and d==selected[1],'reverse selection order retains correct roles')
local count=calls
for _,bad in ipairs({{model('one'),model('two')},{model('texture','SurfaceAppearance')},{model('elsewhere','Model',true)},{model('Hunt'),model('Hunt'),model('Detail')}}) do
 selected=bad;assert(not pcall(M.installSelected) and calls==count,'invalid input must not dispatch a mutation')
end
print('MESHY_INSTALLER_SELECTION_PASS: missing input, arbitrary names, MeshPart, role order, invalid/ambiguous selection; API stubs only')
'''
p=R/'.tools/check_meshy_installer.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
