"""Bundle the generator for Studio's Command Bar; no game installation."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'src/authoring/StudBlockMapGenerator.luau').read_text(encoding='utf-8')
layout=(ROOT/'src/authoring/StudHuntLayout.luau').read_text(encoding='utf-8')
scenery=(ROOT/'src/authoring/ForestSceneryLayout.luau').read_text(encoding='utf-8')
layout=layout.replace('local Scenery = require(script.Parent.ForestSceneryLayout)', 'local Scenery = (function()\n'+scenery+'\nend)()')
source=source.replace('local Layout = require(script.Parent.StudHuntLayout)', 'local Layout = (function()\n'+layout+'\nend)()')
out=ROOT/'dist/ReviewModels/CreateStudBlockMap.commandbar.lua'
out.write_text('-- Run in a separate empty Studio place for design review.\n'
               'local Generator = (function()\n'+source+'\nend)()\n'
               'game:GetService("ChangeHistoryService"):SetWaypoint("Before Stud map review")\n'
               'local model = Generator.create(workspace, Vector3.new(0,8,0), game:GetService("ServerStorage"))\n'
               'local scripts=game:GetService("StarterPlayer").StarterPlayerScripts\n'
               'local old=scripts:FindFirstChild("ForestReviewPresentation") if old then old:Destroy() end\n'
               'local presentation=Instance.new("LocalScript") presentation.Name="ForestReviewPresentation"\n'
               'presentation.Source=[==[\n'+(ROOT/'src/authoring/ForestAtmosphere.client.luau').read_text(encoding='utf-8')+'\n]==]\n'
               'presentation.Parent=scripts\n'
               'game:GetService("ChangeHistoryService"):SetWaypoint("After Stud map review")\n'
               'game:GetService("Selection"):Set({model:FindFirstChild("MeadowPlate")})\n'
               'print("STUD_MAP_REVIEW_CREATED", #model:GetChildren(), "Parts; 1000m x 192 studs; models pending")\n', encoding='utf-8')
print(out.name)
