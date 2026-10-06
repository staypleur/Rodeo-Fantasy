-- Pure logic: used by both the UI and server, and executable without Roblox.
local Rules = {}

function Rules.position(elapsed, roundTripSeconds)
	local phase = (math.max(0, elapsed) / roundTripSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

function Rules.zone(position, widths)
	if position < widths.White then
		return "White"
	elseif position < 1 - widths.Orange then
		return "Yellow"
	else
		return "Orange"
	end
end

function Rules.inRange(dx, dy, dz, range)
	return dx * dx + dy * dy + dz * dz <= range * range
end

return Rules
