"""Preserve saved imported assets while embedding approved knock-shatter code."""
from pathlib import Path
import patch_nameplate_place as patcher
ROOT=Path(__file__).resolve().parents[1]
patcher.SOURCES={
 'HuntWorld':ROOT/'src/server/HuntWorld.luau',
 'RideAnimator':ROOT/'src/client/RideAnimator.luau',
 'CrashEffect':ROOT/'src/client/CrashEffect.luau',
 'CaptureClient':ROOT/'src/client/CaptureClient.client.luau',
}
if __name__=='__main__':
 patcher.patch(ROOT/'dist/RodeoFantasy-NoNameplate.rbxlx',ROOT/'dist/RodeoFantasy-KnockEffects.rbxlx')
