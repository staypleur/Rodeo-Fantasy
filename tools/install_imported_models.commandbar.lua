-- Run once from the Roblox Studio Command Bar after importing all 20 GLBs.
-- Put the imported Models under Workspace.ImportedCreatureModels first.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local package = ReplicatedStorage:WaitForChild("RodeoFantasy")
local catalog = require(package:WaitForChild("MonsterCatalog"))
local imported = workspace:WaitForChild("ImportedCreatureModels")
local species = {"MeadowMouse", "GrassBoar", "TreeWolf", "RockElephant", "Weedcrow"}
local starsList = {1, 3, 6, 9}
local install = {}

-- Validate the full batch before changing any existing template.
for _, id in ipairs(species) do
	for _, stars in ipairs(starsList) do
		local sourceName = id .. "_A_S" .. stars
		local source = imported:FindFirstChild(sourceName)
		assert(source and source:IsA("Model"), "Missing imported Model: " .. sourceName)
		local parts = {}
		for _, node in ipairs(source:GetDescendants()) do
			if node:IsA("MeshPart") then table.insert(parts, node) end
		end
		assert(#parts >= 10, sourceName .. " imported with too few MeshParts")
		assert(source:FindFirstChild("Body", true), sourceName .. " is missing the named Body mesh")
		local visual = package:FindFirstChild(catalog.visual(id, stars))
		local template = ServerStorage:FindFirstChild(catalog.template(id, stars))
		assert(visual and visual:IsA("Model"), "Missing visual template: " .. catalog.visual(id, stars))
		assert(template and template:IsA("Model"), "Missing server template: " .. catalog.template(id, stars))
		assert(visual:FindFirstChild("MountRoot") and template:FindFirstChild("MountRoot"), sourceName .. " template has no MountRoot")
		table.insert(install, {id=id, stars=stars, source=source, visual=visual, template=template, parts=parts})
	end
end

local function replaceGeometry(target, source, parts)
	local root = target:FindFirstChild("MountRoot")
	assert(root and root:IsA("BasePart"), target.Name .. " has no MountRoot")
	for _, child in ipairs(target:GetChildren()) do
		if child ~= root then child:Destroy() end
	end
	local sourcePivot = source:GetPivot()
	for _, sourcePart in ipairs(parts) do
		local mesh = sourcePart:Clone()
		mesh.Anchored = true
		mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
		mesh.CFrame = root.CFrame * sourcePivot:ToObjectSpace(sourcePart.CFrame)
		mesh.Parent = target
	end
	target.PrimaryPart = root
	target:SetAttribute("MeshDecorated", true)
end

for _, item in ipairs(install) do
	replaceGeometry(item.visual, item.source, item.parts)
	replaceGeometry(item.template, item.source, item.parts)
end

imported:Destroy()
print("Installed all 20 A-family models into the bag, journal, ranch and hunt templates.")
