local S=require(game.ServerScriptService.ProgressService)
local character=Instance.new('Model') character.Parent=workspace
local head=Instance.new('Part') head.Name='Head' head.Parent=character
local h=Instance.new('Humanoid') h.Parent=character
local player={Name='ExplorerTest',UserId=123,Character=character}
S.join(player)
local initial=S.snapshot(player,true) assert(initial.level==1 and initial.xp==0)
local gui=head.ExplorerNameplate assert(gui.PlayerName.Text=='ExplorerTest' and gui.LeafLevel.Level.Text=='1')
S.caught(player,'MeadowMouse',1) S.caught(player,'MeadowMouse',1)
local progress=S.snapshot(player,true)
assert(progress.xp==2 and progress.seen['MeadowMouse:1'] and not progress.seen['MeadowMouse:3'])
assert(gui.LeafLevel.Level.Text==tostring(progress.level) and h.NameDisplayDistance==0)
S.discover(player,'MeadowMouse',3)
assert(S.snapshot(player,true).seen['MeadowMouse:3'] and S.snapshot(player).xp==2)
local replacement=Instance.new('Part') replacement.Name='Head' replacement.Parent=character head:Destroy()
S.snapshot(player) assert(replacement.ExplorerNameplate.LeafLevel.Level.Text==tostring(progress.level))
S.leave(player) character:Destroy()
print('PROGRESS_PASS: individual capture XP, unioned stage discoveries, original overhead level/name and head replacement')
