local Players=game:GetService("Players")
local player=Players.LocalPlayer
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local remote=P:WaitForChild("CaptureRemote")
local gui=Instance.new("ScreenGui") gui.Name="CafeUI" gui.ResetOnSpawn=false gui.DisplayOrder=10 gui.Parent=player:WaitForChild("PlayerGui")
local bag=require(script.Parent:WaitForChild("BagUI")).new(gui,remote)
local journal=require(script.Parent:WaitForChild("JournalUI")).new(gui,remote)
local social=require(script.Parent:WaitForChild("SocialUI")).new(gui,remote,bag,journal)
local menus=require(script.Parent:WaitForChild("LobbyMenus")).new(gui,bag,journal,remote)
local stats=require(script.Parent:WaitForChild("HudStats")).new(gui)
local activities=require(script.Parent:WaitForChild("CafeActivityUI")).new(gui,function() bag.close() journal.close() social.close() menus.close() end)
require(script.Parent:WaitForChild("LocalizationController")).watch(gui)
require(script.Parent:WaitForChild("PetPromptUI")).new(gui,player)
bag.onOpen=function() activities.close() journal.close() social.close() menus.close() end
journal.onOpen=function() activities.close() bag.close() social.close() menus.close() end
menus.onOpen=function() activities.close() bag.close() journal.close() social.close() end
social.onOpen=function() activities.close() bag.close() journal.close() menus.close() end
remote.OnClientEvent:Connect(function(kind,data)
 if kind=="Bag" then bag.snapshot(data)
 elseif kind=="State" then bag.state(data) journal.state(data) social.state(data) menus.state(data) stats.state(data) bag.income(data.income)
 elseif kind=="EvolutionResult" then bag.evolutionResult(data)
 elseif kind=="Journal" then journal.snapshot(data)
 else social.event(kind,data) end
end)
local animator=require(script.Parent:WaitForChild("RideAnimator"))
game:GetService("RunService").RenderStepped:Connect(function(dt)
 local map=workspace:FindFirstChild("RodeoCafe")
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if map and workspace.CurrentCamera then animator.update(map,workspace:GetServerTimeNow(),root and root.Position,dt) end
end)
remote:FireServer("Sync")
