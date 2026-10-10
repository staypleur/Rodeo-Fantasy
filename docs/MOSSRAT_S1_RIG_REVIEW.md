# 새 모스랫1성 리깅 검토

사용자 파일 `Meshy_AI_Mossrat_1Star_Remesh__1010052217_texture.glb`로 제작했다. 높이90cm,10,294삼각형/17,341정점,원본 메시·법선·UV·텍스처 바이트 보존. 새 조형으로 바꾸거나 과거 모스랫 모델로 대체하지 않았다. 사용자 후속 요청으로 **눈 감기 제외**. 최종 파일에는 추가 눈꺼풀·깜빡임이 없고 삼각형 수도 원본과 같다.

리그34관절: 몸통3구간/목/머리/턱, 눈 주변2곳, 귀/귀 끝, 새싹/끝, 수염, 네 다리 각3관절, 꼬리5구간, 전체Root. 정점당최대4영향. 눈은 얼굴 표면에 그려진 원본 텍스처이므로 눈 주변 표면의 작은 이동만 넣으며 독립 구형 안구가 자유롭게 회전하는 방식은 아니다. 잎·몸통·목·다리 연결을 부드럽게 가중하고 UV 경계의 동일 위치 정점은 같은 가중치를 사용한다.

## 검토 파일

- `assets/previews/MossratS1RigMotion.gif`: 실제 glTF 뼈/가중치로 변형한 메시를 렌더한 움직임. 왼쪽 숨쉬기, 가운데 걷기, 오른쪽 목/머리/꼬리 움직임.
- `assets/previews/MossratS1RigReview.png`: 원본 정지 형상,34관절 위치,머리/목 동작.
- `assets/models/MossratS1UserRig/MossratS1Rigged.glb`: 뼈·스키닝·텍스처·4개검토클립 포함.
- `assets/models/MossratS1UserRig/MossratS1Rigged.gltf`: Studio에서 가져올 파일. 같은 폴더의 `.bin`/PNG2장을 함께 유지한다.
- `assets/models/MossratS1UserRig/Source.glb`: 받은 원본 사본. SHA256 `488598762339c44959cef95e1803a3ead9bff32fd864b54afadb241380474bec`.

4개 검토 클립은 Idle/Walk/LookAround/RigRange다. 게임 상황별 달리기·점프·착지 및 속도별 전환, 탑승 위치, 무료 지급, 가방/도감/사냥 연결은 이번 리깅 결과 승인 뒤 연결할 후속 작업이다. 걷기 미리보기는 제자리 동작이며 지면 접촉/이동 속도와의 동기화 검증이 아니다.

## 별도 Studio 검토를 할 때

1. Roblox Studio를 실행하고 **New → Baseplate**로 빈 검토 장소를 만든다. 기존 게임에 설치하는 단계가 아니다.
2. **File → Import**에서 위 `MossratS1Rigged.gltf`를 선택한다. [공식 Importer 안내](https://create.roblox.com/docs/studio/importer)
3. 리그 설정이 나오면 **Rig Type: Custom**으로 확인한다. 모델·뼈를 유지하고, 필요하면 **Keep Zero Influence Bones**를 켠다. 아바타 R15로 변환하지 않는다.
4. 미리보기에서 원래 모스랫 색과 형상, 오류/경고를 확인한 뒤 Import한다. Explorer에서 Model을 선택하고 **F**로 화면에 맞춘다.
5. Explorer를 펼쳐 MeshPart와 Bone 계층이 생겼는지 확인한다. 이 가져오기와 애니메이션 재생은 아직 에이전트가 Studio에서 실제 검증하지 않았다. 경고가 있으면 무시하고 게임에 설치하지 않는다.

게임 설치 높이는 기존 기획대로2.5studs로 따로 맞춘다. 90cm를 Importer가 자동으로2.5studs로 변환한다고 가정하지 않는다. 원본4K텍스처를 보존한 상세 검토본이며 사냥용약3K/텍스처 축소,모바일 실제 FPS/메모리 측정은 별도다. 동일 모델의 여러 마리가 보일 때 텍스처가 공유될 수 있으므로 텍스처 메모리를 단순히 마릿수만큼 곱해 성능을 확정하지 않는다.

현재 상태: 파일 검사 통과, 실제 메시 동작 미리보기 제작. 사용자 리깅 승인/Studio 가져오기/PC·모바일 실행/게임 적용은 미완료. 사용자가 요청한 **리깅 승인 후 게임 적용** 순서를 유지한다.
