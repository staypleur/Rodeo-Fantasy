"""Editable Roblox-native geometry for the user-selected Emberrat B base form.

Local origin is the old mount root. Forward is -Z. All shapes move together
through Model:PivotTo; no uploaded mesh/texture or third-party asset is needed.
"""
import math

RUSSET = (175, 77, 36)
LIGHT_RUSSET = (205, 105, 48)
DARK_RUSSET = (123, 52, 28)
CREAM = (255, 218, 157)
EAR_PINK = (239, 145, 94)
ORANGE = (255, 137, 34)
GOLD = (242, 170, 47)
BLACK = (39, 24, 22)
FLAME_YELLOW = (255, 230, 81)


def components():
    result = []

    def add(name, pos, size, color, shape="Sphere", rotation=(0, 0, 0), flame=False, neon=False):
        result.append(dict(name=name, position=pos, size=size, color=color,
                           shape=shape, rotation=rotation, flame=flame, neon=neon))

    add("Body", (0, 0, 0.1), (2.55, 2.15, 4.65), RUSSET)
    add("Belly", (0, -0.57, -0.1), (2.10, 1.10, 3.65), CREAM)
    add("Shoulders", (0, 0.12, -1.32), (2.05, 2.10, 1.95), LIGHT_RUSSET)
    add("Chest", (0, -0.28, -1.93), (1.35, 1.48, 0.48), CREAM, rotation=(-12, 0, 0))
    add("Head", (0, 0.74, -2.15), (1.98, 1.72, 2.12), LIGHT_RUSSET)
    add("Muzzle", (0, 0.31, -3.03), (1.45, 0.85, 1.23), CREAM)
    add("Nose", (0, 0.56, -3.62), (0.42, 0.28, 0.28), (119, 48, 34))
    add("Chin", (0, 0.04, -2.96), (1.07, 0.45, 0.95), CREAM)

    for side, sign in (("Left", -1), ("Right", 1)):
        add(side + "Ear", (sign * 1.05, 2.02, -1.98), (1.66, 2.05, 0.42), LIGHT_RUSSET,
            rotation=(8, 0, -sign * 16))
        add(side + "InnerEar", (sign * 1.05, 2.04, -2.19), (1.29, 1.61, 0.11), EAR_PINK,
            rotation=(8, 0, -sign * 16))
        add(side + "Cheek", (sign * 0.56, 0.39, -2.98), (0.77, 0.73, 0.92), CREAM)
        add(side + "EyeRim", (sign * 0.78, 1.11, -2.69), (0.76, 0.89, 0.45), DARK_RUSSET)
        add(side + "EyeWhite", (sign * 0.81, 1.13, -2.86), (0.59, 0.72, 0.27), CREAM)
        add(side + "Iris", (sign * 0.83, 1.13, -3.00), (0.44, 0.60, 0.18), GOLD)
        add(side + "Pupil", (sign * 0.82, 1.13, -3.095), (0.27, 0.46, 0.10), BLACK)
        add(side + "EyeShine", (sign * 0.78, 1.28, -3.15), (0.12, 0.14, 0.045), (255, 255, 247))
        add(side + "Brow", (sign * 0.77, 1.58, -2.77), (0.71, 0.18, 0.24), DARK_RUSSET,
            rotation=(0, 0, sign * 10))
        for leg, z in (("Front", -1.25), ("Back", 1.45)):
            add(side + leg + "Leg", (sign * 0.87, -0.95, z), (0.75, 1.37, 0.82), RUSSET,
                rotation=(12 if leg == "Front" else -18, 0, sign * 6))
            add(side + leg + "Paw", (sign * 0.94, -1.67, z - 0.12), (0.77, 0.49, 0.99), CREAM)
            for toe in range(3):
                add(side + leg + "Toe" + str(toe),
                    (sign * 0.94 + (toe - 1) * 0.19, -1.69, z - 0.52),
                    (0.16, 0.18, 0.19), (235, 186, 123))
        add(side + "Haunch", (sign * 0.97, -0.31, 1.43), (1.22, 1.61, 1.54), RUSSET)
        for index, (y, z) in enumerate(((0.55, 0.95), (0.18, 1.52))):
            add(side + "EmberMark" + str(index), (sign * 1.23, y, z),
                (0.07, 0.36, 0.43), ORANGE, shape="Block", rotation=(45, 0, 0))
        add(side + "RearTuft", (sign * 0.7, 0.96, 1.65), (0.44, 0.65, 0.89), LIGHT_RUSSET,
            shape="Wedge", rotation=(-25, sign * 15, 0))

    # A compact swept-back head tuft keeps the middle of the back clear for a rider.
    for index, (x, height, z) in enumerate(((-0.35, 0.62, -1.9), (0, 0.9, -1.8), (0.34, 0.55, -1.65))):
        add("HeadTuft" + str(index), (x, 1.82, z), (0.43, height, 0.66),
            ORANGE if index == 1 else LIGHT_RUSSET, shape="Wedge", rotation=(-25, 0, index * 8 - 8))

    points = [(0, -0.25, 2.04), (0.22, -0.15, 2.68), (0.54, 0.10, 3.30),
              (0.83, 0.52, 3.87), (1.01, 1.10, 4.20), (1.04, 1.73, 4.32),
              (0.95, 2.31, 4.34)]
    for index, (start, end) in enumerate(zip(points, points[1:])):
        dx, dy, dz = (end[i] - start[i] for i in range(3))
        length = math.sqrt(dx * dx + dy * dy + dz * dz)
        radius = 0.44 - index * 0.043
        center = tuple((start[i] + end[i]) / 2 for i in range(3))
        # Orient the long Y axis along the curved tail segment.
        pitch = math.degrees(math.acos(dy / length))
        yaw = math.degrees(math.atan2(dx, dz))
        add("TailSegment" + str(index), center, (radius, length + radius * 0.85, radius),
            RUSSET if index < 4 else LIGHT_RUSSET, rotation=(pitch, yaw, 0))

    for name, pos, size in (("TailFlame", (0.95, 2.66, 4.34), (0.43, 0.94, 0.38)),
                            ("HeadFlame", (0, 2.23, -1.87), (0.29, 0.62, 0.25))):
        add(name, pos, size, ORANGE, shape="Wedge", rotation=(0, 30, -12), flame=True, neon=True)
        add(name + "Core", (pos[0], pos[1] - 0.10, pos[2] - 0.08),
            tuple(v * 0.57 for v in size), FLAME_YELLOW, shape="Wedge",
            rotation=(0, 30, -12), neon=True)
    return result
