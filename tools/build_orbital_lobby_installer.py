"""One edit-mode map update, preserving the user's uploaded creatures and textures."""
from pathlib import Path
import json,xml.etree.ElementTree as E,subprocess
R=Path(__file__).resolve().parents[1]
def long(s):return '[========['+s+']========]'
def build():
 root=E.parse(R/'assets/maps/SpaceLobby.rbxmx').getroot().find('Item')
 rows=[]
 def walk(item,parent):
  index=len(rows)+1;properties={}
  for p in item.find('Properties'):
   if p.tag in ('string','bool','float','token'):v=p.text or '';v=(v=='true') if p.tag=='bool' else float(v) if p.tag in ('float','token') else v
   elif p.tag in ('Vector3','Color3','CoordinateFrame','UDim2'):v=[float(n.text) for n in p]
   else:raise AssertionError(p.tag)
   properties[p.get('name')]=[p.tag,v]
  rows.append([item.get('class'),parent,properties])
  for child in item.findall('Item'):walk(child,index)
 walk(root,0)
 changes=[]
 for path in ['src/shared/LobbyIncubatorRules.luau','src/shared/Config.luau','src/server/LobbyWorld.luau','src/server/CaptureServer.server.luau','src/server/LobbyCompanions.luau','src/client/BagUI.luau','src/client/RideAnimator.luau','src/client/UserMossratRigAnimator.luau','src/client/CaptureClient.client.luau','src/client/HuntEffects.luau']:
  file=R/path;name=file.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau');kind='Script' if file.name.endswith('.server.luau') else 'LocalScript' if file.name.endswith('.client.luau') else 'ModuleScript'
  parent='shared' if file.parent.name=='shared' else 'server' if file.parent.name=='server' else 'clients'
  before=[]
  for rev in ['b0c9be0','d1b7826']:
   old=subprocess.run(['git','show',rev+':'+path],cwd=R,capture_output=True)
   if old.returncode==0:before.append(old.stdout.decode('utf-8'))
  after=file.read_text(encoding='utf-8');before.append(after)
  changes.append('{parent='+parent+',name='+json.dumps(name)+',kind='+json.dumps(kind)+',allowed={'+','.join(long(s) for s in before)+'},after='+long(after)+',new='+str(name in ('LobbyIncubatorRules','HuntEffects','LobbyCompanions')).lower()+'}')
 code='''-- Edit mode only: swap lobby, retain uploaded models/materials, back up old map/code.
assert(not game:GetService("RunService"):IsRunning(),"Play를 중지하세요.")
local old=assert(workspace:FindFirstChild("RodeoLobby"),"RodeoFantasy-New 맵을 열어 주세요.")
assert(workspace:FindFirstChild("GreenStar"),"GreenStar 없음")
local shared=assert(game.ReplicatedStorage:FindFirstChild("RodeoFantasy"),"게임 시스템 없음")
local server=game:GetService("ServerScriptService")
local clients=game:GetService("StarterPlayer").StarterPlayerScripts
local function normalize(s) return s:gsub("\\r\\n","\\n") end
local changes={
'''+',\n'.join(changes)+'''
}
for _,c in ipairs(changes) do
 c.node=c.parent:FindFirstChild(c.name)
 if c.node then
  assert(c.node.ClassName==c.kind,"종류 불일치: "..c.name)
  local allowed=false for _,s in ipairs(c.allowed) do if normalize(c.node.Source)==normalize(s) then allowed=true break end end
  assert(allowed,"사용자 코드가 달라 중단했습니다: "..c.name)
  c.original=c.node.Source
 else assert(c.new,"게임 코드 없음: "..c.name) end
end
local rows=game:GetService("HttpService"):JSONDecode('''+long(json.dumps(rows,separators=(',',':'),ensure_ascii=True))+''')
local objects={}
local fresh
local ok,err=pcall(function()
 for index,row in ipairs(rows) do
  local object=Instance.new(row[1]) objects[index]=object
  for key,entry in pairs(row[3]) do
   local kind,value=entry[1],entry[2]
   if kind=="Vector3" then value=Vector3.new(table.unpack(value))
   elseif kind=="Color3" then value=Color3.new(table.unpack(value))
   elseif kind=="CoordinateFrame" then value=CFrame.new(table.unpack(value))
   elseif kind=="UDim2" then value=UDim2.new(table.unpack(value))
   elseif kind=="token" then
    if key=="Material" then value=value==256 and Enum.Material.Plastic or value==288 and Enum.Material.Neon or Enum.Material.Glass
    elseif key=="shape" then value=Enum.PartType.Block
    elseif key=="Face" then value=Enum.NormalId.Front
    else value=value==3 and Enum.SurfaceType.Studs or Enum.SurfaceType.Inlet end
   end
   if key=="size" then key="Size" elseif key=="shape" then key="Shape" end
   object[key]=value
  end
  if row[2]>0 then object.Parent=objects[row[2]] else fresh=object end
 end
 local doors=Instance.new("Script") doors.Name="SpaceLobbyDoors"
 doors.Source='''+long((R/'src/server/SpaceLobbyDoors.server.luau').read_text(encoding='utf-8'))+''' doors.Parent=fresh
 fresh:SetAttribute("SpaceLobbyInstalled",true) fresh:SetAttribute("LobbyCapacity",8)
 fresh.Airport.Airship:SetAttribute("RocketDepartureActive",true)
end)
if not ok then for _,object in ipairs(objects) do object:Destroy() end error("새 맵 준비 실패: "..tostring(err)) end
local ss=game:GetService("ServerStorage")
local backup=Instance.new("Folder") backup.Name="OrbitalLobbyBackup_"..game:GetService("HttpService"):GenerateGUID(false)
local made={}
game:GetService("ChangeHistoryService"):SetWaypoint("Before orbital lobby")
ok,err=pcall(function()
 backup.Parent=ss
 for _,c in ipairs(changes) do
  if c.node then c.node:Clone().Parent=backup else c.node=Instance.new(c.kind) c.node.Name=c.name c.node.Parent=c.parent table.insert(made,c.node) end
  c.node.Source=c.after
 end
 old.Parent=backup fresh.Parent=workspace
end)
if not ok then
 for _,c in ipairs(changes) do if c.original then c.node.Source=c.original end end
 for _,object in ipairs(made) do object:Destroy() end
 old.Parent=workspace fresh:Destroy() backup:Destroy()
 error("설치 실패·기존 로비 복원: "..tostring(err))
end
game:GetService("ChangeHistoryService"):SetWaypoint("Orbital lobby installed")
game:GetService("Selection"):Set({fresh})
print("ORBITAL_LOBBY_INSTALLED — Ctrl+S 저장 후 Play. 개인실 8개 / 알 부화소 1개씩 / 빈 새끼 캡슐 4개씩. 기존 몬스터 메시와 텍스처 보존.")
'''
 (R/'dist/InstallOrbitalLobby.commandbar.lua').write_text(code,encoding='utf-8')
 print('ORBITAL_LOBBY_INSTALLER_BUILT',len(rows),'objects; model/source preflight and rollback')
if __name__=='__main__':build()
