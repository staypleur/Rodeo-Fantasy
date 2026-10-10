# 새 UI와 제공 로비 모델 적용

최신 인덱스·정면 미리보기·제공 버튼 이미지와 HTTP 502 텍스처 재시도는 `docs/APPLY_INDEX.md`를 참고합니다. 기존 장소에 인덱스만 적용하려면 `dist/InstallIndex.commandbar.lua`를 사용합니다.

현재 색상이 표시되는 장소를 계속 사용합니다. 코드 수정 파일과 모델 설치 파일을 순서대로 실행합니다. 에이전트가 실행 중인 Studio에 직접 적용한 상태는 아닙니다.

## 1. UI·복귀·천장 수정

1. Studio에서 Play를 중지하고 Ctrl+S로 저장합니다.
2. `dist/FixCurrentLobbyHunt.commandbar.lua`를 메모장으로 열고 Ctrl+A → Ctrl+C를 누릅니다.
3. Studio **보기/창 → 명령 모음(Command Bar)**에 붙여 넣고 Enter를 누릅니다.
4. 출력에 `LOBBY_HUNT_FIXES_INSTALLED`가 나오면 저장합니다.

왼쪽은 룰렛/상점/도감, 오른쪽은 알/발자국, 왼쪽 아래는 몬스터 수/돈입니다. 발자국 → 동행 선택 → 같은 몬스터 재선택으로 해제합니다. 알 관리에서 알 배치는 자기 부화실 안에서 이용합니다. 새끼 캡슐은 준비 중으로 표시하며 미정 기능을 만들지 않았습니다.

랭킹은 로켓 양옆 바닥에 표시하고 충돌을 끕니다. 검은 출발 간판 및 옛 배경 행성은 백업으로 이동합니다. 천장은 유리, 벽은 불투명 금속, 바닥 아래에는 보이지 않는 충돌판이 있습니다. 로비 복귀 시 잠시 캐릭터를 고정하고 다시 착지시킨 뒤 이동을 복원합니다. 실제 실패 해결 여부는 Play로 확인해야 합니다.

## 2. 모델 네 개 가져오기

프로젝트 `assets/models/LobbyModules` 아래 각 폴더의 파일을 사용합니다. **홈/모델 → 가져오기**에서 한 개씩 선택하고, 재질·텍스처를 포함해 Workspace에 추가합니다.

| 파일 | Workspace의 전체 Model 이름 |
|---|---|
| `Incubator/Incubator.glb` | `IncubatorImport` |
| `Door/Door.glb` | `DoorImport` |
| `Console/Console.glb` | `ConsoleImport` |
| `Planet/Planet.glb` | `PlanetImport` |

탐색기에서 각 파일을 가져온 **가장 바깥쪽 Model**을 선택하고 F2로 위 이름을 지정합니다. 메시 한 부품의 이름만 바꾸면 안 됩니다. 가져오기 실패 항목은 설치된 모델이 아닙니다.

원본 GLB가 실패하면 같은 폴더의 `.gltf` 복구 파일을 시도합니다. `.gltf`, `.bin`, Texture 파일은 같은 폴더에 있어야 합니다. 저장소를 새로 받은 경우 `tools/prepare_lobby_models.py`로 복구 파일을 재생성합니다. 회색 메시만 들어왔다면 텍스처까지 성공한 것으로 취급하지 않습니다.

## 3. 8개 구역에 설치

1. Play가 중지된 상태에서 `dist/InstallLobbyModules.commandbar.lua`를 메모장으로 엽니다.
2. 전체 복사 → Studio 명령 모음 붙여 넣기 → Enter.
3. `LOBBY_MODULES_INSTALLED`가 나오면 Ctrl+S로 저장하고 Play를 누릅니다.
4. 부화기 8개, 문틀 8개, 콘솔 8개와 유리 천장 위 행성을 확인합니다. 문 가까이 가면 두 문짝이 좌우로 열리는지, 문에서 멀어지면 닫히는지도 확인합니다.

자동문 원본은 문짝 없는 빈 문틀이므로 원본 형상을 자르지 않았습니다. 새 금속 문짝 2개를 기존 자동 개폐 코드에 연결합니다. 기존 모델·가져오기 원본은 ServerStorage의 `LobbyModulesBackup_…`에 보관합니다. 새끼 양육 캡슐은 새 모델 수령 후 교체합니다.

## 4. 모스랫 얼굴 이미지

`assets/ui/MossratFace.png`는 제공 모스랫 화면을 참고해 만든 투명 2D 아이콘입니다. 모델에서 직접 렌더한 이미지가 아닌 그림입니다. 아직 Roblox 이미지 에셋으로 업로드하지 않아 기본 얼굴 도형을 표시합니다.

Studio **에셋 관리자 → 이미지 → 가져오기**로 PNG를 올리고 **이미지 ID**를 확인한 뒤 명령 모음에서 아래 숫자를 실제 이미지 ID로 바꿔 실행합니다. Decal ID 대신 이미지 콘텐츠 ID가 필요합니다.

```lua
game.ReplicatedStorage.RodeoFantasy:SetAttribute("MossratFaceImage","rbxassetid://이미지ID")
```

Ctrl+S로 저장합니다. 이미지 ID를 알려주시면 코드에도 기록할 수 있습니다. 4개 모델 및 아이콘의 실제 Roblox 업로드, Studio 화면, PC·모바일 실행과 성능 검증은 남아 있습니다.

원본 텍스처는 각 모델에 4096×4096 이미지 2개입니다. 복제 시 같은 이미지 에셋을 공유하지만 모바일에서의 메모리·렌더링 검증은 아직 하지 않았습니다. 원본 파일은 보존하며 크기 축소본 제작은 별도로 진행할 수 있습니다.
