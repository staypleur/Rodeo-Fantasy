-- Reconnect the user's uploaded color image. No mesh import or image upload.
assert(not game:GetService("RunService"):IsRunning(), "Play를 중지하세요.")
local asset = game:GetService("InsertService"):LoadAsset(88970410075115)
local decal = asset:FindFirstChildWhichIsA("Decal", true)
if not decal then asset:Destroy() error("색상 업로드에서 Decal을 찾지 못했습니다.") end
local image = decal.Texture
if image == "" then image = decal.ColorMap end
asset:Destroy()
assert(image ~= "" and image:match("^rbxassetid://%d+$"), "실제 이미지 주소를 확인하지 못했습니다: " .. tostring(image))
local rs = game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
assert(rs, "RodeoFantasy-New 맵을 열어 주세요.")
local roots = {}
for _, name in ipairs({"VisualTemplate", "MeshyMossratHuntTemplate"}) do
    local root = rs:FindFirstChild(name)
    if root then table.insert(roots, root) end
end
local template = game:GetService("ServerStorage"):FindFirstChild("RodeoMonsterTemplate")
if template then table.insert(roots, template) end
local preview = workspace:FindFirstChild("InstalledMossratPreview")
if preview then table.insert(roots, preview) end
local surfaces = {}
for _, root in ipairs(roots) do
    for _, part in ipairs(root:GetDescendants()) do
        if part:IsA("MeshPart") and part.MeshId == "rbxassetid://112233757801076" then
            local surface = part:FindFirstChildOfClass("SurfaceAppearance")
            assert(surface, "SurfaceAppearance 없음: " .. part:GetFullName())
            table.insert(surfaces, {surface = surface, before = surface.ColorMap})
        end
    end
end
assert(#surfaces > 0, "설치된 모스랫 재질이 없습니다.")
game:GetService("ChangeHistoryService"):SetWaypoint("Before Mossrat color repair")
local ok, err = pcall(function()
    for _, entry in ipairs(surfaces) do entry.surface.ColorMap = image end
end)
if not ok then
    for _, entry in ipairs(surfaces) do entry.surface.ColorMap = entry.before end
    error(err)
end
game:GetService("ChangeHistoryService"):SetWaypoint("Mossrat color repaired")
print("MOSSRAT_COLOR_CONNECTED", image, "재질 수:", #surfaces, "— 초록색 표시 확인 후 Ctrl+S. 이 메시지는 이미지 로딩 완료를 보장하지 않습니다.")
