"""Verify private file setup without storing any real user password."""
from pathlib import Path
import importlib.util,hashlib,re,tempfile,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('operator_setup',R/'tools/configure_operator_password.py')
setup=importlib.util.module_from_spec(spec);spec.loader.exec_module(setup)
with tempfile.TemporaryDirectory(dir=R/'.tools') as temp:
 folder=Path(temp);source=folder/'empty.rbxlx';target=folder/'configured.rbxlx'
 source.write_text('<roblox><Item class="ModuleScript"><Properties><string name="Name">OperatorSettings</string><ProtectedString name="Source">return {}</ProtectedString></Properties></Item></roblox>',encoding='utf-8')
 password='dummy-local-test-only'
 setup.configure(password,source,target)
 content=E.parse(target).find('.//ProtectedString').text
 salt=re.search(r'Salt="([a-f0-9]+)"',content).group(1)
 digest=re.search(r'PasswordHash="([a-f0-9]+)"',content).group(1)
 assert len(salt)==32 and hashlib.sha256((salt+password).encode()).hexdigest()==digest
 assert password not in target.read_text(encoding='utf-8')
 try:setup.configure('short',source,target)
 except ValueError:pass
 else:raise AssertionError('short password accepted')
print('OPERATOR_SETUP_PASS: private salt/verifier injection, no plaintext password saved, short password rejected')
