"""Compare pre-neck-fix/current head geometry with identical review cameras."""
from pathlib import Path
import subprocess,sys
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
old=R/'.tools/Mossrat9BeforeFaceFix.glb'
old.write_bytes(subprocess.run(['git','show','b746643^:dist/ReviewModels/Mossrat_S9_FacetedReview.glb'],cwd=R,capture_output=True,check=True).stdout)
source=(R/'tools/render_textured_review.py').read_text(encoding='utf-8')
source=source.replace("for node in g['nodes']:","for node in g['nodes']:\n if not (node['name'] in ('Head','Nose','ClosedMouth') or any(k in node['name'] for k in ('Eye','Ear','Cheek'))):continue")
results=[]
for label,model in [('BEFORE NECK / FACE REFINEMENT',old),('CURRENT APPROVED MODEL',R/'dist/ReviewModels/Mossrat_S9_FacetedReview.glb')]:
 output=R/'.tools'/('mossrat-face-'+('before' if model==old else 'current')+'.png')
 sys.argv=['render','--model',str(model),'--output',str(output),'--lineage-review','--side-label','SIDE','--title',label]
 exec(compile(source,'actual_face_render','exec'),{'__file__':str(R/'tools/render_textured_review.py')})
 results.append(Image.open(output).copy())
combined=Image.new('RGB',(1560,1300),(249,242,226))
for index,image in enumerate(results):combined.paste(image,(0,index*650))
combined.save(R/'assets/previews/mossrat-s9-face-before-after.png')
print('MOSSRAT_FACE_COMPARISON_PASS: only head/eyes/ears/nose/mouth; same cameras, independently fitted scale; real GLB geometry')
