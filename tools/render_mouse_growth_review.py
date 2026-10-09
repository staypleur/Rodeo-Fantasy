"""Compose the actual model renders into a concise stage comparison sheet."""
from pathlib import Path
import subprocess,sys
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
canvas=Image.new('RGB',(1560,590),(248,241,223))
draw=ImageDraw.Draw(canvas)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',26)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
draw.text((24,15),'MOSSRAT / 3 - 6 - 9 STAR / ACTUAL 3D REVIEW',font=font,fill=(58,43,28))
for col,stage in enumerate((3,6,9)):
 output=R/f'assets/previews/mossrat-s{stage}-faceted-review.png'
 subprocess.run([sys.executable,str(R/'tools/render_textured_review.py'),'--model',str(R/f'dist/ReviewModels/Mossrat_S{stage}_FacetedReview.glb'),'--output',str(output),'--title',f'MOSSRAT {stage} STAR / ACTUAL LOW-POLY 3D REVIEW'],check=True,cwd=R)
 panel=Image.open(output).crop((525,134,1040,610))
 canvas.paste(panel,(col*520+5,92))
 draw.text((col*520+25,59),f'{stage} STAR',font=font,fill=(86,65,36))
draw.text((24,569),'Review only. Not installed. Flat-shaded meshes, embedded texture, each under 2,000 triangles.',font=small,fill=(98,81,61))
canvas.save(R/'assets/previews/mossrat-growth-faceted-review.png')
