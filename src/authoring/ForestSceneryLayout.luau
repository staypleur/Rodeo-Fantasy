-- Visual review additions only. The 192-stud driving floor and obstacles stay intact.
local Scenery={}
function Scenery.build(base)
 local blocks={}
 local function put(name,x,y,z,sx,sy,sz,r,g,b)
  table.insert(blocks,{Name=name,Position={x,y,z},Size={sx,sy,sz},Color={r,g,b},Kind="Scenery"})
 end
 -- Trees grow on the outer terraces, rather than filling the driving corridor.
 for _,cap in ipairs(base) do
  if cap.Name=="GrassCap" and math.abs(cap.Position[1])==136 then
   local x,z=cap.Position[1],cap.Position[3]
   local row=math.floor((-z-80)/160)
   if row%2==0 then
    local top=cap.Position[2]+cap.Size[2]/2
    local extra=(row%3)*8
    put("TreeRoot",x,top+4,z,16,8,16,91,65,44)
    put("TreeTrunk",x,top+24+extra/2,z,8,46+extra,8,115,83,53)
    for layer=0,3 do
     local offset=layer%2==0 and -4 or 4
     put(layer==0 and "CanopyLower" or layer==3 and "CanopyUpper" or "CanopyMiddle",
      x+offset,top+48+extra+layer*2,z+offset,80-layer*8,2,64-layer*8,
      68+layer*24,105+layer*23,53+layer*12)
    end
    for _,side in ipairs({-1,1}) do
     put("TreeTrunk",x+side*24,top+36+extra,z,40,6,8,115,83,53)
     for layer=0,3 do
      put(layer==0 and "CanopyLower" or layer==3 and "CanopyUpper" or "CanopyMiddle",
       x+side*(48+layer%2*4),top+40+extra+layer*2,z+(side==1 and 16 or -16),
       48-layer*8,2,40-layer*8,73+layer*22,110+layer*22,50+layer*13)
     end
    end
   end
  end
 end
 -- Four landmarks spaced along the forest. Water is non-colliding Plastic,
 -- never Terrain; the original shoulder beneath it remains traversable.
 for index,segment in ipairs({2,9,18,25}) do
  local side=index%2==1 and -1 or 1
  local z=-80-segment*160
  local cliffTop
  for _,p in ipairs(base) do
   if p.Name=="GrassCap" and p.Position[1]==side*104 and p.Position[3]==z then
    cliffTop=p.Position[2]+p.Size[2]/2 break
   end
  end
  assert(cliffTop,"Waterfall requires its source terrace")
  put("WaterPool",side*100,cliffTop+4,z,24,8,24,87,175,190)
  for band=2,cliffTop/8-1 do
   put("Waterfall",side*92,4+band*8,z,8,8,24,
    55+band*9,145+band*8,170+band*9)
  end
  put("WaterPool",side*88,8,z,16,16,40,62,160,175)
  put("WaterFoam",side*84,20,z,8,8,16,188,226,216)
  put("WaterStream",side*92,8,z+44,8,16,48,65,152,165)
 end
 -- Low edge plants give foreground scale without becoming new obstacles.
 for row=0,29 do
  for _,side in ipairs({-1,1}) do
   local z=-48-row*160
   local groundTop=0
   for _,p in ipairs(base) do
    if p.Name=="MeadowShoulder" and p.Position[1]==side*88 and p.Position[3]==-80-row*160 then
     groundTop=p.Position[2]+p.Size[2]/2 break
    end
   end
   put("FernBase",side*84,groundTop+4,z,8,8,8,98,135,58)
   put("FernTip",side*84,groundTop+12,z,8,8,8,154,181,87)
  end
 end
 return blocks
end
return Scenery
