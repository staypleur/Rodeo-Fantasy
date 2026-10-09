"""Execute the real mesh factory/apply path with API stubs; not engine rendering."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
prefix='''local data=(function()\n'''+(R/'src/client/FacetedMouseData.luau').read_text(encoding='utf-8')+'''\nend)()
local function client(fail)
 local vec={}
 local function V(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end
 vec.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
 vec.__sub=function(a,b) return V(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
 vec.__mul=function(a,b) return V(a.X*b,a.Y*b,a.Z*b) end
 local Vector3={new=V} local Vector2={new=function(x,y) return {X=x,Y=y} end,zero={X=0,Y=0}}
 local cf={}
 local function F(x,y,z) if type(x)=='table' then return setmetatable({Position=x},cf) else return setmetatable({Position=V(x or 0,y or 0,z or 0)},cf) end end
 cf.__mul=function(a,b) return F(a.Position+b.Position) end
 cf.__index=cf
 function cf:ToObjectSpace(b) return F(b.Position.X-self.Position.X,b.Position.Y-self.Position.Y,b.Position.Z-self.Position.Z) end
 local CFrame={new=F} local Color3={new=function(...) return {...} end}
 local Content={fromObject=function(obj) return obj end}
 local Enum={CollisionFidelity={Box=1},RenderFidelity={Precise=1}}
 local objects={} local meshes={} local triangles=0 local written
 local dynamicLive,fixedCount=0,0
 local currentModel
 local function object(kind)
  local o=setmetatable({ClassName=kind,attrs={}},{__newindex=function(t,k,v)
   if kind=='MeshPart' and k=='RenderFidelity' then error("The current thread cannot write 'RenderFidelity' (lacking capability PluginOrOpenCloud)") end
   if kind=='MeshPart' and k=='TextureContent' then
    assert(written and v.ClassName=='EditableImage' and not v.destroyed)
    assert(not currentModel:GetAttribute('ApprovedVisualGuard'),'fallback must remain until every image binding succeeds')
    currentModel.PrimaryPart.CFrame=F(60,2.05,-120)
    if fail=='texture' then error('simulated direct image binding failure') end
   end
   rawset(t,k,v)
  end})
  function o:IsA(k) return k==self.ClassName or (k=='BasePart' and (kind=='Part' or kind=='MeshPart')) end
  function o:GetChildren() local list={} for _,item in ipairs(objects) do if item.Parent==self then list[#list+1]=item end end return list end
  function o:GetDescendants() local out={} for _,c in ipairs(self:GetChildren()) do out[#out+1]=c for _,d in ipairs(c:GetDescendants()) do out[#out+1]=d end end return out end
  function o:IsDescendantOf(parent) local n=self.Parent while n do if n==parent then return true end n=n.Parent end return false end
  function o:GetAttribute(k) return self.attrs[k] end
  function o:SetAttribute(k,v) self.attrs[k]=v end
  function o:Destroy()
   if self.destroyed then return end
   if self.dynamic then dynamicLive-=1 end
   for _,child in ipairs(self:GetChildren()) do child:Destroy() end self.Parent=nil self.destroyed=true
  end
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
 function Asset:CreateSurfaceAppearanceAsync(content)
  error('mouse must not allocate PBR surface packs per displayed part')
 end
 function Asset:CreateEditableMesh()
  assert(dynamicLive==0,'only one temporary dynamic mesh may be live')
  dynamicLive+=1
  local m=object('EditableMesh');m.vertices={} m.normals={} m.uvs={}
  m.dynamic=true
  function m:AddVertex(p) self.vertices[#self.vertices+1]=p return #self.vertices end
  function m:AddNormal(n) self.normals[#self.normals+1]=n return #self.normals end
  function m:AddUV(uv) self.uvs[#self.uvs+1]=uv return #self.uvs end
  function m:AddTriangle(a,b,c) triangles+=1 return triangles end
  function m:SetFaceNormals(face,ids) assert(ids[1]==ids[2] and ids[2]==ids[3],'must stay flat shaded') end
  function m:SetFaceUVs(face,ids) assert(#ids==3 and self.uvs[ids[3]]) end
  meshes[#meshes+1]=m return m
 end
 function Asset:CreateEditableMeshAsync(source,options)
  assert(options.FixedSize==true and source.dynamic and not source.destroyed)
  if fail==true and fixedCount==2 then error('simulated denied fixed mesh budget') end
  fixedCount+=1
  local fixed=object('EditableMesh');fixed.FixedSize=true
  fixed.vertices=table.clone(source.vertices) fixed.normals=table.clone(source.normals) fixed.uvs=table.clone(source.uvs)
  return fixed
 end
 function Asset:CreateMeshPartAsync(mesh,options)
  assert(mesh.FixedSize and dynamicLive==0,'display meshes must use compact fixed topology')
  assert(options.RenderFidelity==Enum.RenderFidelity.Precise,'fidelity must be set in creation options')
  local p=object('MeshPart') local low=V(math.huge,math.huge,math.huge) local high=V(-math.huge,-math.huge,-math.huge)
  for _,v in ipairs(mesh.vertices) do for _,a in ipairs({'X','Y','Z'}) do low[a]=math.min(low[a],v[a]) high[a]=math.max(high[a],v[a]) end end
  p.Size=V(high.X-low.X,high.Y-low.Y,high.Z-low.Z) return p
 end
 local catalog={MeadowMouse={RootHeight=2.05},stage=function(stars) return stars>=3 and 3 or 1 end,scale=function(stars) return stars==2 and 1.2 or 1 end}
 for _,star in ipairs({3,6,9}) do
  local back={[3]=2.212572,[6]=3.232653,[9]=6.561222}
  assert(math.abs(catalog.saddleHeight('MeadowMouse',star)+2.05*catalog.scale(star)-back[star]-1.36)<.00001,'seat must use back rather than crown height')
 end
 local package={MonsterCatalog='catalog'} local script={Parent={FacetedMouseData='data'}}
 local game={ReplicatedStorage={RodeoFantasy=package},GetService=function() return Asset end}
 local require=function(which) return which=='data' and data or catalog end
 local task={wait=function() error('unexpected concurrent wait') end,defer=function(fn) fn() end} local warn=function() end
 function script.Parent:WaitForChild(name) return self[name] end\n local module=(function()\n'''
source=(R/'src/client/FacetedMouse.luau').read_text(encoding='utf-8')
remember=(R/'src/client/RideAnimator.luau').read_text(encoding='utf-8').split('local function remember(model, existing)',1)[1].split('function RideAnimator.update',1)[0]
suffix='''\nend)()
 local Catalog=catalog local poses={}
 Catalog.visual=function() return 'visual' end
 function package:WaitForChild() return {WaitForChild=function() return {CFrame=F()} end} end
 local function remember(model, existing)'''+remember+'''
 local function model(stars,silhouette)
  local m=object('Model');m.DescendantAdded={callbacks={},Connect=function(self,fn) self.callbacks[#self.callbacks+1]=fn return {} end};m.Parent={} m:SetAttribute('MonsterId','MeadowMouse') m:SetAttribute('Stars',stars)
  m:SetAttribute('PortraitSilhouette',silhouette)
  local root=object('Part');root.Name='MountRoot' root.CFrame=F(0,2.05,0) root.Parent=m m.PrimaryPart=root
  local old=object('Part');old.Name='Body' old.Parent=m
  local nested=object('Model');nested.Parent=m local leftover=object('Part');leftover.Name='LegacyTail' leftover.Parent=nested
  currentModel=m
  return m,old
 end
 return module,model,objects,function() return triangles,written end,function(target) target.PrimaryPart.CFrame=F(50,10,-100) return remember(target) end,function(target) local p=object('Part') p.Parent=target for _,fn in ipairs(target.DescendantAdded.callbacks) do fn(p) end return p end
end
local m,new,objects,metrics,remember,late=client(false)
local animal,old=new(1,false)
assert(m.apply(animal) and old.destroyed and animal.PrimaryPart.Parent==animal)
assert(animal:GetAttribute('FacetedMouseRevision')=='Mossrat-Lineage-v1-S1')
assert(not m.apply(animal),'same model must not install twice')
local tri,pixels=metrics() assert(tri==747)
local fixedCount=0
for _,o in ipairs(objects) do if o.ClassName=='EditableMesh' then
 if o.dynamic then assert(o.destroyed,'temporary topology builder must be freed') else fixedCount+=1 assert(o.FixedSize and not o.destroyed) end
end end
assert(fixedCount==8)
local count=0
for _,p in ipairs(animal:GetChildren()) do if p.ClassName=='MeshPart' then
 count+=1 assert(not p.CanCollide and not p.CanTouch and not p.CanQuery)
 assert(p.CFrame.Position.X==animal.PrimaryPart.CFrame.Position.X+p:GetAttribute("ApprovedRest").Position.X,"all staged parts must use latest root after texture yields")
 assert(#p:GetChildren()==0 and p.TextureContent.ClassName=='EditableImage' and not p.TextureContent.destroyed)
 if p.Name=='LeftFrontLeg' then assert(math.abs(p.CFrame.Position.Y-p.Size.Y/2)<.00001,'paws must meet ground') end
end end
assert(count==8)
for _,p in ipairs(animal:GetDescendants()) do if p:IsA('BasePart') and p~=animal.PrimaryPart then assert(p:GetAttribute('ApprovedRest'),'nested original must be removed') end end
assert(late(animal).destroyed,'late server geometry must not reappear')
-- Root is moved in the injected callback, before the real animator remembers.
local pose=remember(animal)
for _,entry in ipairs(pose) do assert(entry.rest==entry.part:GetAttribute('ApprovedRest'),'animator must use canonical parts, not stale world positions') end
assert(#pose==8)
local silhouette=new(1,true) assert(m.apply(silhouette))
for _,p in ipairs(silhouette:GetChildren()) do if p.ClassName=='MeshPart' then assert(#p:GetChildren()==0 and p.TextureID=='' and p.Color[1]==0) end end
assert(metrics()==747,'portraits must reuse the shared factory')
local second=new(2,false) assert(m.apply(second))
for run=1,10 do
 local replay=new(1,false) assert(m.apply(replay))
 for _,part in ipairs(replay:GetChildren()) do if part.ClassName=='MeshPart' then
  assert(#part:GetChildren()==0 and part.TextureContent.ClassName=='EditableImage' and not part.TextureContent.destroyed,'every restarted run must directly bind the retained image')
 end end
 replay:Destroy()
end
assert(metrics()==747,'restarting must reuse meshes and image rather than allocate new geometry')
for _,stars in ipairs({3,6,9,4,7,10}) do
 local growth=new(stars,false) assert(m.apply(growth),'approved stages must install')
 local scales={[1]=1,[3]=1.4,[6]=1.9,[9]=2.5}
 local stage=stars>=9 and 9 or stars>=6 and 6 or 3
 local scale=stage==9 and 2.5+(stars-9)*.2 or scales[stage]+(scales[stage+3]-scales[stage])*(stars-stage)/3
 local legs=0 local top=-math.huge
 for _,part in ipairs(growth:GetChildren()) do if part.ClassName=='MeshPart' then
  assert(part:GetAttribute('ApprovedPivot'),'animation pivot must survive replacement')
  local rest=part:GetAttribute('ApprovedRest').Position
  top=math.max(top,rest.Y+part.Size.Y/2+2.05*scale)
  if part.Name:find('Leg') then
   legs+=1
   assert(math.abs(rest.Y-part.Size.Y/2+2.05*scale)<.00001,'growth feet must be grounded')
  end
 end end
 assert(legs==4,'four separately animated legs')
 local heights={[3]=4,[6]=6.62043285,[9]=16.1318016}
 assert(math.abs(top-heights[stage]*scale/scales[stage])<.0001,'growth must not scale twice')
 local black=new(stars,true) assert(m.apply(black))
 for _,part in ipairs(black:GetChildren()) do if part.ClassName=='MeshPart' then assert(part.Color[1]==0 and part.TextureID=='') end end
end
assert(metrics()==747+1075+1399+1671,'all stages must reuse factory')
local imageCount,meshCount=0,0
for _,obj in ipairs(objects) do
 if obj.ClassName=='EditableImage' then imageCount+=1 end
 if obj.ClassName=='EditableMesh' and not obj.dynamic then meshCount+=1 end
end
assert(imageCount==2 and meshCount==32,'two atlases/eight animation batches per stage')
local failed,newFailed,all=client(true) local target,prior=newFailed(1,false)
assert(not failed.apply(target) and not prior.destroyed and target.PrimaryPart.Parent==target)
for _,obj in ipairs(all) do if obj.ClassName=='EditableMesh' or obj.ClassName=='SurfaceAppearance' or obj.ClassName=='MeshPart' then assert(obj.destroyed,'failed factory must free mesh resources') end end
local surfaceFail,makeSurfaceFail=client('texture') local interrupted,previous=makeSurfaceFail(1,false)
assert(not surfaceFail.apply(interrupted) and not previous.destroyed,'surface error must preserve original visual')
assert(not interrupted:GetAttribute('FacetedMouseRevision'),'failed color binding must not mark installation complete')
print('APPROVED_MOUSE_RUNTIME_PASS: four stages, 32 fixed meshes/two atlases, four animated legs/ears/tail pivots, grounding/interpolated scale/silhouettes/replay/cache/failure fallback; API stubs only')
'''
prefix=prefix.replace("local catalog={MeadowMouse={RootHeight=2.05},stage=function(stars) return stars>=3 and 3 or 1 end,scale=function(stars) return stars==2 and 1.2 or 1 end}","local catalog=(function()\n"+(R/'src/shared/MonsterCatalog.luau').read_text(encoding='utf-8')+"\nend)()")
harness=R/'.tools/approved_mouse_runtime.luau';harness.write_text(prefix+source+suffix,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(harness.relative_to(R))],cwd=R,check=True)
