-- Run with Studio's documented --task RunScript option in the generated place.
local package = game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
assert(package, "RodeoFantasy package missing")
local config = require(package.Config)
local rules = require(package.CaptureRules)
assert(config.Monster.Id == "Emberrat")
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
clone:Destroy()
print("RODEO_STUDIO_SMOKE_PASS: Emberrat B parts, flames, hierarchy and complete model pivot validated")
