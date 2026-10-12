-- Shared 2D portraits: inventory/catalog never clone 3D rigs or cameras.
local P={}
local package=game.ReplicatedStorage.RodeoFantasy
local C=require(package.MonsterCatalog)
local defaults={[1]="rbxassetid://136157716828140",[3]="rbxassetid://132856650627155",[6]="rbxassetid://105207783752500",[9]="rbxassetid://85299683248138"}
function P.fill(container,id,stars,silhouette,_distanceScale)
 local stage=C.stage(stars)
 local imageId=id=="MeadowMouse" and (package:GetAttribute("MossratPortraitS"..stage) or defaults[stage])
  or id=="GrassBoar" and package:GetAttribute("BrambleboarPortraitS"..stage) or nil
 local image=Instance.new("ImageLabel") image.Name="MonsterPortraitImage"
 image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
 image.ScaleType=Enum.ScaleType.Fit image.ZIndex=container.ZIndex+1
 image.Image=type(imageId)=="string" and imageId or ""
 image.ImageColor3=silhouette and Color3.new(0,0,0) or Color3.new(1,1,1)
 image.Parent=container
 if image.Image=="" then
  local label=Instance.new("TextLabel") label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
  label.Text="?" label.TextScaled=true label.TextColor3=Color3.fromRGB(160,180,170) label.Parent=container
 end
 return image
end
return P
