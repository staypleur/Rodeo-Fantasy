from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def q(s):
 e='='
 while ']'+e+']' in s:e+='='
 return '['+e+'['+s+']'+e+']'
spec=[('P','CourseGeometry','src/shared/CourseGeometry.luau','ModuleScript'),('S','HuntWorld','src/server/HuntWorld.luau','ModuleScript'),('S','GreenStarCourseLayout','src/server/GreenStarCourseLayout.luau','ModuleScript'),('S','CaptureServer','src/server/CaptureServer.server.luau','Script'),('C','CaptureClient','src/client/CaptureClient.client.luau','LocalScript'),('C','CrashEffect','src/client/CrashEffect.luau','ModuleScript')]
rows=[]
for parent,name,path,cls in spec:
 old=subprocess.run(['git','show','64db03d:'+path],cwd=R,capture_output=True,check=True).stdout.decode('utf8')
 rows.append('{parent='+q(parent)+',name='+q(name)+',class='+q(cls)+',before='+q(old)+',after='+q((R/path).read_text(encoding='utf8'))+'}')
code='assert(not game.RunService:IsRunning()); assert(game.GameId==10770388358 and game.PlaceId==131121026461681); local parents={C=game.StarterPlayer.StarterPlayerScripts,P=game.ReplicatedStorage.RodeoFantasy,S=game.ServerScriptService}; local updates={'+','.join(rows)+'}; local function norm(s) return s:gsub("\\r\\n","\\n") end; for _,u in ipairs(updates) do local n=parents[u.parent]:FindFirstChild(u.name); assert(n and n:IsA(u.class) and (norm(n.Source)==norm(u.before) or norm(n.Source)==norm(u.after)),"Source changed "..u.name); assert(loadstring(u.after)); end; local backup=Instance.new("Folder"); backup.Name="MixedCourseBackup_"..game.HttpService:GenerateGUID(false); backup.Parent=game.ServerStorage; game.ChangeHistoryService:SetWaypoint("Before mixed course"); for _,u in ipairs(updates) do local n=parents[u.parent][u.name]; n:Clone().Parent=backup; n.Source=u.after; end; game.ChangeHistoryService:SetWaypoint("Mixed mountain canyon course"); print("MIXED_COURSE_INSTALLED",#updates)'
(R/'.tools/MixedCourse.commandbar.lua').write_text(code,encoding='utf8')
