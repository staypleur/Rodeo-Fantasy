-- Green Star keeps the full 192-stud width for its entire 1,000m.
local C={LengthStuds=4800,LayoutScale=3,LengthMeters=1000}
function C.width() return 96 end
function C.median() return 0 end
function C.ranges(z,padding) return {{-96+padding,96-padding}} end
function C.planningRanges(z,horizon,padding) return C.ranges(z,padding) end
function C.contains(x,z,padding) local r=C.ranges(z,padding)[1] return x>r[1] and x<r[2] end
return C
