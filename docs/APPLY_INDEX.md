# 인덱스·정면 미리보기 적용

기존 색상과 업로드된 모델을 보존합니다. 에이전트가 실행 중인 Studio에 적용한 상태는 아닙니다.

1. Roblox Studio에서 Play를 중지하고 Ctrl+S로 저장합니다.
2. 프로젝트 `dist/InstallIndex.commandbar.lua`를 메모장으로 엽니다. Ctrl+A → Ctrl+C.
3. Studio **보기/창 → 명령 모음(Command Bar)**에 붙여 넣고 Enter를 누릅니다.
4. 출력에 `INDEX_UPDATE_INSTALLED`가 나오면 Ctrl+S → Play.
5. 왼쪽 **인덱스** 버튼 또는 T를 누릅니다. Green Star 분류, 4개 카드, 선택 상세, 실제 수집 수를 확인합니다. X로 닫힌 뒤 이동이 복원되는지도 확인합니다.

모스랫 미리보기는 사선 위쪽 카메라 대신 정면 카메라를 사용하며, 게임과 같은 중립 머리 보정을 즉시 적용합니다. 실제 형상의 정렬과 다리 동작은 Studio에서 확인해야 합니다. 원본 메시·UV·텍스처·게임 이동 방향은 유지합니다.

`assets/ui/IndexPreview.png`는 배치 검토용 그림입니다. 미리보기의 2D 얼굴과 예시 숫자는 실제 Studio의 3D 화면 및 플레이어 데이터가 아닙니다. 실제 인덱스는 기존 수집 데이터와 수입 공식을 사용합니다. 현재 모스랫 1·3·6·9성 네 항목이므로 분모는 4이며, 다른 게임의 보상을 추가하지 않았습니다.

## 제공 버튼 이미지

`assets/ui/ShopButton.png`, `IndexButton.png`, `EggButton.png`, `PawButton.png`를 원본 그대로 저장했습니다. Roblox가 로컬 PNG 경로를 게임 이미지로 읽지는 못하므로 업로드된 **이미지 콘텐츠 ID**가 필요합니다.

1. Studio의 **에셋 관리자 → 이미지 → 가져오기**에서 네 PNG를 업로드합니다.
2. 각 이미지의 콘텐츠 ID를 확인합니다. Decal ID를 넣으면 에셋 유형 불일치가 날 수 있습니다.
3. 명령 모음에서 아래 각 숫자를 실제 해당 이미지 ID로 바꿔 실행합니다. 아래 0은 예시이며 그대로 실행하지 않습니다.

```lua
local p=game.ReplicatedStorage.RodeoFantasy
p:SetAttribute("ShopButtonImage","rbxassetid://0")
p:SetAttribute("IndexButtonImage","rbxassetid://0")
p:SetAttribute("EggButtonImage","rbxassetid://0")
p:SetAttribute("PawButtonImage","rbxassetid://0")
```

4. Ctrl+S → Play에서 실제 이미지를 확인합니다. 아직 ID를 설정하지 않으면 기본 버튼을 표시합니다. 테스트 중에도 속성을 바꾸면 버튼 이미지가 갱신됩니다.

`MoneyReference.png`의 $702.4K는 디자인 참고용으로만 보관합니다. 돈 표시는 실제 잔액+미수령 수입을 동적으로 계산하며 예시 금액을 고정 표시하지 않습니다. 룰렛은 기존 버튼을 유지합니다.

## 부화기·행성 텍스처 HTTP 502 재시도

현재 로그는 Roblox 서버에서 텍스처를 받는 단계의 HTTP 502입니다. 업로드 성공 여부나 영구적인 파일 손상을 이 로그만으로 확정할 수 없습니다.

1. Play를 중지하고 Ctrl+S로 저장합니다.
2. `dist/RetryLobbyTextures.commandbar.lua`를 메모장으로 열고 전체 복사합니다.
3. Studio 명령 모음에 붙여 넣고 Enter를 누릅니다.
4. `LOBBY_TEXTURE_RETRY_REQUESTED`와 로딩 성공/실패 수를 확인합니다. 부화기·문틀·콘솔·행성의 원래 텍스처 ID를 유지한 채 한 번 재요청합니다.
5. 색상과 재질이 화면에 표시되는지 확인합니다. 502가 계속되면 재실행을 반복하지 말고 잠시 후 저장한 장소를 다시 열어 확인합니다.

재시도 파일은 Workspace 안의 IncubatorImport / DoorImport / ConsoleImport / PlanetImport 및 설치된 UserIncubator / UserDoorFrame / UserDoorConsole / CeilingPlanet을 대상으로 합니다. RodeoLobby 아래에 중첩되어 있어도 찾으며, ServerStorage의 백업 원본은 건드리지 않습니다. `LOBBY_TEXTURE_TARGETS`의 모델/재질/업로드 맵/임시 맵 수로 찾은 대상을 확인할 수 있습니다. 모델 및 SurfaceAppearance를 삭제하지 않습니다. 로딩 성공 수는 실제 재질 렌더링 검증과 구분합니다. 네 모델이 정상 표시되면 기존 `dist/InstallLobbyModules.commandbar.lua`로 8개 구역에 배치합니다.

코드·파일 검사와 모의 실행은 통과했지만 실제 Studio·PC·모바일 조작, 이미지 업로드, Roblox 텍스처 복구 여부와 성능 측정은 아직 확인하지 않았습니다.
