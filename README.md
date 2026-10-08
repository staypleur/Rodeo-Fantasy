# Rodeo Fantasy

Roblox에서 실행하는 포켓몬 사냥·수집 게임입니다. 사냥터는 로데오 스탬피드의 연속 달리기, 점프, 줄 던지기, 갈아타기, 오래 타서 길들이기 흐름을 따릅니다.

첫 실험용 포켓몬은 파이리입니다. Roblox 기본 부품으로 제작한 주황색 몸, 크림색 배, 두 다리, 불꽃 꼬리 모델을 사용합니다. 협곡 길의 파이리 무리와 바위가 등장하며 달리다가 손을 떼어 점프하고 다시 눌러 줄로 잡습니다. 색깔 판정 막대는 제거했습니다.

[Studio 적용 방법](docs/STUDIO_SETUP.md) · [기획](GAME_DESIGN.md) · [검증](docs/VALIDATION.md) · [작업 기록](docs/WORK_LOG.md) · [영상/공식 참고](docs/VIDEO_REFERENCES.md)

## 파일

- `dist/RodeoFantasy-Capture.rbxlx`: 코드와 파이리 모델이 들어 있는 테스트 장소
- `dist/Charmander.rbxmx`: 다른 장소에 삽입할 수 있는 외형만 포함한 파이리 모델
- `src/server/CaptureServer.server.luau`: 사냥 상태, 서버 판정, 길들이기, 가방 수익
- `src/server/HuntWorld.luau`: 달리는 무리, 협곡/장애물, 충돌 검사와 먼 구간 정리
- `src/shared/HuntRules.luau`: 점프 높이, 진행률, 범위와 이동 중 충돌 계산
- `src/shared/BagRules.luau`: 가방 개체와 접속 중 수익 계산
- `src/client/CaptureClient.client.luau`: 마우스/터치/A·D, 카메라, 줄 범위와 안내
- `src/client/RideAnimator.luau`: 두 다리 달리기와 화났을 때 몸 움직임
- `tools/charmander_model.py`: 수정 가능한 파이리 모델 부품
- `tools/build_place.py`: Python 표준 라이브러리로 장소/모델 생성

## 현재 범위

파이리 한 종류로 연속 사냥의 핵심 흐름을 구현하는 실험입니다. 원작의 모든 종류·지형·능력이 재현된 완성판은 아닙니다. 공식 자료에 공개되지 않은 정확한 시간/속도는 시험용 조정값으로 구분했습니다.

가방 수익은 전시/소환 없이 계산하며 이번 접속에서만 유지됩니다. 다시 사냥하기는 가방을 유지하지만 Studio Stop 후 Play는 초기화합니다. 펫 소환/동행, 직접 수령 조작, 결제, 진화와 영구 저장은 아직 구현하지 않았습니다.
