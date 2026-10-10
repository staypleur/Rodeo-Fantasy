-- Applies the requested smooth surfaces to the installed lobby only.
local lobby=workspace:WaitForChild("RodeoLobby")
require(script.Parent.LobbyAppearance).ensure(lobby)
local safety=lobby:FindFirstChild("LobbyCollisionFloor")
if not safety then
 safety=Instance.new("Part") safety.Name="LobbyCollisionFloor" safety.Size=Vector3.new(512,4,512) safety.Position=Vector3.new(6000,0,0)
 safety.Anchored=true safety.Transparency=1 safety.CanCollide=true safety.CanTouch=false safety.CollisionGroup="Default" safety.Parent=lobby
end
local decor=lobby:FindFirstChild("SpaceDiorama")
if decor then for _,p in ipairs(decor:GetDescendants()) do if p.Name=="PlanetLayer" or p.Name=="PlanetRing" then p:Destroy() end end end
local sign=lobby.Airport:FindFirstChild("DepartureSign") if sign then sign:Destroy() end
local shell=lobby:FindFirstChild("ShipShell")
if shell then for _,p in ipairs(shell:GetDescendants()) do if p:IsA("BasePart") and p.Name=="WindowSpace" then p.Material=Enum.Material.Metal p.Transparency=0 p.CanCollide=true p.Color=Color3.fromRGB(62,78,103) end end end
if not lobby:FindFirstChild("OverheadSpace") then
 local space=Instance.new("Model") space.Name="OverheadSpace" space.Parent=lobby
 local random=Random.new(731)
 for i=1,70 do
  local star=Instance.new("Part") star.Name="Star" star.Shape=Enum.PartType.Ball star.Size=Vector3.one*random:NextNumber(.8,2)
  star.Position=Vector3.new(6000+random:NextNumber(-470,470),495,random:NextNumber(-470,470)) star.Color=Color3.fromRGB(193,217,255) star.Material=Enum.Material.Neon
  star.Anchored=true star.CanCollide=false star.CanTouch=false star.CanQuery=false star.CastShadow=false star.Parent=space
 end
end
for _,part in ipairs(lobby:GetDescendants()) do
 if part:IsA("Part") then
  part.TopSurface=Enum.SurfaceType.Smooth part.BottomSurface=Enum.SurfaceType.Smooth
  part.FrontSurface=Enum.SurfaceType.Smooth part.BackSurface=Enum.SurfaceType.Smooth
  part.LeftSurface=Enum.SurfaceType.Smooth part.RightSurface=Enum.SurfaceType.Smooth
  if part.Material==Enum.Material.Plastic then part.Material=Enum.Material.SmoothPlastic end
 end
end
