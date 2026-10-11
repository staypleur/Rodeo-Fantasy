"""Select static sources from the saved Studio inspection; never run source code."""
import copy, collections, sys
import xml.etree.ElementTree as E
from pathlib import Path
from build_project import prop
root=E.parse(sys.argv[1]).getroot()
allowed={'Model','Folder','Part','WedgePart','CornerWedgePart','MeshPart','UnionOperation','SpecialMesh','SurfaceAppearance','Decal','Texture'}
def named(name):
 return next(v for v in root.iter('Item') if v.findtext("Properties/string[@name='Name']")==name)
building=copy.deepcopy(named('CafeBuildingCandidate'))
prop(building,'string','Name','CafeBuildingSource')
# Three ground-floor glass panes become a permanent, wide entrance.
for v in list(building.findall('Item')):
 cf=v.find("Properties/CoordinateFrame[@name='CFrame']")
 if cf is not None and 193<float(cf.findtext('X'))<218 and float(cf.findtext('Z'))>201 and float(cf.findtext('Y'))<35:
  building.remove(v)
tree=copy.deepcopy(named('DarkTreeCandidate').find('Item'))
prop(tree,'string','Name','CafeDarkTreeSource')
for v in [building,tree]:
 for parent in list(v.iter('Item')):
  for c in parent.findall('Item'):
   if c.get('class') not in allowed:parent.remove(c)
  ps=parent.find('Properties')
  for p in list(ps):
   if p.tag=='UniqueId' or p.get('name') in {'TexturePack','WorldPivotData','ModelMeshData'}:ps.remove(p)
# Adjacent vertical glass strips share a plane and material. Merge them without
# changing the outline; solid frames and source mesh geometry remain untouched.
groups=collections.defaultdict(list)
for v in building.findall('Item'):
 cf=v.find("Properties/CoordinateFrame[@name='CFrame']");s=v.find("Properties/Vector3[@name='size']")
 if cf is None or s is None or v.findall('Item'):continue
 if float(v.findtext("Properties/float[@name='Transparency']") or 0)<=0:continue
 if abs(float(cf.findtext('R11'))-1)>1e-5:continue
 ps=tuple((p.tag,p.get('name'),p.text) for p in v.find('Properties') if p.get('name') not in {'CFrame','size','Name'})
 key=(round(float(cf.findtext('X')),3),round(float(cf.findtext('Z')),3),tuple(round(float(cf.findtext(f'R{i}{j}')),5) for i in range(3) for j in range(3)),round(float(s.findtext('X')),3),round(float(s.findtext('Z')),3),ps)
 y,h=float(cf.findtext('Y')),float(s.findtext('Y'));groups[key].append((y-h/2,y+h/2,v))
removed=0
for values in groups.values():
 values.sort(key=lambda v:v[0]);start=end=None;keeper=None
 for lo,hi,v in values:
  if keeper is not None and abs(lo-end)<.003:
   end=hi;keeper.find("Properties/CoordinateFrame[@name='CFrame']/Y").text=str((start+end)/2)
   keeper.find("Properties/Vector3[@name='size']/Y").text=str(end-start);building.remove(v);removed+=1
  else:start,end,keeper=lo,hi,v
out=E.Element('roblox',version='4');out.extend([building,tree])
refs={v.get('referent'):f'CafeBuildingTree{i}' for i,v in enumerate(out.iter('Item'))}
for v in out.iter('Item'):v.set('referent',refs[v.get('referent')])
for ref in out.iter('Ref'):ref.text=refs.get(ref.text,'null')
keys={n.text for n in out.findall('.//Properties/SharedString')};shared=E.SubElement(out,'SharedStrings')
for n in root.findall('SharedStrings/SharedString'):
 if n.get('md5') in keys:shared.append(copy.deepcopy(n))
E.indent(out);target=Path(__file__).resolve().parents[1]/'assets/maps/CafeBuildingTree.rbxmx'
E.ElementTree(out).write(target,encoding='utf-8',xml_declaration=True)
print('BUILDING',len(list(building.iter('Item'))),'MERGED_GLASS',removed,'TREE',len(list(tree.iter('Item'))))
