"""Render Meshy's real geometry and base-color image, not a generated concept."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'tools/render_textured_review.py').read_text(encoding='utf-8')
source=source.replace("g['images'][0]['bufferView']","g['images'][g['textures'][g['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index']]['source']]['bufferView']")
source=source.replace('normal[indices[0]]','normal[indices]')
source=source.replace("for node in g['nodes']:","for node in g['nodes']:\n if 'mesh' not in node:continue")
source=source.replace('shade=.88+.12*max(0,np.dot(normal,light))','nn=a[...,None]*normal[0]+b[...,None]*normal[1]+c[...,None]*normal[2]\n  nn/=np.maximum(np.linalg.norm(nn,axis=-1,keepdims=True),1e-8)\n  shade=.65+.35*np.maximum(0,nn@light)')
source=source.replace('texture[ty,tx]*shade','texture[ty,tx]*shade[...,None]')
source=source.replace('flat normals','vertex normals')
exec(compile(source,__file__,'exec'),{'__file__':str(ROOT/'tools/render_textured_review.py')})
