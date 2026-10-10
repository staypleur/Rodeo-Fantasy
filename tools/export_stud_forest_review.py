"""Export layout data and diagrams from the real Luau layout; no Studio-render claims."""
from pathlib import Path
import json, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from native_part_review import save_review

ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'src/authoring/StudHuntLayout.luau').read_text(encoding='utf-8')
harness=ROOT/'.tools/export_stud_layout.luau'
harness.write_text('local Layout=(function()\n'+source+'\nend)()\n'+'''
for _,b in ipairs(Layout.build()) do
 local cells={b.Name,b.Kind}
 for _,list in ipairs({b.Position,b.Size,b.Color}) do for _,v in ipairs(list) do table.insert(cells,tostring(v)) end end
 print(table.concat(cells,"|"))
end
''',encoding='utf-8')
result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(harness.relative_to(ROOT))],cwd=ROOT,check=True,capture_output=True,text=True)
blocks=[]
for line in result.stdout.splitlines():
 cells=line.split('|'); numbers=list(map(float,cells[2:]))
 blocks.append(dict(name=cells[0],kind=cells[1],position=numbers[:3],size=numbers[3:6],color=list(map(int,numbers[6:9]))))
folder=ROOT/'assets/courses/StudForest1000';folder.mkdir(parents=True,exist_ok=True)
(folder/'layout.json').write_text(json.dumps(dict(lengthMeters=1000,lengthStuds=4800,widthStuds=192,screenCompositionTarget=dict(empty=0.4,obstacles=0.2,monsters=0.4),monsterModelsPending=True,blocks=blocks),ensure_ascii=False,indent=2),encoding='utf-8')

# Exact exported geometry excerpt; software renderer does not show native Stud texture.
parts=[(b['name'],np.array(b['position']),np.array(b['size']),tuple(b['color']),np.eye(3))
       for b in blocks if -640<=b['position'][2]<=0]
save_review(parts,'StudForest1000OpeningGeometry','숲 1,000m — 시작 구간 형상·색 검토',
            'Stud 표면은 Studio에서 확인 · 몬스터 미포함',eye_direction=(.65,.95,1.3),export_model=False)

details=[]
for b in blocks:
 x,y,z=b['position']
 if b['kind']=='Obstacle' and -260<=z<=-220:
  details.append((b['name'],np.array((x-40,y,z+240)),np.array(b['size']),tuple(b['color']),np.eye(3)))
 elif b['kind']=='Obstacle' and x>0 and -420<=z<=-380:
  details.append((b['name'],np.array((x+8,y,z+400)),np.array(b['size']),tuple(b['color']),np.eye(3)))
save_review(details,'StudForestTreeRockDetails','나무·바위 — 형상과 여러 색층 확대 검토',
            '동일 부품을 나란히 놓은 검토 모델 · Stud는 Studio에서 확인',eye_direction=(.65,.7,1.3),export_model=False)

# Five panels keep the long route legible. Rectangles are actual obstacle footprints.
im=Image.new('RGB',(1500,1050),(243,239,224));draw=ImageDraw.Draw(im)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',23)
small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',16)
draw.text((25,16),'개인 숲 사냥터 0–1,000m · 전체 폭 192studs 유지',font=font,fill=(58,67,47))
draw.text((25,52),'실제 배치 데이터의 평면도 · 나무: 초록 / 바위: 회갈색 · Studio 화면 아님',font=small,fill=(81,87,72))
for panel in range(5):
 x0=35+panel*295; y0=130; panelw=230; panelh=860
 start=panel*960; end=start+960
 draw.text((x0,95),f'{panel*200}–{(panel+1)*200}m ↓',font=font,fill=(70,82,52))
 draw.rectangle((x0,y0,x0+panelw,y0+panelh),fill=(223,198,151),outline=(116,80,54),width=3)
 for tick in range(0,961,240):
  py=y0+tick/960*panelh
  draw.line((x0,py,x0+panelw,py),fill=(199,177,134),width=1)
 for b in blocks:
  if b['kind']!='Obstacle':continue
  x,_,z=b['position']; w,_,d=b['size']; lo=max(start,-z-d/2);hi=min(end,-z+d/2)
  if hi<=lo:continue
  left=x0+(x-w/2+96)/192*panelw;right=x0+(x+w/2+96)/192*panelw
  top=y0+(lo-start)/960*panelh;bottom=y0+(hi-start)/960*panelh
  col=(106,140,68) if b['name'].startswith(('Tree','Canopy')) else (136,116,116)
  draw.rectangle((left,top,right,bottom),fill=col)
im.save(ROOT/'assets/previews/StudForest1000Route.png')
print(f'STUD_FOREST_EXPORT: {len(blocks)} Parts; layout JSON and geometry/route images created')
