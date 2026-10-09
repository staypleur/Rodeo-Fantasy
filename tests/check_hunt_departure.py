"""Execute the real departure transaction: missing model, recovery, failure, retry."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
source=(R/'src/server/CaptureServer.server.luau').read_text(encoding='utf-8')
block=source[source.index('local function huntTemplate()'):source.index('local function launch(')]
prefix='''
local destroyed=0
local Instance={new=function() return {SetAttribute=function() end,Destroy=function(self) self.destroyed=true destroyed+=1 end} end}
local storage={FindFirstChild=function(self,name) return self[name] end}
local approved={PrimaryPart={},IsA=function() return true end,GetAttribute=function() return true end}
function approved:Clone() return {PrimaryPart=self.PrimaryPart} end
local package={FindFirstChild=function() return approved end}
local game={GetService=function() return storage end}
local warnings={}
local warn=function(message) table.insert(warnings,message) end
local frame=setmetatable({}, {__mul=function(a,b) return a end})
local CFrame={new=function() return frame end}
local Vector3={new=function() return {} end}
local root={Anchored=false,CFrame=frame}
local humanoid={Health=100,AutoRotate=true,PlatformStand=false}
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end}
local player={UserId=1,Character=character,GetAttribute=function() return nil end}
local states,worlds,worldRoots,views,huntGroups={},{},{},{},{}
local runs,Config,Rules={},{},{}
local tuning={IntroSeconds=1,RideHeightStuds=1}
local now=function() return 0 end
local Lobby={canDepart=function() return true end}
local messages={}
local send=function(_,reason) table.insert(messages,reason or "started") end
local restores=0
local restoreAvatar=function() restores+=1 end
local freeMount=function() end
local setCharacterGroup=function() end
local isolateRoot=function() end
local attachRope=function() end
local fail=false
local model={SetAttribute=function() end,GetAttribute=function() return nil end,GetPivot=function() return frame end}
local World={new=function()
 return {init=function(_,template) assert(template.PrimaryPart) if fail then error("injected init failure") end end,
 ensure=function() end,replenish=function() end,spawn=function() return model end}
end}
'''
suffix='''
-- No approved fallback: failure must not publish a partial world or freeze avatar.
approved=nil
start(player)
assert(worlds[player]==nil and states[player]==nil and worldRoots[player]==nil)
assert(destroyed==1 and not root.Anchored and warnings[1]:find("HUNT_START_FAILED"))
-- Approved fallback allows another E attempt without reconnecting.
approved={PrimaryPart={},IsA=function() return true end,GetAttribute=function() return true end,Clone=function(self) return {PrimaryPart=self.PrimaryPart} end}
start(player)
assert(worlds[player] and worldRoots[player] and states[player].monster==model)
assert(root.Anchored and not humanoid.AutoRotate and humanoid.PlatformStand)
-- An unsuccessful restart keeps the old world and completed-run state intact.
local beforeWorld,beforeRoot,beforeState=worlds[player],worldRoots[player],states[player]
beforeState.phase="GameOver"
fail=true
start(player)
assert(worlds[player]==beforeWorld and worldRoots[player]==beforeRoot and states[player]==beforeState)
assert(not beforeRoot.destroyed and restores==0)
fail=false
start(player)
assert(worlds[player]~=beforeWorld and beforeRoot.destroyed and restores==1)
-- Existing server template wins over the fallback.
local existing={PrimaryPart={}}
storage.RodeoMonsterTemplate=existing
approved=nil
assert(huntTemplate()==existing)
print("HUNT_DEPARTURE_PASS: missing template, approved recovery, atomic failure, retry and restart")
'''
path=R/'.tools/hunt_departure.luau'
path.write_text(prefix+block+suffix,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
