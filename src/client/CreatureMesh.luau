-- Only approved user-supplied models; no legacy generated creature fallback.
local Native=require(script.Parent:WaitForChild("NativeMossrat"))
local M={ready=true,failed=false}
function M.prepare() end
function M.materialize(model) if Native.isTarget(model) then Native.apply(model) end end
function M.decorate(model) M.materialize(model) end
function M.animate(model,phase,moving,angry) Native.animate(model,phase,moving,angry) end
function M.huntFrame(model,frame) return Native.huntFrame(model,frame) end
return M
