"""Repair only duplicate IDs in the user's rejected Boarding place."""
from pathlib import Path
import copy,xml.etree.ElementTree as E
from place_identity import repair_duplicate_unique_ids,assert_unique_ids
R=Path(__file__).resolve().parents[1]
before=E.parse(R/'dist/RodeoFantasy-LobbyBoarding.rbxlx').getroot();after=copy.deepcopy(before)
count=repair_duplicate_unique_ids(after);assert count==15
old=copy.deepcopy(before);new=copy.deepcopy(after)
for tree in (old,new):
 for p in tree.iter('Properties'):
  for n in list(p):
   if n.tag=='UniqueId' and n.get('name')=='UniqueId':p.remove(n)
assert E.tostring(old)==E.tostring(new),'repair changed game content'
assert_unique_ids(after)
out=R/'dist/RodeoFantasy-LobbyBoardingFixed.rbxlx'
E.ElementTree(after).write(out,encoding='utf-8',xml_declaration=True)
assert_unique_ids(E.parse(out).getroot())
print(f'BOARDING_IDS_PASS: {count} duplicate IDs removed, all game properties/scripts/geometry preserved, saved-file recheck passed; {out}')
