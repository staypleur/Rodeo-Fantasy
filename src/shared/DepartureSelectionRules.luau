-- Server-side validation for the upcoming planet -> owned mount flow.
-- Returns the owned item, never accepts client monster stats or wild models.
local Rules={}
function Rules.validate(bag,destinationId,itemId,catalog,availableModels)
 if destinationId~="GreenStar" then return nil,"UnknownDestination" end
 if type(itemId)~="number" or itemId~=itemId or itemId%1~=0 then return nil,"InvalidMonster" end
 if type(bag)~="table" or type(bag.monsters)~="table" then return nil,"InventoryUnavailable" end
 for _,item in ipairs(bag.monsters) do
  if item.id==itemId then
   if item.breedingTeam or item.tradeLock then return nil,"MonsterBusy" end
   if not catalog[item.monsterId] then return nil,"UnknownSpecies" end
   if not availableModels(item.monsterId,item.stars or 1) then return nil,"ModelPending" end
   return item
  end
 end
 return nil,"NotOwned"
end
return Rules
