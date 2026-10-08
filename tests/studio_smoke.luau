-- Run with Studio's documented --task RunScript option in the generated place.
local package = game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
assert(package, "RodeoFantasy package missing")
local config = require(package.Config)
local rules = require(package.CaptureRules)
assert(config.Monster.Id == "Emberrat")
local bagRules = require(package.BagRules)
local bag = bagRules.new()
bagRules.grant(bag, config.Monster.Id, 10)
bagRules.accrue(bag, 12, config.BagIncome.IncomeSeconds, config.BagIncome.IncomeAmount)
assert(bag.pending == 1 and #bag.monsters == 1)
assert(package:FindFirstChild("ZooRules") == nil and config.Zoo == nil)
assert(rules.zone(0.97, config.Capture.Repeat) == "Orange")
assert(package.CaptureRemote:IsA("RemoteEvent"))
assert(game:GetService("ServerScriptService").CaptureServer:IsA("Script"))
assert(game:GetService("StarterPlayer").StarterPlayerScripts.CaptureClient:IsA("LocalScript"))
local world = workspace.RodeoPrototype
assert(world.Spawn:IsA("SpawnLocation"))
assert(world.PreviewGround.Size.Z == 256)
local template = game:GetService("ServerStorage").RodeoMonsterTemplate
local clone = template:Clone()
clone:PivotTo(CFrame.new(0, 2, -8))
assert((clone.PrimaryPart.Position - Vector3.new(0, 2, -8)).Magnitude < 0.01)
assert(clone.PrimaryPart.Anchored)
assert(clone.PrimaryPart.Name == "MountRoot" and clone.PrimaryPart.Transparency == 1)
assert(clone.Body:FindFirstChild("Shape").MeshType == Enum.MeshType.Sphere)
assert(clone.LeftEar and clone.RightEar and clone.TailSegment5)
assert(clone.TailFlame.EmberFlame:IsA("Fire"))
assert(clone.HeadFlame.EmberFlame.Size == 2 and clone.HeadFlame.EmberFlame.Heat == 0.5)
local localTail = clone.PrimaryPart.CFrame:ToObjectSpace(clone.TailFlame.CFrame)
clone:PivotTo(CFrame.new(9, 2, -20) * CFrame.Angles(0, 0.4, 0))
local movedTail = clone.PrimaryPart.CFrame:ToObjectSpace(clone.TailFlame.CFrame)
assert((localTail.Position - movedTail.Position).Magnitude < 0.001, "tail must follow mount pivot")
for _, descendant in ipairs(clone:GetDescendants()) do
	if descendant:IsA("BasePart") then
		assert(descendant.Anchored and not descendant.CanCollide, "model must not block rider")
	end
end
local animator = require(game:GetService("StarterPlayer").StarterPlayerScripts.RideAnimator)
local testFolder = Instance.new("Folder")
testFolder.Name = "TemporaryAnimationTest"
testFolder.Parent = workspace
clone.Parent = testFolder
local rootBefore, legBefore = clone.PrimaryPart.CFrame, clone.LeftFrontLeg.CFrame
clone:SetAttribute("Running", true)
clone:SetAttribute("RunStarted", 0)
clone:SetAttribute("Steering", 1)
animator.update(testFolder, 0.1)
assert(clone.PrimaryPart.CFrame == rootBefore, "animation must preserve mount root")
assert((clone.LeftFrontLeg.Position - legBefore.Position).Magnitude > 0.01, "legs must animate")
assert(clone.TailFlame.Parent == clone, "flame must remain attached")
clone:SetAttribute("Running", false)
animator.update(testFolder, 0.2)
assert((clone.LeftFrontLeg.Position - legBefore.Position).Magnitude < 0.001, "idle must restore rest pose")
assert(clone.PrimaryPart.CFrame == rootBefore, "idle must preserve mount root")
clone:Destroy()
testFolder:Destroy()
print("RODEO_STUDIO_SMOKE_PASS: Emberrat B parts, flames, hierarchy, model pivot and ride animation validated")
