"""Execute actual authoring modules with numeric rotation and Studio API stubs."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
code=r'''
local vm={} vm.__index=vm
local function V(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm) end
vm.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub=function(a,b) return V(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__mul=function(a,b) return V(a.X*b,a.Y*b,a.Z*b) end
local cm={}
local function F(v,yaw) return setmetatable({Position=v or V(),yaw=yaw or 0},cm) end
cm.__index=function(self,k) if k=='Rotation' then return F(V(),self.yaw) end return cm[k] end
local function rotate(v,yaw) return V(math.cos(yaw)*v.X+math.sin(yaw)*v.Z,v.Y,-math.sin(yaw)*v.X+math.cos(yaw)*v.Z) end
cm.__mul=function(a,b) return F(a.Position+rotate(b.Position,a.yaw),a.yaw+b.yaw) end
function cm:ToObjectSpace(b) return F(rotate(b.Position-self.Position,-self.yaw),b.yaw-self.yaw) end
function cm:PointToWorldSpace(v) return self.Position+rotate(v,self.yaw) end
local CFrame={new=function(x,y,z) if type(x)=='number' then return F(V(x,y,z)) end return F(x) end,Angles=function(_,y,_) return F(V(),y) end}
local Vector3={new=V}
local objects={}
local function obj(kind,name)
 local o={ClassName=kind,Name=name,attrs={},CFrame=F()}
 function o:IsA(k) return k==kind end
 function o:GetAttribute(k) return self.attrs[k] end
 function o:SetAttribute(k,v) self.attrs[k]=v end
 function o:GetChildren() local out={} for _,c in ipairs(objects) do if c.Parent==self then table.insert(out,c) end end return out end
 function o:FindFirstChild(name) for _,c in ipairs(self:GetChildren()) do if c.Name==name then return c end end end
 function o:Clone() local c=obj(kind,self.Name) c.CFrame=self.CFrame c.Source=self.Source c.PrimaryPart=self.PrimaryPart for k,v in pairs(self.attrs) do c.attrs[k]=v end return c end
 function o:Destroy() self.Parent=nil end
 table.insert(objects,o) return o
end
local Instance={new=function(k) return obj(k,k) end}
local package=obj('Folder','RodeoFantasy')
local ss=obj('Folder','ServerStorage')
local hunt=obj('Model','MeshyMossratHuntTemplate');hunt.Parent=package
local server=obj('Model','RodeoMonsterTemplate');server.Parent=ss
for _,model in ipairs({hunt,server}) do
 model.PrimaryPart=obj('Part','Root');model.PrimaryPart.Parent=model
 local body=obj('MeshPart','Body');body.CFrame=F(V(0,-.8,0),math.pi);body.Parent=model
 model:SetAttribute('NativeMeshyMossrat',true);model:SetAttribute('HuntFacingRepair20261010',true)
end
local ship=obj('Model','Airship');ship:SetAttribute('NativeMeshyAirship',true)
local body=obj('MeshPart','MeshyAirshipBody');body.Parent=ship
local workspace={RodeoLobby={Airport={Airship=ship}}}
local game={GetService=function(_,k) return ({RunService={IsRunning=function() return false end},ReplicatedStorage={RodeoFantasy=package},ServerStorage=ss})[k] end}
local D={Height=90,SourceHeight=10,WorldAnchor={6000,41.0569904608,0},SourceAnchor={0,0,5}}
local installer=obj('ModuleScript','MeshyAirshipInstaller');installer.Parent=package;package.MeshyAirshipInstaller=installer
local script={Parent={MeshyAirshipData=D}}
local realInstaller
local requires=0
local require=function(m) if m==D then return D end assert(m~=installer,'must avoid old require cache');requires+=1;return realInstaller end
realInstaller=(function()
__MeshyAirshipInstaller__
end)()
local repair=(function()
__MeshyLobbyRepair__
end)()
assert(repair.apply());assert(requires==1)
assert(hunt:GetAttribute('MeshyVisualYawDegrees')==180 and not hunt:GetAttribute('HuntFacingRepair20261010'))
local canonical=hunt:FindFirstChild('Body').CFrame
assert(math.abs(math.sin(canonical.yaw))<1e-5 and math.cos(canonical.yaw)>.99,'old direct-body patch must normalize before runtime yaw')
assert(math.cos(body.CFrame.yaw)>.99,'native -Z import must retain -Z face after airship correction')
local contact=body.CFrame:PointToWorldSpace(V(.0124306679,-5,-5-.0058398247)*9)
assert(math.abs(contact.Z)<1e-4 and math.abs(contact.X-6000)<1e-4,'converted native torso anchor must be over the deck')
local first=body.CFrame
assert(repair.apply());assert(requires==2 and body.CFrame.Position.Z==first.Position.Z and body.CFrame.yaw==first.yaw)
assert(hunt:FindFirstChild('Body').CFrame.yaw==canonical.yaw,'repeat must not rotate source again')
local backup=ss:FindFirstChild('LobbyRepairBackup20261010');assert(#backup:GetChildren()==3,'backup once only')
print('LOBBY_REPAIR_PASS: legacy correction normalization, cached-require avoidance, native -Z alignment, deck anchor, repeat stability, one backup')

'''
for name in ("MeshyAirshipInstaller","MeshyLobbyRepair"):
 code=code.replace("__"+name+"__",(R/"src/authoring"/(name+".luau")).read_text(encoding="utf-8"))
p=R/".tools/check_lobby_repair.luau";p.write_text(code,encoding="utf-8")
subprocess.run([str(R/".tools/luau/luau.exe"),str(p.relative_to(R))],cwd=R,check=True)
