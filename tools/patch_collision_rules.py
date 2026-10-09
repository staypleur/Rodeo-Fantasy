"""Update only collision scripts, preserving whatever assets Studio has saved."""
import argparse
from pathlib import Path
import patch_nameplate_place as patcher
from place_identity import assert_unique_ids
import xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--source',type=Path,default=R/'dist/RodeoFantasy-SkyWhaleReady.rbxlx')
parser.add_argument('--output',type=Path,default=R/'dist/RodeoFantasy-CollisionRules.rbxlx')
args=parser.parse_args()
patcher.SOURCES={
 'HuntRules':R/'src/shared/HuntRules.luau',
 'HuntWorld':R/'src/server/HuntWorld.luau',
 'CaptureServer':R/'src/server/CaptureServer.server.luau'}
patcher.patch(args.source,args.output)
assert_unique_ids(E.parse(args.output).getroot())
print('COLLISION_PLACE_PASS: three sources patched; every other saved property/mesh/boarding asset preserved; no new designs installed')
