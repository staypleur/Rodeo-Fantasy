from pathlib import Path
import sys,xml.etree.ElementTree as E
r=Path.cwd();doc=E.parse(sys.argv[1]).getroot()
def name(n):return n.findtext("Properties/string[@name='Name']")
def child(n,key):return next(v for v in n.findall('Item') if name(v)==key)
def service(key):return next(v for v in doc.findall('Item') if v.get('class')==key)
p=child(service('ReplicatedStorage'),'RodeoFantasy');c=child(service('StarterPlayer'),'StarterPlayerScripts')
paths=['src/client/BagUI.luau','src/client/HudIcons.luau','src/client/HuntEffects.luau','src/client/NativeMossrat.luau','src/client/PetPromptUI.luau','src/client/RocketDeparture.client.luau','src/client/UserMossratRigAnimator.luau','src/client/RideAnimator.luau','src/server/CaptureServer.server.luau','src/server/LobbyCompanions.luau','src/server/RocketDepartureService.luau','src/shared/DepartureSelectionRules.luau','src/shared/LobbyRideRules.luau','src/shared/UserMossratRigDataS9.luau']
paths += ['src/client/BipedAnimator.luau','src/client/QuadrupedAnimator.luau','src/shared/BipedMotionData.luau','src/shared/QuadrupedMotion.luau','src/client/MonsterPortrait.luau','src/client/JournalUI.luau','src/client/SocialUI.luau']
paths += ['src/shared/BagRules.luau','src/client/CaptureClient.client.luau','src/client/NeutralMossratAnimator.luau','src/server/InventoryStore.luau']
for path in paths:
 key=Path(path).name.replace('.client.luau','').replace('.server.luau','').replace('.luau','')
 parent=c if '/client/' in path else p if '/shared/' in path else service('ServerScriptService')
 assert child(parent,key).findtext("Properties/ProtectedString[@name='Source']").replace('\r\n','\n')==(r/path).read_text(encoding='utf8'),key
for stage,height in [(1,2.5),(3,4.25),(6,7),(9,12)]:
 suffix='' if stage==1 else '_S'+str(stage)
 for parent,key in [(p,'VisualTemplate'+suffix),(p,'MeshyMossratHuntTemplate'+suffix),(service('ServerStorage'),'RodeoMonsterTemplate'+suffix)]:
  m=child(parent,key);body=child(m,'Body');props=body.find('Properties')
  assert abs(float(props.findtext("Vector3[@name='size']/Y"))-height)<.01,(key,E.tostring(props)[:400])
  assert len([b for b in body.iter('Item') if b.get('class')=='Bone'])==(34 if stage==9 else 23),key
  if stage==6:
   assert props.findtext("Content[@name='MeshId']/url")=='rbxassetid://95452286447649',key
   surface=next(x for x in body.findall('Item') if x.get('class')=='SurfaceAppearance')
   assert '122822919155461' in E.tostring(surface).decode(),key
  if stage==9:
   assert props.findtext("bool[@name='DoubleSided']")=='true'
   surface=next(x for x in body.findall('Item') if x.get('class')=='SurfaceAppearance')
   assert '102088380784982' in E.tostring(surface).decode()
print(f'RIDE_SAVED_PASS: {len(paths)} modules match; 12 templates; provided S6 mesh/23 bones/color; tier sizes and S9 surfaces')
