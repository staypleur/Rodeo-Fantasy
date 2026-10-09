"""Review-only shop and ranking pavilion; no inventory or game-place mutation."""
import math,itertools
import numpy as np
from native_part_review import save_review
parts=[]
cream=(236,223,190);stone=(188,170,136);gold=(199,153,76);wood=(151,109,72)
def box(n,p,s,c,a=0):
 a=math.radians(a);co,si=math.cos(a),math.sin(a)
 parts.append((n,np.array(p,float),np.array(s,float),c,np.array([[co,0,si],[0,1,0],[-si,0,co]])))
def canopy(cx,base,width,depth):
 # Tiered warm-teal roof gradient, repeated modules match the garden masonry.
 for j in range(7):
  t=j/6;col=tuple(round(lo+(hi-lo)*t) for lo,hi in zip((30,97,107),(109,187,169)))
  box('RoofCourse',(cx,base+j*.45,0),(width-j*1.4,.5,depth-j*1.2),col)
 box('GoldRidge',(cx,base+3.3,0),(width-8,.25,.5),gold)
def pillar(cx,x,z):
 box('Pillar',(cx+x,3.3,z),(1,6.6,1),cream)
 box('Foot',(cx+x,.35,z),(1.8,.7,1.8),stone)
 box('Capital',(cx+x,6.6,z),(1.8,.6,1.8),gold)
def planter(cx,x,z):
 box('Planter',(cx+x,.45,z),(2.5,.9,3),stone)
 for dz in (-.8,0,.8):
  box('FlowerLeaves',(cx+x,1,z+dz),(1.6,.4,.8),(105,163,111),15)
  for dx in (-.45,.45):box('Flower',(cx+x+dx,1.4,z+dz),(.55,.25,.55),(229,163,174),45)
for cx in (-19,19):
 box('StoneWalk',(cx,.05,0),(29,.2,22),cream)
 for x in (-11,11):
  for z in (-6,6):pillar(cx,x,z)
 box('Cornice',(cx,7.15,0),(25,1,16),cream)
 canopy(cx,7.9,28,19)
 for x in (-13,13):planter(cx,x,-7.5)

# Shop: empty display shelves; final merchandise and prices remain undecided.
cx=-19
box('ShopCounter',(cx,1.5,-4),(18,3,2.7),wood)
for x in range(-8,9,2):
 box('CounterInset',(cx+x,1.7,-5.42),(1.6,1.7,.12),(204,170,118))
box('CounterTop',(cx,3.1,-4),(19,.35,3.3),(226,201,151))
box('DisplayBack',(cx,3.1,5),(19,6,1.2),cream)
for y in (1.5,3.2,5):box('EmptyDisplayShelf',(cx,y,4.1),(17,.25,2.5),wood)
for x in (-8,0,8):box('ShelfDivider',(cx+x,3.2,4.5),(.3,5,2),wood)
box('ShopSignFrame',(cx,6.7,-8.2),(10,2.6,.35),gold)
box('ShopSignFace',(cx,6.7,-8.42),(9.5,2.1,.15),(45,107,99))

# Ranking pavilion: display geometry, no fabricated ranking values or services.
cx=19
box('RankingBoardFrame',(cx,3.9,2),(20,6.3,.8),gold)
box('RankingBoardFace',(cx,3.9,1.52),(19.3,5.6,.18),(39,90,92))
box('RankingHeader',(cx,6.1,1.38),(18.6,.8,.1),(225,203,148))
box('Divider',(cx,3.5,1.38),(.12,3.8,.1),(173,184,157))
for y in (4.8,3.8,2.8,1.8):
 for x in (-5,5):
  box('ListSlot',(cx+x,y,1.38),(8,.5,.1),(93,136,125))
box('PublicBench',(cx,1.25,-5),(14,.4,2.3),wood)
for x in (-5,5):box('BenchFoot',(cx+x,.55,-5),(.8,1.1,1.7),stone)
box('BenchBack',(cx,2.2,-4),(14,1.5,.4),(185,145,95))

for n,p,s,c,m in parts:
 assert np.isfinite(p).all() and (s>0).all() and np.allclose(m.T@m,np.eye(3))
out=save_review(parts,'LobbyServicesReview','다음 디자인 · 정원 상점 / 랭킹 게시판 쉼터','게임 미적용 · 진열대는 비워둠 · 간판 글씨/랭킹 UI는 적용 시 연결',(.45,.32,-1.1))
print(f'SERVICES_REVIEW_PASS: {len(parts)} native Parts, no shop rules or game modifications; {out}')
