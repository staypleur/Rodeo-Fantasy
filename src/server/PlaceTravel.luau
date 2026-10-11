local T={}
local Service=game:GetService("TeleportService")
local Store=require(script.Parent.InventoryStore)
local P=game.ReplicatedStorage.RodeoFantasy
local Config=require(P.SocialConfig)
local busy={}
function T.go(player,cafe)
 if busy[player] or Store.busy(player) then return end
 local id=cafe and Config.CafePlaceId or Config.LobbyPlaceId
 if id<=0 then P.CaptureRemote:FireClient(player,"SocialMessage","Cafe is being prepared.") return end
 if game:GetService("RunService"):IsStudio() then P.CaptureRemote:FireClient(player,"SocialMessage","Server travel is available in the published game.") return end
 busy[player]=true player:SetAttribute("Travelling",true)
 if not Store.save(player,true) then
  busy[player]=nil player:SetAttribute("Travelling",nil)
  P.CaptureRemote:FireClient(player,"SocialMessage","Could not save. Please try again.") return
 end
 local ok=pcall(function() Service:TeleportAsync(id,{player}) end)
 if not ok then player:Kick("Travel could not start. Your bag is saved. Please rejoin.") end
end
Service.TeleportInitFailed:Connect(function(player) if busy[player] then player:Kick("Travel failed. Your bag is saved. Please rejoin.") end end)
return T
