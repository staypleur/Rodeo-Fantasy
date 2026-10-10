"""Show HUD composition only; the background is not the live Roblox lobby."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];W,H=1250,820
im=Image.new('RGBA',(W,H),(37,54,78,255));d=ImageDraw.Draw(im)
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/malgunbd.ttf',n)
d.text((220,22),'UI 배치 검토안 · 실제 Studio 화면 아님',font=font(23),fill='white')
def label(x,y,t,n=24,color='white'):d.text((x,y),t,font=font(n),fill=color,stroke_width=2,stroke_fill='black')
for text,color,offset in [('룰렛',(255,191,31),-90),('상점',(100,255,12),-26),('도감',(15,216,255),38)]:
 y=int(H*.42+offset);d.rounded_rectangle((8,y,152,y+56),5,fill=color,outline='black',width=2);label(62,y+10,text)
 if text=='상점':
  d.polygon([(23,y+22),(53,y+19),(48,y+36),(29,y+36)],fill='white',outline='black');d.line((18,y+15,24,y+16,28,y+36),fill='black',width=3)
  for x in [31,46]:d.ellipse((x-3,y+41,x+3,y+47),fill='white',outline='black',width=2)
 elif text=='도감':
  d.rounded_rectangle((22,y+13,50,y+43),3,fill='white',outline='black',width=2)
  for yy in [23,29,35]:d.line((29,y+yy-10,44,y+yy-10),fill='black',width=2)
 else:
  d.ellipse((18,y+11,52,y+45),fill='#ffdc30',outline='black',width=2)
  for x,z in [(22,20),(39,15),(43,32),(25,36)]:d.ellipse((x,y+z,x+7,y+z+7),fill='#ff657a',outline='black')
for kind,color,offset in [('egg','#ff5350',-26),('paw','#ffa036',38)]:
 x=W-64;y=int(H*.42+offset);d.rounded_rectangle((x,y,x+56,y+56),5,fill=color,outline='black',width=2)
 if kind=='egg':d.ellipse((x+16,y+8,x+42,y+47),fill='#ffd391',outline='black',width=2)
 else:
  d.ellipse((x+15,y+26,x+42,y+48),fill='#ffc67c',outline='black',width=2)
  for xx,yy in [(7,18),(17,9),(30,9),(41,18)]:d.ellipse((x+xx,y+yy,x+xx+10,y+yy+15),fill='#ffd197',outline='black',width=2)
face=Image.open(R/'assets/ui/MossratFace.png').convert('RGBA');face.thumbnail((42,42));im.alpha_composite(face,(8,H-90))
label(56,H-88,'1',30)
d.polygon([(8,H-42),(34,H-50),(48,H-37),(46,H-17),(20,H-9),(6,H-21)],fill='#83ff38',outline='black')
d.line((28,H-49,36,H-13),fill='#efda1f',width=7)
label(56,H-48,'$702.4K',30,'#36ff09')
label(W-95,H-60,'가방',20)
im.save(R/'assets/ui/LobbyHudPreview.png')
