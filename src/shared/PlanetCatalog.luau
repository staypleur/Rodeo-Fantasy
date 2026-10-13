-- User-approved order and artwork. Only Green Star has a playable hunt course.
local Course=require(script.Parent.CourseGeometry)
local P={Order={"GreenStar","Zephyrus","Floareef","Cryo","Iris","Phyto","Solaris","Mechanica","Celestia","Overgrown","Soultan","Nuclear","Stalline","Abyss","Neon","Chronos","Wasteland","Vortex","Gargantua"},
 GreenStar={Name="Green Star",Description="숲 초원 행성",Image="rbxassetid://138744590770196",Available=true,LengthMeters=Course.LengthMeters},
 Zephyrus={Name="Zephyrus",Description="사막 모래 폭풍 행성",Image="rbxassetid://109972305275318",Available=false},
 Floareef={Name="Floareef",Description="바다, 해초, 해파리, 산호 행성",Image="rbxassetid://132856159980542",Available=false},
 Cryo={Name="Cryo",Description="빙하, 얼어붙은 별, 영혼 에너지가 갇힌 행성",Image="rbxassetid://137343730723244",Available=false},
 Iris={Name="Iris",Description="무지개빛 유리, 보석 지형 행성",Image="rbxassetid://134345029159213",Available=false},
 Phyto={Name="Phyto",Description="벌레, 파리지옥, 버섯 행성",Image="rbxassetid://110070555355468",Available=false},
 Solaris={Name="Solaris",Description="하얀 마그마, 주황 태양풍, 극한 열기 행성",Image="rbxassetid://132429133902459",Available=false},
 Mechanica={Name="Mechanica",Description="거대한 기계와 파이프라인 행성",Image="rbxassetid://109682350665982",Available=false},
 Celestia={Name="Celestia",Description="보라색 안개, 부유하는 암석 행성",Image="rbxassetid://93669217728731",Available=false},
 Overgrown={Name="Overgrown",Description="이끼 낀 오래된 고대 기계, 자연 마도공학 행성",Image="rbxassetid://90442953407793",Available=false},
 Soultan={Name="Soultan",Description="서리오라, 주황·푸른 영혼 불꽃 설원 행성",Image="rbxassetid://129197246489405",Available=false},
 Nuclear={Name="Nuclear",Description="녹색 오염, 방사능, 일그러진 시공간 행성",Image="rbxassetid://70732990890234",Available=false},
 Stalline={Name="Stalline",Description="용암, 빛나는 용암 결정, 화산 행성",Image="rbxassetid://138868303166132",Available=false},
 Abyss={Name="Abyss",Description="암흑물질, 공허의 빛 행성",Image="rbxassetid://99659267680487",Available=false},
 Neon={Name="Neon",Description="네온 전선, 미래도시 구조물 행성",Image="rbxassetid://114563861855074",Available=false},
 Chronos={Name="Chronos",Description="과거의 고대문명, 황금빛, 시간오류 행성",Image="rbxassetid://88252375899235",Available=false},
 Wasteland={Name="Wasteland",Description="환각, 보라 버섯포자, 사막 황무지 행성",Image="rbxassetid://130292428150726",Available=false},
 Vortex={Name="Vortex",Description="푸른·보라 가스, 심연, 표면 없음, 플라즈마 폭풍 행성",Image="rbxassetid://113610760687152",Available=false},
 Gargantua={Name="Gargantua",Description="유황, 중금속, 강한 중력, 현무암 지형, 붉은 유황호수, 금곡 결정체 행성",Image="rbxassetid://76365437870859",Available=false},
 -- Reserved artwork: no selection position was specified for Cherry.
 Cherry={Name="Cherry",Image="rbxassetid://135408549566412",Available=false},
}
return P
