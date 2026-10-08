local Audio={}
local service=game:GetService("SoundService")
local config=require(game:GetService("ReplicatedStorage"):WaitForChild("RodeoFantasy"):WaitForChild("Config"))
local sounds,hooves={},{}
local previousPhase,previousCount=nil,nil
local function sound(name,id,parent,volume,looped)
 local s=Instance.new("Sound") s.Name=name s.SoundId=id s.Volume=volume
 s.Looped=looped or false s.Parent=parent return s
end
local function initialize()
 if sounds.BGM then return end
 for _,kind in ipairs({"BGM","Jump","Rope","Land","Success"}) do
  sounds[kind]=sound("Rodeo"..kind,config.Audio[kind],service,kind=="BGM" and config.Audio.MusicVolume or config.Audio.EffectsVolume,kind=="BGM")
 end
 sounds.Rope.Volume=0.18 sounds.Success.PlaybackSpeed=1.4
 sounds.BGM:Play()
end
local function play(kind)
 local s=sounds[kind] s:Stop() s.TimePosition=0 s:Play()
end
function Audio.update(state,monsters,position,clock)
 initialize()
 local active=state.phase~="Idle" and state.phase~="GameOver" and state.phase~="CourseEnd"
 if previousPhase and previousPhase~=state.phase then
  if state.phase=="Airborne" then play("Jump")
  elseif state.phase=="Lassoing" then play("Rope")
  elseif state.phase=="Riding" then play("Land") end
 end
 if previousCount and (state.count or 0)>previousCount then play("Success") end
 previousPhase,previousCount=state.phase,state.count or 0
 local candidates={}
 if active and position then
  for _,model in ipairs(monsters:GetChildren()) do
   local root=model.PrimaryPart
   local velocity=model:GetAttribute("HerdVelocity")
   local moving=model:GetAttribute("Occupied") or not velocity or velocity.Magnitude>1
   if root and model:GetAttribute("Running") and moving then
    local distance=(root.Position-position).Magnitude
    if distance<70 then table.insert(candidates,{model=model,distance=distance}) end
   end
  end
 end
 table.sort(candidates,function(a,b) return a.distance<b.distance end)
 local kept={}
 for i=1,math.min(6,#candidates) do
  local model=candidates[i].model kept[model]=true
  local s=hooves[model]
  if not s then
   s=sound("RodeoHooves",config.Audio.Hooves,model.PrimaryPart,0.16,true)
   s.RollOffMinDistance,s.RollOffMaxDistance=6,70
   s.RollOffMode=Enum.RollOffMode.InverseTapered hooves[model]=s s:Play()
  end
  local dash=model:GetAttribute("DashUntil")
  s.PlaybackSpeed=dash and clock<dash and 1.5 or 1
 end
 for model,s in pairs(hooves) do
  if not kept[model] or not model.Parent then s:Destroy() hooves[model]=nil end
 end
end
return Audio
