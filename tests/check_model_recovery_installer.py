"""Run the batch installer: PBR-pack preservation, mesh validation, and rollback."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
code=r'''
local function scenario(failColor,failInstall,failMesh)
local function V(x,y,z) return {X=x or 0,Y=y or 0,Z=z or 0} end
local cm={}
local function F(v,yaw) return setmetatable({Position=v or V(),yaw=yaw or 0},cm) end
cm.__index=function(s,k) if k=='Rotation' then return F(V(),s.yaw) end return cm[k] end
cm.__mul=function(a,b) return F(V(a.Position.X+b.Position.X,a.Position.Y+b.Position.Y,a.Position.Z+b.Position.Z),a.yaw+b.yaw) end
function cm:ToObjectSpace(b) return F(V(b.Position.X-self.Position.X,b.Position.Y-self.Position.Y,b.Position.Z-self.Position.Z),b.yaw-self.yaw) end
local CFrame={new=function(v) return F(v) end,Angles=function(_,yaw,_) return F(V(),yaw) end}
local objects={}
local methods={}
local mt={__index=function(s,k)
 if k=='Parent' then return s.data.Parent end
 local found=methods[k] or s.data[k]
 if found~=nil then return found end
 return methods.FindFirstChild(s,k)
end,__newindex=function(s,k,v) s.data[k]=v end}
local function obj(kind,name,parent)
 local o=setmetatable({data={ClassName=kind,Name=name,Parent=parent,attrs={},CFrame=F(),Size=V(1,2.5,1)}},mt)
 table.insert(objects,o) return o
end
function methods:IsA(k) return self.ClassName==k or k=='BasePart' and (self.ClassName=='Part' or self.ClassName=='MeshPart') end
function methods:GetChildren() local out={} for _,o in ipairs(objects) do if o.Parent==self then table.insert(out,o) end end return out end
function methods:GetDescendants() local out={} for _,o in ipairs(self:GetChildren()) do table.insert(out,o) for _,v in ipairs(o:GetDescendants()) do table.insert(out,v) end end return out end
function methods:FindFirstChild(k,recursive) for _,o in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do if o.Name==k then return o end end end
function methods:FindFirstChildOfClass(k) for _,o in ipairs(self:GetChildren()) do if o.ClassName==k then return o end end end
function methods:FindFirstChildWhichIsA(k,recursive) for _,o in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do if o:IsA(k) then return o end end end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:SetAttribute(k,v) self.attrs[k]=v end
function methods:Destroy() self.Parent=nil end
function methods:Clone()
 local map={}
 local function cp(s)
  local c=obj(s.ClassName,s.Name);map[s]=c
  for k,v in pairs(s.data) do if k~='attrs' and k~='Parent' and k~='PrimaryPart' then c[k]=v end end
  for k,v in pairs(s.attrs) do c.attrs[k]=v end
  for _,child in ipairs(s:GetChildren()) do cp(child).Parent=c end
  if s.PrimaryPart then c.PrimaryPart=map[s.PrimaryPart] end
  return c
 end
 return cp(self)
end
local Instance={new=function(kind) return obj(kind,kind) end}
local workspace=obj('Workspace','Workspace')
local rs=obj('Folder','ReplicatedStorage') local ss=obj('Folder','ServerStorage')
local package=obj('Folder','RodeoFantasy',rs)
local airport=obj('Folder','Airport',obj('Folder','RodeoLobby',workspace))
local departure=obj('Part','Departure',airport)
local area=obj('Folder','BoardingArea',airport)
for i=1,4 do obj('Part','Cable',area) end
local function template(name,parent)
 local t=obj('Model',name,parent);t.PrimaryPart=obj('Part','Root',t)
 local b=obj('MeshPart','Body',t);b.CFrame=F(V(0,-.8,0),.2)
 local surface=obj('SurfaceAppearance','SurfaceAppearance',b)
 surface.ColorMap='ApprovedColor'..name;surface.TexturePack='ApprovedPack'..name
 return t
end
local oldHunt=template('MeshyMossratHuntTemplate',package)
local oldDetail=template('VisualTemplate',package) local oldServer=template('RodeoMonsterTemplate',ss)
local oldShip=obj('Model','Airship',airport);obj('MeshPart','MeshyAirshipBody',oldShip)
local roots={}
for i,name in ipairs({'RecoveryMossratHunt','RecoveryMossratDetail','RecoveryAirship'}) do
 local root=obj('Model',name,workspace);roots[i]=root
 local mesh=obj('MeshPart',({'Mossrat_S1_Hunt_HeadStraight','Mossrat_S1_Detail_HeadStraight','LobbyAirship_Recovery'})[i],root);mesh.MeshId='Mesh'..i
 local appearance=obj('SurfaceAppearance','SurfaceAppearance',mesh)
 appearance.ColorMap='Color'..i;appearance.MetalnessMap='';appearance.RoughnessMap='';appearance.NormalMap=''
 if i<3 then for _,bone in ipairs({'MossLeftFrontLeg','MossLeftBackLeg','MossRightFrontLeg','MossRightBackLeg'}) do obj('Bone',bone,mesh) end end
end
local selected={departure}
local selection={Get=function() return selected end,Set=function(_,v) selected=v end}
local Enum={AssetFetchStatus={Success='Success'}}
local game={ReplicatedStorage=rs,GetService=function(_,k) return ({ServerStorage=ss,RunService={IsRunning=function() return false end},Selection=selection,
 ContentProvider={PreloadAsync=function(_,ids,cb)
  assert(ids[1]:sub(1,4)=='Mesh','must not gate PBR on individual image preloading')
  cb(ids[1],failMesh and ids[1]=='Mesh1' and 'Failure' or 'Success')
 end}})[k] end}
obj('ModuleScript','MeshyMossratInstaller',package);obj('ModuleScript','MeshyAirshipInstaller',package)
local require=function(m)
 if m.Name=='MeshyMossratInstaller' then return {install=function(h,d,forward)
  assert(forward=='-Z')
  for _,entry in ipairs({{package,'MeshyMossratHuntTemplate',h},{package,'VisualTemplate',d},{ss,'RodeoMonsterTemplate',h}}) do
   local parent,name,source=unpack(entry);local old=parent:FindFirstChild(name);old:Destroy()
   local t=template(name,parent);local body=t.Body;body:Destroy();body=source:Clone();body.Name='Body';body.CFrame=F(V(0,-.8,0));body.Parent=t
  end
 end} end
 assert(m.Name=='MeshyAirshipInstaller')
 return {installSelected=function(forward)
  assert(forward=='-Z' and selected[1].Name=='LobbyAirship_Recovery')
  if failInstall then error('simulated airship failure') end
  oldShip.Parent=ss
  local ship=obj('Model','Airship',airport);obj('MeshPart','MeshyAirshipBody',ship)
 end}
end
local print=function() end local warn=function() end
local installer=(function()
__INSTALLER__
end)()
local ok,result=pcall(installer.install)
assert(selected[1]==departure and airport.Departure==departure,'selection and E departure preserved')
if failMesh then
 assert(not ok and package.MeshyMossratHuntTemplate==oldHunt and airport.Airship==oldShip,'mesh failure must leave old models intact')
elseif failInstall then
 assert(not ok and package.MeshyMossratHuntTemplate:GetAttribute('HeadShapeStraightened')==nil,'failed ship install must roll back head templates')
 assert(airport.Airship==oldShip,'unchanged ship stays in place on install failure')
else
 assert(ok and result==true)
 assert(package.MeshyMossratHuntTemplate:GetAttribute('HeadShapeStraightened'))
 assert(package.MeshyMossratHuntTemplate:GetAttribute('FaceCourseForward')==false)
 assert(package.MeshyMossratHuntTemplate:GetAttribute('MeshyVisualYawDegrees')==180)
 assert(math.abs(package.MeshyMossratHuntTemplate.Body.CFrame.yaw-.2)<1e-6)
 assert(package.VisualTemplate:GetAttribute('MeshyVisualYawDegrees')==0)
 local appearance=package.MeshyMossratHuntTemplate.Body:FindFirstChildOfClass('SurfaceAppearance')
 assert(appearance.ColorMap=='ApprovedColorMeshyMossratHuntTemplate' and appearance.TexturePack=='ApprovedPackMeshyMossratHuntTemplate','retain previously displayed PBR pack')
 assert(package.VisualTemplate.Body:FindFirstChildOfClass('SurfaceAppearance').TexturePack=='ApprovedPackVisualTemplate','detail retains its own pack')
 assert(airport.Airship~=oldShip and airport.Airship:GetAttribute('RecoveryPBRPreserved'))
 assert(not airport.Airship:GetAttribute('RecoveryTexturesChecked'),'do not claim texture render success from preload')
end
end
scenario(false,false,false);scenario(true,false,false);scenario(false,true,false);scenario(false,false,true)
print('BATCH_INSTALLER_PASS: PBR-pack reuse, mesh-only preload, geometry failure, rollback; E departure/selection preserved; color success not falsely claimed')
'''
code=code.replace('__INSTALLER__',(R/'src/authoring/ModelRecoveryInstaller.luau').read_text(encoding='utf-8'))
p=R/'.tools/check_model_recovery_installer.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
