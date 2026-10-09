"""Validate both XML referents and Roblox instance UniqueIds before export."""
def repair_duplicate_unique_ids(root):
 seen=set();removed=0
 for item in root.iter('Item'):
  props=item.find('Properties')
  if props is None:continue
  for node in list(props):
   if node.tag!='UniqueId' or node.get('name')!='UniqueId':continue
   value=(node.text or '').strip().lower()
   if not value or set(value)=={'0'}:continue
   assert len(value)==32 and all(c in '0123456789abcdef' for c in value),'invalid UniqueId'
   if value in seen:
    # Like newly generated Parts, omit the ID so Studio allocates a fresh one.
    props.remove(node);removed+=1
   else:seen.add(value)
 assert_unique_ids(root)
 return removed

def assert_unique_ids(root):
 ids=[]
 for node in root.findall(".//UniqueId[@name='UniqueId']"):
  value=(node.text or '').strip().lower()
  if value and set(value)!={'0'}:ids.append(value)
 assert len(ids)==len(set(ids)),'duplicate Roblox UniqueId'
 refs=[item.get('referent') for item in root.iter('Item')]
 assert len(refs)==len(set(refs)),'duplicate XML referent'
 refset=set(refs)
 assert all(n.text in refset or n.text in ('null','nil',None) for n in root.iter('Ref')),'broken XML reference'
