local C=require('../src/shared/MonsterCatalog')
local R=require('../src/shared/HuntRules')
local expected={MeadowMouse={0,64,5,1},GrassBoar={150,64,6,2},TreeWolf={300,76.8,6,2},Weedcrow={400,80,5,2},RockElephant={500,64,7,3}}
for id,v in pairs(expected) do
 assert(C[id].UnlockMeters==v[1] and C[id].RunSpeed==v[2] and C[id].TameSeconds==v[3])
 assert(C[id].IncomeSeconds==3 and C[id].IncomeAmount==v[4])
end
for _,meters in ipairs({0,149,150,299,300,399,400,499,500,1000}) do
 for serial=1,30 do assert(C[C.pick(meters,serial)].UnlockMeters<=meters) end
end
for _,a in ipairs({'Small','Medium','Large'}) do
 for _,b in ipairs({'Small','Medium','Large'}) do
  for _,dash in ipairs({false,true}) do
   assert(R.canKnock(a,b,dash)==(b~='Large' and (a=='Large' or a=='Medium' and dash)))
  end
 end
end
local cycle=1 local peaks=0 local last=0
for i=0,200 do
 local h=R.buck(i/100,cycle,8,true)
 if h>last and (i==1 or R.buck((i-2)/100,cycle,8,true)>=last) then peaks+=1 end
 last=h
end
assert(peaks==3,'wolf must hop three times in a burst')
assert(R.buck(1.6,1,8,true)==0,'burst must have a landing pause')
assert(C.visual('RockElephant',10)=='RockElephantVisualTemplate_S9')
print('PASS: five species stats, unlock gates, 18 size/dash contacts and three-hop burst')
