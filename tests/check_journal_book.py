"""Exercise actual journal callbacks and progression checkpoints without claiming engine rendering."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
def mod(path):return '(function()\n'+(R/path).read_text(encoding='utf-8')+'\nend)()'
code='local C='+mod('src/shared/MonsterCatalog.luau')+'\nlocal Q='+mod('src/shared/CollectionQuery.luau')+'\nlocal L='+mod('src/shared/Localization.luau')+'\n'
code+='''
local function signal()
 local n={callbacks={}}
 function n:Connect(f) table.insert(self.callbacks,f) return {Disconnect=function() end} end
 function n:fire(...) for _,f in ipairs(self.callbacks) do f(...) end end
 return n
end
local Enum=setmetatable({},{__index=function(t,k) local n=setmetatable({},{__index=function(_,v) return v end}) rawset(t,k,n) return n end})
local Vector2={new=function(x,y) return {X=x,Y=y} end}
local Vector3={zero={}}
local UDim={new=function(s,o) return {Scale=s,Offset=o} end}
local UDim2={new=function(xs,xo,ys,yo) return {xs,xo,ys,yo} end,fromScale=function(x,y) return {x,0,y,0} end,fromOffset=function(x,y) return {0,x,0,y} end}
local Color3={fromRGB=function(r,g,b) return {r/255,g/255,b/255} end,new=function(r,g,b) return {r,g,b} end}
local ColorSequence={new=function(...) return {...} end}
local TweenInfo={new=function(...) return {...} end}
local nodes={} local width=1000
local Instance={new=function(class)
 local node={ClassName=class,children={},props={},signals={}}
 function node:IsA(c) return c==class end
 function node:GetChildren() return table.clone(self.children) end
 function node:Destroy() for _,n in ipairs(self:GetChildren()) do n:Destroy() end self.destroyed=true if self.Parent then for i,n in ipairs(self.Parent.children) do if n==self then table.remove(self.Parent.children,i) break end end end end
 function node:GetPropertyChangedSignal(k) self.signals[k]=self.signals[k] or signal() return self.signals[k] end
 setmetatable(node,{__index=function(t,k)
  if k=='AbsoluteSize' then return {X=width,Y=780} end
  if k=='Activated' or k=='MouseEnter' then t.signals[k]=t.signals[k] or signal() return t.signals[k] end
  return t.props[k]
 end,__newindex=function(t,k,v) t.props[k]=v if k=='Parent' and v then table.insert(v.children,t) end end})
 table.insert(nodes,node) return node
end}
local h={WalkSpeed=32,JumpPower=50,JumpHeight=7.2,AutoRotate=true,Parent=true,Move=function() end}
local player={LocaleId='ko-kr',Character={FindFirstChildOfClass=function() return h end}}
local focus=false
local UIS={InputBegan=signal(),GetFocusedTextBox=function() return focus end}
local Run={RenderStepped=signal()}
local CAS={}
function CAS:BindActionAtPriority(_,f) self.action=f end
function CAS:UnbindAction() self.action=nil end
local Tween={Create=function(_,node,_,props) return {Play=function() for k,v in pairs(props) do node[k]=v end end} end}
local pending={}
local task={delay=function(_,f) table.insert(pending,f) end}
local function flush() local queue=pending pending={} for _,f in ipairs(queue) do f() end end
local sounds={}
local Audio={ui=function(k) table.insert(sounds,k) end}
local Portrait={fill=function(node,id,stars,black) node.monsterId=id node.stars=stars node.black=black end}
local Buttons={iconButton=function(gui) local n=Instance.new('TextButton') n.Parent=gui return n end}
local package={MonsterCatalog=C,CollectionQuery=Q,Localization=L}
local script={Parent={MonsterPortrait=Portrait,BagUI=Buttons,AudioPresentation=Audio}}
local game={ReplicatedStorage={RodeoFantasy=package}}
local services={Players={LocalPlayer=player},UserInputService=UIS,RunService=Run,TweenService=Tween,ContextActionService=CAS}
function game:GetService(k) return services[k] end
local require=function(v) return v end
local J=(function()
'''+(R/'src/client/JournalUI.luau').read_text(encoding='utf-8')+'''
end)()
local gui=Instance.new('ScreenGui') local requests=0
local book=J.new(gui,{FireServer=function() requests+=1 end})
local function find(name) for _,n in ipairs(nodes) do if not n.destroyed and n.Name==name then return n end end error(name) end
local function key(k,processed) UIS.InputBegan:fire({KeyCode=k},processed or false) end
book.snapshot({seen={['MeadowMouse:1']=true},caught={['MeadowMouse:1']=9},captures=9})
key('T') assert(find('FieldJournal').Visible and h.WalkSpeed==0 and sounds[1]=='BookOpen')
assert(book.perSpread==2)
local count=0 for _,n in ipairs(nodes) do if not n.destroyed and n.Name=='JournalPortrait' then count+=1 end end assert(count==8)
assert(find('SpeciesCaught').Text=='포획 수 9')
local soundCount=#sounds CAS.action('', 'Begin',{KeyCode='A'}) assert(book.page==1 and #sounds==soundCount,'first page does not animate or sound')
CAS.action('','Begin',{KeyCode='D'}) assert(book.page==2 and sounds[#sounds]=='PageTurn')
CAS.action('','Begin',{KeyCode='D'}) assert(book.page==2,'turn debounce') flush()
find('JournalPrevious').Activated:fire() assert(book.page==1) flush()
find('Region_Ocean').Activated:fire() assert(book.region=='Ocean' and find('JournalEmpty')) flush()
find('Region_Meadow').Activated:fire() assert(book.region=='Meadow') flush()
key('T') assert(not find('FieldJournal').Visible and h.WalkSpeed==32 and h.JumpPower==50 and h.AutoRotate)
focus=true key('T') assert(not find('FieldJournal').Visible) focus=false
key('T',true) assert(not find('FieldJournal').Visible)
key('T') width=430 find('FieldJournal'):GetPropertyChangedSignal('AbsoluteSize'):fire()
assert(book.perSpread==1 and not find('BookSpine').Visible)
count=0 for _,n in ipairs(nodes) do if not n.destroyed and n.Name=='JournalPortrait' then count+=1 end end assert(count==4)
book.state({area='Hunt'}) assert(not find('FieldJournal').Visible and h.WalkSpeed==32)
print('JOURNAL_BOOK_PASS: tap T, A/D, click, region flip, debounce, typed/processed input, single-page mobile layout, movement restoration, eight/four portraits')
'''
code+='local Rules='+mod('src/shared/ProgressRules.luau')+'\nlocal Bag='+mod('src/shared/BagRules.luau')+'''
local seen={['MeadowMouse:1']=true}
local a=Rules.merge(nil,'a',2,seen,100,{['MeadowMouse:1']=2})
local b=Rules.merge(a,'a',2,seen,101,{['MeadowMouse:1']=2}) assert(b.caught['MeadowMouse:1']==2 and b.captures==2)
local c=Rules.merge(b,'b',3,seen,102,{['MeadowMouse:1']=3}) assert(c.caught['MeadowMouse:1']==5 and c.captures==5)
local d=Rules.merge(c,'a',1,seen,103,{['MeadowMouse:1']=1}) assert(d.caught['MeadowMouse:1']==5)
local female,male=0,0 for i=0,999 do if Bag.sexForRoll((i+.5)/1000)=='Male' then male+=1 else female+=1 end end
assert(male==500 and female==500 and Bag.sexForRoll(.5)=='Female')
local old=Rules.merge({captures=13,seen=seen},'new',1,seen,104,{['MeadowMouse:1']=1})
assert(old.captures==14 and old.caught['MeadowMouse:1']==1,'never invent historical species counts')
print('JOURNAL_COUNTS_SEX_PASS: idempotent checkpoints, concurrent sessions, stale checkpoint protection, legacy migration, exact half probability boundary')
'''
p=R/'.tools/journal_book_test.luau';p.write_text(code,encoding='utf-8')
if __name__=='__main__':subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
