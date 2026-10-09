"""Preserve assets and user saves while patching journal, HUD, ranch and progression."""
from pathlib import Path
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={name:R/f'src/{folder}/{name}{suffix}.luau' for folder,name,suffix in (
 ('client','JournalUI',''),('client','FacetedMouse',''),('client','RideAnimator',''),
 ('client','SettingsUI',''),('client','MonsterPortrait',''),('client','CaptureClient','.client'),
 ('server','LobbyWorld',''),('server','ProgressService',''),('shared','ProgressRules',''))}
if __name__=='__main__':
 patcher.patch(R/'dist/RodeoFantasy-MouseMemoryFix.rbxlx',R/'dist/RodeoFantasy-JournalRanchFix.rbxlx')
