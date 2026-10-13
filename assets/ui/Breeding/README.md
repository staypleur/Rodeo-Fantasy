# 우주 번식실 UI

배경 `Background.png`는 사용자 PNG의 원본 사본이다. 1448×1086 RGBA, SHA256 `1D1227BA85D7D013AC8AF7032211AF99E88DDDCACFA386E12D796192BAB532C7`.

## 구성

- `src/client/BreedingUI.luau`: ImageLabel 배경과 투명 ImageButton. 전체 화면을 하나의 UIScale로 확대/축소하므로 배경과 입력 영역이 함께 움직인다.
- 닫기, 암컷/수컷 슬롯, 교체(선택 해제), Breed, Guide. 하단은 10개 2D 초상화 슬롯을 재사용한다. 페이지 이동은 좌우 테두리, 페이지 번호는 슬롯 위 빈 띠에 표시한다.
- 보유 몬스터는 별레벨 내림차순으로 표시한다. 성별에 맞게 자동 배치하고 사용 중인 개체는 제외한다. 서버에 두 인벤토리 ID만 전송하며 소유권과 교배 조건은 기존 서버가 검사한다.
- 기존 교배는 짝 확인만 지원한다. 알 생성, 비용 차감, 교배서 드롭/해금 규칙을 추가하지 않았다. Guide에 준비 중인 상태를 안내한다.
- 배경 문구 Breeding/Breed/Guide는 이미지 자체에 있으므로 원본을 그대로 쓰는 동안 번역되지 않는다. 동적 안내는 한국어/영어다.

## Studio 설치

1. Creator Dashboard의 개발 아이템/이미지에서 `Background.png`를 업로드한다. 현재 체험에서 사용 가능한 **이미지 에셋 ID**를 확인한다.
2. Roblox Studio에서 로비 장소를 열고 테스트를 중지한다.
3. `dist/BreedingUI.commandbar.lua` 첫 설정 `local IMAGE_ID = ""`에 그 숫자를 입력한다.
4. Studio의 보기(View) 메뉴에서 명령 모음(Command Bar)을 열어 설치 파일 전체 내용을 실행한다.
5. Output에 `BREEDING_UI_INSTALLED`가 표시되는지 확인한다. 카페 장소에도 동일하게 설치한다.
6. Play에서 가방 → Breed를 열어 원본 배경, 암수 선택/해제, 닫기, Guide와 페이지 이동을 확인한다. Device Emulator에서 가로·세로 화면과 작은 휴대전화 화면을 확인한다.

설치기는 개인 편집과 충돌할 경우 중단하며 기존 모듈을 ServerStorage에 백업한다. 자동 게시하지 않는다. 현재 이미지 업로드·Studio 설치·기기 실행 검증은 미완료다.

## 검증

원본 파일 SHA256 일치 및 Luau 컴파일 통과. 슬롯은 1448×1086 원본 좌표를 사용한다. 실제 Roblox 렌더링·모바일 터치·PC 조작은 설치 후 검증해야 한다.
