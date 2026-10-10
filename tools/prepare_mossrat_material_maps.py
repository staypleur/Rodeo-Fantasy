"""Losslessly separate glTF's packed channels for Studio's material path pickers."""
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'assets/models/MossratS1UserRig'

def prepare():
    # glTF 2.0: roughness=G, metalness=B. Do not assign the RGB packed map
    # to both grayscale material fields in Studio's manual override.
    with Image.open(FOLDER/'MossratTexture1.png') as image:
        image.load()
        for channel,name in [('G','MossratRoughness.png'),('B','MossratMetalness.png')]:
            expected=image.getchannel(channel)
            path=FOLDER/name
            expected.save(path,format='PNG',optimize=True)
            with Image.open(path) as actual:
                actual.load()
                assert actual.mode=='L' and actual.size==image.size
                assert actual.tobytes()==expected.tobytes()
            print(name,path.stat().st_size,'bytes; exact',channel,'channel')
    with Image.open(FOLDER/'MossratTexture0.png') as color:
        color.verify()
    print('Color PNG decodes successfully; originals and approved rig unchanged.')
if __name__=='__main__': prepare()
