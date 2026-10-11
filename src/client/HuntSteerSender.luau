local S={}
function S.new(send)
 local last,value,retry=-math.huge,nil,false
 return function(nextValue,clock,edge)
  if edge or clock-last>=.05 and (retry or value==nil or math.abs(nextValue-value)>.015 or clock-last>=.2) then
   send(nextValue) last,value,retry=clock,nextValue,edge==true
   return true
  end
  return false
 end
end
return S
