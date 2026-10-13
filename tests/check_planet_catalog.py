from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1]
expected='GreenStar Zephyrus Floareef Cryo Iris Phyto Solaris Mechanica Celestia Overgrown Soultan Nuclear Stalline Abyss Neon Chronos Wasteland Vortex Gargantua'.split()
s=(R/'src/shared/PlanetCatalog.luau').read_text(encoding='utf8')
assert re.findall(r'"([^"]+)"',re.search(r'Order=\{([^}]+)',s)[1])==expected
for row in json.loads((R/'assets/ui/Planets/manifest.json').read_text()):
    assert hashlib.sha256((R/'assets/ui/Planets'/row['file']).read_bytes()).hexdigest()==row['sha256']
    assert f'rbxassetid://{row["imageId"]}' in s
for p in ['src/shared/PlanetCatalog.luau','src/client/JournalUI.luau','src/client/RocketDeparture.client.luau']:
    subprocess.run([str(R/'.tools/luau/luau-compile.exe'),p],cwd=R,check=True,stdout=subprocess.DEVNULL)
catalog=s.replace('require(script.Parent.CourseGeometry)','{LengthMeters=2000}')
rules=(R/'src/shared/TravelRules.luau').read_text(encoding='utf8')
h='local P=(function()\n'+catalog+'\nend)()\nlocal R=(function()\n'+rules+'\nend)()\n'+'''
assert(#P.Order==19 and P.GreenStar.Available and P.GreenStar.LengthMeters==2000)
for i,id in ipairs(P.Order) do
 assert(P[id].Image~="")
 if i>1 then
  assert(not P[id].Available)
  assert(not R.unlocks(P.Order,{[P.Order[i-1]]=9999})[id])
  assert(R.unlocks(P.Order,{[P.Order[i-1]]=10000})[id])
 end
end
assert(not table.find(P.Order,"Cherry"))
print("PLANET_CATALOG_PASS: 19 ordered planets, 18 distance boundaries, unpublished hunts blocked")
'''
p=R/'.tools/planet_catalog_test.luau';p.write_text(h,encoding='utf8')
subprocess.run([str(R/'.tools/luau/luau.exe'),'.tools/planet_catalog_test.luau'],cwd=R,check=True)
print('16 original images match SHA256; changed Luau compiles')
