"""Render properties created by the actual JournalUI callbacks in an offline stub.
Not a Roblox screenshot; font and viewport lighting are approximations.
"""
from pathlib import Path
import sys,json,subprocess,struct,io
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R/'tests'))
import check_journal_book as test
extra=r'''
width=1000 book.state({area='Lobby'})
find('FieldJournal'):GetPropertyChangedSignal('AbsoluteSize'):fire()
book.open()
local function encode(v)
 if type(v)=='string' then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')..'"' end
 if type(v)=='boolean' or type(v)=='number' then return tostring(v) end
 if type(v)=='table' then local a={} for _,n in ipairs(v) do table.insert(a,encode(n)) end return '['..table.concat(a,',')..']' end
 return 'null'
end
local keys={'Name','Text','PlaceholderText','Size','Position','AnchorPoint','BackgroundColor3','BackgroundTransparency','Visible','ZIndex','TextColor3','TextSize','TextScaled','Color','Rotation','Thickness','monsterId','stars','black'}
local ids={} for i,n in ipairs(nodes) do ids[n]=i end
for i,n in ipairs(nodes) do
 if not n.destroyed then
  local p={} for _,k in ipairs(keys) do if n[k]~=nil then table.insert(p,'"'..k..'":'..encode(k=='AnchorPoint' and {n[k].X,n[k].Y} or n[k])) end end
  print('NODE '..'{"id":'..i..',"parent":'..(ids[n.Parent] or 0)..',"class":"'..n.ClassName..'","props":{'..table.concat(p,',')..'}}')
 end
end
'''
bag='--bag' in sys.argv
if bag:
 setup="\nbook.close()\nlocal ColorSequenceKeypoint={new=function(t,c) return {t,c} end}\nlocal cfg="+test.mod('src/shared/Config.luau')+"\npackage.Config=cfg script.Parent.IncomeEffects={}\nlocal Bag=(function()\n"+(R/'src/client/BagUI.luau').read_text(encoding='utf-8')+"\nend)()\nlocal bagUI=Bag.new(gui,{FireServer=function() end})\nbagUI.snapshot({{id=1,monsterId='MeadowMouse',stars=1,sex='Male',incomeSeconds=3,incomeAmount=1},{id=2,monsterId='MeadowMouse',stars=1,sex='Female',incomeSeconds=3,incomeAmount=1}})\nbagUI.state({area='Lobby',count=2,pending=0})\nbagUI.toggle()\n"
 extra=setup+extra[extra.index('local function encode'):]
p=R/'.tools/journal_review_dump.luau';p.write_text(test.code+extra,encoding='utf-8')
result=subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True,capture_output=True,text=True,encoding='utf-8')
nodes=[json.loads(line[5:]) for line in result.stdout.splitlines() if line.startswith('NODE ')]
byid={n['id']:n for n in nodes}
fontpath='C:/Windows/Fonts/malgun.ttf'
def rgb(v):return tuple(round(x*255) for x in v)
def rect(n,W,H):
 if n['class']=='ScreenGui':return (0,60,W,H-60)
 parent=byid.get(n['parent']);pr=rect(parent,W,H) if parent else (0,60,W,H-60)
 s=n['props'].get('Size',[1,0,1,0]);p=n['props'].get('Position',[0,0,0,0]);a=n['props'].get('AnchorPoint',[0,0])
 w=pr[2]*s[0]+s[1];h=pr[3]*s[2]+s[3]
 if n['props'].get('Name')=='FieldJournal':w=min(w,1200);h=min(h,780)
 if n['props'].get('Name')=='BagWindow':w=min(w,1100);h=min(h,720)
 x=pr[0]+pr[2]*p[0]+p[1]-w*a[0];y=pr[1]+pr[3]*p[2]+p[3]-h*a[1]
 if parent and parent['props'].get('Name')=='JournalRegions' and n['class']=='TextButton':
  siblings=[v for v in nodes if v['parent']==parent['id'] and v['class']=='TextButton']
  y+=siblings.index(n)*50
 if parent and parent['props'].get('Name')=='BagCards' and n['props'].get('Name')=='MonsterCard':
  siblings=[v for v in nodes if v['parent']==parent['id'] and v['props'].get('Name')=='MonsterCard'];index=siblings.index(n);cols=max(1,int((pr[2]+12)/182))
  x+=index%cols*182;y+=index//cols*257
 if parent and parent['props'].get('Name')=='BagRegions' and n['class']=='TextButton':
  siblings=[v for v in nodes if v['parent']==parent['id'] and v['class']=='TextButton'];x+=siblings.index(n)*120
 return (x,y,w,h)
def visible(n):
 if n['props'].get('Visible') is False:return False
 parent=byid.get(n['parent']);return visible(parent) if parent else True
def thumbnail(size,id,stars,black):
 path=R/'dist/ReviewModels/MeadowMouse_A_S1_FacetedReview.glb' if id=='MeadowMouse' and stars==1 else R/f'dist/CreatureModels/{id}_A_S{stars}.glb'
 if not path.exists():return Image.new('RGBA',size)
 data=path.read_bytes();count=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+count]);blob=data[28+count:]
 def values(index):
  a=g['accessors'][index];b=g['bufferViews'][a['bufferView']];dtype={5126:'<f4',5123:'<u2',5125:'<u4'}[a['componentType']];dim={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
  return np.frombuffer(blob,dtype=dtype,count=a['count']*dim,offset=b.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,dim)
 tex=None
 if not black and g.get('images'):
  b=g['bufferViews'][g['images'][0]['bufferView']];tex=np.array(Image.open(io.BytesIO(blob[b['byteOffset']:b['byteOffset']+b['byteLength']])).convert('RGB'))
 triangles=[]
 for mesh in g['meshes']:
  for primitive in mesh['primitives']:
   pos=values(primitive['attributes']['POSITION']);ids=values(primitive['indices']).reshape(-1,3)
   uv=values(primitive['attributes']['TEXCOORD_0']) if tex is not None else None
   for indices in ids:triangles.append((pos[indices],uv[indices] if uv is not None else None))
 if not triangles:return Image.new('RGBA',size)
 eye=np.array((.6,.35,-1));eye/=np.linalg.norm(eye);right=np.cross(eye,(0,1,0));right/=np.linalg.norm(right);up=np.cross(right,eye)
 points=np.concatenate([p for p,_ in triangles]);xy=np.stack((points@right,points@up),axis=-1);lo=xy.min(axis=0);hi=xy.max(axis=0);middle=(lo+hi)/2
 scale=min(size[0]*.80/(hi[0]-lo[0]),size[1]*.85/(hi[1]-lo[1]))
 image=Image.new('RGBA',size);draw=ImageDraw.Draw(image)
 if tex is not None:
  frame=np.zeros((size[1],size[0],4),dtype=np.uint8);depth=np.full((size[1],size[0]),-np.inf)
  for p,uv in triangles:
   sx=(p@right-middle[0])*scale+size[0]/2;sy=-(p@up-middle[1])*scale+size[1]/2;z=p@eye
   x0=max(0,int(np.floor(sx.min())));x1=min(size[0]-1,int(np.ceil(sx.max())))
   y0=max(0,int(np.floor(sy.min())));y1=min(size[1]-1,int(np.ceil(sy.max())))
   denom=(sy[1]-sy[2])*(sx[0]-sx[2])+(sx[2]-sx[1])*(sy[0]-sy[2])
   if x0>x1 or y0>y1 or abs(denom)<1e-8:continue
   yy,xx=np.mgrid[y0:y1+1,x0:x1+1];xx=xx+.5;yy=yy+.5
   a=((sy[1]-sy[2])*(xx-sx[2])+(sx[2]-sx[1])*(yy-sy[2]))/denom
   b=((sy[2]-sy[0])*(xx-sx[2])+(sx[0]-sx[2])*(yy-sy[2]))/denom;c=1-a-b
   zz=a*z[0]+b*z[1]+c*z[2];old=depth[y0:y1+1,x0:x1+1]
   mask=(a>=-1e-5)&(b>=-1e-5)&(c>=-1e-5)&(zz>old)
   tuv=a[...,None]*uv[0]+b[...,None]*uv[1]+c[...,None]*uv[2]
   tx=np.clip((tuv[...,0]*tex.shape[1]).astype(int),0,tex.shape[1]-1);ty=np.clip((tuv[...,1]*tex.shape[0]).astype(int),0,tex.shape[0]-1)
   patch=frame[y0:y1+1,x0:x1+1];patch[mask,:3]=tex[ty,tx][mask];patch[mask,3]=255;old[mask]=zz[mask]
  return Image.fromarray(frame)
 for p,uv in sorted(triangles,key=lambda item:np.mean(item[0]@eye)):
  color=(15,13,12)
  if tex is not None:
   sample=uv.mean(axis=0);color=tuple(tex[min(int(sample[1]*len(tex)),len(tex)-1),min(int(sample[0]*tex.shape[1]),tex.shape[1]-1)])
  coords=list(zip((p@right-middle[0])*scale+size[0]/2,-(p@up-middle[1])*scale+size[1]/2))
  draw.polygon(coords,fill=color)
 return image
W,H=1280,900
image=Image.new('RGB',(W,H),(31,42,36));draw=ImageDraw.Draw(image)
draw.text((20,15),'가방 실제 UI 속성 검토 · 예시 수컷/암컷 · Studio 화면 아님' if bag else '도감 실제 UI 속성 검토 · 예시 9마리 포획 · Studio 화면/실제 사용자 기록 아님',font=ImageFont.truetype(fontpath,19),fill=(244,230,195))
def layer(n):
 if 'ZIndex' in n['props']:return n['props']['ZIndex']
 parent=byid.get(n['parent']);return layer(parent) if parent else 1
for n in sorted(nodes,key=layer):
 if not visible(n):continue
 prop=n['props'];x,y,w,h=rect(n,W,H)
 if w<=0 or h<=0:continue
 if n['class'] in ('Frame','TextButton','TextLabel','TextBox','ScrollingFrame') and prop.get('BackgroundTransparency',0)<1 and prop.get('BackgroundColor3'):
  col=rgb(prop['BackgroundColor3']);gradient=next((c for c in nodes if c['parent']==n['id'] and c['class']=='UIGradient'),None)
  if gradient:
   colors=gradient['props']['Color'];a,b=(colors[0][0][1],colors[0][-1][1]) if len(colors)==1 else colors[0:2]
   for line in range(max(1,int(h))):
    t=line/max(1,h-1);color=tuple(round(255*(a[i]*(1-t)+b[i]*t)) for i in range(3));draw.line((x,y+line,x+w,y+line),fill=color)
  else:draw.rounded_rectangle((x,y,x+w,y+h),radius=4,fill=col)
 if n['class']=='UIStroke':
  parent=byid.get(n['parent']);color=rgb(prop.get('Color',[.5,.5,.5]));thickness=max(1,int(prop.get('Thickness',1)))
  if parent and parent['props'].get('Name')=='SexRing':draw.ellipse((x,y,x+w,y+h),outline=color,width=thickness)
  else:draw.rounded_rectangle((x,y,x+w,y+h),radius=4,outline=color,width=thickness)
 if n['class']=='ViewportFrame':
  thumb=thumbnail((max(1,int(w)),max(1,int(h))),prop.get('monsterId',''),prop.get('stars',1),prop.get('black',False));image.paste(thumb,(int(x),int(y)),thumb)
 if prop.get('Text') or (n['class']=='TextBox' and prop.get('PlaceholderText')):
  value=prop.get('Text') or prop['PlaceholderText'];size=int(prop.get('TextSize',18));constraint=next((c for c in nodes if c['parent']==n['id'] and c['class']=='UITextSizeConstraint'),None)
  if prop.get('TextScaled'):size=min(19,int(h*.55)) if prop.get('Name')!='UndiscoveredQuestion' else 48
  size=max(10,size);font=ImageFont.truetype(fontpath,size)
  while font.getlength(value)>w-6 and size>10:size-=1;font=ImageFont.truetype(fontpath,size)
  draw.text((x+w/2,y+h/2),value,font=font,fill=rgb(prop.get('TextColor3',[.2,.2,.2])),anchor='mm')
out=R/('assets/previews/bag-ochre-review.png' if bag else 'assets/previews/journal-book-review.png');image.save(out);print(out)
