"""Guarded patch for private lobby/cafe; approved course layout is separate."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def q(s):
 e='='
 while ']'+e+']' in s:e+='='
 return '['+e+'['+s+']'+e+']'
spec=[('C','NeutralMossratAnimator','src/client/NeutralMossratAnimator.luau',False),
 ('C','RideAnimator','src/client/RideAnimator.luau',False),
 ('S','LobbyCompanions','src/server/LobbyCompanions.luau',False),
 ('C','RocketDeparture','src/client/RocketDeparture.client.luau',True),
 ('S','CaptureServer','src/server/CaptureServer.server.luau',True),
 ('S','RecordService','src/server/RecordService.luau',True),
 ('S','RocketDepartureService','src/server/RocketDepartureService.luau',True),
 ('S','PlaceTravel','src/server/PlaceTravel.luau',True),
 ('S','TravelService','src/server/TravelService.luau',True),
 ('P','TravelRules','src/shared/TravelRules.luau',True),
 ('P','CourseGeometry','src/shared/CourseGeometry.luau',True),
 ('P','Config','src/shared/Config.luau',True),
 ('P','MonsterCatalog','src/shared/MonsterCatalog.luau',True),
 ('S','HuntWorld','src/server/HuntWorld.luau',True),
 ('S','GreenStarCourseLayout','src/server/GreenStarCourseLayout.luau',True)]
rows=[]
for parent,name,path,lobby in spec:
 result=subprocess.run(['git','show','HEAD:'+path],cwd=R,capture_output=True)
 before=q(result.stdout.decode('utf8')) if result.returncode==0 else 'nil'
 if name=='RideAnimator':
  old=result.stdout.decode('utf8')
  cafe_old=old.replace("-- The player's mount should not inherit the herd's deliberately soft follow.\n   local response=model:GetAttribute(\"Occupied\") and 45 or 22\n   local blended=pose.frame:Lerp(target,1-math.exp(-response*dt))","local blended=pose.frame:Lerp(target,1-math.exp(-22*dt))")
  before='(game.PlaceId==133084853508719 and '+q(cafe_old)+' or '+before+')'
 if result.returncode!=0 and name=='GreenStarCourseLayout' and (R/'.tools/CourseLayout-before.luau').exists():
  before=q((R/'.tools/CourseLayout-before.luau').read_text(encoding='utf8'))
 cls='LocalScript' if '.client.' in path else 'Script' if '.server.' in path else 'ModuleScript'
 rows.append('{parent='+q(parent)+',name='+q(name)+',class='+q(cls)+',lobby='+str(lobby).lower()+',before='+before+',after='+q((R/path).read_text(encoding='utf8'))+'}')
code='''assert(not game.RunService:IsRunning(),"Stop Play first")
assert(game.GameId==10770388358,"Wrong experience")
assert(game.PlaceId==131121026461681 or game.PlaceId==133084853508719,"Wrong place")
local parents={C=game.StarterPlayer.StarterPlayerScripts,S=game.ServerScriptService,P=game.ReplicatedStorage.RodeoFantasy}
local updates={'''+','.join(rows)+'''}
local function norm(s) return s:gsub("\\r\\n","\\n") end
for _,u in ipairs(updates) do if not u.lobby or game.PlaceId==131121026461681 then
 local n=parents[u.parent]:FindFirstChild(u.name)
 assert((u.before==nil and n==nil) or (n and n:IsA(u.class) and (norm(n.Source)==norm(u.before or "") or norm(n.Source)==norm(u.after))),"Source changed: "..u.name)
 assert(loadstring(u.after),"Compile failed "..u.name)
end end
local backup=Instance.new("Folder") backup.Name="TravelMotionBackup_"..game.HttpService:GenerateGUID(false) backup.Parent=game.ServerStorage
game.ChangeHistoryService:SetWaypoint("Before distance and motion fixes")
local count=0
for _,u in ipairs(updates) do if not u.lobby or game.PlaceId==131121026461681 then
 local n=parents[u.parent]:FindFirstChild(u.name)
 if n then n:Clone().Parent=backup else n=Instance.new(u.class) n.Name=u.name n.Parent=parents[u.parent] end
 n.Source=u.after count+=1
end end
game.ChangeHistoryService:SetWaypoint("Distance and motion fixes")
print("TRAVEL_MOTION_INSTALLED",game.PlaceId,count)
'''
(R/'.tools/TravelMotion.commandbar.lua').write_text(code,encoding='utf8')
print('Generated guarded patch:',len(code),'characters')
