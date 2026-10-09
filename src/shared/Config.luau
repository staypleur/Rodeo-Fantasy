-- Confirmed rules and adjustable prototype presentation values are kept separate.
local Config = {}
Config.LobbyWalkSpeed=32 -- Faster walking across the expanded lobby (originally 16).

-- Creator Store music/hoof recording plus Roblox bundled action sounds.
Config.Audio = {
 BookOpen="rbxassetid://9118835414", -- ProSoundEffects: Scrapbook Open And Turn Pages 2
 PageTurn="rbxassetid://9118835637", -- ProSoundEffects: Scrapbook Open And Turn Pages 5
 BagOpen="rbxassetid://9121003611", -- ProSoundEffects: Zipper Fly On Jeans Various Speeds 5
 LobbyBGM="rbxassetid://9044539308", -- APMOfficial Fashion Lobby, replaceable trial
 BGM="rbxassetid://1839048285",
 Hooves="rbxassetid://118636555040923",
 Jump="rbxasset://sounds/action_jump.mp3",
 Rope="rbxassetid://9120718279",
 Land="rbxasset://sounds/action_jump_land.mp3",
 Success="rbxasset://sounds/volume_slider.ogg",
 Warning="rbxasset://sounds/volume_slider.ogg",
 CrashObstacle="rbxasset://sounds/impact_explosion_03.mp3",
 CrashMonster="rbxasset://sounds/ouch.ogg",
 Fall="rbxasset://sounds/action_jump_land.mp3",
 Knock="rbxasset://sounds/action_jump_land.mp3",
 BreakWood="rbxasset://sounds/impact_explosion_03.mp3",
 BreakRock="rbxasset://sounds/impact_explosion_03.mp3",
 HoovesFallback="rbxasset://sounds/action_footsteps_plastic.mp3",
 WarningInterval=0.55,
 EventMaxAge=1.5,
 EventHearingDistance=160,
 MusicVolume=0.16,
 EffectsVolume=0.35,
}

Config.Monster = {
	Id = "MeadowMouse",
	Name = "MeadowMouse",
 RunSpeed = 64, -- species-specific riding speed
 SizeClass = "Small", -- meadow mouse
}

-- Merging/evolution remain pending.
Config.Growth = {
	MaxStars = 10,
	CopiesPerUpgrade = 3,
	EvolutionStars = { 3, 6, 9 },
}

Config.BagIncome = {
	IncomeSeconds = 3,
	IncomeAmount = 1,
}

-- Original-style behaviours; exact source-game numbers are not verified.
-- Timing below is explicit prototype tuning, not a claim of identical balance.
Config.Hunt = {
	TameSeconds = 5,
	AngerSeconds = 8,
	AngerEnabled = true,
}

-- These are tuning values for testing, not finalized game balance/art.
Config.Prototype = {
	MetersPerStud = 0.625 / 3,
	ForwardStudsPerSecond = 64,
	SidewaysStudsPerSecond = 32,
	JumpSeconds = 0.28,
	IntroSeconds = 0.55,
	JumpArcStuds = 10,
	RoadHalfWidth = 35,
	HerdStudsPerSecond = 44,
	SwitchDashSeconds = 0.6,
	SwitchDashMultiplier = 1.5,
	HerdSpawnChance = 0.325,
	RockSpawnChance = 0.825,
 CrateSpawnChance = 0.07, -- rare placement trial, not final density
	AirStudsPerSecond = 80,
	LassoRangeStuds = 12,
	FlightSeconds = 1.2,
	AngerWarningSeconds = 2,
	BuckCycleSeconds = 0.55,
	BuckHeightStuds = 2.4,
	AngrySteerMultiplier = 0.35,
	BuckSidewaysStudsPerSecond = 12,
	GroundChunkStuds = 256,
	RideHeightStuds = 2,
	RideForwardStuds = -0.4,
	RespawnSeconds = 1,
	CameraHeightStuds = 56,
	CameraBehindStuds = 32,
	CameraLookAheadStuds = 16,
	CameraSideStuds = 22,
	CameraGroundFocusStuds = 2,
	CameraFieldOfView = 50,
}

return Config
