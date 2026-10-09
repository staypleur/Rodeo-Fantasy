"""User-run, local-only password setup. Never accepts a password in command arguments."""
from pathlib import Path
import getpass,hashlib,json,secrets,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
SOURCE=R/'dist/RodeoFantasy-LobbyFinal-Operator.rbxlx'
TARGET=R/'dist/LocalOperator/RodeoFantasy-OperatorConfigured.rbxlx'
def configure(password,source=SOURCE,target=TARGET):
 if len(password)<6 or len(password.encode('utf-8'))>256:raise ValueError('비밀번호는 6자 이상, UTF-8 기준 256바이트 이하여야 합니다.')
 salt=secrets.token_hex(16)
 digest=hashlib.sha256((salt+password).encode('utf-8')).hexdigest()
 tree=E.parse(source)
 node=next(x for x in tree.getroot().iter('Item') if x.findtext("Properties/string[@name='Name']")=='OperatorSettings')
 assert node.attrib['class']=='ModuleScript'
 node.find("Properties/ProtectedString[@name='Source']").text='return {OwnerUsername="puller3313",Salt='+json.dumps(salt)+',PasswordHash='+json.dumps(digest)+'}\n'
 target.parent.mkdir(parents=True,exist_ok=True)
 tree.write(target,encoding='utf-8',xml_declaration=True)
 return target
def reuse(source=SOURCE,target=TARGET):
 """Carry the existing private verifier into an updated public place."""
 previous=E.parse(target)
 private=next(x.findtext("Properties/ProtectedString[@name='Source']") for x in previous.getroot().iter('Item') if x.findtext("Properties/string[@name='Name']")=='OperatorSettings')
 tree=E.parse(source)
 node=next(x for x in tree.getroot().iter('Item') if x.findtext("Properties/string[@name='Name']")=='OperatorSettings')
 node.find("Properties/ProtectedString[@name='Source']").text=private
 tree.write(target,encoding='utf-8',xml_declaration=True)
 return target
if __name__=='__main__':
 try:
  if TARGET.exists():
   target=reuse()
   print('기존 운영자 비밀번호를 유지해 최신 게임 파일에 반영했습니다.')
  else:
   print('운영자: puller3313 / 비밀번호 입력은 화면에 표시되지 않습니다.')
   password=getpass.getpass('새 운영자 비밀번호 (6자 이상): ')
   confirmation=getpass.getpass('비밀번호 다시 입력: ')
   if password!=confirmation:raise ValueError('두 비밀번호가 다릅니다.')
   target=configure(password)
   password=confirmation=None
  print('개인용 게임 파일 저장 완료:',target)
  print('Studio에서 이 파일을 Ctrl+O로 열고 F5로 테스트하세요. 공개 게임에도 이 파일을 게시하세요.')
 except (ValueError,StopIteration,FileNotFoundError) as error:
  print('설정 실패:',error)
  raise SystemExit(1)
