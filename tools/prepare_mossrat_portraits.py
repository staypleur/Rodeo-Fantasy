from pathlib import Path
from PIL import Image,ImageFilter
import numpy as np
from collections import deque
def binary_propagation(seeds,mask):
 seen=seeds.copy(); h,w=mask.shape; q=deque(zip(*np.where(seeds)))
 while q:
  y,x=q.popleft()
  for ny,nx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
   if 0<=ny<h and 0<=nx<w and mask[ny,nx] and not seen[ny,nx]:
    seen[ny,nx]=True;q.append((ny,nx))
 return seen
root=Path.cwd(); source=Path('C:/Users/wucha/AppData/Local/Temp')
ids=['935e6f1a-377e-4d62-b041-848e5c333688','14c0ca53-a99e-48d8-b98f-189c0901bd26','31978f8f-3db4-4dc5-a980-41795058e07c','2b0aa1dc-7c44-43c2-afeb-6126a32969f8']
for stage,key in zip([1,3,6,9],ids):
 im=Image.open(source/f'codex-clipboard-{key}.png').convert('RGBA'); a=np.array(im); rgb=a[:,:,:3].astype(float)
 # Boundary plus reviewed enclosed background gaps. Never globally erase white
 # pixels: eyes, teeth and pale fur must retain their original pixels.
 eligible=(rgb.min(2)>150)&((rgb.max(2)-rgb.min(2))<20)
 seeds=np.zeros(eligible.shape,bool); seeds[0,:]=True;seeds[-1,:]=True;seeds[:,0]=True;seeds[:,-1]=True
 holes={6:[(369,295),(459,403)],9:[(387,296),(405,107),(163,108),(202,101),(367,101),(211,139),(355,140),(117,72),(451,72),(447,91),(119,92)]}
 for x,y in holes.get(stage,[]):
  assert eligible[y,x],(stage,x,y)
  seeds[y,x]=True
 bg=binary_propagation(seeds&eligible,mask=eligible)
 a[bg,3]=0
 out=Image.fromarray(a)
 if stage in (6,9):
  # Trim the one-pixel white antialias matte without recoloring the artwork.
  out.putalpha(out.getchannel('A').filter(ImageFilter.MinFilter(3)))
 box=out.getbbox(); out=out.crop(box)
 out.thumbnail((480,480),Image.Resampling.LANCZOS)
 canvas=Image.new('RGBA',(512,512));canvas.alpha_composite(out,((512-out.width)//2,(512-out.height)//2))
 path=root/f'assets/ui/MossratPortraits/MossratS{stage}.png';canvas.save(path,optimize=True)
 print(stage,im.size,'=>512',path.stat().st_size,'bytes')
clock=Image.open(source/'codex-clipboard-21bc5273-8bc3-47b0-b63b-b787354d7979.png').convert('RGBA')
clock.thumbnail((256,256),Image.Resampling.LANCZOS);clock.save(root/'assets/ui/MossratClock.png',optimize=True)
