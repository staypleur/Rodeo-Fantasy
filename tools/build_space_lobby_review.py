"""Standalone Studio review and cutaway images from the exact Luau geometry."""
from pathlib import Path
import subprocess, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from native_part_review import save_review
ROOT=Path(__file__).resolve().parents[1]
layout=(ROOT/'src/authoring/SpaceLobbyLayout.luau').read_text(encoding='utf-8')
source=(ROOT/'src/authoring/SpaceLobbyReview.luau').read_text(encoding='utf-8')
source=source.replace('local Layout=require(script.Parent.SpaceLobbyLayout)','local Layout=(function()\n'+layout+'\nend)()')
doors=(ROOT/'src/authoring/SpaceLobbyDoors.server.luau').read_text(encoding='utf-8')
bundle='-- Empty Studio place only; design review, no game installation.\nlocal Review=(function()\n'+source+'\nend)()\n'
bundle+='game:GetService("ChangeHistoryService"):SetWaypoint("Before spaceship lobby review")\n'
bundle+='local model=Review.create(workspace,game:GetService("ServerStorage"),Vector3.new(0,8,0))\n'
bundle+='local doors=Instance.new("Script") doors.Name="ReviewAutomaticDoors" doors.Source='+('[==['+doors+']==]')+' doors.Parent=model\n'
bundle+='local spawn=Instance.new("SpawnLocation") spawn.Name="ReviewSpawn" spawn.Size=Vector3.new(8,1,8) spawn.CFrame=CFrame.new(0,9,-52) spawn.Anchored=true spawn.CanCollide=false spawn.Transparency=1 spawn.Neutral=true spawn.Duration=0 spawn.Parent=model\n'
bundle+='game:GetService("Selection"):Set({model.Dock.DockTop})\n'
bundle+='game:GetService("ChangeHistoryService"):SetWaypoint("After spaceship lobby review")\n'
bundle+='print("SPACE_LOBBY_REVIEW_CREATED", "8 rooms / 32 egg slots; rocket model pending; game inventory not connected")\n'
(ROOT/'dist/ReviewModels/CreateSpaceLobby.commandbar.lua').write_text(bundle,encoding='utf-8')
harness=ROOT/'.tools/export_space_lobby.luau'
harness.write_text('local L=(function()\n'+layout+'\nend)()\n'+'''
for _,b in ipairs(L.build()) do
 local cells={b.name,b.group,tostring(b.yaw)}
 for _,values in ipairs({b.pos,b.size,b.color}) do for _,v in ipairs(values) do table.insert(cells,tostring(v)) end end
 print(table.concat(cells,"|"))
end
''',encoding='utf-8')
out=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(harness.relative_to(ROOT))],cwd=ROOT,check=True,capture_output=True,text=True)
blocks=[]
for row in out.stdout.splitlines():
 c=row.split('|');v=list(map(float,c[2:]));blocks.append(dict(name=c[0],group=c[1],yaw=v[0],pos=v[1:4],size=v[4:7],color=list(map(int,v[7:10]))))
folder=ROOT/'assets/courses/SpaceLobby';folder.mkdir(parents=True,exist_ok=True)
(folder/'layout.json').write_text(json.dumps(dict(reviewOnly=True,rooms=8,eggSlots=32,departureFacility='Rocket',rocketModelPending=True,blocks=blocks),indent=2),encoding='utf-8')
def parts(selection):
 result=[]
 for b in selection:
  a=np.radians(b['yaw']);matrix=np.array(((np.cos(a),0,np.sin(a)),(0,1,0),(-np.sin(a),0,np.cos(a))))
  result.append((b['name'],np.array(b['pos']),np.array(b['size']),tuple(b['color']),matrix))
 return result
cutaway=[b for b in blocks if b['group'] not in ('Roof','Hull') and b['name'] not in ('Ceiling','DoorSensor')]
save_review(parts(cutaway),'SpaceLobbyCutaway','우주선 로비 — 8인 부화실과 중앙 출발 광장',
            '지붕·선체를 숨긴 실제 형상 검토 · 중앙 로켓 모델 대기 · Stud는 Studio에서 확인',eye_direction=(.4,1.8,1.1),export_model=False)
room=[dict(b) for b in blocks if b['group']=='Room_1' and b['name'] not in ('Ceiling','DoorSensor','BackWall','SideWall')]
for b in room:
 if b['name'] in ('DoorLeft','DoorRight'):
  b['pos']=list(b['pos']);b['pos'][0]+=-16 if b['name']=='DoorLeft' else 16
save_review(parts(room),'SpaceLobbyIncubatorRoom','개인 부화실 — 자동문과 알 전용 부화소 4칸',
            '문이 열린 상태의 형상 검토 · 일부 벽·천장 생략 · 실제 알·부화 시간 미연결',eye_direction=(.4,1.6,-1.2),export_model=False)
im=Image.new('RGB',(1100,1100),(19,29,44));draw=ImageDraw.Draw(im)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',24);small=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',18)
draw.text((30,22),'우주선 로비 · 8인 / 개인 부화소 총 32칸',font=font,fill=(224,234,230))
draw.text((30,62),'중앙 로켓 → E 길게 → Green Star → 보유 몬스터 선택 → 출발',font=small,fill=(109,208,204))
scale=2;ox=550;oy=600
for b in blocks:
 if b['name'] not in ('Deck','RoomDeck','DockBase','DockTop','EggSocket_1','EggSocket_2','EggSocket_3','EggSocket_4','DoorLeft','DoorRight','StationCounter'):continue
 a=np.radians(b['yaw']);c=np.cos(a);s=np.sin(a);x,_,z=b['pos'];sx,_,sz=b['size']
 corners=[(ox+(x+dx*c+dz*s)*scale,oy+(z-dx*s+dz*c)*scale) for dx,dz in ((-sx/2,-sz/2),(sx/2,-sz/2),(sx/2,sz/2),(-sx/2,sz/2))]
 draw.polygon(corners,fill=tuple(b['color']))
for slot in range(1,9):
 a=np.radians((slot-1)*45);x=ox+np.sin(a)*160*scale;z=oy+np.cos(a)*160*scale
 draw.text((x-27,z-48),f'{slot}번',font=small,fill=(30,45,59))
draw.text((ox-20,oy-20),'로켓',font=small,fill=(238,243,228))
labels={'Shop_1':'상점1','Shop_2':'상점2','DistanceRanking':'거리 랭킹','JournalRanking':'도감 랭킹','Roulette':'룰렛','BattlePass':'배틀패스'}
for b in blocks:
 if b['name']=='StationCounter':
  x,_,z=b['pos'];draw.text((ox+x*scale-35,oy+z*scale-27),labels[b['group']],font=small,fill=(240,234,217))
im.save(ROOT/'assets/previews/SpaceLobbyPlan.png')
print('SPACE_LOBBY_EXPORT:',len(blocks),'Plastic blocks; 8 rooms, 32 sockets; cutaway/room/plan images')
