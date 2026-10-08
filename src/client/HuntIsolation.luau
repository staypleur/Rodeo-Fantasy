-- The lobby remains social; run geometry, creatures and collisions belong to one player.
local I={}
local watched=setmetatable({},{__mode="k"})
local avatars=setmetatable({},{__mode="k"})
function I.update(player,hunting)
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
end
return I
