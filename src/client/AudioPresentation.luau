local Audio={}
local service=game:GetService("SoundService")
local config=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("Config"))
local settings=config.Audio
local sounds,hooves={},{}
local lastBurst={}
local hoofId=settings.Hooves
local lastWorld
local groups={}
local volumes={Music=1,Effects=1}
function Audio.clampVolume(value)
 if type(value)~="number" or value~=value then return nil end
 return math.clamp(value,0,1)
end
local function group(kind)
 if not groups[kind] then
  local node=Instance.new("SoundGroup") node.Name="RodeoLocal"..kind
  node.Volume=volumes[kind] node.Parent=service groups[kind]=node
 end
 return groups[kind]
end
function Audio.setVolume(kind,value)
 if volumes[kind]==nil then return false end
 local clamped=Audio.clampVolume(value)
 if clamped==nil then return false end
 volumes[kind]=clamped group(kind).Volume=clamped
 return true
end
function Audio.getVolume(kind) return volumes[kind] end
-- Event decisions are independent of sound loading and frame rate.
function Audio.newEvents()
 local tracker={}
 function tracker:update(state,clock,warning)
  local events={}
  local phase=state.phase
  local active=state.area=="Hunt" and (phase=="Riding" or phase=="Lassoing" or phase=="Airborne")
  if self.phase and self.phase~=phase then
   if phase=="Airborne" then events[#events+1]="Jump"
   elseif phase=="Lassoing" then events[#events+1]="Rope"
   elseif phase=="Riding" then events[#events+1]="Land"
   elseif phase=="GameOver" then
    local reason=state.endReason
    if reason=="Monster" then events[#events+1]="CrashMonster"
    elseif reason=="Obstacle" or reason=="Wall" then events[#events+1]="CrashObstacle"
    elseif reason=="Fall" then events[#events+1]="Fall" end
   end
  end
  if self.phase and active and phase=="Riding" and state.tamed and (not self.tamed or self.mount~=state.monster) then
   events[#events+1]="Success"
  end
  if self.mount~=state.monster then self.nextWarning=nil end
  if active and phase=="Riding" and warning then
   if not self.nextWarning or clock>=self.nextWarning then
    events[#events+1]="Warning" self.nextWarning=clock+settings.WarningInterval
   end
  else self.nextWarning=nil end
  self.phase,self.tamed,self.mount=phase,state.tamed,state.monster
  return events
 end
 return tracker
end
local tracker=Audio.newEvents()
local function sound(name,id,parent,volume,looped)
 local s=Instance.new("Sound") s.Name=name s.SoundId=id s.Volume=volume
 s.SoundGroup=group((name=="RodeoBGM" or name=="RodeoLobbyBGM") and "Music" or "Effects")
 s.Looped=looped or false s.Parent=parent return s
end
local profiles={
 Rope={volume=.18},Success={volume=.3,pitch=1.4},Warning={volume=.12,pitch=.85},
 CrashObstacle={volume=.35,pitch=1.4},CrashMonster={volume=.3,pitch=1.2},Fall={volume=.25,pitch=.8},
 Knock={volume=.3,pitch=1.25},BreakWood={volume=.26,pitch=1.7},BreakRock={volume=.3,pitch=.85},
}
local function initialize()
 if sounds.BGM then return end
 local preload={}
 for _,kind in ipairs({"BGM","LobbyBGM","Jump","Rope","Land","Success","Warning","CrashObstacle","CrashMonster","Fall","Knock","BreakWood","BreakRock"}) do
  local music=kind=="BGM" or kind=="LobbyBGM"
  local profile=profiles[kind] or {}
  local s=sound("Rodeo"..kind,settings[kind],service,music and settings.MusicVolume or profile.volume or settings.EffectsVolume,music)
  s.PlaybackSpeed=profile.pitch or 1 sounds[kind]=s
  if not music then table.insert(preload,s) end
 end
 local probe=sound("RodeoHoovesPreload",hoofId,service,0,false) table.insert(preload,probe)
 task.spawn(function()
  local ok,err=pcall(function()
   game:GetService("ContentProvider"):PreloadAsync(preload,function(id,status)
    if status~=Enum.AssetFetchStatus.Success then
     if id==settings.Hooves then
      hoofId=settings.HoovesFallback
      for _,s in pairs(hooves) do s.SoundId=hoofId s:Play() end
     else warn("Rodeo sound unavailable: "..id.." ("..status.Name..")") end
    end
   end)
  end)
  if not ok then warn("Rodeo audio preload failed: "..tostring(err)) end
  probe:Destroy()
 end)
end
local function play(kind,volume,pitch)
 local s=sounds[kind] local profile=profiles[kind] or {}
 s.Volume=(profile.volume or settings.EffectsVolume)*(volume or 1)
 s.PlaybackSpeed=pitch or profile.pitch or 1
 s:Stop() s.TimePosition=0 s:Play()
end
-- Remember each exact event timestamp, allowing the same obstacle to break again after respawn.
function Audio.newTimestampEvents()
 local seen=setmetatable({},{__mode="k"})
 return function(node,stamp,clock)
  if not stamp or seen[node]==stamp or stamp>clock+.25 then return false end
  seen[node]=stamp
  return clock-stamp<=settings.EventMaxAge
 end
end
local knockEvent,breakEvent=Audio.newTimestampEvents(),Audio.newTimestampEvents()
local function burst(kind,clock,distance,sizeClass)
 if lastBurst[kind] and clock-lastBurst[kind]<.09 then return end
 lastBurst[kind]=clock
 local attenuation=math.clamp(1-distance/settings.EventHearingDistance,.15,1)
 local profile=profiles[kind] or {}
 local pitch=(profile.pitch or 1)*(sizeClass=="Large" and .8 or 1)
 play(kind,attenuation,pitch)
end
function Audio.update(state,monsters,position,clock,selected)
 initialize()
 if lastWorld~=monsters then
  tracker=Audio.newEvents() knockEvent,breakEvent=Audio.newTimestampEvents(),Audio.newTimestampEvents()
  lastBurst={} lastWorld=monsters
 end
 local music=state.area=="Lobby" and "LobbyBGM" or "BGM"
 if sounds[music].Playing~=true then
  sounds[music=="BGM" and "LobbyBGM" or "BGM"]:Stop() sounds[music]:Play()
 end
 local active=state.area=="Hunt" and (state.phase=="Riding" or state.phase=="Lassoing" or state.phase=="Airborne")
 local mount=state.monster
 local warning=mount and (mount:GetAttribute("AngerWarning")==true or mount:GetAttribute("Angry")==true)
 for _,kind in ipairs(tracker:update(state,clock,warning)) do play(kind) end
 if not active or state.phase~="Riding" or not warning then sounds.Warning:Stop() end
 local candidates={}
 if active and position then
  for _,model in ipairs(monsters:GetChildren()) do
   local root=model.PrimaryPart
   if root and model:GetAttribute("KnockedAway") then
    if knockEvent(model,model:GetAttribute("KnockedAt"),clock) then
     local distance=(root.Position-position).Magnitude
     if distance<settings.EventHearingDistance then burst("Knock",clock,distance,mount and mount:GetAttribute("SizeClass")) end
    end
   end
   local velocity=model:GetAttribute("HerdVelocity")
   local moving=model:GetAttribute("Occupied") or not velocity or velocity.Magnitude>1
   if root and model:GetAttribute("Running") and not model:GetAttribute("KnockedAway") and moving and not model:GetAttribute("Flying") and (model:GetAttribute("Occupied") or not selected or selected[model]) then
    local distance=(root.Position-position).Magnitude
    if distance<70 then table.insert(candidates,{model=model,distance=distance}) end
   end
  end
  local obstacles=monsters.Parent and monsters.Parent:FindFirstChild("Obstacles")
  if obstacles then for _,obstacle in ipairs(obstacles:GetChildren()) do
   if obstacle:IsA("BasePart") and obstacle:GetAttribute("Broken") and breakEvent(obstacle,obstacle:GetAttribute("BrokenAt"),clock) then
    local distance=(obstacle.Position-position).Magnitude
    if distance<settings.EventHearingDistance then
     local kind=(obstacle:GetAttribute("BreakableCrate") or obstacle.Name:find("Tree")) and "BreakWood" or "BreakRock"
     burst(kind,clock,distance,mount and mount:GetAttribute("SizeClass"))
    end
   end
  end end
 end
 table.sort(candidates,function(a,b) return a.distance<b.distance end)
 local kept={}
 for i=1,math.min(4,#candidates) do
  local model=candidates[i].model kept[model]=true
  local s=hooves[model]
  local own=model==mount or model:GetAttribute("Occupied")==true
  local parent=own and service or model.PrimaryPart
  if s and s.Parent~=parent then s:Destroy() hooves[model]=nil s=nil end
  if not s then
   -- The rider's feet are local audio; a high hunt camera must not attenuate them away.
   s=sound("RodeoHooves",hoofId,parent,own and .16 or .055,true)
   s.RollOffMinDistance,s.RollOffMaxDistance=8,160
   s.RollOffMode=Enum.RollOffMode.InverseTapered hooves[model]=s s:Play()
  end
  local size=model:GetAttribute("SizeClass")
  local speed=size=="Large" and .8 or size=="Medium" and 1 or 1.15
  local dash=model:GetAttribute("DashUntil")
  s.PlaybackSpeed=speed*(dash and clock<dash and 1.5 or 1)
 end
 for model,s in pairs(hooves) do
  if not kept[model] or not model.Parent then s:Destroy() hooves[model]=nil end
 end
end
return Audio
