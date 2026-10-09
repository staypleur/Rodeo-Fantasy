# 승인한 하늘고래를 Studio에 넣기

코드와 설치 준비 파일은 저장되어 있지만 고래 메시의 Studio 가져오기는 아직 실행하지 않았다. 현재 도구에는 Studio를 직접 조작하는 기능이 없다. 아래 단계는 한 번만 진행한다. 이전 사용자 시험 파일은 덮어쓰지 않는다.

1. Roblox Studio의 시험을 정지한다. Ctrl+O로 `C:\Users\wucha\OneDrive\바탕 화면\Project\Rodeo Fantasy\dist\RodeoFantasy-SkyWhaleReady.rbxlx`를 연다. 아직 기존 비행선이 보이는 것이 정상이다.
2. 상단 **파일 → 가져오기**(Ctrl+M)를 누른다. 파일 선택창 주소/파일 이름 칸에 `C:\Users\wucha\OneDrive\바탕 화면\Project\Rodeo Fantasy\dist\SkyWhale_BodyReview.gltf`를 붙여 넣고 연다. 파일 탐색기로 폴더를 하나씩 찾지 않아도 된다.
3. 가져오기 미리 보기의 **파일 일반**에서 이름은 `SkyWhale_BodyReview`, **모델로만 가져오기 / Roblox에 업로드 / 작업 공간에 추가**는 켜 둔다. **파일 변환**은 월드 앞으로=전면, 월드 위로=상단이다. **파일 지오메트리**는 스케일 단위=스터드, 배율=1, **메시 병합은 끈다**. 눈·몸 색이 있는지 확인하고 **가져오기**를 누른다. 성공 상태가 표시될 때까지 기다린다. 색이 없거나 오류가 있으면 설치를 실행하지 말고 오류 내용을 알려준다.
4. 오른쪽 **탐색기 → Workspace → SkyWhale_BodyReview** 모델을 한 번 클릭한다. 모델 안의 개별 부품을 선택하지 않는다. 아래 **명령 표시줄**에 다음 한 줄을 붙여 넣고 오른쪽 **실행**을 누른다. 명령 표시줄이 안 보이면 상단 **보기** 또는 **창** 메뉴에서 명령 표시줄을 켠다.

```lua
require(game.ServerStorage.SkyWhaleInstaller).install(game:GetService("Selection"):Get()[1])
```

5. 고래가 로비 바구니 위에 배치되면 Ctrl+S로 저장하고 F5로 시험한다. 지느러미와 꼬리가 천천히 움직이고, 사다리로 바구니에 올라간 뒤 기존 E 1초/모바일 출발 프롬프트가 동작하는지 확인한다. 움직임은 플레이 시험 중에만 나온다. 아래 바구니와 사다리는 고정이다.

성공 시 출력 창에 `SKY_WHALE_INSTALLED`가 표시된다. 설치는 18개 메시·색 텍스처를 확인한 후 기존 비행선을 교체한다. 이전 비행선과 가져온 원본은 ServerStorage의 SkyWhaleBackup 폴더에 보관한다. 이후 시험은 저장한 SkyWhaleReady 파일을 사용한다. 생성 도구를 다시 실행하면 설치 전 파일로 돌아가므로 설치 후 파일을 다시 생성하지 않는다.

이번 고래는 저장된 MeshPart와 색 텍스처를 사용한다. 실시간 EditableMesh/EditableImage를 추가하지 않는다. 실제 가져오기·조명·유영·등반·출발·모바일/PC 성능은 Studio와 기기에서 추가 확인해야 한다. 소스와 파일 검사는 실제 실행 확인을 대신하지 않는다.

가져오기 옵션 근거: [Roblox 공식 Importer 문서](https://create.roblox.com/docs/studio/importer).
