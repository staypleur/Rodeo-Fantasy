local factory=require(game.StarterPlayer.StarterPlayerScripts.CreatureMesh)
assert(factory.prepare(),'actual 3D mesh construction must succeed')
local C=require(game.ReplicatedStorage.RodeoFantasy.MonsterCatalog)
local animator=require(game.StarterPlayer.StarterPlayerScripts.RideAnimator)
local folder=Instance.new('Folder') folder.Parent=workspace
local checked=0
for _,id in ipairs(C.Order) do
 for _,stars in ipairs({1,3,6,9}) do
  local model=game.ServerStorage[C.template(id,stars)]:Clone()
  model:SetAttribute('MonsterId',id) model:SetAttribute('Stars',stars) model:SetAttribute('Running',true) model.Parent=folder
  model:PivotTo(CFrame.new(0,30,0))
  local size,position=model.Body.Size,model.Body.CFrame
  factory.decorate(model)
  assert(model.Body:IsA('MeshPart') and model.Body.Size==size and model.Body.CFrame==position,'mesh must replace actual body without changing size or position')
  local leaf=false for _,part in ipairs(model:GetChildren()) do if part:IsA('MeshPart') and (part.Name:find('Leaf') or part.Name:find('Sprout') or part.Name:find('Clover') or part.Name:find('Grass')) then leaf=true end end
  assert(leaf,'original pointed leaf mesh must appear on every meadow family')
  local pose=animator.update(folder,.2,nil,1/60)[model]
  assert((model.Body.Position-(pose*game.ReplicatedStorage.RodeoFantasy[C.visual(id,stars)].Body.CFrame).Position).Magnitude<.001,'mesh animation follows approved reference')
  model:Destroy() checked+=1
 end
end
folder:Destroy()
print('CREATURE_MESH_PASS: '..checked..' actual MeshPart growth models, pointed leaf geometry, dimensions and native animation')

local W=require(game.ServerScriptService.HuntWorld)
local cfg=require(game.ReplicatedStorage.RodeoFantasy.Config)
W.init(workspace.RodeoPrototype,game.ServerStorage.RodeoMonsterTemplate,cfg,require(game.ReplicatedStorage.RodeoFantasy.HuntRules))
W.ensure(0) W.replenish(0,1,nil,true)
local initial={}
for _,model in ipairs(workspace.RodeoPrototype.Monsters:GetChildren()) do
 assert(model:GetAttribute('BornAtDen') and model:GetAttribute('Emerging'),'all initial wild creatures must start inside a real den')
 assert(#model:GetChildren()==1 and model.PrimaryPart,'server must replicate only the authoritative wild root')
 initial[model]=model.PrimaryPart.Position
end
W.step(.6)
for model,p in pairs(initial) do assert(math.abs(model.PrimaryPart.Position.X)<math.abs(p.X),'creatures physically walk out toward road') end
local model=next(initial)
factory.materialize(model) factory.decorate(model)
assert(model.Body:IsA('MeshPart') and model.PrimaryPart.Name=='MountRoot','deferred visual must become the approved actual 3D mesh')
local count=#model:GetChildren() factory.materialize(model) assert(#model:GetChildren()==count,'materialization must not duplicate body parts')
print('DEFERRED_DEN_MESH_PASS: real cave births, continuous exit motion, root-only replication and one-time actual mesh materialization')
