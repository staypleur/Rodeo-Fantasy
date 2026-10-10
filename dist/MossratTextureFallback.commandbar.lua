-- Test the existing uploaded image, then use the original UV with a basic texture.
assert(not game:GetService("RunService"):IsRunning(), "Play를 중지하세요.")
local asset = game:GetService("InsertService"):LoadAsset(88970410075115)
local decal = asset:FindFirstChildWhichIsA("Decal", true)
assert(decal, "업로드한 색상 Decal 없음")
local image = decal.ColorMap
if image == "" then image = decal.Texture end
assert(image ~= "", "색상 이미지 주소 없음")
local probe = Instance.new("Decal") probe.Texture = image
local loaded = false
game:GetService("ContentProvider"):PreloadAsync({probe}, function(id, status)
    print("MOSSRAT_IMAGE_FETCH", id, status.Name)
    if status == Enum.AssetFetchStatus.Success then loaded = true end
end)
probe:Destroy() asset:Destroy()
assert(loaded, "MOSSRAT_IMAGE_FAILED — 색상 이미지 로딩 실패. 위 MOSSRAT_IMAGE_FETCH 문장을 보내주세요. 기존 재질은 수정하지 않았습니다.")
local rs = assert(game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy"), "새 맵 없음")
local roots = {}
for _, name in ipairs({"VisualTemplate", "MeshyMossratHuntTemplate"}) do
    local root = rs:FindFirstChild(name) if root then table.insert(roots, root) end
end
local ss = game:GetService("ServerStorage")
for _, root in ipairs({ss, workspace}) do
    local model = root:FindFirstChild(root == ss and "RodeoMonsterTemplate" or "InstalledMossratPreview")
    if model then table.insert(roots, model) end
end
local parts = {}
for _, root in ipairs(roots) do
    for _, part in ipairs(root:GetDescendants()) do
        if part:IsA("MeshPart") and part.MeshId == "rbxassetid://112233757801076" then table.insert(parts, part) end
    end
end
assert(#parts > 0, "설치된 모스랫 없음")
game:GetService("ChangeHistoryService"):SetWaypoint("Before Mossrat texture fallback")
local backup = Instance.new("Folder") backup.Name = "MossratTextureBackup_" .. game:GetService("HttpService"):GenerateGUID(false) backup.Parent = ss
for _, part in ipairs(parts) do
    local record = Instance.new("Folder") record.Name = part.Parent.Name record.Parent = backup
    local ref = Instance.new("ObjectValue") ref.Name = "OriginalPart" ref.Value = part ref.Parent = record
    record:SetAttribute("TextureID", part.TextureID) record:SetAttribute("Color", part.Color)
    local surface = part:FindFirstChildOfClass("SurfaceAppearance")
    if surface then surface.Parent = record end
    part.Color = Color3.new(1, 1, 1) part.TextureID = image
end
game:GetService("ChangeHistoryService"):SetWaypoint("Mossrat texture fallback")
print("MOSSRAT_BASIC_TEXTURE_CONNECTED", image, #parts, "— 초록색 표시 확인 후 Ctrl+S. 기존 PBR 재질은 ServerStorage에 보관했습니다.")
