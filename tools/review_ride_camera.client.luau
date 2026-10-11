-- Play-only diagnostic: use the real summoned pet and server riding path.
local p=game.Players.LocalPlayer
local pet=workspace.RodeoLobby.LobbyCompanions:FindFirstChild("Companion_"..p.UserId)
assert(pet and p:GetAttribute("LobbyRiding"),"Mount using the ride button first")
local rs=game.RunService
local presentation=require(p.PlayerScripts.RideAnimator)
local started=os.clock()
local initial=pet.PrimaryPart.Position
local maxDistance=0
local low,high=math.huge,-math.huge
local lowBody,highBody=math.huge,-math.huge
local samples=0
local initialTravel=presentation.travelFrame(pet)
local startingY=initialTravel and initialTravel.Y or initial.Y
rs:BindToRenderStep("RideCameraDiagnosticInput",202,function()
 local t=os.clock()-started
 p.Character.Humanoid:Move(Vector3.new(t%4<2 and 1 or -1,0,0),false)
end)
rs:BindToRenderStep("RideCameraDiagnosticSample",204,function()
 local t=os.clock()-started
 local travel=presentation.travelFrame(pet)
 local body=presentation.frame(pet)
 maxDistance=math.max(maxDistance,(pet.PrimaryPart.Position-initial).Magnitude)
 if t>1 and travel and body and math.abs(travel.Y-startingY)<.001 then
  samples+=1
  local y=workspace.CurrentCamera.CFrame.Y-travel.Y
  low=math.min(low,y) high=math.max(high,y)
  lowBody=math.min(lowBody,body.Y-travel.Y) highBody=math.max(highBody,body.Y-travel.Y)
 end
 if t>=8 then
  rs:UnbindFromRenderStep("RideCameraDiagnosticInput")
  rs:UnbindFromRenderStep("RideCameraDiagnosticSample")
  p.Character.Humanoid:Move(Vector3.zero,false)
  print("RIDE_CAMERA_REVIEW",samples,"flat samples",maxDistance,"travel",samples>0 and high-low or "NO_FLAT_SAMPLES","camera Y range",samples>0 and highBody-lowBody or "NO_FLAT_SAMPLES","body bounce",pet.Parent~=nil,"pet retained")
 end
end)
