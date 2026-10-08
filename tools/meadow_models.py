# Approved A families: original meadow creatures, four visibly distinct growth stages.
import math
SPECIES=("MeadowMouse","GrassBoar","TreeWolf","RockElephant","Weedcrow")
STAGES=(1,3,6,9)
SCALES={1:1,3:1.4,6:1.9,9:2.5}
ROOT_HEIGHT={"MeadowMouse":2.05,"GrassBoar":2.45,"TreeWolf":2.35,"RockElephant":3.25,"Weedcrow":16}
BOUNDS={"MeadowMouse":(2.3,2,3.8),"GrassBoar":(3,2.5,4.8),"TreeWolf":(2.8,2.4,4.9),"RockElephant":(4.7,3.5,6.5),"Weedcrow":(2.6,2,4)}

def components(species="MeadowMouse",stars=1):
    stage=STAGES.index(stars);scale=SCALES[stars];out=[];counts={}
    cream=(244,232,206);brown=(163,111,76);pink=(227,157,164)
    greens=((89,133,65),(113,160,72),(145,181,97),(176,201,123))
    def add(name,p,size,color,shape="Ball",rotation=(0,0,0),studs=False):
        n=counts.get(name,0);counts[name]=n+1
        unique=name if n==0 else name+"_"+str(n)
        out.append(dict(name=unique,position=tuple(v*scale for v in p),size=tuple(v*scale for v in size),color=color,shape=shape,rotation=rotation,neon=False,studs=studs,glow=False))
    def leaf(name,p,length=.9,width=.45,rot=(25,0,0),color=None):
        add(name,p,(width,.13,length),color or greens[(len(out)+stage)%4],rotation=rot)
        add(name+"Vein",(p[0],p[1]+.065,p[2]),(.045,.045,length*.7),(185,205,136),"Block",rot)
    def flower(name,p,size=.3):
        for k in range(5):
            a=k*math.tau/5
            add(name+"Petal",(p[0]+math.sin(a)*size*.55,p[1],p[2]+math.cos(a)*size*.55),(size,.12,size),(250,243,215))
        add(name+"Heart",(p[0],p[1]+.05,p[2]),(size*.45,.15,size*.45),(235,196,88))
    def clover(name,p,size=.4):
        for k in range(3):
            a=k*math.tau/3
            add(name,(p[0]+math.sin(a)*size*.4,p[1],p[2]+math.cos(a)*size*.4),(size,.1,size),greens[2])
    def eyes(headw,y,z,adult=False):
        for side,sg in (("Left",-1),("Right",1)):
            x=sg*headw*.31
            add(side+"EyeRim",(x,y,z+.025),(.66,.78,.18),(160,109,65))
            add(side+"EyeWhite",(x,y,z-.07),(.57,.7,.16),(255,248,225))
            add(side+"Iris",(x-sg*.025,y,z-.16),(.39,.58,.13),(118,74,35))
            add(side+"Pupil",(x-sg*.03,y,z-.215),(.24,.44,.08),(36,36,38))
            add(side+"Shine",(x-sg*.1,y+.17,z-.263),(.12,.16,.045),(255,255,248))
            if adult: add(side+"Brow",(x,y+.48,z),(.73,.17,.21),brown,rotation=(0,0,sg*14))
    def feet(width,zfront,zback,height,hoof=False):
        for side,sg in (("Left",-1),("Right",1)):
            for which,z in (("Front",zfront),("Back",zback)):
                add(side+which+"Leg",(sg*width,-height*.6,z),(.65,height,.72),body)
                add(side+which+"Paw",(sg*width,-height-.12,z-.12),(.82,.38,.98),(71,65,51) if hoof else cream)
                if not hoof:
                    for toe in (-.2,0,.2): add(side+which+"Claw",(sg*width+toe,-height-.08,z-.57),(.14,.15,.18),(188,160,116))
    def mane(p,width,layers=1):
        for layer in range(layers):
            for j in range(7+stage*2):
                a=j*math.tau/(7+stage*2)
                leaf("ManeLeaf",(math.sin(a)*width,p[1]+math.cos(a)*.35-layer*.2,p[2]+layer*.45),1+stage*.16,.4+stage*.06,(math.cos(a)*35,math.degrees(a),math.sin(a)*35))

    if species=="MeadowMouse":
        body=(210,169,120)
        add("Body",(0,-.1,.25),(2,1.65,2.7),cream)
        add("BackPatch",(0,.42,.43),(1.5,1.3,2.1),body)
        headw=2.1-stage*.055
        add("Head",(0,.5,-1.23),(headw,1.72,1.52),body)
        add("Muzzle",(0,.18,-1.98),(1.45,.76,.75),cream)
        add("Nose",(0,.45,-2.36),(.31,.24,.2),pink)
        eyes(headw,.76,-1.99,stage>=2)
        for side,sg in (("Left",-1),("Right",1)):
            add(side+"Ear",(sg*1.02,1.36,-1.03),(1.28,1.6,.48),body,rotation=(0,sg*8,sg*-15))
            add(side+"EarInner",(sg*1.02,1.38,-1.3),(.97,1.28,.16),pink,rotation=(0,sg*8,sg*-15))
            add(side+"Cheek",(sg*.67,.14,-2.11),(.6,.28,.16),cream)
            for j in range(2): add(side+"Whisker",(sg*(.78+j*.05),.22-j*.17,-2.08),(.95,.035,.035),(143,117,91),"Block",(0,0,sg*(10-j*22)))
        feet(.7,-.65,1.0,1.62)
        for n in range(10+stage*2):
            t=n/(9+stage*2);a=t*2.2
            add("TailCurve",(math.sin(a)*(1+stage*.1),-.1+t*1.15,1.58+t*.8),(.17,.17,.35),body,rotation=(0,math.degrees(a),0))
        clover("TailClover",(.9,1.3,2.4),.42+stage*.07)
        leaf("CrownSprout",(-.2,1.65,-1.22),.7,.4,(0,-30,-25))
        leaf("CrownSprout",(.2,1.7,-1.22),.9,.42,(0,35,25))
        mane((0,.2,-.72),.83,1+stage)
        if stage: flower("ForeheadFlower",(0,1.55,-1.67),.25)
        for n in range(stage*4):
            sg=-1 if n%2 else 1
            leaf("CloakLeaf",(sg*.88,.8-(n%4)*.19,-.2+(n//4)*.5),1.05+stage*.15,.5,(35,sg*35,sg*30))
        if stage>=2:
            for sg in (-1,1): clover("CloakClover",(sg*.95,.76,.9),.3)
    elif species in ("GrassBoar","TreeWolf"):
        boar=species=="GrassBoar";body=(119,158,73) if boar else (178,205,173)
        add("Body",(0,-.05,.35),(2.7 if boar else 2.25,2.15,3.5 if boar else 3.8),body)
        add("Belly",(0,-.48,.2),(2.2,1.4,2.9),cream)
        headw=2.45 if boar else 2.12
        add("Head",(0,.38,-1.53),(headw,1.9,1.8),body)
        add("Muzzle",(0,-.05,-2.45),(1.75 if boar else 1.32,.9,1.0),pink if boar else cream)
        if boar:
            for sg in (-1,1): add("Nostril",(sg*.37,.05,-2.96),(.22,.3,.07),(119,81,65))
        else: add("Nose",(0,.25,-2.99),(.43,.29,.19),(48,55,47))
        eyes(headw,.72,-2.3,stage>=2)
        for side,sg in (("Left",-1),("Right",1)):
            add(side+"Ear",(sg*.95,1.45,-1.2),(.85,1.05,.5),greens[1] if boar else body,rotation=(0,sg*12,sg*-20))
            add(side+"EarInner",(sg*.95,1.5,-1.49),(.46,.66,.12),pink if boar else (219,167,149),rotation=(0,sg*12,sg*-20))
        feet(.97 if boar else .82,-1.05,1.5,2.03 if boar else 1.92,boar)
        mane((0,.75,-.9),1.02,1+stage)
        for row in range(2+stage*2):
            for sg in (-1,1): leaf("BackLeaf",(sg*.55,1.05+row*.03,-.1+row*.43),1.1,.65,(20,sg*30,sg*25))
        if boar:
            for sg in (-1,1):
                for n in range(3+stage):
                    t=n/(2+stage)
                    add("Tusk",(sg*(.8+t*.35),-.2+t*(.35+stage*.2),-2.52-t*.45),(.27-t*.17,.38,.32-t*.15),cream,("Ball"),rotation=(0,0,sg*-30))
                for z in (.15,1.1): clover("HideClover",(sg*1.32,.3,z),.35)
            for n in range(7):
                a=n*math.pi/4
                add("TailCurl",(math.sin(a)*.24,.2+math.cos(a)*.24,2.25),(.2,.2,.32),body)
            leaf("TailSprout",(0,.52,2.36),.7,.4,(0,0,0))
        else:
            for n in range(7):
                t=n/6
                add("TailBranch",(.2*math.sin(t*3),.4+t*.8,2.2+t*.75),(.34,.34,.48),brown,rotation=(-25,0,0))
            for n in range(3+stage): leaf("TailLeaf",((-.4 if n%2 else .4),.8+n*.1,2.5),.7,.4,(30,n*35,0))
            for side,sg in (("Left",-1),("Right",1)):
                leaf(side+"EarLeaf",(sg*.9,1.7,-1.2),.82,.42,(0,sg*40,sg*20),greens[2])
                if stage>=2:
                    for n in range(2+stage):
                        add("BranchCrown",(sg*(.4+n*.14),1.53+n*.23,-1.2+n*.09),(.18,.46,.18),brown,rotation=(0,0,sg*-30))
                    for n in range(3): leaf("CrownLeaf",(sg*(.75+n*.12),2.1+n*.18,-1.1),.6,.28,(20,sg*40,sg*25))
            if stage>=1:
                for sg in (-1,1):
                    add("WoodAnkle",(sg*.85,-1.5,-1.02),(.82,.48,.85),brown)
                    leaf("AnkleLeaf",(sg*.86,-1.19,-1.04),.8,.4,(0,sg*45,0))
    elif species=="RockElephant":
        body=(196,181,147)
        add("Body",(0,0,.6),(4.3,3.45,5.2),body)
        add("Head",(0,.35,-2.25),(3.5,3.12,2.9),body)
        add("Forehead",(0,1.32,-2.2),(2.95,1.55,2.3),(219,205,170))
        eyes(3.35,.85,-3.49,stage>=2)
        for side,sg in (("Left",-1),("Right",1)):
            add(side+"Ear",(sg*2.0,.62,-1.86),(1.35,3.3,2.18),(213,198,161),rotation=(0,sg*22,sg*8))
            add(side+"EarInner",(sg*2.35,.65,-2.3),(.46,2.45,1.45),(230,214,179),rotation=(0,sg*22,0))
        feet(1.46,-1.35,2.07,2.88)
        for n in range(10):
            t=n/9
            add("Trunk",(0,-.15-t*1.7+math.sin(t*math.pi)*.25,-3.52-t*.82),(.83-t*.37,.45,.75-t*.26),body,rotation=(20-t*40,0,0))
        if stage:
            for sg in (-1,1):
                for n in range(5+stage):
                    t=n/(4+stage)
                    add("Tusk",(sg*(.92+t*.28),-.3+t*(.3+stage*.28),-3.3-t*(.4+stage*.32)),(.4-t*.29,.36,.47-t*.28),cream,rotation=(-18,0,0))
        for row in range(3+stage):
            for sg in (-1,1):
                add("StonePlate",(sg*1.95,.38+math.sin(row)*.2,-1.1+row*.72),(.38,1.5,1.45),(185+row*4,171+row*3,140+row*2),rotation=(0,sg*15,sg*8))
        for row in range(3+stage*2):
            for sg in (-1,1): leaf("MeadowGrass",(sg*.65,1.7,-1.65+row*.58),.85+stage*.1,.37,(0,sg*30,sg*30))
        for n in range(2+stage*3): flower("MeadowDaisy",((-.8 if n%2 else .8),1.76,-1.7+(n//2)*.64),.31)
        add("TailStem",(0,-.3,3.42),(.24,.24,1.0),body,rotation=(-25,0,0))
        leaf("TailGrass",(0,-.65,3.8),.75,.4,(50,0,0))
    elif species=="Weedcrow":
        body=(171,200,117)
        add("Body",(0,-.03,.15),(2.25,1.85,2.68),body)
        add("Chest",(0,-.1,-.8),(1.65,1.65,1.72),cream)
        add("Head",(0,.6,-1.14),(1.97,1.75,1.72),body)
        eyes(1.97,.81,-1.98,stage>=2)
        add("Beak",(0,.23,-2.17),(.75,.48,.58),(91,88,61),"Wedge",(0,180,0))
        for side,sg in (("Left",-1),("Right",1)):
            add(side+"BackLeg",(sg*.5,-1.15,.3),(.23,.5,.25),(84,82,66))
            add(side+"BackPaw",(sg*.5,-1.4,.13),(.42,.18,.65),(84,82,66))
            for row in range(2+stage):
                for n in range(4+stage):
                    x=sg*(1.2+n*.29+row*.1)
                    leaf(side+"Wing" if row==0 and n==0 else side+"WingLeaf",(x,.2+row*.13,.0+n*.12+row*.23),1.25+stage*.25,.6,(10,sg*(20+n*7),sg*(12+n*3)),greens[(n+row)%4])
        for n in range(3+stage*2): leaf("TailLeaf",((n%3-1)*.25,-.12,1.65+n*.12),1.0+stage*.3,.45,(25,(n%3-1)*25,0))
        for n in range(5):
            a=n*math.tau/5
            add("BudPetal",(math.sin(a)*.22,1.58+stage*.08,-1.12+math.cos(a)*.22),(.34,.72+stage*.07,.34),(224,150+n*5,167+n*4),rotation=(0,0,math.sin(a)*-18))
        for n in range(4): leaf("BudLeaf",((n%2-.5)*.5,1.32,-1.1),.68,.35,(20,n*90,25))
        if stage>=2: mane((0,.48,-.25),.9,stage)
    else: raise ValueError(species)
    return out
