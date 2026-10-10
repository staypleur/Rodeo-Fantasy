-- Run in Studio Command Bar in edit mode. Uses the installed model; no upload.
assert(not game:GetService("RunService"):IsRunning(), "Play를 중지하고 실행하세요.")
local source = assert(game:GetService("ServerStorage"):FindFirstChild("RodeoMonsterTemplate"), "저장된 모스랫이 없습니다. RodeoFantasy-New.rbxlx를 열어 주세요.")
local body = assert(source:FindFirstChildWhichIsA("MeshPart", true), "설치된 MeshPart가 없습니다.")
assert(body.MeshId ~= "", "설치된 메시 주소가 없습니다.")
local bones = 0
for _, node in ipairs(source:GetDescendants()) do
    if node:IsA("Bone") then bones += 1 end
end
assert(bones > 0, "설치된 뼈대가 없습니다.")
local copy = source:Clone()
copy.Name = "InstalledMossratPreview"
for _, node in ipairs(copy:GetDescendants()) do
    if node:IsA("BasePart") then
        node.Anchored = true
        node.CanCollide = false
        node.CanTouch = false
        node.CanQuery = false
    end
end
copy:PivotTo(CFrame.new(6000, 6, -64))
local previous = workspace:FindFirstChild(copy.Name)
if previous then previous:Destroy() end
copy.Parent = workspace
game:GetService("Selection"):Set({copy})
print("INSTALLED_MOSSRAT_READY — 선택된 모스랫에 F를 눌러 확인하세요. 재업로드하지 않았습니다. 뼈:", bones, "메시:", body.MeshId)
