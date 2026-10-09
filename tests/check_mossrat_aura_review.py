"""Exercise review aura eligibility, quality, toggling and resource lifecycle."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
prefix=r'''
local objects={}
local function signal()
 local callbacks={}
 return {Connect=function(self,fn) table.insert(callbacks,fn) end,Fire=function() for _,fn in ipairs(callbacks) do fn() end end}
end
local function object(class)
 local o={ClassName=class,Destroying=signal()}
 function o:IsA(c) return c==self.ClassName or c=='BasePart' and self.ClassName=='MeshPart' end
 function o:Destroy() if self.destroyed then return end self.Destroying:Fire() self.destroyed=true self.Parent=nil end
 table.insert(objects,o) return o
end
local Instance={new=object}
local Color3={fromRGB=function(...) return {...} end}
local ColorSequence={new=function(...) return {...} end}
local NumberSequence={new=function(...) return {...} end}
local NumberSequenceKeypoint={new=function(...) return {...} end}
local NumberRange={new=function(...) return {...} end}
local Vector2={new=function(...) return {...} end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Enum={NormalId={Top='Top'}}
local aura=(function()
'''
suffix=r'''
end)()
local function model(stars,species)
 local m={Parent=true};local body=object('MeshPart') body.Parent=m body.Size={X=3,Y=4,Z=6}
 function m:GetAttribute(name) return name=='Stars' and stars or name=='MonsterId' and (species or 'MeadowMouse') end
 function m:FindFirstChild(name)
  if name=='Body' then return body end
  for _,o in ipairs(objects) do if not o.destroyed and o.Parent==self and o.Name==name then return o end end
 end
 return m,body
end
assert(not aura.profile(1) and not aura.profile(3),'young monsters must have no aura')
assert(aura.profile(9).Orbits>aura.profile(6).Orbits,'elder aura distinct')
local young=model(3) assert(not aura.attach(young,{},false))
local other=model(9,'TreeWolf') assert(not aura.attach(other,{},false))
local m=model(9) assert(not aura.attach(m,{},false),'no unapproved placeholder textures')
local textures={Leaf='test-leaf',Glow='test-glow',Spark='test-spark'}
local state=assert(aura.attach(m,textures,true))
local oldAttachments={};local count=0
for _,o in ipairs(objects) do
 if o.ClassName=='ParticleEmitter' and not o.destroyed then count+=1 assert(o.Rate<=9*.45,'mobile rate cap') end
 if o.ClassName=='Attachment' and not o.destroyed then table.insert(oldAttachments,o) end
end
assert(count==12 and #oldAttachments==4)
state:step(.016,false)
for _,o in ipairs(objects) do if o.ClassName=='ParticleEmitter' then assert(o.Enabled==false) end end
state:step(.016,true)
for _,o in ipairs(oldAttachments) do assert(o.Position.X==o.Position.X and o.Position.Z==o.Position.Z) end
local replacement=assert(aura.attach(m,textures,false))
assert(state.dead,'replacing marker destroys old aura')
for _,o in ipairs(oldAttachments) do assert(o.destroyed,'reattach must remove old attachments') end
m.Parent=nil replacement:step(.1,true) assert(replacement.dead,'removed model cleans resources')
replacement:destroy() -- idempotent
print('MOSSRAT_AURA_REVIEW_PASS: eligibility, texture gate, mobile rates, visibility, finite motion, reattach/removal cleanup; API stubs only')
'''
path=R/'.tools/mossrat_aura_review.luau'
path.write_text(prefix+(R/'src/client/MossratAuraReview.luau').read_text(encoding='utf-8')+suffix,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
