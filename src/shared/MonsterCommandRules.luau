-- Resolve commands from the active catalog, including localized display names.
local M={}
function M.help(catalog,names)
 local available={}
 for _,id in ipairs(catalog.Order) do
  table.insert(available,(names[id] and names[id].en) or id)
 end
 return "Commands: /monster <"..table.concat(available," | ").."> <stars 1-10> [count 1-10]"
end
function M.parse(text,catalog,names)
 local parts={}
 for word in string.gmatch(text,"%S+") do table.insert(parts,word) end
 if string.lower(parts[1] or "")=="/operator" then return {help=true} end
 if string.lower(parts[1] or "")~="/monster" then return nil end
 local species=string.lower(parts[2] or "")
 local id
 for _,candidate in ipairs(catalog.Order) do
  if species==string.lower(candidate) then id=candidate break end
  for _,name in pairs(names[candidate] or {}) do
   if species==string.lower(name) then id=candidate break end
  end
  if id then break end
 end
 local stars,count=tonumber(parts[3]),tonumber(parts[4] or "1")
 if not id or not stars or stars%1~=0 or stars<1 or stars>10
  or not count or count%1~=0 or count<1 or count>10 or #parts>4 then return {invalid=true} end
 return {id=id,stars=stars,count=count}
end
return M
