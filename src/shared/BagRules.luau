-- Session-only bag income. Summoning/display never affects income.
local BagRules = {}

function BagRules.new()
	return { monsters = {}, pending = 0, balance = 0, serial = 0, totalProduced = 0 }
end

function BagRules.grant(session, monsterId, clock, incomeSeconds, incomeAmount)
	session.serial=(session.serial or 0)+1
	table.insert(session.monsters, { id=session.serial, monsterId = monsterId, stars = 1, lastIncome = clock, incomeSeconds=incomeSeconds, incomeAmount=incomeAmount })
end

function BagRules.accrue(session, clock, seconds, amount)
 local gains={}
	for _, monster in ipairs(session.monsters) do
		local interval=monster.incomeSeconds or seconds
        local rate=monster.incomeAmount or amount
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

-- Prepared for direct collection; the UI/action remains to be confirmed.
function BagRules.collect(session)
	local amount = session.pending
	session.pending = 0
	session.balance += amount
	return amount
end

return BagRules
