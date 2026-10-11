"""Unpublished cafe review: user-approved direction, final layout awaiting review."""
from pathlib import Path
import math,copy,xml.etree.ElementTree as E
from build_project import node,prop,composite,part,script
from cafe_island_layout import arrange
from cafe_landscape import decorate
R=Path(__file__).resolve().parents[1]
WHITE=(247,232,229);PINK=(241,158,195);GOLD=(235,188,101);DARK=(43,31,61);VIOLET=(126,69,161)
def build():
 root=E.Element('roblox',version='4');ws=node(root,'Workspace','Workspace');node(ws,'Terrain','Terrain');prop(ws,'bool','StreamingEnabled','true');prop(ws,'int','StreamingMinRadius',64);prop(ws,'int','StreamingTargetRadius',256);cafe=node(ws,'Model','RodeoCafe')
 structure=node(cafe,'Folder','Structure');dec=node(cafe,'Folder','Decor');furniture=node(cafe,'Folder','Furniture');space=node(cafe,'Folder','SpaceView')
 def p(name,pos,size,col,solid=False,parent=None,mat=256,shape=1):
  v=part(parent if parent is not None else structure if solid else dec,name,list(pos),list(size),col)
  prop(v,'bool','CanCollide',str(solid).lower());prop(v,'bool','CanQuery',str(solid).lower());prop(v,'bool','CanTouch','false');prop(v,'bool','CastShadow',str(solid).lower());prop(v,'token','Material',mat);prop(v,'token','shape',shape)
  for face in ['Top','Bottom','Left','Right','Front','Back']:prop(v,'token',face+'Surface',0)
  return v
 def rotate(v,y=0,z=0):
  cf=v.find("Properties/CoordinateFrame[@name='CFrame']");cy,sy,cz,sz=math.cos(y),math.sin(y),math.cos(z),math.sin(z)
  for key,value in zip(['R00','R01','R02','R10','R11','R12','R20','R21','R22'],[cy*cz,-cy*sz,sy,sz,cz,0,-sy*cz,sy*sz,cy]):cf.find(key).text=str(value)
 def disk(name,x,y,z,r,h,color,solid=False):
  v=p(name,(x,y,z),(h,r*2,r*2),color,solid,shape=2);rotate(v,z=math.pi/2);return v
 def ring(name,x,y,z,r,color,segments=24,width=1,height=.5):
  for i in range(segments):
   a=i*math.tau/segments;v=p(name,(x+math.cos(a)*r,y,z+math.sin(a)*r),(r*math.tau/segments+.3,height,width),color);rotate(v,y=math.pi/2-a)
 def island(name,x,z,r,color):
  disk(name+'Rock',x,-8,z,r,16,color,True);disk(name+'Ground',x,.25,z,r-.8,.5,WHITE if x<=0 else (65,44,79),True)
  ring(name+'Edge',x,3,z,r-1,GOLD if x<=0 else VIOLET,width=1.5,height=6)
  # Static tapered underside, kept outside the playable collision surface.
  for i,(radius,y,h) in enumerate([(r*.8,-23,20),(r*.56,-44,24),(r*.27,-66,22)]):disk(name+'FloatingRock',x,y,z,radius,h,color)
 island('Central',0,0,93,(105,78,139));island('RoseGarden',-230,-35,135,(174,140,157));island('TwilightGarden',230,-35,135,(67,42,80))
 # Wide, flat bridges: preserve a level route for every monster size.
 for x in [-105,105]:
  p('GrandBridge',(x,.7,0),(78,1.4,42),WHITE if x<0 else (73,48,88),True)
  for z in [-22,22]:
   p('BridgeRail',(x,3.5,z),(78,5,1),GOLD if x<0 else VIOLET,True)
   for dx in [-30,0,30]:p('BridgePillar',(x+dx,4,z),(2,8,2),WHITE if x<0 else DARK,True)
 # Central astronomy monument sits at the rear, leaving a huge clear arrival plaza.
 disk('AstralDais',0,1,-38,24,2,(161,119,205),True);ring('DaisGold',0,2.1,-38,22,GOLD)
 p('AstralStem',(0,12,-38),(2,22,2),(206,150,255),False,mat=288)
 p('AstralPlanet',(0,33,-38),(22,22,22),(170,130,246),False,mat=288,shape=0)
 for i in range(24):
  a=i*math.tau/24;v=p('AstralOrbit',(math.cos(a)*18,33+math.sin(a)*6,-38+math.sin(a)*12),(5,.5,1),GOLD);rotate(v,y=-a)
 ring('PlazaInlay',0,.6,0,67,(212,173,240),width=.6)
 # Broad lawns on both islands, deliberately empty in their front halves.
 for x,col in [(-230,(153,187,151)),(230,(97,64,123))]:disk('RideGarden',x,.65,5,87,.2,col)
 def tower(x,z,height,dark=False,base=0):
  body=DARK if dark else WHITE;trim=VIOLET if dark else GOLD;glow=(255,81,127) if dark else (149,222,255)
  p('Tower',(x,base+height/2,z),(14,height,14),body,True)
  for dx in [-6,6]:p('TowerTrim',(x+dx,base+height/2,z+7.2),(1,height,1),trim)
  p('TowerWindow',(x,base+height*.62,z+7.3),(6,height*.32,.4),glow,mat=288)
  roof=p('TowerSpire',(x,base+height+10,z),(20,22,20),trim);roof.set('class','WedgePart')
  p('TowerCrystal',(x,base+height+25,z),(3,10,3),glow,mat=288)
 def cafe_building(cx,cz,dark=False):
  body=DARK if dark else WHITE;trim=VIOLET if dark else GOLD;accent=(102,53,130) if dark else PINK
  p('CafeFloor',(cx,.9,cz),(98,1.8,64),(85,52,67) if dark else (204,161,126),True,mat=512)
  p('CafeRoof',(cx,33,cz),(104,2,70),accent,True)
  p('CafeBack',(cx,16,cz-31),(98,32,2),body,True)
  for dx in [-48,48]:p('CafeSide',(cx+dx,16,cz),(2,32,64),body,True)
  # Fully open facade: large pets and cameras can enter without glass occlusion.
  for dx in [-47,-24,24,47]:
   p('CafeColumn',(cx+dx,16,cz+31),(2,32,2),body,True);p('ColumnGold',(cx+dx,16,cz+32.1),(.6,32,.5),trim)
  p('FacadeBeam',(cx,30,cz+32),(98,3,3),trim)
  for dx in [-47,47]:tower(cx+dx,cz-24,47,dark)
  for dx in range(-42,43,12):p('CafeAwning',(cx+dx,27,cz+36),(11.5,1,10),accent if dx%24 else body)
  p('CoffeeCounter',(cx-24,3.8,cz-20),(37,6,10),(77,43,67) if dark else (158,101,74),True)
  p('CounterMarble',(cx-24,7,cz-20),(39,.6,12),body,True)
  for dx in [-35,-23]:
   p('CoffeeMachine',(cx+dx,9.6,cz-22),(7,5,6),(64,57,71));p('MachineGlow',(cx+dx,10,cz-18.9),(4,1,.2),(255,186,131),mat=288)
  for dx in [-24,12,36]:
   p('PendantCable',(cx+dx,25,cz),(.25,9,.25),(89,66,90));p('Pendant',(cx+dx,20,cz),(5,2,5),(255,200,143),mat=288,shape=0)
  lamp=p('WarmCeiling',(cx,31,cz),(66,.2,28),(255,217,165),mat=288)
  prop(lamp,'float','Transparency',1)
  light=node(lamp,'SurfaceLight','WarmLight');prop(light,'token','Face',4);prop(light,'float','Brightness',.6);prop(light,'float','Range',45);prop(light,'bool','Shadows','false');composite(light,'Color3','Color',{'R':1,'G':.90,'B':.82})
  for dx in [-29,0,29]:
   disk('CafeTable',cx+dx,4,cz+12,6,.6,(105,67,80) if dark else (179,125,91),True);p('TableStem',(cx+dx,2.4,cz+12),(1.5,3.2,1.5),trim)
 cafe_building(-255,-97);cafe_building(255,-97,True)
 # Two light-weight imported Creator Store furniture models, sanitized offline.
 library=E.parse(R/'assets/maps/CafeFurniture.rbxmx').getroot()
 def imported(modelname,pos,yaw,color):
  original=next(n for n in library.findall('Item') if n.findtext("Properties/string[@name='Name']")==modelname);v=copy.deepcopy(original)
  refs={n.get('referent'):f'CafeFurniture{len(furniture)}_{i}' for i,n in enumerate(v.iter('Item'))}
  for n in v.iter('Item'):
   n.set('referent',refs[n.get('referent')])
   for e in n.iter('Ref'):
    if e.text in refs:e.text=refs[e.text]
   # Roblox serialized GUIDs must never be duplicated by template cloning.
   props=n.find('Properties')
   for e in list(props):
    if e.tag=='UniqueId':props.remove(e)
   if n.get('class') in ['Part','Seat','UnionOperation','MeshPart']:
    cf=n.find("Properties/CoordinateFrame[@name='CFrame']");old=[float(cf.find(k).text) for k in 'XYZ'];origin=(22.75,2.25,3.055) if modelname=='ClassicSofa' else (0,0,0)
    # Shelf origin is recorded in the extracted library metadata file.
    if modelname not in ['ClassicSofa']:origin=shelf_origin
    dx,dy,dz=[old[i]-origin[i] for i in range(3)];c,s=math.cos(yaw),math.sin(yaw)
    for key,val in zip('XYZ',[pos[0]+c*dx+s*dz,pos[1]+dy,pos[2]-s*dx+c*dz]):cf.find(key).text=str(val)
    mat=[[float(cf.find(f'R{i}{j}').text) for j in range(3)] for i in range(3)];rot=[[c,0,s],[0,1,0],[-s,0,c]]
    for i in range(3):
     for j in range(3):cf.find(f'R{i}{j}').text=str(sum(rot[i][k]*mat[k][j] for k in range(3)))
    prop(n,'bool','Anchored','true');prop(n,'bool','CanTouch',str(n.get('class')=='Seat').lower());prop(n,'bool','CanCollide',str(n.get('class') in ['UnionOperation','Seat']).lower());prop(n,'bool','CastShadow','false');
    if any('Leather_Couch' in (sa.findtext("Properties/string[@name='Name']") or '') for sa in n.findall('Item')):composite(n,'Color3','Color',dict(zip('RGB',[a/255 for a in color])))
    if n.get('class')=='UnionOperation':prop(n,'bool','UsePartColor','true');prop(n,'token','CollisionFidelity',1)
  furniture.append(v)
 shelf_origin=tuple(map(float,(R/'assets/maps/CafeFurnitureOrigin.txt').read_text().split()))
 for cx,dark in [(-255,False),(255,True)]:
  for dx in [-29,0,29]:
   for dz,yaw in [(5,math.pi/2),(19,-math.pi/2)]:imported('ClassicSofa',(cx+dx,4.05,-97+dz),yaw,(146,85,177) if dark else (242,177,202))
  imported('WoodShelf',(cx+30,5.5,-120),0,(79,50,91) if dark else (163,107,79))
 # Blossom trees, fountain lounges and static decorative streams at the outer edges.
 for cx,dark in [(-230,False),(230,True)]:
  for dx,dz in [(-78,5),(78,5),(-63,67),(63,67),(-90,-61),(90,-61)]:
   x,z=cx+dx,-35+dz;p('TreeTrunk',(x,9,z),(3,18,3),(91,65,79),True,mat=512)
   for ox,oy,oz in [(-6,21,0),(6,21,0),(0,27,1)]:p('Blossom',(x+ox,oy,z+oz),(22,16,21),(110,53,137) if dark else (250,168,204),shape=0)
  fx,fz=cx,75;disk('FountainBasin',fx,1.5,fz,17,3,DARK if dark else WHITE,True);disk('FountainWater',fx,3.1,fz,15,.2,(177,79,230) if dark else (118,219,244));disk('FountainTier',fx,6,fz,7,.8,GOLD if not dark else VIOLET);p('FountainCrystal',(fx,10,fz),(3,10,3),(187,111,255) if dark else (142,226,255),mat=288)
  for dx in [-29,29]:
   p('GardenBench',(fx+dx,2,fz),(14,1,4),PINK if not dark else VIOLET,True);p('BenchBack',(fx+dx,4,fz+1.8),(14,4,.6),PINK if not dark else VIOLET,True)
  p('FloatingCascade',(cx,-42,100),(8,84,.5),(242,62,116) if dark else (156,218,253),mat=288)
  for z in [-38,40]:
   for x in [cx-102,cx+102]:
    p('GardenLampPost',(x,7,z),(1,14,1),DARK if dark else GOLD);p('LampLantern',(x,15,z),(3,3,3),(255,83,134) if dark else (255,218,170),mat=288)
 # Repeated facade arches and planted borders bring the cafe scale down to people.
 for cx,dark in [(-255,False),(255,True)]:
  trim=VIOLET if dark else GOLD
  for dx in [-35,0,35]:
   for i in range(9):
    a=i*math.pi/8
    v=p('FacadeArch',(cx+dx+math.cos(a)*10,17+math.sin(a)*10,-63),(4.3,1,1),trim);rotate(v,z=a+math.pi/2)
  for dx in [-43,43]:
   p('CafePlanter',(cx+dx,2,-60),(9,4,7),DARK if dark else WHITE,True)
   p('CafeShrub',(cx+dx,6,-60),(10,6,8),(89,56,123) if dark else (143,178,143),shape=0)
  for dx in [-29,29]:
   for dz in [-1,1]:
    seat=p('GardenSeat',(cx+dx,2.8,76+dz*1.2),(5,.6,3.4),VIOLET if dark else PINK)
    seat.set('class','Seat');prop(seat,'bool','CanTouch','true');prop(seat,'bool','CanCollide','true')
 # Solid edge guards leave bridge openings clear. No invisible full-ring walls.
 for n in list(dec):
  if (n.findtext("Properties/string[@name='Name']") or '').endswith('Edge'):
   cf=n.find("Properties/CoordinateFrame[@name='CFrame']")
   x,z=float(cf.find('X').text),float(cf.find('Z').text)
   gate=(abs(z)<28 and (abs(abs(x)-92)<12 or abs(abs(x)-100)<20)) or (n.findtext("Properties/string[@name='Name']")=='CentralEdge' and z>40)
   if gate:dec.remove(n)
   else:prop(n,'bool','CanCollide','true');prop(n,'bool','CanQuery','true')
 # A separate giant riding garden extends the map without multiplying furniture.
 giant=node(cafe,'Folder','GiantGarden')
 for ix in range(4):
  for iz in range(4):
   x=-1350+ix*900;z=550+iz*900
   p('GiantGardenGround',(x,-1,z),(900,2,900),(143,174,150) if x<0 else (116,96,150),True,parent=giant)
   p('GiantIslandRock',(x,-25,z),(900,46,900),(127,104,146),False,parent=giant)
 # The broad entrance has no building-height gate or narrow arch to obstruct giants.
 p('GiantGardenEntrance',(0,.2,40),(540,.4,200),WHITE,True,parent=giant)
 for x in [-1800,1800]:
  for z in [550,1450,2350,3250]:p('GiantGardenSideGuard',(x,12,z),(4,26,900),GOLD if x<0 else VIOLET,True,parent=giant)
 for x in [-1350,-450,450,1350]:p('GiantGardenEndGuard',(x,12,3700),(900,26,4),VIOLET,True,parent=giant)
 for x,width in [(-1350,900),(-585,630),(585,630),(1350,900)]:
  p('GiantGardenBoundary',(x,12,100),(width,26,4),GOLD if x<0 else VIOLET,True,parent=giant)
 # Keep a handful of landmarks at the perimeter rather than a dense forest.
 for x,z in [(-1630,500),(1630,500),(-1630,1800),(1630,1800),(-1630,3300),(1630,3300)]:
  p('GiantGardenTrunk',(x,24,z),(10,48,10),(103,76,115),False,parent=giant)
  p('GiantGardenBlossom',(x,65,z),(100,72,96),PINK if x<0 else (159,108,190),False,parent=giant,shape=0)
 # Curated Roblox furniture keeps detail where players sit and socialize.
 curated=E.parse(R/'assets/maps/CafeCuratedFurniture.rbxmx').getroot()
 origins={'Couch_Double':(-122.29555,1.953728,55.84164),'Couch_Single':(-130.24902,1.954344,55.85006),'Furniture_CoffeeTable':(-39.76236,.941884,9.00256),'Furniture_FloorLamp_Off':(107.10797,3.260036,-60.171875),'Pillow_SmallWide_PlainQuilt':(-63.473785,3.504417,14.5625),'Kitchen_DiningChair':(-103.861297,2.112779,9.79123),'Kitchen_DiningTable':(-76.289703,1.568078,59.55682),'Display_Case_Desk_Top':(-38.33673,1.262924,41.86206)}
 # Replace the initial placeholder furniture before assembling distinct seating groups.
 for n in furniture.findall('Item'):furniture.remove(n)
 for n in list(structure):
  if n.findtext("Properties/string[@name='Name']") in ['CafeTable','TableStem']:structure.remove(n)
 for n in list(dec):
  if n.findtext("Properties/string[@name='Name']")=='TableStem':dec.remove(n)
 oldlib=library
 def curated_at(name,pos,yaw=0,dark=False):
  nonlocal library,shelf_origin
  library=curated;shelf_origin=origins[name]
  # imported() supports recorded-origin templates via this name-specific override.
  imported(name,pos,yaw,(178,125,198) if dark else (248,185,207))
  library=oldlib
 for cx,dark in [(-255,False),(255,True)]:
  for dx in [-25,25]:
   curated_at('Kitchen_DiningTable',(cx+dx,3.37,-76),dark=dark)
   for ox,oz,rot in [(-3,-4,0),(3,-4,0),(-3,4,math.pi),(3,4,math.pi)]:curated_at('Kitchen_DiningChair',(cx+dx+ox,3.91,-76+oz),rot,dark)
  for dx in [-16,14]:
   p('LoungeRug',(cx+dx,1.85,-100),(22,.1,20),(196,153,189) if dark else (240,207,211),False,parent=furniture,mat=1312)
   curated_at('Couch_Double',(cx+dx,3.82,-103),0,dark)
   curated_at('Furniture_CoffeeTable',(cx+dx,2.74,-96),0,dark)
   curated_at('Furniture_FloorLamp_Off',(cx+dx+6,5.02,-104),0,dark)
   curated_at('Pillow_SmallWide_PlainQuilt',(cx+dx+1.8,4.2,-103),0,dark)
  curated_at('Display_Case_Desk_Top',(cx-18,8.57,-117),0,dark)
 plantlib=E.parse(R/'assets/maps/CafeTablePlant.rbxmx').getroot()
 for cx,dark in [(-255,False),(255,True)]:
  for dx in [-16,14]:
   library=plantlib;shelf_origin=(25.6141376,1.18628395,-14.9428682)
   imported('CafeTablePlant',(cx+dx,4.72,-96),0,PINK)
 library=oldlib
 # Small floating vistas are decorative, never streamed as interactive pet areas.
 for x,z,r in [(-365,-185,27),(370,-180,28),(-130,-265,24),(150,-265,25)]:
  disk('DistantIsland',x,28,z,r,9,(140,104,149) if x<0 else DARK);tower(x,z,32,x>0,32.5)
 p('CelestialPlanet',(-160,160,-440),(180,180,180),(143,104,190),parent=space,shape=0)
 for i in range(40):
  a=i*math.tau/40;v=p('PlanetRing',(-160+math.cos(a)*119,160+math.sin(a)*26,-440+math.sin(a)*42),(20,1.8,2),GOLD,parent=space,mat=288);rotate(v,y=-a)
 p('Eclipse',(320,136,-415),(120,120,120),(29,18,42),parent=space,shape=0)
 for i in range(32):
  a=i*math.tau/32;v=p('EclipseRing',(320+math.cos(a)*67,136+math.sin(a)*67,-405),(14,1.2,2),(243,68,148),parent=space,mat=288);rotate(v,z=a+math.pi/2)
 for i in range(44):p('Star',(((i*137)%960)-480,80+(i*53)%180,-540),(1.2,1.2,1.2),(203,189,250),parent=space,mat=288,shape=0)
 spawn=p('CafeArrival',(0,1,46),(14,1,12),WHITE,False);spawn.set('class','SpawnLocation');prop(spawn,'float','Transparency',1);prop(spawn,'float','Duration',0);prop(spawn,'bool','Neutral','true')
 zones,routes=arrange(cafe,p,disk,rotate,ring)
 landscape_shared=decorate(cafe,zones,p,rotate)
 lighting=node(root,'Lighting','Lighting');prop(lighting,'float','ClockTime',12);prop(lighting,'float','Brightness',1.5);prop(lighting,'float','ExposureCompensation',0)
 composite(lighting,'Color3','Ambient',dict(zip('RGB',[100/255,86/255,115/255])));composite(lighting,'Color3','OutdoorAmbient',dict(zip('RGB',[118/255,107/255,134/255])));prop(lighting,'bool','GlobalShadows','true');prop(lighting,'float','EnvironmentDiffuseScale',.5);prop(lighting,'float','EnvironmentSpecularScale',.5)
 players=node(root,'Players','Players');prop(players,'int','MaxPlayers',20);starter=node(root,'StarterPlayer','StarterPlayer');prop(starter,'float','CameraMaxZoomDistance',120);prop(starter,'float','CameraMinZoomDistance',.5);node(starter,'StarterPlayerScripts','StarterPlayerScripts');node(root,'StarterGui','StarterGui')
 server=node(root,'ServerScriptService','ServerScriptService');script(server,'Script','CafeReviewCapacity','game.Players.PlayerAdded:Connect(function(p) if #game.Players:GetPlayers()>20 then p:Kick("Cafe is full.") end end)')
 shared=copy.deepcopy(library.find('SharedStrings'))
 known={n.get('md5') for n in shared}
 for n in plantlib.find('SharedStrings'):
  if n.get('md5') not in known:shared.append(copy.deepcopy(n));known.add(n.get('md5'))
 for n in landscape_shared:
  if n.get('md5') not in known:shared.append(n);known.add(n.get('md5'))
 root.append(shared)
 skyfile=R/'assets/maps/CafeSky.rbxmx'
 if skyfile.exists():lighting.append(copy.deepcopy(E.parse(skyfile).getroot().find('Item')))
 out=R/'dist/ReviewModels/CafeLandscape-DesignReview.rbxlx';E.ElementTree(root).write(out,encoding='utf-8',xml_declaration=True)
 asset=E.Element('roblox',version='4');asset.append(copy.deepcopy(cafe));asset.append(copy.deepcopy(shared));E.ElementTree(asset).write(R/'assets/maps/SpaceCafeReview.rbxmx',encoding='utf-8',xml_declaration=True)
 print('CAFE_FANTASY_REVIEW',len(list(cafe.iter('Item'))),'instances; scripts in furniture:',sum(n.get('class') in ['Script','LocalScript','ModuleScript'] for n in furniture.iter('Item')))
 return out
if __name__=='__main__':build()
