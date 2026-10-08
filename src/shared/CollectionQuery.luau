local Q={}
function Q.regions(catalog)
 local regions={"All","Breeding"} local known={All=true,Breeding=true}
 for _,id in ipairs(catalog.Order) do
  local region=catalog[id].Region or "Meadow"
  if not known[region] then known[region]=true table.insert(regions,2,region) end
 end
 return regions
end
function Q.filter(items,catalog,region,search,name)
 local result={} search=string.lower(search or "")
 for _,item in ipairs(items) do
  local species=catalog[item.monsterId]
  if species and (region=="All" or (species.Region or "Meadow")==region) then
   local text=string.lower((name and name(item.monsterId) or item.monsterId).." "..item.monsterId)
   if search=="" or string.find(text,search,1,true) then table.insert(result,item) end
  end
 end
 return result
end
function Q.entries(catalog)
 local entries={}
 for _,id in ipairs(catalog.Order) do
  for _,stars in ipairs({1,3,6,9}) do table.insert(entries,{monsterId=id,stars=stars,key=id..":"..stars}) end
 end
 return entries
end
return Q
