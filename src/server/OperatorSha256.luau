-- SHA-256 for the server-private salted password verifier.
local K={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
local b=bit32 local mod=4294967296
local function word(n) return string.char(b.band(b.rshift(n,24),255),b.band(b.rshift(n,16),255),b.band(b.rshift(n,8),255),b.band(n,255)) end
return function(text)
 local length=#text
 text=text..string.char(128)..string.rep('\0',(55-length)%64)..word(math.floor(length/536870912))..word((length*8)%mod)
 local h={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
 for offset=1,#text,64 do
  local w={}
  for i=0,15 do local a,c,d,e=string.byte(text,offset+i*4,offset+i*4+3) w[i+1]=a*16777216+c*65536+d*256+e end
  for i=17,64 do
   local x,y=w[i-15],w[i-2]
   local s0=b.bxor(b.rrotate(x,7),b.rrotate(x,18),b.rshift(x,3))
   local s1=b.bxor(b.rrotate(y,17),b.rrotate(y,19),b.rshift(y,10))
   w[i]=(w[i-16]+s0+w[i-7]+s1)%mod
  end
  local a,c,d,e,f,g,j,k=table.unpack(h)
  for i=1,64 do
   local s1=b.bxor(b.rrotate(f,6),b.rrotate(f,11),b.rrotate(f,25))
   local choose=b.bxor(b.band(f,g),b.band(b.bnot(f),j))
   local t1=(k+s1+choose+K[i]+w[i])%mod
   local s0=b.bxor(b.rrotate(a,2),b.rrotate(a,13),b.rrotate(a,22))
   local majority=b.bxor(b.band(a,c),b.band(a,d),b.band(c,d))
   local t2=(s0+majority)%mod
   k,j,g,f,e,d,c,a=j,g,f,(e+t1)%mod,d,c,a,(t1+t2)%mod
  end
  for i,v in ipairs({a,c,d,e,f,g,j,k}) do h[i]=(h[i]+v)%mod end
 end
 local out={} for i,v in ipairs(h) do out[i]=string.format('%08x',v) end
 return table.concat(out)
end
