"""Execute the real mesh factory/apply path with API stubs; not engine rendering."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
prefix='''local data=(function()\n'''+(R/'src/client/FacetedMouseData.luau').read_text(encoding='utf-8')+'''\nend)()
local function client(fail)
 local vec={}
 local function V(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end
 vec.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
 vec.__mul=function(a,b) return V(a.X*b,a.Y*b,a.Z*b) end
 local Vector3={new=V} local Vector2={new=function(x,y) return {X=x,Y=y} end,zero={X=0,Y=0}}
 local cf={}
 local function F(x,y,z) if type(x)=='table' then return setmetatable({Position=x},cf) else return setmetatable({Position=V(x or 0,y or 0,z or 0)},cf) end end
 cf.__mul=function(a,b) return F(a.Position+b.Position) end
 local CFrame={new=F} local Color3={new=function(...) return {...} end}
 local Content={fromObject=function(obj) return obj end}
 local Enum={CollisionFidelity={Box=1},RenderFidelity={Precise=1}}
 local objects={} local meshes={} local triangles=0 local written
 local function object(kind)
  local o={ClassName=kind,attrs={}}
  function o:IsA(k) return k==self.ClassName or (k=='BasePart' and (kind=='Part' or kind=='MeshPart')) end
  function o:GetChildren() local list={} for _,item in ipairs(objects) do if item.Parent==self then list[#list+1]=item end end return list end
  function o:GetAttribute(k) return self.attrs[k] end
  function o:SetAttribute(k,v) self.attrs[k]=v end
  function o:Destroy() for _,child in ipairs(self:GetChildren()) do child:Destroy() end self.Parent=nil self.destroyed=true end
  function o:Clone()
   local copy=object(kind)
   for k,v in pairs(self) do if type(v)~='function' and k~='Parent' and k~='attrs' then copy[k]=v end end
   for _,child in ipairs(self:GetChildren()) do child:Clone().Parent=copy end
   return copy
  end
  objects[#objects+1]=o return o
 end
 local Asset={}
 function Asset:CreateEditableImage(options)
  local o=object('EditableImage')
  function o:WritePixelsBuffer(origin,size,pixels)
   assert(size.X==1024 and size.Y==1024 and buffer.len(pixels)==4194304)
   written=pixels
  end
  return o
 end
 function Asset:CreateSurfaceAppearanceAsync(content) assert(written and content.ColorMap.ClassName=='EditableImage') return object('SurfaceAppearance') end
 function Asset:CreateEditableMesh()
  if fail and #meshes==2 then error('simulated denied mesh budget') end
  local m=object('EditableMesh');m.vertices={} m.normals={} m.uvs={}
  function m:AddVertex(p) self.vertices[#self.vertices+1]=p return #self.vertices end
  function m:AddNormal(n) self.normals[#self.normals+1]=n return #self.normals end
  function m:AddUV(uv) self.uvs[#self.uvs+1]=uv return #self.uvs end
  function m:AddTriangle(a,b,c) triangles+=1 return triangles end
  function m:SetFaceNormals(face,ids) assert(ids[1]==ids[2] and ids[2]==ids[3],'must stay flat shaded') end
  function m:SetFaceUVs(face,ids) assert(#ids==3 and self.uvs[ids[3]]) end
  meshes[#meshes+1]=m return m
 end
 function Asset:CreateMeshPartAsync(mesh)
  local p=object('MeshPart') local low=V(math.huge,math.huge,math.huge) local high=V(-math.huge,-math.huge,-math.huge)
  for _,v in ipairs(mesh.vertices) do for _,a in ipairs({'X','Y','Z'}) do low[a]=math.min(low[a],v[a]) high[a]=math.max(high[a],v[a]) end end
  p.Size=V(high.X-low.X,high.Y-low.Y,high.Z-low.Z) return p
 end
 local catalog={MeadowMouse={RootHeight=2.05},stage=function(stars) return stars>=3 and 3 or 1 end,scale=function(stars) return stars==2 and 1.2 or 1 end}
 local package={MonsterCatalog='catalog'} local script={Parent={FacetedMouseData='data'}}
 local game={ReplicatedStorage={RodeoFantasy=package},GetService=function() return Asset end}
 local require=function(which) return which=='data' and data or catalog end
 local task={wait=function() error('unexpected concurrent wait') end} local warn=function() end
 local module=(function()\n'''
source=(R/'src/client/FacetedMouse.luau').read_text(encoding='utf-8')
suffix='''\nend)()
 local function model(stars,silhouette)
  local m=object('Model');m.Parent={} m:SetAttribute('MonsterId','MeadowMouse') m:SetAttribute('Stars',stars)
  m:SetAttribute('PortraitSilhouette',silhouette)
  local root=object('Part');root.Name='MountRoot' root.CFrame=F(0,2.05,0) root.Parent=m m.PrimaryPart=root
  local old=object('Part');old.Name='Body' old.Parent=m
  return m,old
 end
 return module,model,objects,function() return triangles,written end
end
local m,new,objects,metrics=client(false)
local animal,old=new(1,false)
assert(m.apply(animal) and old.destroyed and animal.PrimaryPart.Parent==animal)
assert(animal:GetAttribute('FacetedMouseRevision')=='FacetedA1-v1')
assert(not m.apply(animal),'same model must not install twice')
local tri,pixels=metrics() assert(tri==747)
local count=0
for _,p in ipairs(animal:GetChildren()) do if p.ClassName=='MeshPart' then
 count+=1 assert(not p.CanCollide and not p.CanTouch and not p.CanQuery)
 assert(#p:GetChildren()==1 and p:GetChildren()[1].ClassName=='SurfaceAppearance')
 if p.Name=='LeftFrontLeg' then assert(math.abs(p.CFrame.Position.Y-p.Size.Y/2)<.00001,'paws must meet ground') end
end end
assert(count==29)
local silhouette=new(1,true) assert(m.apply(silhouette))
for _,p in ipairs(silhouette:GetChildren()) do if p.ClassName=='MeshPart' then assert(#p:GetChildren()==0 and p.TextureID=='' and p.Color[1]==0) end end
assert(metrics()==747,'portraits must reuse the shared factory')
local second=new(2,false) assert(m.apply(second))
local third=new(3,false) assert(not m.apply(third),'unapproved growth stages must stay unchanged')
local failed,newFailed,all=client(true) local target,prior=newFailed(1,false)
assert(not failed.apply(target) and not prior.destroyed and target.PrimaryPart.Parent==target)
for _,obj in ipairs(all) do if obj.ClassName=='EditableMesh' or obj.ClassName=='EditableImage' or obj.ClassName=='SurfaceAppearance' or obj.ClassName=='MeshPart' then assert(obj.destroyed,'failed factory must free resources') end end
print('APPROVED_MOUSE_RUNTIME_PASS:747 faces/29 textured parts, cache reuse, grounded paws, silhouette, growth scope and atomic failure cleanup; API stubs only')
'''
harness=R/'.tools/approved_mouse_runtime.luau';harness.write_text(prefix+source+suffix,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(harness.relative_to(R))],cwd=R,check=True)
