local E={}
local Tween=game:GetService("TweenService")
local active={}
local function content(parent,amount)
 local label=Instance.new("TextLabel") label.Name="GainAmount"
 label.BackgroundTransparency=1 label.Size=UDim2.new(1,-30,1,0) label.Position=UDim2.fromOffset(30,0)
 label.Text="+"..amount label.TextSize=28 label.Font=Enum.Font.GothamBlack
 label.TextColor3=Color3.fromRGB(255,230,117) label.TextStrokeColor3=Color3.fromRGB(44,64,39) label.TextStrokeTransparency=0
 label.ZIndex=parent:IsA("GuiObject") and parent.ZIndex+1 or 2 label.Parent=parent
 local coin=Instance.new("ImageLabel") coin.Name="MoneyGainIcon" coin.Size=UDim2.fromOffset(28,28) coin.Position=UDim2.new(0,0,.5,-14)
 coin.BackgroundTransparency=1 coin.ScaleType=Enum.ScaleType.Fit coin.ZIndex=label.ZIndex
 coin.Image=require(script.Parent:WaitForChild("HudIcons")).imageId(game.ReplicatedStorage.RodeoFantasy,"MoneyImage") coin.Parent=parent
 return label,coin
end
local function animate(node,amount,goal)
 active[node]=true
 local label,coin=content(node,amount)
 local info=TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 local motion=Tween:Create(node,info,goal) motion:Play()
 Tween:Create(label,info,{TextTransparency=1,TextStrokeTransparency=1}):Play()
 Tween:Create(coin,info,{ImageTransparency=1}):Play()
 motion.Completed:Connect(function() active[node]=nil node:Destroy() end)
 return node
end
function E.card(card,amount)
 local node=Instance.new("Frame") node.Name="CoinGain" node.AnchorPoint=Vector2.new(.5,.5)
 node.Position=UDim2.new(.5,0,0,93) node.Size=UDim2.fromOffset(100,38) node.BackgroundTransparency=1 node.ZIndex=30 node.Parent=card
 return animate(node,amount,{Position=UDim2.new(.5,0,0,38)})
end
function E.pet(model,amount)
 local node=Instance.new("BillboardGui") node.Name="PetCoinGain" node.Adornee=model.PrimaryPart
 local height=math.max(3,model:GetExtentsSize().Y*.5+.7)
 node.Size=UDim2.fromOffset(108,45) node.StudsOffset=Vector3.new(0,height,0) node.AlwaysOnTop=true node.MaxDistance=120 node.Parent=model.PrimaryPart
 return animate(node,amount,{StudsOffset=Vector3.new(0,height+2,0)})
end
function E.clear()
 for node in pairs(active) do node:Destroy() end table.clear(active)
end
return E
