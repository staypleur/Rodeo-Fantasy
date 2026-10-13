from pathlib import Path
import xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
root=E.Element('roblox',version='4')
counter=0
def node(parent,kind,name):
 global counter
 counter+=1
 n=E.SubElement(parent,'Item',{'class':kind,'referent':f'RBXBreedReview{counter}'})
 p=E.SubElement(n,'Properties'); E.SubElement(p,'string',name='Name').text=name
 return n
def source(parent,name,path,kind='ModuleScript'):
 n=node(parent,kind,name);E.SubElement(n.find('Properties'),'ProtectedString',name='Source').text=(R/path).read_text(encoding='utf8');return n
node(root,'Workspace','Workspace')
rs=node(root,'ReplicatedStorage','ReplicatedStorage');package=node(rs,'Folder','RodeoFantasy')
for name in ['MonsterCatalog','Localization','SocialRules']:source(package,name,f'src/shared/{name}.luau')
sg=node(root,'StarterGui','StarterGui')
sp=node(root,'StarterPlayer','StarterPlayer');client=node(sp,'StarterPlayerScripts','StarterPlayerScripts')
for name in ['BreedingUI','MonsterPortrait']:source(client,name,f'src/client/{name}.luau')
source(client,'BreedingReview','tools/review_breeding.client.luau','LocalScript')
E.indent(root);E.ElementTree(root).write(R/'dist/Breeding-UI-Review.rbxlx',encoding='utf-8',xml_declaration=True)
