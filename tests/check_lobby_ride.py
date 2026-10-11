from pathlib import Path
import subprocess
r=Path.cwd()
s=(r/'src/server/LobbyCompanions.luau').read_text(encoding='utf8')
bond=s[s.index(' function api.bond'):s.index(' function api.clear')]
ride=s[s.index(' function api.ride'):s.index(' function api.input')]
rules=(r/'src/shared/LobbyRideRules.luau').read_text(encoding='utf8')
dep=(r/'src/shared/DepartureSelectionRules.luau').read_text(encoding='utf8')
service=(r/'src/server/RocketDepartureService.luau').read_text(encoding='utf8')
service=service.replace('local Rules=require(game:GetService("ReplicatedStorage").RodeoFantasy.DepartureSelectionRules)','local Rules=Departure')
h='''local Vector3={zero={}}
local player={Character={}}
local attrs={}
function player:SetAttribute(k,v) attrs[k]=v end
local modelAttrs={}
local model={PrimaryPart={Position=0},GetAttribute=function(_,k) return modelAttrs[k] end,SetAttribute=function(_,k,v) modelAttrs[k]=v end}
local distance=5 local alive=true local r={Anchored=false,Position=setmetatable({},{__sub=function() return {Magnitude=distance} end})}
local hum={Health=100,AutoRotate=true,PlatformStand=false,Sit=false,ChangeState=function(self,state) self.state=state end}
function player.Character:FindFirstChildOfClass() return hum end
local validRoot=true
local function root() return validRoot and r end
local canAct,lobby,available=true,true,true
local context={canAct=function() return canAct end,inLobby=function() return lobby end,bag=function() return {} end}
local Rules={find=function() return {} end,available=function() return available end}
local pets={[player]={id=1,model=model}}
local time=10 local workspace={GetServerTimeNow=function() return time end}
local Enum={HumanoidStateType={Seated='Seated'}}
local removed=0 local api={dismount=function() removed+=1 pets[player].ride=nil end}
'''+ride+'''
assert(not api.ride(player,2))
distance=11 assert(not api.ride(player,1)) distance=5
canAct=false assert(not api.ride(player,1)) canAct=true
lobby=false assert(not api.ride(player,1)) lobby=true
available=false assert(not api.ride(player,1)) available=true
hum.Health=0 assert(not api.ride(player,1)) hum.Health=100
modelAttrs.PetBondUntil=12 assert(not api.ride(player,1)) modelAttrs.PetBondUntil=nil
assert(api.ride(player,1) and r.Anchored and hum.Sit and not hum.PlatformStand and attrs.LobbyRiding)
assert(pets[player].ride.anchored==false and pets[player].ride.sit==false)
assert(api.ride(player,1) and removed==1)
local Departure=(function()
'''+dep+'''\nend)()
local catalog={MeadowMouse={}}
local function ready(id,stars) return id=='MeadowMouse' and stars==1 end
assert(Departure.starter('GreenStar',catalog,ready).stars==1)
assert(not Departure.starter('Iris',catalog,ready))
assert(not Departure.starter('GreenStar',catalog,function() return false end))
local Service=(function()
'''+service+'''\nend)()
local open=true local launches=0 local result
local service=Service.new({bag=function() return {} end,canOpen=function() return open end,token=function() return 'test' end,now=function() return time end,catalog=catalog,modelReady=ready,courseReady=function() return true end,send=function(_,action,data) result={action,data} end,launch=function(_,item) assert(item==nil) launches+=1 return true end})
assert(service.open(player))
assert(not service.submit(player,{token='wrong',planet='GreenStar'})) time+=1
assert(not service.submit(player,{token='test',planet='Iris'})) time+=1
open=false assert(not service.submit(player,{token='test',planet='GreenStar'})) open=true time+=1
assert(service.submit(player,{token='test',planet='GreenStar',itemId=999,stars=9}) and launches==1)
time+=1 assert(not service.submit(player,{token='test',planet='GreenStar'}) and launches==1)
print('RIDE_DEPARTURE_PASS: invalid mount/state denied; seated snapshot; dismount toggle; default starter; token/planet/proximity/replay guards')
'''
(r/'.tools/test_lobby_ride.luau').write_text(h,encoding='utf8')
subprocess.run([str(r/'.tools/luau/luau.exe'),'.tools/test_lobby_ride.luau'],check=True)
server=(r/'src/server/CaptureServer.server.luau').read_text(encoding='utf8')
snapshot=server.index('states[player]={phase="Lassoing"')
assert server.rfind('companions.clear(player)',0,snapshot)>server.rfind('local model=',0,snapshot)
print('DEPARTURE_RESTORE_ORDER_PASS')
