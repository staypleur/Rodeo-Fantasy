-- Server-authoritative selection, independent of model import and UI layout.
local Service={}
local Rules=require(game:GetService("ReplicatedStorage").RodeoFantasy.DepartureSelectionRules)
function Service.new(ctx)
 local pending,lastSubmit={},{}
 local api={}
 local function result(player,ok,reason)
  ctx.send(player,"DepartureResult",{ok=ok,reason=reason})
 end
 function api.open(player)
  if not ctx.canOpen(player) then return false end
  local bag=ctx.bag(player)
  if not bag then return false end
  local token=ctx.token()
  pending[player]={token=token,expires=ctx.now()+60}
  local items={}
  for _,item in ipairs(bag.monsters or {}) do
   local owned,reason=Rules.validate(bag,"GreenStar",item.id,ctx.catalog,ctx.modelReady)
   table.insert(items,{id=item.id,monsterId=item.monsterId,stars=item.stars or 1,
    ready=owned~=nil,reason=reason})
  end
  ctx.send(player,"DepartureMenu",{token=token,items=items,planet="GreenStar",name="Green Star",lengthMeters=1000})
  return true
 end
 function api.submit(player,value)
  if type(value)~="table" then return false end
  if ctx.now()-(lastSubmit[player] or -math.huge)<.5 then return false end
  lastSubmit[player]=ctx.now()
  local menu=pending[player]
  if not menu or value.token~=menu.token or ctx.now()>menu.expires then
   result(player,false,"MenuExpired") return false
  end
  if not ctx.canOpen(player) then result(player,false,"ApproachRocket") return false end
  local item,reason=Rules.validate(ctx.bag(player),value.planet,value.itemId,ctx.catalog,ctx.modelReady)
  if not item then result(player,false,reason) return false end
  if not ctx.courseReady() then result(player,false,"CoursePending") return false end
  -- Revalidate the live bag immediately before launch, and consume the menu
  -- only after a successful hunt creation. A failed launch can be retried.
  local ok=ctx.launch(player,item.id)==true
  if ok then pending[player]=nil end
  result(player,ok,ok and nil or "LaunchFailed")
  return ok
 end
 function api.cancel(player) pending[player]=nil end
 function api.remove(player) pending[player],lastSubmit[player]=nil,nil end
 return api
end
return Service
