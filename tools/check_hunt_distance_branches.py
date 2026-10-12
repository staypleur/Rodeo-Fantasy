from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
s=(R/'tests/hunt_distance_branches.luau').read_text(encoding='utf8')
for tag,path in [('COURSE','src/shared/CourseGeometry.luau'),('PLAN','src/shared/HerdSpawnPlan.luau'),('VIEW','src/shared/HerdVisibility.luau'),('CONFIG','src/shared/Config.luau')]:
 s=s.replace('-- '+tag+'_SOURCE',(R/path).read_text(encoding='utf8'))
client=(R/'src/client/CaptureClient.client.luau').read_text(encoding='utf8')
assert 'math.min(displayDistance,Course.LengthMeters)' in client
assert 'math.min(displayDistance,1000)' not in client
assert 'local nextDistance=Course.LengthMeters' in (R/'src/client/DistanceMarkers.luau').read_text(encoding='utf8')
(R/'.tools/hunt-distance-branches-test.luau').write_text(s,encoding='utf8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/hunt-distance-branches-test.luau'],cwd=R,check=True)
