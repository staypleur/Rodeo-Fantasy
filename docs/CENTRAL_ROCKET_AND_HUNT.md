# 현재 Studio 맵에 적용

현재 열어둔 맵의 미저장 모델/색상 설정을 보존하려면 새 장소를 다시 여는 대신 아래 설치 코드를 실행한다. 실행 전 파일 → 다른 이름으로 저장으로 별도 사본을 저장한다.

## 사냥터·모스랫 방향

1. Studio의 빨간 정지 버튼으로 Play를 종료한다.
2. dist/RestoreLegacyHunt.commandbar.lua를 텍스트 편집기로 열고 전체를 복사한다.
3. Studio 보기 또는 창 → 명령 모음(Command Bar)에 붙여넣고 실행한다.
4. 출력에 LEGACY_HUNT_RESTORED가 나오면 Ctrl+S로 저장한다.
5. Play → 중앙 출발 지점 E → Green Star → 보유 모스랫 선택. 이전 협곡/초원과 모스랫 앞 방향을 확인한다. ground는 Play에서 생성되므로 편집 화면에 사냥터가 비어 있는 것은 정상이다.

## 새 로켓

1. Studio 홈 → 가져오기에서 assets/models/CentralRocket/Rocket.glb를 선택한다. 전체 모델을 Workspace에 가져온다. 모델 색상이 보이는지 확인한다.
2. 가져온 전체 Model 이름을 RocketImport로 바꾼다. MeshPart 하나의 이름만 바꾸면 안 된다.
3. dist/InstallCentralRocket.commandbar.lua 전체를 명령 모음에 붙여넣고 실행한다.
4. 출력 CENTRAL_ROCKET_INSTALLED 확인 → Ctrl+S. 중앙의 기존 로켓은 ServerStorage/CentralRocketBackup_...에 보관된다. 기존 E 출발 지점은 유지한다.
5. Play에서 중앙 E를 눌러 기존 행성·몬스터 선택과 출발이 되는지 확인한다.

가져오기 실패 시 같은 폴더 Rocket.gltf 대안이 있다. RocketMeshOnly.gltf는 이미지 가져오기를 제외한 진단용으로 회색이 정상이다. 색상 PNG는 Color.png이며 업로드 성공만으로 실제 표시 성공을 단정하지 않는다. Studio 실제 설치·텍스처 표시·주행은 아직 확인하지 않았다.
