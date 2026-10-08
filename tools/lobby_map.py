"""Original brick village with physical studs, tiled paths and block-built greenery."""
import math
def build_lobby(workspace, item, part, prop):
    lobby, _ = item(workspace, "Folder", "RodeoLobby")
    cream, mint, pink = (224, 207, 164), (113, 164, 92), (211, 160, 143)
    def block(parent, name, pos, size, color, rotation=(0, 0, 0), collide=True):
        node, properties = part(parent, name, (6000 + pos[0], pos[1], pos[2]), size, color, rotation=rotation)
        prop(properties, "token", "Material", 1280 if name in ("MeadowIsland","PenGrass") else 816 if name in ("GardenPath","MiddleWalk","CentralPlaza","PavingStone") else 512 if name in ("BenchSeat","BenchBack","BoardingStep","BoardingDeck","LadderRail","LadderRung","Counter","CounterPlank","CounterTop","TreeTrunk","SignPost","BoardPost") else 272)
        prop(properties, "bool", "CanCollide", collide)
        prop(properties, "bool", "CanTouch", False)
        for surface in ("TopSurface","FrontSurface","BackSurface","LeftSurface","RightSurface"):
            old=properties.find(f"token[@name='{surface}']")
            if old is not None: old.text="0"
            else: prop(properties,"token",surface,0)
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
    block(lobby, "MeadowIsland", (0, -3, 0), (316, 6, 316), (117, 146, 108))
    circle(lobby, "CentralPlaza", (0, .08, 0), 32, .16, cream)
    # Limestone mosaic, garden water and eight clear radial bridges.
    for x in range(-28,29,4):
        for z in range(-28,29,4):
            if x*x+z*z>30*30: continue
            block(lobby,"PlazaBrick",(x,.21,z),(3.92,.12,3.92),((221,213,192),(232,225,205),(199,212,210))[(x//4+z//4)%3])
    logo=block(lobby,"PlanetureFloorLogo",(0,.285,0),(26,.015,20),(229,222,201),collide=False)
    gui,gp=item(logo,"SurfaceGui","Logo")
    prop(gp,"token","Face",1);prop(gp,"Vector2","CanvasSize",dict(X=1300,Y=1000))
    label,lp=item(gui,"TextLabel","Title")
    prop(lp,"UDim2","Size",dict(XS=1,XO=0,YS=1,YO=0));prop(lp,"float","BackgroundTransparency",1)
    prop(lp,"string","Text","RODEO\nPLANETURE");prop(lp,"int","Font",17);prop(lp,"int","TextSize",180)
    prop(lp,"Color3","TextColor3",dict(R=.12,G=.33,B=.39));prop(lp,"float","TextStrokeTransparency",.8)
    for n in range(64):
        deg=n*360/64;a=math.radians(deg)
        if min(abs((deg-k*45+180)%360-180) for k in range(8))<7: continue
        block(lobby,"GardenWater",(math.sin(a)*37,.06,math.cos(a)*37),(3.7,.12,9),(81,161,183),(0,deg+90,0),collide=False)
        block(lobby,"CanalStone",(math.sin(a)*42,.32,math.cos(a)*42),(4,.64,1),(204,208,190),(0,deg+90,0))
    plots, _ = item(lobby, "Folder", "Plots")
    colors = [(233,140,143),(243,178,111),(247,225,129),(147,204,154),(137,189,230),(111,132,186),(188,154,220),(245,244,236)]
    for index in range(8):
        angle=math.radians(index*45)
        yaw=math.degrees(angle)
        cx,cz=math.sin(angle)*108,math.cos(angle)*108
        plot, _ = item(plots, "Model", f"Plot_{index+1}")
        def point(x, y, z):
            return (cx + x*math.cos(angle) + z*math.sin(angle), y,
                    cz - x*math.sin(angle) + z*math.cos(angle))
        marker=block(plot,"ManagePoint",point(0,2.2,-33),(2,2,2),cream,collide=False)
        prop(marker.find("Properties"),"float","Transparency",1)
        block(plot, "GardenPad", point(0, .12, 0), (58, .24, 64), colors[index], (0, yaw, 0))
        block(plot, "MiddleWalk", point(0, .27, 0), (7, .1, 64), cream, (0, yaw, 0))
        block(lobby,"GardenPath",(math.sin(angle)*61,.09,math.cos(angle)*61),(7,.3,65),cream,(0,yaw,0))
        sign(plot, "OwnerBoard", point(0, 15, -34.2), " ", color=colors[index], rotation=(0, yaw, 0), width=20)
        for x in (-10,10):
            block(plot,"SignPost",point(x,7,-33),(.6,14,.6),(173,130,91))
        accent=colors[index]
        pens, _ = item(plot, "Folder", "Pens")
        for row in range(2):
            for col in range(2):
                number=row*2+col+1
                pen, _ = item(pens, "Model", f"Pen_{number}")
                px, pz = (-16,16)[col], (-1 if row == 0 else 1)*15
                block(pen, "PenGrass", point(px, .3, pz), (22, .22, 24), (166, 189, 155), (0, yaw, 0))
                side=-1 if px<0 else 1
                inner_x=px-side*11
                outer_x=px+side*11
                for dx in (-11,11):
                    for dz in (-12,12):
                        block(pen,"FencePost",point(px+dx,1.55,pz+dz),(.65,2.6,.65),accent,(0,yaw,0))
                for h in (.95,1.9):
                    for dz in (-12,12):
                        block(pen,"FenceRail",point(px,h,pz+dz),(22,.3,.35),accent,(0,yaw,0))
                    block(pen,"BackRail",point(outer_x,h,pz),(.35,.3,24),accent,(0,yaw,0))
                    for dz in (-8.5,8.5):
                        block(pen,"GateRail",point(inner_x,h,pz+dz),(.35,.3,7),accent,(0,yaw,0))
                sign(pen,"CapacitySign",point(inner_x,2.2,pz+4.5),str(number),rotation=(0,yaw+90,0),width=4)
        # Four pens form one open courtyard, enclosed by an original architectural ranch.
        stone=(232,221,193);trim=(249,238,210);roof=(42,126,133);shadow=(176,190,178)
        def arch(name,x,z,face):
            for side in (-1,1):
                block(plot,name+"Pier",point(x+side*3.3,5,z),(1.3,10,1.4),stone,(0,yaw+face,0))
            for j in range(9):
                a=math.pi*j/8
                block(plot,name+"Voussoir",point(x+math.cos(a)*3.3,9+math.sin(a)*3.3,z),(.95,1.3,1.5),trim,(0,yaw+face,math.degrees(a)-90))
        for side in (-1,1):
            for z in (-22,-10,2,14,26):
                block(plot,"CourtyardColumn",point(side*29,6,z),(1.4,12,1.4),stone,(0,yaw,0))
                block(plot,"ColumnBase",point(side*29,.6,z),(2.2,1.2,2.2),shadow,(0,yaw,0))
                block(plot,"ColumnCapital",point(side*29,12,z),(2.4,.7,2.4),trim,(0,yaw,0))
            block(plot,"ArcadeCornice",point(side*29,13,2),(2,1.6,58),stone,(0,yaw,0))
            block(plot,"ArcadeFrieze",point(side*29,14,2),(2.6,.4,59),trim,(0,yaw,0))
            for j in range(3):
                block(plot,"ArcadeRoof",point(side*(28.7-j*.45),14.5+j*.4,2),(3.5-j*.5,.6,60),roof,(0,yaw,0))
            block(plot,"GateHouseWing",point(side*20,7,-31),(16,14,3),stone,(0,yaw,0))
            block(plot,"GateWingAccent",point(side*20,7,-32.6),(12,4,.15),colors[index],(0,yaw,0),collide=False)
            for j in range(6): block(plot,"GateRoofTile",point(side*20,15+j*.55,-31),(18-j*.8,.55,7-j*.55),roof,(0,yaw,0))
        arch("EntryArch",0,-32,0)
        block(plot,"EntryEntablature",point(0,15,-32),(15,2,4),stone,(0,yaw,0))
        block(plot,"EntryCornice",point(0,16.3,-32),(17,.6,5),trim,(0,yaw,0))
        for j in range(8): block(plot,"EntryRoof",point(0,17+j*.65,-32),(18-j*1.5,.65,8-j*.65),roof,(0,yaw,0))
        block(plot,"BackGallery",point(0,7,32),(58,14,2),stone,(0,yaw,0))
        for x in (-22,-11,0,11,22):
            block(plot,"BackWindowInset",point(x,8,30.8),(5.5,6,.2),(64,102,109),(0,yaw,0),collide=False)
            block(plot,"WindowSill",point(x,4.8,30.5),(6.5,.5,1),trim,(0,yaw,0))
        for sx in (-1,1):
            for sz in (-1,1):
                tx,tz=sx*25,sz*28
                block(plot,"RanchTower",point(tx,12,tz),(8,24,8),stone,(0,yaw,0))
                for j in range(8):
                    block(plot,"TowerRoofCourse",point(tx,24.8+j*.75,tz),(10-j,.75,10-j),roof,(0,yaw,0))
                block(plot,"TowerFinial",point(tx,31.2,tz),(.7,2,.7),(216,180,101),(0,yaw,0))
                for yy in (3,12,23): block(plot,"TowerBelt",point(tx,yy,tz),(8.6,.45,8.6),trim,(0,yaw,0))
                block(plot,"TowerBanner",point(tx,17,tz-4.15),(2.2,6,.15),colors[index],(0,yaw,0),collide=False)
        for side in (-1, 1):
            for n in range(5):
                p = point(side*28, .6, -24+n*12)
                circle(plot, "Flower", p, .7, .4, pink if n%2 else cream)
    def radial_point(angle,radius,x,y,z):
        return (math.sin(angle)*radius+x*math.cos(angle)+z*math.sin(angle),y,math.cos(angle)*radius-x*math.sin(angle)+z*math.cos(angle))
    shops,_=item(lobby,"Folder","Shops")
    for i,deg in enumerate((22.5,202.5),1):
        a=math.radians(deg)
        shop,_=item(shops,"Model",f"Shop_{i}")
        def sb(name,pos,size,color,rx=0):
            return block(shop,name,radial_point(a,49,*pos),size,color,(rx,deg,0))
        for side in (-1,1):
            sb("StoneShopPier",(side*5.5,5,1),(1,10,1),(232,221,193))
        sb("ShopBackWall",(0,4,3),(12,8,1),(232,221,193))
        for j in range(7): sb("ShopRoof",(0,10+j*.55,0),(13-j*.65,.55,9-j*.6),(42,126,133))
        sb("Counter",(0,1.5,0),(10,3,5),(159,115,78))
        sb("CounterTop",(0,3.1,0),(10.6,.35,5.5),(199,156,104))
        for x in range(-4,5): sb("CounterPlank",(x,1.55,-2.6),(.9,2.7,.2),(170+x*2,124+x*2,83))
        for x in (-5,5):
            for z in (-2.5,2.5): sb("Post",(x,4,z),(.4,8,.4),(108,89,71))
        for stripe in range(0):
            for j in range(4):
                sb("Awning",(-4.4+stripe*1.25,8.3-abs(j-1.5)*.25,-2.4+j*1.6),(1.25,.16,1.7),cream if stripe%2 else ((119,165,168) if i==1 else (194,142,158)),rx=(-9 if j<2 else 9))
            sb("AwningFringe",(-4.4+stripe*1.25,7.7,-3.4),(1.25,.5,.15),cream if stripe%2 else mint)
        for x in (-3,0,3):
            sb("DisplayTray",(x,3.4,0),(2.3,.2,2),(124,94,65))
            sb("DisplayParcel",(x,3.8,0),(1.2,.7,1),((194,155,122),(148,169,186),(178,156,185))[int((x+3)/3)])
        sign(shop,"ShopSign",radial_point(a,49,0,9,0),"Shop",width=10,rotation=(0,deg,0))
    airport, _ = item(lobby, "Model", "Airport")
    ship,_ = item(airport,"Model","Airship")
    # Ninth-star final evolution: smooth sculpted volumes, swept wings and long trunk.
    blue, light_blue, dark_blue=(45,108,163),(91,162,205),(27,62,105)
    def smooth(name,pos,size,color,rotation=(0,0,0)):
        node=block(ship,name,pos,size,color,rotation,collide=False)
        prop(node.find("Properties"),"token","shape",0)  # native ellipsoid, no uploaded mesh
        return node
    smooth("WalrusBody",(0,48,-5),(38,28,70),blue)
    smooth("BackMantle",(0,57,-6),(33,12,61),light_blue)
    smooth("Chest",(0,43,-29),(31,25,30),blue)
    smooth("WalrusHead",(0,52,-42),(30,27,30),light_blue)
    smooth("Forehead",(0,59,-45),(24,12,20),blue)
    smooth("Muzzle",(0,44,-51),(20,12,17),(112,178,207))
    # Overlapping tapered ellipsoids follow a curved trunk instead of a block staircase.
    for n in range(15):
        t=n/14
        z=-54-t*37
        y=46-10*math.sin(t*math.pi*.8)+5*t*t
        radius=7.5*(1-t)+2.5*t
        smooth("TrunkSegment",(0,y,z),(radius,radius,6.8),blue if n<9 else light_blue,(-12+30*t,0,0))
    smooth("TrunkTip",(0,43,-91),(3.7,4.5,6),light_blue,(-28,0,0))
    for side in (-1,1):
        smooth("GreatEar",(side*17,54,-35),(5,23,21),dark_blue,(0,side*22,side*12))
        smooth("EarInner",(side*19,54,-37),(2,18,15),blue,(0,side*22,side*12))
        smooth("EyeSocket",(side*10.7,54.5,-53),(7,3.6,2.8),dark_blue,(0,side*24,side*-9))
        smooth("Eye",(side*11,54.7,-54.4),(4.5,1.5,.8),(131,224,244),(0,side*24,side*-9))
        smooth("BrowArmor",(side*10.8,57,-53),(8,1.6,3),dark_blue,(0,side*20,side*-14))
        for n in range(6):
            t=n/5
            smooth("Tusk",(side*(7.5+2*t),40-14*t,-53-5*t),(2.7-2*t,4,2.7-2*t),(242,235,207),(12,0,side*-10))
        # Each feather belongs to the same wing pivot for a coherent slow wing beat.
        smooth("SeaWingRoot",(side*22,47,-9),(21,4,35),dark_blue,(0,side*18,side*8))
        for n in range(9):
            x=side*(30+n*4.2)
            z=-10+n*2.3
            length=30-n*1.7
            smooth("SeaWingFeather",(x,46+n*.8,z),(12-n*.6,2.7,length),light_blue if n%3==0 else blue,(0,side*(20+n*2),side*(8+n*1.5)))
        for n in range(4):
            smooth("TailFin",(side*(5+n*4),48,30+n*2),(11,2,19-n*2),blue,(0,side*(-22-n*8),0))
        for n in range(5):
            smooth("SideArmor",(side*16.5,51,-25+n*10),(4,8,8),dark_blue,(0,0,side*12))
    for n in range(7):
        smooth("DorsalCrest",(0,62-n*.45,-27+n*8),(6,6,10),dark_blue,(0,0,0))
        smooth("CrestGlow",(0,65-n*.45,-27+n*8),(2.5,2.2,6),(153,213,229))
    # Open hot-air-balloon basket: no house, roof or window box.
    basket=(154,108,69)
    floor=block(ship,"BasketFloor",(0,13.1,-5),(12,.5,16),basket,collide=False)
    for side in (-1,1):
        block(ship,"BasketSide",(side*5.8,14.8,-5),(.7,3,16),basket,collide=False)
        block(ship,"BasketFront",(side*3,14.8,-12.7),(6,3,.7),basket,collide=False)
        block(ship,"BasketBack",(side*4.7,14.8,2.7),(2.6,3,.7),basket,collide=False)
        for n in range(12):
            block(ship,"BasketWeave",(side*6.2,14.8,-12+n*1.3),(.12,2.8,.15),(202,163,112),collide=False)
        for z in (-11,1):
            block(ship,"BasketCable",(side*5,25,z),(.24,21,.24),(215,198,156),collide=False)
        block(ship,"BasketRim",(side*5.9,16.4,-5),(1,.55,16.5),(115,79,52),collide=False)
    for y in (13.7,14.4,15.1,15.8):
        for side in (-1,1):
            block(ship,"BasketWeave",(side*6.2,y,-5),(.12,.12,16),(202,163,112),collide=False)
    block(ship,"BasketInnerDeck",(0,13.2,-5),(11,.25,15),(186,141,91),collide=False)
    # A single climbable ladder leads to the open basket, away from the center spawn.
    ladder,lp=item(airport,"TrussPart","BoardingLadder")
    prop(lp,"bool","Anchored",True); prop(lp,"bool","CanCollide",True)
    prop(lp,"float","Transparency",1)  # Invisible native climb surface; visible wooden ladder below.
    prop(lp,"Vector3","size",dict(X=2,Y=14,Z=2))
    prop(lp,"CoordinateFrame","CFrame",dict(X=6000,Y=7,Z=7.5,R00=1,R01=0,R02=0,R10=0,R11=1,R12=0,R20=0,R21=0,R22=1))
    prop(lp,"Color3uint8","Color3uint8",(142<<16)|(110<<8)|79)
    for side in (-1,1):
        block(airport,"LadderRail",(side*1.25,7.2,7.5),(.28,14.4,.45),(140,100,67),collide=False)
        block(airport,"LadderFoot",(side*1.25,.25,7.5),(.35,.5,.5),(62,69,65),collide=False)
    for rung in range(14):
        y=.65+rung*.9
        block(airport,"LadderRung",(0,y,7.75),(2.65,.24,.42),(190,146,98),collide=False)
        for side in (-1,1):
            block(airport,"LadderBolt",(side*1.25,y,8.0),(.09,.09,.05),(71,78,77),collide=False)
    block(airport,"BoardingDeck",(0,13,4.5),(6,.5,5),(183,151,116))
    departure=block(airport,"Departure",(0,14.5,3),(2,2,2),mint,collide=False)
    prop(departure.find("Properties"),"float","Transparency",1)
    # Human-scale furnishing, varied paving and landscaping around the plaza.
    for ring in (24,29):
        for n in range(48):
            angle=math.tau*n/48
            x,z=math.sin(angle)*ring,math.cos(angle)*ring
            if abs(x)<6 and z>5: continue  # keep the staircase approach clear
            block(lobby,"PavingStone",(x,.21,z),(2.5,.12,2.4),((206,192,171),(187,191,185),(218,195,145))[n%3],(0,n*7.5,0))
    for deg in (67.5,157.5,247.5,337.5):
        a=math.radians(deg)
        furniture,_=item(lobby,"Model",f"GardenCorner_{deg}")
        def fb(name,x,y,z,size,color):
            return block(furniture,name,radial_point(a,43,x,y,z),size,color,(0,deg,0))
        for z in (-.6,0,.6): fb("BenchSeat",0,1.3,z,(8,.23,.45),(166,118,83))
        for y in (1.8,2.3,2.8): fb("BenchBack",0,y,.9,(8,.3,.25),(166,118,83))
        for x in (-3.7,3.7):
            fb("BenchLeg",x,.65,0,(.3,1.3,1.8),(60,74,78))
            fb("BenchArm",x,1.95,0,(.25,.25,1.7),(60,74,78))
            fb("BenchArmPost",x,1.5,-.6,(.25,.7,.25),(60,74,78))
        fb("Planter",0,.6,6,(8,1.2,4),(134,102,80))
        fb("Soil",0,1.22,6,(7.5,.15,3.5),(91,74,60))
        for j in range(7):
            x=-3+j
            fb("FlowerStem",x,1.8,6,(.12,1.1,.12),(81,128,83))
            for petal in range(5):
                q=math.tau*petal/5
                node=fb("FlowerPetal",x+math.sin(q)*.28,2.3,6+math.cos(q)*.28,(.5,.18,.5),((218,143,163),(225,192,100),(157,150,195))[j%3])
                prop(node.find("Properties"),"token","shape",1)
            node=fb("FlowerCenter",x,2.38,6,(.23,.16,.23),(235,204,104));prop(node.find("Properties"),"token","shape",0)
            fb("FlowerLeaf",x+.2,1.8,6,(.5,.1,.25),(100,151,98))
    for n in range(8):
        a=math.radians(22.5+n*45)
        x,z=math.sin(a)*35,math.cos(a)*35
        block(lobby,"LampPost",(x,4,z),(.35,8,.35),(62,78,88))
        lamp=block(lobby,"Lantern",(x,8,z),(1.2,1.6,1.2),(255,222,165),collide=False)
        prop(lamp.find("Properties"),"token","Material",288)
        light,lp=item(lamp,"PointLight","WarmLight")
        prop(lp,"float","Brightness",.7);prop(lp,"float","Range",15)
        block(lobby,"LampCap",(x,9,z),(1.6,.3,1.6),dark_blue)
    boards,_=item(lobby,"Folder","Leaderboards")
    for key,deg,color in (("Distance",112.5,(86,128,154)),("Income",292.5,(159,127,76))):
        a=math.radians(deg)
        x,z=math.sin(a)*49,math.cos(a)*49
        board=block(boards,key,(x,8,z),(15,12,.8),color,(0,deg,0))
        for dx in (-6,6): block(boards,"BoardPost",radial_point(a,49,dx,4,0),(.8,8,.8),(123,92,71),(0,deg,0))
        gui,gp=item(board,"SurfaceGui","Ranking")
        prop(gp,"token","Face",5); prop(gp,"Vector2","CanvasSize",dict(X=750,Y=600))
        label,lp=item(gui,"TextLabel","Entries")
        prop(lp,"UDim2","Size",dict(XS=1,XO=0,YS=0,YO=490)); prop(lp,"UDim2","Position",dict(XS=0,XO=0,YS=0,YO=100)); prop(lp,"float","BackgroundTransparency",1)
        prop(lp,"int","TextSize",32); prop(lp,"bool","TextWrapped",True)
        prop(lp,"Color3","TextColor3",dict(R=.98,G=.95,B=.87))
        prop(lp,"string","Text","Loading records...")
        header,hp=item(gui,"TextLabel","Heading")
        prop(hp,"UDim2","Size",dict(XS=1,XO=0,YS=0,YO=90)); prop(hp,"float","BackgroundTransparency",1)
        prop(hp,"int","TextSize",38); prop(hp,"Color3","TextColor3",dict(R=1,G=.93,B=.7))
        prop(hp,"string","Text","Farthest run" if key=="Distance" else "Total produced")
    for n in range(32):
        angle=math.tau*n/32
        x,z=math.sin(angle)*145,math.cos(angle)*145
        clear=True
        for i in range(8):
            a=math.tau*i/8
            dx,dz=x-math.sin(a)*108,z-math.cos(a)*108
            lx,lz=dx*math.cos(a)-dz*math.sin(a),dx*math.sin(a)+dz*math.cos(a)
            if abs(lx)<33 and abs(lz)<37: clear=False
        if not clear: continue
        trunk=block(lobby,"TreeTrunk",(x,3,z),(6,1.5,1.5),(121,89,64),(0,0,90))
        prop(trunk.find("Properties"),"token","shape",2)
        for tier in range(3):
            width=10-tier*2.5
            canopy=block(lobby,"TreeCanopy",(x,6+tier*2,z),(width,4.5,width),((81,133,62),(105,159,77),(131,179,88))[tier])
            prop(canopy.find("Properties"),"token","shape",1)
        for dx in (-3,3): block(lobby,"GardenRock",(x+dx,.7,z+3),(2,1.4,1.7),(141,148,146),(0,n*17,0))
    walls,_=item(lobby,"Folder","Boundary")
    for side in (-1,1):
        block(walls,"GardenWall",(side*158,12,0),(4,24,320),(204,198,174))
        block(walls,"GardenWall",(0,12,side*158),(320,24,4),(204,198,174))
        block(walls,"WallTrim",(side*158,24.5,0),(5,1,321),cream)
        block(walls,"WallTrim",(0,24.5,side*158),(321,1,5),cream)
    return lobby