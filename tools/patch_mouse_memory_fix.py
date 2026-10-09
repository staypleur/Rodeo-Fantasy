"""Preserve saved assets while fixing client mesh allocation and hunt cleanup."""
from pathlib import Path
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={
    'FacetedMouse':R/'src/client/FacetedMouse.luau',
    'CreatureMesh':R/'src/client/CreatureMesh.luau',
    'HuntWorld':R/'src/server/HuntWorld.luau',
}
if __name__=='__main__':
    patcher.patch(R/'dist/RodeoFantasy-MouseRuntimeFix.rbxlx',R/'dist/RodeoFantasy-MouseMemoryFix.rbxlx')
