local isolate=require(game.StarterPlayer.StarterPlayerScripts.HuntIsolation)
local character=Instance.new("Model") character.Parent=workspace
local head=Instance.new("Part") head.Name="Head" head.Parent=character
local gui=Instance.new("BillboardGui") gui.Name="ExplorerNameplate" gui.Enabled=true gui.Parent=head
local player={Character=character}

isolate.update(player,true)
assert(not gui.Enabled,"own level/name plaque must be hidden in a hunt")
isolate.update(player,false)
assert(gui.Enabled,"own plaque visibility must be restored in the lobby")

isolate.update(player,true)
gui:Destroy()
local replacement=Instance.new("BillboardGui") replacement.Name="ExplorerNameplate" replacement.Enabled=true replacement.Parent=head
isolate.update(player,true)
assert(not replacement.Enabled,"a late-created plaque must also stay hidden during a hunt")
isolate.update(player,false)
assert(replacement.Enabled,"a late-created plaque must be restored in the lobby")
character:Destroy()
print("HUNT_NAMEPLATE_PASS: own theme/name/level plaque hidden during hunting and restored in lobby")
