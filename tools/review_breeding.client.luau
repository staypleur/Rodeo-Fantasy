-- Local isolated review: no production scripts, remotes, or DataStore access.
local player=game.Players.LocalPlayer
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
P:SetAttribute("BreedingBackgroundImage","rbxassetid://112011601018432")
for stage,id in pairs({[1]=109234225323915,[3]=86751563747627,[6]=75209703574739,[9]=134420784707320}) do P:SetAttribute("BrambleboarPortraitS"..stage,"rbxassetid://"..id) end
local gui=Instance.new("ScreenGui") gui.Name="BreedingReview" gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
local notice=Instance.new("TextLabel") notice.Name="ReviewStatus" notice.Size=UDim2.new(1,0,0,36) notice.BackgroundColor3=Color3.fromRGB(12,15,28) notice.TextColor3=Color3.new(1,1,1) notice.TextSize=16 notice.ZIndex=200 notice.Parent=gui
local items={}
for i=1,23 do table.insert(items,{id=i,monsterId=i%2==0 and "GrassBoar" or "MeadowMouse",stars=({1,3,6,9})[(i-1)%4+1],sex=i%2==0 and "Male" or "Female",tradeLock=i==23}) end
local event=Instance.new("BindableEvent") local remote={OnClientEvent=event.Event}
local rules=require(P.SocialRules)
function remote:FireServer(action,value)
 if action=="Breed" then
  local ok,message=rules.pair({monsters=items},value)
  notice.Text="SERVER RULES: "..tostring(ok).." | "..message
  print("BREEDING_REVIEW_PAIR",ok,value[1],value[2],message)
 elseif action=="Bag" then event:Fire("Bag",items) end
end
local ui=require(script.Parent:WaitForChild("BreedingUI")).new(gui,remote,function() return items end,function(message) notice.Text=message print("BREEDING_REVIEW_NOTICE",message) end)
ui.open()
local reopen=Instance.new("TextButton") reopen.Text="Open Breeding" reopen.Size=UDim2.fromOffset(130,36) reopen.Position=UDim2.fromOffset(0,36) reopen.ZIndex=200 reopen.Parent=gui
reopen.Activated:Connect(ui.open)
task.delay(10,function()
 local root=gui.BreedingOverlay local a=root.Background
 print("BREEDING_REVIEW_LOADED",a.IsLoaded,a.Image,gui.AbsoluteSize,root.AbsoluteSize,root.UIScale.Scale)
 notice.Text="UI review | artwork loaded: "..tostring(a.IsLoaded).." | 23 test monsters | no saved data"
end)
