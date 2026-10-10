-- Pure ownership rules used by both servers. No client-authored monster data.
local R={}
local function find(bag,id)
 if type(id)~="number" or id~=id or id%1~=0 then return nil end
 for _,m in ipairs(bag.monsters) do if m.id==id then return m end end
end
R.find=find
function R.available(m) return m and not m.breedingTeam and not m.tradeLock end
function R.profile(bag,ids)
 if type(ids)~="table" or #ids>5 then return nil end
 local result,used={},{}
 for _,id in ipairs(ids) do
  if used[id] or not find(bag,id) then return nil end
  used[id]=true table.insert(result,id)
 end
 return result
end
function R.pair(bag,ids)
 if type(ids)~="table" or #ids~=2 or ids[1]==ids[2] then return false,"Select one female and one male." end
 local a,b=find(bag,ids[1]),find(bag,ids[2])
 if not R.available(a) or not R.available(b) then return false,"A selected monster is busy." end
 if not ((a.sex=="Male" and b.sex=="Female") or (a.sex=="Female" and b.sex=="Male")) then return false,"A female and a male are required." end
 local teams=0 for _ in pairs(bag.breedingTeams or {}) do teams+=1 end
 if teams>=4 then return false,"Up to four breeding pairs are allowed." end
 return true,"Breeding is coming soon. Pairing does not start breeding yet."
end
function R.egg(bag,id,slot,remove)
 if type(slot)~="number" or slot%1~=0 or slot<1 or slot>4 then return false end
 local target
 for _,egg in ipairs(bag.eggs or {}) do
  if egg.id==id then target=egg end
  if not remove and egg.assignedPen==slot then return false end
 end
 if not target then return false end
 if remove then if target.assignedPen~=slot then return false end target.assignedPen=nil
 else if target.assignedPen then return false end target.assignedPen=slot end
 return true
end
function R.offer(bag,offer)
 if type(offer)~="table" or type(offer.ids)~="table" or #offer.ids>100 then return nil end
 local coins=offer.coins
 if type(coins)~="number" or coins~=coins or coins<0 or coins%1~=0 or coins>9e12 or coins>(bag.pending or 0)+(bag.balance or 0) then return nil end
 local selected,used={},{}
 for _,id in ipairs(offer.ids) do
  local m=find(bag,id)
  if not R.available(m) or used[id] then return nil end
  used[id]=true table.insert(selected,m)
 end
 return {coins=coins,ids=table.clone(offer.ids),monsters=selected}
end
function R.exchange(a,b,offerA,offerB)
 local x,y=R.offer(a,offerA),R.offer(b,offerB)
 if not x or not y then return nil,"Your inventory or monster status has changed." end
 if (x.coins==0 and #x.ids==0) or (y.coins==0 and #y.ids==0) then return nil,"Both players must offer something." end
 if #x.ids+#y.ids==0 then return nil,"A trade must include a monster." end
 local function transfer(bag,outgoing,incoming)
  local result=table.clone(bag) result.monsters={} result.profile={}
  local remove={} for _,id in ipairs(outgoing.ids) do remove[id]=true end
  for _,m in ipairs(bag.monsters) do if not remove[m.id] then table.insert(result.monsters,table.clone(m)) end end
  for _,id in ipairs(bag.profile or {}) do if not remove[id] then table.insert(result.profile,id) end end
  for _,m in ipairs(incoming.monsters) do
   result.serial+=1 local copy=table.clone(m) copy.id=result.serial copy.assignedPen=nil copy.tradeLock=nil
   table.insert(result.monsters,copy)
  end
  result.balance=(bag.balance or 0)+(bag.pending or 0)-outgoing.coins+incoming.coins result.pending=0
  return result
 end
 return {transfer(a,x,y),transfer(b,y,x)}
end
return R
