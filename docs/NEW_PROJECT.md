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
