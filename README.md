# Rodeo Fantasy

귀여운 독자 몬스터를 포획해 카페에서 펫으로 데리고 다니고, 가방에 보유한 몬스터가 돈을 생산하는 Roblox 게임입니다. 게임은 카페와 사냥터 두 공간으로 나눕니다. 지금은 사냥터부터 개발합니다.

사냥은 Rodeo Stampede의 자동 전진 → 누른 채 좌우 이동 → 손을 떼어 점프 → 다시 눌러 줄로 갈아타기 → 오래 타서 길들이기 흐름을 참고합니다. 외부 게임의 자산과 캐릭터는 사용하지 않습니다.

첫 시험 몬스터는 **루미돈**입니다. 등에 작은 등불이 달린 귀여운 블록 아기멧돼지로 사용자가 선택한 독자 디자인입니다.

[Studio 적용](docs/STUDIO_SETUP.md) · [전체 기획](GAME_DESIGN.md) · [검증](docs/VALIDATION.md) · [작업 기록](docs/WORK_LOG.md) · [참고 조사](docs/VIDEO_REFERENCES.md)

## 실행 파일

- `dist/RodeoFantasy-Capture.rbxlx`: 코드와 루미돈이 포함된 사냥터 시험 장소
- `dist/Lumidon.rbxmx`: 다른 장소에 삽입할 수 있는 루미돈 외형 모델
- `assets/models/lumidon-brick-preview.png`: 실제 모델 부품에서 만든 구조 미리보기. Studio 스크린샷은 아닙니다.
- `tools/build_place.py`: 장소와 모델 생성
- `tools/lumidon_model.py`: 루미돈 부품 설계
- `tools/preview_lumidon.py`: 구조 미리보기 생성

## 현재 상태

첫 몬스터로 날아가 탑승, 같은 개체로 연속 주행, 달리는 무리, 장애물, 길 중심의 사선 카메라, 점프/줄/갈아타기, 착지 보호, 길들이기, 느낌표와 화남/종료/재시작과 접속 중 가방 수익을 시험할 수 있습니다. 카페와 두 공간 연결, 펫 동행, 영구 저장, 음성 채팅 설정, 합성/진화와 상점은 아직 구현하지 않았습니다. 이름이나 외형 변경만으로 비침해를 보장한다고 주장하지 않습니다.
