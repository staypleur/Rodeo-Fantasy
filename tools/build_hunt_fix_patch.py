from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def q(s):
 e='='
 while ']'+e+']' in s:e+='='
 return '['+e+'['+s+']'+e+']'
spec=[('C','CaptureClient','src/client/CaptureClient.client.luau','LocalScript'),('C','DistanceMarkers','src/client/DistanceMarkers.luau','ModuleScript'),('P','PlanetCatalog','src/shared/PlanetCatalog.luau','ModuleScript'),('P','HerdVisibility','src/shared/HerdVisibility.luau','ModuleScript'),('P','HerdSpawnPlan','src/shared/HerdSpawnPlan.luau','ModuleScript'),('S','HuntWorld','src/server/HuntWorld.luau','ModuleScript')]
rows=[]
for parent,name,path,cls in spec:
 old=subprocess.run(['git','show','HEAD:'+path],cwd=R,capture_output=True)
 before=q(old.stdout.decode('utf8')) if old.returncode==0 else 'nil'
 rows.append('{parent='+q(parent)+',name='+q(name)+',class='+q(cls)+',before='+before+',after='+q((R/path).read_text(encoding='utf8'))+'}')
code='assert(not game.RunService:IsRunning()); assert(game.GameId==10770388358 and game.PlaceId==131121026461681); local parents={C=game.StarterPlayer.StarterPlayerScripts,P=game.ReplicatedStorage.RodeoFantasy,S=game.ServerScriptService}; local updates={'+','.join(rows)+'}; local function norm(s) return s:gsub("\\r\\n","\\n") end; for _,u in ipairs(updates) do local n=parents[u.parent]:FindFirstChild(u.name); assert((not n and not u.before) or (n and n:IsA(u.class) and (norm(n.Source)==norm(u.before or "") or norm(n.Source)==norm(u.after))),"Source changed "..u.name); assert(loadstring(u.after)); end; local backup=Instance.new("Folder"); backup.Name="HuntFixBackup_"..game.HttpService:GenerateGUID(false); backup.Parent=game.ServerStorage; game.ChangeHistoryService:SetWaypoint("Before hunt fixes"); for _,u in ipairs(updates) do local n=parents[u.parent]:FindFirstChild(u.name); if n then n:Clone().Parent=backup else n=Instance.new(u.class); n.Name=u.name; n.Parent=parents[u.parent] end; n.Source=u.after; end; game.ChangeHistoryService:SetWaypoint("Hunt fixes"); print("HUNT_FIX_INSTALLED",#updates)'
(R/'.tools/HuntFix.commandbar.lua').write_text(code,encoding='utf8')
