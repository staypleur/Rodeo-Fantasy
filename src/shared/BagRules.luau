-- Session-only bag income. Summoning/display never affects income.
local BagRules = {}

function BagRules.new()
	return { monsters = {}, pending = 0, balance = 0 }
end

function BagRules.grant(session, monsterId, clock)
	table.insert(session.monsters, { monsterId = monsterId, stars = 1, lastIncome = clock })
end

function BagRules.accrue(session, clock, seconds, amount)
	for _, monster in ipairs(session.monsters) do
		local ticks = math.floor(math.max(0, clock - monster.lastIncome) / seconds)
		session.pending += ticks * amount
		monster.lastIncome += ticks * seconds
	end
end

-- Prepared for direct collection; the UI/action remains to be confirmed.
function BagRules.collect(session)
	local amount = session.pending
	session.pending = 0
	session.balance += amount
	return amount
end

return BagRules
