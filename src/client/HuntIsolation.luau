-- The lobby remains social; run geometry, creatures and collisions belong to one player.
local I={}
local watched=setmetatable({},{__mode="k"})
local avatars=setmetatable({},{__mode="k"})
local ownNameplates=setmetatable({},{__mode="k"})
local screenPlates={}
local overlay
-- Pure projection helper: the complete avatar bounds, including accessories,
-- must end below the plaque. World-space offsets cannot ensure that at every angle.
function I.screenPosition(camera,frame,size,width,height)
 local center,onScreen=camera:WorldToViewportPoint(frame.Position)
 if not onScreen or center.Z<=0 then return nil end
 local top=math.huge
 for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
  local point=camera:WorldToViewportPoint(frame:PointToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
  if point.Z<=0 then return nil end
  top=math.min(top,point.Y)
 end end end
 local viewport=camera.ViewportSize
 -- Hide at the screen edge rather than overlapping the avatar to fit the plaque.
 if top-10-height<0 or width>viewport.X then return nil end
 return Vector2.new(math.clamp(center.X,width/2,viewport.X-width/2),top-10)
end
local function updateScreenPlates(player,hunting)
 local camera=workspace.CurrentCamera
 if not camera then return end
 if not overlay then
  overlay=Instance.new("ScreenGui") overlay.Name="RodeoNameplatesV3"
  overlay.IgnoreGuiInset=true overlay.ResetOnSpawn=false overlay.DisplayOrder=5
  overlay.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
  overlay.Parent=player:FindFirstChildOfClass("PlayerGui")
  if not overlay.Parent then overlay:Destroy() overlay=nil return end
 end
 local current={}
 for _,other in ipairs(game:GetService("Players"):GetPlayers()) do
  local character=other.Character
  local head=character and character:FindFirstChild("Head")
  local source=head and head:FindFirstChild("ExplorerNameplate")
  local canvas=source and source:FindFirstChild("PlaqueCanvas")
  if canvas and canvas:FindFirstChild("Level") and canvas:FindFirstChild("PlayerName") and canvas:FindFirstChild("CompactPlaqueScale") then
   current[source]=true
   canvas.Visible=false -- Keep replicated content, but never render its 3D billboard.
   local key=tostring(source:GetAttribute("ThemeTier"))..":"..tostring(source:GetAttribute("LayoutWidth"))..":"..tostring(source:GetAttribute("LevelWidth"))
   local record=screenPlates[source]
   if not record or record.key~=key or record.sourceCanvas~=canvas then
    if record then record.host:Destroy() end
    local host=Instance.new("Frame") host.Name="Player_"..other.UserId
    host.BackgroundTransparency=1 host.AnchorPoint=Vector2.new(.5,1)
    host.Size=source.Size host.Parent=overlay
    local copy=canvas:Clone() copy.Visible=true
    copy.AnchorPoint=Vector2.zero copy.Position=UDim2.fromOffset(0,0) copy.Parent=host
    record={host=host,canvas=copy,key=key,sourceCanvas=canvas} screenPlates[source]=record
   end
   record.canvas.Level.Text=canvas.Level.Text
   record.canvas.PlayerName.Text=canvas.PlayerName.Text
   local humanoid=character:FindFirstChildOfClass("Humanoid")
   local visible=not hunting and source.Enabled and humanoid and humanoid.Health>0
    and head.Transparency<1 and head.LocalTransparencyModifier<1
    and (camera.CFrame.Position-head.Position).Magnitude<=source.MaxDistance
   local position
   if visible then
    local frame,size=character:GetBoundingBox()
    position=I.screenPosition(camera,frame,size,source.Size.X.Offset,source.Size.Y.Offset)
   end
   record.host.Visible=position~=nil
   if position then record.host.Position=UDim2.fromOffset(position.X,position.Y) end
  end
 end
 for source,record in pairs(screenPlates) do
  if not current[source] then record.host:Destroy() screenPlates[source]=nil end
 end
end
function I.update(player,hunting)
 local character=player.Character
 if character then
  for _,node in ipairs(character:GetDescendants()) do
   if node:IsA("BillboardGui") and node.Name=="ExplorerNameplate" then
    if ownNameplates[node]==nil then ownNameplates[node]=node.Enabled end
    node.Enabled=not hunting and ownNameplates[node]
   end
  end
 end
 local runs=workspace:FindFirstChild("PrivateHunts")
 if runs then for _,folder in ipairs(runs:GetChildren()) do
  if not watched[folder] then
   watched[folder]=true
   local function filter(part)
    if part:IsA("BasePart") and folder.Name~=tostring(player.UserId) then part.LocalTransparencyModifier=1
    elseif part:IsA("BillboardGui") and folder.Name~=tostring(player.UserId) then part.Enabled=false end
   end
   for _,part in ipairs(folder:GetDescendants()) do filter(part) end
   folder.DescendantAdded:Connect(filter)
  end
 end end
 for _,other in ipairs(game:GetService("Players"):GetPlayers()) do
  if other~=player and other.Character then
   local character=other.Character
   local record=avatars[character]
   if not record then record={parts={},labels={}} avatars[character]=record end
   for _,part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") then
     if record.parts[part]==nil then record.parts[part]=part.LocalTransparencyModifier end
     part.LocalTransparencyModifier=hunting and 1 or record.parts[part]
    elseif part:IsA("BillboardGui") then
     if record.labels[part]==nil then record.labels[part]=part.Enabled end
     part.Enabled=not hunting and record.labels[part]
    end
   end
  end
 end
 updateScreenPlates(player,hunting)
end
return I
