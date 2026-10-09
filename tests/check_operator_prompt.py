"""Run the real prompt controller: masked input, clearing, single submit, cancel."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parents[1]
code=r'''
local nodes={}
local function signal()
 local s={callbacks={}} function s:Connect(fn) self.callbacks[#self.callbacks+1]=fn end
 function s:fire(...) for _,fn in ipairs(self.callbacks) do fn(...) end end return s
end
local Instance={new=function(class)
 local props={ClassName=class};local signals={}
 local node=setmetatable({Activated=signal(),FocusLost=signal()},{__index=props,__newindex=function(_,k,v) props[k]=v if signals[k] then signals[k]:fire() end end})
 function node:GetPropertyChangedSignal(k) signals[k]=signals[k] or signal() return signals[k] end
 function node:CaptureFocus() props.focused=true end
 function node:ReleaseFocus() props.focused=false self.FocusLost:fire(false) end
 nodes[#nodes+1]=node return node
end}
local Vector2={new=function(...) return {...} end}
local UDim={new=function(...) return {...} end}
local UDim2={new=function(...) return {...} end,fromScale=function(...) return {...} end,fromOffset=function(...) return {...} end}
local Color3={new=function(...) return {...} end,fromRGB=function(...) return {...} end}
local Enum={Font={GothamMedium=1,Gotham=2,GothamBold=3},TextXAlignment={Left=1}}
local remote={OnClientEvent=signal(),sent={}}
function remote:FireServer(action,value) self.sent[#self.sent+1]={action=action,value=value} end
local module=(function()
'''+(R/'src/client/OperatorPrompt.luau').read_text(encoding='utf-8')+r'''
end)()
local gui=module.new({},remote)
local field,mask,confirm,cancel
for _,node in ipairs(nodes) do if node.Name=='Password' then field=node elseif node.Text=='확인' then confirm=node elseif node.Text=='닫기' then cancel=node end end
for _,node in ipairs(nodes) do if node.Parent==field and node.ClassName=='TextLabel' then mask=node end end
assert(field.TextTransparency==1 and not gui.Enabled)
remote.OnClientEvent:fire('OperatorPrompt',{token='nonce',description='test'})
field.Text='dummy-password' assert(not mask.Text:find('dummy',1,true))
confirm.Activated:fire() assert(#remote.sent==1 and remote.sent[1].action=='OperatorVerify' and remote.sent[1].value.token=='nonce' and remote.sent[1].value.password=='dummy-password')
assert(field.Text=='' and not field.focused,'input must be cleared immediately')
confirm.Activated:fire() assert(#remote.sent==1,'double click must not submit again')
remote.OnClientEvent:fire('OperatorResult',{ok=false,retry=true,message='wrong'})
field.Text='retry-password' field.FocusLost:fire(true) assert(#remote.sent==2 and field.Text=='')
remote.OnClientEvent:fire('OperatorResult',{ok=true,message='done'})
field.Text='ignored' confirm.Activated:fire() assert(#remote.sent==2,'successful authentication never persists for another command')
remote.OnClientEvent:fire('OperatorPrompt',{token='next',description='test'})
cancel.Activated:fire() assert(remote.sent[3].action=='OperatorCancel' and remote.sent[3].value=='next' and not gui.Enabled and field.Text=='')
print('OPERATOR_PROMPT_PASS: masked input, immediate clearing, click/Enter, duplicate submit suppression, per-command confirmation and cancel; UI stubs only')
'''
p=R/'.tools/check_operator_prompt.luau';p.write_text(code,encoding='utf-8')
subprocess.run([str(R/'.tools/luau/luau.exe'),str(p.relative_to(R))],cwd=R,check=True)
