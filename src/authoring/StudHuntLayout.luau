-- Deterministic private meadow layout. No monsters, rewards, or new hunt rules.
local Layout = {WidthStuds=192,LengthStuds=4800,LengthMeters=1000,MetersPerStud=1000/4800}
-- Latest user target is screen composition, not spawn counts or exact pixel masks.
-- Tune against the rear-follow camera after the user supplies new monster models.
Layout.ScreenComposition = {Empty=0.40,Obstacles=0.20,Monsters=0.40}

function Layout.build()
 local blocks = {}
 local function put(name,x,y,z,sx,sy,sz,r,g,b,kind)
  table.insert(blocks,{Name=name,Position={x,y,z},Size={sx,sy,sz},Color={r,g,b},Kind=kind or "Scenery"})
 end
 -- Adjacent slabs share only their edge; no overlapping top faces.
 for index=0,29 do
  local z=-80-index*160
  local tint=index%3
  put("MeadowPlate",0,-4,z,192,8,160,224-tint*3,199-tint*3,151-tint*2,"Ground")
  for _,side in ipairs({-1,1}) do
   local height=24+(index%3)*8
   put("CliffFoot",side*104,4,z,16,8,160,113,73,48)
   for level=0,height/8-1 do
    put("CliffWall",side*120,12+level*8,z,16,8,160,119+level*10,76+level*9,48+level*7)
   end
   put("GrassCap",side*120,12+height,z,16,8,160,154,170,89)
  end
 end
 local function tree(x,z,large)
  local crown=large and 48 or 40
  put("TreeRoot",x,4,z,16,8,16,107,72,48,"Obstacle")
  for level=0,2 do
   put("TreeTrunk",x,12+level*8,z,8,8,8,125+level*12,86+level*10,58+level*8,"Obstacle")
  end
  for _,side in ipairs({-1,1}) do
   put("TreeBranch",x+side*12,24,z,16,8,8,146,104,72,"Obstacle")
  end
  -- Separate adjacent strips give irregular crowns and colour variation without
  -- overlapping coplanar surfaces. All geometry stays on the four-stud grid.
  for band=-1,1 do
   local w=band==0 and crown or crown-8
   put("CanopyLower",x+band*4,36,z+band*8,w,8,8,99+band*9,120+band*8,52+band*5,"Obstacle")
   put("CanopyMiddle",x-band*4,44,z+band*8,w-8,8,8,153+band*13,170+band*9,82+band*8,"Obstacle")
  end
  put("CanopyUpper",x,52,z,crown-16,8,16,182,193,104,"Obstacle")
 end
 local function rock(x,z,large)
  local w=large and 48 or 32
  put("LowRock",x,4,z,w,8,24,106,91,94,"Obstacle")
  put("RockMiddle",x+4,12,z+4,w-8,8,16,139,120,123,"Obstacle")
  put("RockCap",x,20,z,w-16,8,8,178,157,151,"Obstacle")
 end
 -- Opening and final approach stay clear. Alternate splits with open recovery space.
 -- Rows have 160-stud spacing (~33 m); the full outer width stays constant.
 for row=0,27 do
  local z=-240-row*160
  local pattern=row%7
  if pattern==0 then tree(0,z,true)
  elseif pattern==1 then rock(-40,z,false) rock(40,z,false)
  elseif pattern==2 then tree(-56,z,true) rock(24,z,false)
  elseif pattern==3 then rock(-24,z,false) tree(56,z,true)
  elseif pattern==4 then rock(-24,z,true) rock(24,z,true)
  elseif pattern==5 then tree(-64,z,false) tree(0,z,false) tree(64,z,false)
  else rock(-64,z,false) tree(40,z,true) end
 end
 return blocks
end

return Layout
