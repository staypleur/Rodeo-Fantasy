"""Execute actual audio event logic with Luau CLI, without simulating sound playback."""
from pathlib import Path
import subprocess, argparse
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--luau',type=Path,default=ROOT/'.tools/luau/luau.exe')
args=parser.parse_args()
config=(ROOT/'src/shared/Config.luau').read_text(encoding='utf-8')
audio=(ROOT/'src/client/AudioPresentation.luau').read_text(encoding='utf-8')
tests=(ROOT/'tests/studio_audio_events.luau').read_text(encoding='utf-8')
assert "local Audio=require(game.StarterPlayer.StarterPlayerScripts.AudioPresentation)" in tests
tests=tests.replace("local Audio=require(game.StarterPlayer.StarterPlayerScripts.AudioPresentation)","",1)
# Only module loading is mocked. Event functions below run unchanged from source.
prefix="local cfg=(function()\n"+config+"\nend)()\nlocal Audio=(function()\nlocal node={} function node:WaitForChild() return self end\nlocal game={} function game:GetService() return node end\nlocal require=function() return cfg end\n"
harness=ROOT/'.tools/audio_events_harness.luau'
harness.parent.mkdir(exist_ok=True)
harness.write_text(prefix+audio+'\nend)()\n'+tests,encoding='utf-8')
subprocess.run([str(args.luau),str(harness.relative_to(ROOT))],check=True,cwd=ROOT)
