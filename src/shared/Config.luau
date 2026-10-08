-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}

Config.Monster = {
	Id = "Lumidon",
	Name = "루미돈",
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 2,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	BucksOff = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 35,
	HerdStudsPerSecond = 44,
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	BuckWarningSeconds = 2,
	LandingGraceSeconds = 2,
	GroundChunkStuds = 256,
	RideHeightStuds = 4,
	RespawnSeconds = 1,
	CameraHeightStuds = 68,
	CameraBehindStuds = 22,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 14,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
