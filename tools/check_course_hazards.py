from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
source=(R/'src/shared/CourseGeometry.luau').read_text(encoding='utf8')
test='local C=(function()\n'+source+'\nend)()\n'+'''
for d=0,2000 do local w=C.width(-d*4.8)*2 assert(w>=48 and w<=70) end
for i,f in C.Forks do
 local z=-(f[1]+f[2])/2*4.8
 assert(C.hazard(0,z,1,false)==(i%2==1 and "Wall" or "CanyonFall"))
 assert(C.hazard(0,z,1,true)==nil)
 assert(C.hazard(21.12,z,1,false)==nil)
 assert(C.hazard(-21.12,z,1,false)==nil)
 assert(C.hazard(40,z,1,true)=="Wall")
 assert(C.hazard(0,-f[1]*4.8,1,false)==nil)
 assert(C.hazard(0,-f[2]*4.8,1,false)==nil)
end
print("COURSE_HAZARDS_PASS", "48..70 width; mountain wall/canyon fall; both roads; flying; tapered endpoints")
'''
(R/'.tools/course-hazards-test.luau').write_text(test,encoding='utf8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/course-hazards-test.luau'],cwd=R,check=True)
