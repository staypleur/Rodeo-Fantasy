"""Execute actual approved runtime with success/failure API stubs, not engine rendering."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
wrap=lambda p:'(function()\n'+(R/p).read_text(encoding='utf-8')+'\nend)()'
code='local data='+wrap('src/client/SkyWhaleData.luau')+r'''
local function trial(failure)
 local vec={}
 local function V(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end
 local Vector3={new=V} local Vector2={new=V,zero=V(0,0,0)}
 local CFrame={new=function(x,y,z) return {Position=V(x,y,z)} end}
 local Color3={new=function(...) return {...} end}
 local Content={fromObject=function(o) return o end}
 local Enum={CollisionFidelity={Box=1},RenderFidelity={Precise=1}}
 local objects={} local triangles=0 local dynamic=0 local fixedCount=0 local surfaceCount=0
 local function object(kind)
  local o={ClassName=kind,attrs={}}
  function o:IsA(k) return k==kind or (k=='BasePart' and (kind=='Part' or kind=='MeshPart')) end
  function o:GetAttribute(k) return self.attrs[k] end
  function o:SetAttribute(k,v) self.attrs[k]=v end
  function o:GetChildren() local result={} for _,v in ipairs(objects) do if v.Parent==self then result[#result+1]=v end end return result end
  function o:GetDescendants() local result={} for _,v in ipairs(self:GetChildren()) do result[#result+1]=v for _,q in ipairs(v:GetDescendants()) do result[#result+1]=q end end return result end
  function o:Destroy() if self.destroyed then return end if self.dynamic then dynamic-=1 end for _,c in ipairs(self:GetChildren()) do c:Destroy() end self.Parent=nil self.destroyed=true end
  objects[#objects+1]=o return o
 end
 local asset={}
 function asset:CreateEditableImage(options)
  assert(options.Size.X==512 and options.Size.Y==512)
  local image=object('EditableImage')
  function image:WritePixelsBuffer(_,size,pixels) assert(size.X==512 and buffer.len(pixels)==1048576) end
  return image
 end
 function asset:CreateEditableMesh()
  assert(dynamic==0,'only one temporary builder at a time') dynamic+=1
  local m=object('EditableMesh') m.dynamic=true m.vertices={} m.uvs={} m.normals={}
  function m:AddVertex(v) self.vertices[#self.vertices+1]=v return #self.vertices end
  function m:AddNormal(v) self.normals[#self.normals+1]=v return #self.normals end
  function m:AddUV(v) self.uvs[#self.uvs+1]=v return #self.uvs end
  function m:AddTriangle() triangles+=1 return triangles end
  function m:SetFaceNormals(_,ids) assert(ids[1]==ids[2] and ids[2]==ids[3]) end
  function m:SetFaceUVs(_,ids) assert(self.uvs[ids[3]]) end
  return m
 end
 function asset:CreateEditableMeshAsync(builder,options)
  assert(options.FixedSize and builder.dynamic and not builder.destroyed)
  if failure=='mesh' and fixedCount==2 then error('test mesh budget failure') end
  fixedCount+=1 local fixed=object('EditableMesh') fixed.fixed=true return fixed
 end
 function asset:CreateMeshPartAsync(mesh,options)
  assert(mesh.fixed and dynamic==0 and options.RenderFidelity==1)
  local part=object('MeshPart') return part
 end
 function asset:CreateSurfaceAppearanceAsync(maps)
  surfaceCount+=1
  if failure=='surface' and surfaceCount==3 then error('test texture failure') end
  assert(maps.ColorMap.ClassName=='EditableImage' and not maps.ColorMap.destroyed)
  return object('SurfaceAppearance')
 end
 local game={GetService=function() return asset end}
 local script={Parent={SkyWhaleData=data}} local require=function(x) return x end local warn=function() end
 function script.Parent:WaitForChild(name) return self[name] end
 local runtime='''+wrap('src/client/SkyWhaleRuntime.luau')+r'''
 local airport=object('Model') local area=object('Model') airport.BoardingArea=area
 local ship=object('Model') ship.Parent=airport
 local old=object('Part') old.Parent=ship
 for _,c in ipairs(data.Cables) do
  local p=object('Part') p.Name='Cable' p.Parent=area p.Position=V(c[1],20,c[2]) p.Size=V(.2,7,.2)
 end
 local result=runtime.install(ship)
 if failure then
  assert(not result and not old.destroyed and not ship:GetAttribute('SkyWhaleRevision'))
  for _,o in ipairs(objects) do if o.ClassName=='EditableMesh' or o.ClassName=='EditableImage' or o.ClassName=='SurfaceAppearance' or o.ClassName=='MeshPart' then assert(o.destroyed,'failure must free temporary resources') end end
 else
  assert(result and old.destroyed and triangles==988 and fixedCount==4 and surfaceCount==4)
  assert(ship:GetAttribute('SkyWhaleRevision')==data.Revision and ship:GetAttribute('WhaleAnchor').Position.Y==95)
  local count=0
  for _,part in ipairs(ship:GetChildren()) do if part.ClassName=='MeshPart' then
   count+=1 assert(not part.CanCollide and not part.CanQuery and part:GetAttribute('WhaleRest'))
   assert(#part:GetChildren()==1)
   if part.Name~='RegalWhaleBody' then assert(part:GetAttribute('WhaleHinge') and part:GetAttribute('WhaleMotionGroup')) end
  end end
  assert(count==4 and not runtime.install(ship) and triangles==988,'reentry must not allocate or install again')
  for i,c in ipairs(data.Cables) do local p=area:GetChildren()[i] assert(math.abs(p.Size.Y-(c[4]-c[3]))<1e-7) end
 end
 assert(dynamic==0)
end
trial(nil) trial('mesh') trial('surface')
print('REGAL_RUNTIME_PASS:988 faces/four fixed groups/shared512 image; texture/hinges/cables, idempotent install, allocation/texture failure preserves old ship and frees resources; API stubs only')
'''
p=R/'.tools/regal_whale_runtime_test.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
