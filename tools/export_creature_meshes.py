"""Portable original A-family 3D meshes; geometry matches CreatureMesh's runtime profiles."""
from pathlib import Path
import math
from meadow_models import components, SPECIES, STAGES

def geometry(component, stars):
    name=component['name']
    leaf=any(word in name for word in ('Leaf','Sprout','Clover','Grass')) and 'Vein' not in name
    if 'Clover' in name and 'Vein' not in name:
        vertices=[]
        for y in (.5,-.5):
            for j in range(24):
                a=math.tau*j/24
                vertices.append((math.sin(a)**3*.5,y,-(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/32))
        vertices.extend(((0,.5,0),(0,-.5,0)));faces=[]
        for j in range(24):
            n=(j+1)%24
            faces.extend(((48,j,n),(49,24+n,24+j),(j,24+j,24+n),(j,24+n,n)))
    elif leaf:
        vertices=[];faces=[]
        for j in range(9):
            t=j/8;width=.5*math.sin(math.pi*t)**.8+.005;y=.38*math.sin(math.pi*t);z=t-.5
            vertices.extend(((-width,y-.15,z),(0,y,z),(width,y-.15,z),(0,y-.3,z)))
        for j in range(8):
            for k in range(4):
                n=(k+1)%4
                faces.extend(((j*4+k,(j+1)*4+k,(j+1)*4+n),(j*4+k,(j+1)*4+n,j*4+n)))
    elif component['shape'] in ('Ball','Sphere'):
        sides,rings=(24,14) if stars>=9 else (10,6)
        vertices=[(0,.5,0),(0,-.5,0)]
        for r in range(1,rings):
            latitude=math.pi*r/rings
            for i in range(sides):
                a=2*math.pi*i/sides
                vertices.append((math.sin(latitude)*math.cos(a)*.5,math.cos(latitude)*.5,math.sin(latitude)*math.sin(a)*.5))
        faces=[]
        for i in range(sides):
            j=(i+1)%sides
            faces.extend(((0,2+j,2+i),(1,2+(rings-2)*sides+i,2+(rings-2)*sides+j)))
            for r in range(rings-2):
                a,b,c,d=2+r*sides+i,2+r*sides+j,2+(r+1)*sides+j,2+(r+1)*sides+i
                faces.extend(((a,b,c),(a,c,d)))
    else:
        vertices=[(x*.5,y*.5,z*.5) for x,y,z in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
        faces=[]
        for a,b,c,d in ((0,3,2,1),(4,5,6,7),(0,4,7,3),(1,2,6,5),(3,7,6,2),(0,1,5,4)):
            faces.extend(((a,b,c),(a,c,d)))
        if component['shape']=='Wedge':
            vertices=[(-.5,-.5,-.5),(.5,-.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(-.5,.5,.5),(.5,.5,.5)]
            faces=[(0,1,3),(0,3,2),(2,3,5),(2,5,4),(0,4,5),(0,5,1),(0,2,4),(1,5,3)]
    return vertices,faces

def transform(point, component):
    x,y,z=(a*b for a,b in zip(point,component['size']))
    a,b,c=map(math.radians,component['rotation'])
    # Same matrix as build_place.frame (Roblox CFrame.fromOrientation).
    ca,cb,cc,sa,sb,sc=math.cos(a),math.cos(b),math.cos(c),math.sin(a),math.sin(b),math.sin(c)
    result=((cb*cc+sb*sa*sc)*x+(-cb*sc+sb*sa*cc)*y+sb*ca*z,
            ca*sc*x+ca*cc*y-sa*z,
            (-sb*cc+cb*sa*sc)*x+(sb*sc+cb*sa*cc)*y+cb*ca*z)
    return tuple(a+b for a,b in zip(result,component['position']))

def export():
    output=Path('assets/meshes/meadow')
    output.mkdir(parents=True,exist_ok=True)
    count=0
    for species in SPECIES:
        for stars in STAGES:
            stem=f'{species}_A_S{stars}'
            lines=[f'# Original Rodeo Fantasy mesh; Roblox studs; +Y up, -Z forward',f'mtllib {stem}.mtl']
            materials=[];offset=1
            for index,component in enumerate(components(species,stars)):
                vertices,faces=geometry(component,stars)
                mat=f'color_{index}'
                lines.extend((f'o {component["name"]}',f'usemtl {mat}',f's {1 if stars>=9 and component["shape"]=="Ball" else "off"}'))
                materials.extend((f'newmtl {mat}','Kd '+' '.join(f'{v/255:.6f}' for v in component['color']),'Ka 0.15 0.15 0.15','d 1'))
                for v in vertices:
                    lines.append('v '+' '.join(f'{k:.6f}' for k in transform(v,component)))
                for face in faces:lines.append('f '+' '.join(str(v+offset) for v in face))
                offset+=len(vertices)
            (output/(stem+'.obj')).write_text('\n'.join(lines)+'\n')
            (output/(stem+'.mtl')).write_text('\n'.join(materials)+'\n')
            count+=1
    print(f'Exported {count} original grouped OBJ/MTL growth meshes')

if __name__=='__main__':export()
