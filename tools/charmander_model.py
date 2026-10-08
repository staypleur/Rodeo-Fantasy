"""Editable, Roblox-native Charmander test model. Forward is -Z."""
import math

ORANGE = (244, 143, 55)
CREAM = (255, 225, 164)
DARK = (58, 45, 38)
BLUE = (61, 139, 151)

def components():
    result = []
    def add(name, pos, size, color, shape="Sphere", rotation=(0, 0, 0), flame=False, neon=False):
        result.append(dict(name=name, position=pos, size=size, color=color,
                           shape=shape, rotation=rotation, flame=flame, neon=neon))
    add("Body", (0, 0.15, 0), (2.5, 3.0, 2.3), ORANGE)
    add("Belly", (0, -0.15, -1.01), (1.87, 2.1, 0.44), CREAM)
    add("Neck", (0, 1.34, -0.2), (1.75, 1.35, 1.65), ORANGE)
    add("Head", (0, 2.15, -0.62), (2.64, 2.16, 2.55), ORANGE)
    add("Muzzle", (0, 1.88, -1.74), (2.06, 0.87, 0.96), ORANGE)
    add("Chin", (0, 1.54, -1.62), (1.77, 0.43, 0.69), CREAM)
    add("Mouth", (0, 1.64, -2.16), (1.15, 0.05, 0.06), DARK, "Block")
    for side, sign in (("Left", -1), ("Right", 1)):
        add(side+"EyeWhite", (sign*0.82, 2.48, -1.65), (0.67, 0.87, 0.29), (255,255,247))
        add(side+"Iris", (sign*0.80, 2.47, -1.80), (0.42, 0.70, 0.16), BLUE)
        add(side+"Pupil", (sign*0.81, 2.47, -1.9), (0.21, 0.56, 0.08), DARK)
        add(side+"Shine", (sign*0.75, 2.67, -1.96), (0.12, 0.18, 0.03), (255,255,255))
        add(side+"Nostril", (sign*0.38, 2.13, -2.20), (0.11,0.07,0.07), DARK)
        add(side+"Arm", (sign*1.28, 0.57, -0.63), (0.65,1.46,0.72), ORANGE, rotation=(20,0,sign*25))
        add(side+"Hand", (sign*1.62, -0.08, -0.94), (0.72,0.58,0.62), ORANGE)
        add(side+"Leg", (sign*0.84, -1.06, 0.03), (1.04,1.31,1.15), ORANGE)
        add(side+"Paw", (sign*0.93, -1.71, -0.44), (1.02,0.51,1.45), ORANGE)
        for toe in range(3):
            add(side+"Claw"+str(toe), (sign*0.93+(toe-1)*0.23,-1.73,-1.07), (0.18,0.18,0.39), (255,250,233))
    points=[(0,-0.45,0.95),(0,-0.72,1.83),(0,-0.45,2.66),(0,0.15,3.32),(0,0.88,3.66)]
    for i,(start,end) in enumerate(zip(points,points[1:])):
        dx,dy,dz=(end[k]-start[k] for k in range(3))
        length=math.sqrt(dx*dx+dy*dy+dz*dz)
        width=1.12-i*0.22
        center=tuple((start[k]+end[k])/2 for k in range(3))
        add("TailSegment"+str(i),center,(width,length+width*0.5,width),ORANGE,
            rotation=(math.degrees(math.acos(dy/length)),math.degrees(math.atan2(dx,dz)),0))
    add("TailFlame",(0,1.49,3.67),(0.81,1.37,0.65),(255,110,26),"Wedge",(0,20,-8),True,True)
    add("TailFlameCore",(0,1.18,3.51),(0.45,0.89,0.37),(255,227,74),"Wedge",(0,20,-8),neon=True)
    return result
