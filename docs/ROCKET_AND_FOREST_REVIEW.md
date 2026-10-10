# 로켓과 숲 검토 안내

이번 파일은 Roblox 게시나 현재 작업 장소 변경을 자동 실행하지 않습니다. 원본 로켓은 Downloads에 그대로 있습니다.

## 숲의 실제 Stud·빛·물·바람 확인

1. Roblox Studio를 실행하고 **New → Baseplate**로 별도 빈 장소를 엽니다.
2. **View → Command Bar**를 켭니다. Studio 리본 버전에 따라 **Window → Command Bar**에 있을 수도 있습니다.
3. 저장소의 `dist/ReviewModels/CreateStudBlockMap.commandbar.lua`를 메모장으로 열어 전체 복사하고 Command Bar에 붙여넣은 뒤 Enter를 누릅니다.
4. Output에 `STUD_MAP_REVIEW_CREATED`와 `2190`가 보이면 생성 성공입니다. Explorer의 `Workspace.HuntStudBlockReview`를 선택하고 F로 맞춥니다. 바닥·벽·나무·바위·물 모두 Stud가 유지되는지 확인합니다.
5. **Play**를 누르면 가까운 잎 판이 조금 흔들리고 폭포 색층이 아래로 흐릅니다. 따뜻한 조명과 옅은 안개도 Play에서 표시됩니다. 캐릭터로 직접 걷는 환경 검토이며 사냥 게임·몬스터·후방 사냥 카메라는 연결하지 않았습니다.
6. **Stop** 후 검토 장소만 저장합니다. 기존 게임 장소에는 외형 확인 전 설치하지 않습니다.

거리1,000m/폭192studs는 유지합니다. 물과 작은 식물은 충돌하지 않으며 넓은 바닥을 제거하지 않았습니다. 생성 때4studs X/Z격자, 얇은 판의Y2격자 예외를 유지합니다. Play 중 잎 회전은 시각 애니메이션 예외입니다. 실행 중 다시 생성하지 마세요.

소프트웨어 PNG는 실제 Part 위치·크기·색으로 만든 형상 검토입니다. Roblox Stud 표면·조명·그림자·흐름·바람·성능을 재현한 게임 화면은 아닙니다.

## 사용자 로켓 가져오기와 출발창 검토

1. Studio에서 현재 게임 장소를 열고 **File → Save to File**로 사본을 저장한 뒤 Play를 정지합니다.
2. **File → Import**를 열고 저장소의 `assets/models/UserRocket/Rocket.gltf`를 선택합니다. 구버전 메뉴에서는 **Import 3D**로 표시될 수 있습니다. `Rocket.bin`과 PNG2장은 같은 폴더에 그대로 둡니다. 원본 GLB의 메시·UV·법선·재질·PNG바이트를 그대로 풀어 준비한 파일이며 색/형상을 변경하지 않았습니다. 미리보기에서 빨간 꼭대기/흰 몸체/원형 창/돌기가 보이는지 확인하고 가져옵니다. Roblox 자산 업로드 권한 확인은 본인 계정에서 진행합니다. [Roblox 공식 Importer 안내](https://create.roblox.com/docs/studio/importer)
3. Explorer에서 가져온 로켓의 최상위 **Model** 이름을 `RocketImport`로 바꾸고 `Workspace` 바로 아래에 둡니다. 파일 안의 개별 MeshPart 이름을 바꾸는 것이 아닙니다.
4. `dist/ReviewModels/InstallUserRocket.commandbar.lua` 전체를 Command Bar에서 실행합니다. 현재 스크립트 버전의 연결 지점이 다르면 기존 코드를 유지하고 중단합니다. Output의 `ROCKET_DEPARTURE_PREPARED`가 성공 표시입니다.
5. 중앙 로켓은 높이약64.3studs로 배치됩니다. 기존 비행선 구역과 수정 전 스크립트, 가져온 원본은 `ServerStorage.RocketDepartureBackup_시간`에 남깁니다. 로켓 메시 자체의 복잡한 물리 충돌은 끄고 Stud 받침 바닥만 충돌시킵니다.
6. **Play**에서 중앙 로켓의 앞쪽 가까이 가서 **E를1초** 누릅니다. 모바일은 근처에서 나타나는 기본 상호작용 버튼을 길게 누릅니다. **Green Star → 다음 → 보유 몬스터** 창이 나오는지 확인합니다. X로 취소합니다.
7. 새 몬스터 모델/숲 런타임이 연결되기 전에는 **준비 중** 안내가 정상입니다. 빈 가방에는 옛 모스랫을 임의 지급하지 않습니다. 무료1성 모스랫은 사용자 새 모델을 받은 뒤 연결합니다.

개발 연결 표식 `UserApprovedHuntModel`(서버 보관 승인 모델) 및 `GreenStarRuntimeReady`(새 숲 런타임)는 에이전트가 실제 모델·맵 연결을 끝낸 후 설정할 내부 표식입니다. 사용자가 준비되지 않은 기존 모델/맵에 직접 켜서 출발 검사를 우회하는 절차가 아닙니다.

원본 로켓은 텍스처4K2장/파일약20MB입니다. 모바일에 적합한 최종 텍스처 크기와 실제 메모리는 기기에서 확인해야 합니다. 현재 원본 텍스처를 임의 축소하지 않았습니다.

## 검증 범위

코드 검사: 전체 길이·격자·5면Studs·판 지지·중첩 면 없음·통과 경로·기존 모델 백업/생성 실패 복구, 실제 출발 서비스의 소유권·거리·잠금·만료·재전송·실패 재시도, 연결된 서버/클라이언트 코드의 Luau 컴파일.

미완료: Studio 실제 가져오기/설치/환경 렌더, PC·모바일 실행 및 FPS·메모리, 터치/작은 화면의 실제 가독성, 신규 몬스터/1km사냥 런타임 연결. 코드 검사를 실제 플레이 검증 완료로 취급하지 않습니다.
