-- User-approved meadow species. All current wild spawns are one-star.
local C={
 MeadowMouse={RunSpeed=64,HerdSpeed=44,SizeClass="Small",Flying=false,RootHeight=2.05,SaddleHeight=2,TameSeconds=5,UnlockMeters=0,IncomeSeconds=3,IncomeAmount=1,Template="RodeoMonsterTemplate",Visual="VisualTemplate"},
 GrassBoar={RunSpeed=64,HerdSpeed=44,SizeClass="Medium",Flying=false,RootHeight=3.0625,SaddleHeight=2.8125,TameSeconds=6,UnlockMeters=150,IncomeSeconds=3,IncomeAmount=2,Template="GrassBoarTemplate",Visual="GrassBoarVisualTemplate"},
 TreeWolf={RunSpeed=76.8,HerdSpeed=52.8,SizeClass="Medium",Flying=false,RootHeight=2.9375,SaddleHeight=2.75,TameSeconds=6,UnlockMeters=300,TripleHop=true,IncomeSeconds=3,IncomeAmount=2,Template="TreeWolfTemplate",Visual="TreeWolfVisualTemplate"},
 Weedcrow={RunSpeed=80,HerdSpeed=55,SizeClass="Small",Flying=true,RootHeight=16,SaddleHeight=1.9,TameSeconds=5,UnlockMeters=400,IncomeSeconds=3,IncomeAmount=2,Template="WeedcrowTemplate",Visual="WeedcrowVisualTemplate"},
 RockElephant={RunSpeed=64,HerdSpeed=44,SizeClass="Large",Flying=false,RootHeight=5.3625,SaddleHeight=5.0325,TameSeconds=7,UnlockMeters=500,IncomeSeconds=3,IncomeAmount=3,Template="RockElephantTemplate",Visual="RockElephantVisualTemplate"},
}
C.Order={"MeadowMouse"}
C.MeadowEndMeters=1000 -- Meadow wildlife spawns only at 0 <= metres < 1000.
for _,id in ipairs(C.Order) do C[id].Region=C[id].Region or (C[id].Acquisition=="Breeding" and "Breeding" or "Meadow") C[id].Acquisition=C[id].Acquisition or "Hunt" end
C.Scales={[1]=1,[3]=1.4,[6]=1.9,[9]=2.5}
function C.stage(stars) return stars>=9 and 9 or stars>=6 and 6 or stars>=3 and 3 or 1 end
function C.scale(stars)
 stars=math.clamp(tonumber(stars) or 1,1,10)
 local lower=C.stage(stars)
 if lower==9 then return 2.5+(stars-9)*.2 end
 local upper=lower==1 and 3 or lower+3
 local alpha=(stars-lower)/(upper-lower)
 return C.Scales[lower]+(C.Scales[upper]-C.Scales[lower])*alpha
end
function C.visual(id,stars) local stage=C.stage(stars or 1) return C[id].Visual..(stage==1 and "" or "_S"..stage) end
function C.template(id,stars) local stage=C.stage(stars or 1) return C[id].Template..(stage==1 and "" or "_S"..stage) end
function C.saddleHeight(id,stars)
 stars=stars or 1
 if id=="GrassBoar" then
  local stage=C.stage(stars)
  local back={[1]=2.804463,[3]=3.880880,[6]=7.230789,[9]=11.021101}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 if id=="MeadowMouse" then
  local stage=C.stage(stars)
  if stage==1 or stage==3 then
   local package=game and game:GetService("ReplicatedStorage"):FindFirstChild("RodeoFantasy")
   local visual=package and package:FindFirstChild(C.visual(id,stars))
   local back=visual and visual:GetAttribute("MeshyBackHeight")
   if back then return back*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars) end
   return 1.2*C.scale(stars)
  end
  -- Meshes already contain their approved stage size. Seat above the back,
  -- with a constant clearance for the unscaled player rather than its crown.
  local back={[3]=2.212572,[6]=3.232653,[9]=7.460891}
  return back[stage]*C.scale(stars)/C.Scales[stage]+1.36-C[id].RootHeight*C.scale(stars)
 end
 return C[id].SaddleHeight*C.scale(stars)
end
function C.pick(meters,serial)
 if meters<0 or meters>=C.MeadowEndMeters then return nil end
 local unlocked={}
 for _,id in ipairs(C.Order) do if meters>=C[id].UnlockMeters then table.insert(unlocked,id) end end
 return unlocked[serial%#unlocked+1]
end
return C
