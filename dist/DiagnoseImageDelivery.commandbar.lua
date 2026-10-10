-- Temporary image controls separate asset delivery from imported PBR generation.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local gui=Instance.new("ScreenGui") gui.Name="RodeoImageDeliveryCheck"
gui.Parent=game:GetService("CoreGui")
local rows={{"IncubatorColor","128153809027742"},{"PawButton","85966265063532"}}
for i,row in ipairs(rows) do
 local image=Instance.new("ImageLabel") image.Name=row[1]
 image.Size=UDim2.fromOffset(100,100) image.Position=UDim2.fromOffset(320+(i-1)*120,180)
 image.BackgroundColor3=Color3.fromRGB(30,30,30) image.Image="rbxassetid://"..row[2] image.Parent=gui
 row[3]=image
end
task.delay(15,function()
 for _,row in ipairs(rows) do print("DIRECT_IMAGE_LOAD",row[1],row[2],row[3].IsLoaded) end
 gui:Destroy()
end)
print("DIRECT_IMAGE_LOAD_CHECK_STARTED — 15초 후 두 이미지의 실제 IsLoaded 상태를 출력합니다.")
