# 루미돈 — 독자 몬스터 모델

사용자가 선택한 **등에 작은 등불이 달린 블록 아기멧돼지**입니다. 네 다리, 큰 눈, 짧은 말린 꼬리, 등불로 구성합니다. 외부 캐릭터의 모델이나 텍스처를 재사용하지 않습니다.

`dist/Lumidon.rbxmx`는 Roblox 기본 Part와 PointLight로 구성한 수정 가능한 모델입니다. 몸의 표면 돌기와 빛나는 등불을 포함합니다. `tools/lumidon_model.py`에서 46개 외형 부품을 생성하며 `MountRoot`는 이동 기준인 투명 부품입니다. 개별 모델에 실행 코드는 없습니다.

장소의 `RideAnimator`는 앞·뒤 네 다리의 달리기와 몸 기울기를 계산합니다. 외형 부품은 충돌하지 않으며 실제 사냥 판정은 서버가 처리합니다.

`lumidon-brick-preview.png`는 실제 부품 데이터에서 만든 구조 미리보기입니다. Studio 스크린샷이 아니며 표면 돌기와 빛 효과는 표시하지 않습니다. [Roblox SurfaceType](https://create.roblox.com/docs/reference/engine/enums/SurfaceType)의 Studs는 시각 표현에 사용하며 자동 접합에 의존하지 않습니다.
