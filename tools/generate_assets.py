"""Generate original, purpose-built pixel art and simple square-wave audio.
No reference artwork, fonts, samples or melodies are used.
Run with Python and Pillow. Generated assets are committed, so players need neither.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math, struct, wave
ROOT = Path(__file__).resolve().parents[1]
PALETTE = dict(ink='#15152b', blue='#323a70', sky='#6c78bb', cream='#dfd5a5', gold='#c8a65b', red='#ac5a67', teal='#6ca997', stone='#696b86')

def city():
    im=Image.new('RGB',(320,240),PALETTE['ink']); d=ImageDraw.Draw(im)
    for y in range(24):
        for x in range(32):
            road = 0<x<31 and 0<y<23 and (y in [3,9,15,21] or x in [3,7,11,15,19,23,27])
            if road:
                d.rectangle((x*10,y*10,x*10+9,y*10+9),fill=PALETTE['stone'])
                if (x+y)%2==0:d.rectangle((x*10+4,y*10+4,x*10+5,y*10+5),fill=PALETTE['cream'])
            else:
                if x in [0,31] or y in [0,23]:continue
                d.rectangle((x*10+1,y*10+1,x*10+8,y*10+8),fill=PALETTE['blue'])
                d.rectangle((x*10+2,y*10+2,x*10+7,y*10+3),fill=PALETTE['sky'])
                d.rectangle((x*10+3,y*10+5,x*10+4,y*10+6),fill=PALETTE['gold'])
    im.save(ROOT/'assets/sprites/city.png')

def character(name,color):
    im=Image.new('RGBA',(16,16)); d=ImageDraw.Draw(im)
    d.rectangle((5,1,10,3),fill=PALETTE['ink']);d.rectangle((3,3,12,4),fill=color)
    d.rectangle((6,5,10,7),fill=PALETTE['cream']);d.rectangle((4,8,11,12),fill=color)
    d.rectangle((6,8,7,10),fill=PALETTE['cream']);d.rectangle((4,13,6,15),fill=color);d.rectangle((9,13,11,15),fill=color)
    im.save(ROOT/f'assets/sprites/{name}.png')

def icons():
    for kind in ['pub','arms','cars','store','bank','police','hideout','forgery','casino','loan','subway','station','mayor','transport']:
        im=Image.new('RGBA',(10,10));d=ImageDraw.Draw(im)
        d.rectangle((0,0,9,9),fill=PALETTE['ink']);d.rectangle((1,1,8,8),outline=PALETTE['gold'])
        c=PALETTE['cream']
        if kind in ['cars','transport']:
            d.rectangle((2,4,7,6),fill=c);d.rectangle((3,2,6,4),fill=c);d.point((2,7),fill=PALETTE['red']);d.point((7,7),fill=PALETTE['red'])
        elif kind in ['bank','loan']:
            d.polygon([(2,3),(5,1),(7,3)],fill=c);d.line((2,4,2,6),fill=c);d.line((5,4,5,6),fill=c);d.line((7,4,7,6),fill=c);d.line((2,7,7,7),fill=c)
        elif kind in ['pub','station']:
            d.rectangle((3,2,6,7),fill=c);d.rectangle((6,3,7,5),outline=c);d.rectangle((3,2,6,3),fill=PALETTE['red'])
        elif kind=='arms':d.rectangle((2,3,7,4),fill=c);d.rectangle((3,4,4,7),fill=c)
        elif kind=='police':d.polygon([(5,1),(7,3),(7,6),(5,8),(2,6),(2,3)],fill=c)
        elif kind=='subway':d.rectangle((2,2,7,6),fill=c);d.rectangle((3,3,6,4),fill=PALETTE['ink']);d.line((3,7,2,8),fill=c);d.line((6,7,7,8),fill=c)
        elif kind=='casino':d.rectangle((2,2,7,7),fill=c);d.point((3,3),fill=PALETTE['ink']);d.point((6,6),fill=PALETTE['ink']);d.point((5,4),fill=PALETTE['ink'])
        elif kind=='forgery':d.rectangle((3,2,6,7),fill=c);d.line((4,4,5,4),fill=PALETTE['ink']);d.line((4,6,5,6),fill=PALETTE['ink'])
        else:d.polygon([(2,4),(5,1),(8,4)],fill=c);d.rectangle((3,4,7,7),fill=c);d.rectangle((5,5,6,7),fill=PALETTE['ink'])
        im.save(ROOT/f'assets/sprites/{kind}.png')

def arena():
    im=Image.new('RGB',(400,200),PALETTE['ink']);d=ImageDraw.Draw(im)
    for x in range(0,400,10):d.line((x,0,x,199),fill='#24253d')
    for y in range(0,200,10):d.line((0,y,399,y),fill='#24253d')
    d.rectangle((0,0,399,199),outline=PALETTE['sky'],width=10)
    for x,y in [(18,3),(20,15),(18,9)]:d.rectangle((x*10,y*10,x*10+19,y*10+19),fill=PALETTE['stone']);d.rectangle((x*10+2,y*10+2,x*10+17,y*10+17),outline=PALETTE['cream'])
    im.save(ROOT/'assets/sprites/arena.png')

def illustration(kind):
    im=Image.new('RGB',(192,80),PALETTE['ink']);d=ImageDraw.Draw(im)
    for i in range(10):
        x=i*21;h=20+(i*13)%30
        d.rectangle((x,55-h,x+17,70),fill=PALETTE['blue'])
        for wy in range(57-h,66,7):
            for wx in range(x+3,x+15,6):d.rectangle((wx,wy,wx+2,wy+2),fill=PALETTE['gold'])
    d.rectangle((0,70,191,79),fill=PALETTE['stone'])
    if kind=='title':
        d.rectangle((18,15,72,68),fill=PALETTE['ink']);d.rectangle((28,24,60,34),fill=PALETTE['gold']);d.rectangle((20,33,71,39),fill=PALETTE['gold']);d.rectangle((34,40,56,51),fill=PALETTE['cream']);d.rectangle((23,52,65,68),fill=PALETTE['red'])
    else:
        icon=Image.open(ROOT/f'assets/sprites/{kind}.png').resize((50,50),Image.Resampling.NEAREST);im.paste(icon,(72,19),icon)
    im.save(ROOT/f'assets/sprites/panel_{kind}.png')

def sound(name,notes,seconds,amplitude=0.15):
    rate=22050;frames=[]
    for i in range(int(rate*seconds)):
        t=i/rate;step=min(len(notes)-1,int(t/seconds*len(notes)));freq=notes[step]
        envelope=min(1,(seconds-t)*30) * min(1,(t%(seconds/len(notes)))*60)
        val=0 if freq==0 else (1 if math.sin(2*math.pi*freq*t)>0 else -1)
        frames.append(struct.pack('<h',int(val*envelope*amplitude*32767)))
    with wave.open(str(ROOT/f'assets/audio/{name}.wav'),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(frames))

if __name__=='__main__':
    city();icons();arena();character('player',PALETTE['red']);character('enemy',PALETTE['sky'])
    for kind in ['title','pub','arms','cars','store','bank','police','hideout','forgery','casino','loan','subway','station','mayor','transport']:illustration(kind)
    sound('click',[420,280],0.08);sound('safe',[880],0.12);sound('dull',[110],0.12);sound('shot',[110,80,55],0.15)
    sound('music',[110,0,165,0,130.81,0,146.83,0,110,0,164.81,0,98,0,146.83,0],6.4,0.07)
