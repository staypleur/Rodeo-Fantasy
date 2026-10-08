local P={}
local Themes=require(game.ReplicatedStorage.RodeoFantasy.LevelTheme)
local TextService=game:GetService("TextService")
local function rgb(v) return Color3.fromRGB(table.unpack(v)) end
local function node(kind,name,props,parent)
 local n=Instance.new(kind) n.Name=name
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
function P.update(gui,level,name)
 local theme,tier=Themes.forLevel(level)
 local levelWidth=math.max(20,math.ceil(TextService:GetTextSize(tostring(level),21,Enum.Font.GothamBold,Vector2.new(1000,100)).X)+4)
 local nameWidth=math.ceil(TextService:GetTextSize(name,17,Enum.Font.GothamBold,Vector2.new(1000,100)).X)+4
 local nameX=31+levelWidth+10
 local width=math.max(140,nameX+nameWidth+30)
 gui:SetAttribute("NameplateRevision",3)
 gui.Size=UDim2.fromOffset(math.ceil(width*.6),35)
 if gui:GetAttribute("ThemeTier")~=tier or gui:GetAttribute("LayoutWidth")~=width or gui:GetAttribute("LevelWidth")~=levelWidth then
  gui:ClearAllChildren() gui:SetAttribute("ThemeTier",tier) gui:SetAttribute("Theme",theme.name)
  gui:SetAttribute("LayoutWidth",width) gui:SetAttribute("LevelWidth",levelWidth)
  local canvas=node("Frame","PlaqueCanvas",{BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(width,58)},gui)
  local scale=Instance.new("UIScale") scale.Name="CompactPlaqueScale" scale.Scale=.6 scale.Parent=canvas
  local function block(name,x,y,w,h,color,z)
   return node("Frame",name,{BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,ZIndex=z or 1},canvas)
  end
  local edge,metal,paper=rgb(theme.edge),rgb(theme.metal),rgb(theme.paper)
  block("Shadow",18,21,width-36,32,Color3.fromRGB(32,30,40))
  block("Outer",16,18,width-32,32,edge)
  block("Bevel",19,20,width-38,28,metal)
  block("Inset",25,25,width-50,19,paper,2)
  block("TopGlint",20,20,width-40,2,metal:Lerp(Color3.new(1,1,1),.5),3)
  for _,side in ipairs({0,1}) do
   local x=side==0 and 7 or width-21
   block("Wing",x,23,14,22,edge)
   block("WingFace",x+2,24,10,18,metal,2)
   for j=0,2 do block("WingCarving",x+3,27+j*5,7,2,paper,3) end
  end
  block("CrownBase",width/2-26,10,52,7,edge)
  block("CrownMetal",width/2-23,11,46,4,metal,2)
  for _,x in ipairs({width/2-26,width/2-4,width/2+18}) do
   block("CrownPoint",x,4,8,10,edge)
   block("CrownLight",x+2,5,4,7,metal,2)
  end
  if tier>=5 then
   local jewel=block("Jewel",width/2-3,9,7,7,tier==8 and Color3.fromRGB(255,78,107) or Color3.fromRGB(152,255,235),4)
   jewel.Rotation=45
  end
  if tier==9 then
   for j=0,5 do block("Star",32+j*(width-64)/5,22+(j%2)*19,2,2,Color3.fromRGB(229,210,255),4) end
  elseif tier==10 or tier==11 then
   for side=0,1 do
    for j=0,3 do block("Feather",side==0 and 1+j*3 or width-8-j*3,15+j*3,8,3,Color3.fromRGB(235,248,255),3) end
   end
  end
  if tier==11 then
   local colors={Color3.fromRGB(247,110,115),Color3.fromRGB(255,188,93),Color3.fromRGB(255,230,127),Color3.fromRGB(112,216,173),Color3.fromRGB(111,191,245),Color3.fromRGB(163,137,248),Color3.fromRGB(231,157,226)}
   local seq={} for i,c in ipairs(colors) do seq[i]=ColorSequenceKeypoint.new((i-1)/6,c) end
   node("UIGradient","Rainbow",{Color=ColorSequence.new(seq)},canvas.Bevel)
   for i,c in ipairs(colors) do block("RainbowGem",30+(i-1)*(width-60)/7,46,(width-60)/7-3,3,c,4) end
  end
  local props={BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextColor3=rgb(theme.ink),ZIndex=5}
  local number=node("TextLabel","Level",props,canvas)
  number.Position=UDim2.fromOffset(31,20) number.Size=UDim2.fromOffset(levelWidth,27) number.TextSize=21
  local account=node("TextLabel","PlayerName",props,canvas)
  account.Position=UDim2.fromOffset(nameX,21) account.Size=UDim2.fromOffset(nameWidth,25)
  account.TextSize=17 account.TextXAlignment=Enum.TextXAlignment.Left account.TextTruncate=Enum.TextTruncate.AtEnd
 end
 local canvas=gui:FindFirstChild("PlaqueCanvas")
 if canvas then canvas.Level.Text=tostring(level) canvas.PlayerName.Text=name end
end
return P
