local M={}
function M.ensure(lobby)
 local boards=lobby:FindFirstChild("Leaderboards")
 if not boards then boards=Instance.new("Folder") boards.Name="Leaderboards" boards.Parent=lobby end
 local center=Vector3.new(6000,0,0)
 local airport=lobby:FindFirstChild("Airport")
 local rocket=airport and airport:FindFirstChild("Rocket")
 if rocket and rocket:IsA("Model") then local cf=rocket:GetBoundingBox() center=Vector3.new(cf.X,0,cf.Z) end
 for i,entry in ipairs({{"Distance","최고 거리"},{"Income","도감 수집"}}) do
  local board=boards:FindFirstChild(entry[1])
  if not board then
   board=Instance.new("Part") board.Name=entry[1] board.Size=Vector3.new(26,30,2)
   board.Anchored=true board.Material=Enum.Material.SmoothPlastic board.Color=Color3.fromRGB(24,38,64)
   board.TopSurface=Enum.SurfaceType.Smooth board.BottomSurface=Enum.SurfaceType.Smooth board.Parent=boards
  end
  local target=CFrame.new(center+Vector3.new(i==1 and -54 or 54,23,-16))
  if board:IsA("BasePart") then board.CFrame=target elseif board:IsA("Model") then board:PivotTo(target) end
  local gui=board:FindFirstChild("Ranking")
  if not gui then
   gui=Instance.new("SurfaceGui") gui.Name="Ranking" gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(780,900) gui.Parent=board
   for _,spec in ipairs({{"Heading",0,120,entry[2],52},{"Entries",140,740,"기록을 불러오는 중입니다.",34}}) do
    local text=Instance.new("TextLabel") text.Name=spec[1] text.Position=UDim2.fromOffset(24,spec[2]) text.Size=UDim2.new(1,-48,0,spec[3])
    text.Text=spec[4] text.TextSize=spec[5] text.TextWrapped=true text.Font=Enum.Font.GothamBold text.BackgroundTransparency=1
    text.TextColor3=spec[1]=="Heading" and Color3.fromRGB(126,219,255) or Color3.fromRGB(229,240,255)
    text.TextYAlignment=Enum.TextYAlignment.Top text.Parent=gui
   end
  end
 end
 return boards
end
return M
