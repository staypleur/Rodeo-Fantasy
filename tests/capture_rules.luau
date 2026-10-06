local Rules = require("../src/shared/CaptureRules")
local Config = require("../src/shared/Config")
local checked = 0
local function check(condition, message)
	assert(condition, message)
	checked += 1
end

local first, repeatWidths = Config.Capture.First, Config.Capture.Repeat
check(Rules.zone(0, first) == "White", "start is white")
check(Rules.zone(0.84999, first) == "White", "first white ends at 85%")
check(Rules.zone(0.85, first) == "Yellow", "85% boundary is yellow")
check(Rules.zone(0.98999, first) == "Yellow", "yellow ends at 99%")
check(Rules.zone(0.99, first) == "Orange", "99% boundary is orange")
check(Rules.zone(1, first) == "Orange", "right edge is orange")
check(Rules.zone(0.79999, repeatWidths) == "White", "repeat white ends at 80%")
check(Rules.zone(0.8, repeatWidths) == "Yellow", "repeat yellow starts at 80%")
check(Rules.zone(0.96999, repeatWidths) == "Yellow", "repeat yellow ends at 97%")
check(Rules.zone(0.97, repeatWidths) == "Orange", "repeat orange starts at 97%")
for _, widths in ipairs({first, repeatWidths}) do
	local counts = { White = 0, Yellow = 0, Orange = 0 }
	for i = 0, 9999 do
		local zone = Rules.zone((i + 0.5) / 10000, widths)
		counts[zone] += 1
	end
	for zone, count in pairs(counts) do check(count == math.floor(widths[zone] * 10000 + 0.5), zone .. " exact area") end
end
check(Rules.position(0, 2.4) == 0, "bar starts left")
check(Rules.position(1.2, 2.4) == 1, "bar reaches right")
check(Rules.position(2.4, 2.4) == 0, "bar returns left")
check(math.abs(Rules.position(1.8, 2.4) - 0.5) < 1e-8, "bar moves back")
check(Rules.position(-1, 2.4) == 0, "clock lead is clamped")
local range = Config.Capture.JumpMeters / Config.Prototype.MetersPerStud
check(Rules.inRange(0, 0, range, range), "3m accepted")
check(not Rules.inRange(0, 0, range + 0.001, range), "over 3m rejected")
check(not Rules.inRange(range, range, 0, range), "diagonal cannot bypass range")
check(not Rules.inRange(0/0, 0, 0, range), "NaN cannot bypass range")
check(Config.Monster.MaxEnergy / Config.Monster.EnergyPerAttack == 4, "Emberrat skill requires four attacks")
print("PASS: " .. checked .. " capture rule checks")
