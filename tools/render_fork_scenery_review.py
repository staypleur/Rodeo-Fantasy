"""Render exact offline review geometry; not a Studio/gameplay screenshot."""
from pathlib import Path
import math, xml.etree.ElementTree as E
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
O=R/'dist/CourseReview/SceneryV3'
doc=E.parse(O/'Fork-Scenery-Comparison.rbxlx')
im=Image.new('RGB',(1800,1020),'#142c2c');draw=ImageDraw.Draw(im)
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',n)
draw.text((40,25),'Green Star · 네모난 나무·바위를 유지한 분기 디자인 비교',font=font(32),fill='#f4eedc')
draw.text((40,80),'독립 3D 검토본 렌더 · 게임 적용 전 · 실제 Studio 주행 화면 아님',font=font(19),fill='#bcd4cd')
dot=lambda a,b:sum(x*y for x,y in zip(a,b))
sub=lambda a,b:tuple(x-y for x,y in zip(a,b))
norm=lambda a:tuple(x/math.sqrt(dot(a,a)) for x in a)
cross=lambda a,b:(a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
camera=(100,210,155);target=(0,-5,-85)
forward=norm(sub(target,camera));right=norm(cross(forward,(0,1,0)));up=cross(right,forward)
def project(v,cx,center):
 v=sub((v[0]-cx,v[1],v[2]),camera)
 depth=dot(v,forward)
 return (center[0]+dot(v,right)*1100/depth,center[1]-dot(v,up)*1100/depth),depth
for k,(name,cx,title,desc) in enumerate([
 ('ForestMountain',-62,'A · 숲이 있는 낮은 능선','높이가 다른 경사 · 비탈의 나무 · 별도 바위 군집'),
 ('OpenCanyon',62,'B · 중앙이 열린 협곡','깊게 열린 중앙 · 층이 드러난 절벽 · 가장자리 조경')]):
 x0=30+k*890
 draw.rounded_rectangle((x0,130,x0+850,940),radius=20,fill='#bbd9d6')
 draw.text((x0+25,150),title,font=font(28),fill='#23443c')
 draw.text((x0+25,195),desc,font=font(17),fill='#3d5e54')
 model=next(n for n in doc.iter('Item') if n.findtext('./Properties/string[@name="Name"]')==name)
 faces=[]
 for n in model.iter('Item'):
  if n.attrib['class'] not in ('Part','WedgePart'):continue
  p=n.find('Properties');cf=p.find('CoordinateFrame');sz=p.find('Vector3')
  pos=tuple(float(cf.findtext(a)) for a in ('X','Y','Z'));size=tuple(float(sz.findtext(a)) for a in ('X','Y','Z'))
  rot=[[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)]
  col=tuple(float(p.find('Color3').findtext(a))*255 for a in ('R','G','B'))
  corners=[(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]
  polygons=[(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7),(0,3,7,4),(1,5,6,2)]
  if n.attrib['class']=='WedgePart':polygons=[(0,1,2,3),(0,7,6,1),(3,2,6,7),(0,3,7),(1,6,2)]
  points=[]
  for v in corners:
   v=tuple(v[j]*size[j]/2 for j in range(3))
   points.append(tuple(pos[i]+sum(rot[i][j]*v[j] for j in range(3)) for i in range(3)))
  for inds in polygons:
   poly=[points[i] for i in inds];normal=norm(cross(sub(poly[1],poly[0]),sub(poly[2],poly[0])))
   shade=.68+.32*abs(dot(normal,norm((-.4,1,.5))))
   color=tuple(round(c*shade) for c in col)
   projected=[project(v,cx,(x0+430,580)) for v in poly]
   faces.append((sum(z for _,z in projected)/len(projected),[xy for xy,_ in projected],color))
 for _,poly,col in sorted(faces,key=lambda f:f[0],reverse=True):draw.polygon(poly,fill=col)
draw.text((40,970),'전체 폭은 이전 최대 70스터드를 넘지 않음 · 난이도는 2,000m에 가까워질수록 상승 · 산/협곡 선택 전',font=font(20),fill='#d0e0d5')
im.save(O/'Fork-Scenery-Comparison.png')
print('OFFLINE_3D_REVIEW_RENDER',O/'Fork-Scenery-Comparison.png')
