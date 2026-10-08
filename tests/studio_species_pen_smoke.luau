local package=game.ReplicatedStorage.RodeoFantasy
local Catalog=require(package.MonsterCatalog)
local rules=require(package.BagRules)
local Lobby=require(game.ServerScriptService.LobbyWorld)
local character=Instance.new("Model") character.Parent=workspace
local root=Instance.new("Part") root.Name="HumanoidRootPart" root.Parent=character
local player={Name="PenTest",UserId=910101,Character=character,SetAttribute=function() end}
assert(Lobby.assign(player)==1)
local bag=rules.new()
for _,id in ipairs({"MeadowMouse","Weedcrow","MeadowMouse"}) do
 local species=Catalog[id] rules.grant(bag,id,0,species.IncomeSeconds,species.IncomeAmount)
end
local pen=Lobby.getPen(player,1)
root.CFrame=workspace.RodeoLobby.Plots.Plot_1.ManagePoint.CFrame+Vector3.new(0,0,3)
assert(Lobby.canUsePen(player,1)) assert(not Lobby.canUsePen(player,5))
assert(rules.place(bag,1,1) and rules.place(bag,2,1)) assert(not rules.place(bag,3,1))
Lobby.display(player,1,bag.monsters)
assert(#pen.DisplayMonsters:GetChildren()==2)
local dustBefore=#workspace:GetChildren()
local lobbyAnimator=require(game.StarterPlayer.StarterPlayerScripts.RideAnimator)
lobbyAnimator.update(workspace.RodeoLobby,1,Vector3.new(6000,4,108),1/60)
for _,part in ipairs(workspace:GetChildren()) do assert(part.Name~="LocalHerdDust","ranch roaming must not emit dust") end
assert(pen.DisplayMonsters.Pet_1.CrownSprout and pen.DisplayMonsters.Pet_2.LeftWing)
root.Position=Vector3.new(6000,4,0) assert(not Lobby.canUsePen(player,1))
assert(rules.remove(bag,2,1)) Lobby.display(player,1,bag.monsters)
assert(#pen.DisplayMonsters:GetChildren()==1 and #bag.monsters==3)
Lobby.release(player) assert(not pen:FindFirstChild("DisplayMonsters")) character:Destroy()
local folder=Instance.new("Folder") folder.Parent=workspace
local crow=game.ServerStorage.WeedcrowTemplate:Clone() crow.Parent=folder
crow:SetAttribute("MonsterId","Weedcrow") crow:SetAttribute("Flying",true) crow:SetAttribute("Running",true) crow:SetAttribute("RunStarted",0)
crow:PivotTo(CFrame.new(9,2,-20))
local animator=require(game.StarterPlayer.StarterPlayerScripts.RideAnimator)
local rootBefore=crow.PrimaryPart.CFrame
local wing=crow.LeftWing.CFrame
local frames=animator.update(folder,.1,nil,1/60)
assert(crow.PrimaryPart.CFrame==rootBefore and crow.LeftWing.CFrame~=wing)
assert((crow.Body.Position-(frames[crow]*package.WeedcrowVisualTemplate.Body.CFrame).Position).Magnitude<.001,"species-specific immutable pose")
local p=crow.Body:Clone() crow.Body:Destroy() animator.update(folder,.2,nil,1/60) p.Parent=crow
frames=animator.update(folder,.3,nil,1/60)
assert((p.Position-(frames[crow]*package.WeedcrowVisualTemplate.Body.CFrame).Position).Magnitude<.001,"late crow body must align")
local World=require(game.ServerScriptService.HuntWorld)
World.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,require(package.Config),require(package.HuntRules))
World.ensure(0)
local bird=World.spawn(Vector3.new(0,2,-10),"Weedcrow") local ground=World.spawn(Vector3.new(0,2,-10))
assert(bird.PrimaryPart.Position.Y==16)
assert(World.mountedHit(bird.PrimaryPart.Position,bird.PrimaryPart.Position,bird)==nil,"fliers ignore ground species")
local another=World.spawn(Vector3.new(0,2,-10),"Weedcrow")
assert(World.mountedHit(bird.PrimaryPart.Position,bird.PrimaryPart.Position,bird)=="Monster","same flight layer must collide")
assert(World.mountedHit(ground.PrimaryPart.Position,ground.PrimaryPart.Position,ground)==nil,"ground ignores flying species")
assert(World.mountedHit(Vector3.new(36,16,-10),Vector3.new(36,16,-10),bird)=="Wall","fliers cannot leave canyon")
assert(not World.crateHit(bird.PrimaryPart.Position,bird.PrimaryPart.Position,bird,"Small"))
folder:Destroy()
print("SPECIES_PEN_PASS: ownership/distance, two-pet capacity, correct species models, removal, wing motion and late replication")
