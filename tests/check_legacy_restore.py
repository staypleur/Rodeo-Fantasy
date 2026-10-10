from pathlib import Path
import subprocess,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
course=R/'src/shared/CourseGeometry.luau'
assert course.read_text()==subprocess.check_output(['git','show','17297b5:src/shared/CourseGeometry.luau'],cwd=R).decode()
world=(R/'src/server/HuntWorld.luau').read_text()
old=subprocess.check_output(['git','show','17297b5:src/server/HuntWorld.luau'],cwd=R).decode()
assert world.split('\n',1)[1].replace('function World.groundHeight(x,z) return 0 end\n\n','')==old
assert 'RoadHalfWidth = 35' in (R/'src/shared/Config.luau').read_text()
assert 'yaw+=180' in (R/'src/client/NativeMossrat.luau').read_text()
def models(path):
 r=E.parse(path)
 result=[]
 for item in r.findall('.//Item'):
  if item.get('class') in ('MeshPart','Bone','SurfaceAppearance'):
   result.append((item.get('class'),E.tostring(item.find('Properties'))))
 return result
baseline=R/'.local-backup/before-current-fixes/RodeoFantasy-New.rbxlx'
if not baseline.exists():baseline=R/'.local-backup/before-legacy-hunt/RodeoFantasy-New.rbxlx'
# Compare uploaded templates by role, ignoring unrelated preview/backup models.
def templates(path):
 result={}
 for item in E.parse(path).findall('.//Item'):
  n=item.findtext("Properties/string[@name='Name']")
  if n in ('RodeoMonsterTemplate','VisualTemplate','MeshyMossratHuntTemplate') and any(x.get('class')=='MeshPart' for x in item.iter('Item')) and n not in result:
   result[n]=[(x.get('class'),E.tostring(x.find('Properties'))) for x in item.iter('Item') if x.get('class') in ('MeshPart','Bone','SurfaceAppearance')]
 return result
assert templates(R/'dist/RodeoFantasy-New.rbxlx')==templates(baseline)
for p in ['src/shared/CourseGeometry.luau','src/server/HuntWorld.luau','src/shared/Config.luau','src/client/NativeMossrat.luau','dist/RestoreLegacyHunt.commandbar.lua','dist/InstallCentralRocket.commandbar.lua']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),p],cwd=R,stdout=subprocess.DEVNULL,check=True)
print('LEGACY_MAP_SOURCE_MATCH; MODEL_PROPERTIES_PRESERVED; LUAU_COMPILES')
