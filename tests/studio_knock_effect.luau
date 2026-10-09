-- Run in Studio Command Bar in edit mode on the KnockEffects place.
local p=game.ReplicatedStorage.RodeoFantasy
local W=require(game.ServerScriptService.HuntWorld)
local rules=require(p.HuntRules)
local config=require(p.Config)
local cases={{'GrassBoar','MeadowMouse',true,true},{'GrassBoar','TreeWolf',true,true},
 {'GrassBoar','RockElephant',true,false},{'GrassBoar','MeadowMouse',false,false},
 {'RockElephant','MeadowMouse',false,true},{'RockElephant','TreeWolf',true,true},
 {'RockElephant','RockElephant',true,false}}
for _,case in ipairs(cases) do
 local world=Instance.new('Folder') world.Name='KnockTest' world.Parent=workspace
 local monsters=Instance.new('Folder') monsters.Name='Monsters' monsters.Parent=world
 local obstacles=Instance.new('Folder') obstacles.Name='Obstacles' obstacles.Parent=world
 W.init(world,game.ServerStorage.RodeoMonsterTemplate,config,rules)
 local mount=W.spawn(Vector3.new(0,3,-10),case[1]) mount:SetAttribute('Occupied',true)
 local target=W.spawn(Vector3.new(0,3,-10),case[2])
 local result=W.mountedHit(mount.PrimaryPart.Position,mount.PrimaryPart.Position,mount,{[target]=true},case[3])
 assert((result==nil)==case[4],case[1]..' vs '..case[2])
 assert((target:GetAttribute('KnockedAway')==true)==case[4])
 if case[4] then assert(target:GetAttribute('KnockedAt') and math.abs(target:GetAttribute('KnockDirection'))==1) end
 world:Destroy()
end
local effect=require(game.StarterPlayer.StarterPlayerScripts.CrashEffect)
local world=Instance.new('Folder') world.Parent=workspace
local model=Instance.new('Model') model.Parent=world
local root=Instance.new('Part') root.Name='MountRoot' root.Transparency=1 root.Parent=model model.PrimaryPart=root
root.Position=Vector3.new(0,3,0)
model:SetAttribute('MonsterId','MeadowMouse') model:SetAttribute('KnockedAt',10) model:SetAttribute('KnockDirection',1)
local body=Instance.new('Part') body.Name='Body' body.Color=Color3.fromRGB(200,150,100) body.Parent=model
body.Position=Vector3.new(0,4,0)
local count=effect.knock(model,10)
assert(count==1 and body.LocalTransparencyModifier==1,'shards replace the intact body immediately')
assert(effect.knock(model,10)==0,'same collision must never spawn duplicate shards')
local shard=workspace:FindFirstChild('LocalKnockShard')
assert(shard and shard.Color==body.Color and not shard.CanCollide and not shard.CanQuery)
local origin=shard.Position effect.updateKnocks(10.3,world)
assert(shard.Position.X>origin.X and shard.Position.Y>origin.Y,'chunks scatter sideways and upward')
effect.updateKnocks(11.2,world) assert(not shard.Parent,'temporary chunks expire')
local model2=model:Clone() model2.Parent=world model2:SetAttribute('KnockedAt',20)
effect.knock(model2,20) effect.updateKnocks(20,nil)
assert(not workspace:FindFirstChild('LocalKnockShard'),'lobby return cleans up chunks')
world:Destroy()
print('KNOCK_EFFECT_PASS: unchanged size rules, hit metadata, single burst, color/mesh retention, trajectory and cleanup')
