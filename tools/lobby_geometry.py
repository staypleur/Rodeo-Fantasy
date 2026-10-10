"""The same horizontal expansion and roof plates as LobbyExpansion.luau."""
import math
import xml.etree.ElementTree as E
def name(n):return n.findtext("Properties/string[@name='Name']")
def expand(lobby,node,part):
 if any(name(n)=='OrbitalLobbyV2' for n in lobby.findall('Item')):return
 def snap(v):return math.floor(v/4+.5)*4
 def walk(n,in_rocket=False):
  in_rocket=in_rocket or name(n) in ('Rocket','LobbyCompanions')
  if n.get('class') in ('Part','SpawnLocation','MeshPart') and not in_rocket:
   p=n.find('Properties');s=p.find("Vector3[@name='size']");cf=p.find("CoordinateFrame[@name='CFrame']")
   for axis in ('X','Z'):s.find(axis).text=str(max(4,snap(float(s.findtext(axis))*1.2)))
   cf.find('X').text=str(6000+snap((float(cf.findtext('X'))-6000)*1.2))
   cf.find('Z').text=str(snap(float(cf.findtext('Z'))*1.2))
  for child in n.findall('Item'):walk(child,in_rocket)
 walk(lobby)
 roof=next(n for n in lobby.findall('Item') if name(n)=='Roof')
 for n in list(roof.findall('Item')):
  if name(n)=='Ceiling':roof.remove(n)
 for x in range(-7,8):
  for z in range(-7,8):
   if abs(x)+abs(z)<=11:part(roof,'Ceiling',[6000+x*40,92,z*40],[40,8,40],[30,42,61])
 airport=next(n for n in lobby.findall('Item') if name(n)=='Airport')
 departure=next(n for n in airport.findall('Item') if name(n)=='Departure')
 cf=departure.find("Properties/CoordinateFrame[@name='CFrame']")
 for axis,v in zip('XYZ',[6000,4,-44]):cf.find(axis).text=str(v)
 marker=node(lobby,'BoolValue','LargerLobbyV1');E.SubElement(marker.find('Properties'),'bool',name='Value').text='true'
