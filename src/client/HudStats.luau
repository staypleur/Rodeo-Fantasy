local H={}
local Icons=require(script.Parent:WaitForChild("HudIcons"))
function H.new(gui)
 local root=Instance.new("Frame") root.Name="LobbyStats" root:SetAttribute("BottomHud",true) root.AnchorPoint=Vector2.new(0,1)
 root.Position=UDim2.new(0,8,1,-8) root.Size=UDim2.fromOffset(240,82) root.BackgroundTransparency=1 root.Parent=gui
 local function label(name,y,color)
  local n=Instance.new("TextLabel") n.Name=name n.Position=UDim2.fromOffset(48,y) n.Size=UDim2.fromOffset(186,40) n.BackgroundTransparency=1
  n.Text="0" n.TextColor3=color n.TextStrokeColor3=Color3.new(0,0,0) n.TextStrokeTransparency=0 n.Font=Enum.Font.GothamBlack n.TextSize=30 n.TextXAlignment=Enum.TextXAlignment.Left n.Parent=root return n
 end
 local count=label("BagCount",0,Color3.new(1,1,1));local money=label("MoneyCount",42,Color3.fromRGB(54,255,9))
 local cash=Icons.draw(root,"Money",40) cash.Position=UDim2.fromOffset(0,42)
 local face=Instance.new("ImageLabel") face.Name="MossratFace" face.Size=UDim2.fromOffset(40,40) face.BackgroundTransparency=1 face.Parent=root
 local package=game.ReplicatedStorage.RodeoFantasy
 face.Image=Icons.imageId(package,"MossratFaceImage")
 -- Native fallback until the prepared transparent PNG is uploaded once.
 local fallback=Instance.new("Frame") fallback.Name="FaceFallback" fallback.BackgroundTransparency=1 fallback.Size=UDim2.fromScale(1,1) fallback.Visible=face.Image=="" fallback.Parent=face
 for _,v in ipairs({{.02,.03,.32,.6},{.66,.03,.32,.6},{.2,.28,.6,.65}}) do
  local f=Instance.new("Frame") f.Position=UDim2.fromScale(v[1],v[2]) f.Size=UDim2.fromScale(v[3],v[4]) f.BackgroundColor3=Color3.fromRGB(141,201,56) f.BorderSizePixel=0 f.Parent=fallback
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(.3,0) c.Parent=f
 end
 for _,x in ipairs({.33,.6}) do local eye=Instance.new("Frame") eye.Position=UDim2.fromScale(x,.5) eye.Size=UDim2.fromScale(.12,.17) eye.BackgroundColor3=Color3.fromRGB(36,30,21) eye.BorderSizePixel=0 eye.Parent=fallback end
 game.ReplicatedStorage.RodeoFantasy:GetAttributeChangedSignal("MossratFaceImage"):Connect(function()
  face.Image=Icons.imageId(package,"MossratFaceImage") fallback.Visible=face.Image==""
 end)
 local function short(n)
  n=math.max(0,tonumber(n) or 0)
  for _,v in ipairs({{1e9,"B"},{1e6,"M"},{1e3,"K"}}) do if n>=v[1] then return string.format("%.1f%s",n/v[1],v[2]):gsub("%.0([KMB])","%1") end end
  return tostring(math.floor(n))
 end
 return {state=function(data) count.Text=short(data.count) money.Text="$"..short((data.balance or 0)+(data.pending or 0)) end}
end
return H
