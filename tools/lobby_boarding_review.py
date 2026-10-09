"""Review-only open airship basket and single timber boarding ladder."""
import math
import numpy as np
from native_part_review import save_review
parts=[]
def box(n,p,s,c,angle=0):
 a=math.radians(angle);co,si=math.cos(a),math.sin(a)
 parts.append((n,np.array(p,float),np.array(s,float),c,np.array([[1,0,0],[0,co,-si],[0,si,co]])))
dark=(111,77,48);wood=(168,119,70);gold=(217,171,86);cream=(240,223,182)
box('ReviewBase',(0,-.4,4),(24,.8,29),(221,207,171))
box('BasketFrame',(0,12.6,0),(15,.8,11),dark)
for x in range(-6,7):box('BasketFloorPlank',(x,13.1,0),(.94,.3,10.4),(171+x*2,125+x,77+x))
for x in (-7,7):
 for z in (-5,5):
  box('CornerPost',(x,14.5,z),(.7,3.8,.7),dark)
  box('PostCap',(x,16.5,z),(.95,.35,.95),gold)
  box('Cable',(x,21,z),(.19,9,.19),cream)
for y in (13.5,14.2,14.9,15.6):
 for x in (-7,7):box('SidePlank',(x,y,0),(.35,.5,10),wood)
 box('RearPlank',(0,y,-5),(14,.5,.35),wood)
 for x in (-4.7,4.7):box('FrontPlank',(x,y,5),(4.6,.5,.35),wood)
for x in (-7.25,7.25):
 for z in (-3,0,3):box('GoldBinding',(x,14.6,z),(.12,3.2,.23),gold)
for z in (-5.25,5.25):
 for x in (-6,-3,3,6):box('GoldBinding',(x,14.6,z),(.23,3.2,.12),gold)
box('RearRim',(0,16.2,-5),(15,.3,.6),gold)
for x in (-7,7):box('SideRim',(x,16.2,0),(.6,.3,10),gold)
for x in (-4.7,4.7):box('FrontRim',(x,16.2,5),(4.6,.3,.6),gold)
box('BoardingDeck',(0,13,6.3),(4.5,.4,3.4),dark)
for x in (-1.5,-.5,.5,1.5):box('DeckPlank',(x,13.25,6.3),(.94,.15,3.4),wood)
# One sloping timber ladder, not a second staircase or raised spawn platform.
for x in (-2.1,2.1):
 box('LadderRail',(x,6.7,10.45),(.45,15.6,.45),dark,-31)
for j in range(14):
 y=.8+j*.92;z=14.0-j*.55
 box('LadderRung',(0,y,z),(4.5,.25,.6),wood)
 for x in (-2.1,2.1):box('LadderPeg',(x,y,z),(.55,.18,.74),gold)
for n,p,s,c,m in parts:assert np.isfinite(p).all() and (s>0).all() and np.allclose(m.T@m,np.eye(3))
out=save_review(parts,'LobbyBoardingReview','다음 디자인 · 비행선 바구니와 탑승 사다리','게임 미적용 · 지붕 없는 바구니 · 바다코끼리 본체는 이 검토에 포함하지 않음',(.65,.52,1.1))
print(f'BOARDING_REVIEW_PASS: {len(parts)} native Parts, open basket, one ladder, no game changes; {out}')
