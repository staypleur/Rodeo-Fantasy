"""Studio edit-mode path sweep against the actual HuntWorld chunk/collision code."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
data=json.loads((R/'dist/CourseReview/GreenStar-2000m-layout.json').read_text(encoding='utf8'))
forks=data['forks']
def left(d,x):
 for a,b in forks:
  if a-120<=d<=b+120:
   t=min(1,max(0,(d-a+120)/120),max(0,(b+120-d)/120));t=t*t*(3-2*t)
   return x*(1-t)-4.4*t
 return x
points=','.join('{%.5f,%.5f}'%(r['x']*4.8,left(r['meters'],r['x'])*4.8) for r in data['routes'])
code='''assert(not game.RunService:IsRunning())
local f=Instance.new("Folder") f.Name="TemporaryCourseAudit" f.Parent=game.ServerStorage
local root=Instance.new("Folder") root.Name="TemporaryCourseAuditWorld" root.Parent=workspace
local herd=Instance.new("Folder") herd.Name="Monsters" herd.Parent=root
local ok,err=xpcall(function()
 local P=game.ReplicatedStorage.RodeoFantasy
 for _,name in ipairs({"CourseGeometry","HerdMotion","HerdVisibility","MonsterCatalog","HuntRules","Config"}) do P[name]:Clone().Parent=f end
 game.ServerScriptService.GreenStarCourseLayout:Clone().Parent=f
 local n=game.ServerScriptService.HuntWorld:Clone() n.Parent=f
 local text=n.Source
 local lines={}
 for line in text:gmatch("[^\\n]+") do
  if line:find("local Motion=require",1,true) then line='local Motion=require(script.Parent.HerdMotion)'
  elseif line:find("local Course=require",1,true) then line='local Course=require(script.Parent.CourseGeometry)'
  elseif line:find("local Visibility=require",1,true) then line='local Visibility=require(script.Parent.HerdVisibility)'
  elseif line:find("local Catalog=require",1,true) then line='local Catalog=require(script.Parent.MonsterCatalog)' end
  table.insert(lines,line)
 end
 n.Source=table.concat(lines,"\\n")
 local W=require(n).new() local config=require(f.Config) local rules=require(f.HuntRules)
 W.init(root,nil,config,rules)
 local mount={PrimaryPart={Size=Vector3.new(3,3,5)},GetAttribute=function(_,key) return key=="SizeClass" and "Small" or false end}
 local paths={'''+points+'''}
 local maximum=0
 for d=0,2000 do
  local z=-d*4.8 W.ensure(z)
  if d%50==0 then W.cleanup({z}) end
  maximum=math.max(maximum,#root:GetDescendants())
  if d>0 then for branch=1,2 do
   local from=Vector3.new(paths[d][branch],2.05,-(d-1)*4.8)
   local to=Vector3.new(paths[d+1][branch],2.05,z)
   assert(not W.mountedHit(from,to,mount,{},false),"Wall at "..d.." branch "..branch)
   assert(not W.hit(from,to,false,mount,false),"Obstacle at "..d.." branch "..branch)
   local blocked=W.crateHit(from,to,mount,"Small",false)
   assert(not blocked,"Unbreakable crate blocks small starter at "..d)
  end end
 end
 assert(maximum<3000,"Chunks grew without bound")
 print("COURSE_STUDIO_SWEEP_PASS",2000,"metres, 2 paths; max loaded instances",maximum)
end,debug.traceback)
root:Destroy() f:Destroy()
assert(ok,err)
'''
(R/'.tools/CourseAudit.commandbar.lua').write_text(code,encoding='utf8')
print('Generated actual Studio collision audit')
