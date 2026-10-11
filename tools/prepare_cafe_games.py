"""Extract static free piano geometry; build a compact, unpublished activity review."""
from pathlib import Path
import copy, math, wave, struct
import xml.etree.ElementTree as E
from build_project import prop,script,node
R=Path(__file__).resolve().parents[1]
root=E.parse(R/'dist/ReviewModels/CafePiano-Source.rbxlx').getroot()
piano=copy.deepcopy(next(n for n in root.iter('Item') if n.findtext("Properties/string[@name='Name']")=='CafePianoVisual'))
allowed={'Model','Folder','Part','WedgePart','CornerWedgePart','MeshPart','UnionOperation','SpecialMesh','SurfaceAppearance','Decal','Texture'}
for n in list(piano.iter('Item')):
 for v in n.findall('Item'):
  if v.get('class') not in allowed:n.remove(v)
 for v in list(n.find('Properties')):
  if v.tag=='UniqueId' or v.get('name') in ('WorldPivotData','ModelMeshData'):n.find('Properties').remove(v)
 if n.get('class') in ('Part','WedgePart','MeshPart','UnionOperation'):
  prop(n,'bool','Anchored','true');prop(n,'bool','CanTouch','false');prop(n,'bool','CanQuery','true')
asset=E.Element('roblox',version='4');asset.append(piano)
refs={v.get('referent'):f'PianoVisual{i}' for i,v in enumerate(asset.iter('Item'))}
for v in asset.iter('Item'):v.set('referent',refs[v.get('referent')])
for v in asset.iter('Ref'):v.text=refs.get(v.text,'null')
shared=E.SubElement(asset,'SharedStrings');used={v.text for v in asset.iter('SharedString')}|{v.text for v in asset.iter('NetAssetRef')}
for v in root.findall('SharedStrings/SharedString'):
 if v.get('md5') in used:shared.append(copy.deepcopy(v))
E.ElementTree(asset).write(R/'assets/maps/CafePianoVisual.rbxmx',encoding='utf-8',xml_declaration=True)
# Original synthesized C4, short decay. No downloaded recording or copyrighted song.
audio=R/'assets/audio';audio.mkdir(exist_ok=True)
rate=44100;duration=2.5
data=bytearray()
for n in range(int(rate*duration)):
 t=n/rate
 envelope=(1-math.exp(-t*250))*math.exp(-t*2.5)
 signal=sum(weight*math.sin(2*math.pi*261.625565*(harmonic+.0002*harmonic**3)*t)*math.exp(-t*harmonic*.35) for harmonic,weight in [(1,1),(2,.42),(3,.25),(4,.12),(5,.07),(6,.025)])
 data.extend(struct.pack('<h',int(max(-1,min(1,signal*envelope*.42))*32767)))
with wave.open(str(audio/'CafePianoC4.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(data)
print('PIANO_STATIC',len(list(piano.iter('Item'))),'AUDIO_BYTES',len(data))
