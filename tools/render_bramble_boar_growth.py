"""Reuse the actual GLB rasterizer, with the approved medium 1/2/3 avatar reference."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'tools/render_mouse_growth_review.py').read_text(encoding='utf-8')
s=s.replace('MeadowMouse_A_S1','BrambleBoar_S1').replace('Mossrat_S','BrambleBoar_S')
s=s.replace('MOSSRAT','BRAMBLE BOAR').replace('mossrat','bramble-boar')
s=s.replace('ratio=.5 if i==2 else 1.','ratio=1.')
s=s.replace('12.5','15.0').replace('2.5 PLAYER HEIGHTS','3 PLAYER HEIGHTS')
s=s.replace('5 + 5 + 2.5 = 15.0 studs','5 + 5 + 5 = 15 studs')
s=s.replace('teen 4, adult 5.7, elder about 15.0','teen 5, adult 10, leader 15')
s=s.replace('BODY HEIGHT (ears included; plants/tails excluded)','TOTAL HEIGHT (ears and brambles included)')
s=s.replace("9:'ELDER'","9:'LEADER'")
s=s.replace('Original baby unchanged. Review only, not installed.','Approved baby installed; growth stages are review only.')
s=s.replace('BRANCHING SPROUT & FLOWING MANE','CURVED TUSKS & BRAMBLE RIDGE')
s=s.replace("'--lineage-review','--title'","'--lineage-review','--side-label','SIDE','--title'")
exec(compile(s,str(__file__),'exec'))
