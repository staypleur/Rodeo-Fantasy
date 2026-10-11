"""Curated static cafe landscaping; reuse asset IDs rather than full source packs."""
from pathlib import Path
import copy, math, xml.etree.ElementTree as E
import numpy as np
from build_project import node, prop

R=Path(__file__).resolve().parents[1]

def decorate(cafe,zones,p,rotate):
 libraries=[E.parse(R/'assets/maps'/f).getroot() for f in
            ['CafeSakura.rbxmx','CafeNatureCurated.rbxmx','CafeCuratedFurniture.rbxmx','CafeTablePlant.rbxmx']]
 templates={v.findtext("Properties/string[@name='Name']"):v for lib in libraries for v in lib.findall('Item')}
 landscape=node(cafe,'Folder','CuratedLandscape')
 # Replace the primitive tree placeholders rather than layering new trees over them.
 for parent in cafe.iter('Item'):
  for v in parent.findall('Item'):
   if v.findtext("Properties/string[@name='Name']") in {'GardenTrunk','GardenCrown','CherryTrunk','CherryCrown'}:parent.remove(v)

 def origin(model):
  corners=[]
  for v in model.iter('Item'):
   cf=v.find("Properties/CoordinateFrame[@name='CFrame']");size=v.find("Properties/Vector3[@name='size']")
   if cf is None or size is None:continue
   pos=np.array([float(cf.findtext(k)) for k in 'XYZ'])
   mat=np.array([[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)])
   half=np.array([float(size.findtext(k))/2 for k in 'XYZ'])
   for x in [-1,1]:
    for y in [-1,1]:
     for z in [-1,1]:corners.append(pos+mat@(half*np.array([x,y,z])))
  lo=np.min(corners,axis=0);hi=np.max(corners,axis=0)
  return np.array([(lo[0]+hi[0])/2,lo[1],(lo[2]+hi[2])/2])

 def place(name,pos,scale=1,yaw=0,purple=False,seating=False):
  v=copy.deepcopy(templates[name]);base=origin(v)
  c,s=math.cos(yaw),math.sin(yaw);rot=np.array([[c,0,s],[0,1,0],[-s,0,c]])
  refs={n.get('referent'):f'CafeLandscape{len(landscape)}_{i}' for i,n in enumerate(v.iter('Item'))}
  for n in v.iter('Item'):
   n.set('referent',refs[n.get('referent')]);props=n.find('Properties')
   for e in list(props):
    if e.tag=='UniqueId' or e.get('name') in ['TexturePack','WorldPivotData','ModelMeshData']:props.remove(e)
   for e in n.iter('Ref'):
    if e.text in refs:e.text=refs[e.text]
   cf=n.find("Properties/CoordinateFrame[@name='CFrame']");size=n.find("Properties/Vector3[@name='size']")
   if cf is not None and size is not None:
    old=np.array([float(cf.findtext(k)) for k in 'XYZ']);new=np.array(pos)+rot@((old-base)*scale)
    mat=rot@np.array([[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)])
    for k,value in zip('XYZ',new):cf.find(k).text=str(value)
    for i in range(3):
     for j in range(3):cf.find(f'R{i}{j}').text=str(mat[i,j])
    for k in 'XYZ':size.find(k).text=str(float(size.findtext(k))*scale)
    prop(n,'bool','Anchored','true');prop(n,'bool','CanCollide',str(seating and n.get('class') in ['Seat','UnionOperation']).lower())
    prop(n,'bool','CanTouch',str(n.get('class')=='Seat').lower());prop(n,'bool','CanQuery','false');prop(n,'bool','CastShadow','false')
    if n.get('class')=='UnionOperation':prop(n,'token','CollisionFidelity',1)
    if name=='CafeSakuraSource' and n.findtext("Properties/string[@name='Name']")=='Leaves' and purple:
     prop(n,'Color3uint8','Color3uint8',0xff9e71c5)
   if n.get('class')=='SpecialMesh':
    size=n.find("Properties/Vector3[@name='Scale']")
    if size is not None:
     for k in 'XYZ':size.find(k).text=str(float(size.findtext(k))*scale)
  landscape.append(v);return v

 # Trees at scenic edges; leave bridge directions and the riding lawn open.
 for name,(x,z,r,dark) in zones.items():
  if name=='Central':continue
  count=12 if 'Giant' in name else 4
  near=[]
  for other,(ox,oz,orr,od) in zones.items():
   if other==name:continue
   if ('Giant' in name and (other.endswith('Fountain') or other in ['Conservatory','ArcaneLounge'])) or ('Giant' not in name):
    near.append(math.atan2(oz-z,ox-x))
  for i in range(count):
   a=(i+.5)*math.tau/count
   if any(abs(math.atan2(math.sin(a-g),math.cos(a-g)))<.27 for g in near):continue
   tx,tz=x+math.cos(a)*r*.83,z+math.sin(a)*r*.83
   place('CafeSakuraSource',(tx,0,tz),2.8 if 'Giant' in name else 1.6,a,dark)
   # Two distinct rock shapes reuse the same meshes and materials across beds.
   if i%2==0:
    place('MediumMossBoulder01',(tx-18,0,tz+12),2.3,a)
    place('SmallRock01',(tx+18,0,tz-7),2,a+.8)

 # Human-scale outdoor lounges beside each cafe, not in giant-pet travel lanes.
 for name in ['RoseCafe','ShadowCafe']:
  x,z,r,dark=zones[name];accent=(132,88,152) if dark else (246,180,206)
  for side in [-1,1]:
   cx,cz=x+side*95,z+38
   p('LoungeTerrace',(cx,.5,cz),(62,1,54),(91,60,103) if dark else (219,189,160),True,parent=landscape)
   p('OutdoorRug',(cx,1.03,cz),(28,.05,26),accent,parent=landscape)
   place('Couch_Single',(cx-10,1,cz),yaw=math.pi/2,seating=True)
   place('Couch_Single',(cx+10,1,cz),yaw=-math.pi/2,seating=True)
   place('Furniture_CoffeeTable',(cx,1,cz))
   place('Furniture_FloorLamp_Off',(cx+18,1,cz-14))
   place('CafeTablePlant',(cx,2.6,cz),.8)
   for dz in [-19,19]:
    p('BorderPlanter',(cx,2,cz+dz),(38,2,5),accent,parent=landscape)
    for dx in [-13,0,13]:
     place('RhododendronVar01',(cx+dx,3,cz+dz),1.15,dx*.1)
     place('WildFlower03',(cx+dx+3,3,cz+dz),1.2)
  # Approach stones and planted borders use a few repeated source meshes.
  for dx in [-57,57]:
   for dz in [-72,-38,-4]:place('RhododendronVar01',(x+dx,0,z+dz),1.8)
 # Shared payloads needed by imported geometry only; no full source pack remains.
 shared={}
 for lib in libraries:
  for v in lib.findall('SharedStrings/SharedString'):shared[v.get('md5')]=copy.deepcopy(v)
 return list(shared.values())
