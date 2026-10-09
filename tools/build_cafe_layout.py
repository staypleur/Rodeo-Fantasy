"""Cafe, terrace and oversized outdoor grounds; shared visual/runtime layout."""
from pathlib import Path
import json,math
R=Path(__file__).resolve().parents[1];parts=[]
cream=[238,225,198];wood=[131,91,58];dark=[62,84,65];sage=[146,170,118];gold=[208,163,85]
def p(name,pos,size,color,**kw):parts.append(dict(name=name,pos=pos,size=size,color=color,**kw))
p('MeadowGround',[0,-1,15],[620,2,620],[127,163,100],material='Grass')
p('Terrace',[0,.15,-89],[190,.3,48],[217,201,168],material='WoodPlanks')
p('CafeFloor',[0,.15,-164],[154,.3,104],[178,134,88],material='WoodPlanks')
p('BackWall',[0,13,-215],[156,26,2],cream)
for x in [-77,77]:
 p('WindowSillWall',[x,2,-164],[2,4,104],cream)
 p('WindowLintelWall',[x,24,-164],[2,4,104],cream)
 for z in [-214,-182,-150,-113]:p('WindowPier',[x,13,z],[2,26,5],cream)
 for z in [-198,-166,-134]:
  for dz in [-13,13]:p('WindowFrame',[x,13,z+dz],[2.2,18,1],wood)
  for y in [4,22]:p('WindowFrame',[x,y,z],[2.2,1,27],wood)
  p('Window',[x,13,z],[.4,17,25],[179,214,204],alpha=.7,material='Glass')
for x in [-64,-40,40,64]:
 for dx in [-11,11]:p('FrontWindowFrame',[x+dx,13,-113],[1.2,26,2],wood)
 for y in [1,25]:p('FrontWindowFrame',[x,y,-113],[23,2,2],wood)
 p('FrontWindow',[x,13,-113],[21,22,.4],[182,218,207],alpha=.75,material='Glass')
for x in [-16,16]:p('EntryPillar',[x,13,-113],[4,26,4],cream)
p('CafeSign',[0,25,-110],[58,7,2],dark,text='RODEO · MONSTER CAFE',yaw=180)
for z in range(-208,-110,12):p('CeilingBeam',[0,25,z],[158,2,1.4],wood)
p('Roof',[0,28,-164],[164,4,112],dark)
for x in range(-72,73,12):p('RoofRib',[x,30.1,-164],[.7,.3,112],sage)
for x in [-57,-19,19,57]:
 for z in [-187,-146]:
  p('PendantStem',[x,22,z],[.15,5,.15],gold)
  p('WarmPendant',[x,19.4,z],[4,1.2,4],[247,214,145],light=True,material='Neon')
# Service counter, display shelves, cups and menu boards.
p('Counter',[43,3,-197],[54,6,10],dark)
p('CounterTop',[43,6.2,-197],[56,.5,12],cream)
for x in [24,44,64]:
 p('MenuBoard',[x,15,-213],[15,10,1],dark,text='COFFEE\nTEA · MILK',yaw=180)
 p('CoffeeCup',[x,7.1,-197],[1,1.3,1],[246,233,208])
for y in [7,12]:p('CafeShelf',[-46,y,-211],[48,.8,6],wood)
for x in range(-65,-24,6):p('PlantPot',[x,8.5,-209],[2,2,2],gold);p('ShelfLeaves',[x,10,-209],[3,2,3],sage,shape='Ball')
def sofa(x,z,yaw=0):
 p('SofaBase',[x,1.5,z],[15,3,6],wood,yaw=yaw)
 p('SoftCushion',[x,3.2,z],[14,1,5],sage,yaw=yaw)
 p('SofaBack',[x,5,z+2.5],[15,4,1.5],sage,yaw=yaw)
 for dx in [-7.2,7.2]:p('SofaArm',[x+dx,3.8,z],[1.5,3.2,6],sage)
 for dx in [-4.5,0,4.5]:p('BackCushion',[x+dx,5,z+1.5],[4.2,3,1.4],[166,184,135])
 for dx in [-6,0,6]:p('CafeSeat',[x+dx,3.8,z],[3,.4,3],sage,**{'class':'Seat'},alpha=1)
for x in [-49,-13,25,59]:
 for z in [-163,-132]:
  sofa(x,z)
  p('RoundTable',[x,3,z+9],[8,1,6],cream)
  p('TableLeg',[x,1.5,z+9],[2,3,2],wood)
  p('TablePlanter',[x,4,z+9],[1.4,1.4,1.4],gold)
  p('TableLeaf',[x,5,z+9],[2,2,2],sage,shape='Ball')
  p('WovenRug',[x,.36,z+5],[23,.06,20],[222,206,169],material='Fabric',collide=False)
# Pet beds and climbing furniture in the quieter back-left lounge.
for x in [-58,-37,-16]:
 p('PetBed',[x,.8,-187],[11,1.5,9],sage)
 p('PetBedInner',[x,1.7,-187],[8,.5,6],cream)
for x in [-67,-7]:
 p('IndoorClimber',[x,4,-176],[2,8,2],wood)
 p('ClimberStep',[x,7,-176],[8,1,7],sage)
 p('ClimberTop',[x,11,-176],[6,1,6],cream)
for x in [-80,80]:
 for z in [-101,-78]:
  p('TerracePlanter',[x,2,z],[8,4,8],cream)
  p('TerraceBush',[x,5,z],[10,5,10],sage,shape='Ball')
for x in [-56,-28,28,56]:
 p('TerraceTable',[x,3,-87],[10,1,8],cream)
 for dx in [-7,7]:p('TerraceSeat',[x+dx,2,-87],[4,1,4],wood,**{'class':'Seat'})
# Wide central field: 200 by 250 studs, with 30-stud clear perimeter.
p('Field',[0,.05,93],[200,.1,250],[95,150,84],material='Grass')
for z in range(-32,219,25):p('MownStripe',[0,.115,z+12],[198,.025,24],[109,161,91],collide=False)
for x in [-100,100]:p('FieldLine',[x,.16,93],[.5,.03,250],cream,collide=False)
for z in [-32,93,218]:p('FieldLine',[0,.16,z],[200,.03,.5],cream,collide=False)
for i in range(48):
 a=i*math.tau/48;p('CenterCircle',[math.cos(a)*25,.16,93+math.sin(a)*25],[3.5,.03,.5],cream,yaw=-a*180/math.pi,collide=False)
for z in [-36,222]:
 for x in [-23,23]:p('GoalPost',[x,10,z],[1,20,1],cream)
 p('GoalBar',[0,20,z],[47,1,1],cream)
 for x in range(-20,21,5):p('GoalNet',[x,9,z+(-5 if z<0 else 5)],[.12,18,.12],cream,collide=False)
# Huge-mount play garden: ramps, broad stepping decks, shaded seating.
for x,z,w,h in [(163,15,35,3),(195,58,44,5),(153,107,38,3),(202,149,42,6)]:
 p('PlayDeck',[x,h/2,z],[w,h,32],[184,151,96],material='WoodPlanks')
 for n in range(1,7):p('WidePlayStep',[x,h*n/14,z-16-3*n],[w,h*n/7,3],sage)
for x in [137,222]:
 for z in [-23,195]:p('PergolaPillar',[x,16,z],[3,32,3],wood)
for z in [-23,195]:
 p('PergolaBeam',[180,32,z],[91,3,8],wood)
 for x in range(136,226,9):p('PergolaSlat',[x,34,z],[3,1,18],sage)
for x in [-180,-150]:
 for z in [20,65,110,155]:sofa(x,z)
for x,z in [(-245,-180),(-245,-80),(-245,40),(-245,170),(-170,258),(-55,275),(60,275),(180,264),(264,175),(264,40),(264,-90),(210,-203)]:
 p('TreeTrunk',[x,9,z],[4,18,4],wood)
 p('TreeCanopy',[x,24,z],[27,22,27],sage,shape='Ball')
for x in [-115,115]:
 for z in range(-52,254,38):
  p('GardenLampPost',[x,5,z],[.6,10,.6],dark)
  p('GardenLamp',[x,10.5,z],[2,2,2],[248,214,148],material='Neon',light=True)
p('LobbyReturn',[0,4,-61],[12,8,1],dark,text='LOBBY',yaw=180)
(R/'assets/cafe').mkdir(exist_ok=True)
(R/'assets/cafe/layout.json').write_text(json.dumps(parts,ensure_ascii=False,indent=1),encoding='utf-8')
def lua(v):
 if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(x) for k,x in v.items())+'}'
 if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
 if isinstance(v,bool):return str(v).lower()
 return json.dumps(v,ensure_ascii=False)
(R/'src/server/CafeLayout.luau').write_text('-- Generated by tools/build_cafe_layout.py\nreturn '+lua(parts)+'\n',encoding='utf-8')
print(len(parts),'cafe layout objects')
