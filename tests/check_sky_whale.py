"""Actual Luau motion sampling and rejected-import preflight, not Studio simulation."""
from pathlib import Path
import subprocess,tempfile
R=Path(__file__).resolve().parents[1]
wrap=lambda path:'(function()\n'+(R/path).read_text(encoding='utf-8')+'\nend)()'
code='local motion='+wrap('src/client/SkyWhaleMotion.luau')+'''
for _,fps in ipairs({20,30,60,120}) do
 for tick=0,fps*20 do
  local clock=tick/fps
  local bob,roll,left=motion.sample(clock,"LeftFin")
  local _,_,right=motion.sample(clock,"RightFin")
  local _,_,tail=motion.sample(clock,"Tail")
  local _,_,body=motion.sample(clock,nil)
  assert(math.abs(bob)<=.450001 and math.abs(roll)<=.008001)
  assert(math.abs(left)<=.055001 and math.abs(tail)<=.075001)
  assert(math.abs(left+right)<1e-10 and body==0)
 end
end
local installData='''+wrap('src/server/SkyWhaleInstallData.luau')+'''
local running=false
local old={Parent="unchanged"}
workspace={RodeoLobby={Airport={FindFirstChild=function() return old end}}}
game={GetService=function(_,name) assert(name=="RunService") return {IsRunning=function() return running end} end}
script={Parent={SkyWhaleInstallData=installData}}
require=function(value) return value end
local installer='''+wrap('src/server/SkyWhaleInstaller.luau')+'''
local function source(parts)
 return {IsA=function(_,c) return c=="Model" end,IsDescendantOf=function() return false end,
  GetDescendants=function() return parts end,Clone=function() error("Clone must not run for rejected import") end}
end
local function part(name,textured)
 return {Name=name,TextureID=textured and "rbxassetid://test" or "",
  IsA=function(_,c) return c=="MeshPart" or c=="BasePart" end,FindFirstChildWhichIsA=function() return nil end}
end
for _,case in ipairs({source({}),source({part("WhaleBody",true)}),source({part("WrongWhale",true)}),source({part("WhaleBody",false)}),source({part("WhaleBody",true),part("WhaleBody",true)})}) do
 local ok,err=pcall(installer.install,case)
 assert(not ok and not tostring(err):find("Clone must not run",1,true))
 assert(old.Parent=="unchanged")
end
running=true
assert(not pcall(installer.install,source({})))
print("SKY_WHALE_LUAU_PASS: motion bounds at 20/30/60/120fps, fin symmetry, static body, rejected incomplete/unknown/untextured/duplicate import and play-mode install; old visual preserved")
'''
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau',dir=R/'.tools',encoding='utf-8',delete=False) as f:
 f.write(code);p=Path(f.name)
try:subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
finally:p.unlink()
