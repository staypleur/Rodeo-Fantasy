"""Exercise the actual installer transaction, validation, no-op and rollback."""
from pathlib import Path
import json,subprocess
ROOT=Path(__file__).resolve().parents[1]
g=json.loads((ROOT/'assets/models/MossratS1UserRig/MossratS1Rigged.gltf').read_text())
parents={child:i for i,n in enumerate(g['nodes']) for child in n.get('children',[])}
names={g['nodes'][j]['name']:g['nodes'][parents[j]]['name'] if j in parents else '' for j in g['skins'][0]['joints']}
hierarchy='{'+','.join('['+json.dumps(n)+']='+json.dumps(p) for n,p in names.items())+'}'
source=(ROOT/'src/authoring/UserMossratInstaller.luau').read_text(encoding='utf-8').replace('__BONE_HIERARCHY__',hierarchy)
harness='''local all={} local failSource=false
local V={} V.__index=V
function V.__mul(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},V) end
function V.__sub(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},V) end
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},V) end}
local CF={} CF.__index=CF
function CF.__mul(a,b) return b end function CF:ToObjectSpace(b) return b end
local CFrame={new=function(x,y,z) return setmetatable({Position=type(x)=="table" and x or Vector3.new(x or 0,y or 0,z or 0)},CF) end}
CFrame.identity=CFrame.new() CF.Rotation=CFrame.identity CFrame.Angles=function() return CFrame.identity end
local O={}
O.__index=function(t,k) if k=="Parent" then return rawget(t,"parent") elseif k=="Source" then return rawget(t,"source") end return O[k] or rawget(t,k) end
O.__newindex=function(t,k,v)
 if k=="Parent" then rawset(t,"parent",v)
 elseif k=="Source" then if failSource and t.Name=="NativeMossrat" then failSource=false error("Injected source assignment failure") end rawset(t,"source",v)
 else rawset(t,k,v) end
end
function O:IsA(k) return self.ClassName==k or k=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart") or k=="LuaSourceContainer" and self.ClassName=="ModuleScript" end
function O:GetChildren() local r={} for _,o in ipairs(all) do if o.Parent==self then table.insert(r,o) end end return r end
function O:GetDescendants() local r={} for _,c in ipairs(self:GetChildren()) do table.insert(r,c) for _,d in ipairs(c:GetDescendants()) do table.insert(r,d) end end return r end
function O:FindFirstChild(name,recursive) for _,c in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do if c.Name==name then return c end end end
function O:IsDescendantOf(p) local n=self.Parent while n do if n==p then return true end n=n.Parent end return false end
function O:SetAttribute(k,v) self.attributes[k]=v end function O:GetAttribute(k) return self.attributes[k] end
function O:GetBoundingBox() return CFrame.new(0,.45,0),Vector3.new(1,.9,1) end
function O:Destroy() for _,c in ipairs(self:GetChildren()) do c:Destroy() end self.Parent=nil self.destroyed=true end
local function make(class,name,parent)
 local o=setmetatable({ClassName=class,Name=name or class,attributes={},CFrame=CFrame.identity,Size=Vector3.new(1,1,1),Transform=CFrame.identity},O)
 table.insert(all,o) o.Parent=parent return o
end
function O:Clone()
 local copy=make(self.ClassName,self.Name)
 for _,k in ipairs({"CFrame","Size","MeshId","Source"}) do if self[k]~=nil then copy[k]=self[k] end end
 for k,v in pairs(self.attributes) do copy.attributes[k]=v end
 for _,child in ipairs(self:GetChildren()) do local c=child:Clone() c.Parent=copy if self.PrimaryPart==child then copy.PrimaryPart=c end end
 return copy
end
local Instance={new=function(class) return make(class) end}
local catalog={MeadowMouse={RootHeight=2.05}}
local require=function() return catalog end
local game,workspace,rs,ss,server,client,package,updates,modules,imported,old
local function loadInstaller() return (function()\n'''+source+'''end)() end
local function setup()
 all={} rs=make("Folder","ReplicatedStorage") ss=make("Folder","ServerStorage") server=make("Folder","ServerScriptService") client=make("Folder","StarterPlayerScripts") workspace=make("Folder","Workspace")
 package=make("Folder","RodeoFantasy",rs) rs.RodeoFantasy=package package.MonsterCatalog=catalog
 game={ReplicatedStorage=rs,ServerScriptService=server,StarterPlayer={StarterPlayerScripts=client},GetService=function(self,n)
  if n=="ReplicatedStorage" then return rs elseif n=="ServerStorage" then return ss elseif n=="RunService" then return {IsRunning=function() return false end} elseif n=="HttpService" then return {GenerateGUID=function() return "TestBackup" end} else return {SetWaypoint=function() end} end
 end}
 old={} for _,t in ipairs({{ss,"RodeoMonsterTemplate"},{package,"VisualTemplate"},{package,"MeshyMossratHuntTemplate"}}) do local m=make("Model",t[2],t[1]) m.PrimaryPart=make("Part","HitRoot",m) make("Part","LegacyBody",m) table.insert(old,m) end
 local native=make("ModuleScript","NativeMossrat",client) native.Source="old"
 updates={{name="NativeMossrat",before="old",after="new"}}
 modules={{parent=client,name="UserMossratRigAnimator",source="return {}"}}
 imported=make("Model","MossratImport",workspace) local mesh=make("MeshPart","Mesh",imported) mesh.MeshId="uploaded-user-mesh"
 local bones={} local hierarchy='''+hierarchy+'''
 for n in pairs(hierarchy) do bones[n]=make("Bone",n) end
 for n,p in pairs(hierarchy) do bones[n].Parent=p=="" and mesh or bones[p] end
end
setup() local M=loadInstaller() M.run(updates,modules)
for i,t in ipairs({{ss,"RodeoMonsterTemplate"},{package,"VisualTemplate"},{package,"MeshyMossratHuntTemplate"}}) do
 local model=t[1]:FindFirstChild(t[2]) assert(model~=old[i] and model:GetAttribute("UserApprovedHuntModel") and model:GetAttribute("MossratUserRigRevision"))
 assert(old[i].Parent==imported.Parent and old[i].Parent.Parent==ss,"Originals archived")
end
assert(client:FindFirstChild("NativeMossrat").Source=="new" and client:FindFirstChild("UserMossratRigAnimator"))
local before=#all M.run(updates,modules) assert(#all==before,"Idempotent no-op")
setup() client:FindFirstChild("NativeMossrat").Source="custom unknown" local ok=pcall(function() loadInstaller().run(updates,modules) end) assert(not ok and old[1].Parent==ss,"Unknown sources untouched")
setup() imported:FindFirstChild("Tail5",true):Destroy() ok=pcall(function() loadInstaller().run(updates,modules) end) assert(not ok and old[1].Parent==ss,"Missing bones rejected before mutation")
setup() failSource=true ok=pcall(function() loadInstaller().run(updates,modules) end)
assert(not ok and imported.Parent==workspace and old[1].Parent==ss and old[2].Parent==package and old[3].Parent==package,"Rollback restores all models")
assert(client:FindFirstChild("NativeMossrat").Source=="old" and not client:FindFirstChild("UserMossratRigAnimator"),"Rollback restores source/modules")
print("MOSSRAT_INSTALLER_PASS: hierarchy validation, version rejection, 3 templates, original backups, idempotence and injected write rollback")
'''
path=ROOT/'.tools/test_user_mossrat_installer.luau';path.write_text(harness,encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path.relative_to(ROOT))],cwd=ROOT,check=True)
