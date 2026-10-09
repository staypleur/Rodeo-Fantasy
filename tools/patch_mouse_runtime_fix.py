"""Fix runtime-restricted fidelity writes without modifying saved model assets."""
from pathlib import Path
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={name:R/f'src/client/{name}.luau' for name in ('FacetedMouse','CreatureMesh')}
if __name__=='__main__':patcher.patch(R/'dist/RodeoFantasy-ApprovedMouse.rbxlx',R/'dist/RodeoFantasy-MouseRuntimeFix.rbxlx')
