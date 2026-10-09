local R=require("../src/shared/SocialRules")
local B=require("../src/shared/BagRules")
local a,b=B.new(),B.new()
for _,bag in ipairs({a,b}) do
 B.grant(bag,"MeadowMouse",0,3,1) B.grant(bag,"GrassBoar",0,3,2)
 bag.monsters[1].sex="Female" bag.monsters[2].sex="Male"
end
assert(R.pair(a,{1,2}))
assert(not R.pair(a,{1,1})) assert(not R.pair(a,{1,999}))
a.monsters[1].breedingTeam=1 assert(not R.pair(a,{1,2}));a.monsters[1].breedingTeam=nil
a.breedingTeams={1,2,3,4};assert(not R.pair(a,{1,2}));a.breedingTeams={}
assert(R.profile(a,{1,2}) and not R.profile(a,{1,1}) and not R.profile(a,{99}))
a.eggs={{id=1},{id=2}}
assert(R.egg(a,1,1,false));assert(not R.egg(a,2,1,false));assert(not R.egg(a,1,2,false))
assert(not R.egg(a,1,2,true));assert(R.egg(a,1,1,true));assert(R.egg(a,2,1,false))
assert(not R.egg(a,1,5,false))
a.pending=20;b.balance=10;a.profile={1,2}
assert(not R.exchange(a,b,{ids={1},coins=0},{ids={},coins=0}))
assert(not R.exchange(a,b,{ids={},coins=1},{ids={},coins=2}))
assert(not R.offer(a,{ids={1,1},coins=0}))
assert(not R.offer(a,{ids={},coins=0/0}));assert(not R.offer(a,{ids={},coins=-1}))
assert(not R.offer(a,{ids={},coins=21}));assert(not R.offer(a,{ids={888},coins=0}))
local result=assert(R.exchange(a,b,{ids={1},coins=0},{ids={},coins=7}))
assert(#result[1].monsters==1 and #result[2].monsters==3)
assert(result[1].balance==27 and result[2].balance==3)
assert(result[1].profile[1]==2 and #result[1].profile==1)
assert(#a.monsters==2 and a.pending==20,"planning must not mutate either bag")
assert(result[2].monsters[3].id==3 and result[2].monsters[3].sex=="Female")
local mons=assert(R.exchange(a,b,{ids={1},coins=0},{ids={2},coins=0}))
assert(mons[1].monsters[2].monsterId=="GrassBoar")
a.monsters[1].breedingTeam=1
assert(not R.exchange(a,b,{ids={1},coins=0},{ids={2},coins=0}))
print("SOCIAL_RULES_PASS: ownership, sex, four teams, one egg/slot, profile, no gifts, finite funds, conserved exchange")
