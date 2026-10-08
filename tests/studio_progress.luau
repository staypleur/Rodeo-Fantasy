local S=require(game.ServerScriptService.ProgressService)
local character=Instance.new('Model') character.Parent=workspace
local head=Instance.new('Part') head.Name='Head' head.Parent=character
local h=Instance.new('Humanoid') h.Parent=character
local player={Name='ExplorerTest',UserId=123,Character=character}
S.join(player)
local initial=S.snapshot(player,true) assert(initial.level==1 and initial.xp==0)
local gui=head.ExplorerNameplate local canvas=gui.PlaqueCanvas
assert(canvas.PlayerName.Text=='ExplorerTest' and canvas.Level.Text=='1')
assert(gui.Size.X.Offset<220 and canvas.CompactPlaqueScale.Scale==.6 and gui.Size.Y.Offset==35 and gui:GetAttribute("NameplateRevision")==3,"nameplate fits its text instead of a fixed long panel")
assert(gui.AlwaysOnTop and gui.SizeOffset.Y==2 and gui.StudsOffset.Y==1.5,"avatar must not cover the nameplate")
S.caught(player,'MeadowMouse',1) S.caught(player,'MeadowMouse',1)
local progress=S.snapshot(player,true)
assert(progress.xp==2 and progress.seen['MeadowMouse:1'] and not progress.seen['MeadowMouse:3'])
assert(gui.PlaqueCanvas.Level.Text==tostring(progress.level) and h.NameDisplayDistance==0)
S.discover(player,'MeadowMouse',3)
assert(S.snapshot(player,true).seen['MeadowMouse:3'] and S.snapshot(player).xp==2)
local replacement=Instance.new('Part') replacement.Name='Head' replacement.Parent=character head:Destroy()
S.snapshot(player) assert(replacement.ExplorerNameplate.PlaqueCanvas.Level.Text==tostring(progress.level))
S.leave(player) character:Destroy()
print('PROGRESS_PASS: individual capture XP, unioned stage discoveries, original overhead level/name and head replacement')

local Plaque=require(game.ServerScriptService.LevelPlaque)
for _,case in ipairs({{1,"Bronze"},{99,"Bronze"},{100,"Earth"},{199,"Earth"},{200,"Silver"},{300,"Gold"},{400,"Diamond"},{500,"Obsidian"},{600,"Emerald"},{700,"Ruby"},{800,"Cosmos"},{900,"Angel"},{999,"Angel"},{1000,"Rainbow"}}) do
 local card=Instance.new("BillboardGui") Plaque.update(card,case[1],"staypleur")
 assert(card:GetAttribute("Theme")==case[2] and card.PlaqueCanvas.Level.Text==tostring(case[1]) and card.PlaqueCanvas.PlayerName.Text=="staypleur")
 assert(card.Size.X.Offset<220 and card.PlaqueCanvas.CompactPlaqueScale.Scale<1)
 assert(not card:FindFirstChild("LeafLevel")) card:Destroy()
end
local short=Instance.new("BillboardGui") local long=Instance.new("BillboardGui")
Plaque.update(short,3,"A") Plaque.update(long,3,"TwentyCharacterName20")
assert(short.Size.X.Offset<long.Size.X.Offset,"shorter names must use a shorter panel")
assert(long.PlaqueCanvas.PlayerName.Position.X.Offset+long.PlaqueCanvas.PlayerName.Size.X.Offset<long.PlaqueCanvas.Inset.Position.X.Offset+long.PlaqueCanvas.Inset.Size.X.Offset,"full account name fits inside frame")
short:Destroy() long:Destroy()
print("LEVEL_PLAQUE_PASS: all 11 themes and exact 99/100/199/200/999/1000 boundaries, name inside frame")

-- Real Camera projection: top-down and oblique views, with a large hat/body box.
local isolation=require(game.StarterPlayer.StarterPlayerScripts.HuntIsolation)
local camera=Instance.new("Camera") camera.FieldOfView=70
for _,offset in ipairs({Vector3.new(0,15,15),Vector3.new(0,25,1),Vector3.new(15,10,15)}) do
 camera.CFrame=CFrame.lookAt(offset,Vector3.zero)
 -- Unparented cameras can have a zero viewport in Studio; use a deterministic
 -- projection mock for screen geometry independent of the machine's resolution.
 local mock={ViewportSize=Vector2.new(800,600)}
 function mock:WorldToViewportPoint(world)
  local v=camera.CFrame:PointToObjectSpace(world)
  local depth=-v.Z
  return Vector3.new(400+v.X*400/depth,300-v.Y*400/depth,depth),depth>0
 end
 local frame,size=CFrame.new(),Vector3.new(5,9,5)
 local pos=isolation.screenPosition(mock,frame,size,150,35)
 assert(pos,"normal avatar bounds fit viewport")
 for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
  local point=mock:WorldToViewportPoint(Vector3.new(x*2.5,y*4.5,z*2.5))
  assert(pos.Y<=point.Y-10,"plaque bottom stays above entire avatar at every camera angle")
 end end end
 assert(not isolation.screenPosition(mock,frame,size,900,35),"hide when plaque cannot fit screen")
end
camera:Destroy()
print("NAMEPLATE_PROJECTION_PASS: oblique and overhead avatar separation, viewport edges")
