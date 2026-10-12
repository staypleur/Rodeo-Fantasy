from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
test = (root / 'tests/hunt_size_rules.luau').read_text(encoding='utf8')
source = (root / 'src/shared/HuntRules.luau').read_text(encoding='utf8')
test = test.replace('require("../src/shared/HuntRules")', '(function()\n' + source + '\nend)()')
output = root / '.tools/hunt-size-rules-test.luau'
output.write_text(test, encoding='utf8')
subprocess.run([str(root / '.tools/luau/luau.exe'), '.tools/hunt-size-rules-test.luau'], cwd=root, check=True)
