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

    block(lobby, "MeadowIsland", (0, -3, 0), (360, 6, 360), (162, 202, 153))
    circle(lobby, "CentralPlaza", (0, .08, 95), 32, .16, cream)
    circle(lobby, "FountainPool", (0, .5, 95), 11, 1, (161, 210, 219))
    circle(lobby, "FountainBowl", (0, 1.5, 95), 6, 1, cream)
    block(lobby, "FountainColumn", (0, 3, 95), (2, 3, 2), (186, 222, 218))
    sign(lobby, "Welcome", (0, 6, 125), "Rodeo Fantasy", width=24)
    plots, _ = item(lobby, "Folder", "Plots")
    colors = [mint, pink, (180, 192, 225), (237, 218, 167)]
    for index in range(8):
        angle, yaw = 0, 0
        cx = (-124,-50,50,124)[index%4]
        cz = -35-(index//4)*62
        plot, _ = item(plots, "Model", f"Plot_{index+1}")

        def point(x, y, z):
            return (cx + x*math.cos(angle) + z*math.sin(angle), y,
                    cz - x*math.sin(angle) + z*math.cos(angle))

        block(plot, "GardenPad", point(0, .12, 0), (66, .24, 48), colors[index % 4], (0, yaw, 0))
        block(plot, "MiddleWalk", point(0, .27, 0), (63, .1, 6), cream, (0, yaw, 0))
        block(lobby,"GardenPath",(cx/2,.09,cz),(abs(cx),.18,6),cream)
        sign(plot, "OwnerBoard", point(0, 10, -25), " ", rotation=(0, yaw, 0), width=20)
        for x in (-10,10):
            block(plot,"SignPost",point(x,5,-25),(.9,10,.9),(173,130,91))
        pens, _ = item(plot, "Folder", "Pens")
        for row in range(2):
            for col in range(4):
                number=row*4+col+1
                pen, _ = item(pens, "Model", f"Pen_{number}")
                px, pz = (col-1.5)*15, (-1 if row == 0 else 1)*13
                block(pen, "PenGrass", point(px, .3, pz), (13, .12, 15), (185, 216, 163), (0, yaw, 0))
                for dx in (-6.5, 6.5):
                    for dz in (-7.5, 7.5):
                        block(pen, "FencePost", point(px+dx, 1.55, pz+dz), (.65, 2.6, .65), cream, (0, yaw, 0))
                    for h in (.95, 1.9):
                        block(pen, "FenceRail", point(px+dx, h, pz), (.35, .3, 15), cream, (0, yaw, 0))
                outer_z = pz + (-7.5 if row == 0 else 7.5)
                inner_z = pz + (7.5 if row == 0 else -7.5)
                for h in (.95, 1.9):
                    block(pen, "BackRail", point(px, h, outer_z), (13, .3, .35), cream, (0, yaw, 0))
                    for side in (-1, 1):
                        block(pen, "GateRail", point(px+side*4.8, h, inner_z), (3.5, .3, .35), cream, (0, yaw, 0))
                sign(pen, "CapacitySign", point(px+4.8, 2.2, inner_z), str(number), rotation=(0, yaw, 0), width=4)
        for side in (-1, 1):
            for n in range(5):
                p = point(side*32, .6, -17+n*8.5)
                circle(plot, "Flower", p, .7, .4, pink if n%2 else cream)

    block(lobby,"MainWalk",(0,.1,-28),(16,.2,210),cream)
    shops, _ = item(lobby, "Folder", "Shops")
    for i, x in enumerate((-43,43),1):
        shop, _ = item(shops, "Model", f"Shop_{i}")
        block(shop, "Counter", (x,1.6,0), (10,3.2,5), (179,136,99))
        for dx in (-5,5):
            for dz in (-2.5,2.5):
                block(shop,"Post",(x+dx,3.5,dz),(.5,7,.5),cream)
        for stripe in range(8):
            block(shop,"Awning",(x-4.4+stripe*1.25,7,0),(1.25,.45,7),cream if stripe%2 else mint,rotation=(0,0,0))
        sign(shop,"ShopSign",(x,8,0),"Shop · Coming soon",width=12)

    airport, _ = item(lobby, "Model", "Airport")
    circle(airport,"BoardingPlatform",(0,.4,-8),15,.8,(173,205,210))
    ship,_ = item(airport,"Model","Airship")
    # Stepped block hull inspired by the reference's broad airship silhouette.
    for slice_id in range(11):
        z=-23+slice_id*3
        radius=math.sqrt(max(.12,1-((slice_id-5)/5.5)**2))
        for layer in range(3):
            width=(18 if layer==1 else 14)*radius
            block(ship,"Balloon",(0,12+layer*3,z),(width,3,3.1),mint if slice_id%3 else cream,collide=False)
    for x in (-9,9):
        block(ship,"SideEngine",(x,11,-8),(3,3,5),cream,collide=False)
        block(ship,"EngineFace",(x,11,-10.6),(2.2,2.2,.3),(81,117,114),collide=False)
    block(ship,"TailWings",(0,16,7),(22,.6,8),pink,collide=False)
    block(ship,"Cabin",(0,6.5,-8),(7,3,11),cream)
    block(ship,"Glass",(0,7,-13.6),(5,1.5,.25),(112,180,195),collide=False)
    for x in (-3,3):
        for z in (-12,-4):
            block(ship,"Cable",(x,10,z),(.2,5,.2),(147,119,89),collide=False)
    block(ship,"TailFin",(0,16,7),(.6,7,7),pink,collide=False)
    for x in (-9,9):
        block(ship,"Propeller",(x,11,-8),(.4,4,.4),pink,collide=False)
    block(airport,"Departure",(0,1.4,8),(8,2.8,2),mint,collide=False)
    sign(airport,"DepartureSign",(0,5,8),"Hunting grounds",width=16)
    for parent in (airport,shops):
        for node in parent.iter("Item"):
            cf=node.find("Properties/CoordinateFrame[@name='CFrame']")
            if cf is not None: cf.find("Z").text=str(float(cf.find("Z").text)+95)
    walls,_=item(lobby,"Folder","Boundary")
    for side in (-1,1):
        block(walls,"GardenWall",(side*180,12,0),(4,24,364),(181,207,187))
        block(walls,"GardenWall",(0,12,side*180),(364,24,4),(181,207,187))
        block(walls,"WallTrim",(side*180,24.5,0),(5,1,365),cream)
        block(walls,"WallTrim",(0,24.5,side*180),(365,1,5),cream)
    return lobby
