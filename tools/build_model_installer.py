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
 code='''-- Install into RodeoFantasy-New only, in Edit mode. Input: MossratImport.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local map=assert(workspace:FindFirstChild("RodeoLobby"),"새 로비 없음")
assert(workspace:FindFirstChild("GreenStar") and map:FindFirstChild("Plots") and map:FindFirstChild("Airport"),"RodeoFantasy-New 맵을 먼저 여세요.")
local package=game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
assert(package and package:FindFirstChild("MonsterCatalog") and package:FindFirstChild("UserMossratRigData"),"ReplicatedStorage의 새 프로젝트 모듈이 없습니다.")
local clients=game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
assert(clients and clients:FindFirstChild("UserMossratRigAnimator"),"StarterPlayerScripts의 모스랫 애니메이션 모듈이 없습니다.")
local hasMossrat=workspace:FindFirstChild("MossratImport")~=nil
assert(hasMossrat,"가져온 모스랫 Model 이름을 MossratImport로 바꾸세요.")
'''
 code+='''if not map:FindFirstChild("SpaceLobbyDoors") then
 local doors=Instance.new("Script") doors.Name="SpaceLobbyDoors"
 doors.Source='''+long((R/'src/server/SpaceLobbyDoors.server.luau').read_text(encoding='utf-8'))+'''
 doors.Parent=map
 print("SPACE_LOBBY_DOORS_REPAIRED")
end
'''
 code+='if hasMossrat then local M=(function()\n'+installer+'\nend)() M.run({},{}) end\n'
 code+='''print("NEW_PROJECT_MODELS_INSTALLED — Ctrl+S로 저장하고 Play로 확인하세요.")
'''
 out=R/'dist/InstallModels.commandbar.lua';out.write_text(code,encoding='utf-8');print('NEW_MODEL_INSTALLER_BUILT')
if __name__=='__main__':build()
