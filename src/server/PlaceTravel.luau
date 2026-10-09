local T={}
local Service=game:GetService("TeleportService")
local Store=require(script.Parent.InventoryStore)
local P=game.ReplicatedStorage.RodeoFantasy
local Config=require(P.SocialConfig)
local busy={}
function T.go(player,cafe)
 if busy[player] or Store.busy(player) then return end
 local id=cafe and Config.CafePlaceId or Config.LobbyPlaceId
 if id<=0 then P.CaptureRemote:FireClient(player,"SocialMessage","카페 Place 연결 준비 중입니다. 별도 카페 파일에서 먼저 확인할 수 있어요.") return end
 if game:GetService("RunService"):IsStudio() then P.CaptureRemote:FireClient(player,"SocialMessage","서버 이동은 게시 후 Roblox 앱에서 확인해주세요.") return end
 busy[player]=true player:SetAttribute("Travelling",true)
 if not Store.save(player,true) then busy[player]=nil return end
 local ok=pcall(function() Service:TeleportAsync(id,{player}) end)
 if not ok then player:Kick("이동을 시작하지 못했습니다. 가방은 저장되었으니 다시 접속해주세요.") end
end
Service.TeleportInitFailed:Connect(function(player) if busy[player] then player:Kick("이동에 실패했습니다. 가방은 저장되었으니 다시 접속해주세요.") end end)
return T
