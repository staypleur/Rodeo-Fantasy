-- Visual review additions only. The 192-stud driving floor and obstacles stay intact.
local Scenery={}
function Scenery.build(base)
 local blocks={}
 local function put(name,x,y,z,sx,sy,sz,r,g,b)
  table.insert(blocks,{Name=name,Position={x,y,z},Size={sx,sy,sz},Color={r,g,b},Kind="Scenery"})
 end
 local landmarks={{2,-1,32},{11,1,16},{18,1,40},{26,-1,24}}
 -- Trees grow on the outer terraces, rather than filling the driving corridor.
 for _,cap in ipairs(base) do
  if cap.Name=="GrassCap" then
   local x,z=cap.Position[1],cap.Position[3]
   local row=math.floor((-z-80)/160)
   local side=x<0 and -1 or 1
   local selectedTerrace=(row+side)%3==0 and 120 or 136
   local pattern=side<0 and {[0]=true,[1]=true,[3]=true,[6]=true} or {[1]=true,[2]=true,[4]=true,[5]=true}
   if math.abs(x)==selectedTerrace and pattern[row%7] then
    z+=(((row*17+(side>0 and 5 or 2))%9)-4)*12
    for _,landmark in ipairs(landmarks) do
     if row==landmark[1] and side==landmark[2] and math.abs(z-cap.Position[3])<landmark[3]/2+16 then
      z=cap.Position[3]+(z>=cap.Position[3] and 60 or -60)
     end
    end
    local top=cap.Position[2]+cap.Size[2]/2
    local extra=(row%3)*8
    local width=80-(row%3)*8
    local depth=64-(row%2)*8
    local tint=(row%3)*7
    put("TreeRoot",x,top+4,z,16,8,16,91,65,44)
    put("TreeTrunk",x,top+24+extra/2,z,8,46+extra,8,115,83,53)
    for layer=0,3 do
     local offset=layer%2==0 and -4 or 4
     put(layer==0 and "CanopyLower" or layer==3 and "CanopyUpper" or "CanopyMiddle",
      x+offset,top+48+extra+layer*2,z+offset,width-layer*8,2,depth-layer*8,
      68+layer*24+tint,105+layer*23,53+layer*12)
    end
    for _,side in ipairs({-1,1}) do
     if (row%3==0 and side==1) or (row%3==1 and side==-1) then continue end
     put("TreeTrunk",x+side*24,top+36+extra,z,40,6,8,115,83,53)
     for layer=0,3 do
      put(layer==0 and "CanopyLower" or layer==3 and "CanopyUpper" or "CanopyMiddle",
       x+side*(48+layer%2*4),top+40+extra+layer*2,z+(side==1 and 16 or -16),
       48-layer*8,2,40-layer*8,73+layer*22+tint,110+layer*22,50+layer*13)
     end
    end
   end
  end
 end
 -- Unequal landmarks cascade over the actual three terrace heights.
 -- Water is non-colliding Plastic,
 -- never Terrain; the original shoulder beneath it remains traversable.
 for _,landmark in ipairs(landmarks) do
  local segment,side,depth=table.unpack(landmark)
  local z=-80-segment*160
  local heights={}
  for _,p in ipairs(base) do
   if p.Name=="GrassCap" and p.Position[3]==z and p.Position[1]*side>0 then
    heights[math.abs(p.Position[1])]=p.Position[2]+p.Size[2]/2
   end
  end
  for _,terrace in ipairs({136,120,104}) do
   local top=assert(heights[terrace],"Waterfall requires its source terrace")
   local lower=terrace==104 and 16 or heights[terrace-16]+8
   put("WaterPool",side*(terrace-4),top+4,z,24,8,depth,87,175,190)
   for y=lower+4,top-4,8 do
    put("Waterfall",side*(terrace-12),y,z,8,8,depth,61+math.floor(y/8)*3,148+math.floor(y/8)*2,180)
   end
  end
  local poolDepth=depth+16
  put("WaterPool",side*88,8,z,16,16,poolDepth,62,160,175)
  put("WaterFoam",side*84,20,z-8,8,8,8,188,226,216)
  put("WaterFoam",side*84,20,z+4,8,8,8,214,237,219)
  put("WaterStream",side*92,8,z+poolDepth,8,16,poolDepth,65,152,165)
  put("WaterStream",side*88,8,z+poolDepth*1.5+16,8,16,32,71,165,173)
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
