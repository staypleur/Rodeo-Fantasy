"""Bundle the generator for Studio's Command Bar; no game installation."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'src/authoring/StudBlockMapGenerator.luau').read_text(encoding='utf-8')
out=ROOT/'dist/ReviewModels/CreateStudBlockMap.commandbar.lua'
out.write_text('-- Run in a separate empty Studio place for design review.\n'
               'local Generator = (function()\n'+source+'\nend)()\n'
               'game:GetService("ChangeHistoryService"):SetWaypoint("Before Stud map review")\n'
               'local model = Generator.create(workspace, Vector3.new(0,8,0), game:GetService("ServerStorage"))\n'
               'game:GetService("ChangeHistoryService"):SetWaypoint("After Stud map review")\n'
               'game:GetService("Selection"):Set({model})\n'
               'print("STUD_MAP_REVIEW_CREATED", #model:GetChildren(), "Parts; no hunt logic installed")\n', encoding='utf-8')
print(out.name)
