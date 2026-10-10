do
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local p=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"RodeoFantasy 시스템 없음")
game:GetService("ChangeHistoryService"):SetWaypoint("Before uploaded HUD images")
p:SetAttribute("ShopButtonImage","rbxassetid://135776139567636")
p:SetAttribute("RouletteButtonImage","rbxassetid://103655794024864")
p:SetAttribute("MoneyImage","rbxassetid://71604722538432")
p:SetAttribute("IndexButtonImage","rbxassetid://135277525783308")
p:SetAttribute("EggButtonImage","rbxassetid://87551432940862")
p:SetAttribute("PawButtonImage","rbxassetid://85966265063532")
p:SetAttribute("MossratFaceImage","rbxassetid://87383094549038")
game:GetService("ChangeHistoryService"):SetWaypoint("Uploaded HUD images configured")
print("HUD_IMAGES_CONFIGURED — 이미지 7개 연결. Ctrl+S 저장 후 Play로 확인하세요.")

end
