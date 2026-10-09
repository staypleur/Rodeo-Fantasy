local M={}
function M.new(playerGui,remote)
 local function make(class,props,parent)
  local node=Instance.new(class) for key,value in pairs(props) do node[key]=value end node.Parent=parent return node
 end
 local gui=make('ScreenGui',{Name='OperatorPasswordPrompt',DisplayOrder=1000,ResetOnSpawn=false,Enabled=false},playerGui)
 local cover=make('TextButton',{Text='',AutoButtonColor=false,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.35,BorderSizePixel=0,Modal=true},gui)
 local panel=make('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.45),Size=UDim2.new(.86,0,0,240),BackgroundColor3=Color3.fromRGB(247,232,203),BorderSizePixel=0},cover)
 make('UISizeConstraint',{MaxSize=Vector2.new(460,240)},panel) make('UICorner',{CornerRadius=UDim.new(0,12)},panel)
 local function label(text,y,height)
  return make('TextLabel',{Text=text,Position=UDim2.new(0,16,0,y),Size=UDim2.new(1,-32,0,height),BackgroundTransparency=1,TextColor3=Color3.fromRGB(61,57,40),Font=Enum.Font.GothamMedium,TextSize=16,TextWrapped=true},panel)
 end
 label('운영자 명령어 확인',12,30)
 local description=label('',45,40)
 local field=make('TextBox',{Name='Password',Text='',PlaceholderText='비밀번호 입력',ClearTextOnFocus=false,Position=UDim2.new(0,20,0,91),Size=UDim2.new(1,-40,0,44),BackgroundColor3=Color3.fromRGB(255,249,232),BorderSizePixel=0,TextTransparency=1,Font=Enum.Font.Gotham,TextSize=18,TextXAlignment=Enum.TextXAlignment.Left},panel)
 make('UICorner',{CornerRadius=UDim.new(0,7)},field)
 local mask=make('TextLabel',{Text='비밀번호 입력',Size=UDim2.new(1,-24,1,0),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=18,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=Color3.fromRGB(51,57,44)},field)
 field:GetPropertyChangedSignal('Text'):Connect(function() mask.Text=#field.Text==0 and '비밀번호 입력' or string.rep('●',math.min(utf8.len(field.Text) or #field.Text,64)) end)
 local status=label('',139,36)
 local confirm=make('TextButton',{Text='확인',Position=UDim2.new(.5,6,0,185),Size=UDim2.new(.5,-26,0,42),BackgroundColor3=Color3.fromRGB(91,128,77),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=17,BorderSizePixel=0},panel)
 local cancel=make('TextButton',{Text='닫기',Position=UDim2.new(0,20,0,185),Size=UDim2.new(.5,-26,0,42),BackgroundColor3=Color3.fromRGB(210,185,140),TextColor3=Color3.fromRGB(61,57,40),Font=Enum.Font.GothamBold,TextSize=17,BorderSizePixel=0},panel)
 local nonce,busy=nil,false
 local function clear() field.Text='' field:ReleaseFocus() end
 local function submit()
  if not nonce or busy or #field.Text==0 then return end
  if #field.Text>256 then status.Text='비밀번호 입력이 너무 깁니다.' return end
  busy=true status.Text='확인 중…'
  local password=field.Text clear()
  remote:FireServer('OperatorVerify',{token=nonce,password=password})
  password=nil
 end
 confirm.Activated:Connect(submit)
 field.FocusLost:Connect(function(enter) if enter then submit() end end)
 cancel.Activated:Connect(function() if nonce then remote:FireServer('OperatorCancel',nonce) end nonce=nil clear() gui.Enabled=false end)
 remote.OnClientEvent:Connect(function(kind,data)
  if kind=='OperatorPrompt' then
   nonce=data.token busy=false clear() description.Text=data.description status.Text='' confirm.Visible=true gui.Enabled=true field:CaptureFocus()
  elseif kind=='OperatorResult' then
   clear() busy=false status.Text=data.message gui.Enabled=true
   if data.ok or not data.retry then nonce=nil confirm.Visible=false end
  end
 end)
 return gui
end
return M
