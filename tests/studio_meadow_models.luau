local p=game.ReplicatedStorage.RodeoFantasy
local C=require(p.MonsterCatalog)
local animator=require(game.StarterPlayer.StarterPlayerScripts.RideAnimator)
local folder=Instance.new('Folder') folder.Parent=workspace
local small=game.ServerStorage[C.template('MeadowMouse',1)].PrimaryPart.Size
local medium=game.ServerStorage[C.template('GrassBoar',1)].PrimaryPart.Size
local large=game.ServerStorage[C.template('RockElephant',1)].PrimaryPart.Size
assert(medium.X>small.X*1.5 and large.X>small.X*3 and large.Z>small.Z*2.5,'small/medium/large distinction must be visible at one star')
local checks=0
for _,id in ipairs(C.Order) do
 local last=0
 for _,stars in ipairs({1,3,6,9}) do
  local m=game.ServerStorage[C.template(id,stars)]:Clone()
  m:SetAttribute('MonsterId',id) m:SetAttribute('Stars',stars) m:SetAttribute('Flying',C[id].Flying)
  m:SetAttribute('Running',true) m:SetAttribute('RunStarted',0) m.Parent=folder
  m:PivotTo(CFrame.new(0,20,0))
  local root=m.PrimaryPart.CFrame
  local size=m.PrimaryPart.Size.Magnitude assert(size>last) last=size
  local pose=animator.update(folder,.15,nil,1/60)[m]
  assert(m.PrimaryPart.CFrame==root,'visual animation must preserve authoritative root')
  local ref=p[C.visual(id,stars)]
  assert((m.Body.Position-(pose*ref.Body.CFrame).Position).Magnitude<.001)
  m:SetAttribute('Running',false) animator.update(folder,.2,nil,1/60)
  assert((m.LeftBackLeg.Position-(root*ref.LeftBackLeg.CFrame).Position).Magnitude<.001)
  m:Destroy() checks+=1
 end
end
folder:Destroy()
local W=require(game.ServerScriptService.HuntWorld)
W.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,require(p.Config),require(p.HuntRules))
local mount=W.spawn(Vector3.new(0,2,-10),'GrassBoar')
local target=W.spawn(Vector3.new(0,2,-10),'MeadowMouse')
assert(W.mountedHit(mount.PrimaryPart.Position,mount.PrimaryPart.Position,mount,nil,true)==nil)
assert(target:GetAttribute('KnockedAway')) target:Destroy()
local big=W.spawn(Vector3.new(0,2,-10),'RockElephant')
assert(W.mountedHit(mount.PrimaryPart.Position,mount.PrimaryPart.Position,mount,nil,true)=='Monster')
mount:Destroy() big:Destroy()
big=W.spawn(Vector3.new(0,2,-10),'RockElephant')
target=W.spawn(Vector3.new(0,2,-10),'GrassBoar')
assert(W.mountedHit(big.PrimaryPart.Position,big.PrimaryPart.Position,big,nil,false)==nil)
assert(target:GetAttribute('KnockedAway')) target:Destroy()
local other=W.spawn(Vector3.new(0,2,-10),'RockElephant')
assert(W.mountedHit(big.PrimaryPart.Position,big.PrimaryPart.Position,big,nil,false)=='Monster') other:Destroy()
local stone=Instance.new('Part') stone.Position=big.PrimaryPart.Position stone.Size=Vector3.new(4,4,4)
stone:SetAttribute('Scale',1) stone.Parent=workspace.RodeoPrototype.Obstacles
local child=Instance.new('Part') child.Transparency=.25 child.Parent=stone
assert(not W.hit(big.PrimaryPart.Position,big.PrimaryPart.Position,false,big))
assert(stone:GetAttribute('Broken') and child.Transparency==1)
stone:Destroy() big:Destroy()
print('MEADOW_MODELS_PASS: '..checks..' growth models animated with immutable roots; native medium dash/large contacts and small obstacle destruction')
