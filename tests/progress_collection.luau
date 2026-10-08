local R=require('../src/shared/ProgressRules')
local last=-1
for level=1,1000 do
 local threshold=R.threshold(level)
 assert(threshold>last and R.level(threshold)==level)
 if level>1 then assert(R.level(threshold-1)==level-1) end
 last=threshold
end
assert(R.threshold(1000)==5000 and R.level(100000)==1000)
local a=R.merge(nil,'a',3,{['MeadowMouse:1']=true},100)
local b=R.merge(a,'a',3,{},101) assert(b.captures==3)
local c=R.merge(b,'b',2,{['Weedcrow:3']=true},102) assert(c.captures==5 and c.seen['MeadowMouse:1'] and c.seen['Weedcrow:3'])
local d=R.merge(c,'a',5,{},103) assert(d.captures==7)
assert(R.bar(5000)==1000)
print('PASS: all 1000 levels, strictly increasing thresholds, max at5000, concurrent checkpoint/union/retry')
local Q=require('../src/shared/CollectionQuery') local C=require('../src/shared/MonsterCatalog')
assert(#Q.entries(C)==20)
local regions=Q.regions(C) assert(table.concat(regions,',')=='All,Meadow,Breeding')
local items={{monsterId='MeadowMouse'},{monsterId='Weedcrow'},{monsterId='TreeWolf'}}
assert(#Q.filter(items,C,'Meadow','mouse')==1)
assert(#Q.filter(items,C,'Breeding','')==0)
assert(#Q.filter(items,C,'All','꼬마',function(id) return id=='MeadowMouse' and '꼬마쥐' or id end)==1)
local future={Order={'a','b'},a={Region='Desert'},b={Region='Breeding'}}
assert(#Q.regions(future)==3 and #Q.filter({{monsterId='b'}},future,'Breeding','')==1)
print('PASS: evolution roster, localized search and future region/breeding filters')
