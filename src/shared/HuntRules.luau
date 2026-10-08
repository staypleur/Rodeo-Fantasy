-- Pure rules for continuous riding, airborne lassoing and swept collisions.
local Rules = {}

function Rules.rideSpeed(clock,dashUntil,base,multiplier)
 return base*(dashUntil and clock<dashUntil and multiplier or 1)
end

function Rules.jumpHeight(elapsed, duration, height)
	return math.sin(math.clamp(elapsed / duration, 0, 1) * math.pi) * height
end

-- One ground-to-ground hop. Shared only for synchronized presentation and server motion.
function Rules.buck(elapsed,cycle,height)
 local phase=(math.max(elapsed,0)%cycle)/cycle
 local direction=math.floor(math.max(elapsed,0)/cycle)%2==0 and 1 or -1
 return math.sin(math.pi*phase)*height, math.sin(math.pi*phase)*direction, math.sin(math.pi*phase*2)*0.28
end

function Rules.progress(elapsed, duration)
	return math.clamp(elapsed / duration, 0, 1)
end

function Rules.inRange(dx, dz, range)
	return dx == dx and dz == dz and dx * dx + dz * dz <= range * range
end

function Rules.sweptBox(ax, ay, az, bx, by, bz, cx, cy, cz, sx, sy, sz, radius)
	local enter, leave = 0, 1
	local origins, deltas = {ax, ay, az}, {bx-ax, by-ay, bz-az}
	local centers, halves = {cx, cy, cz}, {sx/2+radius, sy/2+radius, sz/2+radius}
	for axis = 1, 3 do
		local low, high = centers[axis]-halves[axis], centers[axis]+halves[axis]
		if math.abs(deltas[axis]) < 0.000001 then
			if origins[axis] < low or origins[axis] > high then return false end
		else
			local first, last = (low-origins[axis])/deltas[axis], (high-origins[axis])/deltas[axis]
			if first > last then first, last = last, first end
			enter, leave = math.max(enter, first), math.min(leave, last)
			if enter > leave then return false end
		end
	end
	return true
end

return Rules
