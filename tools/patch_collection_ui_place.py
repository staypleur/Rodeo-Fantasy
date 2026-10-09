"""Patch collection ranking and matching UI controls while preserving saved assets."""
from pathlib import Path
import patch_nameplate_place as patcher
R=Path(__file__).resolve().parents[1]
patcher.SOURCES={name:R/f'src/{folder}/{name}.luau' for folder,name in (
 ('client','BagUI'),('client','JournalUI'),('client','SettingsUI'),
 ('server','ProgressService'),('server','RecordService'),('shared','ProgressRules'),('shared','Localization'))}
if __name__=='__main__':
 patcher.patch(R/'dist/RodeoFantasy-JournalRanchFix.rbxlx',R/'dist/RodeoFantasy-CollectionUI.rbxlx')
