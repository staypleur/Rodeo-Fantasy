local p=game.ReplicatedStorage.RodeoFantasy
local inputs,ends,renders={},{},{}
local clock=100 local calls={}
local function signal(list) return {Connect=function(_,fn) table.insert(list,fn) end} end
local fakeUIS={InputBegan=signal(inputs),InputEnded=signal(ends),GetFocusedTextBox=function() return nil end}
local fakeRun={RenderStepped=signal(renders)}
local pageAction
local fakeCAS={BindActionAtPriority=function(_,_,callback) pageAction=callback end,UnbindAction=function() pageAction=nil end}
local character=Instance.new('Model') character.Parent=workspace
local humanoid=Instance.new('Humanoid') humanoid.Parent=character
local fakeGame=setmetatable({GetService=function(_,name)
 if name=='Players' then return {LocalPlayer={LocaleId='en-us',Character=character}} end
 if name=='UserInputService' then return fakeUIS end
 if name=='RunService' then return fakeRun end
 if name=='ContextActionService' then return fakeCAS end
 return game:GetService(name)
end},{__index=function(_,key) return game[key] end})
local function loadUI(name)
 local module=game.StarterPlayer.StarterPlayerScripts[name]
 local f=assert(loadstring(module.Source))
 setfenv(f,setmetatable({game=fakeGame,script=module,os={clock=function() return clock end}},{__index=getfenv()}))
 return f()
end
local gui=Instance.new('ScreenGui') gui.Parent=game.StarterGui
local remote={FireServer=function(_,action) table.insert(calls,action) end}
local book=loadUI('JournalUI').new(gui,remote)
local bag=loadUI('BagUI').new(gui,remote)
book.onOpen=bag.close bag.onOpen=book.close
local function input(list) for _,f in ipairs(list) do f({KeyCode=Enum.KeyCode.T},false) end end
input(inputs) clock=100.5 for _,f in ipairs(renders) do f() end
assert(not gui.FieldJournal.Visible,'short press must not open journal') input(ends)
input(inputs) clock=101.6 for _,f in ipairs(renders) do f() end
assert(gui.FieldJournal.Visible and calls[#calls]=='Journal','one-second hold opens journal')
assert(humanoid.WalkSpeed==0 and humanoid.JumpPower==0 and humanoid.JumpHeight==0,'journal freezes walking and jumping')
local function cards() local result={} for _,n in ipairs(gui.FieldJournal.JournalEntries:GetChildren()) do if n.Name=='JournalEntry' then table.insert(result,n) end end return result end
assert(#cards()==8)
assert(pageAction) pageAction(nil,Enum.UserInputState.Begin,{KeyCode=Enum.KeyCode.D}) assert(book.page==2)
pageAction(nil,Enum.UserInputState.Begin,{KeyCode=Enum.KeyCode.A}) assert(book.page==1)
for _,card in ipairs(cards()) do assert(card.SpeciesName.Text=='???') for _,part in ipairs(card.JournalPortrait.WorldModel:GetDescendants()) do if part:IsA('BasePart') then assert(part.Color==Color3.fromRGB(22,28,23)) end end end
book.snapshot({xp=1,level=2,current=0,required=1,fraction=0,seen={['MeadowMouse:1']=true}})
local known=0 for _,card in ipairs(cards()) do if card.SpeciesName.Text~='???' then known+=1 end end assert(known==1)
book.state({area='Hunt'}) assert(humanoid.WalkSpeed==16 and humanoid.JumpPower==50,'closing restores movement') assert(not gui.FieldJournal.Visible and not gui.OpenJournal.Visible)
input(inputs) clock=104 for _,f in ipairs(renders) do f() end assert(not gui.FieldJournal.Visible)
local items={} for id=1,40 do table.insert(items,{id=id,monsterId=id%2==0 and 'MeadowMouse' or 'Weedcrow',stars=1,incomeSeconds=3,incomeAmount=1}) end
bag.state({area='Lobby',count=40,pending=10}) bag.snapshot(items) bag.toggle()
local function bagCount() local count=0 for _,n in ipairs(gui.BagWindow.BagCards:GetChildren()) do if n.Name=='MonsterCard' then count+=1 end end return count end
assert(bagCount()==12,'large bags only construct twelve portraits at a time')
bag.filter('All','MOUSE') assert(bagCount()==12) bag.page=2 bag.snapshot(items) assert(bagCount()==8)
bag.filter('Breeding','') assert(bagCount()==0 and gui.BagWindow.EmptyBag.Visible)
bag.filter('All','') local first for id in pairs(bag.cards) do first=id break end
bag.income({{id=first,amount=2}}) assert(bag.cards[first]:FindFirstChild('CoinGain'))
local effect=bag.cards[first].CoinGain assert(effect.GainAmount.Text=='+2' and effect.GoldCoin)
local FX=require(game.StarterPlayer.StarterPlayerScripts.IncomeEffects)
local model=game.ServerStorage.RodeoMonsterTemplate:Clone() model.Parent=workspace
local gain=FX.pet(model,3) assert(gain.GainAmount.Text=='+3' and gain.Adornee==model.PrimaryPart)
FX.clear() assert(not gain.Parent)
model:Destroy() character:Destroy() gui:Destroy()
print('COLLECTION_UI_PASS: hold/release/lobby gating, eight journal portraits, black silhouettes, discovery names, capped pagination/localized filters and true coin effects')
