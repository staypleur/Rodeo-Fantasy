"""Run the actual repair against the user's observed backup-only hierarchy."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
prefix='''
local frame
frame=function(angle)
 local f={angle=angle,Position=0}
 f.Rotation=f
 return setmetatable(f,{__mul=function(a,b) return frame(a.angle+b.angle) end, __index={ToObjectSpace=function(_,b) return b end}})
end
local CFrame={new=function() return frame(0) end,Angles=function(_,y) return frame(math.deg(y)) end}
local function node(name,kind,attrs)
 local self={Name=name,kind=kind,attrs=attrs or {},children={}}
 function self:IsA(class) return self.kind==class end
 function self:GetAttribute(key) return self.attrs[key] end
 function self:SetAttribute(key,value) self.attrs[key]=value end
 function self:FindFirstChild(name) return self.children[name] end
 function self:GetChildren() local out={} for _,v in pairs(self.children) do table.insert(out,v) end return out end
 function self:GetDescendants() local out={} for _,v in pairs(self.children) do table.insert(out,v) for _,c in ipairs(v:GetDescendants()) do table.insert(out,c) end end return out end
 function self:Clone()
  local attrs={} for k,v in pairs(self.attrs) do attrs[k]=v end
  local copy=node(self.Name,self.kind,attrs)
  copy.MeshId=self.MeshId
  copy.CFrame=self.CFrame
  for _,v in pairs(self.children) do local child=v:Clone() child.Parent=copy if v==self.PrimaryPart then copy.PrimaryPart=child end end
  return copy
 end
 return setmetatable(self,{__index=function(t,k) return t.children[k] end,__newindex=function(t,k,v)
  if k=="Parent" then
   local old=rawget(t,"_parent") if old then old.children[t.Name]=nil end
   rawset(t,"_parent",v) if v then v.children[t.Name]=t end
  else rawset(t,k,v) end
 end})
end
local function model(name)
 local m=node(name,"Model",{NativeMeshyMossrat=true})
 local root=node("Root","Part") root.CFrame=frame(0) root.Parent=m m.PrimaryPart=root
 local body=node("Body","MeshPart") body.CFrame=frame(0) body.MeshId="approved-mesh" body.Parent=m
 return m
end
local package=node("RodeoFantasy","Folder")
local rs=node("ReplicatedStorage","Folder") package.Parent=rs
local ss=node("ServerStorage","Folder")
local backup=node("LobbyRepairBackup20261010","Folder") backup.Parent=ss
local hunt=model("MeshyMossratHuntTemplate") hunt.Parent=backup
 hunt:SetAttribute("HuntFacingRepair20261010",true)
local server=model("RodeoMonsterTemplate") server.Parent=backup
local workspace=node("Workspace","Folder")
local ship=model("Airship") ship.Parent=workspace
local Instance={new=function(kind) return node("",kind) end}
local game={GetService=function(_,name) return ({RunService={IsRunning=function() return false end},ServerStorage=ss,ReplicatedStorage=rs})[name] end}
local repair=(function()
'''
suffix='''
end)()
-- Missing detail fails before moving or restoring either hunt role.
local ok=pcall(repair.apply)
assert(not ok and not package.MeshyMossratHuntTemplate and not ss.RodeoMonsterTemplate)
assert(backup.MeshyMossratHuntTemplate==hunt and backup.RodeoMonsterTemplate==server)
local detail=model("RecoveryMossratDetailTemplate") detail.Body.MeshId="approved-10k" detail.Parent=workspace
repair.apply()
assert(package.MeshyMossratHuntTemplate and ss.RodeoMonsterTemplate and package.VisualTemplate)
assert(package.VisualTemplate.Body.MeshId=="approved-10k")
assert(package.MeshyMossratHuntTemplate:GetAttribute("MeshyVisualYawDegrees")==180)
assert(backup.MeshyMossratHuntTemplate==hunt and backup.RodeoMonsterTemplate==server and workspace.Airship==ship)
assert(ss.HuntDepartureRecoveryInputs.RecoveryMossratDetailTemplate==detail)
local restored=package.MeshyMossratHuntTemplate
assert(restored.Body.CFrame.angle==180 and hunt.Body.CFrame.angle==0)
repair.apply()
assert(package.MeshyMossratHuntTemplate==restored and package.VisualTemplate.Body.MeshId=="approved-10k")
assert(restored.Body.CFrame.angle==180)
print("HUNT_TEMPLATE_REPAIR_PASS: backup-only hierarchy, missing detail preflight, 10k detail preservation, idempotence, unchanged airship/backups")
'''
path=R/'.tools/hunt_template_repair.luau'
path.write_text(prefix+(R/'src/authoring/HuntTemplateRepair.luau').read_text(encoding='utf-8')+suffix,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(path.relative_to(R))],cwd=R,check=True)
