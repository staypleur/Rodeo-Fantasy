from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
source=(R/'src/client/JournalUI.luau').read_text(encoding='utf-8')
h='''
local function signal() return {Connect=function(self,f) self.fire=f end} end
local enum=function() return setmetatable({},{__index=function(_,k) return k end}) end
local Enum=setmetatable({},{__index=function(t,k) local v=enum() rawset(t,k,v) return v end})
local Vector2={new=function(x,y) return {X=x,Y=y} end}
local Vector3={zero=0}
local UDim={new=function(...) return {...} end}
local UDim2={fromScale=function(x,y) return {X=x,Y=y} end,fromOffset=function(x,y) return {X=x,Y=y} end,new=function(...) return {...} end}
local Color3={new=function(...) return {...} end,fromRGB=function(...) return {...} end}
local ColorSequence={new=function(...) return {...} end}
local nodes={}
local Instance={new=function(kind)
 local props={ClassName=kind,AbsoluteSize={X=900,Y=520},Visible=true,ZIndex=1}
 local n={children={},Activated=signal()}
 function n:IsA(k) return k==kind or (k=="GuiObject" and (kind=="Frame" or kind=="TextButton" or kind=="TextLabel" or kind=="ViewportFrame")) end
 function n:GetChildren() return table.clone(self.children) end
 function n:Destroy() if self.Parent then for i,c in ipairs(self.Parent.children) do if c==self then table.remove(self.Parent.children,i) break end end end end
 setmetatable(n,{__index=function(_,k) return props[k] end,__newindex=function(_,k,v) props[k]=v if k=="Parent" then table.insert(v.children,n) end end})
 table.insert(nodes,n) return n
end}
local human={WalkSpeed=40,JumpPower=50,JumpHeight=7,AutoRotate=true,Parent=true,Move=function() end}
local player={LocaleId="ko-kr",Character={FindFirstChildOfClass=function() return human end}}
local UIS={InputBegan=signal(),GetFocusedTextBox=function() return nil end}
local Run={RenderStepped=signal()}
local CAS={BindActionAtPriority=function() end,UnbindAction=function() end}
local catalog={Order={"MeadowMouse"},MeadowMouse={IncomeAmount=1,IncomeSeconds=3,UnlockMeters=0,TameSeconds=5}}
local entries={} for _,stars in ipairs({1,3,6,9}) do table.insert(entries,{monsterId="MeadowMouse",stars=stars,key="MeadowMouse:"..stars}) end
local modules={MonsterCatalog=catalog,CollectionQuery={entries=function() return entries end},Localization={text=function(v) return v end,income=function(a,s) return tostring(a).."/"..s end,huntHint=function() return "hunt" end,evolutionHint=function() return "evolve" end},MonsterPortrait={fill=function() end},AudioPresentation={ui=function() end}}
modules.BagUI={iconButton=function(gui) return Instance.new("TextButton") end}
local package={MonsterCatalog="MonsterCatalog",CollectionQuery="CollectionQuery",Localization="Localization"}
local game={ReplicatedStorage={RodeoFantasy=package},GetService=function(_,k) return ({Players={LocalPlayer=player},UserInputService=UIS,RunService=Run,ContextActionService=CAS})[k] end}
local script={Parent={WaitForChild=function(_,k) return k end}}
local require=function(k) return modules[k] end
local layoutSignal=signal()
local workspace={CurrentCamera={ViewportSize={X=1250,Y=820},GetPropertyChangedSignal=function() return layoutSignal end}}
local task={defer=function(f) f() end}
local requests=0
local remote={FireServer=function(_,a) assert(a=="Journal") requests+=1 end}
local J=(function()
'''+source+'''
end)()
local api=J.new(Instance.new("Frame"),remote)
local function find(name) for _,n in ipairs(nodes) do if n.Name==name then return n end end error(name) end
api.snapshot({seen={["MeadowMouse:1"]=true},caught={["MeadowMouse:1"]=2}})
api.open() assert(find("FieldJournal").Visible and requests==1 and human.WalkSpeed==0)
assert(find("JournalCount").Text=="잠금 해제: 1/4")
assert(find("ProgressCount").Text=="1/4")
workspace.CurrentCamera.ViewportSize={X=390,Y=844} layoutSignal.fire()
assert(not find("MonsterInformation").Visible and not find("PlanetLandscape").Visible)
assert(find("Planet_GreenStar").Position.X==.70)
workspace.CurrentCamera.ViewportSize={X=1250,Y=820} layoutSignal.fire()
assert(find("MonsterInformation").Visible)
local cards=find("JournalEntries"):GetChildren() local clicked=false
for _,n in ipairs(cards) do if n.Name=="JournalEntry" then clicked=true n.Activated.fire() end end
assert(clicked and api.selected==4)
assert(find("Planet_GreenStar").Text=="행성\\nGreen Star")
api.state({area="Hunt"}) assert(not find("FieldJournal").Visible and human.WalkSpeed==40 and human.JumpPower==50)
api.open() assert(not find("FieldJournal").Visible)
api.state({area="Lobby"}) api.open() api.close() assert(human.AutoRotate)
print("INDEX_FLOW_PASS: saved collection, selected detail, count, open/close and hunt guard")
'''
(R/'.tools/test_index.luau').write_text(h,encoding='utf-8')
for path in ['src/client/JournalUI.luau','src/client/MonsterPortrait.luau','src/client/CreatureMesh.luau','src/client/HudIcons.luau','dist/RetryLobbyTextures.commandbar.lua','dist/InstallIndex.commandbar.lua']:
 subprocess.run([str(R/'.tools/luau/luau-compile.exe'),path],cwd=R,check=True,stdout=subprocess.DEVNULL)
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_index.luau'],cwd=R,check=True)
# A front camera is on the corrected visual's -Z axis, with no horizontal or
# vertical obliqueness; portrait pose is applied before bounding-box fitting.
p=(R/'src/client/MonsterPortrait.luau').read_text(encoding='utf-8')
assert 'Vector3.new(0,0,-1)' in p and p.index('Mesh.posePortrait(model)')<p.index('model:GetBoundingBox()')
print('PORTRAIT_FRONT_CONFIGURATION_PASS; live mesh/render verification pending')

# Run the shipped retry body against an imported model, including the reset
# interval; IDs must be restored before the one preload request is issued.
retry=(R/'dist/RetryLobbyTextures.commandbar.lua').read_text(encoding='utf-8')
h="""
local map={ColorMap="rbxassetid://132065898109030",RoughnessMap="rbxassetid://129909987929379",NormalMap="",MetalnessMap="",IsA=function(_,k) return k=="SurfaceAppearance" end}
local model={GetDescendants=function() return {map} end}
local workspace={FindFirstChild=function(_,k) return k=="PlanetImport" and model or nil end}
local Enum={AssetFetchStatus={Success="OK"}}
local pending,waypoints=0,0
local game={GetService=function(_,k)
 return ({RunService={IsRunning=function() return false end},ChangeHistoryService={SetWaypoint=function() waypoints+=1 end},ContentProvider={PreloadAsync=function(_,ids,cb) pending=#ids for _,id in ipairs(ids) do cb(id,"OK") end end}})[k]
end}
local task={wait=function() assert(map.ColorMap=="" and map.RoughnessMap=="") end}
local warn=function() end
"""+retry+"""
assert(map.ColorMap=="rbxassetid://132065898109030" and map.RoughnessMap=="rbxassetid://129909987929379")
assert(pending==2 and waypoints==2)
print("TEXTURE_RETRY_PASS: original IDs restored, one request batch")
"""
(R/'.tools/test_texture_retry.luau').write_text(h,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/test_texture_retry.luau'],cwd=R,check=True)
