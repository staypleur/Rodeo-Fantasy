"""Fix late server visuals without replacing saved assets or approved designs."""
from pathlib import Path
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={'FacetedMouse':R/'src/client/FacetedMouse.luau'}
if __name__=='__main__':
 patcher.patch(R/'dist/RodeoFantasy-CollectionUI.rbxlx',R/'dist/RodeoFantasy-RanchVisualFix.rbxlx')
