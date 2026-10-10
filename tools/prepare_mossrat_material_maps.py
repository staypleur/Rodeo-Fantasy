"""Losslessly separate glTF's packed channels for Studio's material path pickers."""
from pathlib import Path
import argparse
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
def prepare(model='mossrat'):
    folder=ROOT/('assets/models/UserRocket' if model=='rocket' else 'assets/models/MossratS1UserRig')
    prefix='Rocket' if model=='rocket' else 'Mossrat'
    # glTF 2.0: roughness=G, metalness=B. Do not assign the RGB packed map
    # to both grayscale material fields in Studio's manual override.
    with Image.open(folder/(prefix+'Texture1.png')) as image:
        image.load()
        for channel,name in [('G',prefix+'Roughness.png'),('B',prefix+'Metalness.png')]:
            expected=image.getchannel(channel)
            path=folder/name
            expected.save(path,format='PNG',optimize=True)
            with Image.open(path) as actual:
                actual.load()
                assert actual.mode=='L' and actual.size==image.size
                assert actual.tobytes()==expected.tobytes()
            print(name,path.stat().st_size,'bytes; exact',channel,'channel')
    with Image.open(folder/(prefix+'Texture0.png')) as color:
        color.verify()
    print('Color PNG decodes successfully; originals and approved rig unchanged.')
if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--model',choices=['mossrat','rocket'],default='mossrat')
    prepare(parser.parse_args().model)
