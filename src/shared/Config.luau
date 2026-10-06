-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}

Config.Monster = {
	Id = "Emberrat",
	Name = "앰버랫",
}

-- Confirmed growth design; merging/evolution and zoo income are not implemented yet.
-- Income amounts and payment rules must be confirmed before implementation.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.Capture = {
	JumpMeters = 3,
	RideSeconds = 3,
	HoldSeconds = 5,
	First = { White = 0.85, Yellow = 0.14, Orange = 0.01 },
	Repeat = { White = 0.80, Yellow = 0.17, Orange = 0.03 },
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.28,
	ForwardStudsPerSecond = 40,
	SidewaysStudsPerSecond = 22,
	JumpSeconds = 0.45,
	JumpArcStuds = 3,
	BarRoundTripSeconds = 2.4,
	RoadHalfWidth = 40,
	GroundChunkStuds = 256,
	RideHeightStuds = 4,
	RespawnSeconds = 1,
}

return Config
