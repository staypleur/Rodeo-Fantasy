# Meshy 모스랫 1성 설치

코드·게임용 GLB는 준비되어 있습니다. Roblox 메시/텍스처 자산 ID는 Studio에서 가져오기 후 생성되므로, 아래 가져오기를 한 번 해야 새 외형이 표시됩니다. 아직 실제 Studio 실행·모바일/PC FPS 검증은 하지 않았습니다.

## 파일과 용도

- `assets/meshes/meshy/Mossrat_S1_Source.glb`: 사용자가 승인한 Meshy Remesh 3k 원본. 3,114삼각형, 변경 없이 보관합니다.
- `assets/meshes/meshy/Mossrat_S1_Hunt.glb`: 사냥터용 3,114삼각형/1개 MeshPart, 1MB 미만. 형상·법선·UV를 그대로 유지하고 색/재질 텍스처만512로 줄였습니다.
- `assets/meshes/meshy/Mossrat_S1_Detail.glb`: 가방·도감 및 미래 카페의 기준. 같은3,114삼각형/1개 MeshPart, 원본2048색/4096재질 텍스처를 그대로 보존합니다. 카페는 아직 제작하지 않았습니다.
- 별도 재메시/텍스처 재굽기를 하지 않습니다. 게임 정면 방향에 맞게 Y축180도만 회전합니다. 이전115만삼각형 파일을 실행에 사용하지 않습니다.
- 1성 오라 없음. 전체 높이2.5스터드(발바닥~귀/장식 꼭대기)는 표준5스터드 캐릭터의 허리 높이를 기준으로 합니다. 사용자 아바타와의 정확한 비교는 Studio에서 확인합니다.
- 리깅 없는 정적 메시입니다. 기존 이동·기울기·몸 전체 흔들림을 연결하지만 개별 다리 걷기 애니메이션은 포함하지 않습니다.

## 클릭 순서

1. Roblox Studio에서 재생 중이면 **정지**합니다. **Ctrl+O**로 `dist/LocalOperator/RodeoFantasy-MeshyMossrat-Operator.rbxlx`를 엽니다. 이는 기존 로컬 운영자 설정을 유지한 준비 파일입니다. 이 파일이 없는 환경에서는 `dist/RodeoFantasy-MeshyMossrat.rbxlx`를 사용합니다.
2. **파일(File) → 가져오기(Import)**로 `assets/meshes/meshy/Mossrat_S1_Hunt.glb`를 선택합니다. 이름을 **Mossrat_S1_Hunt**로 지정하고 **Upload to Roblox**, **Add to Workspace**, **Anchored**를 켭니다. **Merge Meshes**는 끕니다. 정면 축은 **Front**, 위쪽은 **Top**으로 둔 뒤 **Import**를 누릅니다.
3. 같은 방법으로 `Mossrat_S1_Detail.glb`도 가져오고 이름을 **Mossrat_S1_Detail**로 지정합니다. **Merge Meshes**는 끕니다. 가져오기 화면에서 얼굴과 색이 보이는지 확인합니다.
4. Studio의 **명령 표시줄(Command Bar)**에 아래 한 줄을 붙여 넣고 Enter를 누릅니다. 명령 표시줄이 없으면 **보기(View)** 메뉴에서 켭니다. 이 코드는 게임 채팅의 운영자 명령어가 아니라 Studio 편집용 설치 코드입니다.

```lua
require(game.ReplicatedStorage.RodeoFantasy.MeshyMossratInstaller).install(workspace:FindFirstChild("Mossrat_S1_Hunt"),workspace:FindFirstChild("Mossrat_S1_Detail"))
```

5. **출력(Output)**에 `모스랫 1성 설치 완료`가 표시되면 **Ctrl+S**로 저장합니다. 가져온 두 전시용 오브젝트는 Workspace에서 지워도 됩니다. 설치된 서버/클라이언트 템플릿은 별도 복사본입니다.
6. **Play**로 사냥터에 들어가 경량 모스랫이 표시되는지, 재사냥 후에도 색이 유지되는지 확인합니다. 가방·도감에서 상세 모델이 표시되는지, 미발견 실루엣이 검은색인지 확인합니다. 탑승 위치와 발 접지는 실제 플레이에서 확인합니다.

Roblox 공식 가져오기 안내: https://create.roblox.com/docs/studio/importer

카페는 현재 제작하지 않습니다. 사용자 원본 GLB도 Downloads에서 수정하지 않았습니다. 이 준비 파일을 여는 것만으로 자산 업로드가 완료된 것은 아닙니다.

10k 교체용 원본은 `assets/meshes/meshy/Mossrat_S1_Source10k.glb`에 보관했습니다. 사용자 게임 검토 후 교체합니다.
