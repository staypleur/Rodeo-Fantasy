-- Injected only into a temporary Studio test session. Never included in dist.
local RS = game:GetService("ReplicatedStorage")
local testRemote = Instance.new("RemoteFunction")
testRemote.Name = "RodeoTestDriver"
testRemote.Parent = RS
local server = Instance.new("Script")
server.Name = "RodeoTestController"
server.Source = [==[
local RS = game:GetService("ReplicatedStorage")
local testService = game:GetService("StudioTestService")
local driver = RS:WaitForChild("RodeoTestDriver")
local finished = false
driver.OnServerInvoke = function(player, action, value)
	if action == "Position" then
		local monster = workspace.RodeoPrototype.Monsters:FindFirstChild("Emberrat")
		assert(monster, "test monster missing")
		local root = player.Character:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new(monster.PrimaryPart.Position + Vector3.new(value and 5 or 30, 3, 0))
		root.AssemblyLinearVelocity = Vector3.zero
		return monster
	elseif action == "SwitchTarget" then
		local monster = game:GetService("ServerStorage").RodeoMonsterTemplate:Clone()
		monster.Name = "SwitchTestTarget"
		monster:SetAttribute("MonsterId", "Emberrat")
		monster:SetAttribute("Occupied", false)
		local root = player.Character.HumanoidRootPart
		monster:PivotTo(CFrame.new(root.Position.X + (value and 30 or 3), 2, root.Position.Z - 3))
		monster.Parent = workspace.RodeoPrototype.Monsters
		return monster
	elseif action == "Finish" then
		finished = true
		print("RODEO_TEST_SERVER_RESULT: " .. value)
		task.defer(function() testService:EndTest(value) end)
		return true
	end
end
task.delay(90, function()
	if not finished then testService:EndTest("FAIL: timeout after 90 seconds") end
end)
]==]
server.Parent = game:GetService("ServerScriptService")
local client = Instance.new("LocalScript")
client.Name = "RodeoTestClient"
client.Source = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local driver = RS:WaitForChild("RodeoTestDriver")
local remote = RS:WaitForChild("RodeoFantasy"):WaitForChild("CaptureRemote")
local config = require(RS.RodeoFantasy.Config)
local rules = require(RS.RodeoFantasy.CaptureRules)
local state = { phase = "Idle", count = 0 }
local lastZone, notice, checks = nil, nil, 0
remote.OnClientEvent:Connect(function(kind, data)
	if kind == "State" then state = data end
	if kind == "Judged" then lastZone = data.zone end
	if kind == "Notice" then notice = data.message end
end)
local function check(value, message)
	assert(value, message)
	checks += 1
end
local function untilTrue(predicate, message, seconds)
	local deadline = os.clock() + (seconds or 10)
	repeat
		if predicate() then return end
		RunService.Heartbeat:Wait()
	until os.clock() > deadline
	error(message)
end
local function mount()
	task.wait(0.3)
	local monster = driver:InvokeServer("Position", true)
	remote:FireServer("Mount", monster)
	untilTrue(function() return state.phase == "Riding" end, "did not mount")
	return monster
end
local function pressAt(position)
	untilTrue(function() return state.phase == "Minigame" or state.phase == "Holding" end, "no minigame")
	local duration = config.Prototype.BarRoundTripSeconds
	local target = state.started + duration * position / 2
	-- Leave room for the input cooldown; a near-immediate next colour uses the next pass.
	while target <= workspace:GetServerTimeNow() + 0.18 do target += duration end
	task.wait(math.max(0, target - workspace:GetServerTimeNow()))
	remote:FireServer("Press")
end
local success, problem = pcall(function()
	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart")
	check(player:WaitForChild("PlayerGui"):WaitForChild("RodeoCaptureUI", 15) ~= nil, "client UI did not load")
	untilTrue(function() return workspace.RodeoPrototype.Monsters:FindFirstChild("Emberrat") ~= nil end, "no monster")
	task.wait(1)
	local monster = driver:InvokeServer("Position", false)
	remote:FireServer("Mount", monster)
	task.wait(0.4)
	check(state.phase == "Idle" and notice ~= nil, "out-of-range mount must be rejected")
	remote:FireServer("Mount", "invalid")
	task.wait(0.3)
	monster = mount()
	check(monster:GetAttribute("Occupied"), "monster must be occupied")
	local firstRideStarted = state.started
	local farTarget = driver:InvokeServer("SwitchTarget", true)
	remote:FireServer("Mount", farTarget)
	task.wait(0.3)
	check(state.phase == "Riding" and monster:GetAttribute("Occupied"), "invalid switch must preserve old ride")
	check(state.started == firstRideStarted, "invalid switch must preserve ride clock")
	local switchTarget = driver:InvokeServer("SwitchTarget", false)
	remote:FireServer("Mount", switchTarget)
	untilTrue(function() return state.phase == "Jumping" end, "switch must jump")
	check(not monster:GetAttribute("Occupied"), "switch must free previous monster")
	untilTrue(function() return state.phase == "Riding" end, "switch must finish mounting")
	check(switchTarget:GetAttribute("Occupied") and state.started > firstRideStarted, "switch must restart three seconds")
	check(state.count == 0, "switch must not capture previous monster")
	monster = switchTarget
	local old = monster.PrimaryPart.Position
	for _ = 1, 4 do remote:FireServer("Steer", 1) task.wait(0.15) end
	remote:FireServer("Steer", 0)
	check(monster.PrimaryPart.Position.Z < old.Z, "must move forward")
	check(monster.PrimaryPart.Position.X > old.X, "D steering must move right")
	pressAt(0.2)
	untilTrue(function() return state.phase == "Idle" end, "white did not dismount")
	check(lastZone == "White" and state.count == 0, "white must not capture")
	check(not character.HumanoidRootPart.Anchored, "dismount must unanchor player")
	mount()
	pressAt(0.9)
	untilTrue(function() return state.phase == "Holding" end, "yellow did not enter hold")
	check(lastZone == "Yellow" and state.count == 0, "yellow must wait before capture")
	local firstDeadline, barStarted = state.captureAt, state.started
	local rejectedTarget = driver:InvokeServer("SwitchTarget", false)
	remote:FireServer("Mount", rejectedTarget)
	task.wait(0.3)
	check(state.phase == "Holding" and state.captureAt == firstDeadline, "holding must reject switch without resetting deadline")
	local captureBar = player.PlayerGui.RodeoCaptureUI:FindFirstChild("CaptureBar", true)
	check(captureBar and captureBar.Visible, "bar must stay visible while holding")
	pressAt(0.9)
	task.wait(0.15)
	check(state.phase == "Holding" and state.count == 0, "second yellow must continue holding")
	check(state.captureAt == firstDeadline, "second yellow must not restart the five-second timer")
	check(state.started == barStarted, "second yellow must not reset the moving bar")
	untilTrue(function() return state.phase == "Idle" end, "yellow did not capture", 7)
	check(workspace:GetServerTimeNow() < firstDeadline + 0.5, "capture must use the first deadline")
	check(state.count == 1 and player:GetAttribute("EmberratCount") == 1, "yellow must capture exactly one")
	task.wait(1.2)
	mount()
	check(state.widths.White == 0.8 and state.widths.Orange == 0.03, "repeat widths must change")
	pressAt(0.9)
	untilTrue(function() return state.phase == "Holding" end, "repeat yellow must start holding")
	local orangeDeadline = state.captureAt
	pressAt(0.985)
	untilTrue(function() return state.phase == "Idle" end, "orange did not capture")
	check(lastZone == "Orange" and state.count == 2, "orange must capture exactly one immediately")
	check(workspace:GetServerTimeNow() < orangeDeadline, "orange during holding must finish before deadline")
	check(not character.HumanoidRootPart.Anchored, "capture must restore player movement")
	task.wait(1.2)
	mount()
	pressAt(0.9)
	untilTrue(function() return state.phase == "Holding" end, "yellow before white test")
	local failedDeadline = state.captureAt
	pressAt(0.2)
	untilTrue(function() return state.phase == "Idle" end, "white during holding must dismount")
	check(lastZone == "White" and state.count == 2, "white during holding must not capture")
	task.wait(math.max(0, failedDeadline - workspace:GetServerTimeNow()) + 0.3)
	check(player:GetAttribute("EmberratCount") == 2, "failed hold must not capture later")
end)
driver:InvokeServer("Finish", success and ("PASS: " .. checks .. " Studio play checks") or ("FAIL: " .. tostring(problem)))
]==]
client.Parent = game:GetService("StarterPlayer").StarterPlayerScripts
local result = game:GetService("StudioTestService"):ExecutePlayModeAsync({ test = "RodeoCapture" })
print("RODEO_PLAY_RESULT: " .. tostring(result))
assert(type(result) == "string" and string.sub(result, 1, 5) == "PASS:", tostring(result))
