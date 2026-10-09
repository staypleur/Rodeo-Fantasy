"""Preserve saved assets; patch hunt sources and separate eight coplanar foundations."""
import argparse, copy, xml.etree.ElementTree as E
from pathlib import Path
import patch_nameplate_place as patcher
from place_identity import assert_unique_ids
R=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--source',type=Path,default=R/'dist/RodeoFantasy-CollisionRules.rbxlx')
parser.add_argument('--output',type=Path,default=R/'dist/RodeoFantasy-LobbyHuntFix.rbxlx')
args=parser.parse_args()
patcher.SOURCES={
 'HuntRules':R/'src/shared/HuntRules.luau',
 'HuntWorld':R/'src/server/HuntWorld.luau',
 'CaptureServer':R/'src/server/CaptureServer.server.luau'}
patcher.patch(args.source,args.output)
root=E.parse(args.output).getroot(); before=copy.deepcopy(root)
def name(n):return n.findtext("Properties/string[@name='Name']")
lobby=next(n for n in root.iter('Item') if name(n)=='RodeoLobby')
plots=next(n for n in lobby.findall('Item') if name(n)=='Plots')
count=0
for plot in plots.findall('Item'):
 floor=next(n for n in plot.findall('Item') if name(n)=='Foundation')
 y=floor.find("Properties/CoordinateFrame[@name='CFrame']/Y")
 assert abs(float(y.text)+.65)<1e-6 or abs(float(y.text)+.57)<1e-6
 y.text='-0.57'; count+=1
assert count==8
# Check all other saved properties and geometry remain identical.
for tree in (before,root):
 lb=next(n for n in tree.iter('Item') if name(n)=='RodeoLobby')
 ps=next(n for n in lb.findall('Item') if name(n)=='Plots')
 for plot in ps.findall('Item'):
  floor=next(n for n in plot.findall('Item') if name(n)=='Foundation')
  floor.find("Properties/CoordinateFrame[@name='CFrame']/Y").text='-0.57'
assert E.tostring(before)==E.tostring(root)
assert_unique_ids(root)
E.ElementTree(root).write(args.output,encoding='utf-8',xml_declaration=True)
print('LOBBY_HUNT_FIX_PASS: eight foundations now .08 above lawn, .095 below courtyard; all other saved geometry preserved')
