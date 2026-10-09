"""Preserve imported models and existing shatter code while adding hunt sound cues."""
from pathlib import Path
import patch_nameplate_place as patcher
ROOT=Path(__file__).resolve().parents[1]
patcher.SOURCES={
 'Config':ROOT/'src/shared/Config.luau',
 'AudioPresentation':ROOT/'src/client/AudioPresentation.luau',
}
if __name__=='__main__':
 patcher.patch(ROOT/'dist/RodeoFantasy-KnockEffects.rbxlx',ROOT/'dist/RodeoFantasy-HuntAudio.rbxlx')
