"""Cute brick-built Charmander based on the user's Roblox pet references. Forward is -Z."""
ORANGE = (250, 155, 65)
CREAM = (255, 231, 177)
DARK = (43, 38, 47)
BLUE = (58, 151, 174)


def components():
    result = []

    def add(name, pos, size, color=ORANGE, rotation=(0, 0, 0), flame=False, neon=False, studs=True):
        result.append(dict(name=name, position=pos, size=size, color=color,
                           shape="Block", rotation=rotation, flame=flame, neon=neon, studs=studs))

    # Stepped bricks soften the silhouette without using round meshes.
    add("Body", (0, 0.05, 0), (2.25, 2.3, 1.85))
    add("Shoulders", (0, 0.91, -0.03), (2.48, 0.55, 1.7))
    add("Belly", (0, -0.05, -0.96), (1.55, 1.75, 0.14), CREAM)
    add("BellyTop", (0, 0.94, -0.91), (1.1, 0.25, 0.15), CREAM)
    add("BellyBottom", (0, -0.99, -0.96), (1.12, 0.23, 0.14), CREAM)
    add("Neck", (0, 1.25, -0.2), (1.65, 0.55, 1.4))
    add("Head", (0, 2.15, -0.45), (2.85, 2.05, 2.4))
    add("HeadCrown", (0, 3.28, -0.45), (2.38, 0.26, 2.05))
    add("Cheeks", (0, 1.39, -0.53), (2.98, 0.62, 2.12))
    add("Muzzle", (0, 1.61, -1.78), (1.92, 0.68, 0.7))
    add("Chin", (0, 1.24, -1.75), (1.52, 0.19, 0.6), CREAM)
    add("Mouth", (0, 1.44, -2.14), (0.76, 0.07, 0.04), DARK, studs=False)
    for side, sign in (("Left", -1), ("Right", 1)):
        # Bright rectangular eyes and white highlights stay legible at a distance.
        add(side+"EyeWhite", (sign*0.85, 2.42, -1.675), (0.72, 0.97, 0.075), (255,255,249), studs=False)
        add(side+"Iris", (sign*0.80, 2.40, -1.725), (0.49, 0.78, 0.04), BLUE, studs=False)
        add(side+"Pupil", (sign*0.78, 2.45, -1.755), (0.32, 0.66, 0.035), DARK, studs=False)
        add(side+"Shine", (sign*0.72, 2.66, -1.782), (0.17, 0.22, 0.025), (255,255,255), studs=False)
        add(side+"Nostril", (sign*0.37, 1.82, -2.14), (0.09,0.07,0.035), DARK, studs=False)
        add(side+"SmileCorner", (sign*0.41, 1.49, -2.14), (0.07,0.12,0.04), DARK, studs=False)
        add(side+"Arm", (sign*1.36, 0.47, -0.23), (0.54,0.97,0.65), rotation=(0,0,sign*10))
        add(side+"Hand", (sign*1.45, -0.05, -0.47), (0.64,0.4,0.75))
        add(side+"Leg", (sign*0.84, -1.05, 0.03), (0.94,1.02,1.08))
        add(side+"Paw", (sign*0.89, -1.67, -0.37), (1.02,0.48,1.4))
        for toe in range(3):
            add(side+"Claw"+str(toe), (sign*0.89+(toe-1)*0.25,-1.68,-1.13), (0.18,0.17,0.18), (255,250,233), studs=False)
    # The segmented raised tail preserves the recognizable silhouette from above.
    add("TailSegment0", (0,-0.48,1.17), (1.05,0.9,1.05))
    add("TailSegment1", (0,-0.5,2.0), (0.79,0.65,1.0))
    add("TailSegment2", (0,-0.16,2.7), (0.59,0.8,0.75))
    add("TailSegment3", (0,0.46,3.12), (0.42,0.8,0.55))
    add("TailFlame", (0,1.08,3.12), (0.88,0.67,0.64), (255,122,38), flame=True, neon=True, studs=False)
    add("TailFlameTip", (0.15,1.62,3.13), (0.38,0.46,0.4), (255,152,41), neon=True, studs=False)
    add("TailFlameCore", (0,1.03,2.78), (0.45,0.44,0.04), (255,236,105), neon=True, studs=False)
    return result
