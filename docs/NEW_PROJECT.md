# 새 프로젝트 실행

앞으로 사용하는 맵 파일은 **dist/RodeoFantasy-New.rbxlx** 하나입니다. Stud 우주선 로비와 Green Star 숲을 연결했습니다. 실제 Studio 실행, 모바일·PC 실행, 모델 업로드는 아직 검증하지 못했습니다.

1. Studio에서 실행 중인 **Play를 중지**합니다. 기존 맵에 저장하지 않은 작업이 있으면 사본으로 저장합니다.
2. **파일 → 파일 열기**에서 `C:\Users\wucha\OneDrive\바탕 화면\Project\Rodeo Fantasy\dist\RodeoFantasy-New.rbxlx`를 엽니다.
3. Explorer에서 **Workspace → RodeoLobby**를 선택하고 **F**를 누르면 우주선 로비가 보입니다. 부화실 8개, 알 자리 32개, 자동문과 중앙 로켓 자리를 확인합니다. **Workspace → GreenStar**를 선택하고 F를 누르면 1km 숲, Stud 바닥, 얇은 판으로 쌓은 나무·바위와 폭포를 확인할 수 있습니다.
4. **Play**를 눌러 로비에서 시작하는지, 방 앞으로 가면 문이 열리는지 확인합니다. 내 방 안에서 E를 1초 눌러 알 관리와 가방·도감 UI를 확인합니다. 모델을 가져오기 전에는 ‘모델 준비 중’으로 표시됩니다.

## 모델 가져오기 재시도

현재실패상세원인은미확인이다. 아래는경로·다중검토클립변수를줄이는재시도이며성공보장이아니다.

1. `dist\ImportRecovery\RodeoImport.zip`을파일탐색기에서**모두압축풀기**. 대상은 `C:\Users\wucha\Downloads\RodeoImport`처럼영문경로로지정.
2. Studio **파일 → 가져오기**에서 `C:\Users\wucha\Downloads\RodeoImport\Mossrat\Mossrat.gltf` **한개만**선택. 같은폴더Data0.bin/Texture0.png/Texture1.png유지.
3. **Rig Type=Custom / 영향이없는뼈보관=체크 / 작업공간에추가=체크**. 모델만가져오기체크는유지가능. 형상·색·재질·리그오류를확인.
4. 재질오류:BakedMaterial선택후폴더버튼으로같은폴더의 **색상=Texture0.png / 금속성=Metalness.png / 거칠기=Roughness.png** 직접선택. 일반·이미시브는비움. 오류가사라지기전에설치를진행하지않는다.
5. 성공한전체Model을Workspace바로아래로두고 **MossratImport**로이름변경.
6. 로켓은 `C:\Users\wucha\Downloads\RodeoImport\Rocket\Rocket.gltf`를별도로가져오기. 재질직접선택은동일. 전체Model이름 **RocketImport**.
7. 프로젝트 `dist\InstallModels.commandbar.lua`를메모장으로열어전체복사. Studio **보기/창 → Command Bar**에붙여넣고Enter. 한 모델만성공했다면그모델만먼저연결가능.
8. Output의 **MOSSRAT_RIG_INSTALLED / NEW_ROCKET_INSTALLED / NEW_PROJECT_MODELS_INSTALLED** 확인. Ctrl+S저장. 입력과이전모델은ServerStorage백업.
9. **Play**:로켓앞E1초→Green Star→보유모스랫선택→개인사냥/A·D/Space점프·줄/포획·가방증가/1000m끝확인. 새가방은무료1성/기존계정데이터유지. 모바일실기기검증별도.

복구묶음은원본메시·UV·스킨·텍스처를변경하지않고영문파일명으로정리했다. 가져오기gltf에서검토클립4개만제외했고게임은별도승인키데이터로Idle/Walk를재생한다. 원본리깅·검토클립은assets/models에남긴다.

## 임시 텍스처 오류가 반복될 때

`ColorMap/RoughnessMap/MetalnessMap 'rbxtemp://...'` 오류는 미리보기의 임시 텍스처 로드 실패입니다. 이 문장만으로 경로, Studio 내부 처리, 업로드 권한 중 원인을 확정할 수 없습니다.

1. 가져오기 창을 닫습니다. 갱신된 `dist/ImportRecovery/RodeoImport.zip`을 `C:\Users\wucha\Downloads\RodeoImport`에 다시 압축 해제합니다.
2. **파일 → 가져오기**에서 `Mossrat/MossratMeshOnly.gltf`를 선택합니다. Rig Type=Custom, 영향이 없는 뼈 보관, 작업공간에 추가를 켭니다. 이 파일은 재질을 제외했으므로 회색이 정상입니다. 성공한 모델을 `MossratImport`로 바꿉니다.
3. Explorer에서 모델 안의 `MossratS1Body` MeshPart를 찾습니다. SurfaceAppearance가 있다면 선택하고, 없다면 MeshPart 옆 **＋ → SurfaceAppearance**로 추가합니다.
4. **속성 → ColorMap**의 이미지 선택 창에서 로컬 이미지 업로드/추가 기능으로 같은 폴더의 `Texture0.png`를 올립니다. 생성된 이미지 자산을 선택합니다. 업로드가 실패하면 이 단계의 오류로 원인을 더 좁힐 수 있습니다.
5. 초록색·크림색이 표시되면 RoughnessMap에는 `Roughness.png`, MetalnessMap에는 `Metalness.png`를 같은 방법으로 연결합니다. NormalMap은 비워 둡니다. 먼저 색상만 연결해서 확인해도 됩니다.
6. 색과 뼈대를 확인한 다음 위의 InstallModels 설치를 진행합니다. 로켓도 `Rocket/RocketMeshOnly.gltf`를 가져와 해당 폴더의 PNG를 같은 방식으로 연결합니다.

별도 이미지 업로드 후 SurfaceAppearance 맵에 이미지 자산을 연결하는 방식은 [Roblox 공식 문서](https://create.roblox.com/docs/art/modeling/surface-appearance)에 설명되어 있습니다. 우회 파일의 메시·UV·뼈대·가중치는 파일 검사로 확인했습니다. 실제 Studio 업로드 성공은 아직 미확인입니다.

## 남은 사항과 복구

- 원인불명의Roblox업로드실패및실제Studio검증.
- 로비동행·교감런타임연결. 로비탑승불가기획유지.
- 카페새맵·별도Place·정원설정후시스템활성화. 지금카페서버·클라이언트Disabled/옛맵생성없음.
- 사냥간소화모델·텍스처최적화·실제모바일·PC렌더/조작/FPS·메모리. 40/20/40화면비중실제검증전.

삭제전523개전체파일을 `.local-backup/pre-reset-files.zip`에보관하고SHA256검증했다. 미커밋서버·장소사본도복구폴더에있다. 로컬복구폴더는GitHub에올리지않는다. 이전Git작업은이력으로도복구가능. 플레이어DataStore삭제·초기화없음.

## 웹 업로드 ID의 자산 종류 오류

웹 데칼 업로드 항목의 ID와 그 안의 이미지 ID는 다를 수 있습니다. `Asset type does not match requested type`이면 데칼 ID를 PBR 맵에 직접 넣지 않습니다. 앞서 Metalness 업로드 ID를 바로 사용하도록 안내한 것은 잘못된 안내였습니다.

Studio에서 Play를 중지하고 **창 → 명령 모음(Command Bar)**에 아래 코드를 붙여넣고 Enter를 누릅니다. 자신의 데칼을 로드하여 이미지 참조를 읽고, 임시 객체는 작업공간에 넣지 않고 제거합니다. 성공 시 `METALNESS_CONNECTED`와 이미지 주소가 출력됩니다. 이는 코드 컴파일만 확인했으며 실제 계정의 자산 로드는 아직 미확인입니다.

```lua
local asset = game:GetService("InsertService"):LoadAsset(113223833745998)
local decal = asset:FindFirstChildWhichIsA("Decal", true)
assert(decal, "Loaded asset has no Decal")
local image = decal.ColorMap
if image == "" then image = decal.Texture end
asset:Destroy()
assert(image ~= "", "Decal has no image reference")
local model = assert(workspace:FindFirstChild("MossratImport"), "MossratImport not found")
local body = assert(model:FindFirstChild("MossratS1Body", true), "MossratS1Body not found")
local surface = assert(body:FindFirstChildOfClass("SurfaceAppearance"), "SurfaceAppearance not found")
surface.MetalnessMap = image
print("METALNESS_CONNECTED", image)
```

[Decal 맵 속성](https://create.roblox.com/docs/reference/engine/classes/Decal)과 [InsertService](https://create.roblox.com/docs/reference/engine/classes/InsertService)는 Roblox 공식 문서를 기준으로 합니다. ColorMap과 RoughnessMap도 각각의 데칼 안 이미지 참조를 사용해야 합니다.

## 새 맵을 먼저 열라는 설치 오류 수정

초기 새 맵에서 자동문 스크립트 누락으로 설치기가 새 맵을 거부하던 버그를 수정했습니다. 이미 모델과 재질을 연결한 경우 현재 Studio 맵을 다시 열지 마세요. Play를 중지하고, 현재 맵을 별도 사본으로 저장한 뒤 갱신된 InstallModels.commandbar.lua 전체를 다시 복사하여 Command Bar에서 실행합니다. SPACE_LOBBY_DOORS_REPAIRED는 누락 자동문 복구, MOSSRAT_RIG_INSTALLED는 모델 연결 완료 메시지입니다. Ctrl+S로 저장 후 실제 자동문·가방·도감·모델 모션을 확인합니다.


## 현재 Studio 맵에 로비·사냥 보완 적용

모스랫을 이미 연결했다면 현재 작업공간을 유지하는 업데이트가 편합니다. 현재 연결한 모델·이미지 ID를 보존하고, 로비와 필요한 코드만 수정합니다.

1. Studio에서 **Play를 중지**합니다. **파일 → 다른 이름으로 파일에 저장**으로 현재 맵의 사본을 먼저 저장합니다.
2. 프로젝트의 `dist/UpdateCurrentProject.commandbar.lua`를 메모장으로 엽니다. **Ctrl+A → Ctrl+C**로 전체를 복사합니다.
3. Studio의 **창 → 명령 모음(Command Bar)**에 붙여넣고 Enter를 누릅니다.
4. 출력에 **LOBBY_HUNT_UPDATE_INSTALLED**가 나오는지 확인합니다. 수정 전 로비와 코드는 ServerStorage의 LobbyUpdateBackup 폴더에 보관됩니다. **Ctrl+S**로 저장합니다.
5. **Play**를 누릅니다. 로비 이동속도, 투명 헬멧, 닫힌 천장, 각 방의 이름표를 확인합니다. 자기 부화실에 들어가 가방의 모스랫 소환 버튼을 1초 누르거나 카드 위에서 E를 1초 누릅니다. 한 마리가 따라오는지, 다시 선택하면 소환 해제되는지 확인합니다. 자기 몬스터의 교감 E는 하트 효과만 표시하며 탑승은 없습니다.
6. 중앙 로켓 자리의 앞쪽으로 가서 **E를 1초 → Green Star → 보유 몬스터 선택 → 출발**합니다. 자동 전진, A/D, 점프 후 Space 줄 던지기, 늘어나는 m 표시, 먼지·바람·점프·줄·착지 소리를 확인합니다. 모바일에서는 기존 터치 조작과 효과 표시를 별도로 확인합니다.

소환은 자기 부화실에서만 시작할 수 있습니다. 플레이어당 한 마리이고 거래 잠금·교배팀·다른 사람의 가방 ID를 사용할 수 없습니다. 소환한 몬스터는 로비에서 따라다니지만 사냥 출발·진화·캐릭터 제거 시 정리합니다.

### 중앙 로켓을 실제 모델로 연결

로켓은 아직 가져오지 않았다는 사용자 답변을 받았습니다. 지금 중앙에 실제 로켓이 없다는 것은 로비 업데이트만으로 해결되지 않습니다.

1. `dist/ImportRecovery/RodeoImport.zip`을 영문 Downloads 경로에 압축 해제합니다.
2. Studio **파일 → 가져오기**에서 `Rocket/RocketMeshOnly.gltf`를 가져옵니다. 전체 모델을 Workspace 바로 아래에 두고 이름을 **RocketImport**로 바꿉니다.
3. 로켓 폴더의 Texture0.png, Metalness.png, Roughness.png는 모스랫처럼 웹 대시보드로 업로드합니다. 데칼 업로드 ID는 실제 이미지 ID와 다르므로 데칼 안의 ColorMap/Texture 참조로 변환하여 연결합니다. 모스랫 이미지 ID를 로켓에 사용하지 않습니다.
4. 색상이 표시된 후 `dist/InstallModels.commandbar.lua` 전체를 Command Bar에서 실행합니다. **NEW_ROCKET_INSTALLED** 확인 후 Ctrl+S로 저장합니다. 모스랫은 이미 설치된 상태이면 다시 가져올 필요가 없습니다.

### 검증 범위

저장된 맵에서 실제 모스랫 업로드 ID와 세 재질 연결을 보존했습니다. 코드·XML·설치 전 경로 검사·소환 소유권 검사·기존 가방 규칙 검사는 통과했습니다. 실제 출발·머리 방향·충돌·UI·헬멧·소리와 PC/모바일 FPS·메모리는 아직 검증하지 못했습니다. 영상 자체도 재생 확인 전입니다.

바람 소리는 [Creator Store wind](https://create.roblox.com/store/asset/2306939610/wind)를 연결한 시험용 설정입니다. 실제 게임에서 자산 권한이나 로드 오류가 나오면 교체 또는 사용 권한 확인이 필요합니다. 개별 효과음 권한과 볼륨도 실제 Studio에서 확인합니다.

## 이미 설치한 모스랫 확인 (재업로드 불필요)

가져오기 대기열의 Mossrat.gltf/Metalness.png 실패와 로비 업데이트 성공은 별개입니다. 저장된 RodeoFantasy-New.rbxlx에는 기존 업로드 메시 112233757801076과 리그가 있습니다. 재질은 기존 SurfaceAppearance와 TexturePack을 그대로 보존합니다.

1. Play를 중지합니다. 실패한 가져오기 대기열은 닫습니다.
2. dist/ShowInstalledMossrat.commandbar.lua를 메모장으로 열고 전체 복사합니다.
3. Studio의 창 → 명령 모음(Command Bar)에 붙여넣고 Enter를 누릅니다.
4. INSTALLED_MOSSRAT_READY가 나오면 선택된 모델에 F를 눌러 확인합니다. Workspace의 InstalledMossratPreview는 확인용 복제이며 게임 템플릿은 수정하지 않습니다. 확인 후 이 복제만 삭제할 수 있습니다.

업로더 실패 원인은 아직 확정하지 못했습니다. 이 절차는 기존 설치 모델을 사용하므로 추가 업로드가 필요하지 않습니다. 실제 색상과 모션 확인은 Studio에서 남아 있습니다.

### 회색 모스랫의 색상 복구

확인용 복제가 회색인 사용자 화면 확인. 저장 XML에서 ColorMap=null이고 TexturePack만 남아 있어 색상 표시 완료로 판단하지 않습니다. Play 중지 후 dist/RepairMossratColor.commandbar.lua를 전체 복사하여 Command Bar에 실행합니다. 웹에 이미 올린 색상 데칼 88970410075115에서 실제 이미지 주소를 읽고 설치 템플릿 3개와 확인용 복제의 ColorMap을 연결합니다. MOSSRAT_COLOR_CONNECTED 출력 후 초록색·크림색이 보이면 Ctrl+S로 저장합니다. 주소 연결 성공과 실제 이미지 로딩 성공은 구분합니다. 실패 시 새 오류를 확인하며 재업로드하지 않습니다.

## 최신 안내: 회색 모스랫과 로켓 모델 제거

기존 로켓 메시 가져오기 절차는 더 이상 사용하지 않습니다. 사용자가 맵으로 새로 제작하기로 변경했습니다. 중앙 출발 기능은 유지합니다.

회색 모스랫은 Play 중지 후 dist/MossratTextureFallback.commandbar.lua 전체를 Command Bar에 실행합니다. 기존 웹 업로드 색상 이미지의 로딩 상태를 MOSSRAT_IMAGE_FETCH로 출력합니다. 실패하면 모델을 변경하지 않습니다. 성공하면 원래 UV를 사용하는 MeshPart.TextureID로 색상을 연결하고 기존 PBR은 ServerStorage의 MossratTextureBackup에 보관합니다. 초록색·크림색 표시를 확인한 뒤 Ctrl+S. 주소만 연결된 메시지는 실제 표시 완료를 뜻하지 않습니다. 실패 시 MOSSRAT_IMAGE_FETCH 문장과 이어지는 오류가 진단 근거입니다.

## 최신 적용: 승인한 새 우주선 로비

사용자가 검토안 배치를 승인하고 이미지에 가까운 디자인 보완을 요청했습니다. 저장된 메인 맵에는 새 로비를 연결했습니다. 현재 Studio 작업을 유지하려면 다음 설치 코드를 사용합니다. 기존 모델 가져오기는 필요하지 않습니다.

1. Play를 중지하고 **파일 → 다른 이름으로 파일에 저장**으로 현재 작업의 사본을 저장합니다.
2. `C:\Users\wucha\OneDrive\바탕 화면\Project\Rodeo Fantasy\dist\InstallOrbitalLobby.commandbar.lua`를 메모장으로 열고 **Ctrl+A → Ctrl+C**.
3. Studio **창 → 명령 모음(Command Bar)**에 붙여넣고 Enter.
4. **ORBITAL_LOBBY_INSTALLED**가 나오면 **Ctrl+S**. 기존 로비와 변경 전 코드는 ServerStorage의 OrbitalLobbyBackup 폴더에 보관됩니다. 기존 업로드 모스랫/이미지 주소는 수정하지 않습니다.
5. Play를 눌러 중앙 Stud 로켓 앞의 **E 1초 → Green Star → 보유 몬스터 → 출발**을 확인합니다. 개인실 자동문, 자신의 이름표, 알 관리에 부화소 1개만 보이는지 확인합니다. 옛 2~4번 알은 다음 접속 때 가방으로 돌아갑니다. 빈 새끼 캡슐은 외형만 있고 상호작용 버튼/성장·수입 기능은 없습니다.
6. 자기 방에서 가방의 모스랫 소환을 확인합니다. 부화실마다 알 부화기 1개, 빈 캡슐 4개가 있어야 합니다. 사냥·가방·도감·수입도 기존대로 확인합니다.

Studio에 보관할 작업이 없다면 파일 → 파일 열기로 `dist/RodeoFantasy-New.rbxlx`를 열어도 됩니다. 두 방식 중 하나만 사용하세요. 이전 UpdateCurrentProject.commandbar.lua는 이제 동일한 새 로비 설치 코드의 호환 사본입니다.

맵에는 닫힌 천장, 투명 우주 창, 메시 업로드가 필요 없는 블록 로켓과 행성, 상점/랭킹/룰렛/배틀패스 외형 자리가 포함됩니다. 실제 플레이 시 조명·유리·글자·자동문과 모바일/PC 화면 및 프레임을 확인해야 합니다. 검토 이미지는 일부 벽·천장을 숨긴 기하 렌더이며 실제 Studio 스크린샷이 아닙니다. 모스랫 회색 문제는 별도 텍스처 검사 결과가 남아 있으며 로비 설치로 해결됐다고 보장하지 않습니다.

## 최신 상태: 기존 Stud 로비 디자인 철회

사용자가 디자인을 거부하고 로비를 매끄러운 형태로 재설계하도록 변경했습니다. 위 InstallOrbitalLobby 절차는 이전 Stud 디자인이므로 지금 다시 적용하지 마세요. 새 간판은 Rodeo Planeture입니다. assets/maps/SmoothLobby/SmoothLobbyDraft.rbxlx는 시스템 없는 독립 형태 초안이며 완성 맵이 아닙니다. 확인하려면 현재 게임 작업을 사본으로 저장하고 파일 → 파일 열기로 이 초안을 별도로 연 뒤 Explorer에서 Workspace → SmoothLobbyDesignDraft 선택, 화면 위에서 F를 누릅니다. 기존 게임 파일 교체/저장은 하지 않습니다. 실제 Studio 외관 확인과 추가 디자인 보완 후 연결합니다.
