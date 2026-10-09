-- Run in Studio edit mode once after importing the approved saved whale meshes.
local M={}
local data=require(script.Parent.SkyWhaleInstallData)
function M.install(source)
 assert(not game:GetService("RunService"):IsRunning(),"Stop the play test before installing the whale.")
 if not source then source=workspace:FindFirstChild("SkyWhale_BodyReview") end
 assert(source and source:IsA("Model"),"Select the imported SkyWhale_BodyReview MODEL in Explorer first.")
 local airport=workspace.RodeoLobby.Airport
 assert(not source:IsDescendantOf(airport),"Select the newly imported model, not the current airship.")
 local old=airport:FindFirstChild("Airship")
 assert(old,"Current Airship missing; no changes made.")
 local byName={};local count=0
 for _,part in ipairs(source:GetDescendants()) do
  assert(not part:IsA("LuaSourceContainer"),"Imported model contains a script; no changes made.")
  if part:IsA("BasePart") then
   assert(part:IsA("MeshPart"),"Expected imported MeshParts only.")
   local key
   for _,expected in ipairs(data.Names) do
    if part.Name:find(expected,1,true) then assert(not key,"Ambiguous mesh name: "..part.Name) key=expected end
   end
   assert(key and not byName[key],"Unexpected/duplicate mesh: "..part.Name..". Disable Merge Meshes and import all objects.")
   local surface=part:FindFirstChildWhichIsA("SurfaceAppearance")
   assert(part.TextureID~="" or (surface and surface.ColorMap~=""),"Missing color texture: "..part.Name..". Complete texture upload before installing.")
   byName[key]=part count+=1
  end
 end
 assert(count==#data.Names,"Expected all 18 whale meshes; current airship unchanged.")
 local clone=source:Clone()
 assert(clone,"Imported model is not Archivable.")
 local ok,err=pcall(function()
  clone.PrimaryPart=nil
  local _,size=clone:GetBoundingBox()
  assert(size.Z>0,"Invalid imported bounds.")
  clone:ScaleTo(clone:GetScale()*data.Length/size.Z)
  local box=clone:GetBoundingBox()
  clone:PivotTo(CFrame.new(6000,55,-5)*box:Inverse()*clone:GetPivot())
  clone.Name="Airship" clone:SetAttribute("SkyWhaleRevision",data.Revision)
  for _,part in ipairs(clone:GetDescendants()) do
   if part:IsA("MeshPart") then
    for _,expected in ipairs(data.Names) do if part.Name:find(expected,1,true) then part.Name=expected break end end
    part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
    part.Color=Color3.new(1,1,1) part.DoubleSided=false
    part:SetAttribute("WhaleRest",part.CFrame)
    local group=data.Groups[part.Name]
    if group then
     part:SetAttribute("WhaleMotionGroup",group)
     local h=data.Hinges[group]
     part:SetAttribute("WhaleHinge",CFrame.new(h[1],h[2],h[3]))
    end
   end
  end
 end)
 if not ok then clone:Destroy() error(err) end
 -- Validate all cable targets before replacing the old visual.
 local changes={}
 for _,part in ipairs(airport.BoardingArea:GetChildren()) do
  if part:IsA("BasePart") and part.Name=="Cable" then
   local found
   for _,c in ipairs(data.Cables) do
    if math.abs(part.Position.X-c[1])<.01 and math.abs(part.Position.Z-c[2])<.01 then found=c break end
   end
   if not found then clone:Destroy() error("Cable layout differs; current airship unchanged.") end
   changes[#changes+1]={part=part,c=found}
  end
 end
 if #changes~=4 then clone:Destroy() error("Expected four boarding cables; current airship unchanged.") end
 local archive=Instance.new("Folder") archive.Name="SkyWhaleBackup"
 archive.Parent=game:GetService("ServerStorage")
 old.Parent=archive
 clone.Parent=airport
 for _,v in ipairs(changes) do
  local part,c=v.part,v.c
  part.Size=Vector3.new(part.Size.X,c[3]-c[4],part.Size.Z)
  part.CFrame=CFrame.new(c[1],(c[3]+c[4])/2,c[2])
 end
 source.Parent=archive
 print("SKY_WHALE_INSTALLED: 18 saved meshes, colored texture, fins/tail motion, four cables. Press Ctrl+S, then F5.")
 return clone
end
return M
