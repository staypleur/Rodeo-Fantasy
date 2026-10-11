"""Static three-zone cafe palette; keep shared mesh and PBR map IDs intact."""
from build_project import prop, composite

WHITE=(250,250,253)
PINK=(239,173,202)
DARK=(35,30,45)

def apply_palette(cafe):
 parents={c:p for p in cafe.iter('Item') for c in p.findall('Item')}
 def ancestry(n):
  names=[]
  while n in parents:
   names.append(n.findtext("Properties/string[@name='Name']") or '')
   n=parents[n]
  return names
 for n in cafe.iter('Item'):
  cf=n.find("Properties/CoordinateFrame[@name='CFrame']")
  if cf is None or n.find("Properties/Vector3[@name='size']") is None:continue
  name=n.findtext("Properties/string[@name='Name']") or ''
  path=ancestry(n);x=float(cf.findtext('X'));dark=x>0
  central='Central' in path or name in ['HubInlay','HubOrb','HubStem','OrbOrbit','CafeArrival']
  body=(53,43,66) if dark else (252,233,242)
  trim=(119,90,143) if dark else (218,154,185)
  roof=(66,48,87) if dark else PINK
  col=None
  if central:
   col=(212,222,236) if any(k in name for k in ['Rock','Taper','Tip','Inlay','Orbit','Edge']) else WHITE
   if name=='HubOrb':col=(218,236,255)
  elif any(k in name for k in ['Ground','Floor','Terrace','Retreat']):
   col=DARK if dark else (246,218,232)
   if 'GiantGardenGround' in name:col=(43,38,51) if dark else (225,194,211)
  elif any(k in name for k in ['Rock','Taper','Tip']):col=(26,23,34) if dark else (190,164,182)
  elif name=='IslandBridge':col=DARK if dark else (252,237,245)
  elif any(k in name for k in ['Guard','Edge','Gold','Forecourt','FacadeBeam','FacadeArch','Window','Spire','Crystal']):col=trim
  elif any(k in name for k in ['Roof','Awning','Rug','Planter','Trail']):col=roof
  elif any(k in name for k in ['Hall','Tower','Column','CafeBack','CafeSide','PavilionWall','PavilionBack','CounterMarble','CoffeeCounter','FountainTier']):col=body
  elif name=='LavaFall':col=(116,61,125)
  elif name=='Waterfall':col=(230,206,237)
  elif name in ['BackgroundPlanet','BackgroundOrbit','VistaIsland','VistaCrystal']:col=roof if name=='BackgroundPlanet' else trim
  elif 'CafeGazeboSource' in path:
   col=roof if float(cf.findtext('Y'))>38 else body
  elif 'CafeFountainSource' in path:col=body
  elif 'CafeBenchSource' in path:col=(72,55,85) if dark else (223,174,198)
  elif 'CafeSakuraSource' in path:
   col=((130,91,157) if dark else (255,192,220)) if name=='Leaves' else ((72,53,82) if dark else (157,117,135))
  # Upholstery is tinted through SurfaceAppearance; wood, food and greenery keep
  # their source texture detail rather than becoming featureless painted shapes.
  sofa=any(k in path for k in ['Couch_Single','Couch_Double','Pillow_SmallWide_PlainQuilt'])
  if sofa:
   col=(86,62,108) if dark else (255,209,231)
   for sa in n.findall("Item[@class='SurfaceAppearance']"):
    composite(sa,'Color3','Color',dict(zip('RGB',[c/255 for c in col])))
  elif dark:
   for sa in n.findall("Item[@class='SurfaceAppearance']"):
    composite(sa,'Color3','Color',dict(zip('RGB',[.64,.53,.72])))
  if col is not None:
   prop(n,'Color3uint8','Color3uint8',0xff000000+(col[0]<<16)+(col[1]<<8)+col[2])
   if n.get('class')=='UnionOperation':prop(n,'bool','UsePartColor','true')
