-- Eight automatic door pairs. Inventory permissions stay in LobbyWorld.
local model=script.Parent
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local doors={}
for slot=1,8 do
 local room=model.Plots:WaitForChild("Plot_"..slot)
 local left,right,sensor=room:FindFirstChild("DoorLeft"),room:FindFirstChild("DoorRight"),room:FindFirstChild("DoorSensor")
 if left and right and sensor then
 left.CanCollide=false right.CanCollide=false
 table.insert(doors,{left=left,right=right,sensor=sensor,lc=left.CFrame,rc=right.CFrame,open=false,tweens={}})
 end
end
if #doors==0 then return end
local elapsed=0
local connection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<.2 then return end elapsed=0
 local roots={}
 for _,player in ipairs(Players:GetPlayers()) do
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if root and h and h.Health>0 then table.insert(roots,root.Position) end
 end
 for _,door in ipairs(doors) do
  local near=false
  for _,pos in ipairs(roots) do if (pos-door.sensor.Position).Magnitude<=(door.open and 20 or 16) then near=true break end end
  if near~=door.open then
   door.open=near
   for _,t in ipairs(door.tweens) do t:Cancel() end door.tweens={}
   for _,item in ipairs({{door.left,door.lc,-door.left.Size.X},{door.right,door.rc,door.right.Size.X}}) do
    local t=Tween:Create(item[1],TweenInfo.new(.35),{CFrame=item[2]*CFrame.new(near and item[3] or 0,0,0)})
    table.insert(door.tweens,t) t:Play()
   end
  end
 end
end)
model.Destroying:Connect(function() connection:Disconnect() for _,d in ipairs(doors) do for _,t in ipairs(d.tweens) do t:Cancel() end end end)
