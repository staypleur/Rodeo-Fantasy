# Rodeo Fantasy — 새 프로젝트

이제 **`dist/RodeoFantasy-New.rbxlx` 하나만** Roblox Studio에서 연다. 옛 맵·몬스터·비행선·중복 적용 파일은 정리했다.

- 로비: Stud 우주선, 부화실8개/알자리32개/자동문, 상점2곳/랭킹2곳/룰렛/배틀패스 자리.
- 사냥터: Green Star 숲1,000m/폭192studs, 얇은 판 나무·바위/절벽/폭포/바람. 개인 사냥과 기존 이동·점프·줄 조작 유지.
- 모델: 사용자 모스랫1성/로켓만 준비. Roblox 업로드는 아직 미완료이며 옛 모델로 대체하지 않는다.
- 가방·도감·교감·거래·저장과 카페 시스템 유지. 옛 카페 맵은 삭제했고 새 맵 제작 때 실행을 연결한다.

**실행·모델 연결·성공 확인:** [새 프로젝트 안내](docs/NEW_PROJECT.md).

빌드: `tools/build_project.py`. 모델 설치 파일 생성: `tools/build_model_installer.py`. 가져오기 묶음: `tools/prepare_import_recovery.py`. 검사: `tests/check_new_project.py`, `tests/check_user_mossrat_rig.py`.

플레이어 DataStore 이름은 유지한다. 삭제 파일과 미커밋 작업의 로컬 복구 사본은 `.local-backup`에 보관하며 GitHub에 올리지 않는다. 코드 검사와 실제 Studio·모바일·PC 검증을 구분한다.
