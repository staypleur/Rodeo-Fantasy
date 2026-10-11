-- Free gomoku: 15 intersections, no forbidden moves, five or more wins.
local G={Size=15}
function G.new() return {cells={},turn=1,moves=0,winner=nil} end
function G.move(board,colour,x,y)
 if board.winner~=nil or colour~=board.turn then return false end
 if type(x)~="number" or type(y)~="number" or x%1~=0 or y%1~=0 or x<1 or x>15 or y<1 or y>15 then return false end
 local index=(y-1)*15+x
 if board.cells[index] then return false end
 board.cells[index]=colour board.moves+=1
 for _,direction in ipairs({{1,0},{0,1},{1,1},{1,-1}}) do
  local count=1
  for _,sign in ipairs({-1,1}) do
   local a,b=x+direction[1]*sign,y+direction[2]*sign
   while a>=1 and a<=15 and b>=1 and b<=15 and board.cells[(b-1)*15+a]==colour do
    count+=1 a+=direction[1]*sign b+=direction[2]*sign
   end
  end
  if count>=5 then board.winner=colour break end
 end
 if not board.winner and board.moves==225 then board.winner=0 end
 board.turn=3-colour
 return true
end
return G
