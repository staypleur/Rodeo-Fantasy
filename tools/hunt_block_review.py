"""Standalone geometry review only; never installs or changes hunt rules."""
from pathlib import Path
import itertools
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from native_part_review import save_review

ROOT = Path(__file__).resolve().parents[1]
parts = []
def block(name, pos, size, color):
    parts.append((name, np.array(pos, float), np.array(size, float), color, np.eye(3)))

# Width and placement are review proposals, not approved gameplay dimensions.
block('MeadowPlate', (0, -1, -130), (160, 2, 320), (166, 196, 112))
STUD_PITCH = 1.5
STUD_WIDTH = 1.0
for x in np.arange(-79, 80, STUD_PITCH):
    for z in np.arange(-289, 30, STUD_PITCH):
        block('ReviewStud', (x, .07, z), (STUD_WIDTH, .14, STUD_WIDTH), (182, 208, 132))
for side in (-1, 1):
    for i, z in enumerate(range(-290, 31, 40)):
        h = 16 + (i % 3) * 5
        block('RockFoot', (side * 86, 3, z), (12, 6, 40), (169, 126, 83))
        block('RockWall', (side * 94, h/2 + 6, z), (12, h, 40), (144, 104, 70))
        block('GrassCap', (side * 94, h + 6.5, z), (13, 1, 40), (119, 159, 84))
for x, z in [(-51,-40), (48,-85), (-60,-132), (57,-195), (-44,-230), (40,-270)]:
    block('TreeTrunk', (x, 7, z), (3, 14, 3), (125, 87, 56))
    block('CanopyLower', (x, 15, z), (14, 5, 13), (115, 154, 76))
    block('CanopyUpper', (x-2, 19, z), (10, 4, 10), (150, 184, 98))
for x,z in [(-28,-70),(32,-135),(-19,-215),(49,-245)]:
    block('LowRock', (x, 1, z), (9, 2, 7), (177, 165, 130))
    block('LowRockCap', (x-1, 2.5, z), (6, 1, 5), (193, 183, 145))
save_review(parts, 'HuntWideBlockReview', '넓은 블록 초원 — 배치 검토안',
            '폭 160 studs는 제안값 · 플레이 기능 없음', eye_direction=(.45,1.2,.8))

# Render the same exported geometry with a perspective rear-follow camera.
W,H=1440,900
pixels=np.full((H,W,3),(216,229,222),dtype=np.uint8)
depth=np.full((H,W),np.inf)
eye=np.array((0.,15.,35.)); focus=np.array((0.,3.,-45.))
forward=focus-eye; forward/=np.linalg.norm(forward)
right=np.cross(forward,(0,1,0)); right/=np.linalg.norm(right)
up=np.cross(right,forward)
focal=H/(2*np.tan(np.radians(64)/2))
faceids=[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]
for name,pos,size,color,matrix in parts:
    world=np.array(list(itertools.product((-1,1),repeat=3)))*size/2@matrix.T+pos
    for ids in faceids:
        q=world[list(ids)]
        normal=np.cross(q[1]-q[0],q[2]-q[0]); normal/=np.linalg.norm(normal)
        if normal@(eye-q.mean(axis=0))<=0: continue
        relative=q-eye; z=relative@forward
        if z.min()<=.1: continue
        sx=W/2+(relative@right)*focal/z; sy=H/2-(relative@up)*focal/z
        shade=.68+.32*max(0,float(normal@np.array((-.3,.85,.4))))
        col=tuple(min(255,int(c*shade)) for c in color)
        for ids3 in ((0,1,2),(0,2,3)):
            ix=list(ids3); tx,ty,tz=sx[ix],sy[ix],z[ix]
            x0=max(0,int(np.floor(tx.min())));x1=min(W-1,int(np.ceil(tx.max())))
            y0=max(0,int(np.floor(ty.min())));y1=min(H-1,int(np.ceil(ty.max())))
            if x0>x1 or y0>y1: continue
            den=(ty[1]-ty[2])*(tx[0]-tx[2])+(tx[2]-tx[1])*(ty[0]-ty[2])
            if abs(den)<1e-8: continue
            yy,xx=np.mgrid[y0:y1+1,x0:x1+1];xx=xx+.5;yy=yy+.5
            a=((ty[1]-ty[2])*(xx-tx[2])+(tx[2]-tx[1])*(yy-ty[2]))/den
            b=((ty[2]-ty[0])*(xx-tx[2])+(tx[0]-tx[2])*(yy-ty[2]))/den;c=1-a-b
            distance=1/(a/tz[0]+b/tz[1]+c/tz[2])
            region=depth[y0:y1+1,x0:x1+1]
            mask=(a>=0)&(b>=0)&(c>=0)&(distance<region)
            region[mask]=distance[mask];pixels[y0:y1+1,x0:x1+1][mask]=col
image=Image.fromarray(pixels);draw=ImageDraw.Draw(image)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',25)
draw.rectangle((0,0,W,83),fill=(239,244,231))
draw.text((24,10),'촘촘한 돌기 바닥 수정안 — 기존보다 간격을 줄인 블록 초원',font=font,fill=(38,67,47))
draw.text((24,46),'동일한 Roblox Part 모델을 렌더 · Studio 화면 아님 · 몬스터/조작 미포함',font=font,fill=(65,83,62))
out=ROOT/'assets/previews/HuntDenseBlockCameraReview.png';image.save(out)
model=ROOT/'dist/ReviewModels/HuntWideBlockReview.rbxmx'
tree=ET.parse(model)
assert len(tree.findall('.//Item[@class="Part"]'))==len(parts)
assert not tree.findall('.//Item[@class="Script"]')
assert all(np.isfinite(p).all() and (s>0).all() for _,p,s,_,_ in parts)
print(f'Review only: {len(parts)} Parts; model XML/geometry checked; {out}')
