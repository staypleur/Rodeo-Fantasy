-- The supplied untouched Meshy lobby creature faces +Z. Install in EDIT mode.
local M={}
local D=require(script.Parent.MeshyAirshipData)
function M.installSelected()
 assert(not game:GetService("RunService"):IsRunning(),"재생을 정지한 뒤 설치해주세요.")
 local selected=game:GetService("Selection"):Get()
 assert(#selected==1,"가져온 새 로비 모델 하나를 선택해주세요.")
 local source=selected[1]
 assert(source:IsA("Model") or source:IsA("MeshPart"),"가져온 Model 또는 MeshPart를 선택해주세요.")
 local airport=workspace.RodeoLobby.Airport
 assert(source:IsDescendantOf(workspace) and not source:IsDescendantOf(airport),"새로 가져온 모델을 선택해주세요.")
 local original=source:IsA("MeshPart") and {source} or source:GetDescendants()
 local meshes={}
 for _,p in ipairs(original) do
  assert(not p:IsA("LuaSourceContainer"),"가져온 모델에 스크립트가 있습니다. 설치를 중단합니다.")
  if p:IsA("MeshPart") then
   local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
   assert(p.MeshId~="" and (p.TextureID~="" or appearance and appearance.ColorMap~=""),"메시와 텍스처 업로드를 완료해주세요.")
   table.insert(meshes,p)
  end
 end
 assert(#meshes==1,"제공된 단일 메시 모델을 병합/분할 없이 가져와주세요.")
 local current=assert(airport:FindFirstChild("Airship"),"기존 Airship을 찾지 못했습니다.")
 local p=meshes[1]
 local scale=D.Height/p.Size.Y
 -- MeshPart origin is imported bounds centre. Reconstruct source coordinates.
 local sourceCenter=Vector3.new(.0124306679,5,-.0058398247)
 local world=CFrame.new(unpack(D.WorldAnchor))*CFrame.Angles(0,math.pi,0)
 local center=world:PointToWorldSpace((sourceCenter-Vector3.new(unpack(D.SourceAnchor)))*(D.Height/D.SourceHeight))
 local clone=Instance.new("Model") clone.Name="Airship"
 local body=p:Clone() body.Name="MeshyAirshipBody" body.Size*=scale
 body.CFrame=CFrame.new(center)*world.Rotation body.Anchored=true body.CanCollide=false body.CanTouch=false body.CanQuery=false
 body.Color=Color3.new(1,1,1) body.DoubleSided=true body.RenderFidelity=Enum.RenderFidelity.Precise
 body:SetAttribute("WhaleRest",body.CFrame) body.Parent=clone
 clone.PrimaryPart=body clone:SetAttribute("NativeMeshyAirship",true) clone:SetAttribute("SkyWhaleRevision","MeshyLobby-v1") clone:SetAttribute("WhaleAnchor",CFrame.new(center))
 local changes={}
 for _,cable in ipairs(airport.BoardingArea:GetChildren()) do
  if cable:IsA("BasePart") and cable.Name=="Cable" then
   for _,c in ipairs(D.Cables) do
    if math.abs(cable.Position.X-c[1])<.1 and math.abs(cable.Position.Z-c[2])<.1 then table.insert(changes,{part=cable,data=c}) end
   end
  end
 end
 if #changes~=4 then clone:Destroy() error("탑승 줄 위치가 예상과 달라 설치하지 않았습니다.") end
 local archive=Instance.new("Folder") archive.Name="MeshyAirshipBackup" archive.Parent=game.ServerStorage
 current.Parent=archive clone.Parent=airport
 for _,change in ipairs(changes) do local c=change.data local cable=change.part cable.Size=Vector3.new(cable.Size.X,c[4]-c[3],cable.Size.Z) cable.CFrame=CFrame.new(c[1],(c[4]+c[3])/2,c[2]) end
 source.Parent=archive
 print("새 로비 모델 설치 완료. 원본 텍스처 보존 / 배 아래 줄 4개 연결. Ctrl+S 후 Play로 확인해주세요.")
 return clone
end
return M
