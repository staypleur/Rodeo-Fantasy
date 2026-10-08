# 파이리 실험용 모델

`dist/Charmander.rbxmx`는 Roblox 기본 Part/Fire로 구성한 수정 가능한 모델입니다. 업로드된 메시나 텍스처 없이 열 수 있습니다.

사용자가 보낸 Roblox 펫 사진을 기준으로 블록 조립 형태와 표면 돌기, 큰 사각 눈, 몸보다 큰 머리, 짧은 팔다리와 계단식 꼬리를 만들었습니다. 주황색 두 다리 체형, 크림색 배와 꼬리 불꽃을 유지합니다. `tools/charmander_model.py`에서 형태와 색을 수정합니다.

`MountRoot`를 기준으로 전체가 이동하고 외형은 충돌하지 않습니다. 장소 파일의 `RideAnimator`가 두 다리 달리기/기울기/화난 몸 움직임을 계산합니다. 개별 모델 파일에는 실행 코드가 포함되지 않습니다. 다른 포켓몬과 진화형은 아직 제작하지 않았습니다.

`charmander-brick-preview.png`는 `tools/preview_charmander.py`가 실제 부품 데이터에서 만든 구조 미리보기입니다. Studio 스크린샷이 아니며 표면 돌기와 움직이는 Fire 효과는 표시하지 않습니다. 표면 돌기는 [Roblox SurfaceType 문서](https://create.roblox.com/docs/reference/engine/enums/SurfaceType)의 Studs 시각 표현을 사용하며 자동 접합에 의존하지 않습니다.
