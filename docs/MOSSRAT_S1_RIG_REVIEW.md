# 새 모스랫1성 리깅 검토

사용자 파일 `Meshy_AI_Mossrat_1Star_Remesh__1010052217_texture.glb`로 제작했다. 높이90cm,10,294삼각형/17,341정점,원본 메시·법선·UV·텍스처 바이트 보존. 새 조형으로 바꾸거나 과거 모스랫 모델로 대체하지 않았다. 사용자 후속 요청으로 **눈 감기 제외**. 최종 파일에는 추가 눈꺼풀·깜빡임이 없고 삼각형 수도 원본과 같다.

리그34관절: 몸통3구간/목/머리/턱, 눈 주변2곳, 귀/귀 끝, 새싹/끝, 수염, 네 다리 각3관절, 꼬리5구간, 전체Root. 정점당최대4영향. 눈은 얼굴 표면에 그려진 원본 텍스처이므로 눈 주변 표면의 작은 이동만 넣으며 독립 구형 안구가 자유롭게 회전하는 방식은 아니다. 잎·몸통·목·다리 연결을 부드럽게 가중하고 UV 경계의 동일 위치 정점은 같은 가중치를 사용한다.

## 검토 파일

- `assets/previews/MossratS1RigMotion.gif`: 실제 glTF 뼈/가중치로 변형한 메시를 렌더한 움직임. 왼쪽 숨쉬기, 가운데 걷기, 오른쪽 목/머리/꼬리 움직임.
- `assets/previews/MossratS1RigReview.png`: 원본 정지 형상,34관절 위치,머리/목 동작.
- `assets/models/MossratS1UserRig/MossratS1Rigged.glb`: 뼈·스키닝·텍스처·4개검토클립 포함.
- `assets/models/MossratS1UserRig/MossratS1Rigged.gltf`: Studio에서 가져올 파일. 같은 폴더의 `.bin`/PNG2장을 함께 유지한다.
- `assets/models/MossratS1UserRig/Source.glb`: 받은 원본 사본. SHA256 `488598762339c44959cef95e1803a3ead9bff32fd864b54afadb241380474bec`.

4개 검토 클립은 Idle/Walk/LookAround/RigRange다. 사용자가 눈 감기 없는 결과를 승인했다. 게임 코드는 승인한 Idle/Walk의24fps 데이터를 직접 보간하고34관절을 최대30Hz로 갱신하며 전환을0.18초 동안 혼합한다. LookAround/RigRange는 가져오기 파일의 검토 클립으로 남긴다. 별도 달리기/점프/착지 리그 클립, 실제 탑승 위치·지면 접촉/속도 동기화 검증은 남아 있다.

## 별도 Studio 검토를 할 때

1. Roblox Studio를 실행하고 **New → Baseplate**로 빈 검토 장소를 만든다. 기존 게임에 설치하는 단계가 아니다.
2. **File → Import**에서 위 `MossratS1Rigged.gltf`를 선택한다. [공식 Importer 안내](https://create.roblox.com/docs/studio/importer)
3. 리그 설정이 나오면 **Rig Type: Custom**으로 확인한다. 모델·뼈를 유지하고, 필요하면 **Keep Zero Influence Bones**를 켠다. 아바타 R15로 변환하지 않는다.
4. 미리보기에서 원래 모스랫 색과 형상, 오류/경고를 확인한 뒤 Import한다. Explorer에서 Model을 선택하고 **F**로 화면에 맞춘다.
5. Explorer를 펼쳐 MeshPart와 Bone 계층이 생겼는지 확인한다. 이 가져오기와 애니메이션 재생은 아직 에이전트가 Studio에서 실제 검증하지 않았다. 경고가 있으면 무시하고 게임에 설치하지 않는다.

게임 설치 높이는 기존 기획대로2.5studs로 따로 맞춘다. 90cm를 Importer가 자동으로2.5studs로 변환한다고 가정하지 않는다. 원본4K텍스처를 보존한 상세 검토본이며 사냥용약3K/텍스처 축소,모바일 실제 FPS/메모리 측정은 별도다. 동일 모델의 여러 마리가 보일 때 텍스처가 공유될 수 있으므로 텍스처 메모리를 단순히 마릿수만큼 곱해 성능을 확정하지 않는다.

현재 상태: 사용자 리깅 승인 완료, 게임 연결 코드/설치 파일 준비 및 코드 검사 통과. Studio 가져오기·설치 실행과 PC·모바일 실행은 미완료다. metadata의installedInGame/studioVerified/mobilePerformanceMeasured는 실제 설치/측정 전까지false로 유지한다.

## 승인 모델을 현재 게임에 설치

### 텍스처 파일을 읽을 수 없다고 나올 때

사용자Studio스크린샷에서BakedMaterial의색상/금속성/거칠기파일을읽을수없다는오류를확인했다. 저장소의PNG2장은4096×4096/RGB의유효한PNG로실제디코드된다. 이미지누락/손상은로컬검사에서발견하지않았으며,Studio가상대경로를어떻게해석했는지는미확인이다. `모델만 가져오기`는단일자산묶음설정으로텍스처제외옵션이아니다.

가져오기창의왼쪽 `MossratS1 → MossratS1Body → BakedMaterial`을선택한다. 오른쪽각행의폴더버튼을눌러아래실제파일을선택한다. 파일선택창의주소표시줄에 `C:\Users\wucha\OneDrive\바탕 화면\Project\Rodeo Fantasy\assets\models\MossratS1UserRig`를붙여넣고Enter하면해당폴더로이동한다.

| Studio 항목 | 선택할 파일 |
|---|---|
| 색상 파일 경로 | MossratTexture0.png |
| 금속성 파일 경로 | MossratMetalness.png |
| 거칠기 파일 경로 | MossratRoughness.png |

일반(Normal)/이미시브는원본에없으므로비워둔다. 세빨간느낌표가사라지고모델미리보기에초록색/얼굴색이나오면가져오기한다. 같은오류가남으면해당직접선택후의오류문구를확인한다. `영향이 없는 뼈 보관`도켜34관절을유지한다. 파일직접선택해결여부는아직사용자Studio에서확인전이다.

금속성/거칠기는glTF2.0의packedRGB맵에서B/G채널을각각PNG로손실없이분리했다. 원본두PNG/UV/메시/리그/승인색은변경하지않는다. 실행도구 `tools/prepare_mossrat_material_maps.py`에서디코드/원본채널과픽셀완전일치를검사한다. [glTF 공식 재질 명세](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html), [Studio Importer 공식 안내](https://create.roblox.com/docs/studio/importer).

1. Studio에서 현재 로비 장소를 열고 **Stop**을 눌러 Play를 중지한다. **File → Save to File**로 장소 사본을 저장한다.
2. **File → Import**에서 프로젝트의 `assets/models/MossratS1UserRig/MossratS1Rigged.gltf`를 선택한다. `.bin`과PNG2장을 같은 폴더에 둔다. Rig Type은Custom, 뼈 보존 옵션을 사용한다. Importer의 오류·경고는 확인한다.
3. Explorer의Workspace 아래에 생긴 모스랫 전체 **Model** 이름을 `MossratImport`로 변경한다. 원본 정적Source.glb를 가져오는 단계가 아니다.
4. 프로젝트 `dist/ReviewModels/InstallUserMossrat.commandbar.lua`를 메모장으로 열어 전체 복사한다. Studio **View → Command Bar**에서 붙여넣고 Enter한다.
5. Output에서 `MOSSRAT_RIG_INSTALLED` 또는 이미 설치했다면 `MOSSRAT_RIG_ALREADY_CURRENT`를 확인한다. 코드 버전 불일치/관절 없음 오류는 설치를 중단한다. 성공 시 Ctrl+S로 저장한다.
6. 서버템플릿RodeoMonsterTemplate 및ReplicatedStorage.RodeoFantasy의VisualTemplate/MeshyMossratHuntTemplate에Body와34Bone이 있는지 확인한다. 기존 모델/가져온 원본/수정 전 스크립트는ServerStorage.MossratRigBackup_*에 보관한다.
7. **Play**에서 가방/도감의 모스랫 외형을 확인한다. 새 계정/미게시 새 세션은 무료1성을 받으며, 기존 저장 가방은 유지한다. 카페에서 보유 모스랫을 소환하고 이동/정지하여 걷기/숨쉬기, 꼬리·귀 움직임, 발 위치를 확인한다. 눈은 계속 열린다. 카페20명/모바일·PC실제 부하는 별도 측정한다.
8. 로켓E1초→Green Star→보유 개체 선택을 확인한다. 새 숲 런타임이 준비되지 않았다면 출발은 준비 중 안내로 막히는 것이 현재 정상이다. 이번 모델 설치는GreenStarRuntimeReady를 켜지 않는다. 로비 동행 기능/새 숲 설치는 별도 남아 있다.

검사:34관절의 런타임 Idle/Walk 지역 변환을 glTF 키와 직접 비교, 루프/전환 시작 확인. 새 가방 지급·저장/재접속·삭제 후 중복 방지·기존 가방 보존 확인. 모형Instance로 설치의34관절 계층 검사/코드 버전 거부/템플릿3개 교체/백업/재실행 무변경/쓰기 실패 복구 확인. 이 검사들은Studio Importer·실제 Bone 렌더·물리·모바일 성능 검증을 대체하지 않는다.
