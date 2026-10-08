"""Original block grass crow, forward -Z; broad wings and a sprouting crest."""
def components():
    result=[]
    def add(name,pos,size,color,rotation=(0,0,0),studs=False):
        result.append(dict(name=name,position=pos,size=size,color=color,rotation=rotation,shape="Block",neon=False,studs=studs))
    navy=(94,151,91); soft=(177,211,126); cream=(249,237,182); green=(125,180,94)
    add("Body",(0,.1,.15),(2.1,1.35,2.45),soft)
    add("ShoulderMantle",(0,1.02,.2),(1.75,.28,2.05),(194,220,145))
    result[-1]["studs"]=True
    add("RoundLowerBody",(0,-.68,.1),(1.75,.35,2.1),soft)
    add("Belly",(0,-.25,-.72),(1.25,.85,.28),cream)
    add("Head",(0,.65,-.9),(2.05,1.7,1.45),(195,224,148))
    add("HeadCrown",(0,1.57,-.9),(1.64,.22,1.2),(206,229,163))
    result[-1]["studs"]=True
    add("Beak",(0,.25,-1.67),(.65,.4,.6),(219,168,114))
    add("BeakTip",(0,.18,-1.97),(.4,.2,.18),(185,124,92))
    for side,sign in (("Left",-1),("Right",1)):
        add(side+"EyeWhite",(sign*.54,.78,-1.675),(.51,.59,.08),(255,250,226))
        add(side+"Pupil",(sign*.53,.78,-1.725),(.32,.4,.03),(25,32,42))
        add(side+"Shine",(sign*.49,.9,-1.765),(.12,.14,.02),(255,255,255))
        add(side+"Cheek",(sign*.73,.39,-1.675),(.26,.16,.04),(227,171,153))
        add(side+"Wing",(sign*1.45,.3,.1),(1.45,.35,1.95),green,(0,sign*12,sign*-8))
        for n in range(3):
            add(side+"WingFeather"+str(n),(sign*(1.9+n*.17),.3,.65-n*.6),(1.0,.32,.65),soft if n%2 else green,(0,sign*(20+n*9),sign*-8))
            add(side+"WingVein"+str(n),(sign*(1.8+n*.17),.5,.65-n*.6),(.8,.05,.06),(218,238,172),(0,sign*(20+n*9),0))
        add(side+"Foot",(sign*.47,-.82,-.1),(.38,.26,.67),(215,174,87))
        add(side+"CrestLeaf",(sign*.35,1.6,-.76),(.3,.9,.56),green,(0,sign*20,sign*-24))
    add("FlowerBud",(0,1.93,-.8),(.5,.72,.5),(239,172,187))
    for n,(x,z) in enumerate(((-.25,-.8),(.25,-.8),(0,-1.05),(0,-.55))):
        add("BudPetal"+str(n),(x,1.86,z),(.32,.65,.32),(243,183,195),(0,n*90,(n-1.5)*5))
    result[-1]["studs"]=True
    add("BudCalyx",(0,1.53,-.8),(.68,.22,.68),green)
    add("BudHighlight",(-.13,2.17,-1.12),(.2,.22,.08),(255,222,220))
    for n in range(3): add("TailFeather"+str(n),((n-1)*.36,-.05,1.65),(.45,.3,1.4),green,(0,(n-1)*20,0))
    return result
