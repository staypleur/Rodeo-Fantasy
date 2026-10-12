-- Play-only real companion API fixture. Inventory is isolated in this script.
local player=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local character=player.Character or player.CharacterAdded:Wait()
local root=character:WaitForChild("HumanoidRootPart")
task.wait(3)
local map=workspace:FindFirstChild("RodeoCafe") or workspace.RodeoLobby
local bag={monsters={}}
local api=require(game.ServerScriptService.LobbyCompanions).new({map=map,bag=function() return bag end,canAct=function() return true end,inLobby=function() return true end,canSummon=function() return true end})
local initial=root.CFrame
for _,id in ipairs({"MeadowMouse","GrassBoar"}) do
 for _,stage in ipairs({1,3,6,9}) do
  root.CFrame=initial
  bag.monsters={{id=900001,monsterId=id,stars=stage}}
  api.summon(player,900001)
  local pet=assert(map.LobbyCompanions:FindFirstChild("Companion_"..player.UserId),"Summon failed")
  root.CFrame=pet.PrimaryPart.CFrame*CFrame.new(0,2,2)
  if stage==1 then
   assert(api.bond(player,900001),"Bond rejected")
   assert(not api.ride(player,900001),"One-star ride accepted")
   task.wait(3.1)
  else
   assert(not api.bond(player,900001),"Mounted stage bond accepted")
   assert(api.ride(player,900001),"Ride rejected")
   local start=pet.PrimaryPart.Position
   local distance=0
   for i=1,80 do
    api.input(player,CFrame.Angles(0,i*math.pi*2/80,0).LookVector)
    task.wait(.05)
    assert(player:GetAttribute("LobbyRiding") and root.Anchored)
    assert(pet.PrimaryPart.CFrame.LookVector.Magnitude>.999)
    distance=math.max(distance,(pet.PrimaryPart.Position-start).Magnitude)
   end
   api.input(player,Vector3.zero) task.wait(.2)
   api.dismount(player)
   assert(not player:GetAttribute("LobbyRiding") and not root.Anchored)
   assert(distance>1,"Mount never moved")
  end
  print("SOCIAL_RIDING_API_PASS",game.PlaceId,id,stage)
  api.clear(player)
 end
end
root.CFrame=initial
print("SOCIAL_RIDING_ALL_PASS",game.PlaceId)
