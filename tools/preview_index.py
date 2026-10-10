"""Index layout preview only, not a Studio render or an actual 3D portrait."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
im=Image.new('RGBA',(1250,820),(26,43,65,255));d=ImageDraw.Draw(im)
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/malgunbd.ttf',n)
def text(x,y,s,n=23,c='white'):
 d.text((x,y),s,font=font(n),fill=c,stroke_width=2,stroke_fill='black')
def box(rect,c,outline='#080c13',width=3):d.rectangle(rect,fill=c,outline=outline,width=width)
def grad(rect,a,b):
 x,y,xx,yy=rect
 for row in range(y,yy):
  t=(row-y)/max(1,yy-y-1);d.line((x,row,xx,row),fill=tuple(round(a[i]*(1-t)+b[i]*t) for i in range(3)))
 d.rectangle(rect,outline='#080c13',width=3)
text(190,25,'인덱스 배치 검토 · 실제 Studio 화면 아님',24)
# UI asset sample + the final collection count follows the current catalog.
for name,y in [('ShopButton',310),('IndexButton',380)]:
 icon=Image.open(R/'assets/ui'/(name+'.png')).convert('RGBA');icon=icon.crop(icon.getbbox());icon.thumbnail((156,66));im.alpha_composite(icon,(8,y))
grad((172,156,1008,695),(71,77,96),(37,39,52))
for x in range(192,1008,51):d.line((x,220,x,685),fill='#454959',width=2)
grad((180,164,1000,228),(117,241,255),(0,167,228));text(197,173,'펫 인덱스',30)
grad((942,175,989,220),(255,131,129),(241,24,34));text(954,174,'X',30)
grad((189,244,302,610),(127,186,62),(24,73,39));text(204,265,'Green',21);text(216,299,'Star',21);text(220,531,'초원',22)
box((323,244,741,527),'#171b23')
face=Image.open(R/'assets/ui/MossratFace.png').convert('RGBA')
colors=[(83,181,78),(26,139,232),(203,73,229),(242,190,32)]
for i,star in enumerate([1,3,6,9]):
 x=330+(i%2)*204;y=254+(i//2)*134;grad((x,y,x+194,y+127),colors[i],(40,58,70))
 portrait=face.copy();portrait.thumbnail((86,86))
 if i==0:
  im.alpha_composite(portrait,(x+54,y+22));text(x+70,y+2,'모스랫',15)
 else:
  silhouette=Image.new('RGBA',portrait.size,(0,0,0,255));silhouette.putalpha(portrait.getchannel('A'));im.alpha_composite(silhouette,(x+54,y+22));text(x+80,y+2,'???',17)
 text(x+80,y+103,str(star)+'★',18)
grad((323,552,741,610),(25,36,43),(9,13,21));grad((326,555,427,607),(103,255,68),(8,138,55));text(494,558,'1/4',32)
grad((757,244,991,470),(30,148,235),(8,31,60))
portrait=face.copy();portrait.thumbnail((143,143));im.alpha_composite(portrait,(800,250));text(825,393,'모스랫',23);text(855,426,'1★',16);text(811,448,'$1 / 3초',18,'#61ff3d')
grad((757,490,991,610),(35,110,57),(13,37,24));text(798,503,'초원 · 0m',18);text(780,540,'길들이기 · 5초',17);text(835,577,'포획 1',17)
box((190,635,990,684),'#11141d');text(432,642,'잠금 해제: 1/4',25)
grad((1027,247,1190,345),(167,250,95),(14,127,67));text(1080,257,'행성',23);text(1042,302,'Green Star',22)
text(216,742,'현재 카탈로그: 모스랫 1·3·6·9성 · 보상 규칙 추가 없음',18)
text(216,779,'미리보기 얼굴은 2D 배치 예시입니다. 실제 화면은 3D 모델로 표시합니다.',15)
im.save(R/'assets/ui/IndexPreview.png')
