local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local package = ReplicatedStorage:WaitForChild("RodeoFantasy")
local Config = require(package:WaitForChild("Config"))
local Rules = require(package:WaitForChild("CaptureRules"))
local remote = package:WaitForChild("CaptureRemote")
local tuning = Config.Prototype
local world = workspace:WaitForChild("RodeoPrototype")
local monsters = world:WaitForChild("Monsters")
local template = game:GetService("ServerStorage"):WaitForChild("RodeoMonsterTemplate")
local states, owners, inventories, rateLimits, chunks = {}, {}, {}, {}, {}
local initialPosition = Vector3.new(0, 2, -8)
local jumpRange = Config.Capture.JumpMeters / tuning.MetersPerStud
local preview = world:FindFirstChild("PreviewMonster")
if preview then preview:Destroy() end
chunks[0] = world:FindFirstChild("PreviewGround")

local function now()
	return workspace:GetServerTimeNow()
end

local function groundAt(z)
	local center = math.floor(z / tuning.GroundChunkStuds + 0.5)
	for index = center - 1, center + 1 do
		if not chunks[index] then
			local floor = Instance.new("Part")
			floor.Name = "TestGround_" .. index
			floor.Anchored = true
			floor.Size = Vector3.new(100, 2, tuning.GroundChunkStuds)
			floor.Position = Vector3.new(0, -1, index * tuning.GroundChunkStuds)
			floor.Material = Enum.Material.Sand
			floor.Color = Color3.fromRGB(195, 166, 119)
			floor.Parent = world
			chunks[index] = floor
		end
	end
end

local function spawnMonster(position)
	local monster = template:Clone()
	monster.Name = Config.Monster.Id
	monster:SetAttribute("MonsterId", Config.Monster.Id)
	monster:SetAttribute("Occupied", false)
	monster:PivotTo(CFrame.new(position))
	monster.Parent = monsters
	return monster
end

local function notify(player, message)
	remote:FireClient(player, "Notice", { message = message })
end

local function sendState(player, state, message)
	remote:FireClient(player, "State", {
		phase = state and state.phase or "Idle",
		started = state and state.started or now(),
		captureAt = state and state.captureAt,
		widths = state and state.widths,
		message = message,
		count = inventories[player] or 0,
	})
end

local function clearRope(state)
	for _, item in ipairs(state.rope or {}) do
		item:Destroy()
	end
	state.rope = nil
end

local function release(player, message)
	local state = states[player]
	if not state then return end
	states[player] = nil
	clearRope(state)
	owners[state.monster] = nil
	if state.monster.Parent then
		state.monster:SetAttribute("Occupied", false)
	end
	local root, humanoid = state.root, state.humanoid
	if root.Parent and humanoid.Parent then
		local p = root.Position
		if state.monster.Parent then p = state.monster:GetPivot().Position end
		groundAt(p.Z)
		root.CFrame = CFrame.new(math.clamp(p.X + 5, -44, 44), 5, p.Z)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.Anchored = state.wasAnchored
		humanoid.AutoRotate = state.autoRotate
		humanoid.PlatformStand = state.platformStand
		if humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	if player.Parent then sendState(player, nil, message) end
end

local function capture(player)
	local state = states[player]
	if not state or state.phase ~= "Holding" and state.phase ~= "Minigame" then return end
	local monster = state.monster
	local position = monster:GetPivot().Position
	inventories[player] = (inventories[player] or 0) + 1
	player:SetAttribute("EmberratCount", inventories[player])
	release(player, "포획 성공! 앰버랫이 추가됐어요.")
	monster:Destroy()
	-- Repeatable test fixture; this is not the final wild-monster spawn system.
	task.delay(tuning.RespawnSeconds, function() spawnMonster(position) end)
end

local function mount(player, monster)
	if states[player] then return end
	if typeof(monster) ~= "Instance" or not monster:IsA("Model") then return end
	if monster.Parent ~= monsters or monster:GetAttribute("MonsterId") ~= Config.Monster.Id then return end
	if owners[monster] then notify(player, "다른 플레이어가 타고 있어요.") return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	local target = monster.PrimaryPart
	if not target then return end
	local difference = target.Position - root.Position
	if not Rules.inRange(difference.X, difference.Y, difference.Z, jumpRange) then
		notify(player, "앰버랫에게 더 가까이 가세요. 점프 범위는 3m예요.")
		return
	end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, monster }
	if workspace:Raycast(root.Position, difference, rayParams) then
		notify(player, "사이에 장애물이 있어 줄을 던질 수 없어요.")
		return
	end
	local state = {
		phase = "Jumping", started = now(), monster = monster,
		root = root, humanoid = humanoid, steer = 0, steerAt = now(),
		origin = root.CFrame, wasAnchored = root.Anchored,
		autoRotate = humanoid.AutoRotate, platformStand = humanoid.PlatformStand,
		widths = (inventories[player] or 0) > 0 and Config.Capture.Repeat or Config.Capture.First,
	}
	states[player], owners[monster] = state, player
	monster:SetAttribute("Occupied", true)
	root.Anchored = true
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	local start = Instance.new("Attachment")
	start.Position = Vector3.new(1, 0, 0)
	start.Parent = root
	local finish = Instance.new("Attachment")
	finish.Parent = target
	local rope = Instance.new("Beam")
	rope.Attachment0, rope.Attachment1 = start, finish
	rope.Width0, rope.Width1 = 0.1, 0.1
	rope.FaceCamera = true
	rope.Color = ColorSequence.new(Color3.fromRGB(166, 119, 65))
	rope.Parent = root
	state.rope = { rope, start, finish }
	sendState(player, state)
end

remote.OnServerEvent:Connect(function(player, action, payload)
	if type(action) ~= "string" then return end
	if action ~= "Sync" and action ~= "Mount" and action ~= "Steer" and action ~= "Press" then return end
	local clock = now()
	local limits = rateLimits[player]
	if not limits then limits = {} rateLimits[player] = limits end
	local interval = action == "Steer" and 0.04 or action == "Press" and 0.1 or 0.25
	if clock - (limits[action] or -math.huge) < interval then return end
	limits[action] = clock
	if action == "Sync" then
		sendState(player, states[player])
	elseif action == "Mount" then
		mount(player, payload)
	elseif action == "Steer" then
		local state = states[player]
		if state and (payload == -1 or payload == 0 or payload == 1) then
			state.steer, state.steerAt = payload, clock
		end
	elseif action == "Press" then
		local state = states[player]
		if not state or (state.phase ~= "Minigame" and state.phase ~= "Holding") then return end
		if not state.humanoid.Parent or state.humanoid.Health <= 0 or not state.monster.Parent then return end
		if state.captureAt and clock >= state.captureAt then
			capture(player)
			return
		end
		-- The client never supplies a success/colour/count. Server receipt time is authoritative.
		local position = Rules.position(clock - state.started, tuning.BarRoundTripSeconds)
		local zone = Rules.zone(position, state.widths)
		remote:FireClient(player, "Judged", { zone = zone, position = position })
		if zone == "Orange" then
			capture(player)
		elseif zone == "Yellow" then
			-- Keep the bar's original clock and the first yellow's deadline.
			state.phase = "Holding"
			state.captureAt = state.captureAt or (clock + Config.Capture.HoldSeconds)
			sendState(player, state)
		else
			release(player, "흰색 판정! 떨어졌어요. 다시 클릭해 도전하세요.")
		end
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	local clock = now()
	for player, state in pairs(states) do
		if not state.root.Parent or not state.humanoid.Parent or state.humanoid.Health <= 0
			or not state.monster.Parent or player.Character ~= state.root.Parent then
			release(player, "다시 탑승할 수 있어요.")
			continue
		end
		local monsterFrame = state.monster:GetPivot()
		local saddle = monsterFrame * CFrame.new(0, tuning.RideHeightStuds, 0)
		if state.phase == "Jumping" then
			local alpha = math.clamp((clock - state.started) / tuning.JumpSeconds, 0, 1)
			state.root.CFrame = state.origin:Lerp(saddle, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * tuning.JumpArcStuds, 0)
			if alpha >= 1 then
				clearRope(state)
				state.phase, state.started = "Riding", clock
				sendState(player, state)
			end
		else
			local p = monsterFrame.Position
			local steering = clock - state.steerAt < 0.5 and state.steer or 0
			local dt = math.min(deltaTime, 0.1)
			local x = math.clamp(p.X + steering * tuning.SidewaysStudsPerSecond * dt, -tuning.RoadHalfWidth, tuning.RoadHalfWidth)
			local z = p.Z - tuning.ForwardStudsPerSecond * dt
			groundAt(z)
			local newFrame = CFrame.new(x, p.Y, z)
			state.monster:PivotTo(newFrame)
			state.root.CFrame = newFrame * CFrame.new(0, tuning.RideHeightStuds, 0)
			state.root.AssemblyLinearVelocity = Vector3.zero
			if state.phase == "Riding" and clock - state.started >= Config.Capture.RideSeconds then
				state.phase, state.started = "Minigame", clock
				sendState(player, state)
			elseif state.phase == "Holding" and clock >= state.captureAt then
				capture(player)
			end
		end
	end
end)

local function playerAdded(player)
	inventories[player] = 0
	player:SetAttribute("EmberratCount", 0)
	player.CharacterRemoving:Connect(function() release(player) end)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(function(player)
	release(player)
	inventories[player], rateLimits[player] = nil, nil
end)
for _, player in ipairs(Players:GetPlayers()) do playerAdded(player) end
groundAt(0)
spawnMonster(initialPosition)
