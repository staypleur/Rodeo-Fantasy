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
		local hasBody = false
		for _, node in ipairs(source:GetDescendants()) do
			if node:IsA("MeshPart") then
				assert(node.Name:match("^.-__C%x%x%x%x%x%x$"), sourceName .. " mesh name lost its color code: " .. node.Name)
				table.insert(parts, node)
				if node.Name:match("^Body__C%x%x%x%x%x%x$") then hasBody = true end
			end
		end
		assert(#parts >= 10, sourceName .. " imported with too few MeshParts")
		assert(hasBody, sourceName .. " is missing the named Body mesh")
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
		local groupName, rgb = sourcePart.Name:match("^(.-)__C(%x%x%x%x%x%x)$")
		assert(groupName and rgb, "Mesh node is missing its encoded color: " .. sourcePart.Name)
		mesh.Name = groupName
		mesh.Color = Color3.fromRGB(
			tonumber(string.sub(rgb, 1, 2), 16),
			tonumber(string.sub(rgb, 3, 4), 16),
			tonumber(string.sub(rgb, 5, 6), 16)
		)
		mesh.Material = Enum.Material.SmoothPlastic
		mesh.Anchored = true
		mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
		mesh.CFrame = root.CFrame * sourcePivot:ToObjectSpace(sourcePart.CFrame)
		mesh.Parent = target
	end
	target.PrimaryPart = root
	target:SetAttribute("MeshDecorated", true)
	target:SetAttribute("ImportedA", true)
end

for _, item in ipairs(install) do
	replaceGeometry(item.visual, item.source, item.parts)
	replaceGeometry(item.template, item.source, item.parts)
end

imported:Destroy()
print("Installed all 20 A-family models into the bag, journal, ranch and hunt templates.")
