# 초원 A 몬스터 모델을 Roblox에 반영하기

`dist/CreatureModels`에는 초원 5종의 1·3·6·9성 A 디자인을 각각 담은 20개 GLB가 있습니다. 각 GLB는 재질과 부품 이름을 가진 3D 메시이며, 날개·귀·다리·꼬리 애니메이션 부품을 구분합니다. 현재 3D Importer로 업로드해 게임 템플릿에 연결하는 절차가 필요합니다.

## Studio에서 가져오기

1. Roblox Studio에서 기존 시험을 중지하고 `Ctrl+O`를 누릅니다. 프로젝트의 `dist/RodeoFantasy-Capture.rbxlx`를 엽니다.
2. Studio의 **File → Import**에서 `dist/CreatureModels` 폴더를 엽니다. 20개 `.glb` 파일을 모두 선택해 가져옵니다.
3. 업로드 옵션을 켜고, 이 경험을 소유한 계정 또는 그룹을 Creator로 선택합니다. 실제 게임에서 메시를 보려면 모델이 경험에 업로드되어 있어야 합니다. 가져오기 미리보기에서 이름·색·경고를 확인하고 Import를 누릅니다.
4. 가져온 20개 Model을 Workspace 아래 `ImportedCreatureModels`라는 Folder 하나에 모읍니다. 가져온 Model 이름은 파일명과 같아야 합니다. 예: `MeadowMouse_A_S1`.
5. 저장소의 `tools/install_imported_models.commandbar.lua` 파일을 열어 전체 내용을 복사합니다. Studio에서 **View → Command Bar**를 열고 붙여 넣어 실행합니다. 성공하면 Output에 `Installed all 20 A-family models...`가 나옵니다. 이름 누락이나 MeshPart 이름 변경이 있으면 스크립트가 기존 모델을 건드리기 전에 멈춥니다.
6. `Ctrl+S`로 장소를 저장하고 F5를 눌러 사냥터, 가방, 도감, 목장에 모델이 나오는지 확인합니다.
7. 게시된 게임을 바꾸려면 확인 후 **File → Publish to Roblox**로 현재 경험에 게시합니다. 저장소의 파일을 커밋하거나 푸시하는 것만으로 이미 게시된 Roblox 게임이 바뀌지는 않습니다.

## 왜 Studio 작업이 필요한가요?

Roblox는 `.obj`, `.fbx`, `.gltf/.glb`를 3D Importer로 가져와 `MeshPart`로 사용합니다. GLB 파일은 저장소에만 존재한다고 게임이 자동으로 읽지 않습니다. Importer에서 업로드한 MeshPart를 장소의 ReplicatedStorage/ServerStorage 모델 템플릿에 연결해야 하므로 설치 스크립트가 그 연결을 처리합니다. [3D Importer 공식 안내](https://create.roblox.com/docs/studio/importer)

이 20개는 승인된 A 시안을 바탕으로 만든 로우폴리 3D 해석입니다. 한 장의 콘셉트 그림에서 보이지 않는 등 쪽 형태와 일부 구조를 보완해 모델링하므로 픽셀 단위로 동일한 자동 변환은 아닙니다. 날개·귀·다리·꼬리는 별도 메시로 남겨 달리기와 날갯짓에 사용할 수 있게 했습니다.

## 로비 반영

`dist/RodeoFantasy-Capture.rbxlx`에는 A안 석조 정원 로비(8개 건물, 안뜰마다 목장 4개, 중앙 바닥 로고, 바다코끼리 비행선)가 들어 있습니다. 현재 Roblox에 게시된 경험은 별도로 Studio에서 위 장소를 열어 저장하고 게시해야 바뀝니다. 실제 F5 화면과 게시된 게임의 최종 확인은 게시 계정에서 해야 합니다.
