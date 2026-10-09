"""Regression for cloned instance IDs, zero IDs and reference integrity."""
import sys, copy
from pathlib import Path
import xml.etree.ElementTree as E
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from place_identity import repair_duplicate_unique_ids, assert_unique_ids

root=E.fromstring('<roblox><Item referent="a"><Properties><UniqueId name="UniqueId">11111111111111111111111111111111</UniqueId></Properties></Item><Item referent="b"><Properties><UniqueId name="UniqueId">11111111111111111111111111111111</UniqueId><Ref name="Parent">a</Ref></Properties></Item><Item referent="c"><Properties><UniqueId name="UniqueId">00000000000000000000000000000000</UniqueId></Properties></Item></roblox>')
assert repair_duplicate_unique_ids(root)==1
assert len(root.findall(".//UniqueId"))==2
assert root.find(".//Ref").text=='a'
assert repair_duplicate_unique_ids(root)==0
for mode in ('duplicate referent','broken reference'):
 broken=copy.deepcopy(root)
 if mode=='duplicate referent':broken.findall('Item')[1].set('referent','a')
 else:broken.find('.//Ref').text='missing'
 try:assert_unique_ids(broken)
 except AssertionError:pass
 else:raise AssertionError(mode+' was accepted')
print('PLACE_IDENTITY_PASS: duplicate repair, zero ID preservation, idempotence, duplicate referent and broken reference rejection')
