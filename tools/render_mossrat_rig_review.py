"""Render real glTF skinning/animation, never an AI-generated motion preview."""
import argparse
import io
import json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from mossrat_rig_common import ASSETS,ROOT,load,read,skin,transforms


def render(g,b,pos,normals,eye,size=(480,480),bones=False,visibility=False):
    node=next(n for n in g['nodes'] if 'mesh' in n)
    p=g['meshes'][node['mesh']]['primitives'][0]
    ids=read(g,b,p['indices']).reshape(-1,3);uv=read(g,b,p['attributes']['TEXCOORD_0'])
    im=g['images'][g['textures'][g['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index']]['source']]
    view=g['bufferViews'][im['bufferView']]
    tex=Image.open(io.BytesIO(b[view['byteOffset']:view['byteOffset']+view['byteLength']])).convert('RGB')
    tex.thumbnail((1024,1024));tex=np.array(tex)
    width,height=size;frame=np.full((height,width,3),(247,244,237),np.uint8);depth=np.full((height,width),-np.inf)
    visible=np.full((height,width),-1,dtype=np.int32)
    d=np.array(eye,float);d/=np.linalg.norm(d);right=np.cross(d,(0,1,0));right/=np.linalg.norm(right);up=np.cross(right,d)
    # Fixed framing keeps breathing/steps visible, rather than auto-fitting poses.
    reference=read(g,b,p['attributes']['POSITION']);pr=np.stack((reference@right,reference@up),axis=-1)
    low,high=pr.min(axis=0),pr.max(axis=0);center=(low+high)/2
    scale=min((width-36)/(high[0]-low[0]),(height-36)/(high[1]-low[1]))
    sx=(pos@right-center[0])*scale+width/2;sy=-(pos@up-center[1])*scale+height/2;sz=pos@d
    light=np.array((.25,.75,.75));light/=np.linalg.norm(light)
    for triangle_index,tri in enumerate(ids):
        x=sx[tri];y=sy[tri];z=sz[tri];nu=normals[tri];tuv=uv[tri]
        x0=max(0,int(np.floor(x.min())));x1=min(width-1,int(np.ceil(x.max())))
        y0=max(0,int(np.floor(y.min())));y1=min(height-1,int(np.ceil(y.max())))
        if x0>x1 or y0>y1:continue
        den=(y[1]-y[2])*(x[0]-x[2])+(x[2]-x[1])*(y[0]-y[2])
        if abs(den)<1e-8:continue
        yy,xx=np.mgrid[y0:y1+1,x0:x1+1];xx=xx+.5;yy=yy+.5
        a=((y[1]-y[2])*(xx-x[2])+(x[2]-x[1])*(yy-y[2]))/den
        c=((y[2]-y[0])*(xx-x[2])+(x[0]-x[2])*(yy-y[2]))/den;f=1-a-c
        zz=a*z[0]+c*z[1]+f*z[2];old=depth[y0:y1+1,x0:x1+1]
        mask=(a>=-1e-5)&(c>=-1e-5)&(f>=-1e-5)&(zz>old)
        if not mask.any():continue
        tc=a[...,None]*tuv[0]+c[...,None]*tuv[1]+f[...,None]*tuv[2]
        tx=np.clip((tc[...,0]*tex.shape[1]).astype(int),0,tex.shape[1]-1);ty=np.clip((tc[...,1]*tex.shape[0]).astype(int),0,tex.shape[0]-1)
        nn=a[...,None]*nu[0]+c[...,None]*nu[1]+f[...,None]*nu[2];nn/=np.maximum(np.linalg.norm(nn,axis=-1,keepdims=True),1e-8)
        shade=.7+.3*np.maximum(0,nn@light)
        rgb=np.clip(tex[ty,tx]*shade[...,None],0,255).astype(np.uint8)
        old[mask]=zz[mask];frame[y0:y1+1,x0:x1+1][mask]=rgb[mask]
        visible[y0:y1+1,x0:x1+1][mask]=triangle_index
    image=Image.fromarray(frame)
    if bones:
        draw=ImageDraw.Draw(image);world=transforms(g,b)
        def project(node):
            point=world[node][:3,3];return ((point@right-center[0])*scale+width/2,-(point@up-center[1])*scale+height/2)
        for i,node in enumerate(g['nodes']):
            if 'mesh' in node:continue
            point=project(i)
            for child in node.get('children',[]):draw.line((*point,*project(child)),fill=(255,90,40),width=2)
            draw.ellipse((point[0]-3,point[1]-3,point[0]+3,point[1]+3),fill=(255,210,50))
    return (image,visible) if visibility else image


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--animate',action='store_true');args=parser.parse_args()
    g,b=load(ASSETS/'MossratS1Rigged.glb')
    folder=ROOT/'assets/previews';folder.mkdir(parents=True,exist_ok=True)
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
    cases=[('REST / ORIGINAL SHAPE',None,0,(.65,.25,1)),('34 BONE RIG',None,0,(1,.15,.1)),('HEAD / NECK MOTION','LookAround',1,(0,.08,1))]
    image=Image.new('RGB',(1440,565),(247,244,237));draw=ImageDraw.Draw(image)
    draw.text((15,8),'MOSSRAT S1 / ACTUAL SKINNED MESH REVIEW',font=font,fill=(50,60,45))
    for i,(label,clip,t,eye) in enumerate(cases):
        pos,norm=skin(g,b,clip,t);image.paste(render(g,b,pos,norm,eye,bones=i==1),(i*480,62))
        draw.text((i*480+15,38),label,font=font,fill=(50,60,45))
    meta=json.loads((ASSETS/'metadata.json').read_text(encoding='utf-8'))
    draw.text((15,539),f"{meta['riggedTriangles']:,} triangles / {meta['bones']} bones / review only - not a Studio screenshot or a device performance test",font=font,fill=(80,85,75))
    image.save(folder/'MossratS1RigReview.png')
    print('Static rig review saved',flush=True)
    if args.animate:
        frames=[]
        for frame in range(40):
            image=Image.new('RGB',(1080,425),(247,244,237));draw=ImageDraw.Draw(image)
            for i,(label,clip,eye) in enumerate([('IDLE / BREATHING','Idle',(0,.08,1)),('WALK','Walk',(1,.15,.1)),('HEAD / TAIL','LookAround',(.65,.25,1))]):
                time=frame/10 if clip!='Walk' else frame/20
                pos,norm=skin(g,b,clip,time)
                image.paste(render(g,b,pos,norm,eye,size=(360,360)),(i*360,35))
                draw.text((i*360+12,8),label,font=font,fill=(50,60,45))
            draw.text((12,398),'Real skinning preview / draft motions / Studio and mobile tests pending',font=font,fill=(80,85,75))
            frames.append(image)
            if frame%10==0:print('Animation frame',frame,flush=True)
        frames[0].save(folder/'MossratS1RigMotion.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=False)
        print('Motion GIF saved',flush=True)


if __name__=='__main__':main()
