"""Static top-view layout from the owner's celestial-island reference."""
import math
from build_project import node, prop

WHITE=(247,232,229); GOLD=(235,188,101); PINK=(246,164,201)
DARK=(38,25,47); RED=(199,47,78); PURPLE=(126,69,161)
SPACING=1.4

def arrange(cafe,p,disk,rotate,ring):
 folders={n.findtext("Properties/string[@name='Name']"):n for n in cafe.findall('Item')}
 structure,decor,furniture,space=(folders[k] for k in ['Structure','Decor','Furniture','SpaceView'])
 # Preserve selected furniture and the two cafe buildings, not the superseded ground.
 keep={'CafeFloor','CafeRoof','CafeBack','CafeSide','CafeColumn','ColumnGold','FacadeBeam','CafeAwning','CoffeeCounter','CounterMarble','PendantCable','Pendant','WarmCeiling','FacadeArch','CafePlanter','CafeShrub'}
 for folder in [structure,decor,space]:
  for n in folder.findall('Item'):
   name=n.findtext("Properties/string[@name='Name']") or ''
   cf=n.find("Properties/CoordinateFrame[@name='CFrame']")
   tower=name.startswith('Tower') and cf is not None and abs(float(cf.find('Z').text)+121)<12 and 190<abs(float(cf.find('X').text))<315
   if name in keep or tower:
    x=float(cf.find('X').text);cf.find('X').text=str(x+(-(1055*SPACING-255) if x<0 else 1055*SPACING-255));cf.find('Z').text=str(float(cf.find('Z').text)-(400+450*(SPACING-1)))
   else:folder.remove(n)
 for n in furniture.iter('Item'):
  cf=n.find("Properties/CoordinateFrame[@name='CFrame']")
  if cf is not None:
   x=float(cf.find('X').text);cf.find('X').text=str(x+(-(1055*SPACING-255) if x<0 else 1055*SPACING-255));cf.find('Z').text=str(float(cf.find('Z').text)-(400+450*(SPACING-1)))
 old=folders.get('GiantGarden')
 if old is not None:cafe.remove(old)
 layout=node(cafe,'Folder','IslandLayout')
 # ID, centre, radius, theme. Circular geometry stays below Roblox's 2048 axis limit.
 zones={
  'Central':(0,0,360,False),
  'RosePalace':(-1000,-1300,470,False),'ShadowPalace':(1000,-1300,470,True),
  'RoseCafe':(-1055,-450,270,False),'ShadowCafe':(1055,-450,270,True),
  'Conservatory':(-1150,180,240,False),'ArcaneLounge':(1150,180,240,True),
  'RoseFountain':(-650,460,180,False),'ShadowFountain':(650,460,180,True),
  'RoseGiantGarden':(-1450,1500,1020,False),'ShadowGiantGarden':(1450,1500,1020,True),
 }
 # Spread centres without inflating islands, furniture, trees or bridge widths.
 zones={name:(x*SPACING,z*SPACING,r,dark) for name,(x,z,r,dark) in zones.items()}
 routes=[('Central','RoseCafe',280),('Central','ShadowCafe',280),('Central','RoseFountain',280),('Central','ShadowFountain',280),('RoseCafe','RosePalace',280),('ShadowCafe','ShadowPalace',280),('RoseCafe','Conservatory',220),('ShadowCafe','ArcaneLounge',220),('Conservatory','RoseGiantGarden',320),('ArcaneLounge','ShadowGiantGarden',320),('RoseFountain','RoseGiantGarden',320),('ShadowFountain','ShadowGiantGarden',320)]
 gates={k:[] for k in zones}
 for a,b,w in routes:
  ax,az,ar,ad=zones[a];bx,bz,br,bd=zones[b];dx,dz=bx-ax,bz-az;length=math.hypot(dx,dz);ux,uz=dx/length,dz/length
  gates[a].append((math.atan2(dz,dx),w));gates[b].append((math.atan2(-dz,-dx),w))
  start=(ax+ux*ar*.65,az+uz*ar*.65);end=(bx-ux*br*.65,bz-uz*br*.65)
  span=math.hypot(end[0]-start[0],end[1]-start[1]);cx,cz=(start[0]+end[0])/2,(start[1]+end[1])/2
  v=p('IslandBridge',(cx,-.1,cz),(w,1.2,span+40),DARK if bd else WHITE,True,parent=layout);rotate(v,y=math.atan2(ux,uz))
  for side in [-1,1]:
   v=p('BridgeGuard',(cx+uz*side*(w/2+2),7,cz-ux*side*(w/2+2)),(4,14,span),RED if bd else GOLD,True,parent=layout);rotate(v,y=math.atan2(ux,uz))
 for name,(x,z,r,dark) in zones.items():
  zone=node(layout,'Model',name)
  ground=DARK if dark else WHITE
  if 'Giant' in name:ground=(51,34,57) if dark else (145,179,137)
  rock=(47,31,57) if dark else (171,145,164)
  for suffix,y,rad,h,col,solid in [('Ground',-.5,r,1,ground,True),('Rock',-30,r*.99,58,rock,False),('Taper',-110,r*.74,105,rock,False),('Tip',-215,r*.35,120,rock,False)]:
   v=disk(name+suffix,x,y,z,rad,h,col,solid);zone.append(v)
   # append moves are explicit because ElementTree does not reparent automatically.
   for parent in [structure,decor]:
    if v in list(parent):parent.remove(v)
  segments=64 if r>500 else 40
  for i in range(segments):
   a=i*math.tau/segments
   open_gate=any(abs(math.atan2(math.sin(a-ga),math.cos(a-ga)))<math.asin(min(.95,(w/2+45)/r)) for ga,w in gates[name])
   if open_gate:continue
   v=p('IslandEdge',(x+math.cos(a)*(r-3),6,z+math.sin(a)*(r-3)),(r*math.tau/segments+1,12,3),RED if dark else GOLD,True,parent=zone);rotate(v,y=math.pi/2-a)
  # Jagged hanging rock silhouettes, non-interactive and static.
  for i in range(10):
   a=i*math.tau/10;v=p('HangingRock',(x+math.cos(a)*r*.73,-112,z+math.sin(a)*r*.73),(r*.18,190,r*.22),rock,parent=zone);v.set('class','WedgePart');rotate(v,y=-a)
  if name!='Central':
   for i in range(3):
    a=(i+1)*math.pi/2
    p('LavaFall' if dark else 'Waterfall',(x+math.cos(a)*r*.92,-140,z+math.sin(a)*r*.92),(max(8,r*.035),280,1.5),RED if dark else (136,213,247),parent=zone,mat=288)
  if 'Giant' in name:
   # The centre remains open. The circular route is a visual guide, not a forced track.
   ring(name+'Trail',x,.15,z,r*.70,(83,50,66) if dark else (217,192,151),segments=72,width=65,height=.2)
   for i in range(18):
    a=i*math.tau/18
    if any(abs(math.atan2(math.sin(a-ga),math.cos(a-ga)))<.3 for ga,w in gates[name]):continue
    tx,tz=x+math.cos(a)*r*.87,z+math.sin(a)*r*.87
    if dark:
     for dx,h in [(-18,42),(0,78),(18,56)]:
      v=p('GardenCrystal',(tx+dx,h/2,tz),(15,h,15),PURPLE,parent=zone);v.set('class','WedgePart');rotate(v,y=a)
    else:
     p('CherryTrunk',(tx,24,tz),(8,48,8),(103,72,84),parent=zone)
     for dx,dy,dz in [(-22,61,0),(22,61,0),(0,78,8)]:p('CherryCrown',(tx+dx,dy,tz+dz),(70,49,62),PINK,parent=zone,shape=0)
  elif name!='Central':
   for i in range(8):
    a=i*math.tau/8
    if any(abs(math.atan2(math.sin(a-ga),math.cos(a-ga)))<.4 for ga,w in gates[name]):continue
    tx,tz=x+math.cos(a)*r*.8,z+math.sin(a)*r*.8
    p('GardenTrunk',(tx,14,tz),(4,28,4),(86,60,85),parent=zone)
    for dx in [-9,9]:p('GardenCrown',(tx+dx,34,tz),(34,28,33),PURPLE if dark else PINK,parent=zone,shape=0)
  if 'Palace' in name:
   trim=RED if dark else GOLD;body=DARK if dark else WHITE
   for dx,h in [(-150,135),(0,230),(150,135)]:
    p('PalaceHall',(x+dx,h/2,z-100),(130,h,125),body,True,parent=zone)
    v=p('PalaceRoof',(x+dx,h+28,z-100),(150,65,145),PURPLE if dark else PINK,parent=zone);v.set('class','WedgePart')
    for ox in [-48,0,48]:p('PalaceWindow',(x+dx+ox,h*.57,z-36),(13,h*.58,1.5),trim,parent=zone,mat=288)
   for dx,dz,h in [(-250,-140,180),(250,-140,180),(-200,30,120),(200,30,120),(-70,-195,250),(70,-195,250)]:
    p('PalaceTower',(x+dx,h/2,z+dz),(24,h,24),body,True,parent=zone)
    v=p('PalaceSpire',(x+dx,h+30,z+dz),(40,70,40),trim,parent=zone);v.set('class','WedgePart')
   ring('PalaceForecourt',x,.15,z+120,130,trim,segments=32,width=5,height=.2)
  elif 'Fountain' in name:
   for radius,y,h in [(55,3,6),(27,13,6),(12,22,8)]:
    v=disk('FountainTier',x,y,z,radius,h,RED if dark else WHITE,True);structure.remove(v);zone.append(v)
   p('FountainCrystal',(x,45,z),(9,42,9),PURPLE if dark else (147,224,255),parent=zone,mat=288)
  elif name in ['Conservatory','ArcaneLounge']:
   body=DARK if dark else WHITE;trim=RED if dark else GOLD
   for dx in [-85,85]:p('PavilionWall',(x+dx,34,z-25),(8,68,125),body,True,parent=zone)
   p('PavilionBack',(x,34,z-90),(175,68,8),body,True,parent=zone)
   p('PavilionRoof',(x,72,z-25),(185,8,140),PURPLE if dark else PINK,True,parent=zone)
   for dx in range(-70,71,28):p('PavilionWindow',(x+dx,38,z-84),(20,48,1),trim,parent=zone,mat=288)
 # Landmark at the arrival hub; lanes around it remain unobstructed.
 ring('HubInlay',0,.15,0,250,GOLD,segments=48,width=3,height=.2)
 # Small vista islands lie in the gap, without interactive collision or scripts.
 # Giant playgrounds: readable pitch borders and a running circuit, kept open.
 for name in ['RoseGiantGarden','ShadowGiantGarden']:
  x,z,r,dark=zones[name];field=node(layout,'Folder',name+'SportsMarkings')
  col=(179,155,202) if dark else (255,242,249)
  for dx in [-410,410]:p('SportsSideline',(x+dx,.12,z),(5,.1,980),col,parent=field)
  for dz in [-490,490]:p('SportsEndline',(x,.12,z+dz),(825,.1,5),col,parent=field)
  p('SportsHalfway',(x,.12,z),(825,.1,5),col,parent=field)
  ring('SportsCentreCircle',x,.12,z,110,col,segments=32,width=5,height=.1)
  for dz in [-400,400]:
   p('SportsGoalLine',(x,.12,z+dz),(300,.1,5),col,parent=field)
   for dx in [-150,150]:p('SportsGoalSide',(x+dx,.12,z+dz+(45 if dz>0 else -45)),(5,.1,90),col,parent=field)
 for x,z,r in [(-420,-900,65),(430,-880,65),(0,-1350,70),(-220,1050,55),(240,950,55),(0,1950,70)]:
  x,z=x*SPACING,z*SPACING
  v=disk('VistaIsland',x,45,z,r,25,PURPLE);decor.remove(v);space.append(v)
  p('VistaCrystal',(x,110,z),(10,80,10),PURPLE if z>0 else GOLD,parent=space,mat=288)
 for x,col in [(-1900,(160,128,213)),(1900,(36,19,43))]:
  x=x*SPACING;planet_z=-2250*SPACING
  p('BackgroundPlanet',(x,700,planet_z),(620,620,620),col,parent=space,shape=0)
  for i in range(40):
   a=i*math.tau/40
   v=p('BackgroundOrbit',(x+math.cos(a)*410,700+math.sin(a)*110,planet_z+math.sin(a)*180),(68,3,5),RED if x>0 else GOLD,parent=space,mat=288);rotate(v,y=-a)
 spawn=p('CafeArrival',(0,1,220),(16,1,16),WHITE,False,parent=layout);spawn.set('class','SpawnLocation');prop(spawn,'float','Transparency',1);prop(spawn,'float','Duration',0);prop(spawn,'bool','Neutral','true')
 return zones,routes
