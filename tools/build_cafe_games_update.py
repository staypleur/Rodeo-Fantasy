"""Generate edit-time installers; never alter the user's main place file."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
def quote(text):return json.dumps(text,ensure_ascii=False)
def install(parent,name,path,kind='ModuleScript'):
 return f'local v={parent}:FindFirstChild({quote(name)}) or Instance.new({quote(kind)}); v.Name={quote(name)}; v.Source={quote((R/path).read_text(encoding="utf-8"))}; v.Archivable=true; v.Parent={parent};'
common=['local P=game.ReplicatedStorage:FindFirstChild("RodeoFantasy") or Instance.new("Folder");P.Name="RodeoFantasy";P.Parent=game.ReplicatedStorage;local S=game.ServerScriptService;local C=game.StarterPlayer.StarterPlayerScripts;']
for name,path,parent in [('CafeMapLayout','src/server/CafeMapLayout.luau','S'),('CafeActivities','src/server/CafeActivities.luau','S'),('GomokuRules','src/shared/GomokuRules.luau','P'),('PianoNotes','src/shared/PianoNotes.luau','P'),('CafeActivityUI','src/client/CafeActivityUI.luau','C')]:common.append(install(parent,name,path))
common.append('local event=P:FindFirstChild("CafeActivityRemote") or Instance.new("RemoteEvent");event.Name="CafeActivityRemote";event.Parent=P;')
common.append('if not game.ServerStorage:FindFirstChild("CafePianoVisual") then local asset=game.InsertService:LoadAsset(15350031623);asset.Name="CafePianoVisual";asset.Parent=game.ServerStorage end;local asset=game.ServerStorage.CafePianoVisual;for _,v in asset:GetDescendants() do if not (v:IsA("Model") or v:IsA("Folder") or v:IsA("BasePart") or v:IsA("SpecialMesh") or v:IsA("SurfaceAppearance") or v:IsA("Decal") or v:IsA("Texture")) then v:Destroy() elseif v:IsA("BasePart") then v.Anchored=true v.CanTouch=false end end asset:SetAttribute("CreatorStoreAsset",15350031623);')
common.append('local fresh=S.CafeMapLayout:Clone();fresh.Parent=S;local layout=require(fresh);print("CAFE_COMPACT",layout.apply(workspace.RodeoCafe));fresh:Destroy();local a=S.CafeActivities:Clone();a.Parent=S;require(a).build(workspace.RodeoCafe);a:Destroy();print("CAFE_ACTIVITIES_READY",#workspace.RodeoCafe.Activities:GetDescendants());')
review=common+[install('C','AudioPresentation','src/client/AudioPresentation.luau')]
# Test UI volume only: same activity UI without inventory/teleport/DataStore access.
review.append('C.AudioPresentation.Source="return {getVolume=function() return 1 end}";')
server='local map=workspace.RodeoCafe; require(script.Parent.CafeActivities).start(map,function(p) return not p:GetAttribute("Travelling") end);game.Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) c:WaitForChild("HumanoidRootPart");task.wait(1);c:PivotTo(CFrame.new(-1255.25,6,-546));end) end)'
client='local p=game.Players.LocalPlayer;local gui=Instance.new("ScreenGui");gui.Name="CafeActivityReviewUI";gui.Parent=p:WaitForChild("PlayerGui");require(script.Parent:WaitForChild("CafeActivityUI")).new(gui)'
review.append(f'local v=S:FindFirstChild("CafeActivityReview") or Instance.new("Script");v.Name="CafeActivityReview";v.Source={quote(server)};v.Parent=S;')
review.append(f'local v=C:FindFirstChild("CafeActivityReviewUI") or Instance.new("LocalScript");v.Name="CafeActivityReviewUI";v.Source={quote(client)};v.Parent=C;')
review.append('workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(-1213.25,24,-495),Vector3.new(-1213.25,4,-575));print("CAFE_ACTIVITY_PREVIEW_READY");')
service=common+[install('S','CafeServer','src/server/CafeServer.server.luau','Script'),install('C','CafeClient','src/client/CafeClient.client.luau','LocalScript')]
out=R/'dist/ReviewModels'
(out/'CafeGamesReview.commandbar.lua').write_text(' '.join(review),encoding='utf-8')
(out/'CafeGamesService.commandbar.lua').write_text('assert(game.PlaceId==133084853508719,"Wrong place: cafe required"); '+' '.join(service)+'print("CAFE_GAMES_SERVICE_APPLIED");',encoding='utf-8')
lobby='local S=game.ServerScriptService;local C=game.StarterPlayer.StarterPlayerScripts;'+install('S','CaptureServer','src/server/CaptureServer.server.luau','Script')+install('C','CaptureClient','src/client/CaptureClient.client.luau','LocalScript')+install('C','HuntSteerSender','src/client/HuntSteerSender.luau')+install('C','RideAnimator','src/client/RideAnimator.luau')
(out/'HuntResponse.commandbar.lua').write_text('assert(game.PlaceId==131121026461681,"Wrong place: lobby required");'+lobby+'print("HUNT_RESPONSE_APPLIED");',encoding='utf-8')
print('CAFE_GAMES_INSTALLERS_READY')
