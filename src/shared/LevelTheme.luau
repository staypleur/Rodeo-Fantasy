-- User-approved level bands. The number and account name share one framed plaque.
local T={
 {name="Bronze",min=1,edge={155,83,47},metal={209,132,76},paper={255,218,180},ink={74,39,28}},
 {name="Earth",min=100,edge={89,68,44},metal={157,126,83},paper={232,214,168},ink={66,48,30}},
 {name="Silver",min=200,edge={77,91,113},metal={158,176,198},paper={232,240,250},ink={44,56,74}},
 {name="Gold",min=300,edge={164,98,21},metal={240,177,53},paper={255,237,156},ink={89,54,18}},
 {name="Diamond",min=400,edge={43,111,147},metal={107,207,226},paper={210,252,255},ink={25,79,102}},
 {name="Obsidian",min=500,edge={28,26,35},metal={94,91,108},paper={58,56,69},ink={242,232,255}},
 {name="Emerald",min=600,edge={19,99,76},metal={57,183,127},paper={179,244,208},ink={17,76,55}},
 {name="Ruby",min=700,edge={122,27,55},metal={220,68,98},paper={255,198,207},ink={106,22,46}},
 {name="Cosmos",min=800,edge={50,29,100},metal={127,85,199},paper={57,38,98},ink={240,225,255}},
 {name="Angel",min=900,edge={135,157,184},metal={224,234,249},paper={255,252,239},ink={69,92,130}},
 {name="Rainbow",min=1000,edge={95,63,158},metal={255,231,171},paper={255,255,249},ink={76,48,115}},
}
function T.forLevel(level)
 for i=#T,1,-1 do if level>=T[i].min then return T[i],i end end
 return T[1],1
end
return T
