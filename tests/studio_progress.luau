local S=require(game.ServerScriptService.ProgressService)
local character=Instance.new('Model') character.Parent=workspace
local head=Instance.new('Part') head.Name='Head' head.Parent=character
local h=Instance.new('Humanoid') h.Parent=character
local old=Instance.new('BillboardGui') old.Name='ExplorerNameplate' old.Parent=head
local player={Name='ExplorerTest',UserId=123,Character=character}
S.join(player)
local initial=S.snapshot(player,true) assert(initial.level==nil and initial.xp==nil)
assert(not head:FindFirstChild('ExplorerNameplate') and h.NameDisplayDistance==0,'remove old plaque and suppress default name')
S.caught(player,'MeadowMouse',1) S.caught(player,'MeadowMouse',1)
local progress=S.snapshot(player,true)
assert(progress.xp==nil and progress.seen['MeadowMouse:1'] and not progress.seen['MeadowMouse:3'])
assert(not head:FindFirstChild('ExplorerNameplate'),'discoveries do not recreate plaque')
S.discover(player,'MeadowMouse',3)
assert(S.snapshot(player,true).seen['MeadowMouse:3'] and S.snapshot(player).xp==nil)
local replacement=Instance.new('Part') replacement.Name='Head' replacement.Parent=character head:Destroy()
S.snapshot(player) assert(not replacement:FindFirstChild('ExplorerNameplate'),'respawn does not recreate plaque')
S.leave(player) character:Destroy()
print('PROGRESS_PASS: level/XP removed and discoveries retained, all overhead names removed')
