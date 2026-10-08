local P={}
local Themes=require(game.ReplicatedStorage.RodeoFantasy.LevelTheme)
local function rgb(v) return Color3.fromRGB(table.unpack(v)) end
local function node(kind,name,props,parent)
 local n=Instance.new(kind) n.Name=name
 for k,v in pairs(props) do n[k]=v end n.Parent=parent return n
end
function P.update(gui,level,name)
 local theme,tier=Themes.forLevel(level)
 if gui:GetAttribute("ThemeTier")~=tier then
  gui:ClearAllChildren() gui:SetAttribute("ThemeTier",tier) gui:SetAttribute("Theme",theme.name)
  local function block(name,x,y,w,h,color,z)
   return node("Frame",name,{BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=color,ZIndex=z or 1},gui)
  end
  local edge,metal,paper=rgb(theme.edge),rgb(theme.metal),rgb(theme.paper)
  block("Shadow",18,21,264,32,Color3.fromRGB(32,30,40))
  block("Outer",16,18,268,32,edge)
  block("Bevel",19,20,262,28,metal)
  block("Inset",25,25,250,19,paper,2)
  block("TopGlint",20,20,260,2,metal:Lerp(Color3.new(1,1,1),.5),3)
  for _,side in ipairs({0,1}) do
   local x=side==0 and 7 or 279
   block("Wing",x,23,14,22,edge)
   block("WingFace",x+2,24,10,18,metal,2)
   for j=0,2 do block("WingCarving",x+3,27+j*5,7,2,paper,3) end
  end
  block("CrownBase",124,10,52,7,edge)
  block("CrownMetal",127,11,46,4,metal,2)
  for _,x in ipairs({124,146,168}) do
   block("CrownPoint",x,4,8,10,edge)
   block("CrownLight",x+2,5,4,7,metal,2)
  end
  if tier>=5 then
   local jewel=block("Jewel",147,9,7,7,tier==8 and Color3.fromRGB(255,78,107) or Color3.fromRGB(152,255,235),4)
   jewel.Rotation=45
  end
  if tier==9 then
   for j=0,5 do block("Star",32+j*44,22+(j%2)*19,2,2,Color3.fromRGB(229,210,255),4) end
  elseif tier==10 or tier==11 then
   for side=0,1 do
    for j=0,3 do block("Feather",side==0 and 1+j*3 or 292-j*3,15+j*3,8,3,Color3.fromRGB(235,248,255),3) end
   end
  end
  if tier==11 then
   local colors={Color3.fromRGB(247,110,115),Color3.fromRGB(255,188,93),Color3.fromRGB(255,230,127),Color3.fromRGB(112,216,173),Color3.fromRGB(111,191,245),Color3.fromRGB(163,137,248),Color3.fromRGB(231,157,226)}
   local seq={} for i,c in ipairs(colors) do seq[i]=ColorSequenceKeypoint.new((i-1)/6,c) end
   node("UIGradient","Rainbow",{Color=ColorSequence.new(seq)},gui.Bevel)
   for i,c in ipairs(colors) do block("RainbowGem",36+(i-1)*36,46,15,3,c,4) end
  end
  local props={BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextColor3=rgb(theme.ink),ZIndex=5}
  local number=node("TextLabel","Level",props,gui)
  number.Position=UDim2.fromOffset(31,20) number.Size=UDim2.fromOffset(48,27) number.TextSize=21
  local account=node("TextLabel","PlayerName",props,gui)
  account.Position=UDim2.fromOffset(82,21) account.Size=UDim2.fromOffset(188,25)
  account.TextSize=17 account.TextXAlignment=Enum.TextXAlignment.Left account.TextTruncate=Enum.TextTruncate.AtEnd
 end
 gui.Level.Text=tostring(level) gui.PlayerName.Text=name
end
return P
