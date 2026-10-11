"""Extract geometry-only templates from an explicitly saved Studio source review."""
from pathlib import Path
import copy, sys, xml.etree.ElementTree as E
from build_project import node, prop
from place_identity import assert_unique_ids

root=E.parse(sys.argv[1]).getroot()
def named(name):
 return next(n for n in root.iter('Item') if n.findtext("Properties/string[@name='Name']")==name)

out=E.Element('roblox',version='4')
choices=[named(n) for n in ['CafeGazeboSource','CafeFountainSource','CafeBenchSource','CafeCoffeeMachineSource']]
kit=named('CafeCafeteriaSource')
for name in ['coffee','waffle','plate']:
 choices.append(next(n for n in kit.iter('Item') if n.get('class')=='Model' and n.findtext("Properties/string[@name='Name']")==name))
allowed={'Model','Folder','Part','WedgePart','CornerWedgePart','MeshPart','UnionOperation','SpecialMesh','SurfaceAppearance','Decal','Texture','Seat'}
for original in choices:
 v=copy.deepcopy(original)
 for parent in list(v.iter('Item')):
  for c in parent.findall('Item'):
   if c.get('class') not in allowed:parent.remove(c)
  props=parent.find('Properties')
  for p in list(props):
   if p.tag=='UniqueId' or p.get('name') in {'TexturePack','WorldPivotData','ModelMeshData'}:props.remove(p)
 if v.get('class')!='Model':
  wrapper=node(out,'Model',original.findtext("Properties/string[@name='Name']"));wrapper.append(v)
 else:out.append(v)
refs={v.get('referent'):f'CafeExtra{i}' for i,v in enumerate(out.iter('Item'))}
for v in out.iter('Item'):v.set('referent',refs[v.get('referent')])
for ref in out.iter('Ref'):ref.text=refs.get(ref.text,'null')
keys={n.text for n in out.findall('.//Properties/SharedString')}
shared=E.SubElement(out,'SharedStrings')
for n in root.findall('SharedStrings/SharedString'):
 if n.get('md5') in keys:shared.append(copy.deepcopy(n))
assert_unique_ids(out)
target=Path(__file__).resolve().parents[1]/'assets/maps/CafeScenicCurated.rbxmx'
E.indent(out);E.ElementTree(out).write(target,encoding='utf-8',xml_declaration=True)
print('CAFE_EXTRAS',len(list(out.iter('Item'))))
