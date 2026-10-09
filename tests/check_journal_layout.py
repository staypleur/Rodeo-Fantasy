"""Execute journal callbacks with UI stubs; visual QA still needs Studio."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def module(path):return '(function()\n'+(R/path).read_text(encoding='utf-8')+'\nend)()'
prefix=r"""
local function signal() local callbacks={} return {Connect=function(_,f) callbacks[#callbacks+1]=f return {Disconnect=function() end} end,Fire=function(_,...) for _,f in ipairs(callbacks) do f(...) end end} end
local vm={}
local function V(x,y) return setmetatable({X=x,Y=y},vm) end
vm.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y) end
vm.__sub=function(a,b) return V(a.X-b.X,a.Y-b.Y) end
vm.__mul=function(a,b) return V(a.X*b,a.Y*b) end
local Vector2={new=V}
local Vector3={zero={}}
local UDim2={new=function(x,a,y,b) return {x=x,a=a,y=y,b=b} end,fromOffset=function(a,b) return {x=0,a=a,y=0,b=b} end,fromScale=function(x,y) return {x=x,a=0,y=y,b=0} end}
local UDim={new=function(...) return {...} end}
local Color3={fromRGB=function(...) return {...} end,new=function(...) return {...} end}
local Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,x) return x end}) rawset(t,k,v) return v end})
local objects={} local Instance={}
function Instance.new(kind)
 local o={ClassName=kind,AbsolutePosition=V(0,0),AbsoluteSize=V(980,680),Activated=signal(),MouseEnter=signal(),MouseLeave=signal()}
 function o:IsA(k) return self.ClassName==k end
 function o:GetChildren() local out={} for _,n in ipairs(objects) do if n.Parent==self then out[#out+1]=n end end return out end
 function o:Destroy() for _,n in ipairs(self:GetChildren()) do n:Destroy() end self.Parent=nil end
 objects[#objects+1]=o return o
end
local UIS={InputBegan=signal(),InputEnded=signal(),GetFocusedTextBox=function() end}
local Run={RenderStepped=signal()}
local Tween={Create=function(_,node,info,goals) return {Completed=signal(),Play=function() for k,v in pairs(goals) do node[k]=v end end} end}
local CAS={BindActionAtPriority=function() end,UnbindAction=function() end}
local player={LocaleId='ko',Character=nil}
local package={MonsterCatalog='C',CollectionQuery='Q',Localization='L'}
local game={ReplicatedStorage={RodeoFantasy=package},GetService=function(_,name) return ({Players={LocalPlayer=player},UserInputService=UIS,RunService=Run,TweenService=Tween,ContextActionService=CAS})[name] end}
local TweenInfo={new=function() return {} end}
local task={delay=function() end}
local script={Parent={MonsterPortrait='P'}}
"""
prefix+='local C='+module('src/shared/MonsterCatalog.luau')+'\nlocal Q='+module('src/shared/CollectionQuery.luau')+'\n'
prefix+=r"""
local portraits={}
local L={text=function(t) return t end,huntHint=function() return 'Hunt acquisition hint' end,evolutionHint=function(s) return 'Evolution '..s end}
local P={fill=function(view,id,stars,silhouette,zoom) portraits[#portraits+1]={view=view,id=id,stars=stars,silhouette=silhouette,zoom=zoom} end}
local require=function(k) return ({C=C,Q=Q,L=L,P=P})[k] end
local J=(function()
"""
source=(R/'src/client/JournalUI.luau').read_text(encoding='utf-8')
suffix=r"""
end)()
local gui=Instance.new('ScreenGui') local calls=0
local ui=J.new(gui,{FireServer=function() calls+=1 end})
local function find(name) for _,o in ipairs(objects) do if o.Name==name and o.Parent then return o end end end
ui.open() ui.snapshot({seen={['MeadowMouse:1']=true}})
assert(not find('JournalTitle') and not find('ExplorerLevel') and not find('JournalXPTrack'))
local function verify(left,right,count)
 local cards={} for _,o in ipairs(find('JournalEntries'):GetChildren()) do if o.Name=='JournalEntry' then cards[#cards+1]=o end end
 assert(#cards==count)
 for i,card in ipairs(cards) do
  local expected=i<=4 and left or right
  local portrait
  for _,entry in ipairs(portraits) do if entry.view.Parent==card then portrait=entry end end
  assert(portrait.id==expected and portrait.stars==({1,3,6,9})[(i-1)%4+1] and portrait.zoom)
  assert(card.Position.x<.5==(i<=4),'each species must stay on its own paper page')
  local pages=find('JournalEntries')
  local bw,bh=980,680 local ph=bh+pages.Size.b
  card.AbsolutePosition=V(32+card.Position.x*(bw-64),98+card.Position.y*ph)
  card.AbsoluteSize=V(card.Size.x*(bw-64),card.Size.y*ph)
  card.MouseEnter:Fire()
  local bubble=find('AcquisitionBubble')
  assert(bubble.Visible and bubble.Position.b>=card.AbsolutePosition.Y+card.AbsoluteSize.Y,'hint must never cover its hovered card')
  assert(bubble.Size.b<=58 and bubble.Size.a<=280)
  card.MouseLeave:Fire() assert(not bubble.Visible)
  card.Activated:Fire() assert(bubble.Visible,'touch acquisition hint')
 end
end
verify('MeadowMouse','GrassBoar',8)
ui.turn(1) verify('TreeWolf','Weedcrow',8)
ui.turn(1) verify('RockElephant',nil,4)
ui.turn(1) assert(ui.page==3)
find('Region_Breeding').Activated:Fire() assert(find('JournalEmpty').Visible)
print('JOURNAL_LAYOUT_PASS: species stay on separate pages, ordered 1/3/6/9, discovery, pagination, empty filter and compact hover/touch notes outside cards; UI stubs')
"""
path=R/'.tools/journal_layout.luau';path.write_text(prefix+source+suffix,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
