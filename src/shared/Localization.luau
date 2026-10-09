local L={}
L.entries={
 ["Ocean"]={ko="바다",ja="海"},
 ["Swamp"]={ko="늪지",ja="沼地"},
 ["Forest"]={ko="숲",ja="森"},
 ["Total caught"]={ko="총 포획",ja="総捕獲"},
 ["Caught"]={ko="포획 수",ja="捕獲数"},
 ["Found at"]={ko="발견 위치",ja="発見場所"},
 ["Taming (1 star)"]={ko="1성 길들이기",ja="1つ星の捕獲"},
 ["Seconds"]={ko="초",ja="秒"},
 ["Region not released yet"]={ko="아직 공개되지 않은 지역이에요",ja="まだ公開されていない地域です"},
 ["Male"]={ko="수컷",ja="オス"},
 ["Female"]={ko="암컷",ja="メス"},
 ["Unknown sex"]={ko="미확인",ja="不明"},
 ["Collection discoveries"]={ko="도감 수집 랭킹",ja="図鑑収集ランキング"},
 ["Settings"]={ko="설정",ja="設定"},
 ["Sound settings"]={ko="소리 설정",ja="サウンド設定"},
 ["Background music"]={ko="배경 음악",ja="背景音楽"},
 ["Sound effects"]={ko="효과음",ja="効果音"},
 ["Hunting continues while settings are open"]={ko="설정을 열어도 사냥은 계속 진행돼요",ja="設定中も狩りは続きます"},
 ["MeadowMouse"]={ko="모스랫",en="모스랫",ja="모스랫"},
 ["GrassBoar"]={ko="브램블보어",en="브램블보어",ja="브램블보어"},
 ["TreeWolf"]={ko="바인팽",en="바인팽",ja="바인팽"},
 ["RockElephant"]={ko="엘레바인",en="엘레바인",ja="엘레바인"},
 ["Farthest run"]={ko="최장 거리 랭킹",ja="最長距離ランキング"},
 ["Total produced"]={ko="누적 생산액 랭킹",ja="累計生産ランキング"},
 ["Loading records..."]={ko="기록 불러오는 중…",ja="記録を読み込み中…"},
 ["No records yet"]={ko="아직 기록이 없어요",ja="まだ記録がありません"},
 ["Publish to enable rankings"]={ko="게시 후 랭킹을 사용할 수 있어요",ja="公開後にランキングが使えます"},
 ["Records temporarily unavailable"]={ko="기록을 잠시 불러올 수 없어요",ja="記録を一時的に読み込めません"},
 ["Farthest run"]={ko="최장 거리 랭킹",ja="最長距離ランキング"},
 ["Total produced"]={ko="누적 생산액 랭킹",ja="累計生産ランキング"},
 ["No records yet"]={ko="아직 기록이 없어요",ja="まだ記録がありません"},
 ["Publish to enable rankings"]={ko="게시 후 랭킹을 사용할 수 있어요",ja="公開後にランキングが使えます"},
 ["Records temporarily unavailable"]={ko="기록을 잠시 불러올 수 없어요",ja="記録を一時的に読み込めません"},
 ["Manage ranch"]={ko="목장 관리",ja="牧場を管理"},
 ["Choose ranch"]={ko="관리할 목장 선택",ja="管理する牧場を選ぶ"},
 ["Weedcrow"]={ko="쏜크로",en="쏜크로",ja="쏜크로"},
 ["Monster tamed! Added to your bag."]={ko="길들이기 성공! 가방에 추가됐어요.",ja="仲間にしました！バッグに追加。"},
 ["Place monsters"]={ko="몬스터 배치",ja="モンスターを配置"},
 ["Ranch"]={ko="목장",ja="牧場"},
 ["Place"]={ko="배치",ja="配置"},
 ["Return to bag"]={ko="가방으로 돌려놓기",ja="バッグに戻す"},
 ["Placed"]={ko="배치됨",ja="配置済み"},
 ["Full"]={ko="가득 참",ja="満員"},
 ["This server holds up to 8 players."]={ko="이 서버는 8명까지 입장할 수 있어요.",ja="このサーバーは8人までです。"},
 ["Start hunt"]={ko="사냥 시작",ja="狩りを始める"},
 ["Hunt again"]={ko="다시 사냥하기",ja="もう一度狩る"},
 ["Return to lobby"]={ko="로비로 돌아가기",ja="ロビーに戻る"},
 ["Jump / Lasso"]={ko="점프 / 줄",ja="ジャンプ / ロープ"},
 ["Hunt ended"]={ko="사냥 종료",ja="狩り終了"},
 ["Next region coming soon"]={ko="다음 지역 준비 중",ja="次のエリアは準備中"},
 ["You hit an obstacle."]={ko="장애물에 부딪혔어요.",ja="障害物にぶつかりました。"},
 ["You missed the next monster."]={ko="다음 몬스터를 잡지 못했어요.",ja="次のモンスターをつかめませんでした。"},
 ["You lost your mount."]={ko="몬스터를 놓쳤어요.",ja="乗っていたモンスターを失いました。"},
 ["This monster cannot break crates."]={ko="상자를 부술 수 없는 몬스터예요.",ja="このモンスターは木箱を壊せません。"},
 ["You hit a wall."]={ko="벽에 부딪혔어요.",ja="壁にぶつかりました。"},
 ["You hit another monster."]={ko="다른 몬스터에 부딪혔어요.",ja="別のモンスターにぶつかりました。"},
 ["Welcome back to the lobby."]={ko="로비로 돌아왔어요.",ja="ロビーに戻りました。"},
 ["Approach the airship to start."]={ko="비행장에서 사냥터로 출발하세요.",ja="飛行船に近づくと出発します。"},
 ["Lumidon tamed! Added to your bag."]={ko="루미돈 길들이기 성공! 가방에 추가됐어요.",ja="ルミドンを仲間にしました！バッグに追加。"},
 ["Lumidon"]={ko="루미돈",ja="ルミドン"},
 ["Angry! Press Space to jump!"]={ko="화났어요! 스페이스바로 점프하세요!",ja="怒っています！スペースでジャンプ！"},
 ["Tamed · Keep riding"]={ko="길들이기 성공 · 계속 타고 달리세요",ja="仲間になった · そのまま走ろう"},
 ["Taming Lumidon ♥"]={ko="루미돈 길들이는 중 ♥",ja="ルミドンを仲間にしています ♥"},
 ["A/D to steer · Space to jump / again to lasso"]={ko="A·D로 좌우 이동 · 스페이스바로 점프 / 공중에서 다시 누르면 줄",ja="A/Dで左右 · スペースでジャンプ / 空中でもう一度ロープ"},
 ["Press Space to catch the next monster!"]={ko="스페이스바로 다음 몬스터를 잡으세요!",ja="スペースで次のモンスターをつかもう！"},
 ["Lasso a monster inside the yellow ring"]={ko="노란 원 안에 몬스터가 들어오면 줄이 연결됩니다",ja="黄色い輪の中のモンスターにロープを投げよう"},
 ["Flying to your next mount…"]={ko="날아가서 탑승하는 중…",ja="次のモンスターに飛び乗っています…"},
 ["Keep riding after landing"]={ko="탑승 후 계속 타고 달릴 수 있어요",ja="着地後も乗り続けられます"},
 ["1,000m · Next region coming soon"]={ko="1,000m · 다음 지역 준비 중",ja="1,000m · 次のエリアは準備中"},
 ["Meadow complete · Start again or return"]={ko="초원 시험 구간이 끝났어요 · 사냥 시작으로 다시 달릴 수 있어요",ja="草原クリア · 再挑戦またはロビーへ"},
 ["Try again · Your bag income is kept"]={ko="다시 사냥하기로 재도전 · 가방 수익은 유지",ja="再挑戦 · バッグの収入は残ります"},
 ["Bag"]={ko="가방",ja="バッグ"},
 ["Close"]={ko="닫기",ja="閉じる"},
 ["No monsters caught yet"]={ko="아직 포획한 몬스터가 없어요",ja="まだモンスターがいません"},
 ["Uncollected coins"]={ko="모인 돈",ja="未受取コイン"},
 ["Shop · Coming soon"]={ko="상점 · 준비 중",ja="ショップ · 準備中"},
 ["Hunting grounds"]={ko="사냥터",ja="狩りエリア"},
 ["Airship"]={ko="비행선",ja="飛行船"},
 ["Fly to hunt"]={ko="사냥터로 출발",ja="狩りに出発"},
 ["All"]={ko="전체",ja="すべて"},
 ["Meadow"]={ko="초원",ja="草原"},
 ["Breeding"]={ko="배합",ja="交配"},
 ["Search monsters"]={ko="몬스터 검색",ja="モンスターを検索"},
 ["No matching monsters"]={ko="검색 결과가 없어요",ja="該当するモンスターがいません"},
 ["Field journal"]={ko="몬스터 도감",ja="モンスター図鑑"},
 ["Explorer's field journal"]={ko="탐험가의 몬스터 도감",ja="探検家のモンスター図鑑"},
 ["Discovered"]={ko="발견",ja="発見"},
 ["Hover an entry for field notes"]={ko="몬스터에 커서를 올리면 획득 방법을 볼 수 있어요",ja="モンスターにカーソルを合わせると入手方法を表示"},
 ["No entries here yet"]={ko="아직 등록된 몬스터가 없는 분류예요",ja="この分類にはまだ項目がありません"},
 ["Breeding details not announced yet"]={ko="배합 방법은 아직 공개되지 않았어요",ja="交配方法はまだ公開されていません"},
 ["Evolve"]={ko="진화",ja="進化",en="Evolve"},
 ["Cancel"]={ko="취소",ja="キャンセル",en="Cancel"},
 ["Select"]={ko="선택",ja="選択",en="Select"},
 ["Selected"]={ko="선택됨",ja="選択済み",en="Selected"},
 ["Select three matching monsters"]={ko="같은 종류·같은 별 3마리를 선택하세요",ja="同種・同じ星の3匹を選んでください",en="Select three matching monsters"},
 ["Evolution failed"]={ko="진화할 수 없어요. 가방을 새로 확인해 주세요.",ja="進化できません。バッグを確認してください。",en="Evolution failed. Refresh your bag and try again."},
 ["Already at max stars"]={ko="10성이 된 몬스터는 더 진화할 수 없어요.",ja="10星のモンスターは進化できません。",en="A 10-star monster cannot evolve further."},
 ["Loading progress"]={ko="기록을 불러오는 중",ja="記録を読み込み中"},
 ["Progress saved"]={ko="기록 저장됨",ja="記録を保存済み"},
 ["Progress loaded"]={ko="기록 불러옴",ja="記録を読み込み済み"},
 ["Session progress"]={ko="이번 접속의 기록",ja="今回の記録"},
 ["Progress temporarily unavailable"]={ko="기록 저장 연결을 기다리는 중",ja="記録の接続待ち"},
}
function L.text(source,locale)
 local lang=string.lower(string.sub(locale or "en",1,2))
 local row=L.entries[source]
 return row and (row[lang] or row.en) or source
end
function L.stats(count,money,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "가방: %d마리 · 모인 돈: %d" or lang=="ja" and "バッグ: %d匹 · 未受取コイン: %d" or "Bag: %d · Uncollected coins: %d"
 return string.format(pattern,count,money)
end
function L.income(amount,seconds,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "%s초마다 %s코인" or lang=="ja" and "%s秒ごとに%sコイン" or (amount==1 and "%s coin every %ss" or "%s coins every %ss")
 if lang=="ko" or lang=="ja" then return string.format(pattern,tostring(seconds),tostring(amount)) end
 return string.format(pattern,tostring(amount),tostring(seconds))
end
function L.levelLabel(level,current,required,locale)
 local lang=string.sub(locale or "en",1,2)
 local name=lang=="ko" and "레벨" or lang=="ja" and "レベル" or "Lv."
 return name.." "..level..(required==0 and " · MAX" or " · "..current.."/"..required.." XP")
end
function L.huntHint(meters,seconds,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "초원 %dm부터 등장. 점프 후 다시 Space로 줄을 던지고 %d초 동안 타세요." or lang=="ja" and "草原%dmから出現。ジャンプ後Spaceで投げ縄を使い、%d秒乗り続けよう。" or "Found in the meadow from %dm. Jump, press Space again to lasso, then ride for %ds."
 return string.format(pattern,meters,seconds)
end
function L.evolutionHint(stars,locale)
 local lang=string.sub(locale or "en",1,2)
 local pattern=lang=="ko" and "가방에서 같은 종류·같은 별 3마리를 선택해 %d성으로 진화시키세요." or lang=="ja" and "バッグで同種・同じ星の3匹を選び、%d星に進化させよう。" or "Select three of the same species and star in your bag to evolve to %d stars."
 return string.format(pattern,stars)
end
return L
