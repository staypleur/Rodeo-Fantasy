"""Editable native Roblox geometry for the agreed pastel resort lobby."""
import math


def build_lobby(workspace, item, part, prop):
    lobby, _ = item(workspace, "Folder", "RodeoLobby")
    cream, mint, pink = (255, 244, 220), (158, 211, 181), (244, 184, 192)

    def block(parent, name, pos, size, color, rotation=(0, 0, 0), collide=True):
        node, properties = part(parent, name, (6000 + pos[0], pos[1], pos[2]), size, color, rotation=rotation)
        prop(properties, "token", "Material", 272)
        prop(properties, "bool", "CanCollide", collide)
        prop(properties, "bool", "CanTouch", False)
        return node

    def circle(parent, name, pos, radius, height, color):
        node = block(parent, name, pos, (height, radius*2, radius*2), color, (0, 0, 90))
        prop(node.find("Properties"), "token", "shape", 2)
        return node

    def sign(parent, name, pos, words, color=cream, rotation=(0, 0, 0), width=12):
        board = block(parent, name, pos, (width, 4, .4), color, rotation)
        for face in (5, 2):  # Front and Back; readable from both sides.
            gui, gp = item(board, "SurfaceGui", "SignFace" + str(face))
            prop(gp, "token", "Face", face)
            prop(gp, "Vector2", "CanvasSize", dict(X=600, Y=200))
            label, lp = item(gui, "TextLabel", "Text")
            prop(lp, "UDim2", "Size", dict(XS=1, XO=0, YS=1, YO=0))
            prop(lp, "float", "BackgroundTransparency", 1)
            prop(lp, "bool", "TextScaled", True)
            prop(lp, "string", "Text", words)
            prop(lp, "Color3", "TextColor3", dict(R=.19, G=.33, B=.29))
        return board

    block(lobby, "MeadowIsland", (0, -3, -25), (530, 6, 590), (162, 202, 153))
    circle(lobby, "CentralPlaza", (0, .08, 0), 49, .16, cream)
    circle(lobby, "FountainPool", (0, .5, 0), 11, 1, (161, 210, 219))
    circle(lobby, "FountainBowl", (0, 1.5, 0), 6, 1, cream)
    block(lobby, "FountainColumn", (0, 3, 0), (2, 3, 2), (186, 222, 218))
    sign(lobby, "Welcome", (0, 6, 30), "로데오 판타지\n비행장에서 사냥터로 출발", width=24)
    plots, _ = item(lobby, "Folder", "Plots")
    colors = [mint, pink, (180, 192, 225), (237, 218, 167)]
    for index in range(8):
        angle = math.radians(22.5 + index*45)
        cx, cz = math.sin(angle)*151, math.cos(angle)*151
        yaw = math.degrees(angle)
        plot, _ = item(plots, "Model", f"Plot_{index+1}")

        def point(x, y, z):
            return (cx + x*math.cos(angle) + z*math.sin(angle), y,
                    cz - x*math.sin(angle) + z*math.cos(angle))

        block(plot, "GardenPad", point(0, .12, 0), (88, .24, 64), colors[index % 4], (0, yaw, 0))
        block(plot, "MiddleWalk", point(0, .27, 0), (85, .1, 8), cream, (0, yaw, 0))
        block(lobby, "GardenPath", (math.sin(angle)*87, .09, math.cos(angle)*87), (10, .18, 80), cream, (0, yaw, 0))
        sign(plot, "OwnerBoard", point(0, 4, -33), f"개인 구역 {index+1}\n빈 목장 · 8개", rotation=(0, yaw, 0), width=20)
        pens, _ = item(plot, "Folder", "Pens")
        for row in range(2):
            for col in range(4):
                number=row*4+col+1
                pen, _ = item(pens, "Model", f"Pen_{number}")
                px, pz = (col-1.5)*20, (-1 if row == 0 else 1)*17
                block(pen, "PenGrass", point(px, .3, pz), (18, .12, 20), (185, 216, 163), (0, yaw, 0))
                for dx in (-9, 9):
                    for dz in (-10, 10):
                        block(pen, "FencePost", point(px+dx, 1.55, pz+dz), (.65, 2.6, .65), cream, (0, yaw, 0))
                    for h in (.95, 1.9):
                        block(pen, "FenceRail", point(px+dx, h, pz), (.35, .3, 20), cream, (0, yaw, 0))
                outer_z = pz + (-10 if row == 0 else 10)
                inner_z = pz + (10 if row == 0 else -10)
                for h in (.95, 1.9):
                    block(pen, "BackRail", point(px, h, outer_z), (18, .3, .35), cream, (0, yaw, 0))
                    for side in (-1, 1):
                        block(pen, "GateRail", point(px+side*6, h, inner_z), (6, .3, .35), cream, (0, yaw, 0))
                sign(pen, "CapacitySign", point(px+6, 2.2, inner_z), f"{number} · 2마리", rotation=(0, yaw, 0), width=4)
        for side in (-1, 1):
            for n in range(5):
                p = point(side*43, .6, -22+n*11)
                circle(plot, "Flower", p, .7, .4, pink if n%2 else cream)

    shops, _ = item(lobby, "Folder", "Shops")
    for i, x in enumerate((-67, 67), 1):
        shop, _ = item(shops, "Model", f"Shop_{i}")
        circle(shop, "RoundWall", (x, 5, 0), 10, 10, pink if i==1 else (183, 197, 230))
        circle(shop, "RoundRoof", (x, 11, 0), 12, 2, cream)
        block(shop, "GlassDoor", (x, 3.5, 10.15), (4, 6, .3), (161, 209, 215), collide=False)
        sign(shop, "ShopSign", (x, 9, 11), "상점\n준비 중", width=9)
        for n in range(3):
            block(shop, "Window", (x-6+n*6, 6.5, 9.5), (2.8, 2.8, .3), (187, 225, 223), collide=False)

    airport, _ = item(lobby, "Model", "Airport")
    block(lobby, "AirportPath", (0, .12, -122), (13, .24, 154), cream)
    block(airport, "Apron", (0, .1, -247), (106, .2, 90), (184, 208, 214))
    block(airport, "Runway", (0, .23, -282), (98, .12, 18), (123, 156, 163))
    for x in range(-42, 43, 12):
        block(airport, "RunwayStripe", (x, .31, -282), (6, .04, 1), cream)
    circle(airport, "TerminalWall", (-32, 5, -229), 12, 10, (186, 220, 216))
    circle(airport, "TerminalRoof", (-32, 11, -229), 14, 2, cream)
    sign(airport, "TerminalSign", (-32, 8, -216), "비행장", width=12)
    plane, _ = item(airport, "Model", "PastelPlane")
    body=block(plane, "Fuselage", (0, 3, -232), (9, 3, 3), mint, (0, 90, 0))
    prop(body.find("Properties"), "token", "shape", 2)
    block(plane, "Wings", (0, 3, -232), (17, .5, 3.5), cream)
    block(plane, "Cockpit", (0, 4.5, -234), (2.5, 1.5, 2), (105, 161, 176))
    block(plane, "Tail", (0, 4, -228), (.45, 3, 3), pink)
    block(plane, "TailWing", (0, 3, -228), (7, .4, 2), cream)
    block(plane, "Propeller", (0, 3, -237), (.4, 6, .3), pink, collide=False)
    for x in (-1.6, 1.6):
        block(plane, "Wheel", (x, 1, -233), (.8, 1.4, 1.4), (82, 101, 106))
    departure = block(airport, "Departure", (0, 1.4, -217), (8, 2.8, 2), (129, 184, 170), collide=False)
    sign(airport, "DepartureSign", (0, 5, -217), "사냥터로 출발\n가까이에서 E", width=16)
    return lobby
