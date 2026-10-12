from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
test=(root/'tests/travel_rules.luau').read_text(encoding='utf8')
rules=(root/'src/shared/TravelRules.luau').read_text(encoding='utf8')
test=test.replace('local R=require("../src/shared/TravelRules")','local R=(function()\n'+rules+'\nend)()')
out=root/'.tools/travel-rules-test.luau'
out.write_text(test,encoding='utf8')
subprocess.run([str(root/'.tools/luau/luau.exe'),str(out.relative_to(root))],cwd=root,check=True)
service_test=(root/'tests/travel_service.luau').read_text(encoding='utf8')
service_test=service_test.replace('-- RULES_SOURCE',rules).replace('-- SERVICE_SOURCE',(root/'src/server/TravelService.luau').read_text(encoding='utf8'))
out=root/'.tools/travel-service-test.luau'
out.write_text(service_test,encoding='utf8')
subprocess.run([str(root/'.tools/luau/luau.exe'),str(out.relative_to(root))],cwd=root,check=True)
