"""Verify real asset limits, preserved cafe geometry/PBR, and native runtime path."""
from pathlib import Path
import json,struct,subprocess,hashlib
import numpy as np
R=Path(__file__).resolve().parents[1]
def load(path):
 raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0]
 assert struct.unpack_from('<III',raw)==(0x46546c67,2,len(raw))
 g=json.loads(raw[20:20+n]);b=raw[28+n:]
 def accessor(i):
  a=g['accessors'][i];v=g['bufferViews'][a['bufferView']]
  return np.frombuffer(b,dtype={5126:'<f4',5125:'<u4',5123:'<u2'}[a['componentType']],count=a['count']*{'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']],offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(a['count'],-1)
 return g,b,accessor
base=R/'assets/meshes/meshy'
original=base/'Mossrat_S1_Source.glb'
source,sb,sa=load(original)
sp=source['meshes'][0]['primitives'][0];sf=sa(sp['indices']).reshape(-1).astype(int)
counts={}
for role in ('Hunt','Detail'):
 source,sb,sa=load(base/('Mossrat_S1_Source10k.glb' if role=='Detail' else 'Mossrat_S1_Source.glb'))
 sp=source['meshes'][0]['primitives'][0];sf=sa(sp['indices']).reshape(-1).astype(int)
 g,b,a=load(base/f'Mossrat_S1_{role}.glb');total=0
 for mesh in g['meshes']:
  p=mesh['primitives'][0];indices=a(p['indices']).reshape(-1).astype(int)
  assert len(indices)%3==0 and len(indices)//3<=20000
  for name in ('POSITION','NORMAL','TEXCOORD_0'):
   values=a(p['attributes'][name]);assert np.isfinite(values).all() and indices.max()<len(values)
   expected=sa(sp['attributes'][name])[sf]
   if name!='TEXCOORD_0':expected=expected*np.array([-1,1,-1],dtype=np.float32)
   assert np.array_equal(values[indices],expected),'approved source geometry or UVs changed'
  total+=len(indices)//3
 assert g['materials']==source['materials']
 if role=='Detail':
  for image,old in zip(g['images'],source['images']):
   v=g['bufferViews'][image['bufferView']];ov=source['bufferViews'][old['bufferView']]
   assert b[v['byteOffset']:v['byteOffset']+ov['byteLength']]==sb[ov['byteOffset']:ov['byteOffset']+ov['byteLength']]
 counts[role]=total
assert counts=={'Hunt':3114,'Detail':10348}
assert (base/'Mossrat_S1_Hunt.glb').stat().st_size<1000000
code='''
local objects={}
local vm={} vm.__index=vm
local function V(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm) end
vm.__mul=function(a,b) return V(a.X*b,a.Y*b,a.Z*b) end
vm.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
local cm={} cm.__index=cm
local function F(v) return setmetatable({Position=v or V(),Rotation=0},cm) end
cm.__mul=function(a,b) if b==0 then return a end return F(a.Position+b.Position) end
function cm:ToObjectSpace(b) return F(V(b.Position.X-self.Position.X,b.Position.Y-self.Position.Y,b.Position.Z-self.Position.Z)) end
local CFrame={new=F,Angles=function(x,y,z) return F(V(x,y,z)) end} local Color3={new=function(...) return {...} end}
local function obj(kind,name)
 local o={ClassName=kind,Name=name,attrs={},Size=V(1,1,1),CFrame=F()}
 function o:IsA(k) return k==kind or k=='BasePart' and (kind=='MeshPart' or kind=='Part') end
 function o:GetAttribute(k) return self.attrs[k] end
 function o:SetAttribute(k,v) self.attrs[k]=v end
 function o:GetChildren() local result={} for _,c in ipairs(objects) do if c.Parent==self then table.insert(result,c) end end return result end
 function o:GetDescendants() local result={} for _,c in ipairs(self:GetChildren()) do table.insert(result,c) for _,d in ipairs(c:GetDescendants()) do table.insert(result,d) end end return result end
 function o:FindFirstChild(name) for _,c in ipairs(self:GetChildren()) do if c.Name==name then return c end end end
 function o:WaitForChild(name) return self:FindFirstChild(name) or self[name] end
 function o:Destroy() self.Parent=nil self.destroyed=true end
 function o:Clone() local copy=obj(kind,name) for k,v in pairs(self) do if type(v)~='function' and k~='Parent' and k~='attrs' then copy[k]=v end end for _,c in ipairs(self:GetChildren()) do c:Clone().Parent=copy end return copy end
 table.insert(objects,o) return o
end
local package=obj('Folder','RodeoFantasy')
local C={stage=function(s) return s>=3 and 3 or 1 end,scale=function(s) return s==2 and 1.2 or 1 end}
package.MonsterCatalog=C
local detail=obj('Model','VisualTemplate');detail.Parent=package;detail:SetAttribute('NativeMeshyMossrat',true);package.VisualTemplate=detail
local hunt=obj('Model','MeshyMossratHuntTemplate');hunt.Parent=package
for _,t in ipairs({detail,hunt}) do
 t.PrimaryPart=obj('Part','Root');t.PrimaryPart.Parent=t
 local body=obj('MeshPart','Body');body.Parent=t;body.CFrame=F(V(0,-1,0));body.TextureID='uploaded-texture';body.MeshId='uploaded-mesh'
 obj('SurfaceAppearance','PBR').Parent=body
 for _,name in ipairs({'MossLeftFrontLeg','MossRightFrontLeg','MossLeftBackLeg','MossRightBackLeg'}) do local bone=obj('Bone',name);bone.CFrame=F(V(.1,.2,.3));bone.Parent=body end
end
local game={GetService=function() return {WaitForChild=function() return package end} end}
local require=function(x) return x end
local M=(function()
'''+(R/'src/client/NativeMossrat.luau').read_text(encoding='utf-8')+'''
end)()
local model=obj('Model','Wild');model.PrimaryPart=obj('Part','Root');model.PrimaryPart.Parent=model;model.PrimaryPart.CFrame=F(V(5,2.05,-80));model:SetAttribute('MonsterId','MeadowMouse');model:SetAttribute('Stars',2);model:SetAttribute('VisualDeferred',true)
local old=obj('Part','OldBody');old.Parent=model
assert(M.apply(model));assert(old.destroyed)
local body=model:FindFirstChild('Body');assert(body.MeshId=='uploaded-mesh' and body.TextureID=='uploaded-texture' and body:FindFirstChild('PBR'))
assert(math.abs(body.CFrame.Position.Y-.85)<.00001 and model.PrimaryPart.CFrame.Position.Y==2.05)
local allocations=#objects;assert(M.apply(model) and #objects==allocations,'repeat must not allocate new geometry')
M.animate(model,math.pi/2,true,false)
assert(body:FindFirstChild('MossLeftFrontLeg').Transform.Position.X>.4 and body:FindFirstChild('MossRightFrontLeg').Transform.Position.X<-.4,'diagonal leg bones must alternate')
assert(math.abs(body:FindFirstChild('MossLeftFrontLeg').CFrame.Position.Y-.24)<.00001,'bones must scale with intermediate-star meshes')
M.animate(model,math.pi/2,false,false);assert(body:FindFirstChild('MossLeftFrontLeg').Transform.Position.X==0,'resting restores bind pose')
model:SetAttribute('Stars',3);assert(not M.isTarget(model),'higher stars retain approved designs')
local silhouette=obj('Model','Silhouette');silhouette.PrimaryPart=obj('Part','Root');silhouette.PrimaryPart.Parent=silhouette;silhouette:SetAttribute('MonsterId','MeadowMouse');silhouette:SetAttribute('PortraitSilhouette',true)
assert(M.apply(silhouette));assert(silhouette:FindFirstChild('Body').TextureID=='' and not silhouette:FindFirstChild('Body'):FindFirstChild('PBR'))
print('NATIVE_RUNTIME_PASS: uploaded texture/PBR clones, root preservation, scale, idempotence, silhouettes, higher-stage exclusion')
'''
tmp=R/'.tools/test_meshy_native.luau';tmp.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_meshy_native.luau'],cwd=R,check=True)
print('MESHY_ASSET_PASS:',counts,'; geometry/UVs unchanged; detailed PBR retained; hunt below 1 MB')
