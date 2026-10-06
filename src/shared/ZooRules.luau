-- Session-only economy. No persistence, evolution, offline rewards or purchases.
local ZooRules = {}

function ZooRules.new(slotCount)
	local slots = {}
	for index = 1, slotCount do slots[index] = { monster = nil, pending = 0, lastIncome = 0 } end
	return { available = 0, balance = 0, slots = slots }
end

function ZooRules.grant(session)
	session.available += 1
end

function ZooRules.place(session, index, clock, monsterId)
	if type(index) ~= "number" or index ~= math.floor(index) then return false, "InvalidSlot" end
	local slot = session.slots[index]
	if not slot then return false, "InvalidSlot" end
	if slot.monster then return false, "Occupied" end
	if session.available < 1 then return false, "NoMonster" end
	session.available -= 1
	slot.monster, slot.lastIncome = monsterId, clock
	return true
end

function ZooRules.accrue(session, clock, seconds, amount)
	for _, slot in ipairs(session.slots) do
		if slot.monster then
			local ticks = math.floor(math.max(0, clock - slot.lastIncome) / seconds)
			slot.pending += ticks * amount
			slot.lastIncome += ticks * seconds
		end
	end
end

function ZooRules.collect(session, index)
	local slot = session.slots[index]
	if not slot then return 0 end
	local amount = slot.pending
	slot.pending = 0
	session.balance += amount
	return amount
end

return ZooRules
