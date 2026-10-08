"""Original Lumidon: a cute brick baby boar carrying a little lantern. Forward is -Z."""
BODY = (155, 181, 159)
EAR = (115, 145, 125)
PINK = (247, 185, 173)
CREAM = (255, 233, 188)
DARK = (54, 53, 58)


def components():
    result = []
    def add(name, pos, size, color=BODY, rotation=(0,0,0), neon=False, studs=True, glow=False):
        result.append(dict(name=name, position=pos, size=size, color=color,
                          shape="Block", rotation=rotation, neon=neon, studs=studs, glow=glow))
    add("Body", (0,-0.05,0.15), (2.35,1.9,3.0))
    add("Back", (0,0.99,0.22), (2.05,0.3,2.45))
    add("Belly", (0,-1.03,0.05), (1.85,0.2,2.45), CREAM)
    add("Head", (0,0.35,-1.52), (2.4,1.65,1.45))
    add("HeadCrown", (0,1.26,-1.46), (1.95,0.2,1.15))
    add("Snout", (0,-0.02,-2.41), (1.58,0.83,0.52), PINK)
    add("NoseTop", (0,0.45,-2.32), (1.32,0.12,0.37), PINK)
    add("Smile", (0,-0.32,-2.685), (0.55,0.055,0.025), DARK, studs=False)
    for side,sign in (("Left",-1),("Right",1)):
        add(side+"Ear", (sign*0.87,1.57,-1.21), (0.62,0.62,0.38), EAR, rotation=(0,0,sign*-15))
        add(side+"EarInner", (sign*0.87,1.57,-1.42), (0.34,0.37,0.045), PINK, rotation=(0,0,sign*-15), studs=False)
        add(side+"EyeWhite", (sign*0.83,0.61,-2.265), (0.48,0.65,0.06), (255,255,249), studs=False)
        add(side+"Pupil", (sign*0.81,0.61,-2.307), (0.32,0.49,0.045), DARK, studs=False)
        add(side+"Shine", (sign*0.75,0.75,-2.339), (0.12,0.15,0.025), (255,255,255), studs=False)
        add(side+"Nostril", (sign*0.35,0.02,-2.685), (0.15,0.22,0.025), (144,95,93), studs=False)
        add(side+"Cheek", (sign*1.0,0.02,-2.275), (0.29,0.2,0.03), PINK, studs=False)
        for location,z in (("Front",-0.91),("Back",1.17)):
            add(side+location+"Leg", (sign*0.88,-1.28,z), (0.61,0.82,0.67))
            add(side+location+"Paw", (sign*0.88,-1.8,z-0.1), (0.73,0.24,0.84), CREAM)
            add(side+location+"HoofLine", (sign*0.88,-1.8,z-0.53), (0.035,0.17,0.02), EAR, studs=False)
    add("TailBase", (0,-0.1,1.92), (0.36,0.35,0.69))
    add("TailCurl", (0.2,0.13,2.24), (0.62,0.28,0.3))
    add("TailTip", (0.45,-0.08,2.24), (0.24,0.44,0.3))
    # Distinctive lantern on the back, with no flame tail or borrowed character silhouette.
    brass=(152,114,69)
    add("LanternSaddle", (0,1.21,0.74), (1.18,0.18,1.15), brass)
    add("LanternBase", (0,1.43,0.74), (0.8,0.19,0.8), brass)
    add("LanternGlow", (0,1.88,0.74), (0.61,0.74,0.61), (255,219,115), neon=True, studs=False, glow=True)
    for x in (-0.36,0.36):
        for z in (0.38,1.1):
            add("LanternPost"+str(x)+str(z), (x,1.88,z), (0.09,0.8,0.09), brass, studs=False)
    add("LanternRoof", (0,2.36,0.74), (0.95,0.17,0.95), brass)
    add("LanternCap", (0,2.5,0.74), (0.47,0.13,0.47), brass)
    return result
