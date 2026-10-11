local A={}
local Players=game:GetService("Players")
local P=game.ReplicatedStorage:WaitForChild("RodeoFantasy")
local G=require(P.GomokuRules)
local function part(model,name,position,size,colour)
 local p=Instance.new("Part") p.Name=name p.Anchored=true p.Size=size p.Position=position
 p.Color=colour p.Material=Enum.Material.SmoothPlastic p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.CanTouch=false p.CastShadow=false p.Parent=model return p
end
function A.build(map)
 local existing=map:FindFirstChild("Activities")
 if existing and existing:GetAttribute("BuildVersion")==5 then return existing end
 if existing then existing:Destroy() end
 local folder=Instance.new("Folder") folder.Name="Activities" folder.Parent=map
 folder:SetAttribute("BuildVersion",5)
 for i,x in ipairs({-1055*1.15,1055*1.15}) do
  local z=-450*1.15
  local model=Instance.new("Model") model.Name="Gomoku"..i model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic model.Parent=folder
  local pos=Vector3.new(x-42,4.4,z-40)
  local top=part(model,"Board",pos,Vector3.new(10,.7,10),Color3.fromRGB(206,166,111)) model.PrimaryPart=top
  part(model,"Pedestal",pos-Vector3.new(0,1.5,0),Vector3.new(3,3,3),Color3.fromRGB(75,49,70))
  local grid=Instance.new("SurfaceGui") grid.Name="BoardGrid" grid.Face=Enum.NormalId.Top grid.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize grid.CanvasSize=Vector2.new(512,512) grid.ZOffset=.05 grid.LightInfluence=0 grid.Active=false grid.Parent=top
  for n=0,14 do
   local offset=.1+n*.8/14
   for _,vertical in ipairs({true,false}) do
    local line=Instance.new("Frame") line.Name="Grid" line.BorderSizePixel=0 line.BackgroundColor3=Color3.fromRGB(50,36,28)
    line.Position=vertical and UDim2.new(offset,-1,.1,0) or UDim2.new(.1,0,offset,-1)
    line.Size=vertical and UDim2.new(0,2,.8,0) or UDim2.new(.8,0,0,2) line.Parent=grid
   end
  end
  for _,sign in ipairs({-1,1}) do
   local seat=Instance.new("Seat") seat.Name="PlayerSeat"..(sign==-1 and "1" or "2") seat.Anchored=true seat.Size=Vector3.new(3,.7,3)
   seat.CFrame=CFrame.lookAt(pos+Vector3.new(0,-1,sign*8),Vector3.new(pos.X,pos.Y-1,pos.Z))
   seat.Color=i==1 and Color3.fromRGB(236,158,190) or Color3.fromRGB(82,58,107) seat.Parent=model
  end
  local prompt=Instance.new("ProximityPrompt") prompt.Name="GomokuPrompt" prompt.ActionText="⚫ ⚪" prompt.ObjectText="Gomoku" prompt.HoldDuration=0 prompt.MaxActivationDistance=15 prompt.RequiresLineOfSight=false prompt.Parent=top
  local piano=Instance.new("Model") piano.Name="Piano"..i piano.ModelStreamingMode=Enum.ModelStreamingMode.Atomic piano.Parent=folder
  local anchor=part(piano,"Anchor",Vector3.new(x+42,4.4,z-65),Vector3.new(1,1,1),Color3.new()) anchor.Transparency=1 anchor.CanCollide=false piano.PrimaryPart=anchor
  local template=game.ServerStorage:FindFirstChild("CafePianoVisual")
  if template then
   local visual=template:Clone() visual.Parent=piano
   -- Use world-space geometry bounds. Source pivots can be attached to upside-down legs.
   local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
   for _,p in ipairs(visual:GetDescendants()) do if p:IsA("BasePart") then
    for _,dx in ipairs({-1,1}) do for _,dy in ipairs({-1,1}) do for _,dz in ipairs({-1,1}) do
     local point=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(dx,dy,dz)*.5)
     low=Vector3.new(math.min(low.X,point.X),math.min(low.Y,point.Y),math.min(low.Z,point.Z))
     high=Vector3.new(math.max(high.X,point.X),math.max(high.Y,point.Y),math.max(high.Z,point.Z))
    end end end
   end end
   local centre=(low+high)*.5
   visual:PivotTo(CFrame.new(anchor.Position.X,1.4,anchor.Position.Z)*CFrame.Angles(0,-math.pi/2,0)*CFrame.new(-centre.X,-low.Y,-centre.Z)*visual:GetPivot())
  else
   part(piano,"Body",anchor.Position+Vector3.new(0,1,-1.5),Vector3.new(11,5,3),Color3.fromRGB(45,28,46))
   for key=1,14 do part(piano,"Key",anchor.Position+Vector3.new(-5.2+(key-1)*.8,-.2,.5),Vector3.new(.75,.3,2),Color3.fromRGB(248,241,233)) end
  end
  -- Two octaves of actual white and black keys, sharing one small audio sample.
  local keyboard=Instance.new("Folder") keyboard.Name="Keyboard" keyboard.Parent=piano
  local whites={0,2,4,5,7,9,11,12,14,16,17,19,21,23}
  for n,semitone in ipairs(whites) do
   local key=part(keyboard,"WhiteKey",anchor.Position+Vector3.new(-3.25+(n-1)*.5,.38,4),Vector3.new(.48,.18,1.8),Color3.fromRGB(250,246,237))
   key:SetAttribute("Note",semitone+1) key.CanCollide=false
   if semitone%12~=4 and semitone%12~=11 then
    local black=part(keyboard,"BlackKey",key.Position+Vector3.new(.25,.15,-.35),Vector3.new(.29,.23,1.05),Color3.fromRGB(22,20,24))
    black:SetAttribute("Note",semitone+2) black.CanCollide=false
   end
  end
  local pianoSeat=Instance.new("Seat") pianoSeat.Name="PlayerSeat" pianoSeat.Anchored=true pianoSeat.Transparency=1 pianoSeat.Size=Vector3.new(2,.3,2)
  pianoSeat.CFrame=CFrame.lookAt(anchor.Position+Vector3.new(0,-.4,7),anchor.Position+Vector3.new(0,-.4,0)) pianoSeat.Parent=piano
  local promptP=Instance.new("ProximityPrompt") promptP.Name="PianoPrompt" promptP.ActionText="♫" promptP.ObjectText="Piano" promptP.HoldDuration=0 promptP.MaxActivationDistance=15 promptP.RequiresLineOfSight=false promptP.Parent=anchor
 end
 return folder
end
function A.start(map,canAct)
 local folder=A.build(map)
 local remote=P:FindFirstChild("CafeActivityRemote") or Instance.new("RemoteEvent") remote.Name="CafeActivityRemote" remote.Parent=P
 local sessions,stamps,noteBudget,joins={}, {},{},{}
 local snapshot
 local function clearStones(s)
  for _,stone in pairs(s.stones) do stone.Transparency=1 end
 end
 local function placeStone(s,x,y,colour)
  local index=(y-1)*15+x local stone=s.stones[index]
  if not stone then
   stone=part(s.model,"Stone",s.model.PrimaryPart.Position+Vector3.new(-4+(x-1)*8/14,.5,-4+(y-1)*8/14),Vector3.new(.48,.18,.48),Color3.new())
   stone.Shape=Enum.PartType.Cylinder stone.Size=Vector3.new(.18,.48,.48) stone.CFrame=CFrame.new(stone.Position)*CFrame.Angles(0,0,math.pi/2)
   stone.CanCollide=false stone.CanTouch=false stone.CanQuery=false s.stones[index]=stone
  end
  stone.Transparency=0 stone.Color=colour==1 and Color3.fromRGB(20,20,24) or Color3.fromRGB(248,248,243)
 end
 local function close(p)
  local s=sessions[p] if not s then return end sessions[p]=nil
  local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(s.model) then hum.Sit=false end
  if s.kind=="Gomoku" then
   for colour,who in pairs(s.players) do if who==p then s.players[colour]=nil end end
   s.board=G.new() clearStones(s) s.ready={} s.revision+=1
   for _,who in pairs(s.players) do snapshot(s,who) end
  else s.owner=nil end
  if p.Parent then remote:FireClient(p,"Close") end
 end
 local function nearby(p,s)
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  return canAct(p) and not p:GetAttribute("LobbyRiding") and root and hum and hum.Health>0 and (root.Position-s.model.PrimaryPart.Position).Magnitude<=24
 end
 snapshot=function(s,p)
  local cells={} for n=1,225 do cells[n]=s.board.cells[n] or 0 end
  local colour=s.players[1]==p and 1 or s.players[2]==p and 2 or 0
  remote:FireClient(p,"Board",{id=s.model.Name,cells=cells,turn=s.board.turn,winner=s.board.winner,revision=s.revision,colour=colour,players={s.players[1] and s.players[1].DisplayName or "…",s.players[2] and s.players[2].DisplayName or "…"}})
 end
 for _,model in ipairs(folder:GetChildren()) do
  local kind=model.Name:find("Gomoku") and "Gomoku" or "Piano"
  local s={model=model,kind=kind,board=G.new(),players={},stones={},revision=0}
  model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt").Triggered:Connect(function(p)
   if not nearby(p,s) then return end
   local clock=os.clock() if clock-(joins[p] or -math.huge)<.5 then return end joins[p]=clock
   if sessions[p]~=s then
    if kind=="Gomoku" and s.players[1] and s.players[2] or kind=="Piano" and s.owner and s.owner~=p then return end
    close(p) sessions[p]=s
    if kind=="Gomoku" then s.players[s.players[1] and 2 or 1]=p else s.owner=p end
   end
   local colour=s.players[1]==p and 1 or 2
   local seat=model:FindFirstChild(kind=="Gomoku" and "PlayerSeat"..colour or "PlayerSeat")
   local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if seat and hum then seat:Sit(hum) end
   if kind=="Gomoku" then for _,who in pairs(s.players) do snapshot(s,who) end else remote:FireClient(p,"Piano",{id=model.Name}) end
  end)
 end
 remote.OnServerEvent:Connect(function(p,action,x,y,revision)
  if action=="Leave" then close(p) return end
  local s=sessions[p] if not s or not nearby(p,s) then close(p) return end
  local now=os.clock()
  if action=="Note" then
   local budget=noteBudget[p] or {at=now,tokens=8} noteBudget[p]=budget
   budget.tokens=math.min(8,budget.tokens+(now-budget.at)*22) budget.at=now
   if budget.tokens<1 then return end budget.tokens-=1
  else
   if now-(stamps[p] or -math.huge)<.12 then return end stamps[p]=now
  end
  if action=="Move" and s.kind=="Gomoku" and s.players[1] and s.players[2] and revision==s.revision then
   local colour=s.players[1]==p and 1 or 2
   if G.move(s.board,colour,x,y) then placeStone(s,x,y,colour) s.revision+=1 for _,who in pairs(s.players) do snapshot(s,who) end end
  elseif action=="Again" and s.kind=="Gomoku" and s.board.winner~=nil then
   s.ready=s.ready or {} s.ready[p]=true
   if s.ready[s.players[1]] and s.ready[s.players[2]] then s.board=G.new() clearStones(s) s.ready={} s.revision+=1 for _,who in pairs(s.players) do snapshot(s,who) end end
  elseif action=="Note" and s.kind=="Piano" and s.owner==p and type(x)=="number" and x%1==0 and x>=1 and x<=24 then
   for _,listener in ipairs(Players:GetPlayers()) do
    local root=listener.Character and listener.Character:FindFirstChild("HumanoidRootPart")
    if root and (root.Position-s.model.PrimaryPart.Position).Magnitude<=90 then remote:FireClient(listener,"Note",{id=s.model.Name,note=x,performer=p.UserId}) end
   end
  end
 end)
 Players.PlayerRemoving:Connect(function(p) close(p) stamps[p]=nil noteBudget[p]=nil joins[p]=nil end)
 task.spawn(function()
  while map.Parent and task.wait(.5) do
   for p,s in pairs(sessions) do if not nearby(p,s) then close(p) end end
  end
 end)
 return {close=close}
end
return A
