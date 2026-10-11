local motion=require(game.ReplicatedStorage.RodeoFantasy.QuadrupedMotion)
local A={}
local cache=setmetatable({},{__mode="k"})
function A.apply(model,moving,dt)
 local body=model:FindFirstChild("Body") if not body then return end
 local c=cache[model]
 if not c or c.body~=body then
  c={body=body,legs={},phase=0,weight=0,gait=0}
  for _,side in ipairs({"Left","Right"}) do
   for _,limb in ipairs({"Front","Rear"}) do
    local name=side..limb
    local upper=body:FindFirstChild(name.."Upper",true)
    local lower=body:FindFirstChild(name.."Lower",true)
    local paw=body:FindFirstChild(name.."Paw",true)
    if upper and lower and paw and lower.Parent==upper and paw.Parent==lower then
     local u,l=lower.CFrame.Position,paw.CFrame.Position
     local a,b=Vector2.new(u.Y,u.Z).Magnitude,Vector2.new(l.Y,l.Z).Magnitude
     if a>.001 and b>.001 then
      c.legs[#c.legs+1]={name=name,upper=upper,lower=lower,paw=paw,a=a,b=b,
       y=u.Y+l.Y,z=u.Z+l.Z,restA=math.atan2(u.Z,-u.Y),restB=math.atan2(l.Z,-l.Y),bend=limb=="Front" and -1 or 1}
     end
    end
   end
  end
  cache[model]=c
 end
 local velocity=model:GetAttribute("HerdVelocity")
 local speed=typeof(velocity)=="Vector3" and velocity.Magnitude or 0
 local running=speed>18
 c.gait+=((running and 1 or 0)-c.gait)*(1-math.exp(-8*dt))
 c.weight+=( (moving and 1 or 0)-c.weight)*(1-math.exp(-12*dt))
 if moving then c.phase=(c.phase+dt*math.clamp(speed/math.max(body.Size.Y*2,1),.7,2.8))%1 end
 for _,leg in ipairs(c.legs) do
  local length=leg.a+leg.b
  local walkZ,walkLift=motion.foot(c.phase,leg.name,false)
  local runZ,runLift=motion.foot(c.phase,leg.name,true)
  local z=walkZ+(runZ-walkZ)*c.gait
  local lift=walkLift+(runLift-walkLift)*c.gait
  local a,b=motion.solve(leg.y+length*(.06+lift*.22),leg.z+z*length*(.45+.20*c.gait),leg.a,leg.b,leg.bend)
  local upper=-(a-leg.restA)
  local lower=-(b-leg.restB)-upper
  leg.upper.Transform=CFrame.identity:Lerp(CFrame.Angles(upper,0,0),c.weight)
  leg.lower.Transform=CFrame.identity:Lerp(CFrame.Angles(lower,0,0),c.weight)
  leg.paw.Transform=CFrame.identity:Lerp(CFrame.Angles(-upper-lower,0,0),c.weight)
 end
end
return A
