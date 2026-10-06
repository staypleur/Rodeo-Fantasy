local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local package = ReplicatedStorage:WaitForChild("RodeoFantasy")
local Config = require(package:WaitForChild("Config"))
local Rules = require(package:WaitForChild("CaptureRules"))
local remote = package:WaitForChild("CaptureRemote")
local monsters = workspace:WaitForChild("RodeoPrototype"):WaitForChild("Monsters")
local mouse = player:GetMouse()
local phase, started, widths = "Idle", 0, Config.Capture.First
local captureAt, lastPress = nil, -math.huge
local left, right, pressed, lastSteer = false, false, false, 0
local noticeUntil, savedCameraType, savedCameraSubject = 0, nil, nil

local function make(className, properties, parent)
	local item = Instance.new(className)
	for key, value in pairs(properties) do item[key] = value end
	item.Parent = parent
	return item
end

local gui = make("ScreenGui", { Name = "RodeoCaptureUI", ResetOnSpawn = false, DisplayOrder = 10 }, player:WaitForChild("PlayerGui"))
local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.new(0.9, 0, 0, 192), BackgroundColor3 = Color3.fromRGB(27, 24, 23),
	BackgroundTransparency = 0.08, BorderSizePixel = 0,
}, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(720, 192) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, panel)
local function label(parent, text, position, size, fontSize, color)
	return make("TextLabel", {
		Text = text, Position = position, Size = size, TextSize = fontSize,
		Font = Enum.Font.GothamMedium, TextColor3 = color or Color3.fromRGB(249, 242, 225),
		BackgroundTransparency = 1, TextWrapped = true,
	}, parent)
end
label(panel, "RODEO FANTASY · 앰버랫 포획 테스트", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 26), 18)
local status = label(panel, "3m 안의 앰버랫을 클릭하세요", UDim2.fromOffset(12, 40), UDim2.new(1, -24, 0, 34), 19)
local detail = label(panel, "WASD 이동 · 마우스 클릭으로 줄 던지기", UDim2.fromOffset(12, 78), UDim2.new(1, -24, 0, 24), 14)
local bar = make("Frame", { Name = "CaptureBar", Position = UDim2.new(0, 24, 0, 115), Size = UDim2.new(1, -48, 0, 26), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(241, 238, 228), Visible = false }, panel)
local yellow = make("Frame", { BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(250, 208, 65) }, bar)
local orange = make("Frame", { BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 116, 30) }, bar)
local marker = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 3, 1, 12), BackgroundColor3 = Color3.fromRGB(34, 31, 29), BorderSizePixel = 0, ZIndex = 3 }, bar)
local collection = label(panel, "이번 접속 앰버랫 포획: 0마리", UDim2.fromOffset(12, 156), UDim2.new(1, -24, 0, 24), 14, Color3.fromRGB(230, 190, 126))
label(gui, "앰버랫 B · 기본형 모델\n포획 기록은 이번 접속에서만 유지됩니다", UDim2.fromOffset(16, 12), UDim2.fromOffset(400, 54), 14)
local highlight = make("Highlight", { Enabled = false, FillTransparency = 0.85, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.Occluded }, gui)

local function targetMonster()
	local target = mouse.Target
	if not target then return nil end
	local model = target:FindFirstAncestorOfClass("Model")
	if model and model.Parent == monsters then return model end
	return nil
end

local function sendSteer()
	remote:FireServer("Steer", (right and 1 or 0) - (left and 1 or 0))
	lastSteer = os.clock()
end

local function inputAction(_, inputState, input)
	if inputState == Enum.UserInputState.Cancel then
		left, right = false, false
		sendSteer()
		return Enum.ContextActionResult.Sink
	end
	local down = inputState == Enum.UserInputState.Begin
	if inputState ~= Enum.UserInputState.Begin and inputState ~= Enum.UserInputState.End then
		return Enum.ContextActionResult.Sink
	end
	if UserInputService:GetFocusedTextBox() and down then return Enum.ContextActionResult.Pass end
	if input.KeyCode == Enum.KeyCode.A then left = down sendSteer() end
	if input.KeyCode == Enum.KeyCode.D then right = down sendSteer() end
	if input.KeyCode == Enum.KeyCode.Space and down and (phase == "Minigame" or phase == "Holding")
		and not pressed and os.clock() - lastPress >= 0.12 then
		pressed = true
		lastPress = os.clock()
		remote:FireServer("Press")
	end
	return Enum.ContextActionResult.Sink
end

local function toggleRide(active)
	local camera = workspace.CurrentCamera
	if active then
		if savedCameraType == nil then
			savedCameraType, savedCameraSubject = camera.CameraType, camera.CameraSubject
			ContextActionService:BindActionAtPriority("RodeoRide", inputAction, false, Enum.ContextActionPriority.High.Value + 1,
				Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.Space)
		end
		camera.CameraType = Enum.CameraType.Scriptable
	else
		ContextActionService:UnbindAction("RodeoRide")
		if savedCameraType then
			camera.CameraType = savedCameraType
			if savedCameraSubject and savedCameraSubject.Parent then camera.CameraSubject = savedCameraSubject end
		end
		savedCameraType, savedCameraSubject = nil, nil
		left, right = false, false
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or phase ~= "Idle" or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	local target = targetMonster()
	if target then remote:FireServer("Mount", target) end
end)
UserInputService.WindowFocusReleased:Connect(function()
	left, right = false, false
	if phase ~= "Idle" then sendSteer() end
end)
UserInputService.TextBoxFocused:Connect(function()
	left, right = false, false
	if phase ~= "Idle" then sendSteer() end
end)

remote.OnClientEvent:Connect(function(kind, data)
	if kind == "Notice" then
		status.Text, noticeUntil = data.message, os.clock() + 3
	elseif kind == "Judged" then
		marker.Position = UDim2.fromScale(data.position, 0.5)
	elseif kind == "State" then
		phase, started, pressed = data.phase, data.started, false
		captureAt = data.captureAt
		widths = data.widths or Config.Capture.First
		bar.Visible = phase == "Minigame" or phase == "Holding"
		yellow.Position, yellow.Size = UDim2.fromScale(widths.White, 0), UDim2.fromScale(widths.Yellow, 1)
		orange.Position, orange.Size = UDim2.fromScale(1 - widths.Orange, 0), UDim2.fromScale(widths.Orange, 1)
		collection.Text = string.format("이번 접속 앰버랫 포획: %d마리", data.count)
		noticeUntil = 0
		if data.message then status.Text, noticeUntil = data.message, os.clock() + 3 end
		toggleRide(phase ~= "Idle")
	end
end)

player.CharacterAdded:Connect(function()
	phase = "Idle"
	toggleRide(false)
	remote:FireServer("Sync")
end)

RunService.RenderStepped:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local elapsed = workspace:GetServerTimeNow() - started
	if pressed and os.clock() - lastPress > 0.75 then pressed = false end
	if phase == "Minigame" or phase == "Holding" then
		marker.Position = UDim2.fromScale(Rules.position(elapsed, Config.Prototype.BarRoundTripSeconds), 0.5)
	end
	if phase ~= "Idle" and root then
		local camera = workspace.CurrentCamera
		local goal = CFrame.lookAt(root.Position + Vector3.new(0, 12, 20), root.Position + Vector3.new(0, 0, -10))
		camera.CFrame = camera.CFrame:Lerp(goal, 1 - math.exp(-10 * dt))
		if os.clock() - lastSteer >= 0.15 then sendSteer() end
	end
	highlight.Enabled = false
	if phase == "Idle" then
		local target = targetMonster()
		if target and target.PrimaryPart and root then
			local distance = (target.PrimaryPart.Position - root.Position).Magnitude * Config.Prototype.MetersPerStud
			highlight.Adornee, highlight.Enabled = target, true
			local available = distance <= Config.Capture.JumpMeters and not target:GetAttribute("Occupied")
			highlight.OutlineColor = available and Color3.fromRGB(136, 229, 165) or Color3.fromRGB(245, 105, 89)
			detail.Text = string.format("앰버랫까지 %.1fm / 점프 범위 3m · 클릭하여 탑승", distance)
		else
			detail.Text = "WASD 이동 · 마우스 클릭으로 줄 던지기"
		end
		if os.clock() >= noticeUntil then status.Text = "3m 안의 앰버랫을 클릭하세요" end
	elseif phase == "Jumping" then
		status.Text, detail.Text = "줄을 던져 탑승 중…", "앰버랫"
	elseif phase == "Riding" then
		status.Text = string.format("미니게임까지 %.1f초", math.max(0, Config.Capture.RideSeconds - elapsed))
		detail.Text = "자동 전진 중 · A / D로 좌우 이동"
	elseif phase == "Minigame" then
		status.Text = pressed and "판정 중…" or "노란색이나 주황색에서 스페이스바!"
		detail.Text = string.format("흰색 %d%% 실패 · 노란색 %d%% 5초 버티기 · 주황색 %d%% 즉시 포획", math.floor(widths.White * 100 + 0.5), math.floor(widths.Yellow * 100 + 0.5), math.floor(widths.Orange * 100 + 0.5))
	elseif phase == "Holding" then
		status.Text = string.format("계속 버티세요! 포획까지 %.1f초", math.max(0, (captureAt or 0) - workspace:GetServerTimeNow()))
		detail.Text = "스페이스바 계속 판정 · 노란색: 유지 / 흰색: 낙하 / 주황색: 즉시 포획"
	end
end)

remote:FireServer("Sync")
