# Fantasy Monster Rodeo

현재 게임은 **Fantasy Monster Rodeo**, 카페 장소는 **Fantasy Monster Cafe**이며 비공개 시험 중입니다.

- 실제 게시된 로비·카페에는 최신 모스랫 모델과 공통 UI가 연결되어 있습니다.
- Green Star 사냥터는 2,000m, 기존 최대 폭 안에서 변화하는 산·협곡 분기와 네모난 나무·바위 장애물을 사용합니다.
- 최신 확정 기획은 `GAME_DESIGN.md`, 게시·검사 기록은 `docs/WORK_LOG.md`를 확인합니다.
- `dist/RodeoFantasy-New.rbxlx`는 사용자 로컬 작업 파일입니다. 실제 게시된 장소와 동일 버전이라고 가정하지 않으며 임의로 덮어쓰지 않습니다.
- 모델 원본과 재생성 도구는 보존하고, 반려된 MountainV2 검토본과 생성기는 정리했습니다. 현재 코스 검토 자료는 `dist/CourseReview/SceneryV3`와 `VarietyV4`에 있습니다.

빌드 도구: `tools/build_project.py`. 실행 전에 로컬 파일의 모델과 변경 사항을 보존해야 합니다. 이전 시작 안내는 `docs/NEW_PROJECT.md`이며 최신 서비스 상태는 작업 기록을 우선합니다.

플레이어 DataStore 이름은 유지한다. 삭제 파일과 미커밋 작업의 로컬 복구 사본은 `.local-backup`에 보관하며 GitHub에 올리지 않는다. 코드 검사와 실제 Studio·모바일·PC 검증을 구분한다.
