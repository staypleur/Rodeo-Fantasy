"""Render the actual generated brick geometry; this is not a Studio screenshot."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont
from charmander_model import components

ROOT = Path(__file__).resolve().parents[1]

def dot(a,b): return sum(x*y for x,y in zip(a,b))
def unit(v):
    length=math.sqrt(dot(v,v))
    return tuple(x/length for x in v)
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def rotate(v,angles):
    x,y,z=v
    rx,ry,rz=map(math.radians,angles)
    x,y=x*math.cos(rz)-y*math.sin(rz),x*math.sin(rz)+y*math.cos(rz)
    y,z=y*math.cos(rx)-z*math.sin(rx),y*math.sin(rx)+z*math.cos(rx)
    return (x*math.cos(ry)+z*math.sin(ry),y,-x*math.sin(ry)+z*math.cos(ry))

image=Image.new('RGB',(1400,900),(255,248,235))
draw=ImageDraw.Draw(image)
font_path='C:/Windows/Fonts/malgun.ttf'
font=ImageFont.truetype(font_path,30)
small=ImageFont.truetype(font_path,21)
draw.text((50,30),'파이리 · 블록 펫 모델',font=font,fill=(64,48,37))
draw.text((50,78),'실제 모델 부품의 구조 미리보기 (Studio 화면 아님)',font=small,fill=(99,87,72))
for center,camera,label in [(350,(3,5,-12),'앞모습'),(1050,(-8,5,10),'뒷모습 / 꼬리 불꽃')]:
    normal=unit(camera)
    right=unit((-camera[2],0,camera[0]))
    up=cross(right,normal)
    faces=[]
    for part in components():
        vertices=[]
        for ix,iy,iz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]:
            local=(ix*part['size'][0]/2,iy*part['size'][1]/2,iz*part['size'][2]/2)
            rotated=rotate(local,part['rotation'])
            vertices.append(tuple(rotated[i]+part['position'][i] for i in range(3)))
        for ids,local_normal in [((0,3,2,1),(0,0,-1)),((4,5,6,7),(0,0,1)),((0,4,7,3),(-1,0,0)),((1,2,6,5),(1,0,0)),((3,7,6,2),(0,1,0)),((0,1,5,4),(0,-1,0))]:
            face_normal=rotate(local_normal,part['rotation'])
            if dot(face_normal,normal)<=0: continue
            points=[vertices[i] for i in ids]
            shade=0.72+0.28*max(0,dot(face_normal,unit((-4,8,-6))))
            color=tuple(int(c*shade) for c in part['color'])
            projected=[(center+dot(p,right)*88,580-dot(p,up)*88) for p in points]
            faces.append((sum(dot(p,normal) for p in points)/4,projected,color))
    draw.ellipse((center-160,693,center+160,730),fill=(233,222,204))
    for _,polygon,color in sorted(faces,key=lambda f:f[0]):
        draw.polygon(polygon,fill=color)
    draw.text((center-110,770),label,font=small,fill=(64,48,37))
draw.text((50,843),'표면 돌기와 움직이는 불꽃 효과는 Studio에서 표시됩니다.',font=small,fill=(99,87,72))
output=ROOT/'assets/models/charmander-brick-preview.png'
image.save(output)
print(output)

