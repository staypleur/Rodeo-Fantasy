"""Static obstacle collisions; leaves and tiny ornamental props remain passable."""
import numpy as np
from build_project import node, prop

def apply_collisions(cafe,p,rotate):
 parents={c:v for v in cafe.iter('Item') for c in v.findall('Item')}
 proxies=node(cafe,'Folder','ObstacleCollisions')
 def path(n):
  names=[]
  while n in parents:
   names.append(n.findtext("Properties/string[@name='Name']") or '')
   n=parents[n]
  return names
 for v in list(cafe.iter('Item')):
  cf=v.find("Properties/CoordinateFrame[@name='CFrame']");size=v.find("Properties/Vector3[@name='size']")
  if cf is None or size is None:continue
  names=path(v);name=names[0]
  tree=('CafeSakuraSource' in names or 'CafeDarkTreeSource' in names) and name=='Trunk'
  furniture=any(k in names for k in ['Couch_Single','Couch_Double','Kitchen_DiningChair','Kitchen_DiningTable','Furniture_CoffeeTable'])
  rock=any(k in names for k in ['MediumMossBoulder01','SmallRock01'])
  building=any(k in names for k in ['CafeGazeboSource','CafeBenchSource','CafeFountainSource'])
  if tree:
   centre=np.array([float(cf.findtext(k)) for k in 'XYZ']);mat=np.array([[float(cf.findtext(f'R{i}{j}')) for j in range(3)] for i in range(3)])
   half=np.array([float(size.findtext(k))/2 for k in 'XYZ']);worldhalf=np.abs(mat)@half
   height=worldhalf[1]*2*.58;radius=max(1.2,height*.11)
   collider=p('TreeTrunkCollision',(centre[0],centre[1]-worldhalf[1]+height/2,centre[2]),(height,radius*2,radius*2),(0,0,0),True,parent=proxies,shape=2)
   rotate(collider,z=np.pi/2);prop(collider,'float','Transparency',1);prop(collider,'bool','CastShadow','false')
  elif furniture or rock or building:
   prop(v,'bool','CanCollide','true');prop(v,'bool','CanQuery','true')
   if v.get('class') in ['MeshPart','UnionOperation']:
    # Gazebo walls need their source openings; single rocks use convex hulls.
    prop(v,'token','CollisionFidelity',0 if building else 1 if rock else 2)
