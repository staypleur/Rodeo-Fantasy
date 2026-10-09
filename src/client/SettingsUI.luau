local UI={}
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local function make(kind,props,parent)
 local node=Instance.new(kind)
 for k,v in pairs(props) do node[k]=v end
 node.Parent=parent return node
end
local function round(node,radius)
 make("UICorner",{CornerRadius=UDim.new(0,radius or 10)},node)
end
function UI.new(gui,audio)
 local self={}
 local ink=Color3.fromRGB(43,74,55)
 local button=make("TextButton",{Name="OpenSettings",Text="Settings",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(255,245,219),BackgroundColor3=ink,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,12),Size=UDim2.fromOffset(96,38),ZIndex=30},gui)
 round(button)
 local window=make("Frame",{Name="AudioSettings",Visible=false,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,60),Size=UDim2.new(.9,0,0,252),BackgroundColor3=Color3.fromRGB(249,242,222),BorderSizePixel=0,ZIndex=40,Active=true},gui)
 make("UISizeConstraint",{MaxSize=Vector2.new(370,252)},window) round(window,16)
 make("UIStroke",{Color=Color3.fromRGB(177,155,112),Thickness=1},window)
 local function label(value,pos,size,font)
  return make("TextLabel",{Text=value,Position=pos,Size=size,BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=font or 16,TextColor3=ink,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=41},window)
 end
 label("Sound settings",UDim2.fromOffset(18,12),UDim2.new(1,-82,0,32),21)
 local close=make("TextButton",{Name="CloseSettings",Text="×",Font=Enum.Font.GothamBold,TextSize=26,BackgroundTransparency=1,TextColor3=ink,Position=UDim2.new(1,-52,0,10),Size=UDim2.fromOffset(38,38),ZIndex=42},window)
 label("Hunting continues while settings are open",UDim2.fromOffset(18,213),UDim2.new(1,-36,0,28),11)
 local drag,connections=nil,{}
 local function listen(signal,callback) connections[#connections+1]=signal:Connect(callback) end
 local function row(kind,title,y)
  label(title,UDim2.fromOffset(18,y),UDim2.new(.7,0,0,28))
  local value=label("",UDim2.new(1,-74,0,y),UDim2.fromOffset(56,28))
  value.Name=kind.."Volume" value.TextXAlignment=Enum.TextXAlignment.Right
  local minus=make("TextButton",{Name=kind.."Down",Text="−",Font=Enum.Font.GothamBold,TextSize=24,TextColor3=ink,BackgroundColor3=Color3.fromRGB(231,219,191),Position=UDim2.fromOffset(18,y+29),Size=UDim2.fromOffset(34,36),ZIndex=42},window) round(minus,8)
  local plus=minus:Clone() plus.Name=kind.."Up" plus.Text="+" plus.Position=UDim2.new(1,-52,0,y+29) plus.Parent=window
  local track=make("TextButton",{Name=kind.."Slider",Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromOffset(65,y+29),Size=UDim2.new(1,-130,0,36),ZIndex=42},window)
  local base=make("Frame",{Position=UDim2.new(0,0,.5,-4),Size=UDim2.new(1,0,0,8),BackgroundColor3=Color3.fromRGB(221,207,171),BorderSizePixel=0,ZIndex=42},track) round(base,4)
  local fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(92,147,116),BorderSizePixel=0,ZIndex=43},base) round(fill,4)
  local knob=make("Frame",{Name="Thumb",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(1,.5),Size=UDim2.fromOffset(20,20),BackgroundColor3=Color3.fromRGB(255,250,237),BorderSizePixel=0,ZIndex=44},base) round(knob,10)
  make("UIStroke",{Color=Color3.fromRGB(92,147,116),Thickness=2},knob)
  local function set(amount)
   audio.setVolume(kind,amount)
   local current=audio.getVolume(kind)
   value.Text=tostring(math.floor(current*100+.5)).."%"
   fill.Size=UDim2.fromScale(current,1) knob.Position=UDim2.fromScale(current,.5)
  end
  local function pointer(x)
   if track.AbsoluteSize.X>0 then set((x-track.AbsolutePosition.X)/track.AbsoluteSize.X) end
  end
  listen(minus.Activated,function() set(audio.getVolume(kind)-.05) end)
  listen(plus.Activated,function() set(audio.getVolume(kind)+.05) end)
  listen(track.InputBegan,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
    drag={input=input,pointer=pointer} pointer(input.Position.X)
   end
  end)
  listen(UIS.InputBegan,function(input)
   if not window.Visible or GuiService.SelectedObject~=track then return end
   if input.KeyCode==Enum.KeyCode.Left or input.KeyCode==Enum.KeyCode.DPadLeft then set(audio.getVolume(kind)-.05)
   elseif input.KeyCode==Enum.KeyCode.Right or input.KeyCode==Enum.KeyCode.DPadRight then set(audio.getVolume(kind)+.05) end
  end)
  set(audio.getVolume(kind))
 end
 row("Music","Background music",54) row("Effects","Sound effects",134)
 function self.close() window.Visible=false drag=nil end
 function self.isOpen() return window.Visible end
 listen(button.Activated,function()
  if window.Visible then self.close() else
   if self.onOpen then self.onOpen() end
   window.Visible=true
  end
 end)
 listen(close.Activated,self.close)
 listen(UIS.InputChanged,function(input)
  if drag and (input==drag.input or (drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement)) then drag.pointer(input.Position.X) end
 end)
 listen(UIS.InputEnded,function(input)
  if drag and (input==drag.input or (drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1)) then drag=nil end
 end)
 listen(UIS.WindowFocusReleased,function() drag=nil end)
 listen(window.Destroying,function() for _,connection in ipairs(connections) do connection:Disconnect() end end)
 return self
end
return UI
