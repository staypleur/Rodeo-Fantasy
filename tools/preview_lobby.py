"""Top view of the actual place geometry, not a Studio screenshot."""
from pathlib import Path
import itertools
import math
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
tree = ET.parse(ROOT / 'dist/RodeoFantasy-Capture.rbxlx')
lobby = next(n for n in tree.iter('Item') if n.findtext("Properties/string[@name='Name']") == 'RodeoLobby')
image = Image.new('RGB', (1200, 1320), (249, 245, 235))
draw = ImageDraw.Draw(image)
font = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 26)
small = ImageFont.truetype('C:/Windows/Fonts/malgun.ttf', 19)
draw.text((40, 24), '파스텔 로비 · 실제 맵 부품의 위쪽 배치도', font=font, fill=(44, 72, 61))
draw.text((40, 64), 'Studio 화면 아님 · 개인 구역 8개 / 목장 64개 / 목장당 2마리', font=small, fill=(74, 94, 84))
scale = 2.7
def project(x, z):
    return (600 + (x - 6000)*scale, 720 + z*scale)

parts = []
for n in lobby.iter('Item'):
    if n.get('class') != 'Part':
        continue
    p = n.find('Properties')
    cf, size = p.find("CoordinateFrame[@name='CFrame']"), p.find("Vector3[@name='size']")
    color = int(p.findtext("Color3uint8[@name='Color3uint8']"))
    rgb = ((color >> 16)&255, (color >> 8)&255, color&255)
    position = [float(cf.findtext(a)) for a in 'XYZ']
    matrix = [[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)]
    dims = [float(size.findtext(a)) for a in 'XYZ']
    points = []
    if p.findtext("token[@name='shape']") == '2':
        # Cylinders run along their local X axis.
        locals_ = [(sx*dims[0]/2, math.cos(a)*dims[1]/2, math.sin(a)*dims[2]/2)
                   for sx in (-1,1) for a in (i*math.pi/24 for i in range(48))]
    else:
        locals_ = [tuple(signs[i]*dims[i]/2 for i in range(3)) for signs in itertools.product((-1,1),repeat=3)]
    for v in locals_:
        world = [position[i]+sum(matrix[i][j]*v[j] for j in range(3)) for i in range(3)]
        points.append(project(world[0],world[2]))
    # Convex hull of the projected native part.
    pts=sorted(set(points))
    def cross(o,a,b): return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    halves=[]
    for order in (pts,pts[::-1]):
        half=[]
        for pt in order:
            while len(half)>1 and cross(half[-2],half[-1],pt)<=0: half.pop()
            half.append(pt)
        halves+=half[:-1]
    parts.append((position[1],halves,rgb))
for _,poly,color in sorted(parts,key=lambda p:p[0]):
    if len(poly)>2: draw.polygon(poly,fill=color)
for n in next(p for p in lobby.findall("Item") if p.findtext("Properties/string[@name='Name']")=="Plots").findall("Item"):
    idx=n.findtext("Properties/string[@name='Name']").split('_')[-1]
    board=next(p for p in n.findall('Item') if p.findtext("Properties/string[@name='Name']")=='OwnerBoard')
    cf=board.find("Properties/CoordinateFrame[@name='CFrame']")
    x,z=project(float(cf.findtext('X')),float(cf.findtext('Z')))
    draw.text((x,z+9), f'개인 구역 {idx}',font=small,fill=(40,67,55),anchor='mt')
draw.text((600,940),'중앙 비행선',font=small,fill=(40,67,55),anchor='mt')
draw.text((600,1080),'중앙 광장',font=small,fill=(40,67,55),anchor='mt')
out=ROOT/'assets/maps/lobby-layout-preview.png'
out.parent.mkdir(parents=True,exist_ok=True)
image.save(out)
print(out)
