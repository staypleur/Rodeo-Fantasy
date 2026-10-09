-- Session-only bag income. Summoning/display never affects income.
local BagRules = {}

function BagRules.new()
	return { monsters = {}, pending = 0, balance = 0, serial = 0, totalProduced = 0 }
end

function BagRules.grant(session, monsterId, clock, incomeSeconds, incomeAmount)
	session.serial=(session.serial or 0)+1
	table.insert(session.monsters, { id=session.serial, monsterId = monsterId, stars = 1, lastIncome = clock, incomeSeconds=incomeSeconds, incomeAmount=incomeAmount,sex=BagRules.sexForRoll(math.random()) })
end
function BagRules.sexForRoll(roll) return roll<.5 and "Male" or "Female" end

function BagRules.income(monster, fallback)
 return (monster.incomeAmount or fallback or 1)*2^(math.clamp(math.floor(monster.stars or 1),1,10)-1)
end

function BagRules.accrue(session, clock, seconds, amount)
 local gains={}
	for _, monster in ipairs(session.monsters) do
		local interval=monster.incomeSeconds or seconds
        local rate=BagRules.income(monster,amount)
		local ticks = math.floor(math.max(0, clock - monster.lastIncome) / interval)
		session.pending += ticks * rate
        session.totalProduced = (session.totalProduced or 0) + ticks * rate
		monster.lastIncome += ticks * interval
  if ticks>0 then table.insert(gains,{id=monster.id,amount=ticks*rate}) end
	end
 return gains
end

function BagRules.find(session,id)
 if type(id)~="number" or id~=id or id%1~=0 then return nil end
 for _,item in ipairs(session.monsters) do if item.id==id then return item end end
end
function BagRules.place(session,id,pen)
 if type(pen)~="number" or pen~=pen or pen%1~=0 or pen<1 or pen>4 then return false end
 local item=BagRules.find(session,id)
 if not item or item.assignedPen then return false end
 local count=0
 for _,other in ipairs(session.monsters) do if other.assignedPen==pen then count+=1 end end
 if count>=2 then return false end
 item.assignedPen=pen return true
end
function BagRules.remove(session,id,pen)
 local item=BagRules.find(session,id)
 if not item or item.assignedPen~=pen then return false end
 item.assignedPen=nil return true
end

-- Consumes exactly three distinct copies of the same species and star tier.
-- Returns the new monster and the affected ranches, or nil plus a reason.
function BagRules.evolve(session,ids,clock)
 if type(ids)~="table" or #ids~=3 then return nil,"NeedThree" end
 local unique,selected={},{}
 for _,id in ipairs(ids) do
  if type(id)~="number" or id~=id or id%1~=0 or unique[id] then return nil,"InvalidSelection" end
  unique[id]=true
  local item=BagRules.find(session,id)
  if not item then return nil,"MissingMonster" end
  table.insert(selected,item)
 end
 local first=selected[1]
 if math.floor(first.stars or 1)>=10 then return nil,"MaxStars" end
 for index=2,3 do
  local item=selected[index]
  if item.monsterId~=first.monsterId then return nil,"DifferentSpecies" end
  if item.stars~=first.stars then return nil,"DifferentStars" end
 end
 local affected={}
 for _,item in ipairs(selected) do if item.assignedPen then affected[item.assignedPen]=true end end
 for index=#session.monsters,1,-1 do
  if unique[session.monsters[index].id] then table.remove(session.monsters,index) end
 end
 session.serial=(session.serial or 0)+1
 local evolved={id=session.serial,monsterId=first.monsterId,stars=first.stars+1,lastIncome=clock,
  incomeSeconds=first.incomeSeconds,incomeAmount=first.incomeAmount}
 table.insert(session.monsters,evolved)
 return evolved,affected
end

-- Prepared for direct collection; the UI/action remains to be confirmed.
function BagRules.collect(session)
	local amount = session.pending
	session.pending = 0
	session.balance += amount
	return amount
end

return BagRules
