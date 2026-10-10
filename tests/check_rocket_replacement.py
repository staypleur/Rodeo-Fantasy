"""Execute the generated replacement transaction with mock instances in Luau."""
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'dist/ReviewModels/InstallUserRocket.commandbar.lua').read_text(encoding='utf-8')
begin=source.index('if installed then\n');end=source.index('local airship=assert',begin)
replacement=source[begin:end]
harness='''local V={} V.__index=V
function V.__sub(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},V) end
function V.__add(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},V) end
function V.__mul(a,b) return a+b end
local Vector3={new=function(x,y,z) if type(x)=="table" then return x end return setmetatable({X=x,Y=y,Z=z},V) end}
local CFrame={new=Vector3.new,Angles=function() return Vector3.new(0,0,0) end}
local created={}
local instance={}
instance.__index=function(t,k) if k=="Parent" then return rawget(t,"parent") end return instance[k] or rawget(t,k) end
instance.__newindex=function(t,k,v)
 if k=="Parent" then if t.failParent and v==t.failParent then error("Injected parent failure") end rawset(t,"parent",v)
 else rawset(t,k,v) end
end
function instance:SetAttribute(k,v) self.attributes[k]=v end
function instance:GetAttribute(k) return self.attributes[k] end
function instance:GetBoundingBox() return {Position=self.center},self.size end
function instance:GetScale() return self.scale end
function instance:ScaleTo(s) local ratio=s/self.scale self.scale=s self.size=Vector3.new(self.size.X*ratio,self.size.Y*ratio,self.size.Z*ratio) end
function instance:GetPivot() return self.center end
function instance:PivotTo(c) self.center=c end
function instance:GetDescendants() return {} end
function instance:Destroy() self.destroyed=true self.Parent=nil end
local function make(name) local t=setmetatable({Name=name,attributes={},scale=1,size=Vector3.new(10,18,10),center=Vector3.new(0,9,0)},instance) table.insert(created,t) return t end
local cloneFail=false
function instance:Clone() local t=make("Clone") if cloneFail then t.failParent=airport end return t end
local Instance={new=function() return make("Folder") end}
local service={SetWaypoint=function() end,Set=function() end}
local game={GetService=function() return service end}
local installed,imported,storage,airport
local function execute()
'''+replacement+'''
end
local function setup()
 storage=make("Storage") airport=make("Airport") installed=make("OldRocket") imported=make("RocketImport")
 installed.center=Vector3.new(6000,34.142857,0) installed.size=Vector3.new(32,64.285714,32)
 installed.Parent=airport imported.Parent=make("Workspace")
end
setup() execute()
local current=created[#created-1]
assert(installed.Parent~=airport and imported.Parent==installed.Parent,"Originals archived together")
assert(current.Name=="Rocket" and current.Parent==airport and current:GetAttribute("UserRocketSourceSha256"),"New model installed")
assert(math.abs(current.center.Y-current.size.Y/2-2)<.0001 and current.center.X==6000,"Ground and center preserved")
installed=current local before=#created execute() assert(#created==before,"Current model is idempotent")
setup() local oldParent=imported.Parent
cloneFail=true
-- Inject failure when assigning the new clone to airport, after originals move.
local savedClone=instance.Clone
instance.Clone=function(self) local t=make("Clone") t.failParent=airport return t end
local ok=pcall(execute)
assert(not ok and installed.Parent==airport and imported.Parent==oldParent,"Rollback restores originals")
instance.Clone=savedClone
print("ROCKET_REPLACEMENT_PASS: current model no-op, center/base placement, original/input backup, injected transaction rollback")
'''
# The first mock Clone references a global; the failure test overrides it explicitly.
path=ROOT/'.tools/test_rocket_replacement.luau';path.write_text(harness,encoding='utf-8')
subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path.relative_to(ROOT))],cwd=ROOT,check=True)
