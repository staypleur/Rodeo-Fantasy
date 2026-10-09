"""Exercise the actual client audio module against an isolated sound service stub."""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[1]
config=(ROOT/'src/shared/Config.luau').read_text(encoding='utf-8')
audio=(ROOT/'src/client/AudioPresentation.luau').read_text(encoding='utf-8')
prefix='''local cfg=(function()\n'''+config+'''\nend)()
local function client()
 local created={}
 local service={}
 local node={} function node:WaitForChild() return self end
 local game={} function game:GetService(name) if name=="SoundService" then return service else return node end end
 local require=function() return cfg end
 local Instance={new=function(kind)
  local object={ClassName=kind}
  function object:Play() self.Playing=true end
  function object:Stop() self.Playing=false end
  function object:Destroy() self.Parent=nil end
  table.insert(created,object) return object
 end}
 local task={spawn=function() end} -- Do not simulate fetch success or real playback.
 local Enum={RollOffMode={InverseTapered='InverseTapered'}}
 local module=(function()\n'''
suffix='''
 end)()
 return module,created,service
end
local a,nodesA=client() local b,nodesB=client()
assert(a.getVolume('Music')==1 and a.getVolume('Effects')==1)
assert(a.setVolume('Music',0) and a.setVolume('Effects',.35))
assert(a.getVolume('Music')==0 and a.getVolume('Effects')==.35)
assert(b.getVolume('Music')==1 and b.getVolume('Effects')==1,'client volume must be isolated')
assert(not a.setVolume('Bogus',.5) and not a.setVolume('Music',0/0))
assert(not a.setVolume('Music','bad'))
assert(a.setVolume('Effects',9) and a.getVolume('Effects')==1)
assert(a.setVolume('Effects',-2) and a.getVolume('Effects')==0)
local monsters={GetChildren=function() return {} end}
local state={area='Lobby',phase='Idle'}
a.update(state,monsters,nil,0,nil)
state.area='Hunt' state.phase='Riding' state.tamed=false
a.update(state,monsters,nil,1,nil)
state.tamed=true a.update(state,monsters,nil,2,nil)
for _,event in ipairs({'BookOpen','PageTurn','BagOpen'}) do a.ui(event) end
a.ui('Bogus')
for _,sound in ipairs(nodesA) do if sound.ClassName=='Sound' then
 local isMusic=sound.Name=='RodeoBGM' or sound.Name=='RodeoLobbyBGM'
 assert(sound.SoundGroup.Name==(isMusic and 'RodeoLocalMusic' or 'RodeoLocalEffects'))
 assert(sound.SoundGroup.Volume==0,'new sounds and new events must stay muted')
end end
assert(a.setVolume('Effects',.65))
for _,sound in ipairs(nodesA) do if sound.ClassName=='Sound' then
 local isMusic=sound.Name=='RodeoBGM' or sound.Name=='RodeoLobbyBGM'
 assert(sound.SoundGroup.Volume==(isMusic and 0 or .65),'effects restore must not change music')
end end
local mount={PrimaryPart={Position={}},GetAttribute=function(self,key)
 if key=='Running' or key=='Occupied' then return true end
 if key=='SizeClass' then return 'Small' end
end}
mount.PrimaryPart.Position=setmetatable({},{__sub=function() return {Magnitude=0} end})
function monsters:GetChildren() return {mount} end
state.monster=mount a.update(state,monsters,{},3,nil)
local hoof
for _,sound in ipairs(nodesA) do if sound.Name=='RodeoHooves' then hoof=sound end end
assert(hoof and hoof.SoundGroup.Name=='RodeoLocalEffects' and hoof.SoundGroup.Volume==.65)
a.setVolume('Effects',0) assert(hoof.SoundGroup.Volume==0,'running sound must mute immediately')
state.area='Lobby' state.phase='Idle' a.update(state,nil,nil,4,nil)
assert(a.getVolume('Music')==0 and a.getVolume('Effects')==0,'world change must not reset volume')
print('LOCAL_AUDIO_SETTINGS_PASS: two-client isolation, clamping, separate groups, live mute/restore, new events/hooves and world transitions')
'''
harness=ROOT/'.tools/local_audio_settings_harness.luau'
harness.write_text(prefix+audio+suffix,encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(harness.relative_to(ROOT))],cwd=ROOT,check=True)
