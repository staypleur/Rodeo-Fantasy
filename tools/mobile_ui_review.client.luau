-- Isolated Studio review. Installer restores disabled scripts before publication.
local C=script.Parent
C:WaitForChild("BagUI") C:WaitForChild("LobbyMenus") C:WaitForChild("HudStats")
local gui=Instance.new('ScreenGui') gui.Name='MobileLayoutReview' gui.DisplayOrder=100 gui.Parent=game.Players.LocalPlayer.PlayerGui
local root=Instance.new('Frame') root.AnchorPoint=Vector2.new(.5,.5) root.Position=UDim2.fromScale(.5,.5) root.BackgroundColor3=Color3.fromRGB(30,40,50) root.Parent=gui
local remote={FireServer=function() end}
local items={} for i=1,12 do items[i]={id=tostring(i),monsterId='MeadowMouse',stars=1,sex='Male',incomeAmount=1,incomeSeconds=3} end
local function settle() for i=1,5 do game.RunService.RenderStepped:Wait() end end
for _,size in ipairs({Vector2.new(844,350),Vector2.new(740,310),Vector2.new(390,760),Vector2.new(1100,720)}) do
 root:ClearAllChildren() root.Size=UDim2.fromOffset(size.X,size.Y)
 local bag=require(C.BagUI).new(root,remote)
 require(C.BagUI).iconButton(root,'Journal','J',90)
 local menus=require(C.LobbyMenus).new(root,bag,{},remote)
 require(C.HudStats).new(root).state({count=12,gems=0,balance=4200})
 menus.state({area='Lobby',phase='Idle'}) bag.snapshot(items) bag.openCompanionMenu() settle()
 local window=root.BagWindow local cards=window.BagCards
 assert(cards.AbsoluteSize.Y>=100,'Card viewport too short '..tostring(size))
 assert(cards.AbsolutePosition.Y+cards.AbsoluteSize.Y<=window.AbsolutePosition.Y+window.AbsoluteSize.Y-30,'Footer overlap')
 assert(root.OpenJournal.AbsolutePosition.Y<root.OpenEgg.AbsolutePosition.Y,'Index must precede egg')
 assert(root.OpenCafe.AbsolutePosition.Y+root.OpenCafe.AbsoluteSize.Y<root.LobbyStats.AbsolutePosition.Y,'Cafe overlaps stats')
 cards.CanvasPosition=Vector2.new(0,80) settle() bag.snapshot(items) settle()
 assert(cards.CanvasPosition.Y>=79,'Snapshot reset scroll')
 bag.openRanchMenu() settle()
 local choice=window.RanchChooser
 assert(choice:IsA('ScrollingFrame') and choice.ScrollingEnabled,'Hatchery must scroll')
 for i=1,4 do local n=choice['RanchChoice'..i] assert(n.AbsolutePosition.Y+n.AbsoluteSize.Y<=choice.AbsolutePosition.Y+choice.AbsoluteSize.Y+1,'Hatchery clipped') end
 print('MOBILE_LAYOUT_PASS',size.X,size.Y,cards.AbsoluteSize.Y)
end
root:ClearAllChildren() root.Size=UDim2.fromOffset(844,350)
local bag=require(C.BagUI).new(root,remote)
require(C.BagUI).iconButton(root,'Journal','J',90)
local menus=require(C.LobbyMenus).new(root,bag,{},remote)
require(C.HudStats).new(root).state({count=12,gems=0,balance=4200}) menus.state({area='Lobby',phase='Idle'})
bag.snapshot(items) bag.openCompanionMenu()
game.UserInputService.InputBegan:Connect(function(input) if input.KeyCode==Enum.KeyCode.One then bag.openCompanionMenu() elseif input.KeyCode==Enum.KeyCode.Two then bag.openRanchMenu() elseif input.KeyCode==Enum.KeyCode.Three then bag.setEvolutionMode(true) end end)


