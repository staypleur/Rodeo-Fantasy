from pathlib import Path
import subprocess,re
R=Path(__file__).resolve().parents[1]
for name in ('social_rules','bag_rules'):
 code=(R/f'tests/{name}.luau').read_text(encoding='utf-8')
 def replace(m):return '(function()\n'+(R/'src/shared'/f'{m[1]}.luau').read_text(encoding='utf-8')+'\nend)()'
 code=re.sub(r'require\("\.\./src/shared/(\w+)"\)',replace,code)
 out=R/f'.tools/test_{name}.luau';out.write_text(code,encoding='utf-8')
 subprocess.run([str(R/'.tools/luau/luau.exe'),f'.tools/test_{name}.luau'],cwd=R,check=True)
