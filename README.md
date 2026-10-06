# Rodeo Fantasy

Roblox에서 만드는 몬스터 포획 및 편성 전투 게임입니다.

몬스터를 타고 이동하며 포획하고, 포획한 몬스터 8마리의 배치와 시너지를 조합해 PvP 전투를 진행하는 게임을 기획하고 있습니다.

## 프로젝트 문서
- [게임 기획](GAME_DESIGN.md): 기존 기획과 추후 확정할 세부 규칙
- [작업 원칙](AGENTS.md): 개발 진행 방식과 초보자를 위한 적용 안내 원칙
- [작업 기록](docs/WORK_LOG.md): 변경 내역과 검증 결과
- [첫 테스트 적용 방법](docs/STUDIO_SETUP.md): Studio에서 열고 포획을 테스트하는 순서
- [검증 기록](docs/VALIDATION.md): 자동 검사와 실제 플레이 확인 항목

## 현재 상태
앰버랫 탑승·포획 기능의 첫 프로토타입입니다. [Studio 테스트 파일](dist/RodeoFantasy-Capture.rbxlx)을 열어 사용할 수 있습니다.

범위 내 클릭 → 줄 던지기와 3m 이내 점프 → 자동 전진과 A/D 이동 → 탑승 3초 후 포획 미니게임을 구현했습니다. 성공하면 이번 접속의 포획 수가 증가합니다.

노란색 판정 후에도 미니게임은 5초 동안 계속됩니다. 다시 노란색을 맞혀도 남은 시간이 초기화되지 않으며, 흰색은 낙하, 주황색은 즉시 포획입니다.

앰버랫 외형은 미정이므로 이름표가 있는 회색 블록을 사용합니다. 전투·진화·영구 저장은 아직 구현하지 않았습니다. 이동/막대 속도는 테스트 조정값이며 최종 게임 규칙이 아닙니다.

## 개발 파일
- `src/shared/Config.luau`: 확정된 앰버랫 정보, 포획 규칙, 테스트 조정값
- `src/shared/CaptureRules.luau`: 거리와 미니게임 판정 계산
- `src/server/CaptureServer.server.luau`: 서버의 탑승·포획 처리
- `src/client/CaptureClient.client.luau`: 입력, 카메라, 한국어 안내 화면
- `tools/build_place.py`: 소스를 포함한 Studio 파일 생성 (Python 표준 라이브러리 사용)

코드 변경 후 `python tools/build_place.py`를 실행하면 테스트 파일을 갱신합니다. 사용자는 별도 플러그인 설치나 코드 복사 없이 생성된 파일을 열면 됩니다.
