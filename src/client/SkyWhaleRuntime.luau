-- Build the approved whale once per client, using only four compact fixed meshes.
local M={}
local Asset=game:GetService("AssetService")
local data=require(script.Parent:WaitForChild("SkyWhaleData"))
local resources={} -- Keep EditableImage and fixed geometry alive across hunt restarts.
local busy=false
function M.install(ship)
 if busy or ship:GetAttribute("SkyWhaleRevision")==data.Revision then return false end
 busy=true
 local staged,owned={},{}
 local builder
 local function own(value) owned[#owned+1]=value return value end
 local ok,err=pcall(function()
  local cables={}
  for _,part in ipairs(ship.Parent.BoardingArea:GetChildren()) do
   if part:IsA("BasePart") and part.Name=="Cable" then
    for _,c in ipairs(data.Cables) do
     if math.abs(part.Position.X-c[1])<.01 and math.abs(part.Position.Z-c[2])<.01 then cables[#cables+1]={part=part,c=c} break end
    end
   end
  end
  assert(#cables==4,"Boarding cable layout differs")
  local image=own(assert(Asset:CreateEditableImage({Size=Vector2.new(data.ImageSize,data.ImageSize)}),"No whale image budget"))
  local pixels=buffer.create(data.ImageSize*data.ImageSize*4) local offset=0
  local encoded=data.ImageRLE:gsub("%s","")
  for i=1,#encoded,10 do
   local count=tonumber(encoded:sub(i,i+3),16)
   local color=tonumber(encoded:sub(i+4,i+5),16)+tonumber(encoded:sub(i+6,i+7),16)*256+tonumber(encoded:sub(i+8,i+9),16)*65536+255*16777216
   for _=1,count do buffer.writeu32(pixels,offset,color) offset+=4 end
  end
  assert(offset==buffer.len(pixels),"Incomplete whale texture")
  image:WritePixelsBuffer(Vector2.zero,Vector2.new(data.ImageSize,data.ImageSize),pixels)
  for _,entry in ipairs(data.Parts) do
   builder=assert(Asset:CreateEditableMesh(),"No whale builder budget")
   for i=1,#entry.Vertices,3 do
    local ids,uvs={},{} local v=entry.Vertices[i]
    local normal=builder:AddNormal(Vector3.new(v[4],v[5],v[6]))
    for j=i,i+2 do
     local p=entry.Vertices[j]
     ids[#ids+1]=builder:AddVertex(Vector3.new(p[1],p[2],p[3]))
     uvs[#uvs+1]=builder:AddUV(Vector2.new(p[7],p[8]))
    end
    local face=builder:AddTriangle(ids[1],ids[2],ids[3])
    builder:SetFaceNormals(face,{normal,normal,normal}) builder:SetFaceUVs(face,uvs)
   end
   local fixed=own(assert(Asset:CreateEditableMeshAsync(Content.fromObject(builder),{FixedSize=true}),"No whale fixed mesh budget"))
   builder:Destroy() builder=nil
   local part=own(Asset:CreateMeshPartAsync(Content.fromObject(fixed),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise}))
   part.Name="RegalWhale"..entry.Name part.Anchored=true part.Color=Color3.new(1,1,1)
   part.CanCollide,part.CanTouch,part.CanQuery=false,false,false
   part.CFrame=CFrame.new(unpack(entry.Center)) part:SetAttribute("WhaleRest",part.CFrame)
   if entry.Hinge then
    part:SetAttribute("WhaleMotionGroup",entry.Name) part:SetAttribute("WhaleHinge",CFrame.new(unpack(entry.Hinge)))
   end
   local surface=own(Asset:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(image)}))
   surface.Parent=part staged[#staged+1]=part
  end
  assert(ship.Parent,"Airship removed while preparing")
  -- All resource creation finishes before the existing airship is replaced.
  for _,part in ipairs(ship:GetDescendants()) do if part:IsA("BasePart") then part:Destroy() end end
  for _,part in ipairs(staged) do part.Parent=ship end
  for _,v in ipairs(cables) do
   local c=v.c v.part.Size=Vector3.new(.35,c[4]-c[3],.35)
   v.part.CFrame=CFrame.new(c[1],(c[3]+c[4])/2,c[2])
  end
  ship:SetAttribute("WhaleAnchor",CFrame.new(unpack(data.Anchor)))
  ship:SetAttribute("SkyWhaleRevision",data.Revision)
 end)
 busy=false
 if not ok then
  if builder then builder:Destroy() end
  for _,object in ipairs(owned) do object:Destroy() end
  warn("Approved sky whale could not load; previous airship retained: "..tostring(err))
  return false
 end
 resources=owned
 return true
end
return M
