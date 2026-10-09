"""Export and render the exact same native box geometry for design review."""
from pathlib import Path
import math,itertools,xml.etree.ElementTree as E
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
def save_review(parts,model_name,title,note):
 root=E.Element('roblox',version='4');model=E.SubElement(root,'Item',{'class':'Model','referent':model_name})
 props=E.SubElement(model,'Properties');E.SubElement(props,'string',name='Name').text=model_name
 for index,(name,pos,size,color,matrix) in enumerate(parts):
  item=E.SubElement(model,'Item',{'class':'Part','referent':f'GardenPart{index}'})
  p=E.SubElement(item,'Properties');E.SubElement(p,'string',name='Name').text=name
  for key,value in [('Anchored','true'),('CanCollide','true'),('CanTouch','false')]:E.SubElement(p,'bool',name=key).text=value
  E.SubElement(p,'token',name='Material').text='272'
  E.SubElement(p,'token',name='TopSurface').text='0';E.SubElement(p,'token',name='BottomSurface').text='0'
  E.SubElement(p,'Color3uint8',name='Color3uint8').text=str(color[0]*65536+color[1]*256+color[2])
  cf=E.SubElement(p,'CoordinateFrame',name='CFrame');dims=E.SubElement(p,'Vector3',name='size')
  for j,a in enumerate('XYZ'):E.SubElement(cf,a).text=str(pos[j]);E.SubElement(dims,a).text=str(size[j])
  for i in range(3):
   for j in range(3):E.SubElement(cf,f'R{i}{j}').text=str(matrix[i,j])
 folder=R/'dist/ReviewModels';folder.mkdir(parents=True,exist_ok=True)
 E.ElementTree(root).write(folder/(model_name+'.rbxmx'),encoding='utf-8',xml_declaration=True)
 # Orthographic render of actual geometry, no generated concept art.
 image=Image.new('RGB',(1500,1020),(234,237,226));draw=ImageDraw.Draw(image)
 eye=np.array((.72,.85,-1.1));eye/=np.linalg.norm(eye);right=np.cross((0,1,0),eye);right/=np.linalg.norm(right);up=np.cross(eye,right)
 vertices=[];faces=[]
 faceids=[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]
 for name,pos,size,color,matrix in parts:
  corners=np.array(list(itertools.product((-1,1),repeat=3)))*size/2
  world=corners@matrix.T+pos
  for ids in faceids:
   q=world[list(ids)];n=np.cross(q[1]-q[0],q[2]-q[0]);n/=np.linalg.norm(n)
   if n@eye<=0:continue
   shade=.66+.34*max(0,float(n@np.array((-.3,.85,-.4))))
   faces.append((float(q.mean(axis=0)@eye),q,tuple(int(c*shade) for c in color)))
  allp=world
  vertices.extend(allp)
 v=np.array(vertices);px=v@right;py=v@up
 scale=min(1380/(px.max()-px.min()),870/(py.max()-py.min()));cx=(px.max()+px.min())/2;cy=(py.max()+py.min())/2
 pixels=np.full((1020,1500,3),(234,237,226),dtype=np.uint8)
 depths=np.full((1020,1500),-np.inf)
 for _,q,col in faces:
  for ids in ((0,1,2),(0,2,3)):
   t=q[list(ids)];sx=(t@right-cx)*scale+750;sy=-(t@up-cy)*scale+560;z=t@eye
   x0=max(0,int(sx.min()));x1=min(1499,int(math.ceil(sx.max())))
   y0=max(0,int(sy.min()));y1=min(1019,int(math.ceil(sy.max())))
   if x0>x1 or y0>y1:continue
   denom=(sy[1]-sy[2])*(sx[0]-sx[2])+(sx[2]-sx[1])*(sy[0]-sy[2])
   if abs(denom)<1e-8:continue
   yy,xx=np.mgrid[y0:y1+1,x0:x1+1];xx=xx+.5;yy=yy+.5
   a=((sy[1]-sy[2])*(xx-sx[2])+(sx[2]-sx[1])*(yy-sy[2]))/denom
   b=((sy[2]-sy[0])*(xx-sx[2])+(sx[0]-sx[2])*(yy-sy[2]))/denom
   c=1-a-b;d=a*z[0]+b*z[1]+c*z[2]
   region=depths[y0:y1+1,x0:x1+1];mask=(a>=-1e-6)&(b>=-1e-6)&(c>=-1e-6)&(d>region)
   region[mask]=d[mask];pixels[y0:y1+1,x0:x1+1][mask]=col
 image=Image.fromarray(pixels);draw=ImageDraw.Draw(image)
 font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',29);small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',18)
 draw.text((30,18),title,font=font,fill=(37,74,68))
 subtitle=note
 draw.text((30,60),f'실제 Roblox Part 모델 {len(parts)}개 · Studio 화면 아님 · {subtitle}',font=small,fill=(73,94,83))
 out=R/'assets/previews'/(model_name+'.png');out.parent.mkdir(parents=True,exist_ok=True);image.save(out)
 return out
