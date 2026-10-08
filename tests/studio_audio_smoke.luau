local cfg=require(game.ReplicatedStorage.RodeoFantasy.Config)
local sounds={}
for _,kind in ipairs({"BGM","Hooves","Jump","Rope","Land","Success"}) do
 local sound=Instance.new("Sound") sound.SoundId=cfg.Audio[kind] sound.Parent=game.SoundService
 table.insert(sounds,sound)
end
local failures={}
game:GetService("ContentProvider"):PreloadAsync(sounds,function(id,status)
 if status~=Enum.AssetFetchStatus.Success then table.insert(failures,id..":"..status.Name) end
end)
assert(#failures==0,"audio failed to load: "..table.concat(failures,", "))
for _,sound in ipairs(sounds) do assert(sound.IsLoaded and sound.TimeLength>0,"empty audio: "..sound.SoundId) sound:Destroy() end
print("AUDIO_ASSETS_PASS: all six music/effect resources loaded with positive duration")
