"""Render the actual generated brick geometry; this is not a Studio screenshot."""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont
import xml.etree.ElementTree as ET

def components():
    tree=ET.parse(Path(__file__).resolve().parents[1]/"dist/RodeoFantasy-Capture.rbxlx")
    ship=next(n for n in tree.iter("Item") if n.findtext("Properties/string[@name='Name']")=="Airship")
    result=[]
    for node in ship.findall("Item"):
        p=node.find("Properties"); cf=p.find("CoordinateFrame[@name='CFrame']"); size=p.find("Vector3[@name='size']")
        if cf is None:continue
        color=int(p.findtext("Color3uint8[@name='Color3uint8']"))
        # Use the saved native transform matrix directly.
        result.append(dict(sphere=p.findtext("token[@name='shape']")=="0",position=(float(cf.findtext('X'))-6000,float(cf.findtext('Y'))-40,float(cf.findtext('Z'))+5),size=tuple(float(size.findtext(a)) for a in 'XYZ'),color=((color>>16)&255,(color>>8)&255,color&255),rotation=(0,0,0),matrix=[[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)]))
    return result

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
draw.text((50,30),'푸른 바다코끼리 · 거대 판타지 비행선',font=font,fill=(64,48,37))
draw.text((50,78),'실제 모델 부품의 구조 미리보기 (Studio 화면 아님)',font=small,fill=(99,87,72))
for center,camera,label in [(350,(7,4,-12),'앞모습'),(1050,(-12,5,-3),'옆모습 / 긴 코 · 큰 날개')]:
    normal=unit(camera)
    right=unit((-camera[2],0,camera[0]))
    up=cross(right,normal)
    faces=[]
    for part in components():
        def world(v):
            local=tuple(v[i]*part['size'][i]/2 for i in range(3))
            return tuple(sum(part['matrix'][i][j]*local[j] for j in range(3))+part['position'][i] for i in range(3))
        polygons=[]
        if part['sphere']:
            def vertex(a,b): return (math.cos(b)*math.sin(a),math.sin(b),math.cos(b)*math.cos(a))
            for row in range(14):
                b0=-math.pi/2+math.pi*row/14; b1=-math.pi/2+math.pi*(row+1)/14
                for col in range(28):
                    a0=math.tau*col/28; a1=math.tau*(col+1)/28
                    polygons.append([world(vertex(a0,b0)),world(vertex(a1,b0)),world(vertex(a1,b1)),world(vertex(a0,b1))])
        else:
            vertices=[world(v) for v in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
            polygons=[[vertices[i] for i in ids] for ids in [(0,3,2,1),(4,5,6,7),(0,4,7,3),(1,2,6,5),(3,7,6,2),(0,1,5,4)]]
        for points in polygons:
            avg=tuple(sum(p[i] for p in points)/4 for i in range(3))
            if part['sphere']:
                fn=tuple((avg[i]-part['position'][i])/(part['size'][i]**2) for i in range(3))
                face_normal=unit(fn)
            else:
                face_normal=unit(cross(tuple(points[1][i]-points[0][i] for i in range(3)),tuple(points[2][i]-points[1][i] for i in range(3))))
            if dot(face_normal,normal)<=0: continue
            shade=.55+.45*max(0,dot(face_normal,unit((-4,8,-6))))
            color=tuple(int(c*shade) for c in part['color'])
            projected=[(center+dot(p,right)*3.5,550-dot(p,up)*3.5) for p in points]
            faces.append((dot(avg,normal),projected,color))
    draw.ellipse((center-160,693,center+160,730),fill=(233,222,204))
    for _,polygon,color in sorted(faces,key=lambda f:f[0]):
        draw.polygon(polygon,fill=color)
    draw.text((center-110,770),label,font=small,fill=(64,48,37))
draw.text((50,843),'9성 최종 진화형 · 매끄러운 몸과 열기구 바구니 · 날개 움직임은 Studio Play에서 표시됩니다.',font=small,fill=(99,87,72))
output=ROOT/'assets/models/blue-sea-elephant-preview.png'
image.save(output)
print(output)

