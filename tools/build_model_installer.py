"""One model installer for the new project; no patching legacy game scripts."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
def long(s):return '[====['+s+']====]'
def build():
 g=json.loads((R/'assets/models/MossratS1UserRig/MossratS1Rigged.gltf').read_text())
 parents={child:i for i,node in enumerate(g['nodes']) for child in node.get('children',[])}
 hierarchy='{'+','.join('['+json.dumps(g['nodes'][j]['name'])+']='+json.dumps(g['nodes'][parents[j]]['name'] if j in parents else '') for j in g['skins'][0]['joints'])+'}'
 installer=(R/'src/authoring/UserMossratInstaller.luau').read_text(encoding='utf-8').replace('__BONE_HIERARCHY__',hierarchy)
 code='''-- Install into RodeoFantasy-New only, in Edit mode. Inputs: MossratImport / RocketImport.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local map=assert(workspace:FindFirstChild("RodeoLobby"),"새 로비 없음")
assert(workspace:FindFirstChild("GreenStar") and map:FindFirstChild("Plots") and map:FindFirstChild("Airport"),"RodeoFantasy-New 맵을 먼저 여세요.")
local package=game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
assert(package and package:FindFirstChild("MonsterCatalog") and package:FindFirstChild("UserMossratRigData"),"ReplicatedStorage의 새 프로젝트 모듈이 없습니다.")
local clients=game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
assert(clients and clients:FindFirstChild("UserMossratRigAnimator"),"StarterPlayerScripts의 모스랫 애니메이션 모듈이 없습니다.")
local hasMossrat=workspace:FindFirstChild("MossratImport")~=nil
local hasRocket=workspace:FindFirstChild("RocketImport")~=nil
assert(hasMossrat or hasRocket,"가져온 전체 Model 이름을 MossratImport 또는 RocketImport로 바꾸세요.")
'''
 code+='''if not map:FindFirstChild("SpaceLobbyDoors") then
 local doors=Instance.new("Script") doors.Name="SpaceLobbyDoors"
 doors.Source='''+long((R/'src/server/SpaceLobbyDoors.server.luau').read_text(encoding='utf-8'))+'''
 doors.Parent=map
 print("SPACE_LOBBY_DOORS_REPAIRED")
end
'''
 code+='if hasMossrat then local M=(function()\n'+installer+'\nend)() M.run({},{}) end\n'
 code+='''if hasRocket then
 local source=workspace.RocketImport
 assert(source:IsA("Model"),"RocketImport는 전체 Model이어야 합니다.")
 local count=0
 for _,n in ipairs(source:GetDescendants()) do
  assert(not n:IsA("LuaSourceContainer"),"입력 로켓에 스크립트를 넣지 마세요.")
  if n:IsA("MeshPart") then assert(n.MeshId~="","로켓 메시 업로드 필요") count+=1 end
 end
 assert(count>0,"로켓 MeshPart 없음")
 local airport=map.Airport local old=airport:FindFirstChild("Rocket")
 local copy=assert(source:Clone(),"로켓 복제 실패") copy.Name="Rocket"
 copy:PivotTo(copy:GetPivot()*CFrame.Angles(0,math.pi,0))
 local box,size=copy:GetBoundingBox() assert(size.Y>0,"로켓 높이 오류")
 copy:ScaleTo(copy:GetScale()*(18/.28)/size.Y)
 box,size=copy:GetBoundingBox()
 copy:PivotTo(CFrame.new(Vector3.new(6000,8+size.Y/2,0)-box.Position)*copy:GetPivot())
 for _,p in ipairs(copy:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end end
 copy:SetAttribute("UserRocketDepartureV1",true)
 copy:SetAttribute("UserRocketSourceSha256","458fe773d5b29cf4b90979d8990334dad62344c3ed917b729cad7a387e1f91a8")
 local backup=Instance.new("Folder") backup.Name="RocketImportBackup_"..game:GetService("HttpService"):GenerateGUID(false)
 backup.Parent=game:GetService("ServerStorage")
 local ok,err=pcall(function() if old then old.Parent=backup end copy.Parent=airport source.Parent=backup end)
 if not ok then copy:Destroy() if old then old.Parent=airport end source.Parent=workspace backup:Destroy() error(err) end
 local pending=airport:FindFirstChild("RocketModelPending") if pending then pending.Parent=backup end
 print("NEW_ROCKET_INSTALLED")
end
print("NEW_PROJECT_MODELS_INSTALLED — Ctrl+S로 저장하고 Play로 확인하세요.")
'''
 out=R/'dist/InstallModels.commandbar.lua';out.write_text(code,encoding='utf-8');print('NEW_MODEL_INSTALLER_BUILT')
if __name__=='__main__':build()
