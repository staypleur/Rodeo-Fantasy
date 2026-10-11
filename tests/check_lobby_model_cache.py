from pathlib import Path
import subprocess
r=Path.cwd();s=(r/'src/client/RideAnimator.luau').read_text(encoding='utf8');func=s[s.index('local function lobbyModels'):s.index('local function clearHerdPath')]
h='''local function event() return {Connect=function(self,f) self.fire=f end} end
local scans=0
local function node(class) return {IsA=function(_,c) return class==c end} end
local a,b,part=node('Model'),node('Model'),node('Part')
local root={DescendantAdded=event(),DescendantRemoving=event(),GetDescendants=function() scans+=1 return {a,part} end}
'''+func+'''
local c={} local list=lobbyModels(root,c) assert(#list==1 and list[1]==a)
for _=1,600 do assert(lobbyModels(root,c)==list) end assert(scans==1)
root.DescendantAdded.fire(b) root.DescendantAdded.fire(b) root.DescendantAdded.fire(part) assert(#list==2)
root.DescendantRemoving.fire(a) assert(#list==1 and list[1]==b)
root.DescendantRemoving.fire(b) assert(#list==0)
root.DescendantAdded.fire(a) assert(#list==1 and list[1]==a)
print('LOBBY_MODEL_CACHE_PASS: one scan across 600 frames; late models; no duplicates; removal and re-add')
'''
(r/'.tools/test_lobby_model_cache.luau').write_text(h,encoding='utf8')
subprocess.run([str(r/'.tools/luau/luau.exe'),'.tools/test_lobby_model_cache.luau'],check=True)
